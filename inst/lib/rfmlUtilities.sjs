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

function getFlatResult(docRaw, docFormat, searchRelatedVals, addFields, extrFields) {
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
  for (var field in addFields) {
    var fieldName = field;
    var fieldDef = addFields[field].fieldDef;
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
/***********************************************************************************************************
* Returns a flatten result set using cts.search
*
* whereQuery - a cts.query used for the search
* pageStart - integer. One-based index of the first document to return.
* getRows - integer. 	The one-based index of the document after the last document to return
* relevanceScores - boolean. If the score, confidence and fitness values should be returned
* docUri - boolean. If the uri should be returned
* addFields - object. Additional fields to add to the results
* extrFields - object. Fields that should be extracted from the results and returned instead of all fields.
************************************************************************************************************/
function getDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extrFields) {
  var path = typeof path !== 'undefined' ?  path : "";
  var resultContent;
  var flatResult = [];
  var nEstimate = cts.estimate(whereQuery);
  var results = fn.subsequence(cts.search(whereQuery), pageStart, getRows);

  for (var result of results) {
    var searchRelatedVals = {};
    if (docUri) {
      searchRelatedVals.docUri = results.uri;
    };

    if (relevanceScores) {
      searchRelatedVals.score = results.score;
      searchRelatedVals.confidence = results.confidence;
      searchRelatedVals.fitness = results.fitness;
    };
    var flatDoc = getFlatResult(result, result.documentFormat, searchRelatedVals, addFields, extrFields);
    flatResult.push(flatDoc);
  };
  return {"results":flatResult};
}
/***********************************************************************************************************
* Returns a flatten result set using jsearch
*
* whereQuery - a cts.query used for the search
* pageStart - integer. Zero-based index of the first document to return.
* getRows - integer. 	The zero-based index of the document after the last document to return
* relevanceScores - boolean. If the score, confidence and fitness values should be returned
* docUri - boolean. If the uri should be returned
* addFields - object. Additional fields to add to the results
* extrFields - object. Fields that should be extracted from the results and returned instead of all fields.
************************************************************************************************************/
function getDataJS(whereQuery, pageStart,getRows, relevanceScores, docUri, addFields, extrFields) {
  var jsearch = require('/MarkLogic/jsearch.sjs');
  return jsearch.documents()
                 .where(whereQuery)
                 .slice(pageStart,getRows)
                 .map(function (match) {
                         var docRaw = match.document;
                         var flatDoc = {};
                         var searchRelatedVals = {};
                         if (docUri) {
                           searchRelatedVals.docUri = match.uri;
                         };

                         if (relevanceScores) {
                           searchRelatedVals.score = match.score;
                           searchRelatedVals.confidence = match.confidence;
                           searchRelatedVals.fitness = match.fitness;
                         };

                        return getFlatResult(docRaw, docRaw.nodeKind, searchRelatedVals, addFields, extrFields);
                   })
                   .result();
 }
 /***********************************************************************************************
 * Returns a array with the value pairs of the fields in fields
 *
 * whereQuery - a cts.query used for the search
 * pageStart - integer. one-based index of the first document to return.
 * getRows - integer. 	The one-based index of the document after the last document to return
 * fields - object. The fields which vales is added to the returned array.
 *************************************************************************************************/
 function fields2array(whereQuery, pageStart, getRows, fields) {
   var mlVersion = xdmp.version();
   var res = {};
     /* Check version and do diffrently */
   if (mlVersion >= "8.0-6") {
     /* jsearch DocumentsSearch.slice starts on 0 so we need to decrease with 1 (subsequence used in with cts starts at 1) */
     pageStart = pageStart -1;
     res = getDataJS(whereQuery, pageStart,getRows, true, true, fields, fields)
   } else {
     res = getDataCts(whereQuery, pageStart, getRows, true, true, fields, fields)
   };
  var resArray = res.results;
  var flatResult = [];
  for (var i=0; i<resArray.length;i++) {
      var useFields = [];
      for (var field in resArray[i]) {
        useFields.push(resArray[i][field])
      };
      flatResult.push(useFields);
    }
    return flatResult;
}

/***********************************************************************
 * Creates a result set that can be used to create
 * summary (descreptive statsitcs).
 ************************************************************************/
function getMatrixResult(whereQuery, pageStart,getRows, relevanceScores, docUri, addFields, extFields) {
  var mlVersion = xdmp.version();
  var res = {};
  if (mlVersion >= "8.0-4") {
    /* jsearch DocumentsSearch.slice starts on 0 so we need to decrease with 1 (subsequence used in with cts starts at 1) */
    pageStart = pageStart -1;
    res = getDataJS(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields,extFields);
  } else {
    res = getDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields);
  };
  var resArray = res.results;
  var flatResult = {};
  for (var i=0; i<resArray.length;i++) {
    for (var field in resArray[i]) {
      if (flatResult[field]) {
        if (flatResult[field].fieldType == 'number' && !isNumeric(resArray[i][field])) {
          flatResult[field].fieldType = 'string';
        };
        flatResult[field].values.push(isNumeric(resArray[i][field]) ? parseFloat(resArray[i][field]) : resArray[i][field])
      } else {
        flatResult[field] = {"fieldType":isNumeric(resArray[i][field]) ? 'number' : 'string',
                             'values' : [isNumeric(resArray[i][field]) ? parseFloat(resArray[i][field]) : resArray[i][field]]};
      }
    }
  }
  return flatResult;
}
/******************************************************************************
 * Gets data using cts.search/jsearch, add additional fields and flatten the result
 ******************************************************************************/
 function getResultData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields) {
   var mlVersion = xdmp.version();
     /* Check version and do diffrently */
   if (mlVersion >= "8.0-4") {
       return getDataJS(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields);
   } else {
      return getDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields)
   };
 }
 /******************************************************************************
  * Gets metadata using jsearch
  ******************************************************************************/
 function getMetaDataJS(whereQuery, getRows, docFields) {
   var jsearch = require('/MarkLogic/jsearch.sjs');
   var xml2json = require('/ext/rfml/xml2json.sjs');

     var x  = jsearch.documents()
                 .where(whereQuery)
                 .slice(0,getRows)
                 .map(function (match) {
                         var docRaw = match.document;
                         var orgFormat = "";
                         var resultContent;
                         switch (docRaw.nodeKind) {
                           case 'element':
                             orgFormat = 'XML';
                             var xmlContent = xdmp.unquote(docRaw.toString()).next().value;
                             var x2js = new xml2json.X2JS();
                             var resultContent = x2js.xml2json( xmlContent );
                             break;
                           case 'object':
                             orgFormat = 'JSON';
                             var resultContent = JSON.parse(docRaw);
                             break;
                           default:
                             return;
                         };
                         //getFlatResult(docRaw, docRaw.nodeKind, searchRelatedVals, addFields, extrFields);
                         docFields = flattenJsonObject(resultContent, docFields, "", true, orgFormat,"");

                   })
                   .result();

   var dfInfoDoc = {
     "ctsQuery": whereQuery,
     "nrows": x.estimate,
     "dataFrameFields": docFields
   };

   return dfInfoDoc;

 }
 /******************************************************************************
  * Gets metadata using cts.search
  ******************************************************************************/
 function getMetaDataCts(whereQuery, getRows, docFields) {
   var xml2json = require('/ext/rfml/xml2json.sjs');
   var resultContent;
   var nEstimate = cts.estimate(whereQuery);
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
     docFields =  flattenJsonObject(resultContent, docFields, "", true, result.documentFormat, "");
   };
   var dfInfoDoc = {
     "ctsQuery": whereQuery,
     "nrows": nEstimate,
     "dataFrameFields": docFields
   };
   return dfInfoDoc;
 }
 function getResultMetadata(whereQuery, getRows, relevanceScores, docUri, extFields) {
   var mlVersion = xdmp.version();

   var docFields = {};
   if (docUri) {
       docFields.docUri = {"fieldType":'string', "fieldDef":'docUri'};
   };
   if (relevanceScores) {
       docFields.score = {"fieldType":'number', "fieldDef":'score'};
       docFields.confidence = {"fieldType":'number', "fieldDef":'confidence'};
       docFields.fitness = {"fieldType":'number', "fieldDef":'fitness'};
   };

   /* Check version and do diffrently */
   if (mlVersion >= "8.0-4") {
     return getMetaDataJS(whereQuery, getRows, docFields)
   } else {
      return getMetaDataCts(whereQuery, getRows, docFields);
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
       var ctsFieldQuery = [];
       for (var field in fieldQuery) {
         ctsFieldQuery.push(cts.orQuery([cts.elementValueQuery(xs.QName(field), fieldQuery[field].value),cts.jsonPropertyValueQuery(field, fieldQuery[field].value)]));
       };
   };

   if (mlVersion >= "8.0-4") {
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

exports.fields2array = fields2array;
exports.getMatrixResult = getMatrixResult;
exports.getCtsQuery = getCtsQuery;
exports.getResultData = getResultData;
exports.getResultMetadata = getResultMetadata;
