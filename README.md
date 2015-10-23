# rfml

rfml is a R package for MarkLogic Server, enabling in-dabase analytics.

It uses the REST interfaces to allow user using search syntax for creating a data.frame similar object, ml.data.frame. There is no data brought back to the client during the creation of the object. [More information on the wiki](https://github.com/mstellwa/rfml/wiki/Introduction-to-the-rfml-package)

In order to use rfml you need a REST server, with a module database, for the MarkLogic database.

Currently the package is not avalible on CRAN so you need to install it using devtools.
```R
if (packageVersion("devtools") < 1.6) {
  install.packages("devtools")
}
devtools::install_github("mstellwa/rfml")
```

After the package is installed you need to setup the database that is to be used. You need to use a administrator user or a user with rest-admin role or the following privileges; http://marklogic.com/xdmp/privileges/rest-admin, http://marklogic.com/xdmp/privileges/rest-writer, http://marklogic.com/xdmp/privileges/rest-reader.

```R
library(rfml)
# setup the database to be used with rfml, will install query options and transformation
ml.init.database("localhost", "8000", "admin", "admin")

````
After the setup you can use a standard user.
```R
#create a connection
ml.connect("localhost","8000", "myuser", "mypassword")

# create a ml.data.frame
mlDf <- ml.data.frame("försäkringskassan AND kalle")
# print information for the mlDf object
mlDf
# get dimensions
dim(mlDf)
# get all column names
colnames(mlDf)

# pull back the first 6 rows, the returned object is a data.frame
head(mlDf)

# create a field based on an existing
mlDf$newField <- df$score

# create a field based on existing
mlDf$newField2 <- df$score + df$confidence

# create a field based on an previous created
mlDf$newField3 <- df$newField + 10

mlDf$abs_score <- abs(df$score)

# pull back the whole result, including the previous created fields
localDf <- as.data.frame(mlDf)

````

