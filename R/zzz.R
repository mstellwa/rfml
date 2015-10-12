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

.onLoad <- function(libname, pkgname) {
  .rfmlEnv$dbOk <- FALSE

}

.onAttach <- function(libname, pkgname) {
  packageStartupMessage("rfml package")
}

.onUnload <- function(libpath) {
  # clean up the enviroment
  #rm(list = ls(), envir = rfml.env)

}
