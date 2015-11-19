/******************************************************************************
 * Returns a correlation matrix between all numeric fields in the result
 ******************************************************************************/
function rfmlCor(context, params, content)
{
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var result = content.toObject();

  var fields = {};
  if (params.fields) {
    fields = JSON.parse(params.fields);
  }

  var flatResult = rfmlUtilities.summaryResult(fields, result);
  var corResult = {};

  for (var field in flatResult) {
    if (flatResult[field].fieldType == 'number') {
      var corValues = {};
      for (var corField in flatResult) {
        if (flatResult[corField].fieldType == 'number') {
          var corArray = [];
          for (var i=0; i < flatResult[field].values.length; i++) {
            var x = new Array();
            if (i < flatResult[corField].values.length) {
              x.push(flatResult[field].values[i], flatResult[corField].values[i]);
              corArray.push(x);
            }

          };
          corVal = math.correlation(corArray);
          corValues[corField] = corVal;
        };
      };
      corResult[field] = corValues;
    };
  };
  return xdmp.toJsonString(corResult)
  /* return corResult */

}
exports.transform = rfmlCor;
