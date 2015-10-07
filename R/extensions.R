#' Search against a MarkLogic Database using eval extension
#'
#' @param con The connection object, created with  \code{\link{rfml_connect}}
#' @param query The query to evaluate, expressed using XQuery or JavaScript
#' @param language Language used for query, can be XQuery or JavaScript
#' @return A data frame containing the result from the query If no results a NULL object is returned.
#' @examples
#' \dontrun{
#' library(rfml)
#' con <- rfml_connect("localhost","8000", "myuser", "mypassword")
#' code <- "xquery=xquery version "1.0-ml"; for $lineItem in /saleOrder/lineItems return <order>{for $item in $lineItem/lineItem/productName return <item>{$item/text()}</item>}</order>"
#' df <- eval_code(con, code)
#' }

eval_code <- function(con, query , language="XQuery") {
  if (length(con) != 4) {
    stop("Need create a connection object. Use rfml_connect first.")
  }

  # The password is stored encrypted in the con list using
  # the key in the package enviorment (created in frml.R)
  # TODO: Check that we have a key!!!!
  key <- rfml.env$key
  password <- "Pass1234"#rawToChar(PKI::PKI.decrypt(con$password, key))
  username <- con$username

  # verify that the database is ok
  # TODO: Need to tidy this up.
  if (!rfml.env$dbOk) {
    if (!.check.database(mlHost, username, password)) {
      # TODO:Handle not finding the options compared with other http responses
      rfml.env$dbOk <- FALSE
      stop(paste("The database on ",mlHost, " is not set up to work with rfml. ",
                 "Use init.database for setting up the database.", sep=""))
    } else {
      rfml.env$dbOk <- TRUE
    }
  }

  mlHost <- paste("http://", con$host, ":", con$port, sep="")
  mlURL <- paste(mlHost, "/LATEST/eval", sep="")
  response <- POST(mlURL, authenticate(username, password, type="digest"), body=query, content_type("application/x-www-form-urlencoded"))
  # response will be raw ...
  #cat(content(response, "text" ), "\n")
  rContent <-  content(response, "text")
  strXML <- .parse.multiresponse(rContent, "inte använd")
  resultDf <- xmlToDataFrame(xmlParseString(strXML))
}
