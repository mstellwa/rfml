
function rfmlLm(context, params, content)
{
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var json = require("/MarkLogic/json/json.xqy");
  //var userName = xdmp.getRequestUsername();
  var result = content.toObject();
  //var dframe = params.dframe;

  var fields = {};
  if (!params.fields) {
    // we need at least two fields
  }
  fields = JSON.parse(params.fields);
  var lmArray = rfmlUtilities.fields2array(fields, result);
  // test with cts.linearModel first, if we get error try math that does not require range indexes
  // however since we flatten first this does not work...
  // to get cts.linearModel to work we need to convert search xml to cts.query XML, figure out if we
  // are using json or XML documents and to unflattern the field names...
  //try {
  //  var lm =  cts.linearModel(lmArray);
  //}
  //catch(err) {
    var lm =  math.linearModel(lmArray);
  //}

  var strLm = String(lm)
  var xmlLm = xdmp.unquote(strLm.substring(17, (strLm.length-1)))
  var config = json.config("custom");
  var jsonLm = json.transformToJson(xmlLm, config).toObject();

  return xdmp.toJsonString(jsonLm)

};

exports.transform = rfmlLm;
