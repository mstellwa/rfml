###############################################################################
# Internal functions used in the package
###############################################################################
# verify that the database has everything neccessary in order to use the package
# if it exists it returns TRUE if not FALSE and if any other status_code than 404
# it will add a warning
.check.database <- function(mlHost, username, password) {

  # the transforms used
  mlTransforms <- .rfmlEnv$mlTransforms
  # name of options used
  mlOptions <-.rfmlEnv$mlOptions
  # name of libs used
  mlLibs <- .rfmlEnv$mlLibs

  # get all transforms
  mlURL <- paste(mlHost, "/v1/config/transforms?format=json", sep="")

  response <- GET(mlURL, authenticate(username, password, type="digest"))
  status_code <- response$status_code
  rContent <- content(response)
  if (status_code != 200){
    # something  went wrong, could be wrong user etc
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
    return(FALSE)
  } else if (rContent$transforms == "") {
    return(FALSE)
  }
  # Need to check, if no transformations exists in DB the response is:
  # {"transforms":""}
  transforms <- rContent$transforms$transform
  nbrFound <- 0
  for (i in 1:length(transforms)) {
    if (transforms[[i]]$name %in% mlTransforms) {
      nbrFound <- nbrFound + 1
    }
  }
  if (nbrFound != length(mlTransforms)) {
    return(FALSE)
  }
  # get search options
  mlURL <- paste(mlHost, "/v1/config/query?format=json", sep="")

  response <- GET(mlURL, authenticate(username, password, type="digest"))
  status_code <- response$status_code
  rContent <- content(response)
  if (status_code != 200){
    # something else went wrong, could be wrong user etc
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
    return(FALSE)
  } else if (rContent == "[]") {
    return(FALSE)
  }
  options <- fromJSON(rContent)
  nbrFound <- 0
  # Need to add .json
  for (i in 1:length(mlOptions)) {
    mlOptions[i] <- paste(mlOptions[i], ".json", sep='')
  }
  for (i in 1:nrow(options)) {
    if (options[i,]$name %in% mlOptions) {
      nbrFound <- nbrFound + 1
    }
  }
  if (nbrFound != length(mlOptions)) {
    return(FALSE)
  }
  # get libraries, we only look under /ext/rfml/ and support javascript (.sjs)
  mlURL <- paste(mlHost, "/v1/ext/rfml/?format=json", sep="")
  response <- GET(mlURL, authenticate(username, password, type="digest"))
  status_code <- response$status_code
  rContent <- content(response)
  if (status_code != 200){
    # something else went wrong, could be wrong user etc
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
    return(FALSE)
  } else if (length(rContent$assets) == 0) {
    return(FALSE)
  }
  libs <- rContent$assets
  nbrFound <- 0
  # fix libs rfmlUtilities -> /ext/rfml/rfmlUtilities.sjs
  for (i in 1:length(mlLibs)) {
    mlLibs[i] <- paste("/ext/rfml/", mlLibs[i], ".sjs", sep="")
  }
  for (i in 1:length(libs)) {
    if (libs[[i]]$asset %in% mlLibs) {
      nbrFound <- nbrFound + 1
    }
  }
  if (nbrFound != length(mlOptions)) {
    return(FALSE)
  }

  return(TRUE)
}

# internal function to add default serach options
.insert.search.options <- function(mlHost, username, password, mlQueryOpName, mlQueryOpFile, fileType)  {
  #mlQueryOpName <- paste(mlOption, ".json", sep='')
  #mlOptions <- upload_file(system.file("options",mlQueryOpName,package = "rfml"), "application/json")
  mlOptions <- upload_file(mlQueryOpFile, fileType)

  mlURL <- paste(mlHost, "/v1/config/query/", mlQueryOpName, sep="")

  # add or replace search options to the database
  response <- PUT(mlURL, authenticate(username, password, type="digest"), body=mlOptions)
  status_code <- response$status_code
  if (status_code != 201 && status_code != 204) {
    rContent <- content(response)
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message,sep="")
       stop(paste("Ops, something went wrong.", errorMsg))

  }

  return(TRUE)
}

# internal function to remove default serach options
.remove.search.options <- function(mlHost, username, password, mlQueryOpName)  {
  mlURL <- paste(mlHost, "/v1/config/query/", mlQueryOpName, sep="")

  # add or replace search options to the database
  response <- DELETE(mlURL, authenticate(username, password, type="digest"))
  # check the response
  status_code <- response$status_code
  if (status_code != 204) {
    rContent <- content(response)
    errorMsg <- paste("statusCode: ",
                         rContent$errorResponse$statusCode,
                         ", status: ", rContent$errorResponse$status,
                         ", message: ", rContent$errorResponse$message, sep="")
    warning(paste("Ops, something went wrong.", errorMsg))
  }
  return(TRUE)
}

