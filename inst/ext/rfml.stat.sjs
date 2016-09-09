function getStat(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');

  var qText = (params.q) ? params.q : "";
  var collections = (params.collection) ? JSON.parse(params.collection): null;
  var directory = (params.directory) ? JSON.parse(params.directory): null;
  var pageLength = params.pageLength;
  var statFunc = params.statfunc; //JSON.parse(params.statfunc);
  var aggFields = (params.fields) ? JSON.parse(params.fields): null;
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
  var mulitElement = false;
  var inxFunc;
  var func;
  switch(statFunc) {
    case "cor":
      inxFunc = cts.correlation;
      func = math.correlation;
      mulitElement = true;
      break;
    case "cov":
      inxFunc = cts.covariance;
      func = math.covariance;
      mulitElement = true;
      break;
    case "cov.pop":
      inxFunc = cts.covarianceP;
      func = math.covarianceP;
      mulitElement = true;
      break;
    case "var":
      inxFunc = cts.variance;
      func = math.variance;
      break;
    case "var.pop":
      inxFunc = cts.varianceP;
      func = math.varianceP;
      break;
    case "sd":
      inxFunc = cts.stddev;
      func = math.stddev;
      break;
    case "sd.pop":
      inxFunc = cts.stddevP;
      func = math.stddevP;
      break;
    case "median":
      inxFunc = cts.median;
      func = math.median;
      break;
    case "mean":
      inxFunc = cts.avgAggregate;
      func = fn.avg;
      break;
    case "sum":
      inxFunc = cts.sumAggregate;
      func = fn.sum;
      break;
    case "max":
      inxFunc = cts.max;
      func = fn.max;
      break;
    case "min":
      inxFunc = cts.min;
      func = fn.min;
      break;
    default:
      /* Unsuported function */
      return null;
      break;
  }

  if (groupByFields) {
    var elementRefs = [];
    for (var field in grpByFields) {
        elementRefs.push(cts.elementReference(xs.QName(grpByFields[field].orgField)));
    }
  } else {

  }
  /* Check if we have indexes and then could use cts* functions */
 try {
    var elementRefs;
   /*
      Need to chwck that we only
      Object.keys(funcFields).length
   */
    if ((Object.keys(aggFields).length > 1 ) && (mulitElement)) {
      elementRefs = [];
      for (var aggField in aggFields) {
        var elementRef;
        if (aggFields[aggField].orgFormat == 'XML') {
          elementRef = cts.elementReference(fn.QName((aggFields[aggField].xmlns != "NA") ? aggFields[aggField].xmlns : "", aggFields[aggField].orgField));
        } else {
          elementRef = cts.jsonPropertyReference(aggFields[aggField].orgField);
        }
        elementRefs.push(elementRef)
      }
    } else if (!mulitElement) {
        var fieldName = Object.keys(aggFields)[0];
        if (aggFields[fieldName].orgFormat == 'XML') {
          elementRefs = cts.elementReference(fn.QName((aggFields[fieldName].xmlns != "NA") ? aggFields[fieldName].xmlns : "", aggFields[fieldName].orgField));
        } else {
          elementRefs = cts.jsonPropertyReference(aggFields[fieldName].orgField);
        }
    } else  {
      return null;
    }
     return inxFunc(elementRefs, null, whereQuery);
  } catch(err) {
    var funcArray = rfmlUtilities.fields2array(whereQuery,pageStart, getRows, aggFields)
    return func(funcArray);
 }

}

exports.GET = getStat;
