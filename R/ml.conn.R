#' Creates a connection to a MarkLogic REST server.
#'
#' @param host Hostname or ip-adress of the MarkLogic http server. Default to localhost.
#' @param port Port number of the MarkLogic http server. 8000 is used default
#' @param username Username. admin is default.
#' @param password Password admin is default.
#' @return A ml.conn object.
#' @examples
#' \dontrun{
#' library(rfml)
#' locConn <- ml.connect("localhost","8000", "admin", "admin")
#'}
#' @export
ml.connect <- function(host = "localhost", port = "8000",
                       username = "admin", password = "admin") {

  # We encrypt the password before storing it in the list
  # The key is stored in a package specific enviroment, created in the defs-pkg.R file
  RSAkey <- PKI::PKI.genRSAkey(2048)
  keyInd <- length(.rfmlEnv$key) + 1L
  connUUID <- .uuid()
  #.rfmlEnv$key <- c(.rfmlEnv$key, RSAkey)
  .rfmlEnv$key[[connUUID]] <- RSAkey
  enc_pwd <- PKI::PKI.encrypt(charToRaw(password), RSAkey)
  mlHost <- paste("http://", host, ":", port, sep="")

  # Check that we have required search options and transformations/modules installed
  mlVersion <- .check.database(mlHost, username, password)

  # the database is ok to use
  .rfmlEnv$dbOk <- TRUE
  mlConn <- new("ml.conn")
  mlConn@.id <- connUUID
  mlConn@.host<-host
  mlConn@.port<-port
  mlConn@.mlversion <- mlVersion
  mlConn@.username <- username
  mlConn@.password <- enc_pwd
  return(mlConn)

}
#' @export
ml.disconnect <- function(mlConnection) {

  .rfmlEnv$key[[mlConnection@.id]] <- NULL
  # mlConnection <- NULL
  mlConnection@.id <- NULL
  mlConnection@.host <- NULL
  mlConnection@.port <- NULL
  mlConnection@.mlversion <- NULL
  mlConnection@.username <- NULL
  mlConnection@.password <- NULL

}
