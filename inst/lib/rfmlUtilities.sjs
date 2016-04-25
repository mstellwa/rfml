/******************************************************************************
 * Various helper functions used by rfml
 * Author: Mats Stellwall
 ******************************************************************************/

 /**
 * Check if a value is numeric
 * returns true if and false if not.
 *
 *  @property {} n - the value to test
 */
function isNumeric(n) {
 return !isNaN(parseFloat(n)) && isFinite(n);
}

/**
 * Flatten a json documet
 *
 *  @property {Object} data - the JSON object to flatten
 *  @property {Object} result - the JSON object to add it to
 *  @property {boolean} retFieldDef - if only field information should be returned
 *  @property {string} docFormat - what format the source was orginaly in XML/JSON
 *  @property {string} docXmlns - the namespace that the orginal XML is using
 */
function flatten(data, result, retFieldDef, docFormat, docXmlns) {
    function recurse (cur, prop, name, path) {
        /* if cur is a value */
        if (Object(cur) !== cur) {
          /* If we only want to extract metadata */
          if (retFieldDef) {
            if (result[prop]) {
               if (result[prop].fieldType == 'number' && !isNumeric(cur)) {
                 result[prop].fieldType = 'string';
               };
             } else {
               result[prop] = {"fieldType":isNumeric(cur) ? 'number' : 'string',
                                         "fieldDef":prop, "orgField": name,
                                         "orgPath" : path,
                                         "orgFormat":docFormat, "xmlns": docXmlns};
             }
          } else {
            result[prop] = cur;
          }
        } else if (Array.isArray(cur)) {
            /* For arrays we will generate a filed namned number */
           for(var i=0, l=cur.length; i<l; i++) {
               recurse(cur[i], prop + (i + 1), prop, path);
           }
            if (l == 0) {
                result[prop] = [];
            }
        } else {
            var isEmpty = true;
            for (var p in cur) {
              isEmpty = false;
              if ((typeof cur[p] === 'object')) {
                /* Use only first and last character in the name of the parent
                   in order to keep field names short */
                var newName = p.slice(0,1) +''+ p.slice(-1)
                recurse(cur[p], prop ? prop+newName+1: newName+1, p+1, path + "/"+ p);
              } else {
                recurse(cur[p], prop ? prop+p: p, p, path + "/"+ p);
              }
            }
            if (isEmpty && prop) {
                result[prop] = {};
            }
        }
    }
    recurse(data, "", "", "");
    return result;
}
/**
 * Primary function for flatten results. If the document is in XML it will converted
 * to JSON first.
 *
 * @property {Object} docRaw - the object to flatten can be XML/JSON
 * @property {string} docFormat - what format the source was orginaly in XML/JSON
 * @property {Object} searchRelatedVals - object contianing search specific information, scores and URI
 * @property {Object} addFields - user defined fields
 * @property {Object} extrFields - if only part of result is returned the fields to return in is this object
 * @property {boolean} sourceFlat - if the source data is already flat
 */
 function getFlatResult(docRaw, docFormat, searchRelatedVals, addFields, extrFields, sourceFlat) {
   var xml2json = require('/ext/rfml/xml2json.sjs');
   var resultContent;
   var mlVersion = xdmp.version();
   switch (docFormat) {
     /* XML format result from jsearch */
     case 'element':
       var itr = xdmp.unquote(docRaw.toString());
       var xmlContent;
       if(itr instanceof ValueIterator && 'function' === typeof itr.next) {
           xmlContent = itr.next().value;
       } else {
           xmlContent = fn.head(itr);
       }
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
   if (sourceFlat) {
    for (field in resultContent) {
      flatDoc[field] = resultContent[field];
    }
   } else {
     flatDoc = flatten(resultContent, flatDoc, false, "", "") ;
   }

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

/**
* Returns a flatten result set using cts.search
*
* @property {cts.query} whereQuery - a cts.query used for the search
* @property {integer} pageStart - One-based index of the first document to return.
* @property {integer} getRows - The one-based index of the document after the last document to return
* @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
* @property {boolean} docUri - If the uri should be returned
* @property {object} addFields - Additional fields to add to the results
* @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
* @property {boolean} sourceFlat - if the source data is already flat
*/
function getDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extrFields, sourceFlat) {
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
    var flatDoc = getFlatResult(result, result.documentFormat, searchRelatedVals, addFields, extrFields, sourceFlat);
    flatResult.push(flatDoc);
  };
  return {"results":flatResult};
}
/***********************************************************************************************************
* Returns a flatten result set using jsearch
*
* @property {cts.query} whereQuery - a cts.query used for the search
* @property {integer} pageStart - One-based index of the first document to return.
* @property {integer} getRows - The one-based index of the document after the last document to return
* @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
* @property {boolean} docUri - If the uri should be returned
* @property {object} addFields - Additional fields to add to the results
* @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
* @property {boolean} sourceFlat - If the source is already flat
************************************************************************************************************/
function getDataJS(whereQuery, pageStart,getRows, relevanceScores, docUri, addFields, extrFields, sourceFlat) {
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
                         return getFlatResult(docRaw, docRaw.nodeKind, searchRelatedVals, addFields, extrFields, sourceFlat);
                   })
                   .result();
 }
 /***********************************************************************************************
 * Returns a array with the value pairs of the fields in fields
 *
 * @property {cts.query} whereQuery - a cts.query used for the search
 * @property {integer} pageStart - One-based index of the first document to return.
 * @property {integer} getRows - The one-based index of the document after the last document to return
 * @property {object} fields - The fields which values is added to the returned array.
 *************************************************************************************************/
 function fields2array(whereQuery, pageStart, getRows, fields) {
   var mlVersion = xdmp.version();
   var res = {};
     /* Check version and do diffrently */
   if (mlVersion >= "8.0-4") {
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

/**
 * Creates a result set that can be used to create a summary table (descreptive statsitcs).
 *
 * @property {cts.query} whereQuery - a cts.query used for the search
 * @property {integer} pageStart - One-based index of the first document to return.
 * @property {integer} getRows - The one-based index of the document after the last document to return
 * @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
 * @property {boolean} docUri - If the uri should be returned
 * @property {object} addFields - Additional fields to add to the results
 * @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
 */
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
  /* Add the values for each filed in a array for that field name */
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
/**
 * Gets data using cts.search/jsearch, add additional fields and flatten the result
 *
 * @property {cts.query} whereQuery - a cts.query used for the search
 * @property {integer} pageStart - One-based index of the first document to return.
 * @property {integer} getRows - The one-based index of the document after the last document to return
 * @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
 * @property {boolean} docUri - If the uri should be returned
 * @property {object} addFields - Additional fields to add to the results
 * @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
 * @property {boolean} sourceFlat - If the source data is already flat
 */
 function getResultData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat) {
  var mlVersion = xdmp.version();
    /* Check version and do diffrently */
  if (mlVersion >= "8.0-4") {
      pageStart = pageStart -1;
      return getDataJS(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat);
  } else {
     return getDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat)
  };
}

