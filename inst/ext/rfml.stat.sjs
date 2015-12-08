function get(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');

  var qText = (params.q) ? params.q : "";
  var collections = params.collection;
  var directory = params.directory;
  var pageLength = params.pageLength;
  var statFunc =  JSON.parse(params.statfunc);
  var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;

  var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory );

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
    var funcArray = rfmlUtilities.fields2array(whereQuery, getRows, fields)
    return eval(statFunc.noindex + '(funcArray)');
  }

}

exports.GET = get;
