
## -----------------------------------------------------------------------
## Private variables of the package
## -----------------------------------------------------------------------

# A package specific enviroment, used to store the RSA key and connection info
.rfmlEnv <- new.env()

setClass("ml.data.frame",
         slots=c(
           .name="character", # the name of the data frame result
           .qtext="character", # the search that defines the data frame
           .ctsQuery="json", #the cts query for the data frame.
           .nrows="integer",  # the number of rows in the result
           .col.name="character", # column names
           .col.data_type = "character", # column types
           .col.defs = "list"
          )
    )
#Column expressions
setClass("ml.col.def",
         slots=c(.expr="character",
                 .parent="ml.data.frame",
                 .type = "character", # column types
                 .aggType="character"
                )
         )
