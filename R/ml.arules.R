#' Mining Association rules and Frequent Itemsets
#'
#' Mine frequent itemsets or association rules using MarkLogic Server built in Range Index functions.
#' The function require that there is a Range Index on the underlying field of itemField. It will return
#' a object of class rules or itemsets, that can be used with any package that works with output from
#' the arules package apriori function.
#'
#' The frequent itemset and association rules extraction method is using the same method as the Apriori
#' algorithm by first identify all 1-n itemsets that satisfy the support threshold and based on these
#' extract rules that satisfy the confidence threshold.
#'
#' It is depended on that there are a Range Index on the underlying field for the itemField.
#' Information about the name of the field can be shown by mlDataFrame$itemField, where mlDataFrame
#' is a ml.data.frame object and itemField is the name of the field.
#'
#' @param data an ml.data.frame object
#' @param itemField a ml.data.frame field which is the field that the itemsets will be created of. The underlying field needs to have a Range Index defined.
#' @param support a numeric value for the minimal support of an item set (default: 0.5)
#' @param confidence a numeric value for the minimal confidence of rules/association hyperedges (default: 0.8)
#' @param maxlen an integer value for the maximal number of items per item set (default: 5)
#' @param target a character string indicating the type of association mined. One of "frequent itemsets" or "rules", default is "rules"
#' @return Returns an object of class rules or itemsets.

#' @export
ml.arules <- function(data, itemField, support = 0.5, confidence = 0.8, maxlen = 5, target = "rules") {

  # need to check for the arules package ...
  if (!requireNamespace("arules", quietly = TRUE)) {
    stop("arules needed for this function to work. Please install it.",
         call. = FALSE)
  }

  key <- .rfmlEnv$key
  password <- rawToChar(PKI::PKI.decrypt(.rfmlEnv$conn$password, key))
  username <- .rfmlEnv$conn$username
  queryComArgs <- data@.queryArgs

  mlHost <- paste("http://", .rfmlEnv$conn$host, ":", .rfmlEnv$conn$port, sep="")
  mlSearchURL <- paste(mlHost, "/v1/resources/rfml.arules", sep="")

  queryArgs <- c(queryComArgs, 'rs:supp'=support, 'rs:conf'=confidence, 'rs:maxlen'=maxlen)

  if (!inherits(itemField, "ml.col.def")) {
    stop("itemField parameter must be a valid ml.data.frame field.")
  }
  fields <- "{"
  fields <- paste(fields, '"',itemField@.name , '":{"fieldDef":"',itemField@.expr ,'","orgField":"', itemField@.org_name, '","orgFormat":"', itemField@.format , '"}',sep='')
  fields <- paste(fields, '}', sep='')
  queryArgs <- c(queryArgs, 'rs:fields'=fields)

  response <- GET(mlSearchURL, query = queryArgs, authenticate(username, password, type="digest"), accept_json())

  rContent <- content(response) #, as = "text""
  if(response$status_code != 200) {
    errorMsg <- paste("statusCode: ",
                      rContent, sep="")
    stop(paste("Ops, something went wrong.", errorMsg))
  }

  if (target == "frequent itemsets") {
    # check what we should return ..
    # create a arules itemset...
    # first generate a list with all itemsets ...
    rItemsets <- rContent$itemsets
    extrItemsets <- list()
    supportDf <- data.frame(support=numeric())

    for (i in 1:length(rItemsets)) {
      for (j in 1:length(rItemsets[[i]])) {
        extrItemsets <- c(extrItemsets, toString(rItemsets[[i]][[j]]$'itemSet'))
        supportDf <- rbind(supportDf, rItemsets[[i]][[j]]$'support')
      }
    }
    # we need arules loaded here!
    result <- new("itemsets")
    # seems to work but not fully...
    # iteminfo not right...
    result@items <- as(extrItemsets, "itemMatrix")
    result@quality <- supportDf
  } else if (target == "rules") {
    # get rules ...
    extrLhs <- list()
    extrRhs <- list()
    qualityRule <- data.frame(support=numeric(),confidence=numeric(),lift=numeric())
    rRules <- rContent$rules
    for (i in 1:length(rRules)) {
      extrLhs <- c(extrLhs, toString(rRules[[i]]$'lhs'))
      extrRhs <- c(extrRhs, toString(rRules[[i]]$'rhs'))
      qualityRule <- rbind(qualityRule, data.frame(support = rRules[[i]]$'support',confidence= rRules[[i]]$'confidence',lift= rRules[[i]]$'lift'))
    }

    # we need arules loaded here!
    result <- new("rules", lhs=as(extrLhs, "itemMatrix"), rhs=as(extrRhs, "itemMatrix"), quality=qualityRule)
  }
  ## add some reflectance
  result@info <- list(data = data,
                       ntransactions = data@.nrows,
                       support = support,
                       confidence = confidence)
  result
}
