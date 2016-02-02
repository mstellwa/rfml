/******************************************************************************
 * Gets data using jsearch, add additional fields and flatten the result
 ******************************************************************************/
 function getDataJS(whereQuery, pageStart,getRows, relevanceScores, docUri, addFields, extrFields) {
   var jsearch = require('/MarkLogic/jsearch.sjs');
   var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');

   return  jsearch.documents()
                 .where(whereQuery)
                 .slice(pageStart-1,getRows)
                 .map(function (match) {
                         var docRaw = match.document;
                         var resultContent;
                         var searchRelatedVals = {};
                         if (docUri) {
                           searchRelatedVals.docUri = match.uri;
                         };

                         if (relevanceScores) {
                           searchRelatedVals.score = match.score;
                           searchRelatedVals.confidence = match.confidence;
                           searchRelatedVals.fitness = match.fitness;
                         };
                         return rfmlUtilities.getFlatResult(docRaw, docRaw.nodeKind, searchRelatedVals, addFields, extrFields);
                   })
                   .result();
 }
/******************************************************************************
 * Gets data using cts.search, add additional fields and flatten the result
 ******************************************************************************/
function getDataCts(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extrFields) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var resultContent;
  var flatResult = [];
  var nEstimate = cts.estimate(whereQuery);
  var results = fn.subsequence(cts.search(whereQuery), pageStart, getRows);

  for (var result of results) {
    var searchRelatedVals = {};
    if (docUri) {
      searchRelatedVals.docUri = match.uri;
    };

    if (relevanceScores) {
      searchRelatedVals.score = match.score;
      searchRelatedVals.confidence = match.confidence;
      searchRelatedVals.fitness = match.fitness;
    };
    var flatDoc = rfmlUtilities.getFlatResult(result, result.documentFormat, searchRelatedVals, addFields, extrFields);
    flatResult.push(flatDoc);
  };
  return {"results":flatResult};
}
/******************************************************************************
 * Gets data using cts.search/jsearch, add additional fields and flatten the result
 ******************************************************************************/
 function resultData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields) {
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
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
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
                        docFields = rfmlUtilities.flattenJsonObject(resultContent, docFields, "", true, orgFormat,"");

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
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
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
    docFields =  rfmlUtilities.flattenJsonObject(resultContent, docFields, "", true, result.documentFormat,"");
  };
  var dfInfoDoc = {
    "ctsQuery": whereQuery,
    "nrows": nEstimate,
    "dataFrameFields": docFields
  };
  return dfInfoDoc;
}
function resultMetadata(whereQuery, getRows, relevanceScores, docUri, extFields) {
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
      return getMetaDataJS(whereQuery, getRows, docFields);
  } else {
     return getMetaDataCts(whereQuery, getRows, docFields);
  };

}

/******************************************************************************
 * Primnary GET function
 ******************************************************************************/
 function get(context, params) {
   var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
   /* parmeters */
   var qText = (params.q) ? params.q : "";
   var collections = params.collection;
   var directory = params.directory;
   var pageLength = params.pageLength;
   var pageStart = (parseInt(params.start) > 0) ? parseInt(params.start) : 1;
   var returnFormat = params.return;
   var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
   var docUri = params.docUri == "TRUE" ? true : false;

   var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;
   var extFields;
   var fieldQuery;

   context.outputTypes = ['application/json'];
   if (params.extfields) {
     extFields = JSON.parse(params.extfields);
   }

   if (params.fieldQuery) {
     fieldQuery = JSON.parse(params.fieldQuery);
   }
   var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory, fieldQuery);
   if (params.return == 'data') {
     var addFields = {};
     if (params.fields) {
       addFields = JSON.parse(params.fields);
     }
     return resultData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields);
   } else {
     return resultMetadata(whereQuery, getRows, relevanceScores, docUri, extFields);
   };
   //return whereQuery;
 }
 function put(context, params, input) {
   var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
   /* parmeters */
   var qText = (params.q) ? params.q : "";
   var collections = params.collection;
   var directory = params.directory;
   var pageLength = params.pageLength;
   var pageStart = (parseInt(params.start) > 0) ? parseInt(params.start) : 1;
   var returnFormat = params.return;
   var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
   var docUri = params.docUri == "TRUE" ? true : false;

   var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;
   var extFields;
   var fieldQuery;

   context.outputTypes = ['application/json'];


   if (params.extfields) {
     extFields = JSON.parse(params.extfields);
   }

   if (params.fieldQuery) {
     fieldQuery = JSON.parse(params.fieldQuery);
   }
   var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory, fieldQuery);
   /* save all result from the query into a new documents
      using directory and collection parameters */


 }
 exports.GET = get;
 exports.PUT = put;
