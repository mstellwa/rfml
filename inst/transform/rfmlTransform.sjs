/******************************************************************************
 * Generates a flatten json with metadata
 ******************************************************************************/
function resultMetadata(userName, dframe, result, relevanceScores, docUri) {
  var json = require("/MarkLogic/json/json.xqy");
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var xml2json = require('/ext/rfml/xml2json.sjs');
  var docFields = {};

  var qText = result.qtext;
  var ctsQuery = {"query": {"queries": [result.query]}};
  var total = result.total;

  var results = result.results;

  for (var i = 0; i < results.length; i++) {
    if (results[i].format == 'xml') {
      var xmlContent = xdmp.unquote(results[i].content).next().value;
      var x2js = new xml2json.X2JS();
      var resultContent = x2js.xml2json( xmlContent );
    } else {
      var resultContent = results[i].content;
    };
    if (docUri) {
      docFields.docUri = {"fieldType":'string', "fieldDef":'docUri'};
    }
    if (relevanceScores) {
      docFields.score = {"fieldType":'number', "fieldDef":'score'};
      docFields.confidence = {"fieldType":'number', "fieldDef":'confidence'};
      docFields.fitness = {"fieldType":'number', "fieldDef":'fitness'};
    }
    docFields = rfmlUtilities.flattenJsonObject(resultContent, docFields, "", true);
  };


  /* create our session data.frame document */
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
/******************************************************************************
 * Either returns a flatten json with data
 ******************************************************************************/
function resultData(fields, result, relevanceScores, docUri) {
  var json = require("/MarkLogic/json/json.xqy");
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var xml2json = require('/ext/rfml/xml2json.sjs');
  var flatResult = [];

  var qText = result.qtext;
  var ctsQuery = result.query;
  var total = result.total;

  var results = result.results;

  for (var i = 0; i < results.length; i++) {
    if (results[i].format == 'xml') {
      var xmlContent = xdmp.unquote(results[i].content).next().value;
      var x2js = new xml2json.X2JS();
      var resultContent = x2js.xml2json( xmlContent );
    } else {

      var resultContent = results[i].content;
    };
    var flatDoc = {};
    /* add additional fields */
    if (docUri) {
      flatDoc.docUri = results[i].uri;
    }
    if (relevanceScores) {
      flatDoc.score = results[i].score;
      flatDoc.confidence = results[i].confidence;
      flatDoc.fitness = results[i].fitness;
    }
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
/******************************************************************************
 * Either returns a flatten json with data or a flatten json with metadata
 ******************************************************************************/
function rfmlTransform(context, params, content)
{
  var userName = xdmp.getRequestUsername();
  var result = content.toObject();
  var dframe = params.dframe;
  var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
  var docUri = params.docUri == "TRUE" ? true : false;

  if (params.return == 'data') {
    var fields = {};
    if (params.fields) {
      fields = JSON.parse(params.fields);
    }
    var returnDoc = resultData(fields, result, relevanceScores, docUri);
  } else {
    var returnDoc = resultMetadata(userName, dframe, result, relevanceScores, docUri);
  };
 return xdmp.toJsonString(returnDoc);
};
exports.transform = rfmlTransform;
