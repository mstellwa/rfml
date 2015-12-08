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
function flattenJsonObject(obj, flatJson, prefix, fieldDef, orgFormat) {
 for (var key in obj) {
   if (Array.isArray(obj[key])) {
     var jsonArray = obj[key];
     if (jsonArray.length < 1) continue;
     flatJson = flattenJsonArray(jsonArray, flatJson, key, fieldDef,orgFormat);
   } else if (obj[key] !== null && typeof obj[key] === 'object') {
     var jsonObject = obj[key];
      flatJson = flattenJsonObject(jsonObject, flatJson, key + 1, fieldDef,orgFormat);
   } else {
     var value = obj[key];
     if (value !== null) {
       if (fieldDef) {
         if (flatJson[prefix + key]) {
           if (flatJson[prefix + key].fieldType == 'number' && !isNumeric(obj[key])) {
             flatJson[prefix + key].fieldType = 'string';
           };
         } else {
           flatJson[prefix + key] = {"fieldType":isNumeric(obj[key]) ? 'number' : 'string', "fieldDef":prefix + key, "orgField": key, "orgFormat":orgFormat};
         };
       } else {
         flatJson[prefix + key] = isNumeric(obj[key]) ?  parseFloat(obj[key]) : obj[key];

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
function flattenJsonArray(obj, flatJson, prefix, fieldDef, orgFormat) {
 var length = obj.length;
 for (var i = 0; i < length; i++) {
   if (Array.isArray(obj[i])) {
     var jsonArray = obj[i];
     if (jsonArray.length < 1) continue;
     flatJson = flattenJsonArray(jsonArray, flatJson, prefix + i,fieldDef,orgFormat);
    } else if (obj[i] !== null && typeof obj[i] === 'object') {
       var jsonObject = obj[i];
       flatJson = flattenJsonObject(jsonObject, flatJson, prefix + (i + 1),fieldDef,orgFormat);
   } else {
     var value = obj[i];
     if (value !== null) {
       if (fieldDef) {
         if (flatJson[prefix + i]) {
           if (flatJson[prefix + i].fieldType == 'number' && !isNumeric(obj[i])) {
             flatJson[prefix + i].fieldType = 'string';
           };
         } else {
           flatJson[prefix + i] = {"fieldType":isNumeric(obj[i]) ? 'number' : 'string', "fieldDef":prefix + i, "orgField": i, "orgFormat":orgFormat };
         };
       } else {
         flatJson[prefix + i] = isNumeric(obj[i]) ?  parseFloat(obj[i]) : obj[i]
       };
     };
   }
 }
 return(flatJson)
}
function getFlatResult(docRaw, docFormat, searchRelatedVals, fields) {
  /* var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs'); */
  var xml2json = require('/ext/rfml/xml2json.sjs');
  var resultContent;
  switch (docFormat) {
    /* XML format result from jsearch */
    case 'element':
      var xmlContent = xdmp.unquote(docRaw.toString()).next().value;
      var x2js = new xml2json.X2JS();
      resultContent = x2js.xml2json( xmlContent );
      break;
    /* XML format result from cts.search */
    case "XML":
      var x2js = new xml2json.X2JS();
      resultContent = x2js.xml2json( docRaw );
      break;
    /* JSON format result from jsearch */
    case 'object':
      resultContent = JSON.parse(docRaw);
      break;
    /* XML format result from cts.search */
    case "JSON":
      resultContent = docRaw.toObject();
      break;
    default:
      return;
  };
  var flatDoc = {};
  /*  Add search related fields */
  flatDoc = searchRelatedVals;
  flatDoc = flattenJsonObject(resultContent, flatDoc, "", false);
  /* Add user defined fields */
  for (var field in fields) {
    var fieldName = field;
    var fieldDef = fields[field].fieldDef;
    flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
  };
  return flatDoc;
}
/***********************************************************************
 * Flatten a json document into a array with the values of each field
 * defined in the fields parameter.
 ************************************************************************/
 function fields2arrayJS(whereQuery, getRows, fields) {
   var jsearch = require('/MarkLogic/jsearch.sjs');
   var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
   var xml2json = require('/ext/rfml/xml2json.sjs');
   var flatResult = [];
   /* We do not produce any result, the map function is updating flatResult that is used instead */
   var x = jsearch.documents()
                 .where(whereQuery)
                 .slice(0,getRows)
                 .map(function (match) {
                         var docRaw = match.document;
                         switch (docRaw.nodeKind) {
                           case 'element':
                             var xmlContent = xdmp.unquote(docRaw.toString()).next().value;
                             var x2js = new xml2json.X2JS();
                             var resultContent = x2js.xml2json( xmlContent );
                             break;
                           case 'object':
                             var resultContent = JSON.parse(docRaw);
                             break;
                           default:
                             return;
                         };
                         var flatDoc = {};
                         flatDoc.docUri = match.uri;
                         flatDoc.score = match.score;
                         flatDoc.confidence = match.confidence;
                         flatDoc.fitness = match.fitness;
                         flatDoc = rfmlUtilities.flattenJsonObject(resultContent, flatDoc, "", false);
                         var useFields = []
                         for (var field in fields) {
                           var fieldName = field;
                           var fieldDef = fields[field].fieldDef;
                           flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
                           useFields.push(flatDoc[fieldName])
                         };
                         flatResult.push(useFields);

                   })
                   .result();
   return flatResult;
 }
 function fields2arrayCts(whereQuery, getRows, fields) {
   var jsearch = require('/MarkLogic/jsearch.sjs');
   var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
   var xml2json = require('/ext/rfml/xml2json.sjs');
   var flatResult = [];
   var resultContent;

   var results = fn.subsequence(cts.search(whereQuery), 1, getRows);

   for (var result of results) {
     switch (result.documentFormat) {
       case "XML":
         var x2js = new xml2json.X2JS();
         resultContent = x2js.xml2json( result );
         break;
       case "JSON":
         resultContent = result.toObject();
         break;
       default:
         continue;
     };
     var flatDoc = {};
      /* add additional fields */
     flatDoc.docUri = fn.documentUri(result);
     flatDoc.score = cts.score(result);
     flatDoc.confidence = cts.confidence(result);
     flatDoc.fitness = cts.fitness(result);

     flatDoc =  rfmlUtilities.flattenJsonObject(resultContent, flatDoc, "", false, result.documentFormat);
     var useFields = []
     for (var field in fields) {
       var fieldName = field;
       var fieldDef = fields[field].fieldDef;
       flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
       useFields.push(flatDoc[fieldName])
     };
     flatResult.push(useFields);
   };
   return flatResult;
 }

 function fields2array(whereQuery, getRows, fields) {
   var mlVersion = xdmp.version();
     /* Check version and do diffrently */
   if (mlVersion >= "8.0-4") {
       return fields2arrayJS(whereQuery, getRows, fields);
   } else {
      return fields2arrayCts(whereQuery, getRows, fields);
   };

 }
 /***********************************************************************
 * Creates a result set that can be used to create
 * summary (descreptive statsitcs).
 ************************************************************************/
function summaryResultJS(whereQuery, getRows, relevanceScores, docUri, fields) {
  var jsearch = require('/MarkLogic/jsearch.sjs');
  var flatResult = {};
  var x = jsearch.documents()
                .where(whereQuery)
                .slice(0,getRows)
                .map(function (match) {
                        var docRaw = match.document;
                        var searchRelatedVals = {};
                        if (docUri) {
                          searchRelatedVals.docUri = match.uri;
                        };

                        if (relevanceScores) {
                          searchRelatedVals.score = match.score;
                          searchRelatedVals.confidence = match.confidence;
                          searchRelatedVals.fitness = match.fitness;
                        };

                        var flatDoc =  getFlatResult(docRaw, docRaw.nodeKind, searchRelatedVals, fields);
                        /*
                          For each field add the type (string/numeric) and value to the  flatResult doc.
                        */
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

                  })
                  .result();


  return flatResult;

}

/***********************************************************************
 * Creates a result set that can be used to create
 * summary (descreptive statsitcs).
 ************************************************************************/
function summaryResultCts(whereQuery, getRows, relevanceScores, docUri, fields) {

  var results = fn.subsequence(cts.search(whereQuery), 1, getRows);
  var flatResult = {};

  for (var result of results) {
    var searchRelatedVals = {};
    if (docUri) {
      searchRelatedVals.docUri = fn.documentUri(result);
    }
    if (relevanceScores) {
      searchRelatedVals.score = cts.score(result);
      searchRelatedVals.confidence = cts.confidence(result);
      searchRelatedVals.fitness = cts.fitness(result);
    }

    flatDoc = getFlatResult(result, result.documentFormat, searchRelatedVals, fields)
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
/***********************************************************************
 * Creates a result set that can be used to create
 * summary (descreptive statsitcs).
 ************************************************************************/
function summaryResult(whereQuery, getRows, relevanceScores, docUri, fields) {
  var mlVersion = xdmp.version();

  if (mlVersion >= "8.0-4") {
    return summaryResultJS(whereQuery, getRows, relevanceScores, docUri, fields);
  } else {
    return summaryResultCts(whereQuery, getRows, relevanceScores, docUri, fields);
  };

}
/******************************************************************************
 * Generates a cts query based on search text, collections and directory
 ******************************************************************************/
function getCtsQuery(qText, collections, directory ) {
  var ctsQuery,collectionQuery, directoryQuery;
  var mlVersion = xdmp.version();

  var andQuery = false;

  if ((collections) && (collections.length > 0)) {
    andQuery = true;
    collectionQuery = cts.collectionQuery(collections);
  };

  if ((directory) && (directory.length > 0)) {
     andQuery = true;
    directoryQuery = cts.directoryQuery(directory);
  };
  if (mlVersion >= "8.0-4") {
    ctsQuery = cts.parse(qText);
    return (andQuery) ? cts.andQuery([ctsQuery,collectionQuery, directoryQuery]) : ctsQuery;

  } else {
    ctsQuery = xdmp.xqueryEval(
            'xquery version "1.0-ml";  ' +
            'import module namespace search = "http://marklogic.com/appservices/search"  ' +
            '    at "/MarkLogic/appservices/search/search.xqy";  ' +
            'declare variable $qtext as xs:string external;  ' +
            'search:parse($qtext)',
             { '{}qtext': qText });
      return (andQuery) ? cts.andQuery([cts.query(ctsQuery),collectionQuery, directoryQuery]) : cts.query(ctsQuery);
  };
}

exports.flattenJsonArray = flattenJsonArray;
exports.flattenJsonObject = flattenJsonObject;
exports.fields2array = fields2array;
exports.summaryResult = summaryResult;
exports.getCtsQuery = getCtsQuery;
exports.getFlatResult = getFlatResult;
