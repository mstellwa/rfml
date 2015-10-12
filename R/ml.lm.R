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
#' Creates a linear model
#'
#' Returns a linear model that fits the given data set. It only supports one term in the formula,
#' for example  y ~ x, as currently only simple linear regression model is supported.
#'
#' The function eliminates all pairs for which either the first field or the second field
#' is empty. After the elimination, if the length of the input is less than 2, the function
#' returns the empty sequence. After the elimination, if the standard deviation of the
#' independent variable is 0, the function returns a linear model with
#' intercept = the mean of the dependent variable, coefficients = NaN and r-squared = NaN.
#' After the elimination, if the standard deviation of the dependent variable is 0,
#' the function returns a linear model with r-squared = NaN.
#'
#' @param form an object of class "formula" (or one that can be coerced to that class): a symbolic description of the model to be fitted.
#' @param mlDf an ml.data.frame object

#' @export
ml.lm <- function(form, mlDf) {

  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  queryComArgs <- mlDf@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/LATEST/search", sep="")
  nPageLength <- mlDf@.nrows
  queryArgs <- c(queryComArgs, pageLength=nPageLength, transform="rfmlLm")

  #
  #addIntercept <- attr(terms(form, keep.order=T, data=data.frame(x=1)), "intercept")
  isResponse <- attr(terms(form, keep.order=T, data=data.frame(x=1)), "response")
  vars <- all.vars(form)
  if (length(vars) != 2) {
    stop("Can only use two variables!")
  }
  # below will return a tabel with all fields on the right to the  ~ as columnnames and
  # all variables as rownames
  tab1 <- attr(terms(form), "factors")
  # our independent variable is in the columnname
  independent <- colnames(tab1)
  # dependent
  dependent <- vars[isResponse]
  if (!(independent %in% mlDf@.col.name) && !(dependent %in% mlDf@.col.name)) {
    stop("Both variables must be part of ml.data.frame")
  }
  # need to very that they are number fields...

  fields <- "{"
  # check if dependent or independent is existing fields
  # or new, if new we ned to use the expersion
  if (is.null(mlDf@.col.defs[[dependent]])) {
    fieldDef <- dependent
  } else {
    fieldDef <- mlDf@.col.defs[[dependent]]
  }
  if (is.null(mlDf@.col.defs[[independent]])) {
    fieldDef <- independent
  } else {
    fieldDef <- mlDf@.col.defs[[independent]]
  }
  fields <- paste(fields, '"',dependent , '":{"fieldDef":"',fieldDef ,'"},"', independent, '":{"fieldDef":"',fieldDef ,'"}' ,sep='')
  fields <- paste(fields, '}', sep='')
  #message(fields)
  queryArgs <- c(queryArgs, 'trans:fields'=fields)

  response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())

  rContent <- content(response) #, as = "text""
  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  res <- list(intercept=rContent$`linear-model`$intercept, coefficients=rContent$`linear-model`$coefficients, rsquared=rContent$`linear-model`$rsquared)
  class(res) = c("mlLm")
  res
}
#' @export
print.mlLm <- function(x) {
  cat("intercept: ", x$intercept)
  cat("\ncoefficients: ", x$coefficients)
  cat("\nr-squared :", x$rsquared, "\n")
}
