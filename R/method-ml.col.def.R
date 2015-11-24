
############## General ######################
#' @export
setMethod("print", signature(x="ml.col.def"),
          function (x) {
            cat(paste("Column definition: ", x@.expr, " parent: ",x@.parent@.name ," \n Use this to define new columns on a ml.data.frame using the $ operator. To select a subset of a table, use bldf[] notation. "),"\n")
          }
)
#' @export
setMethod("show", signature(object="ml.col.def"),
          function (object) {
            cat(paste("Column definition: ", object@.expr, " parent: ",object@.parent@.name ," \n Use this to define new columns on a ml.data.frame using the $ operator. To select a subset of a table, use bldf[] notation. "),"\n")
          }
)
# Not used!
setMethod("as.vector", signature(x="ml.col.def"),
          function (x,mode="any") {
            #res <- idaQuery("SELECT ", x@term , " FROM ",x@table@table,ifelse(nchar(x@table@where), paste(" WHERE ", x@table@where), ""))
            #return(res[[1]])
            message("as.vector")
          }
)

as.ml.col.def <- function(x) {
  if(inherits(x,"ml.data.frame")) {
    return(paste('"rfmlResult[\'',x@.col.name[1],'\']"',sep=''))
  } else if(inherits(x,"ml.col.def")) {
    return(x@.expr)
  } else {
    if(is.character(x)) {
      return(paste("'",x,"'",sep=''))
    } else {
      return(as.character(x))
    }
  }
}

################ Arithmetic operators ############################
# + x
# - x
# x + y
# x - y
# x * y
# x / y
# x ^ y
# x %% y
# x %/% y
#' @export
setMethod("Arith", signature(e1="ml.col.def",e2="ml.col.def"), function(e1, e2) {
  if(e1@.parent@.name!=e2@.parent@.name) {
    stop("Cannot combine two columns from different ml.data.frames.")
  }
  # need to check the data types of
  if (e1@.data_type == e2@.data_type) {
    dataType = e1@.data_type
  } else {
    # we only use string and number, so if they are not same we fall back to string
    dataType = "string"
  }
  return(new(Class="ml.col.def",.expr=paste('(',as.ml.col.def(eval(e1)),.Generic,as.ml.col.def(eval(e2)),')',sep=''),.data_type=dataType,.parent=e1@.parent,.type="expr",.aggType=aggType(e1,e2)));
})

#' @export
setMethod("Arith", signature(e1="ml.col.def", e2="ANY"), function(e1, e2) {
  if (!(is.numeric(e2)) || e1@.data_type == "string") {
    dataType <- "string"
  } else {
    dataType <- "number"
  }
  return(new(Class="ml.col.def",.expr=paste('(', as.ml.col.def(eval(e1)),.Generic,as.ml.col.def(eval(e2)),')',sep=''),.data_type=dataType,.parent=e1@.parent,.type="expr",.aggType=aggType(e1,e2)));
})

#' @export
setMethod("Arith", signature(e1="ANY", e2="ml.col.def"), function(e1, e2) {
  if (!(is.numeric(e1)) || e2@.data_type == "string") {
    dataType <- "string"
  } else {
    dataType <- "number"
  }
  return(new(Class="ml.col.def",.expr=paste('(', as.ml.col.def(eval(e1)),.Generic,as.ml.col.def(eval(e2)),')',sep=''),.data_type=dataType,.parent=e2@.parent,.type="expr",.aggType=aggType(e1,e2)));
})

################ Scalar functions ############################
# Math functions, the following is included in Math:
# abs, sign, sqrt, floor, ceiling, trunc, round, signif,
# exp, log, expm1, log1p,cos, sin, tan,cospi, sinpi, tanpi,
# acos, asin, atan, cosh, sinh, tanh, acosh, asinh, atanh,
# lgamma, gamma, digamma, trigamma, cumsum, cumprod, cummax, cummin,
#
# We only currently support part of these, se below.
#' @export
setMethod("Math",signature(x='ml.col.def'),function (x) {

  func <- switch(.Generic,
         abs='fn.abs',
         acos='math.acos',
         asin='math.asin',
         atan='math.atan',
         ceiling='math.ceil',
         cos='math.cos',
         cosh='math.cosh',
         exp='math.exp',
         floor='math.floor',
         log='math.log',
         log10='math.log10',
         tan='math.tan',
         tanh='math.tanh',
         sqrt='math.sqrt',
         sin='math.sin',
         trunc='math.trunc',
        stop(paste(.Generic, " not supported"))
  )

  return(new(Class="ml.col.def",.expr=paste(func, '(', as.ml.col.def(eval(x)),')',sep=''),.parent=x@.parent,.data_type="number",.type="expr",.aggType=aggType(x)));
});

#' @export
################ Casting operators ############################
setMethod('as.numeric',signature(x="ml.col.def"),function (x) {
  #checkLogical(F,x);
  return(new(Class="ml.col.def",.exor=paste('Number(',as.ml.col.def(eval(x)),')',sep=''),.parent=x@.parent,.data_type="number",.type="expr",.aggType=aggType(x)));
})

setMethod('as.character',signature(x="ml.col.def"),function (x) {
  #checkLogical(F,x);
  return(new(Class="ml.col.def",.expr=paste('String(',as.ml.col.def(x),')',sep=''),.parent=x@.parent,.data_type="string",.type="expr",.aggType=aggType(x)));
})

#' @export
setMethod('as.integer',signature(x="ml.col.def"),function (x) {

  #checkLogical(F,x);
  return(new(Class="ml.col.def",.expr=paste('parseInt(',as.ml.col.def(eval(x)),' )',sep=''),.parent=x@.parent,.data_type="number",.type="expr",.aggType=aggType(x)));
})

################ Utilities ############################

aggType <- function(...) {

  args = list(...);

  for(i in 1:length(args)) {
    if(inherits(args[[i]],'ml.col.def')) {
      if(args[[i]]@.aggType=="simple") {
        return("simple")
      }
    }
  }
  return("none");
}
