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
## -----------------------------------------------------------------------
## Private variables of the package
## -----------------------------------------------------------------------

# A package specific enviroment, used to store the RSA key and connection info
.rfmlEnv <- new.env()

setClass("ml.data.frame",
         slots=c(
           .name="character", # the name of the data frame result
           .qtext="character", # the search that defines the data frame
           .ctsQuery="json", #the cts query for the data frame.
           .queryArgs="list", #parameters used to query ML
           .nrows="integer",  # the number of rows in the result
           .col.name="character", # column names
           .col.data_type = "character", # column types
           .col.defs = "list"
          )
    )
#Column expressions
setClass("ml.col.def",
         slots=c(.expr="character",
                 .parent="ml.data.frame",
                 .type = "character", # column types
                 .name = "character",
                 .data_type = "character",
                 .aggType="character"
                )
         )
