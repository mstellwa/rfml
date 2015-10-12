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

#' Search against a MarkLogic Database using a string query
#'
#' @param con The connection object, created with  \code{\link{rfml_connect}}
#' @param query The query string. If a empty string all documents form the database will be returned.
#' @param collection Restricts the search to one or more collections. Is optional.
#' @param directory Restricts the search to a directory. Is optional.
#' @param results The maximum number results to return. 0 means all, which is the default value.
#' @return A data frame containing the result from the search. If no results a NULL object is returned.
#' @examples
#' \dontrun{
#' library(rfml)
#' con <- rfml_connect("localhost","8000", "myuser", "mypassword")
#' df <- query_string(con, "india AND sweden")
#' df <- query_string(con, "india AND sweden", "mycollection,myothercollection", "/inmydirectory")
#' }

query_string <- function(con, query="", collection = "", directory = "", results = 0) {

  if (length(con) != 4) {
    stop("Need create a connection object. Use rfml_connect first.")
  }

  # The password is stored encrypted in the con list using
  # the key in the package enviorment (created in frml.R)
  # TODO: Check that we have a key!!!!
  key <- rfml.env$key
  password <- rawToChar(PKI::PKI.decrypt(con$password, key))
  username <- con$username

  # verify that the database is ok
  # TODO: Need to tidy this up.
  if (!.rfmlEnv$dbOk) {
    if (!.check.database(mlHost, username, password)) {
      # TODO:Handle not finding the options compared with other http responses
      .rfmlEnv$dbOk <- FALSE
      stop(paste("The database on ",mlHost, " is not set up to work with rfml. ",
               "Use init.database for setting up the database.", sep=""))
    } else {
      .rfmlEnv$dbOk <- TRUE
    }
  }

  mlHost <- paste("http://", con$host, ":", con$port, sep="")
  mlSearchURL <- paste(mlHost, "/LATEST/search", sep="")
  mlOptions <- "ml-r-options"
  nStart=1
  if (results > 0) {
    nPageLength=results
  } else {
    nPageLength=100
  }


  queryArgs <- list(q=query, options=mlOptions, pageLength=nPageLength, start=nStart)
  # TODO: check for additional parameters... such as collection and directory
  if (nchar(collection) > 0) {
    queryArgs <- c(queryArgs, collection=collection)
  }
  if (nchar(directory) > 0) {
    queryArgs <- c(queryArgs, directory=directory)
  }

  # do a search
  response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"))
  # get the content
  rContent <- content(response)
  # check the response
  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent$errorResponse$statusCode,
                      ", status: ", rContent$errorResponse$status,
                      ", message: ", rContent$errorResponse$message, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  nTotResult <- rContent$total
  if (nTotResult == 0) {
    # Is it better to raise an error or returning a NULL object?
    return(NULL)
  }

  # has the actual number of results
  totCollected <- length(rContent$results)
  myXMLstr <- ""
  # loop through all the results and build one XML string for them
  for(result in rContent$results) {
    # Need to verify that the result content is XML or JSON
    # if (result$format == "xml") {
    myXMLstr <- paste(myXMLstr, result$content, sep="")
    # } else if (result$format == "json") {
    # myJSON <- ...
    #}
  }
  # we need to collect additional result if the total is greater than
  # collected
  while (nTotResult > totCollected) {
    nStart <- nStart + nPageLength
    # update the start argument with the new number
    queryArgs$start <- nStart
    response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"))
    # get the content
    rContent <- content(response)

    # check the response
    if(response$status_code != 200) {
      errorMsg <- paste("statusCode: ",
                        rContent$errorResponse$statusCode,
                        ", status: ", rContent$errorResponse$status,
                        ", message: ", rContent$errorResponse$message, sep="")
      stop(paste("Ops, something went wrong.", errorMsg))
    }

    totCollected <- length(rContent$results) + nStart
    for(result in rContent$results) {
      myXMLstr <- paste(myXMLstr, result$content, sep="")
    }
  }

  resultDf <- xmlToDataFrame(xmlParseString(myXMLstr))

  return(resultDf)
}

query_structured <- function(con, query="", collection = "", directory = "", results = 0) {

}

query_graph <- function(){

}

