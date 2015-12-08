## -----------------------------------------------------------------------
## Private variables of the package
## -----------------------------------------------------------------------

# A package specific enviroment, used to store the RSA key and connection info
.rfmlEnv <- new.env()
# name of transformations used
.rfmlEnv$mlTransforms <- c("rfmlTransform", "rfmlLm", "rfmlStat", "rfmlSummary", "rfmlCor")
# name of options used
.rfmlEnv$mlOptions <- c("rfml")
.rfmlEnv$mlDefaultOption <- "rfml"
# name of libs used
.rfmlEnv$mlLibs <- c("rfmlUtilities", "xml2json")
# name of exstentions used
.rfmlEnv$mlExts <- c("rfml.dframe", "rfml.lm", "rfml.stat", "rfml.matrix", "rfml.collection")


setClass("ml.data.frame",
         slots=c(
           .name="character", # the name of the data frame result
           .qtext="character", # the search that defines the data frame
           .ctsQuery="json", #the cts query for the data frame.
           .queryArgs="list", #parameters used to query ML
           .nrows="integer",  # the number of rows in the result
           .col.name="character", # column names
           .col.data_type = "character", # column types
           .col.org_name = "character", # name of field in source document
           .col.format = "character", # source document format XML/JSON
           .col.defs = "list"
          )
    )
#Column expressions
setClass("ml.col.def",
         slots=c(.expr="character",
                 .parent="ml.data.frame",
                 .type = "character", # column types
                 .name = "character",
                 .data_type = "character",
                 .org_name = "character",
                 .format = "character",
                 .aggType="character"
                )
         )