/**
 * Gets metadata using jsearch
 *
 * @property {cts.query} whereQuery - a cts.query used for the search
 * @property {integer} getRows - The one-based index of the document after the last document to return
 * @property {object} docFields -
 */
 function getMetaDataJS(whereQuery, getRows, docFields) {
   var jsearch = require('/MarkLogic/jsearch.sjs');
   var xml2json = require('/ext/rfml/xml2json.sjs');
   var mlVersion = xdmp.version();

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
                             var itr = xdmp.unquote(docRaw.toString());
                             var xmlContent;
                             if(itr instanceof ValueIterator && 'function' === typeof itr.next) {
                                 xmlContent = itr.next().value;
                             } else {
                                 xmlContent = fn.head(itr);
                             }
                             var nsArr = xmlContent.xpath('./*/namespace::*/data()').toArray();
                             var xmlns = '';
                             for (var i = 0; i < nsArr.length; i++) {
                               if (nsArr[i] == "http://www.w3.org/XML/1998/namespace") {
                                 continue;
                               }
                               xmlns = nsArr[i];
                             }
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
                         docFields =  flatten(resultContent, docFields, true, orgFormat, xmlns);

                   })
                   .result();

   var dfInfoDoc = {
     "ctsQuery": whereQuery,
     "nrows": x.estimate,
     "dataFrameFields": docFields
   };

   return dfInfoDoc;

 }
 /**
  * Gets metadata using cts.search
  *
  * @property {cts.query} whereQuery - a cts.query used for the search
  * @property {integer} getRows - The one-based index of the document after the last document to return
  * @property {object} docFields -
  */
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
         var nsArr = result.xpath('./*/namespace::*/data()').toArray();
         var xmlns = '';
         for (var i = 0; i < nsArr.length; i++) {
           if (nsArr[i] == "http://www.w3.org/XML/1998/namespace") {
             continue;
           }
           xmlns = nsArr[i];
         }
         break;
       case "JSON":
         resultContent = result.toObject();
         break;
       default:
         continue;
     };
     docFields =  flatten(resultContent, docFields, true, result.documentFormat, xmlns);
   };
   var dfInfoDoc = {
     "ctsQuery": whereQuery,
     "nrows": nEstimate,
     "dataFrameFields": docFields
   };
   return dfInfoDoc;
 }
 /**
  * Primary function for getting metadata using cts.search/jsearch
  *
  * @property {cts.query} whereQuery - a cts.query used for the search
  * @property {integer} getRows - The one-based index of the document after the last document to return
  * @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
  * @property {boolean} docUri - If the uri should be returned
  * @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
  */
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
/**
 * Generates a cts query based on search text, collections and directory
 *
 * @property {string} qText - a text string query
 * @property {Object} colls - collections to search on
 * @property {Object} dirs - directories to search on
 * @property {Object} fields - elementValueQuery/elementRangeQuery definitions
 */
