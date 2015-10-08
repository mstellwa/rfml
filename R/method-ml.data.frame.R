#' Create a ml.data.frame object
#'
#' This function creates an object of ml.data.frame, it is based on a search done using
#' provided query. The operations that can be applied onto this class of objects are very
#' similar to those of data.frame. No real data is loaded into R. The data transfered
#' between MarkLogic Server and R is minimized.
#'
#' @param query The query string used to define the result.
#' @param collection A list of collection URI:s to filter on.
#' @param directory A list of directory URI:s to filter on.
#' @return A ml.data.frame object.
#' @examples
#' \dontrun{
#'  library(rfml)
#'  ml.connect("localhost", "8000", "admin", "admin")
#'  # create a ml.data.frame based on a search
#'  df <- ml.data.frame("försäkringskassan AND kalle")
#'  # using search and collection filtering
#'  df <- ml.data.frame("försäkringskassan AND kalle", collection=c("Analytics"))
#'  # using only collection filtering
#'  df <- ml.data.frame(collection=c("Analytics"))
#' }
#' @export
ml.data.frame <- function (query="", collection = c(), directory = c())
{
  if (length(.rfmlEnv$conn) != 4) {
    stop("Need create a connection object. Use rfml.connect first.")
  }
  # Check if we are using query or collection

  # fields?

  # get data from ML
  # we need to create a "unique" name for the frame that we use to save the resultset
  dframe <- format(Sys.time(),"%Y%m%d%H%M%S")
  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/LATEST/search", sep="")
  mlOptions <- "rfml"
  nStart=1
  nPageLength=20
  # These are the arguments that are common to all calls to MarkLogic
  queryComArgs <- list(q=query, options=mlOptions, start=nStart, format="json")

  # need to build a structuredQuery in order to get the collection/directory filtering
  # as part of the returned query.
  if (length(collection) > 0) {
    strColl <- ''
    for (i in 1:length(collection)) {
      if (i>1) {
        strColl <- paste(strColl, ',', sep='')
      }
      strColl <- paste(strColl, collection[i], sep='')
    }
    queryComArgs <- c(queryComArgs, collection=strColl)
  }
  if (length(directory) > 0) {
    strDir <- ''
    for (i in 1:length(directory)) {
      if (i>1) {
        strDir <- paste(strDir, ',', sep='')
      }
      strDir <- paste(strDir, directory[i], sep='')
    }
    queryComArgs <- c(queryComArgs, directory=strDir)
  }

#   if (length(collection) > 0 || length(directory) > 0) {
#     collQry <- ''
#     dirQry <- ''
#     structQry <- '{"query":{"queries":['
#     if (length(collection) > 0) {
#       collQry <- '{"collection-query":{"uri":['
#       for (i in 1:length(collection)) {
#         if (i>1) {
#           collQry <- paste(collQry,',' ,sep='')
#         }
#         collQry <- paste(collQry,'"',collection[i],'"' ,sep='')
#       }
#       collQry <- paste(collQry,"]}}", sep='')
#     }
#     if (length(directory) > 0) {
#       dirQry <- '{"directory-query": {"uri": ['
#       for (i in 1:length(directory)) {
#         if (i>1) {
#           dirQry <- paste(dirQry,',' ,sep='')
#         }
#         dirQry <- paste(dirQry,'"',directory[i],'"' ,sep='')
#       }
#       dirQry <- paste(dirQry,"]}}", sep='')
#     }
#     if (nchar(collQry) > 0 && nchar(dirQry) > 0){
#       structQry <- paste(structQry, '{"and-query":[', collQry, ',', dirQry,']}', sep='')
#     } else {
#       structQry <- paste(structQry,ifelse(nchar(collQry) > 0, collQry, dirQry), sep='')
#     }
#     structQry <- paste(structQry, ']}}', sep='')
#     queryArgs <- c(queryArgs, structuredQuery=structQry)
#   }

  queryArgs <- c(queryComArgs, pageLength=nPageLength, transform="rfmlTransform", 'trans:dframe'=dframe,
                 'trans:return'="meta")
  # do a search
  response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())

  # get the content
  rContent <- content(response)

  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }
  if (rContent$nrows == 0) {
    stop("Search did not produce any result");
  }

  res <- new("ml.data.frame")
  res@.name <- dframe
  res@.qtext <- query
  res@.ctsQuery <- toJSON(rContent$ctsQuery)
  res@.queryArgs <- queryComArgs
  res@.nrows <- as.integer(rContent$nrows)
  fieldList <- rContent$dataFrameFields
  fieldNames <- c()
  fieldTypes <- c()
  for (i in 1:length(fieldList)) {
    fieldNames[i] <-  as.character(attributes(fieldList[i]))
    fieldTypes[i] <- fieldList[[i]]$fieldType
  }
  res@.col.name <- fieldNames
  res@.col.data_type <- fieldTypes
  res@.col.defs <- list()
  return(res);

}

################ Generic methods for upload and download of data ############################

