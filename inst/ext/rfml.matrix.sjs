function getSummary(flatResult) {
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
  return xdmp.toJsonString(sumResult);
  /* return sumResult */
}

function getCorrelation(flatResult) {
    /* Get the correlation between all numeric fields */
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
  return xdmp.toJsonString(corResult);
  /*  return corResult */
}

function get(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var qText = (params.q) ? params.q : "";
  var collections = params.collection;
  var directory = params.directory;
  var pageLength = params.pageLength;
  var matrixFunc = params.matrixfunc;
  var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
  var docUri = params.docUri == "TRUE" ? true : false;

  var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;

  context.outputTypes = ['application/json'];

  var fields = {};
  if (params.fields) {
    fields = JSON.parse(params.fields);
  };

  var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory );
  /* Get a resultset whit all unique fields (element/porperties) from the search and for each
     field what data type (string/numeric) it is and the values */
  var flatResult = rfmlUtilities.summaryResult(whereQuery, getRows, relevanceScores, docUri, fields);
  switch (matrixFunc) {
    case "correlation":
        return getCorrelation(flatResult);
    case "summary":
      return getSummary(flatResult);
    default:
       return {};
  };

}

exports.GET = get;
