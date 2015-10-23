# Various statistics methods

#' Correlation
#'
#' Returns the Pearson correlation coefficient of a data set. The size of the input
#' should be 2.
#'
#' The function eliminates all pairs for which either the first element or the second
#' element is empty. After the elimination, if the length of the input is less than 2,
#' the function returns the empty sequence. After the elimination, if the standard
#' deviation of the first column or the standard deviation of the second column is 0,
#' the function returns the empty sequence.
#'
#' @param x a ml.data.frame field.
#' @param y a ml.data.frame field
#' @return The correlation coefficient
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  mlDf <- ml.data.frame("corvette NEAR/1 convertible", collection = c("Analytics"))
#'  # return the correlation
#'  cor(mlDf$orderLines1quantityOrdered, mlDf$orderLines1priceEach)
#' }
#' @export
setMethod(f="cor", signature=c(x="ml.col.def",y="ml.col.def"),

          function(x,y,use = NULL,method = NULL ) {

            # use
            if (!missing(use) && !is.null(use))
             stop(simpleError("use option is not implemented yet"))

             # method
            if (!missing(method) && !is.null(method))
               stop(simpleError("method option is not implemented yet"))

            if(x@.parent@.name!=y@.parent@.name) {
               stop("Cannot combine two columns from different ml.data.frames.")
            }
            if(x@.data_type!="number" || y@.data_type != "number") {
              stop("Can only use columns of number type")
            }

            fields <- "{"
            fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"},"', y@.name, '":{"fieldDef":"',y@.expr ,'"}' ,sep='')
            fields <- paste(fields, '}', sep='')
            func <- "math.correlation"
            return(.ml.stat.func(x@.parent, fields, func))
        }
)
# correlation matrix on all numeric columns in a ml.col.def
setMethod(f="cor", signature=c(x="ml.col.def"),

          function(x,y = NULL,use = NULL,method = NULL ) {

            # use
            if (!missing(use) && !is.null(use))
              stop(simpleError("use option is not implemented yet"))

            # method
            if (!missing(method) && !is.null(method))
              stop(simpleError("method option is not implemented yet"))


            fields <- "{"
            fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"},"', y@.name, '":{"fieldDef":"',y@.expr ,'"}' ,sep='')
            fields <- paste(fields, '}', sep='')
            func <- "math.correlation"
            return(.ml.stat.func(x@.parent, fields, func))
          }
)
#' Covariance
#'
#' Returns the sample covariance of a data set.
#'
#'The function eliminates all pairs for which either the first element or the second
#'element is empty. After the elimination, if the length of the input is less than 2,
#'the function returns the empty sequence.
#'
#' @param x a ml.data.frame field.
#' @param y a ml.data.frame field
#' @return The sample covariance
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  mlDf <- ml.data.frame("corvette NEAR/1 convertible", collection = c("Analytics"))
#'  # return the Covariance
#'  cov(mlDf$orderLines1quantityOrdered, mlDf$orderLines1priceEach)
#' }
#' @export
setMethod(f="cov", signature=c(x="ml.col.def",y="ml.col.def"),

          function(x,y,use = NULL,method = NULL ) {

            # use
            if (!missing(use) && !is.null(use))
              stop(simpleError("use option is not implemented yet"))

            # method
            if (!missing(method) && !is.null(method))
              stop(simpleError("method option is not implemented yet"))

            if(x@.parent@.name!=y@.parent@.name) {
              stop("Cannot combine two columns from different ml.data.frames.")
            }
            if(x@.data_type!="number" || y@.data_type != "number") {
              stop("Can only use columns of number type")
            }

            fields <- "{"
            fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"},"', y@.name, '":{"fieldDef":"',y@.expr ,'"}' ,sep='')
            fields <- paste(fields, '}', sep='')
            func <- "math.covariance"
            return(.ml.stat.func(x@.parent, fields, func))
          }
)

#' Population Covariance
#'
#' Returns the population covariance of a data set.
#'
#' The function eliminates all pairs for which either the first element or the
#' second element is empty. After the elimination, if the length of the input is 0,
#' the function returns the empty sequence.
#'
#' @param x a ml.data.frame field.
#' @param y a ml.data.frame field
#' @return The population covariance
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  mlDf <- ml.data.frame("corvette NEAR/1 convertible", collection = c("Analytics"))
#'  # return the Covariance
#'  cov.pop(mlDf$orderLines1quantityOrdered, mlDf$orderLines1priceEach)
#' }
#' @export
cov.pop <- function(x,y) {

  if(x@.parent@.name!=y@.parent@.name) {
    stop("Cannot combine two columns from different ml.data.frames.")
  }
  if(x@.data_type!="number" || y@.data_type != "number") {
    stop("Can only use columns of number type")
  }

  fields <- "{"
  fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"},"', y@.name, '":{"fieldDef":"',y@.expr ,'"}' ,sep='')
  fields <- paste(fields, '}', sep='')
  func <- "math.covarianceP"
  return(.ml.stat.func(x@.parent, fields, func))
}

