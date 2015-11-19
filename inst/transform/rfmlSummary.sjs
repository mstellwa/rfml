

function rfmlSummary(context, params, content)
{
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var result = content.toObject();

  var fields = {};
  if (params.fields) {
    fields = JSON.parse(params.fields);
  }

  var flatResult = rfmlUtilities.summaryResult(fields, result);
  var sumResult = {};
  for (var field in flatResult) {
    if (flatResult[field].fieldType == 'number') {
      /* mean,median,1th and 3th quartiles,min,max */
      sumResult[field] = {'valType' : 'NUMERIC',
                          'min' : fn.min(flatResult[field].values),
                          'max' : fn.max(flatResult[field].values),
                          'median' : math.median(flatResult[field].values),
                          'mean' : fn.avg(flatResult[field].values),
                          'q1' : math.percentile(flatResult[field].values, 0.25),
                          'q3' : math.percentile(flatResult[field].values, 0.75)};
    } else {
      /* max Length */
      sumResult[field] = {'valType' : 'CATEGORICAL','length' : fn.count(xdmp.arrayValues(flatResult[field].values))};
    };
  };
  return xdmp.toJsonString(sumResult)

};
exports.transform = rfmlSummary;
