function isNumeric(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

function flattenJsonObject(obj, flatJson, prefix, fieldDef) {
  for (var key in obj) {
    if (Array.isArray(obj[key])) {
      var jsonArray = obj[key];
      if (jsonArray.length < 1) continue;
      flatJson = flattenJsonArray(jsonArray, flatJson, key, fieldDef);
    } else if (obj[key] !== null && typeof obj[key] === 'object') {
      var jsonObject = obj[key];
       flatJson = flattenJsonObject(jsonObject, flatJson, key + 1, fieldDef);
    } else {
      var value = obj[key];
      if (value !== null) {
        if (fieldDef) {
          if (flatJson[prefix + key]) {
            if (flatJson[prefix + key].fieldType == 'number' && !isNumeric(obj[key])) {
              flatJson[prefix + key].fieldType = 'string';
            };
          } else {
            flatJson[prefix + key] = {"fieldType":isNumeric(obj[key]) ? 'number' : 'string', "fieldDef":prefix + key};
          };
        } else {
          flatJson[prefix + key] = obj[key];
        };
      };
    };
  };
  return(flatJson);
}

function flattenJsonArray(obj, flatJson, prefix, fieldDef) {
  var length = obj.length;
  for (var i = 0; i < length; i++) {
    if (Array.isArray(obj[i])) {
      var jsonArray = obj[i];
      if (jsonArray.length < 1) continue;
      flatJson = flattenJsonArray(jsonArray, flatJson, prefix + i,fieldDef);
     } else if (obj[i] !== null && typeof obj[i] === 'object') {
        var jsonObject = obj[i];
        flatJson = flattenJsonObject(jsonObject, flatJson, prefix + (i + 1),fieldDef);
    } else {
      var value = obj[i];
      if (value !== null) {
        if (fieldDef) {
          if (flatJson[prefix + i]) {
            if (flatJson[prefix + i].fieldType == 'number' && !isNumeric(obj[i])) {
              flatJson[prefix + i].fieldType = 'string';
            };
          } else {
            flatJson[prefix + i] = {"fieldType":isNumeric(obj[i]) ? 'number' : 'string', "fieldDef":prefix + i};
          };
        } else {
          flatJson[prefix + i] = obj[i]
        };
      };
    }
  }
  return(flatJson)
}

function resultMetadata(userName, dframe, result) {
  var json = require("/MarkLogic/json/json.xqy");
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
    docFields = flattenJsonObject(resultContent, docFields, "", true);
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

function resultData(userName, dframe, fields, result) {
  var json = require("/MarkLogic/json/json.xqy");
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

    flatDoc = flattenJsonObject(resultContent, flatDoc, "", false);

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
    var returnDoc = resultData(userName, dframe, fields, result);
  } else {
    var returnDoc = resultMetadata(userName, dframe, result);
  };
 return xdmp.toJsonString(returnDoc);
};
exports.transform = rfmlTransform;
