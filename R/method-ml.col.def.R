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
#' @export
setMethod("as.vector", signature(x="ml.col.def"),
          function (x,mode="any") {
            #res <- idaQuery("SELECT ", x@term , " FROM ",x@table@table,ifelse(nchar(x@table@where), paste(" WHERE ", x@table@where), ""))
            #return(res[[1]])
            message("as.vector")
          }
)

as.ml.col.def <- function(x) {
  if(inherits(x,"ml.data.frame")) {
    return(paste('"rfmlResult.',x@.col.name[1],'"',sep=''))
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
#' @export
setMethod("Arith", signature(e1="ml.col.def",e2="ml.col.def"), function(e1, e2) {
  return(new(Class="ml.col.def",.expr=paste('(',as.ml.col.def(eval(e1)),.Generic,as.ml.col.def(eval(e2)),')',sep=''),.parent=e1@.parent,.type="expr",.aggType=aggType(e1,e2)));
})

#' @export
setMethod("Arith", signature(e1="ml.col.def", e2="ANY"), function(e1, e2) {
  return(new(Class="ml.col.def",.expr=paste('(', as.ml.col.def(eval(e1)),.Generic,as.ml.col.def(eval(e2)),')',sep=''),.parent=e1@.parent,.type="expr",.aggType=aggType(e1,e2)));
})

#' @export
setMethod("Arith", signature(e1="ANY", e2="ml.col.def"), function(e1, e2) {
  return(new(Class="ml.col.def",.expr=paste('(', as.ml.col.def(eval(e1)),.Generic,as.ml.col.def(eval(e2)),')',sep=''),.parent=e2@.parent,.type="expr",.aggType=aggType(e1,e2)));
})

################ Scalar functions ############################
#' @export
setMethod("Math",signature(x='ml.col.def'),function (x) {

  func <- switch(.Generic,
         abs='fn.abs',
         acos='math.acos',
         asin='Math.asin',
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

  return(new(Class="ml.col.def",.expr=paste(func, '(', as.ml.col.def(eval(x)),')',sep=''),.parent=x@.parent,.type="expr",.aggType=aggType(x)));
});

################ Casting operators ############################
setMethod('as.numeric',signature(x="ml.col.def"),function (x) {
  #checkLogical(F,x);
  return(new(Class="ml.col.def",.exor=paste('CAST(',as.ml.col.def(eval(x)),' AS DOUBLE)',sep=''),.parent=x@.parent,.type="expr",.aggType=aggType(x)));
})

setMethod('as.character',signature(x="ml.col.def"),function (x) {
  #checkLogical(F,x);
  return(new(Class="ml.col.def",.expr=paste('CAST(',as.ml.col.def(x),' AS VARCHAR(100))',sep=''),.parent=x@.parent,.type="expr",.aggType=aggType(x)));
})

setMethod('as.integer',signature(x="ml.col.def"),function (x) {

  #checkLogical(F,x);
  return(new(Class="ml.col.def",.expr=paste('parseInt(',as.ml.col.def(eval(x)),' )',sep=''),.parent=x@.pranet,.type="expr",.aggType=aggType(x)));
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
