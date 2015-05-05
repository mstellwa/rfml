# rfml

rfml is a R package for MarkLogic Server. 
It uses the REST interfaces to allow using search for retriving data. The data is returned as a data frame with strings.

Currently this is very experimental and it only works with XML documents so far and rather simple ones.

This type of document
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

Will result in a data frame with a column for each field.
