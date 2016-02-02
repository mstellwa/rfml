function get(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');

  var qText = (params.q) ? params.q : "";
  var collections = params.collection;
  var directory = params.directory;
  var pageLength = params.pageLength;
  var statFunc =  JSON.parse(params.statfunc);
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
  /* Check if we have indexes and then could use cts* functions */
 try {
    /* Need to change from eval */
    var strParams = '';
    for (var i = 0; i < orgFields.length; i++) {
      if (strParams.length > 1) {
        strParams = strParams + ',';
      };
      var addParam = (orgFields[i].format == 'XML') ? 'cts.elementReference(xs.QName("' + orgFields[i].name +'"))' : 'cts.jsonPropertyReference("' + orgFields[i].name + '")';
      strParams = strParams + addParam;

    }
    strParams = strParams + ',null,whereQuery';
    return eval(statFunc.index + '('+ strParams +')');
  } catch(err) {
    var funcArray = rfmlUtilities.fields2array(whereQuery,pageStart, getRows, fields)
    return eval(statFunc.noindex + '(funcArray)');
  }

}

exports.GET = get;
