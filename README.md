# rfml

rfml is a R package for MarkLogic Server, Enterprise NoSQL database, enabling in-dabase analytics.

It uses the REST interfaces to allow user using search syntax for creating a data.frame similar object, ml.data.frame. There is no data brought back to the client during the creation of the object. [More information on the wiki](https://github.com/mstellwa/rfml/wiki/Introduction-to-the-rfml-package)

In order to use rfml you need a REST server, with a module database, for the MarkLogic database that contains your source data..

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
After the setup you can use a standard user with http://marklogic.com/xdmp/privileges/rest-reader and if you want to upload data http://marklogic.com/xdmp/privileges/rest-writer priviligies.

Before data can be selected a call to ml.connect is needed, the function verifies that the database is setup correctly and also saves the connection information.
```R
#create a connection
ml.connect("localhost","8000", "myuser", "mypassword")
```
After the connections is done there is multiple ways to select data from the MarkLogic database.

Using a string query, more information around the syntax can be found at http://docs.marklogic.com/guide/search-dev/search-api#id_41745, to search within a collection.
```R
# create a ml.data.frame
mlDf <- ml.data.frame("setosa", collection = "iris")
```
There is also possible to upload data to the MarkLogic database that is returned as a ml.data.frame object.
```R
# create a ml.data.frame object based on the iris data set
mlDf <- as.ml.data.frame(iris, "iris")
```
No data is pulled back to the client, if not asked for using for example head.
```R
# pull back the first 6 rows, the returned object is a data.frame
head(mlDf)
```
It is possible to create new columns for the ml.data.frame object. The columns only exists within the object and are not created at the database. 
```R
# create a field based on an existing
mlDf$newField <- df$score

# create a field based on existing
mlDf$newField2 <- df$score + df$confidence

# create a field based on an previous created
mlDf$newField3 <- df$newField + 10

mlDf$abs_score <- abs(df$score)
```
The new columns are calculated at runtime when retriving the data, the calculation is done on the server side.
```R
# pull back the whole result, including the previous created fields
head(mlDf)
```
It is possible also to pull back data from a  ml.data.frame object, it is returned as a data.frame.
```R
localDf <- as.data.frame(mlDf)
```
For more information about the functions see the package doumentation and there is also  [More information on the wiki](https://github.com/mstellwa/rfml/wiki/Introduction-to-the-rfml-package)
