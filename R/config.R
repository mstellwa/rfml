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

  # the transforms, search options and libraries used
  mlTransforms <- .rfmlEnv$mlTransforms
  # name of options used
  mlOptions <-.rfmlEnv$mlOptions
  # name of libs used
  mlLibs <- .rfmlEnv$mlLibs
  #
  mlExts <- .rfmlEnv$mlExts

  # install the needed search options
#  for (i in 1:length(mlOptions)) {
#    mlQueryOpFile <- paste(mlOptions[i], ".json", sep='')
#    mlOptionsFilePath <- system.file("options", mlQueryOpFile, package = "rfml")
#    if (.insert.search.options(mlHost, adminuser, password, mlOptions[i],mlOptionsFilePath, "application/json")) {
#       message(paste("Option ", mlOptions[i]," is now installed on ", host, ":", port, sep=""))
#     }
#  }
 for (i in 1:length(mlLibs)) {
  # install the needed module library
    if (.insert.lib(mlHost, adminuser, password, mlLibs[i])) {
      message(paste("Library ",mlLibs[i] ," is now installed on ", host, ":", port, sep=""))
    }
  }
  # install needed transforms
#   for (i in 1:length(mlTransforms)) {
#     if (.insert.search.transform(mlHost, adminuser, password, mlTransforms[i])) {
#       message(paste("Transformation ",mlTransforms[i], " is now installed on ", host, ":", port, sep=""))
#     }
#   }

  for (i in 1:length(mlExts)) {
    if (.insert.ext(mlHost, adminuser, password, mlExts[i])) {
      message(paste("REST extension ",mlExts[i], " is now installed on ", host, ":", port, sep=""))
    }
  }
  closeAllConnections()
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
#' ml.clear.database("localhost", "8000", "admin", "admin")
#' }
#' @export
ml.clear.database <- function(host = "localhost", port = "8000", adminuser = "admin", password = "admin") {
  # general URL, used as basis for all
  mlHost <- paste("http://", host, ":", port, sep="")

  # the transforms, search options and libraries used
  mlTransforms <- .rfmlEnv$mlTransforms
  # name of options used
  mlOptions <-.rfmlEnv$mlOptions
  # name of libs used
  mlLibs <- .rfmlEnv$mlLibs
  # name of exts used
  mlExts <- .rfmlEnv$mlExts


  # install the needed search options
#   for (i in 1:length(mlOptions)) {
#     #mlQueryOpName <- paste(mlOptions[i], ".json", sep='')
#     #mlOptions <- system.file("options",mlQueryOpName,package = "rfml")
#     if (.remove.search.options(mlHost, adminuser, password, mlOptions[i])) {
#       message(paste("Option ", mlOptions[i]," is now removed from ", host, ":", port, sep=""))
#     }
#   }
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
  # install needed transforms
#   for (i in 1:length(mlTransforms)) {
#     if (.remove.search.transform(mlHost, adminuser, password, mlTransforms[i])) {
#       message(paste("Transformation ",mlTransforms[i], " is now removed from ", host, ":", port, sep=""))
#     }
#   }

  message(paste(host, ":", port, " cleard of rfml specific files",sep=""))
}

ml.add.option <- function(searchOpt, format = "json", host = "localhost", port = "8000", adminuser = "admin", password = "admin") {
  # general URL, used as basis for all
  mlHost <- paste("http://", host, ":", port, sep="")

  if ( format == "json") {
    # need to check for:
    #   "transform-results": {
    #     "apply": "raw"
    fileType <- "application/json"
  } else if (format == "XML") {
    # need to check for:
    #     <search:transform-results apply="raw">
    #       </search:transform-results>
    fileType <- "application/XML"
  } else {
    stop("Format can only be json or XML!")
  }


  # the transforms, search options and libraries used
  if (.insert.search.options(mlHost, adminuser, password, mlOptions, fileType)) {
      message(paste("Options ", searchOpt ,"  is now installed on ", host, ":", port, sep=""))
  }
}
#' @export
ml.default.option <- function(searchOpt) {
  # should it be a control if the option exists in the target database?
  .rfmlEnv$mlDefaultOption <- searchOpt
  message(paste(searchOpt, " is now the deafult search option", sep=""))

}
