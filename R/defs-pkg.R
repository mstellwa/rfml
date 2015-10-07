
## -----------------------------------------------------------------------
## Private variables of the package
## -----------------------------------------------------------------------


setClass("ml.data.frame",
         slots=c(
           query="character", # the search that defines
           col.name="character" # column names
          )
    )
