
function getSummary(flatResult) {
  Array.prototype.unique = function()
{
	var n = {},r=[];
	for(var i = 0; i < this.length; i++)
	{
		if (!n[this[i]])
		{
			n[this[i]] = true;
			r.push(this[i]);
		}
	}
	return r;
}

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
      /* Get the count per level (distinct value) */
      var levels = {};
      var levelArr = flatResult[field].values.sort();
      for(var i=0;i< levelArr.length;i++)
      {
          var key = levelArr[i];
          levels[key] = (levels[key])? levels[key] + 1 : 1 ;

      }
      sumResult[field] = {'valType' : 'CATEGORICAL','length' : fn.count(xdmp.arrayValues(flatResult[field].values)),
                           "levels": levels};
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

function getMatrix(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var qText = (params.q) ? params.q : "";
  var collections = (params.collection) ? JSON.parse(params.collection): null;
  var directory = (params.directory) ? JSON.parse(params.directory): null;
  var pageLength = params.pageLength;
  var pageStart = (parseInt(params.start) > 0) ? parseInt(params.start) : 1;
  var matrixFunc = params.matrixfunc;
  var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
  var docUri = params.docUri == "TRUE" ? true : false;

  var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;

  context.outputTypes = ['application/json'];
  var addFields = {};
  /* Have we added fields */
  if (params.fields) {
    addFields = JSON.parse(params.fields);
  };
  var extFields;
  /* Are we only using part of the fields ? */
  if (params.extfields) {
     extFields = JSON.parse(params.extfields);
  }

  var fieldQuery;
  if (params.fieldQuery) {
    fieldQuery = JSON.parse(params.fieldQuery);
  }
  var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory, fieldQuery);

  /* Get a resultset whit all unique fields (element/porperties) from the search and for each
     field what data type (string/numeric) it is and the values */
  var flatResult = rfmlUtilities.getMatrixResult(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields);
  switch (matrixFunc) {
    case "correlation":
        return getCorrelation(flatResult);
    case "summary":
      return getSummary(flatResult);
    default:
       return {};
  };

}

exports.GET = getMatrix;
