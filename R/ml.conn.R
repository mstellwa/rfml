
#' Creates a connection to a MarkLogic REST server.
#'
#' @param host Hostname or ip-adress of the MarkLogic http server. Default to localhost.
#' @param port Port number of the MarkLogic http server. 8000 is used default
#' @param username Username. admin is default.
#' @param password Password admin is default.
#' @return Nothing if sucess, otherwise an error.
#' @examples
#' \dontrun{
#' library(rfml)
#' ml.connect("localhost","8000", "admin", "admin")
#'
#' @export
ml.connect <- function(host = "localhost", port = "8000",
                       username = "admin", password = "admin") {

  # We encrypt the password before storing it in the list
  # The key is stored in a package specific enviroment, created in the defs-pkg.R file
  RSAkey <- PKI::PKI.genRSAkey(2048)
  .rfmlEnv$key <- RSAkey
  enc_pwd <- PKI::PKI.encrypt(charToRaw(password), RSAkey)
  mlHost <- paste("http://", host, ":", port, sep="")

  # TODO:
  # Check that we have required search options and transformations/modules installed
  if (!.check.database(mlHost, username, password)) {
    # TODO:Handle not finding the options compared with other http responses
    .rfmlEnv$dbOk <- FALSE
    stop(paste("The database on ",mlHost, " is not set up to work with rfml. ",
               "Use init_database for setting up the database.", sep=""))
  }
  # the database is ok to use
  .rfmlEnv$dbOk <- TRUE
  .rfmlEnv$conn <- list("host" = host, "port" = port, "username" = username,
               "password"= enc_pwd)

  #return(rfml)
}
