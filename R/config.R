#' Set up a MarkLogic database for use with rfml.
#'
#' The function installs \href{http://docs.marklogic.com/guide/rest-dev/extensions}{REST extensions} and
#' modules needed to use the package. You only needed to run it once for each database.
#'
#' The database must have a \href{http://docs.marklogic.com/guide/admin/http}{REST server}
#' and a \href{http://docs.marklogic.com/guide/admin/databases#id_38484}{module database}.
#'
#' The user that is used for the login must have the  rest-admin role,
#' or at least the following privileges:
#' \itemize{
#'  \item http://marklogic.com/xdmp/privileges/rest-admin
#'  \item http://marklogic.com/xdmp/privileges/rest-writer
#'  \item http://marklogic.com/xdmp/privileges/rest-reader
#'  }
#'
#' @param host The hostname or ip-adress of the MarkLogic http server. Default to localhost.
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
  # name of libs used
  mlLibs <- .rfmlEnv$mlLibs
  # name of extensions used
  mlExts <- .rfmlEnv$mlExts

 for (i in 1:length(mlLibs)) {
  # install the needed module library
    if (.insert.lib(mlHost, adminuser, password, mlLibs[i])) {
      message(paste("Library ",mlLibs[i] ," is now installed on ", host, ":", port, sep=""))
    }
  }

  for (i in 1:length(mlExts)) {
    if (.insert.ext(mlHost, adminuser, password, mlExts[i])) {
      message(paste("REST extension ",mlExts[i], " is now installed on ", host, ":", port, sep=""))
    }
  }
  closeAllConnections()
  # need to store the current version of rfml
  # packageVersion("rfml")
  message(paste(host, ":", port, " is now ready for use with rfml",sep=""))
}

#' Remove all rfml internal files in a MarkLogic database.
#'
#' The function removes search options, transformations and mdoules that is needed
#' in order to use the package.
#'
#' The database must have a REST server and a module database.
#'
#' The user that is used for the login must have the  rest-admin role,
#' or the following privileges:
#' \itemize{
#'  \item http://marklogic.com/xdmp/privileges/rest-admin
#'  \item http://marklogic.com/xdmp/privileges/rest-writer
#'  \item http://marklogic.com/xdmp/privileges/rest-reader
#'  }
#'
#' @param host The hostname or ipadress of the MarkLogic http server. Default to localhost.
#' @param port The port number of the MarkLogic http server. 8000 is used default
#' @param adminuser The username of a user that have rights to install options. admin is default.
#' @param password The password admin is default.
#' @return The function will raise a error...
#' @examples
#' \dontrun{
#' ml.clear.database("localhost", "8000", "admin", "admin")
#' }
#' @export
ml.clear.database <- function(host = "localhost", port = "8000", adminuser = "admin", password = "admin") {
  # general URL, used as basis for all
  mlHost <- paste("http://", host, ":", port, sep="")

  # name of libs used
  mlLibs <- .rfmlEnv$mlLibs
  # name of exts used
  mlExts <- .rfmlEnv$mlExts


  for (i in 1:length(mlLibs)) {
    # install the needed module library
    if (.remove.lib(mlHost, adminuser, password, mlLibs[i])) {
      message(paste("Library ",  mlLibs[i]," is removed from ", host, ":", port, sep=""))
    }
  }

  for (i in 1:length(mlExts)) {
    # install the needed module library
    if (.remove.ext(mlHost, adminuser, password, mlExts[i])) {
      message(paste("REST extension ",  mlExts[i]," is removed from ", host, ":", port, sep=""))
    }
  }
  message(paste(host, ":", port, " cleared of rfml specific files",sep=""))
}
#' Load sample data set into MarkLogic server
#'
#' The function uploads a sample data set to MarkLogic Server.
#' Provided data sets are:
#' \itemize{
#'  \item "baskets" - sample order documents that can be used with the \link{ml.arules} function.
#'  }
#'
#' @param dataSet Which dataset to upload, "baskets"
#' @param name The name of the object. The data will be added to a collection with that name. If not provided the dataSet name is used.
#' @return A ml.data.frame object pointing to the uploaded dataset.
#' @examples
#' \dontrun{
#'  ml.connect()
#'  mlBaskets <- ml.load.sample.data("baskets")
#' }
#' @export
ml.load.sample.data <- function(dataSet = "baskets", name = "") {

  if (dataSet == "baskets") {
    dataFolder <- "extdata/baskets"
    collection <- "baskets"
  } else {
    stop("Unknown data set!")
  }
  if (nchar(name) > 0) {
    collection <- name
  }
  rfmlCollection <- .insert.ml.data(dataFolder, collection, "json", "")
  return(ml.data.frame(collection=c(rfmlCollection)));
}
#' Creates or updates a Range element index.
#'
#' The function creates or updates a range element index on the underlying element/property of a ml.data.frame field.
#' The index
#'
#' The user that is used for the login must have administration priviligies.
#'
#' @param x a ml.data.frame field that the index will be created on
#' @param scalarType An atomic type specification. "string" is default
#' @param database The name of the database to create the index in. "Documents" is default.
#' @param host The hostname or ipadress of the MarkLogic Manage server. Default is the same as used for ml.connect.
#' @param port The port number of the MarkLogic Manage server. 8002 is used default
#' @param adminuser The username of a user that have rights to create index. Default is the same as used for ml.connect.
#' @param password The password. Default is the same as used for ml.connect.
#' @return The function will raise a error if something goes wrong.
#' @export
ml.add.index <- function(x, scalarType= "string", database = "Documents", host = "", port = "8002", adminuser = "", password = "") {
  if (!is.ml.col.def(x)) {
    stop("x needs to be a ml.col.def object!")
  }
  # get connection imformation
  if (nchar(adminuser) > 0) {
    username <- adminuser
  } else {
    username <- .rfmlEnv$conn$username
  }
  if (nchar(password) > 0) {
    pwd <- password
  } else {
    key <- .rfmlEnv$key
    pwd <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  }
  if (nchar(host) > 0) {
    mlhost <- host
  } else {
    mlhost <- .rfmlEnv$conn$host
  }

  # general URL, used as basis for all
  mlHost <- paste("http://", mlhost, ":", port, sep="")
  mlURL <- paste(mlHost, "/manage/v2/databases/", database, "/properties", sep="")
  localname <- x@.org_name
  indexJson <- paste('{"range-element-indexes":{"range-element-index": {"scalar-type": "', scalarType,
                     '", "namespace-uri":"","localname":"', localname,'"' ,  sep="")
  if (scalarType == "string") {
    indexJson <- paste( indexJson, ',"collation": "http://marklogic.com/collation/"' ,  sep="")

  }
  indexJson <- paste( indexJson,',"range-value-positions":true}}}', sep="")

  response <- PUT(mlURL, authenticate(username, pwd, type="digest"), body=indexJson, encode = "json", content_type_json(),accept_json())
  if(response$status_code != 204) {
    rContent <- content(response, as = "text")
    errorMsg <- paste("return message: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }
  message(paste("Range element index created on ", localname,sep=""))
  #return(response)
}
