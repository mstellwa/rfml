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


