###############################################################################
# Internal functions used in the package
###############################################################################
# verify that the database has everything neccessary in order to use the package
# if it exists it returns TRUE if not FALSE and if any other status_code than 404
# it will add a warning
.check.database <- function(mlHost, username, password) {

  # the search options used
  mlTransformName <- "rfmlTransform"
  mlURL <- paste(mlHost, "/LATEST/config/transforms/", mlTransformName, sep="")

  response <- GET(mlURL, authenticate(username, password, type="digest"))
  status_code <- response$status_code
  # If status 404 the search options was not found
  if (status_code == 404) {
    # 404 Not found
    return(FALSE)
  } else if (status_code != 200){
    # something else went wrong, could be wrong user etc
    rContent <- content(response)
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    warning(paste("Ops, something went wrong.", errorMsg))
    return(FALSE)
  }
  # check for ...

  return(TRUE)


}

# internal function to add default serach options
.insert.search.options <- function(mlHost, username, password)  {
  mlQueryOpName <- "rfml"
  mlOptions <- upload_file(system.file("options", "rfml.json",package = "rfml"), "application/json")
  mlURL <- paste(mlHost, "/v1/config/query/", mlQueryOpName, sep="")

  # add or replace search options to the database
  response <- PUT(mlURL, authenticate(username, password, type="digest"), body=mlOptions)
  # TODO:
  # check the response
  # if not 201 or 204 then raise a error
  # status_code <- response$status_code
#
#   rContent <- content(response)
#   errorMsg <- paste("statusCode: ",
#                     rContent$errorResponse$statusCode,
#                     ", status: ", rContent$errorResponse$status,
#                     ", message: ", rContent$errorResponse$message, sep="")
#   stop(paste("Ops, something went wrong.", errorMsg))
  # return the name of the search options
  return(TRUE)
}

# internal function to add rest interface used
.insert.search.transform <- function(mlHost, username, password, mlTransformName)  {

  #mlTransformName <- "rfmlTransform"
  mlTransformFile <- paste(mlTransformName, ".sjs", sep='')
  file <- system.file("transform",mlTransformFile ,package = "rfml")
  transform <- upload_file(file, "application/vnd.marklogic-javascript")
  mlURL <- paste(mlHost, "/LATEST/config/transforms/", mlTransformName, sep="")

  # add or replace search options to the database
  response <- PUT(mlURL, authenticate(username, password, type="digest"), body=transform)

  if (response$status_code != 204) {

    rContent <- content(response)
    errorMsg <- paste("statusCode: ",
                     rContent$errorResponse$statusCode,
                     ", status: ", rContent$errorResponse$status,
                     ", message: ", rContent$errorResponse$message, sep="")
   stop(paste("Ops, something went wrong.", errorMsg))
  }
  # return the name of the search options
  return(TRUE)
}

.get.ml.data <- function(mlDf, nrows=0) {

  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  dframe <- mlDf@.name
  #query <- mlDf@.ctsQuery
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/LATEST/search", sep="")
  mlOptions <- "rfml"
  nStart=1
  if (nrows>0) {
    nPageLength <- nrows
  } else {
    nPageLength <- mlDf@.nrows
  }

  queryArgs <- c(queryComArgs, pageLength=nPageLength, transform="rfmlTransform",
                 'trans:dframe'=dframe, 'trans:return'="data")


  # create
  if (length(mlDf@.col.defs) > 0) {
    fields <- "{"
    for (i in 1:length(mlDf@.col.defs)) {
      if (nchar(fields) > 1) {
        fields <- paste(fields, ',', sep='')
      }
      fields <- paste(fields, '"', names(mlDf@.col.defs[i]), '":{"fieldDef":"',mlDf@.col.defs[[i]] ,'"}',sep='')
    }
    fields <- paste(fields, '}', sep='')
    queryArgs <- c(queryArgs, 'trans:fields'=fields)
  }


   # do a search
  response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())
  # check that we get an 200
  rContent <- content(response, as = "text")
  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  if (validate(rContent)) {
    return(fromJSON(rContent, simplifyDataFrame = TRUE))
  } else {
    stop("The call to MarkLogic did not return valid data. The ml.data.frame data could be missing in the database.")
  }

}
.parse.multiresponse <- function(content, content_type) {
  # get all positions with ..
  positions <- gregexpr("\r\nContent-Type: application/xml", content)
  # the number of positions
  y <- positions[[1]][1:length(positions[[1]])]
  end <- length(y)
  i <- 1
  strXML <- ""
  while (i <= end) {
    startPos <- y[i]
    if (i < end) {
      endPos <- y[i+1]
    } else {
      endPos <- nchar(content)
    }
    part <- substr(content, startPos, endPos)
    startXML <- regexpr("<", part)[1]
    endXML  <- regexpr(">\r", part)[1]
    strXML <- paste(strXML, substr(part, startXML,endXML), sep = "")
    i <- i+1
  }
  return(strXML)
}
