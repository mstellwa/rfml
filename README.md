# rfml – a R package for MarkLogic Server
[![Build Status](https://travis-ci.org/mstellwa/rfml.svg?branch=master)](https://travis-ci.org/mstellwa/rfml)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/rfml)](http://cran.r-project.org/package=rfml)


rfml is a R package for MarkLogic Server, Enterprise NoSQL database, enabling in-dabase analytics.

It is based on the REST interface to allow users to use search syntax for creating a data.frame similar object, ml.data.frame. There is no data brought back to the client during the creation of the object. More information in the introduction vignette.

rfml only works with MarkLogic Server version 8 and higher. You can download MarkLogic Server at http://developer.marklogic.com/products.

In order to use rfml you need a REST server, with a module database, for the MarkLogic database that contains your source data..

**If you have previous installed rfml, before 7th December 2015, you need to execute ml.clear.database before installing the new version.**

You can install:

* the latest released version from CRAN with
```R
install.packages("rfml")
```

* the latest development version from github with
```R
if (packageVersion("devtools") < 1.6) {
  install.packages("devtools")
}
devtools::install_github("mstellwa/rfml")
```

After the package is installed you need to setup the database that is to be used. You need to use a administrator user or a user with rest-admin role or the following privileges; 

* rest-admin
* rest-writer
* rest-reader

```R
library(rfml)
# setup the database to be used with rfml, will install query options and transformation
ml.init.database("localhost", "8000", "admin", "admin")

````
After the setup you can use a standard user with rest-reader and if you want to upload data rest-writer priviligies.

Before data can be selected a call to ml.connect is needed, the function verifies that the database is setup correctly and returns a connection object. You can have multiple connections at the same time.
```R
#create a connection
localConn <- ml.connect("localhost","8000", "myuser", "mypassword")
```
After the connections is done there is multiple ways to select data from the MarkLogic database.

Using a string query, more information around the syntax can be found at http://docs.marklogic.com/guide/search-dev/search-api#id_41745, to search within a collection.
```R
# create a ml.data.frame
mlIris <- ml.data.frame(localConn, "setosa", collection = "iris")
```
It is also possible to do field level filtering. When using it there a re different requriments depending on the operator used. For ">"  "<"  "!=" "<=" ">=" operators a Element Range Index are needed on the field used, index can be created using the ml.add.index function. "==" can be used without Element Range Indexes.
```R
# create a ml.data.frame object based filtering on the Species field
mlIris <- ml.data.frame(localConn, fieldFilter = "Species == setosa")
# create a ml.data.frame object based filtering on the Petal.Length field, this requires a Element Range Index
mlIris <- ml.data.frame(localConn, fieldFilter = "Petal.Length > 5")
```
There is also possible to upload data to the MarkLogic database, which returns a ml.data.frame object.
```R
# create a ml.data.frame object based on the iris data set
mlIris <- as.ml.data.frame(localConn, iris, "iris")
```
No data is pulled back to the client, if not asked for using for example head.
```R
# pull back the first 6 rows, the returned object is a data.frame
head(mlIris)
#    Sepal.Length    Sepal.Width     Petal.Length       Petal.Width     Species
# 1  6.4              2.9               4.3              1.3            versicolor
# 2  5.6              2.9               3.6              1.3            versicolor
# 3  6.4              2.8               5.6              2.1            virginica
# 4  6.1              2.6               5.6              1.4            virginica
# 5  5.6              3.0               4.5              1.5            versicolor
# 6  4.7              3.2               1.6              0.2            setosa
```
It is possible to create new columns for the ml.data.frame object. The columns only exists within the object and are not created at the database. 
```R
# create a field based on an existing
mlIris$newField <- mlIris$Petal.Width

# create a field based calculation on existing
mlIris$newField2 <- mlIris$Petal.Width + mlIris$Petal.Length

# create a field based on an previous created
mlIris$newField3 <- mlIris$Petal.Width + 10

mlIris$abs_width <- abs(mlIris$Petal.Width)
```
The new columns are calculated at runtime when retriving the data, the calculation is done on the server side.
```R
# pull back the whole result, including the previous created fields
head(mlIris)
#    Sepal.Length  Sepal.Width Petal.Length Petal.Width Species     newField newField2 newField3 abs_width
# 1  6.4           2.9          4.3         1.3         versicolor  1.3       5.6      11.3       1.3
# 2  5.6           2.9          3.6         1.3         versicolor  1.3       4.9      11.3       1.3
# 3  6.4           2.8          5.6         2.1         virginica   2.1       7.7      12.1       2.1
# 4  6.1           2.6          5.6         1.4         virginica   1.4       7.0      11.4       1.4
# 5  5.6           3.0          4.5         1.5         versicolor  1.5       6.0      11.5       1.5
# 6  4.7           3.2          1.6         0.2         setosa      0.2       1.8      10.2       0.2
```
You can also extract a selection from a ml.data.frame into a new ml.data.frame. For example, the
following statements, would select only rows for which the column 'Species' equals 'setosa', and
only the columns 'Sepal.Length' and 'Sepal.Width'
```R
mlIris2 <- mlIris[mlIris$Species=="setosa",c("Sepal.Length","Sepal.Width")]
```
It is possible also to pull back data from a  ml.data.frame object, it is returned as a data.frame.
```R
localDf <- as.data.frame(mlIris)
```
You can also create new documents in MarkLogic based on a ml.data.frame.
```R
# Generate new documents in MarkLogic Server based on the mlIris ml-data.frame object.
newIris <- as.ml.data.frame(x=mlIris,name="newIris" )
head(newIris)
#    Sepal.Length  Sepal.Width Petal.Length Petal.Width Species     newField newField2 newField3 abs_width
# 1  6.4           2.9          4.3         1.3         versicolor  1.3       5.6      11.3       1.3
# 2  5.6           2.9          3.6         1.3         versicolor  1.3       4.9      11.3       1.3
# 3  6.4           2.8          5.6         2.1         virginica   2.1       7.7      12.1       2.1
# 4  6.1           2.6          5.6         1.4         virginica   1.4       7.0      11.4       1.4
# 5  5.6           3.0          4.5         1.5         versicolor  1.5       6.0      11.5       1.5
# 6  4.7           3.2          1.6         0.2         setosa      0.2       1.8      10.2       0.2
```

For more information about the functions see the package help and vignettes.