#' Search against a MarkLogic Database using a SPARQL query
#'
#' @param con The connection object, created with  \code{\link{rfml_connect}}
#' @param sparql The SPARQL query string. If a empty string all triples form the database will be returned.
#' @return A data frame containing the result from the search. If no results a NULL object is returned.
#' @examples
#' \dontrun{
#' library(rfml)
#' con <- rfml.create("localhost","8000", "myuser", "mypassword")
#' options(useFancyQuotes =  FALSE)
#' sparql <- paste("SELECT ?person WHERE { ?person <http://example.org/marklogic/predicate/livesIn>",  dQuote("London")," }", sep="")
#' df <- query_sparql(con, sparql)
#' }

query_sparql <- function(con, sparql="") {
  # options(useFancyQuotes =  FALSE)
  # sparql <- paste("SELECT ?person WHERE { ?person <http://example.org/marklogic/predicate/livesIn>",  dQuote("London")," }", sep="")
  # sparql <- "SELECT * WHERE {  ?s ?p ?o}"
  # host <- "192.168.33.10"
  # port <- "9910"
  # username <- "admin"
  # password <- "Pass1234"

  if (length(con) != 4) {
    stop("Need create a connection object. Use rfml_connect first.")
  }

  # verify that the database is ok
  # TODO: Need to tidy this up.
  if (!.rfmlEnv$dbOk) {
#     if (!.check.database(mlHost, username, password)) {
#       # TODO:Handle not finding the options compared with other http responses
#       rfml.env$dbOk <- FALSE
      stop(paste("The database on ",mlHost, " is not set up to work with rfml. ",
                 "Use init_database for setting up the database.", sep=""))
#     } else {
#       rfml.env$dbOk <- TRUE
#     }
  }
  strSPARQL <- URLencode(sparql, reserved = TRUE)

  # The password is stored encrypted in the con list using
  # the key in the package enviorment (created in frml.R)
  # TODO: Check that we have a key!!!!
  key <- rfml.env$key
  password <- rawToChar(PKI::PKI.decrypt(con$password, key))
  username <- con$username
  mlHost <- paste("http://", host, ":", port, sep="")
  mlSPARQLUrl <- paste(mlHost, "/LATEST/graphs/sparql", sep="")

  sparqlArgs <- list(query=strSPARQL)

  response <- GET(mlSPARQLUrl, query = sparqlArgs, authenticate(username, password, type="digest"), accept("application/sparql-results+xml"))
  myXMLstr <- content(response, type = "text/xml")
# respnse content for the query: SELECT * WHERE {  ?s ?p ?o}
# <?xml version="1.0"?>
# <sparql xmlns="http://www.w3.org/2005/sparql-results#">
#   <head>
#     <variable name="s"/>
#     <variable name="p"/>
#     <variable name="o"/>
#   </head>
#   <results>
#     <result>
#       <binding name="s">
#         <uri>http://example.org/marklogic/people/Jack_Smith</uri>
#       </binding>
#       <binding name="p">
#         <uri>http://example.org/marklogic/predicate/livesIn</uri>
#       </binding>
#       <binding name="o">
#         <literal datatype="http://www.w3.org/2001/XMLSchema#string">Glasgow</literal>
#       </binding>
#     </result>
#     <result>
#       <binding name="s">
#         <uri>http://example.org/marklogic/people/Jane_Smith</uri>
#       </binding>
#       <binding name="p">
#         <uri>http://example.org/marklogic/predicate/livesIn</uri>
#       </binding>
#       <binding name="o">
#         <literal datatype="http://www.w3.org/2001/XMLSchema#string">London</literal>
#       </binding>
#     </result>
#     <result>
#       <binding name="s">
#           <uri>http://example.org/marklogic/people/John_Smith</uri>
#       </binding>
#       <binding name="p">
#         <uri>http://example.org/marklogic/predicate/livesIn</uri>
#       </binding>
#       <binding name="o">
#         <literal datatype="http://www.w3.org/2001/XMLSchema#string">London</literal>
#       </binding>
#     </result>
#   </results>
#</sparql>
  resultDf <- xmlToDataFrame(nodes = xmlChildren(xmlRoot(myXMLstr)[["results"]]) )
  return(resultDf)
}


