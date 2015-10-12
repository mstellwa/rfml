# Copyright (c) 2015 All rights reserved.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

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
#'}
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
