#' Set up a MarkLogic database for use with rfml.
#'
#' The function installs search options and transformations/mdoules that is needed
#' in order to use the package. You only needed to run it once for each database.
#'
#' The database needs to have a REST server and a module database.
#'
#' The user that is used for the login must have the  rest-admin role,
#' or the following privileges:
#'     http://marklogic.com/xdmp/privileges/rest-admin,
#'     http://marklogic.com/xdmp/privileges/rest-writer,
#'     http://marklogic.com/xdmp/privileges/rest-reader
#'
#' @param host The hostname or ipadress of the MarkLogic http server. Default to localhost.
#' @param port The port number of the MarkLogic http server. 8000 is used default
#' @param adminuser The username of a user that have rights to install options. admin is default.
#' @param password The password admin is default.
#' @return The function will raise a error...
#' @examples
#' \dontrun{
#' init_database("localhost", "8000", "admin", "admin")
#' }
#' @export init_database
init_database <- function(host = "localhost", port = "8000", adminuser = "admin", password = "admin") {
  # general URL, used as basis for all
  mlHost <- paste("http://", host, ":", port, sep="")

  # install the needed search options
  mlSearchOpName <- .insert.search.options(mlHost, adminuser, password)
  message(paste("Installed ", mlSearchOpName, " in ", host, ":", port, sep=""))

  # install transformations

  # install modules

  message(paste(host, ":", port, " is now ready for use with rfml",sep=""))
}
