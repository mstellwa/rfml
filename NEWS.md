# rfml 0.1.0.9000
## Major changes

(###) Generation of fields name has been changed in order to get them shorter. Instead of using the full name of parents only first and last letter are used.
(###) Changed the way how data is retrived from MarkLogic, now using a stream in order to speed it up.
(###) Changed to use curl package instead of httr
(###) ml.data.frame is now using a parameter object for parameters that affect the output
(#23) Changed to us fn.head instead of .next().value
(#24) Specify that source data is flat by using a parameter

## Bug fixes
(#20) rm.ml.data.frame is failing with unknown hostname
(#19) Nested JSON with properties with same name will only show first
(#16) Can only search with one collection

# rfml 0.1.0
First CRAN release
