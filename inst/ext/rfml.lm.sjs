function getLm(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var xml2json = require('/ext/rfml/xml2json.sjs');
  var qText = (params.q) ? params.q : "";
  var collections = (params.collection) ? JSON.parse(params.collection): null;
  var directory = (params.directory) ? JSON.parse(params.directory): null;
  var pageLength = params.pageLength;
  var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;
  var mlVersion = xdmp.version();
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
      orgFields.push({"name": fields[field].orgField, "format": fields[field].orgFormat, "xmlns":fields[field].xmlns });
     }
  }
  /* test with cts.linearModel first, we can only handle element range indexes ,
    if we get error try math that does not require range indexes */
  try {
    var lm =  cts.linearModel(
                [(orgFields[0].format == "XML") ? cts.elementReference(fn.QName((orgFields[0].xmlns != "NA") ? forgFields[0].xmlns : "",orgFields[0].name)) : cts.jsonPropertyReference(orgFields[0].name),
                 (orgFields[1].format == "XML") ? cts.elementReference(fn.QName((orgFields[1].xmlns != "NA") ? forgFields[1].xmlns : "",orgFields[1].name)) : cts.jsonPropertyReference(orgFields[1].name)]
                      ,null,whereQuery);

  } catch(err) {
    var lmArray = rfmlUtilities.fields2array(whereQuery, 1,getRows, fields);
    var lm =  math.linearModel(lmArray);
  }
  var strLm = String(lm);
  var xmlLm;
  if (mlVersion < "8.0-5") {
    xmlLm = xdmp.unquote(strLm.substring(17, (strLm.length-1))).next().value;
  }else{
    xmlLm = fn.head(xdmp.unquote(strLm.substring(17, (strLm.length-1))));
  }

  var x2js = new xml2json.X2JS();
  var jsonLm = x2js.xml2json( xmlLm );
  return xdmp.toJsonString(jsonLm);

}

exports.GET = getLm;