# ---------------------------------------------------------------------
# Will pull the data from MarkLogic and return it as a data.frame
#' @export
setMethod("as.data.frame", signature(x="ml.data.frame"),
          function (x, max.rows=NULL, ...) {
            if (is.null(max.rows)) {
              max.rows <- 0
            }
            result <- return(.get.ml.data(x,max.rows))
          }
)
################ Sub data frames ############################
# Not used!
setMethod("[", signature(x = "ml.data.frame"),
          function (x, i=NULL, j=NULL, ..., drop=NA)
          {
            c <- c()
            # check arguments - columns
            if (try(!is.null(j),silent=TRUE) == TRUE) {
              if (is.numeric(j))
                c <- c(c,as.integer(j))
              else if (!is.integer(j))
                if (is.character(j)){

                  for (n in j){
                    if (is.element(n, x@.col.name))
                      c <- c(c, which(names(x)==n))
                    else
                      if (is.element(tolower(n), x@.col.name))
                        stop(paste("No column named ", n, " in the table. Column names are case-sensitive. Did you mean ", tolower(n), "?"))
                    else if (is.element(toupper(n), x@.col.name))
                      stop(paste("No column named ", j, " in the table. Column names are case-sensitive. Did you mean ", toupper(n), "?"))
                    else stop(paste("No column named ", n, " in the table. Column names are case-sensitive."  , "."))

                  }
                }
              else
                stop("columns argument must be integer or character")
            }
            # check arguments i (row)

            if(!missing(i)) {
              if (tryCatch(!is.null(i),error = function(e) {print(e);print("Sub set selection could not be created, the left-hand side of the expression must be a column reference, the right-hand side must be a value or a column reference in the same table.")}) == TRUE) {
                if (is.numeric(i))
                  stop("row numbering is not allowed")
                else if (class(i)=="ida.col.def") {
                  if((i@table@table != x@table)||(i@table@where!=x@where))
                    stop("Cannot apply condition to columns not in the base table.")

                  if(i@type!='logical')
                    stop("Column expression must resolve into a boolean value for row selection.")
                  newRowSelection <- i@term;
                }
                else if (class(i) == "ida.data.frame.rows")
                  newRowSelection <- i@where
                else
                  stop("row object does not specify a subset")

                if (is.null(x@where) || !nchar(x@where))
                  x@where <- newRowSelection
                else
                  x@where <- paste("(", x@where, ") AND (", newRowSelection, ")", sep="")
              }}
            # compute the right subset of columns
            if (!is.null(x@cols) && !is.null(c))
              x@cols <- x@cols[c]
            # i variable has to be of a special class "ida.data.frame.rows"
            return(x)
          }
)

# ---------------------------------------------------------------------
#' @export
setMethod("$", signature(x = "ml.data.frame"),
          function(x, name) {
            if(!(name %in% x@.col.name)) {
              stop("Column not found in ml.data.frame.")
            }
            if(is.null(x@.col.defs[[name]])) {
              return(new(Class="ml.col.def",.expr=paste("rfmlResult.",name, sep=''),.parent=x,.type="field",.aggType="none"));
            } else {
              return(new(Class="ml.col.def",.expr=x@.col.defs[[name]],.parent=x,.type="expr",.aggType="none"));
            }

          }
)

#' @export
setMethod("$<-", signature(x = "ml.data.frame"),
          function(x, name,value) {
             if(is.null(value)) {
               #remove col def
               if(!is.null(x@.col.defs[[name]])) {
                 x@.col.efs[[name]] <- NULL;
               }
               x@.col.name <- setdiff(x@.col.name,name)
             } else {
               if(!inherits(value,"ml.col.def"))
                 stop("Column definition is not valid for a ml.data.frame, please refer to the documentation of ml.data.frame for details on usage.")
               if(((value@.parent)@.name != x@.name))
                stop("Column defintions are only allowed on the same ml.data.frame.");

               if(value@.aggType!='none') {
                 stop("Cannot add column that contains aggregation term to ml.data.frame.")
               }
               # if we are refering an existing column ie x$field
               # then value is the defenition of that field.

               x@.col.defs[[name]]<-value@.expr;
               if(!(name %in% x@.col.name)) {
                 x@.col.name<-c(x@.col.name,name);
               }
              }

            return(x);
          }
)

#' Check if an object is of type ml.data.frame
#'
#' This function checks if the input is of type ml.data.frame.
#'
#' @param x The input can be of any type.
#' @return True if it is a ml.data.fram object. False otherwise.
#' @examples
#' \dontrun{
#'
#' }
#' @export
is.ml.data.frame <-
  function(x) {
    return(inherits(x, "ml.data.frame"))
  }

#' @export
setMethod("dim", signature(x="ml.data.frame"),
          function(x) {
              return(c(x@.nrows, length(x@.col.name)))
          }
)

#' @export
setMethod("colnames", signature(x="ml.data.frame"),
          function(x) { x@.col.name }
)
#' @export
setMethod("head", signature(x="ml.data.frame"),
          function(x, n = 6, ...) {
            if (length(.rfmlEnv$conn) != 4) {
              stop("Need create a connection object. Use rfml.connect first.")
            }
            if (n >= 0) {
              return(.get.ml.data(x,n))
            } else {
              #nr <- nrow(x)
              #n <- abs(n)
              #ans <- idaQuery(idadf.query(x), " FETCH FIRST ", format(nr - n, scientific = FALSE), " ROWS ONLY")

              #if ((nr-n) != 0) rownames(ans) <- 1:(nr-n);
              #return(ans)
            }
          }
)

################ Basic ml.data.frame functions and methods ############################
#' @export
setMethod("print", signature(x="ml.data.frame"),
          function (x) {
            cat(object@.ctsQuery,"\n")
          }
)
#' @export
setMethod("show", signature(object="ml.data.frame"),
          function (object) {
            cat(object@.ctsQuery,"\n")
          }
)

# ---------------------------------------------------------------------
#' @export
setMethod("names", signature(x="ml.data.frame"),
          function(x) { return(x@.col.name) }
)