# Transform function used with search
.insert.search.transform <- function(mlHost, username, password, mlTransformName)  {

  mlTransformFile <- paste(mlTransformName, ".sjs", sep='')
  file <- system.file("transform",mlTransformFile ,package = "rfml")
  transform <- upload_file(file, "application/vnd.marklogic-javascript")
  mlURL <- paste(mlHost, "/v1/config/transforms/", mlTransformName, sep="")

  # add or replace search options to the database
  response <- PUT(mlURL, authenticate(username, password, type="digest"), body=transform)
  status_code <- response$status_code

  if (status_code != 204) {
    rContent <- content(response)
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))

  }

  return(TRUE)
}

# internal function to remove Transforms
.remove.search.transform <- function(mlHost, username, password, mlTransformName)  {

  mlURL <- paste(mlHost, "/v1/config/transforms/", mlTransformName, sep="")

  # add or replace search options to the database
  response <- DELETE(mlURL, authenticate(username, password, type="digest"))
  status_code <- response$status_code
  if (status_code != 204) {

    rContent <- content(response)
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    warning(paste("Ops, something went wrong.", errorMsg))
  }

  return(TRUE)
}
# internal function to add rest interface used
.insert.lib <- function(mlHost, username, password, mlLibName)  {

  mlLibFile <- paste(mlLibName, ".sjs", sep='')
  file <- system.file("lib",mlLibFile ,package = "rfml")
  lib <- upload_file(file, "application/vnd.marklogic-javascript")
  mlURL <- paste(mlHost, "/v1/ext/rfml/", mlLibFile, sep="")
  # add or replace search options to the database
  response <- PUT(mlURL, authenticate(username, password, type="digest"), body=lib)
  status_code <- response$status_code
  if (status_code != 201 && status_code != 204) {
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

# internal function to remove lib used
.remove.lib <- function(mlHost, username, password, mlLibName)  {

  mlLibFile <- paste(mlLibName, ".sjs", sep='')
  mlURL <- paste(mlHost, "/v1/ext/rfml/", mlLibFile, sep="")
  # add or replace search options to the database
  response <- DELETE(mlURL, authenticate(username, password, type="digest"))

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

.get.ml.data <- function(mlDf, nrows=0, searchOption=NULL) {

  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  dframe <- mlDf@.name
  #query <- mlDf@.ctsQuery
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/LATEST/search", sep="")
  if (is.null(searchOption)) {
    mlOptions <- .rfmlEnv$mlDefaultOption
  } else {
    mlOptions <- searchOption
  }


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
# Internal used function that inserts data.frame data into MarkLogic.
# Each line is added as a document, put in a collection based on the name,
# username and rfml.
.insert.ml.data <- function(myData, myCollection) {

  # get connection imformation
  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")

  mlPutURL <- paste(mlHost, "/v1/documents", sep="")

  # add a prefix to the collection so it is keept seperated and generate the directory URI
  rfmlCollection <- paste("rfml-", username, "-", myCollection, sep="")
  rfmlDirectory <- paste("/rfml/", username, "/", myCollection, "/", sep="")

  # this needs to be optimized.
  for (i in 1:nrow(myData)) {
    myJsonData <- toJSON(myData[i,])
    # need to remove the [ ] in the doc, before sending it
    myJsonData <- gsub("\\]", "", gsub("\\[", "", myJsonData))
    docURI <- paste(rfmlDirectory, i, ".json", sep="")
    putArgs <- list(uri=docURI, collection=rfmlCollection)
    response <- PUT(mlPutURL, query = putArgs, body = myJsonData, authenticate(username, password, type="digest"), content_type_json())
    # check that we get an 201 (Created) or 204 (Updated).
    if(response$status_code != 201 && response$status_code != 204) {
      rContent <- content(response, as = "text")
      errorMsg <- paste("statusCode: ",
                        rContent, sep="")
      stop(paste("Ops, something went wrong.", errorMsg))
    }

  }

  return(rfmlCollection)

}
# executes a statistic function
.ml.stat.func <- function(mlDf, fields, func) {
  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/v1/search", sep="")
  nPageLength <- mlDf@.nrows
  queryArgs <- c(queryComArgs, pageLength=nPageLength, transform="rfmlStat", 'trans:statfunc'=func,'trans:fields'=fields)

  response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())
  rContent <- content(response) #, as = "text""
  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }
  return(rContent)

}

# executes a statistic function
.ml.summary.func <- function(mlDf) {

  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  dframe <- mlDf@.name
  #query <- mlDf@.ctsQuery
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/LATEST/search", sep="")
 # if (is.null(searchOption)) {
    mlOptions <- .rfmlEnv$mlDefaultOption
#  } else {
#    mlOptions <- searchOption
#  }


  nStart=1
#  if (nrows>0) {
#    nPageLength <- nrows
#  } else {
    nPageLength <- mlDf@.nrows
#  }

  queryArgs <- c(queryComArgs, pageLength=nPageLength, transform="rfmlSummary")


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
  rContent <- content(response)
  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  return(rContent)
}
