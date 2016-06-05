###############################################################################
# Internal functions used in the package
###############################################################################

# verify that the database has everything neccessary in order to use the package
# if it exists it returns TRUE if not FALSE and if any other status_code than 404
# it will add a warning
.check.database <- function(mlHost, username, password) {

  mlURL <- paste0(mlHost, "/v1/resources/rfml.check")
  response <- .curl("GET",mlURL,username = username, password = password)
  rContent <- .content(response)
  if (response$status_code != 200){
    stop(paste("It seems like rfml is not installed on ",mlHost,
               "\nUse ml.init.database for setting up the database.", sep=""))
  }
  curRfmlVer <- as.character(packageVersion("rfml"))
  mlVersion <- rContent$mlVersion
  if (curRfmlVer != rContent$rfmlVersion) {
    stop(paste("The installed rfml version on ",mlHost, " is not the same version as installed version.",
               "\nVersion on MarkLogic Server: ",rContent$rfmlVersion,
               "\nInstalled version: ",curRfmlVer,
               "\nUse ml.init.database for updating the database.", sep=""))
  }
  return(mlVersion)
}

# internal function to add rest interface used
.insert.lib <- function(mlHost, username, password, mlLibName)  {

  mlLibFile <- paste0(mlLibName, ".sjs")
  file <- system.file("lib",mlLibFile ,package = "rfml")
  type <- "application/vnd.marklogic-javascript"
  lib <- curl::form_file(file, type)
  mlURL <- paste0(mlHost, "/v1/ext/rfml/", mlLibFile)
  # add or replace modules to the database
  response <- .curlBody('PUT', mlURL, body = lib, username =  username, password =  password)
  status_code <- response$status_code
  if (status_code != 201 && status_code != 204) {
    rContent <- .content(response)
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
  type <- "application/vnd.marklogic-javascript"
  ext <- curl::form_file(file, type)

  mlURL <- paste(mlHost, "/v1/config/resources/", mlExtName, sep="")
  # add or replace search options to the database
  response <- .curlBody('PUT', mlURL, body = ext, username = username, password = password)
  status_code <- response$status_code
  if (status_code != 201 && status_code != 204) {
    rContent <- .content(response)
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))

  }
  # return the name of the search options
  return(TRUE)
}

