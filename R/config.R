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

#' Set up a MarkLogic database for use with rfml.
#'
#' The function installs search options and transformations/mdoules that is needed
#' in order to use the package. You only needed to run it once for each database.
#'
#' The database must have a REST server and a module database.
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
#' ml.init.database("localhost", "8000", "admin", "admin")
#' }
#' @export
ml.init.database <- function(host = "localhost", port = "8000", adminuser = "admin", password = "admin") {
  # general URL, used as basis for all
  mlHost <- paste("http://", host, ":", port, sep="")
  mlTransforms <- c("rfmlTransform", "rfmlLm", "rfmlStat")

  # install the needed search options
  if (.insert.search.options(mlHost, adminuser, password, "rfml")) {
    message(paste("Options rfml is now installed on ", host, ":", port, sep=""))
  }
  # install the needed module library
  if (.insert.lib(mlHost, adminuser, password, "rfmlUtilities")) {
    message(paste("Library rfmlUtilities is now installed on ", host, ":", port, sep=""))
  }
  # install needed transforms
  for (i in 1:length(mlTransforms)) {
    if (.insert.search.transform(mlHost, adminuser, password, mlTransforms[i])) {
      message(paste("Transformation ",mlTransforms[i], " is now installed on ", host, ":", port, sep=""))
    }
  }

  message(paste(host, ":", port, " is now ready for use with rfml",sep=""))
}
