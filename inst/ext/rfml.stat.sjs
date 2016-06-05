function getStat(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');

  var qText = (params.q) ? params.q : "";
  var collections = (params.collection) ? JSON.parse(params.collection): null;
  var directory = (params.directory) ? JSON.parse(params.directory): null;
  var pageLength = params.pageLength;
  var statFunc = params.statfunc; //JSON.parse(params.statfunc);
  var groupByFields = (params.groupBy) ? JSON.parse(params.groupBy): null;

  /* pageStart only works with math functions because we first selects the result
     and then apply the function after. With cts functions range indexes are used and
     there is not possible to limit the resul other than with a query(?) */
  var pageStart = (parseInt(params.start) > 0) ? parseInt(params.start) : 1;
  var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;

  var fieldQuery;
  if (params.fieldQuery) {
    fieldQuery = JSON.parse(params.fieldQuery);
  }
  var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory, fieldQuery);

  context.outputTypes = ['application/json'];
  var fields = {};
  if (params.fields) {
     fields = JSON.parse(params.fields);
     /* Get the orginal name of the flatten fields */
    var orgFields = [];
    for (var field in fields) {
      orgFields.push({"name": fields[field].orgField, "format": fields[field].orgFormat});
     }

  }
  var idxFunc;
  var func;
  switch(statFunc) {
    case "cor":
      idxFunc = cts.correlation;
      func = math.correlation;
      break;
    case "cov":
      idxFunc = cts.covariance;
      func = math.covariance;
      break;
    case "cov.pop":
      idxFunc = cts.covarianceP;
      func = math.covarianceP;
      break;
    case "var":
      idxFunc = cts.variance;
      func = math.variance;
      break;
    case "var.pop":
      idxFunc = cts.varianceP;
      func = math.varianceP;
      break;
    case "sd":
      idxFunc = cts.stddev;
      func = math.stddev;
      break;
    case "sd.pop":
      idxFunc = cts.stddevP;
      func = math.stddevP;
      break;
    case "median":
      idxFunc = cts.median;
      func = math.median;
      break;
    case "mean":
      idxFunc = cts.avgAggregate;
      func = fn.avg;
      break;
    case "sum":
      idxFunc = cts.sumAggregate;
      func = fn.sum;
      break;
    case "max":
      idxFunc = cts.max;
      func = fn.max;
      break;
    case "min":
      idxFunc = cts.min;
      func = fn.min;
      break;
    default:
      /* Unsuported function */
      return null;
      break;
  }

  /* Check if we have indexes and then could use cts* functions */
 try {
    var elementRefs = [];
    for (var i = 0; i < orgFields.length; i++) {
      if (orgFields[i].format == 'XML') {
        elementRefs.push(cts.elementReference(fn.QName( (orgFields[i].xmlns != "NA") ? forgFields[i].xmlns : "", orgFields[i].name)));
      } else {
        elementRefs.push(cts.jsonPropertyReference(xs.QName(orgFields[i].name)));
      }
    }
     return idxFunc(elementRefs, null, whereQuery);

  } catch(err) {
    var funcArray = rfmlUtilities.fields2array(whereQuery,pageStart, getRows, fields)
    return func(funcArray);
  }

}

exports.GET = getStat;