#' Variance
#'
#' Returns the sample variance of a sequence of values.
#'
#' The function returns a empty value if the number of rows of the ml.data.frame
#' that x belongs to is less than 2.
#'
#' @param x a ml.data.frame field.
#' @return The sample variance
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  mlDf <- ml.data.frame("corvette NEAR/1 convertible", collection = c("Analytics"))
#'  # return the Covariance
#'  var(mlDf$orderLines1quantityOrdered)
#' }
#' @export
setMethod(f="var", signature=c(x="ml.col.def"),

          function(x,na.rm = FALSE ) {

            # use
            if (na.rm )
              stop(simpleError("na.rm option is not implemented yet"))

            if(x@.data_type!="number") {
              stop("Can only use columns of number type")
            }

            fields <- "{"
            fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"}' ,sep='')
            fields <- paste(fields, '}', sep='')
            func <- "math.variance"
            return(.ml.stat.func(x@.parent, fields, func))
          }
)

#' Population variance
#'
#' Returns the population variance of a sequence of values.
#'
#' The function returns a empty value if the number of rows of the ml.data.frame
#' that x belongs to is less than 2.
#'
#' @param x a ml.data.frame field.
#' @return The sample variance
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  mlDf <- ml.data.frame("corvette NEAR/1 convertible", collection = c("Analytics"))
#'  # return the Covariance
#'  var.pop(mlDf$orderLines1quantityOrdered)
#' }
#' @export
var.pop <- function(x,na.rm = FALSE ) {

  # use
  if (na.rm )
    stop(simpleError("na.rm option is not implemented yet"))

  if(x@.data_type!="number") {
    stop("Can only use columns of number type")
  }

  fields <- "{"
  fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"}' ,sep='')
  fields <- paste(fields, '}', sep='')
  func <- "math.varianceP"
  return(.ml.stat.func(x@.parent, fields, func))
}

#' Standard Deviation
#'
#' Returns the sample standard deviation of a sequence of numeric values.
#'
#' The function returns a empty value if the number of rows of the ml.data.frame
#' that x belongs to is less than 2.
#'
#' @param x a ml.data.frame field.
#' @return The sample standard deviation
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  mlDf <- ml.data.frame("corvette NEAR/1 convertible", collection = c("Analytics"))
#'  # return the Covariance
#'  sd(mlDf$orderLines1quantityOrdered)
#' }
#' @export
setMethod(f="sd", signature=c(x="ml.col.def"),
          function(x,na.rm=NULL) {

            # na.rm
            if (!missing(na.rm) && !is.null(na.rm))
              warning(simpleError("na.rm option is not implemented yet"))

            if(nrow(x@.parent)==0) {
              stop("No rows in ml.data.frame.")
            }
            if(x@.data_type!="number") {
              stop("Can only use columns of number type")
            }

            fields <- "{"
            fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"}', sep='')
            fields <- paste(fields, '}', sep='')
            func <- "math.stddev"
            return(.ml.stat.func(x@.parent, fields, func))

          }
)

#' Standard Deviation of a population
#'
#' Returns the sample standard deviation of a population.
#'
#' @param x a ml.data.frame field.
#' @return The sample standard deviation
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  mlDf <- ml.data.frame("corvette NEAR/1 convertible", collection = c("Analytics"))
#'  # return the Covariance
#'  sd.pop(mlDf$orderLines1quantityOrdered)
#' }
#' @export
sd.pop <- function(x) {

  if(nrow(x@.parent)==0) {
    stop("No rows in ml.data.frame.")
  }
  if(x@.data_type!="number") {
    stop("Can only use columns of number type")
  }

  fields <- "{"
  fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"}', sep='')
  fields <- paste(fields, '}', sep='')
  func <- "math.stddev"
  return(.ml.stat.func(x@.parent, fields, func))

}


#' @export
setMethod(f="median", signature=c(x="ml.col.def"),

          function(x, na.rm = FALSE) {

            # use
            if (na.rm)
              warning(simpleError("na.rm option is not implemented yet"))

            if(x@.data_type!="number") {
              stop("Can only use columns of number type")
            }

            fields <- "{"
            fields <- paste(fields, '"',x@.name , '":{"fieldDef":"',x@.expr ,'"}', sep='')
            fields <- paste(fields, '}', sep='')
            func <- "math.median"
            return(.ml.stat.func(x@.parent, fields, func))
          }
)