function getCtsQuery(qText, colls, dirs, fields) {
    var ctsQuery,collectionQuery, directoryQuery;
    var mlVersion = xdmp.version();

    // count arguments to decide if and query...
    var queries = 0;

    if ((colls) && (colls.length > 0)) {
      queries = queries +1;
      if (Array.isArray(colls)) {
        var collParams = [];
        for (var i = 0; i < colls.length; i++) {
          collParams.push(colls[i]);
        }
        collectionQuery = cts.collectionQuery(collParams);
      } else {
        collectionQuery = cts.collectionQuery(colls);
      }
    };

    if ((dirs) && (dirs.length > 0)) {
      queries = queries +1;
       if (Array.isArray(dirs)) {
        var dirParams = [];
        for (var i = 0; i < dirs.length; i++) {
          dirParams.push(dirs[i]);
        }
        directoryQuery = cts.directoryQuery(dirParams);
      } else {
        directoryQuery = cts.directoryQuery(dirs);
      }
    };
    /*
      In order to be able to handle both XML and JSON without knowing beforehand,
      cts.orQuery needs to be used:
      cts.orQuery([cts.elementValueQuery(xs.QName("addressLine1"), "4092 Furth Circle"),cts.jsonPropertyValueQuery("addressLine1", "4092 Furth Circle")])
      If there is filtering on multiple fields (field1, field2)
        cts.orQuery([field1 XML, field1 JSON]),cts.orQuery([field2 XML, field2 JSON])
    */
    if ((fields)) {
       queries = queries +1;
        var ctsFieldQuery = [];
        for (var field in fields) {
          switch(fields[field].operator) {
            case "==":
              ctsFieldQuery.push(cts.orQuery([cts.elementValueQuery(fn.QName((fields[field].xmlns != "NA") ? fields[field].xmlns : "",field), fields[field].value),cts.jsonPropertyValueQuery(field, fields[field].value)]));
              break;
            default:
              ctsFieldQuery.push(cts.orQuery([cts.elementRangeQuery(fn.QName((fields[field].xmlns != "NA") ? fields[field].xmlns : "",field),fields[field].operator, fields[field].value),
                                             cts.jsonPropertyRangeQuery(field,fields[field].operator, fields[field].value)]));
          }
        };
    };
    if (qText != "") {
       queries = queries +1;
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
    }
    if (queries > 1) {
      return cts.andQuery([ctsQuery,ctsFieldQuery,collectionQuery,directoryQuery]);
    } else {
      return (ctsQuery) ? ctsQuery : (ctsFieldQuery) ? ctsFieldQuery : (collectionQuery) ? collectionQuery : directoryQuery;
    }
  }