# internal function to remove extensions and library used
.remove.ext <- function(mlHost, username, password, mlExtName)  {

  mlURL <- paste0(mlHost, mlExtName)
  # add or replace search options to the database
  #response <- DELETE(mlURL, authenticate(username, password, type="digest"), accept_json())
  response <- .curl("DELETE",mlURL, username = username, password = password)

  if (response$status_code != 204) {

    rContent <- .content(response)
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }
  # return the name of the search options
  return(TRUE)
}
.get.ml.metadata <- function(mlDf, nrows=0, searchOption=NULL) {

}
.get.ml.data <- function(mlDf, nrows=0, searchOption=NULL) {

  conn <- mlDf@.conn
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", conn@.host, ":", conn@.port, sep="")
  mlUrl <- paste(mlHost, "/v1/resources/rfml.dframe", sep="")

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
  # IS IT POSSIBLE TO USE
  # fix queryArgs for curl
  qryStr <- .fixQuery(queryArgs)
  # response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())
  # check that we get an 200
  # rContent <- content(response, as = "text")
  # if(response$status_code != 200) {
  #   errorMsg <- paste("statusCode: ",
  #                     rContent, sep="")
  #   stop(paste("Ops, something went wrong.", errorMsg))
  # }
  #
  # if (validate(rContent)) {
  #   return(fromJSON(rContent, simplifyDataFrame = TRUE)$results)
  # } else {
  #   stop("The call to MarkLogic did not return valid data. The ml.data.frame data could be missing in the database.")
  # }
  mlUrl <- paste0(mlUrl,"?", qryStr)
  userpwd <- paste0(username, ":",password)
  httpauth <- 2
  options <- list(httpauth = httpauth, userpwd=userpwd)
  h <- curl::new_handle()
  curl::handle_setopt(h, .list = options)
  headers <- c("Accept" = "application/json")
  curl::handle_setheaders(h, .list = headers)
  on.exit(expr = curl::handle_reset(h), add = TRUE)
  # There is a risk with this since MarkLogic does not support chuncked data through REST
  # a possibility could be to try to write something that is between and send each complete
  # line to the stream_in function...
  return(suppressMessages(stream_in(curl::curl(url = mlUrl, handle = h))))

}
# Internal used function that creats new documents in MarkLogic based on a
# ml.data.frame object.
# Each line is added as a document, put in a collection named after
# myCollection value
.save.ml.data <- function(mlDf, myCollection, directory) {

  conn <- mlDf@.conn
  # get connection imformation
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  mlHost <- paste("http://", conn@.host, ":", conn@.port, sep="")
  mlSearchURL <- paste(mlHost, "/v1/resources/rfml.dframe", sep="")

  rfmlCollection <- myCollection
  # generate the directory URI
  if (directory == "") {
    rfmlDirectory <- paste("/rfml/", username, "/", myCollection, "/", sep="")
  } else {
    rfmlDirectory <- directory
  }

  # need to pick start and end from mlDf...
  nStart=mlDf@.start
  nPageLength <- mlDf@.nrows
  queryComArgs <- mlDf@.queryArgs
  queryArgs <- c(queryComArgs, 'rs:start'=nStart,'rs:pageLength'=nPageLength, 'rs:saveDirectory'=rfmlDirectory, 'rs:saveCollection'=rfmlCollection)
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

  # created fields
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
  #response <- PUT(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())
  response <- .curlBody('PUT', mlUrl = mlSearchURL, queryArgs = queryArgs, username = username, password = password)
  # check that we get an 200
  #rContent <- content(response, as = "text")
  rContent <- .content(response, format = "text")
  if(response$status_code != 204) {
    errorMsg <- paste("statusCode: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  return(rfmlCollection)

}
# Internal used function that inserts data.frame data into MarkLogic.
# Each row is added as a document, put in a collection named after
# myCollection value
.insert.ml.data <- function(conn, myData, myCollection, format, directory) {

  # get connection imformation
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  mlHost <- paste("http://", conn@.host, ":", conn@.port, sep="")

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
  #docs <- upload_file(bodyFile, type = "multipart/mixed; boundary=BOUNDARY")
  #file <- system.file("ext",mlExtFile ,package = "rfml")

  type <- "multipart/mixed; boundary=BOUNDARY"
  docs <- curl::form_file(bodyFile, type)
  #response <- POST(mlPostURL,  body =docs , authenticate(username, password, type="digest"), encode = "multipart", accept_json())
  response <- .curlBody('POST', mlUrl = mlPostURL, body = docs, encode = "multipart", username = username, password = password)
  #suppressWarnings(closeAllConnections())
  #suppressWarnings(close(bodyFile))
  suppressWarnings(unlink(bodyFile, force=TRUE))
  # for some resaon upload_file is leaving a connection open
  openCons <- showConnections()
  if (nrow(openCons) == 1) {
    try(con <- getConnection(as.integer(row.names(openCons))), silent = TRUE)
    try(close(con), silent = TRUE)
  }

  # message(bodyFile)
  if(response$status_code != 200) {
    rContent <- .content(response,format = "text")
    errorMsg <- paste("statusCode: ",rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  return(rfmlCollection)

}
# Internal used function that deletes data created by as.ml.data.frame.
.delete.ml.data <- function(myData, directory) {
  conn <- myData@.conn
  # get connection imformation
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  mlHost <- paste("http://", conn@.host, ":", conn@.port, sep="")

  mlDelURL <- paste(mlHost, "/v1/resources/rfml.dframe", sep="")

  rfmlCollection <- fromJSON(myData@.queryArgs$`rs:collection`)
  if (nchar(rfmlCollection) == 0) {
    stop("Can only delete data for a ml.data.frame that has been created using as.mld.data.frame!")
  }
  # generate the directory URI
  if (directory == "") {
    rfmlDirectory <- paste("/rfml/", username, "/", rfmlCollection, "/", sep="")
  } else {
    rfmlDirectory <- directory
  }
  queryArgs <- list('rs:collection'=rfmlCollection, 'rs:directory'=rfmlDirectory)

  response <- .curl('DELETE', mlDelURL, queryArgs, username, password)
  if(response$status_code != 204) {
    rContent <- .content(response)
    errorMsg <- paste("statusCode: ",rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  return(TRUE)

}
# executes a statistic function
.ml.stat.func <- function(mlDf, fields, func) {
  conn <- mlDf@.conn
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste0("http://", conn@.host, ":", conn@.port)
  mlSearchURL <- paste0(mlHost, "/v1/resources/rfml.stat")
  nPageLength <- mlDf@.nrows
  queryArgs <- c(queryComArgs, 'rs:pageLength'=nPageLength, 'rs:statfunc'=func,'rs:fields'=fields)

  resp <- .curl("GET",mlSearchURL,queryArgs, username, password)
  rContent <- .content(resp)
  if(resp$status_code != 200) {
    errorMsg <- paste0("statusCode: ",
                      resp$status_code, "\nmessage: ", rContent)
    stop(paste("Ops, something went wrong.", errorMsg))
  }
  #browser()
  return(ifelse(is.numeric(rContent), as.numeric(rContent), NA))
}

# Get data for the summary function
.ml.matrix <- function(mlDf, matrixfunc) {
  conn <- mlDf@.conn
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", conn@.host, ":", conn@.port, sep="")
  mlSearchURL <- paste(mlHost, "/v1/resources/rfml.matrix", sep="")

  nStart=1
  nPageLength <- mlDf@.nrows

  queryArgs <- c(queryComArgs, 'rs:pageLength'=nPageLength, 'rs:matrixfunc'=matrixfunc)

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

  resp <- .curl("GET",mlSearchURL,queryArgs, username, password)
  rContent <- .content(resp)
  if(resp$status_code != 200) {
    errorMsg <- paste0("statusCode: ",
                      resp$status_code, "\nmessage: ",rContent)
    stop(paste0("Ops, something went wrong.", errorMsg))
  }

  return(rContent)
}

# executes a Moving Average function
.ml.movavg.func <- function(mlTs, fields, func, n) {
  conn <- mlTs@.conn
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  queryComArgs <- mlTs@.queryArgs

  mlHost <- paste("http://", conn@.host, ":", conn@.port, sep="")
  mlSearchURL <- paste(mlHost, "/v1/resources/rfml.movavg", sep="")
  nPageLength <- mlTs@.nrows
  queryArgs <- c(queryComArgs, 'rs:pageLength'=nPageLength, 'rs:avgfunc'=func,'rs:fields'=fields)
  response <- .curl("GET",mlSearchURL, queryArgs, username, password)
  rContent <- .content(response)
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
    bodyText <- c(bodyText,boundary,contentType, paste("Content-Disposition: attachment;filename=",directory,row.names(data[i,]), ".xml" ,sep=""), "")
    myXml <- xmlTree()
    myXml$addTag(name, close=FALSE)
    for (j in names(data)) {
      myXml$addTag(j, data[i, j])
    }
    myXml$closeTag()
    bodyText <- c(bodyText, saveXML(myXml,indent = FALSE,prefix = '<?xml version="1.0"?>'))
  }
  bodyText <- c(bodyText, "--BOUNDARY--", "")
  # add it
  tf <- tempfile()
  multipartBody <- file(tf, open = "wb")

  # need to have CRLF no matter of which platform it is running on...
  writeLines(text = bodyText, con = multipartBody, sep="\r\n")
  close(multipartBody)
  return(tf)

}

.generate.json.body <- function(data, name, directory) {

  boundary <- "--BOUNDARY"
  contentType <- "Content-Type: application/json"
  bodyText <- c(boundary,contentType)

  # add metadata
  bodyText <- c(bodyText, "Content-Disposition: inline; category=metadata")
  bodyText <- c(bodyText, "")
  bodyText <- c(bodyText, paste('{"collections" : ["', name, '"] }', sep=""))

  if (is.data.frame(data)) {
    # start loop
    for (i in 1:nrow(data)) {
      bodyText <- c(bodyText,boundary,contentType, paste('Content-Disposition: attachment;filename="',directory,row.names(data[i,]), '.json"', sep=""), "")
      jsonData <- jsonlite::toJSON(data[i,])
      # need to remove the [ ] in the doc, before sending it
      jsonData <- gsub("\\]", "", gsub("\\[", "", jsonData))

      bodyText <- c(bodyText,jsonData)
    }
  } else if (is.character(data)) {
    uploadFiles <- list.files(system.file(data, package = "rfml"))
    for (i in 1:length(uploadFiles)) {
      bodyText <- c(bodyText,boundary,contentType, paste("Content-Disposition: inline;extension=json;directory=", directory,sep=""), "")
      fileName <- system.file(data, uploadFiles[i], package="rfml")
      jsonData <-readChar(fileName, file.info(fileName)$size) #toJSON(data[i,])

      bodyText <- c(bodyText, jsonData)
    }
  }
  bodyText <- c(bodyText, "--BOUNDARY--", "")
  # add it
  tf <- tempfile()
  multipartBody <- file(tf, open = "wb")
  # need to have CRLF no matter of which platform it is running on...
  writeLines(text = bodyText, con = multipartBody, sep="\r\n")
  close(multipartBody)
  return(tf)
}
# generate a UUID that is used to identify a connection object
.uuid <- function(uppercase=FALSE) {

  hex_digits <- c(as.character(0:9), letters[1:6])
  hex_digits <- if (uppercase) toupper(hex_digits) else hex_digits

  y_digits <- hex_digits[9:12]

  paste(
    paste0(sample(hex_digits, 8), collapse=''),
    paste0(sample(hex_digits, 4), collapse=''),
    paste0('4', sample(hex_digits, 3), collapse=''),
    paste0(sample(y_digits,1),
           sample(hex_digits, 3),
           collapse=''),
    paste0(sample(hex_digits, 12), collapse=''),
    sep='-')
}

.list2object <-  function(from, to) {
  if (!length(from)) return(new(to))
  s <- slotNames(to)
  p <- pmatch(names(from), s)
  if(any(is.na(p))) stop(paste("\nInvalid parameter:",
                               paste(names(from)[is.na(p)], collapse=" ")), call.=FALSE)
  names(from) <- s[p]
  do.call("new", c(from, Class = to))
}

.fixQuery <- function(query) {
  names <- curl::curl_escape(names(query))
  encode <- function(x) {
    if (inherits(x, "AsIs")) return(x)
    curl::curl_escape(x)
  }
  values <- vapply(query, encode, character(1))
  paste0(names, "=", values, collapse = "&")
}

.content <- function(r, format = "json") {
  # need probably to allow some more parameteres like encoding and simplifyVector
  # return(jsonlite::fromJSON(iconv(readBin(r$content, character()), from = "UTF-8", to = "UTF-8"), simplifyVector = FALSE))
  if (format == "json") {
    return(jsonlite::fromJSON(readBin(r$content, character()), simplifyVector = FALSE))
  } else if (format == "text") {
    return(readBin(r$content, character()))
  } else {
    # wrong format

  }
}

.curl <- function(reqType = 'GET', mlUrl, queryArgs = NULL, username, password) {

  if (!is.null(queryArgs)) {
    qryStr <- .fixQuery(queryArgs)
    mlUrl <- paste0(mlUrl,"?", qryStr)
  }
  userpwd <- paste0(username, ":",password)
  httpauth <- 2
  options <- list(httpauth = httpauth, userpwd=userpwd, customrequest = reqType)

  h <- curl::new_handle()
  curl::handle_setopt(h, .list = options)

  headers <- c("Accept" = "application/json")
  curl::handle_setheaders(h, .list = headers)
  on.exit(expr = curl::handle_reset(h), add = TRUE)

  return(curl::curl_fetch_memory(url = mlUrl, handle = h))
}

.curlBody <- function(reqType = 'PUT', mlUrl, queryArgs = NULL, body = NULL, encode = NULL,username, password) {

  if (!is.null(queryArgs)) {
    qryStr <- .fixQuery(queryArgs)
    mlUrl <- paste0(mlUrl,"?", qryStr)
  }
  userpwd <- paste0(username, ":",password)
  httpauth <- 2
  options <- list(httpauth = httpauth, userpwd=userpwd, customrequest = reqType,
                  post = TRUE)
  fields <- NULL
  if (is.character(body) || is.raw(body)) {
    if (is.character(body)) {
      body <- charToRaw(paste(body, collapse = "\n"))
    }
    bodyOps <- list(postfieldsize = length(body), postfields = body)
    if (is.null(encode)) {
      type <- ''
    } else {
      if (encode == "json") {
        type <- "application/json"
      } else {
        type <- encode
      }
    }
  } else if (inherits(body, "form_file")) {
    con <- file(body$path, "rb")
    size <- file.info(body$path)$size

    bodyOps <- list(
        readfunction = function(nbytes, ...) {
          if(is.null(con))
            return(raw())
          bin <- readBin(con, "raw", nbytes)
          if (length(bin) < nbytes){
            close(con)
            con <<- NULL
          }
          bin
        },
        postfieldsize_large = size
      )
    type <- body$type
  } else if (is.null(body)) {
    body <- raw()
    type <- ''
    bodyOps <- list(postfieldsize = length(body), postfields = body)
  } else if (encode == "json") {
    null <- vapply(body, is.null, logical(1))
    body <- body[!null]
    charToRaw(paste(jsonlite::toJSON(body, auto_unbox = TRUE),collapse = "\n"))
    type <- "application/json"
  } else if (encode == "multipart") {
    #request(fields = lapply(body, as.character))
    fields <- lapply(body, as.character)
  }
  h <- curl::new_handle()

  options <- c(options, bodyOps)

  curl::handle_setopt(h, .list = options)

  if (!is.null(fields)) {
    curl::handle_setform(h, .list = fields)
  }

  headers <- c("Accept" = "application/json", "Content-Type" = type)
  curl::handle_setheaders(h, .list = headers)
  on.exit(expr = curl::handle_reset(h), add = TRUE)

  return(curl::curl_fetch_memory(url = mlUrl, handle = h))
}
