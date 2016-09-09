###############################################################################
# Internal functions for curl usage
###############################################################################

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

.list2object <-  function(from, to) {
  if (!length(from)) return(new(to))
  s <- slotNames(to)
  p <- pmatch(names(from), s)
  if(any(is.na(p))) stop(paste("\nInvalid parameter:",
                               paste(names(from)[is.na(p)], collapse=" ")), call.=FALSE)
  names(from) <- s[p]
  do.call("new", c(from, Class = to))
}

# escapes the query string so it can be used with curl...
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

# function for calling curl::curl
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

# function for calling curl::curl using body in call
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
