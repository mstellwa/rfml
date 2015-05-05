###############################################################################
# Internal functions used in the package
###############################################################################

# internal function to add default serach options
.insert.search.options <- function(mlHost, username, password)  {
  mlQueryOpName <- "ml-r-options"
  mlURL <- paste(mlHost, "/v1/config/query/", mlQueryOpName, sep="")

  # we are only using <transform-results apply="raw"> as our only option to make sure
  # we are getting all data back when using search
  # TODO: Move the search options to an external XML/JSON file
  options(useFancyQuotes =  FALSE)
  mlOptions <- paste("<search:options xmlns:search=", dQuote("http://marklogic.com/appservices/search"), "><search:transform-results apply=", dQuote("raw")," /></search:options>",sep="")

  # add or replace search options to the database
  response <- PUT(mlURL, authenticate(username, password, type="digest"), body=mlOptions, content_type_xml())
  # TODO:
  # check the response
  # if not 201 or 204 then raise a error
  # status_code <- response$status_code
#
#   rContent <- content(response)
#   errorMsg <- paste("statusCode: ",
#                     rContent$errorResponse$statusCode,
#                     ", status: ", rContent$errorResponse$status,
#                     ", message: ", rContent$errorResponse$message, sep="")
#   stop(paste("Ops, something went wrong.", errorMsg))
  # return the name of the search options
  return(mlQueryOpName)
}

# verify that the database has everything neccessary in order to use the package
# if it exists it returns TRUE if not FALSE and if any other status_code than 404
# it will add a warning
.check.database <- function(mlHost, username, password) {
  # the search options used
  mlQueryOpName <- "ml-r-options"
  mlURL <- paste(mlHost, "/v1/config/query/", mlQueryOpName, sep="")
  # Query the databse for the ml-r-options
  response <- GET(mlURL, authenticate(username, password, type="digest"))
  status_code <- response$status_code
  # If status 404 the search options was not found
  if (status_code == 404) {
    # 404 Not found
    return(FALSE)
  } else {
    # something else went wrong, could be wrong user etc
    rContent <- content(response)
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    warning(paste("Ops, something went wrong.", errorMsg))
    return(FALSE)
  }
  # check for ...

  return(TRUE)


}
