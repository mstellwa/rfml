/******************************************************************************
 * Various helper functions used by rfml
 * Author: Mats Stellwall
 ******************************************************************************/

 /************************************
  * Check if a value is numeric
  * returns true if and false if not.
  ************************************/
function isNumeric(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}

/***********************************************************************
 * Flatten a json object
 * If fieldDef if true it will onnly return the fieldname and datatype,
 * else it will return fieldname and value
 ************************************************************************/
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
/***********************************************************************
 * Flatten a json array
 * If fieldDef if true it will onnly return the fieldname and datatype,
 * else it will return fieldname and value
 ************************************************************************/
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
/***********************************************************************
 * Flatten a json document into a array with the values of each field
 * defined in the fields parameter.
 ************************************************************************/
function fields2array(fields, result) {
  var json = require("/MarkLogic/json/json.xqy");
  var flatResult = [];
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
    /* add additional fields */
    flatDoc.docUri = results[i].uri;
    flatDoc.score = results[i].score;
    flatDoc.confidence = results[i].confidence;
    flatDoc.fitness = results[i].fitness;

    flatDoc = flattenJsonObject(resultContent, flatDoc, "", false);
    var useFields = []
    for (var field in fields) {

      var fieldName = field;
      var fieldDef = fields[field].fieldDef;
      if (fieldDef !== fieldName) {
        flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
      }
      useFields.push(flatDoc[fieldName])
    };

    flatResult.push(useFields);
  };

  return flatResult;

}
/***********************************************************************
 * Creates a result set that can be used to create
 * summary (descreptive statsitcs).
 ************************************************************************/
function summaryResult(addedFields, result) {
  var json = require("/MarkLogic/json/json.xqy");
  var flatResult = {};
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
    /* add search fields */
    flatDoc.docUri = results[i].uri;
    flatDoc.score = results[i].score;
    flatDoc.confidence = results[i].confidence;
    flatDoc.fitness = results[i].fitness;
    /*
      Flatten the current result
    */
    flatDoc = flattenJsonObject(resultContent, flatDoc, "", false);
    /* append added fields */
    for (var field in addedFields) {
      var fieldName = field;
      var fieldDef = addedFields[field].fieldDef;
      flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
    };
    for (var field in flatDoc) {
      if (flatResult[field]) {
        if (flatResult[field].fieldType == 'number' && !isNumeric(flatDoc[field])) {
              flatResult[field].fieldType = 'string';
        };
        flatResult[field].values.push(isNumeric(flatDoc[field]) ? parseFloat(flatDoc[field]) : flatDoc[field])
      } else {
         flatResult[field] = {"fieldType":isNumeric(flatDoc[field]) ? 'number' : 'string',
                              'values' : [isNumeric(flatDoc[field]) ? parseFloat(flatDoc[field]) : flatDoc[field]]};
       }
    }

  };
  return flatResult;

}

exports.flattenJsonArray = flattenJsonArray;
exports.flattenJsonObject = flattenJsonObject;
exports.fields2array = fields2array;
exports.summaryResult = summaryResult;
