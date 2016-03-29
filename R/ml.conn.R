#' Creates a connection to a MarkLogic REST instance.
#'
#' The in order to use a database with rfml there needs to be a \href{http://docs.marklogic.com/guide/rest-dev/service#id_15309}{REST instance}
#' for that database with a \href{http://docs.marklogic.com/guide/admin/databases#id_38484}{module database}. The REST instance needs
#' to be created according to \href{http://docs.marklogic.com/guide/rest-dev/service#id_12021}{Creating a REST instance}.
#'
#' @param host Hostname or ip-adress of the MarkLogic REST instance. Default to localhost.
#' @param port Port number of the MarkLogic REST instance. 8000 is used default
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