/**
 * Generates and save documents based on a cts query using cts search
 *
 * @property {cts.query} whereQuery - a cts.query used for the search
 * @property {integer} pageStart - One-based index of the first document to return.
 * @property {integer} getRows - The one-based index of the document after the last document to return
 * @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
 * @property {boolean} docUri - If the uri should be returned
 * @property {object} addFields - Additional fields to add to the results
 * @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
 * @property {string} collection - the collection to save the documents into
 * @property {string} directory - the directory to save the documents into
 * @property {boolean} sourceFlat - if the source data is already flat
 */
function saveDfDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields,
                       extrFields, collection, directory, sourceFlat) {
 var path = typeof path !== 'undefined' ?  path : "";
 var resultContent;
 var flatResult = [];
 var nEstimate = cts.estimate(whereQuery);
 var results = fn.subsequence(cts.search(whereQuery), pageStart, getRows);
 var i = 0;
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
   var saveDoc = getFlatResult(result, result.documentFormat, searchRelatedVals, addFields, extrFields, sourceFlat);
   var ext = result.documentFormat;
   var docURI =  directory + i + ext;
   xdmp.documentInsert(docURI, saveDoc, xdmp.defaultPermissions(), collection);
   i += 1;
 };
 return true;
}
/**
 * Generates and save documents based on a cts query using jsearch
 *
 * @property {cts.query} whereQuery - a cts.query used for the search
 * @property {integer} pageStart - One-based index of the first document to return.
 * @property {integer} getRows - The one-based index of the document after the last document to return
 * @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
 * @property {boolean} docUri - If the uri should be returned
 * @property {object} addFields - Additional fields to add to the results
 * @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
 * @property {string} collection - the collection to save the documents into
 * @property {string} directory - the directory to save the documents into
 */
function saveDfDataJS(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extrFields, collection, directory) {

 var jsearch = require('/MarkLogic/jsearch.sjs');
 var x = jsearch.documents()
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

                       var saveDoc = getFlatResult(docRaw, docRaw.nodeKind, searchRelatedVals, addFields, extrFields);
                       var ext = (docRaw.nodeKind === 'element') ? '.XML' : '.JSON';
                       var docURI =  directory + match.index + ext;
                       xdmp.documentInsert(docURI, saveDoc, xdmp.defaultPermissions(), collection);
                  })
                  .result();
    return true;
}
/**
 * Primary function for generating and save documents based on a cts query using jsearch/cts.search
 *
 * @property {cts.query} whereQuery - a cts.query used for the search
 * @property {integer} pageStart - One-based index of the first document to return.
 * @property {integer} getRows - The one-based index of the document after the last document to return
 * @property {boolean} relevanceScores - If the score, confidence and fitness values should be returned
 * @property {boolean} docUri - If the uri should be returned
 * @property {object} addFields - Additional fields to add to the results
 * @property {object} extrFields - Fields that should be extracted from the results and returned instead of all fields.
 * @property {string} collection - the collection to save the documents into
 * @property {string} directory - the directory to save the documents into
 */
function saveDfData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, saveCollection, saveDirectory) {
  var mlVersion = xdmp.version();
    /* Check version and do diffrently */
  if (mlVersion >= "8.0-4") {
      pageStart = pageStart -1;
      return saveDfDataJS(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, saveCollection, saveDirectory);
  } else {
     return saveDfDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, saveCollection, saveDirectory);
  };
}
exports.fields2array = fields2array;
exports.getMatrixResult = getMatrixResult;
exports.getCtsQuery = getCtsQuery;
exports.getResultData = getResultData;
exports.getResultMetadata = getResultMetadata;
exports.saveDfData = saveDfData;
