.get.ml.rowcount <- function(mlDf) {
  conn <- mlDf@.conn
  key <- .rfmlEnv$key[[conn@.id]]
  password <- tryCatch(rawToChar(PKI::PKI.decrypt(conn@.password, key))
                       , error = function(err) stop("Need a valid connection. Use ml.connection to create one!"))
  username <- conn@.username
  queryArgs <- c(mlDf@.queryArgs, 'rs:return'="rowCount")

  mlHost <- paste("http://", conn@.host, ":", conn@.port, sep="")
  mlSearchURL <- paste0(mlHost, "/v1/resources/rfml.dframe")

  response <- .curl("GET",mlSearchURL, queryArgs, username, password)

  # get the content
  rContent <- .content(response)

  if(response$status_code != 200) {
    errorMsg <- paste0("statusCode: ",
                       rContent$errorResponse$statusCode,
                       ", status: ", rContent$errorResponse$status,
                       ", message: ", rContent$errorResponse$message)
    stop(paste0("Ops, something went wrong.", errorMsg))
  }
  return(rContent)

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
    qryStr <- .fixQuery(queryArgs)
    mlUrl <- paste0(mlUrl,"?", qryStr)
    userpwd <- paste0(username, ":",password)
    httpauth <- 2
    options <- list(httpauth = httpauth, userpwd=userpwd)
    h <- curl::new_handle()
    curl::handle_setopt(h, .list = options)
    headers <- c("Accept" = "application/json")
    curl::handle_setheaders(h, .list = headers)
    on.exit(expr = curl::handle_reset(h), add = TRUE)

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

