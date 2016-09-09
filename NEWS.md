# rfml 0.1.0.9000
## Enhancements and changes

- Generation of fields name has been changed in order to get them shorter. No only first and last letter for the parent is used.
- Changed the way how data is retrived from MarkLogic, now using a stream in order to speed it up.
- Changed to use curl package instead of httr
- ml.data.frame is now using a parameter object for parameters that affect the output
- Changed to use fn.head instead of .next().value in server side code
- Specify that source data is flat by using a parameter
- List collection without the collection index enabled
- subset, [ ], supports aggregation functions, similar to the data.table package


## Bug fixes
(#26) using no spaces in fieldFilter will generate error
(#20) rm.ml.data.frame is failing with unknown hostname
(#19) Nested JSON with properties with same name will only show first
(#16) Can only search with one collection
(#11) Update row count on ml.data.frame subsets


# rfml 0.1.0
First CRAN release
