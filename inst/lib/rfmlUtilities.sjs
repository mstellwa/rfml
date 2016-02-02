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
function flattenJsonObject(obj, flatJson, prefix, fieldDef, orgFormat, path) {
  var orgFormat = typeof orgFormat !== 'undefined' ?  orgFormat : "";
  var path = typeof path !== 'undefined' ?  path : "";

 for (var key in obj) {
   if (Array.isArray(obj[key])) {
     var jsonArray = obj[key];
     if (jsonArray.length < 1) continue;
     flatJson = flattenJsonArray(jsonArray, flatJson, key, fieldDef,orgFormat, path + '/'+ key);
   } else if (obj[key] !== null && typeof obj[key] === 'object') {
     var jsonObject = obj[key];
      flatJson = flattenJsonObject(jsonObject, flatJson, key + 1, fieldDef,orgFormat, path + '/'+ key);
   } else {
     var value = obj[key];
     if (value !== null) {
       if (fieldDef) {
         if (flatJson[prefix + key]) {
           if (flatJson[prefix + key].fieldType == 'number' && !isNumeric(obj[key])) {
             flatJson[prefix + key].fieldType = 'string';
           };
         } else {
           flatJson[prefix + key] = {"fieldType":isNumeric(obj[key]) ? 'number' : 'string',
                                     "fieldDef":prefix + key, "orgField": key,
                                     "orgPath" : path + '/' + key,
                                     "orgFormat":orgFormat};
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
function flattenJsonArray(obj, flatJson, prefix, fieldDef, orgFormat, path) {
  var orgFormat = typeof orgFormat !== 'undefined' ?  orgFormat : "";
  var path = typeof path !== 'undefined' ?  path : "";
  var length = obj.length;
  for (var i = 0; i < length; i++) {
   if (Array.isArray(obj[i])) {
     var jsonArray = obj[i];
     if (jsonArray.length < 1) continue;
     flatJson = flattenJsonArray(jsonArray, flatJson, prefix + i,fieldDef,orgFormat,path);
    } else if (obj[i] !== null && typeof obj[i] === 'object') {
       var jsonObject = obj[i];
       flatJson = flattenJsonObject(jsonObject, flatJson, prefix + (i + 1),fieldDef,orgFormat,path);
   } else {
     var value = obj[i];
     if (value !== null) {
       if (fieldDef) {
         if (flatJson[prefix + i]) {
           if (flatJson[prefix + i].fieldType == 'number' && !isNumeric(obj[i])) {
             flatJson[prefix + i].fieldType = 'string';
           };
         } else {
           flatJson[prefix + i] = {"fieldType":isNumeric(obj[i]) ? 'number' : 'string', "fieldDef":prefix + i, "orgField": prefix,
                                    "orgPath" : path,"orgFormat":orgFormat };
         };
       } else {
         flatJson[prefix + i] = isNumeric(obj[i]) ?  parseFloat(obj[i]) : obj[i]
       };
     };
   }
 }
 return(flatJson)
}

function getFlatResult(docRaw, docFormat, searchRelatedVals, fields, extrFields) {
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
  flatDoc = flattenJsonObject(resultContent, flatDoc, "", false, "", "");
  /* Add user defined fields */
  for (var field in fields) {
    var fieldName = field;
    var fieldDef = fields[field].fieldDef;
    flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
  };
  var retDoc = {};
  /* if we should only return a extract of the result */
  if (extrFields) {
    for (var extrField in extrFields) {
      retDoc[extrField] = flatDoc[extrField]
    }
  } else {
    retDoc = flatDoc;
  }

  return retDoc;
}
/***********************************************************************
 * Flatten a json document into a array with the values of each field
 * defined in the fields parameter.
 ************************************************************************/
 function fields2arrayJS(whereQuery, pageStart, getRows, fields) {
   var jsearch = require('/MarkLogic/jsearch.sjs');
   var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
   var xml2json = require('/ext/rfml/xml2json.sjs');
   var flatResult = [];
   /* We do not produce any result, the map function is updating flatResult that is used instead */
   var x = jsearch.documents()
                 .where(whereQuery)
                 .slice(pageStart-1,getRows)
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
 function fields2arrayCts(whereQuery, pageStart,getRows, fields) {
   var jsearch = require('/MarkLogic/jsearch.sjs');
   var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
   var xml2json = require('/ext/rfml/xml2json.sjs');
   var flatResult = [];
   var resultContent;

   var results = fn.subsequence(cts.search(whereQuery), pageStart, getRows);

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

 function fields2array(whereQuery, pageStart, getRows, fields) {
   var mlVersion = xdmp.version();
     /* Check version and do diffrently */
   if (mlVersion >= "8.0-4") {
       return fields2arrayJS(whereQuery, pageStart, getRows, fields);
   } else {
      return fields2arrayCts(whereQuery, pageStart, getRows, fields);
   };

 }
 /***********************************************************************
 * Creates a result set that can be used to create
 * summary (descreptive statsitcs).
 ************************************************************************/
function summaryResultJS(whereQuery, pageStart, getRows, relevanceScores, docUri, fields) {
  var jsearch = require('/MarkLogic/jsearch.sjs');
  var flatResult = {};
  var x = jsearch.documents()
                .where(whereQuery)
                .slice(pageStart,getRows)
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
function summaryResultCts(whereQuery, pageStart, getRows, relevanceScores, docUri, fields) {

  var results = fn.subsequence(cts.search(whereQuery), pageStart, getRows);
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
function summaryResult(whereQuery, pageStart,getRows, relevanceScores, docUri, fields) {
  var mlVersion = xdmp.version();

  if (mlVersion >= "8.0-4") {
    return summaryResultJS(whereQuery, pageStart, getRows, relevanceScores, docUri, fields);
  } else {
    return summaryResultCts(whereQuery, pageStart, getRows, relevanceScores, docUri, fields);
  };

}
/******************************************************************************
 * Generates a cts query based on search text, collections and directory
 ******************************************************************************/
 function getCtsQuery(qText, collections, directory, fieldQuery) {
   var ctsQuery,collectionQuery, directoryQuery;
   var mlVersion = xdmp.version();

   // count arguments to decide if and query...
   var queries = 0;
   var andQuery = false;

   if (qText != "") {
     queries = queries +1;
   }
   if ((collections) && (collections.length > 0)) {
     andQuery = true;
     queries = queries +1;
     if (Array.isArray(collections)) {
       var collParams = [];
       collectionQuery = 'cts.collectionQuery(['
       for (var i = 0; i < collections.length; i++) {
         collParams.push(collections[i]);
       }
       collectionQuery = cts.collectionQuery(collParams);
     } else {
       collectionQuery = cts.collectionQuery(collections);
     }
   };

   if ((directory) && (directory.length > 0)) {
     andQuery = true;
     queries = queries +1;
      if (Array.isArray(directory)) {
       var dirParams = [];
       directoryQuery = 'cts.directoryQuery(['
       for (var i = 0; i < directory.length; i++) {
         dirParams.push(directory[i]);
       }
       directoryQuery = cts.directoryQuery(dirParams);
     } else {
       directoryQuery = cts.directoryQuery(directory);
     }
   };
   /*
     In order to be able to handle both XML and JSON without knowing beforehand,
     cts.orQuery needs to be used:
     cts.orQuery([cts.elementValueQuery(xs.QName("addressLine1"), "4092 Furth Circle"),cts.jsonPropertyValueQuery("addressLine1", "4092 Furth Circle")])
     If there is filtering on multiple fields (field1, field2)
       cts.orQuery([field1 XML, field1 JSON]),cts.orQuery([field2 XML, field2 JSON])
   */
   if ((fieldQuery)) {
      andQuery = true;
      queries = queries +1;
       var ctsFieldQuery = "";
       for (var field in fieldQuery) {
         if (ctsFieldQuery != "") {
           ctsFieldQuery = ctsFieldQuery + ',';
         }
         var query = cts.orQuery([cts.elementValueQuery(xs.QName(field), fieldQuery[field].value),cts.jsonPropertyValueQuery(field, fieldQuery[field].value)])
         ctsFieldQuery = ctsFieldQuery + query;
       };
   };

   if (mlVersion >= "8.0-5") {
     ctsQuery = cts.parse(qText);

   } else {
     var parseQuery = xdmp.xqueryEval(
             'xquery version "1.0-ml";  ' +
             'import module namespace search = "http://marklogic.com/appservices/search"  ' +
             '    at "/MarkLogic/appservices/search/search.xqy";  ' +
             'declare variable $qtext as xs:string external;  ' +
             'search:parse($qtext)',
              { '{}qtext': qText });
       ctsQuery = cts.query(parseQuery);
   };
  return (andQuery) ? cts.andQuery([ctsQuery,ctsFieldQuery,collectionQuery,directoryQuery]) : ctsQuery;
 }

/* exports.flattenJsonArray = flattenJsonArray; */
exports.flattenJsonObject = flattenJsonObject;
exports.fields2array = fields2array;
exports.summaryResult = summaryResult;
exports.getCtsQuery = getCtsQuery;
exports.getFlatResult = getFlatResult;
