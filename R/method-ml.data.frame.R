#' Create a ml.data.frame object pointing to a ...
#'
#' This function creates an object of ml.data.frame...
#'
#' @param password The password admin is default.
#' @return The function will raise a error...
#' @examples
#' \dontrun{
#'
#' }
#' @export ml.data.frame
ml.data.frame <- function (query)
{

  # Check if we are using query or collection

  # fields?

  # get data from ML
  mlRESTExtURL <- parse_url(paste("http://192.168.33.10:8030/LATEST/resources/rfml.dframe?rs:query=", query, sep=""))

  # do a search
  response <- PUT(mlRESTExtURL,authenticate("admin", "Pass1234", type="digest"))
  # get the content



  rContent <- content(response)
  if (length(rContent) == 0) {
    stop("Query ", query, " did not produce any result");
  }

  #cols = as.vector(rContent$columns)
  res <- new("ml.data.frame")
  res@.query <- query
  res@.col.name <- rContent$columns
  return(res);

}

#' @export is.ml.data.frame
is.ml.data.frame <-
  function(x) {
    return(inherits(x, "ml.data.frame"))
  }

setMethod("colnames", signature(x="ml.data.frame"),
          function(x) { x@cols }
)
