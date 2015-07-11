#' rfml: a R wrapper for MarkLogic REST api
#'
#' @docType package
#' @name rfml
#' @import XML
#' @import httr
#' @import PKI
NULL

# A package specific enviroment, used to store the RSA key
rfml.env <- new.env(parent = emptyenv())

#' Creates a object of class "rfml"
#'
#' @param host Hostname or ipadress of the MarkLogic http server. Default to localhost.
#' @param port Port number of the MarkLogic http server. 8000 is used default
#' @param username Username. admin is default.
#' @param password Password admin is default.
#' @return If successful a rfml object to use in subsequent operations.
#' @examples
#' \dontrun{
#' rfml <- rfml_connect("localhost","8000", "admin", "admin")
#' }
#'
#' @export rfml_connect
# Maybe is it better to use rfml.connect and then also rfml.is.connected?
rfml_connect <- function(host = "localhost", port = "8000",
                        username = "admin", password = "admin") {

  # We encrypt the password before storing it in the list that is
  # visible for the package user.
  # The key is stored in a package specific enviroment, created at the top
  # of this file.
  RSAkey <- PKI::PKI.genRSAkey(2048)
  rfml.env$key <- RSAkey
  enc_pwd <- PKI::PKI.encrypt(charToRaw(password), RSAkey)
  mlHost <- paste("http://", host, ":", port, sep="")

  # TODO:
  # Check that we have required search options and transformations/modules installed
  if (!.check.database(mlHost, username, password)) {
    # TODO:Handle not finding the options compared with other http responses
    rfml.env$dbOk <- FALSE
    stop(paste("The database on ",mlHost, " is not set up to work with rfml. ",
               "Use init_database for setting up the database.", sep=""))
  }
  rfml <- list("host" = host, "port" = port, "username" = username,
                "password"= enc_pwd)

  # the database is ok to use
  rfml.env$dbOk <- TRUE
  return(rfml)
}
