# rfml

rfml is a R package for MarkLogic Server. 
It uses the REST interfaces to allow using search for retriving data. The data is returned as a data frame with strings.

Currently this is very experimental and it only works with XML documents so far and rather simple ones.

Once you have installed it you will also need to set up a REST server, with a module database, for the MarkLogic database you will use.
```R
library(rfml)
# setup the database to be used with rfml, will install query optiones named ml-r-options
init_database("localhost", "8000", "admin", "admin")
#create a connection
con <- rfml_connect("localhost","8000", "myuser", "mypassword")
# run a query
df <- query_string(con, "india AND sweden")
````
The result will depend on the XML document. 
This type of document:
```XML
<laureate>
  <id>703</id>
  <firstname>Trygve</firstname>
  <surname>Haavelmo</surname>
  <born>1911-12-13</born>
  <died>1999-07-26</died>
  <gender>male</gender>
  <year>1989</year>
  <category>economics</category>
  <share>1</share>
  <name>University of Oslo</name>
  <city>Oslo</city>
  <country>Norway</country>
</laureate>
````
Will result in a data frame looking like this:

| id | firstname | surname | born | died | gender | category | share | name | city | country |
| -- | --------- | ------- | -----| ---- | ------ | -------- | ----- | ---- | ---- | ------- |
| 703 | Trygve | Haavelmo | 1911-12-13 | 1999-07-26 | male | economics | 1 | University of Oslo | Oslo | Norway |

Having nested XML like this:
```XML
<laureate>
  <id>703</id>
  <firstname>Trygve</firstname>
  <surname>Haavelmo</surname>
  <born>1911-12-13</born>
  <died>1999-07-26</died>
  <gender>male</gender>
  <year>1989</year>
  <category>economics</category>
  <share>1</share>
  <name>University of Oslo</name>
  <city>Oslo</city>
  <country>Norway</country>
  <location>
    <latitude>59.939959</latitude>
    <longitude>10.72175</longitude>
  </location>
</laureate>
````

Will generate a data frame looking like this:

| id | firstname | surname | born | died | gender | category | share | name | city | country | location |
| -- | --------- | ------- | -----| ---- | ------ | -------- | ----- | ---- | ---- | ------- | -------- |
| 703 | Trygve | Haavelmo | 1911-12-13 | 1999-07-26 | male | economics | 1 | University of Oslo | Oslo | Norway | 59.939959-10.72175|

