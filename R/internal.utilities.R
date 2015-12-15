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

  mlExts <- .rfmlEnv$mlExts

  # get all transforms
#   mlURL <- paste(mlHost, "/v1/config/transforms?format=json", sep="")
#
#   response <- GET(mlURL, authenticate(username, password, type="digest"))
#   status_code <- response$status_code
#   rContent <- content(response)
#   if (status_code != 200){
#     # something  went wrong, could be wrong user etc
#     errorMsg <- paste("statusCode: ",
#                       rContent$errorResponse$statusCode,
#                       ", status: ", rContent$errorResponse$status,
#                       ", message: ", rContent$errorResponse$message, sep="")
#     stop(paste("Ops, something went wrong.", errorMsg))
#     return(FALSE)
#   } else if (rContent$transforms == "") {
#     return(FALSE)
#   }
#   # Need to check, if no transformations exists in DB the response is:
#   # {"transforms":""}
#   transforms <- rContent$transforms$transform
#   nbrFound <- 0
#   for (i in 1:length(transforms)) {
#     if (transforms[[i]]$name %in% mlTransforms) {
#       nbrFound <- nbrFound + 1
#     }
#   }
#   if (nbrFound != length(mlTransforms)) {
#     return(FALSE)
#   }
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
  if (nbrFound != length(mlLibs)) {
    return(FALSE)
  }
  # get libraries, we only look under /ext/rfml/ and support javascript (.sjs)
  mlURL <- paste(mlHost, "/v1/config/resources?format=json", sep="")
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
  } else if (length(rContent$resources$resource) == 0) {
    return(FALSE)
  }
  exts <- rContent$resources$resource
  nbrFound <- 0
  for (i in 1:length(exts)) {
    if (exts[[i]]$name %in% mlExts) {
      nbrFound <- nbrFound + 1
    }
  }
  if (nbrFound != length(mlExts)) {
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

# internal function to add exstention to rest interface used
.insert.ext <- function(mlHost, username, password, mlExtName)  {

  mlExtFile <- paste(mlExtName, ".sjs", sep='')
  file <- system.file("ext",mlExtFile ,package = "rfml")
  ext <- upload_file(file, "application/vnd.marklogic-javascript")
  #  'http://localhost:8004/v1/config/resources/example'
  mlURL <- paste(mlHost, "/v1/config/resources/", mlExtName, sep="")
  # add or replace search options to the database
  response <- PUT(mlURL, authenticate(username, password, type="digest"), body=ext)
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

# internal function to remove ext used
.remove.ext <- function(mlHost, username, password, mlExtName)  {

  ##mlLibFile <- paste(mlLibName, ".sjs", sep='')
  mlURL <- paste(mlHost, "/v1/config/resources/", mlExtName, sep="")
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
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/v1/resources/rfml.dframe", sep="")
  if (is.null(searchOption)) {
    mlOptions <- .rfmlEnv$mlDefaultOption
  } else {
    mlOptions <- searchOption
  }

  # need to pick start and end from mlDf...
  nStart=mlDf@.start
  if (nrows>0 && nrows<mlDf@.nrows) {
    nPageLength <- nrows
  } else {
    nPageLength <- mlDf@.nrows
  }
  queryArgs <- c(queryComArgs, 'rs:start'=nStart,'rs:pageLength'=nPageLength, 'rs:return'="data")
  # Need to check if extracted then we could have changed the rows...
  if (mlDf@.extracted) {
    # create a extfields parameter...
    extFields <- "{"
    for (i in 1:length(mlDf@.col.name)) {
      if (nchar(extFields) > 1) {
        extFields <- paste(extFields, ',', sep='')
      }
      extFields <- paste(extFields, '"', mlDf@.col.name[i],
                         '":{"fieldDef":"',mlDf@.col.name[i],
                         '","orgField":"',mlDf@.col.org_name[i],
                         '","orgPath":"',mlDf@.col.org_xpath[i],
                         '","orgFormat":"',mlDf@.col.format[i],'"}',sep='')
    }
    extFields <- paste(extFields, '}', sep='')
    queryArgs <- c(queryArgs,'rs:extfields'=extFields)
  }

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
    queryArgs <- c(queryArgs, 'rs:fields'=fields)
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
    return(fromJSON(rContent, simplifyDataFrame = TRUE)$results)
  } else {
    stop("The call to MarkLogic did not return valid data. The ml.data.frame data could be missing in the database.")
  }

}
# Internal used function that inserts data.frame data into MarkLogic.
# Each line is added as a document, put in a collection based on the name
.insert.ml.data <- function(myData, myCollection, format, directory) {

  # get connection imformation
  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")

  mlPostURL <- paste(mlHost, "/v1/documents", sep="")

  rfmlCollection <- myCollection
  # generate the directory URI
  if (directory == "") {
    rfmlDirectory <- paste("/rfml/", username, "/", myCollection, "/", sep="")
  } else {
    rfmlDirectory <- directory
  }

  if (format == "XML") {
    bodyFile <- .generate.xml.body(myData, myCollection, rfmlDirectory)
  } else if (format == "json") {
    bodyFile <- .generate.json.body(myData, myCollection, rfmlDirectory)
  } else {
    stop("Unkown format")
  }
  response <- POST(mlPostURL,  body = upload_file(bodyFile, type = "multipart/mixed; boundary=BOUNDARY"), authenticate(username, password, type="digest"), encode = "multipart")
  unlink(bodyFile)
  if(response$status_code != 200) {
    rContent <- content(response, as = "text")
    errorMsg <- paste("statusCode: ",rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  return(rfmlCollection)

}
# Internal used function that deletes data created by as.ml.data.frame.
.delete.ml.data <- function(myData, myCollection, format, directory) {

  # get connection imformation
  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")

  mlPostURL <- paste(mlHost, "/v1/documents", sep="")

  rfmlCollection <- myCollection
  # generate the directory URI
  if (directory == "") {
    rfmlDirectory <- paste("/rfml/", username, "/", myCollection, "/", sep="")
  } else {
    rfmlDirectory <- directory
  }

  if (format == "XML") {
    bodyFile <- .generate.xml.body(myData, myCollection, rfmlDirectory)
  } else if (format == "json") {
    bodyFile <- .generate.json.body(myData, myCollection, rfmlDirectory)
  } else {
    stop("Unkown format")
  }
  response <- POST(mlPostURL,  body = upload_file(bodyFile, type = "multipart/mixed; boundary=BOUNDARY"), authenticate(username, password, type="digest"), encode = "multipart")
  unlink(bodyFile)
  if(response$status_code != 200) {
    rContent <- content(response, as = "text")
    errorMsg <- paste("statusCode: ",rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
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
  mlSearchURL <- paste(mlHost, "/v1/resources/rfml.stat", sep="")
  nPageLength <- mlDf@.nrows
  queryArgs <- c(queryComArgs, 'rs:pageLength'=nPageLength, 'rs:statfunc'=func,'rs:fields'=fields)

  response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())
  rContent <- content(response) #, as = "text""
  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }
  return(rContent)

}

# Get data for the summary function
.ml.summary.func <- function(mlDf) {

  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  #dframe <- mlDf@.name
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

# Get data for the summary function
.ml.matrix <- function(mlDf, matrixfunc) {

  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  #dframe <- mlDf@.name
  #query <- mlDf@.ctsQuery
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/v1/resources/rfml.matrix", sep="")
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

  queryArgs <- c(queryComArgs, 'rs:pageLength'=nPageLength, 'rs:matrixfunc'=matrixfunc)


  # create
  if (length(mlDf@.col.defs) > 0) {
    fields <- "{"
    for (i in 1:length(mlDf@.col.defs)) {
      if (nchar(fields) > 1) {
        fields <- paste(fields, ',', sep='')
      }
      fields <- paste(fields, '"', names(mlDf@.col.defs[i]), '":{"fieldDef":"',mlDf@.col.defs[[i]] ,'"}',sep='')
      #fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'","orgField":"', x@.org_name, '","orgFormat":"', x@.format , '"}
    }
    fields <- paste(fields, '}', sep='')
    queryArgs <- c(queryArgs, 'rs:fields'=fields)
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


.generate.xml.body <- function(data, name, directory) {

  boundary <- "--BOUNDARY"
  contentType <- "Content-Type: application/xml"
  bodyText <- c(boundary,contentType)

  # add metadata
  bodyText <- c(bodyText, "Content-Disposition: inline; category=metadata")
  bodyText <- c(bodyText, "")
  bodyText <- c(bodyText, '<?xml version="1.0" encoding="UTF-8"?>')
  bodyText <- c(bodyText, '<rapi:metadata xmlns:rapi="http://marklogic.com/rest-api">')
  bodyText <- c(bodyText, paste('<rapi:collections><rapi:collection>', name, '</rapi:collection></rapi:collections>', sep=""))
  bodyText <- c(bodyText, '</rapi:metadata>')

  # start loop
  for (i in 1:nrow(data)) {
    bodyText <- c(bodyText,boundary,contentType, paste("Content-Disposition: inline;extension=xml;directory=", directory,sep=""), "")
    myXml <- xmlTree()
    myXml$addTag(name, close=FALSE)
    for (j in names(data)) {
      myXml$addTag(j, data[i, j])
    }
    myXml$closeTag()
    bodyText <- c(bodyText, saveXML(myXml,indent = FALSE,prefix = '<?xml version="1.0"?>'))
    #bodyText <- c(bodyText, saveXML(myXml,indent = FALSE, prefix = ''))
  }
  bodyText <- c(bodyText, "--BOUNDARY--", "")
  # add it
  multipartBody <- tempfile()
  writeLines(bodyText, multipartBody, sep='\r\n')
  # remove the file after upload
  #unlink(multipartBody)
  return(multipartBody)
  # start loop


}

.generate.json.body <- function(data, name, directory) {

  boundary <- "--BOUNDARY"
  #contentTypeXML <- "Content-Type: application/xml"
  contentType <- "Content-Type: application/json"
  bodyText <- c(boundary,contentType)

  # add metadata
  bodyText <- c(bodyText, "Content-Disposition: inline; category=metadata")
  bodyText <- c(bodyText, "")
  bodyText <- c(bodyText, paste('{"collections" : ["', name, '"] }', sep=""))


  # start loop
  for (i in 1:nrow(data)) {
    bodyText <- c(bodyText,boundary,contentType, paste("Content-Disposition: inline;extension=json;directory=", directory,sep=""), "")
    jsonData <- toJSON(data[i,])
    # need to remove the [ ] in the doc, before sending it
    jsonData <- gsub("\\]", "", gsub("\\[", "", jsonData))

    bodyText <- c(bodyText, jsonData)
  }
  bodyText <- c(bodyText, "--BOUNDARY--", "")
  # add it
  multipartBody <- tempfile()
  writeLines(bodyText, multipartBody, sep='\r\n')
  return(multipartBody)
}
