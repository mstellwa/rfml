

function resultMetadata(userName, dframe, result) {
  var json = require("/MarkLogic/json/json.xqy");
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var docFields = {};

  var qText = result.qtext;
  var ctsQuery = {"query": {"queries": [result.query]}};
  var total = result.total;

  var results = result.results;

  for (var i = 0; i < results.length; i++) {
    if (results[i].format == 'xml') {
      /* This has not been tested fully */

      var xmlContent = xdmp.unquote(results[i].content);
      var config = json.config("custom");
      var resultContent = json.transformToJson(xmlContent, config).toObject();
    } else {
      var resultContent = results[i].content;
    };
    docFields.docUri = {"fieldType":'string', "fieldDef":'docUri'};
    docFields.score = {"fieldType":'number', "fieldDef":'score'};
    docFields.confidence = {"fieldType":'number', "fieldDef":'confidence'};
    docFields.fitness = {"fieldType":'number', "fieldDef":'fitness'};
    docFields = rfmlUtilities.flattenJsonObject(resultContent, docFields, "", true);
  };


  // create our session data.frame document
  var dfInfoDoc = {
    "rfmlUser": userName,
    "rfmlDataFrame": dframe,
    "qText": qText,
    "ctsQuery": ctsQuery,
    "queryTime": '',
    "nrows": total,
    "dataFrameFields": docFields
  };

  return dfInfoDoc;
}

function resultData(fields, result) {
  var json = require("/MarkLogic/json/json.xqy");
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var flatResult = [];

  var qText = result.qtext;
  var ctsQuery = result.query;
  var total = result.total;

  var results = result.results;

  for (var i = 0; i < results.length; i++) {
    if (results[i].format == 'xml') {
      /* This has not been tested fully */

      var xmlContent = xdmp.unquote(results[i].content);
      var config = json.config("custom");
      var resultContent = json.transformToJson(xmlContent, config).toObject();
    } else {

      var resultContent = results[i].content;
    };
    var flatDoc = {};
    // add additional fields
    flatDoc.docUri = results[i].uri;
    flatDoc.score = results[i].score;
    flatDoc.confidence = results[i].confidence;
    flatDoc.fitness = results[i].fitness;

    flatDoc = rfmlUtilities.flattenJsonObject(resultContent, flatDoc, "", false);

    for (var field in fields) {
      var fieldName = field;
      var fieldDef = fields[field].fieldDef;
      flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
    };

    flatResult.push(flatDoc);
  };

  return flatResult;

}
function rfmlTransform(context, params, content)
{
  //var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var userName = xdmp.getRequestUsername();
  var result = content.toObject();
  var dframe = params.dframe;

  if (params.return == 'data') {
    var fields = {};
    if (params.fields) {
      fields = JSON.parse(params.fields);
    }
    var returnDoc = resultData(fields, result);
  } else {
    var returnDoc = resultMetadata(userName, dframe, result);
  };
 return xdmp.toJsonString(returnDoc);
};
exports.transform = rfmlTransform;
