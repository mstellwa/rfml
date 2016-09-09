
/******************************************************************************
 * Primnary GET function
 ******************************************************************************/
function getDframe(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  /* Structured query text */
  var qText = (params.q) ? params.q : "";
  /* values for collectionQuery */
  var collections = (params.collection) ? JSON.parse(params.collection): null;
  /* values for directoryQuery */
  var directory = (params.directory) ? JSON.parse(params.directory): null;
  /* values and operator for elementValueQuery/elementRangeQuery/jsonPropertyRangeQuery */
  var fieldQuery = (params.fieldQuery) ? JSON.parse(params.fieldQuery) : null;
  /* Number of documents to return, default is 30 */
  var getRows = (parseInt(params.pageLength) > 0) ? parseInt(params.pageLength) : 30;
  /* Index of first document to return, default 1 */
  var pageStart = (parseInt(params.start) > 0) ? parseInt(params.start) : 1;
  /* If documents or information about documents are going to be returned */
  var returnFormat = params.return;
  /* If relevance scores is going to be returned with the result/information about the result */
  var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
  /* If document uri is going to be returned with the result/information about the result */
  var docUri = params.docUri == "TRUE" ? true : false;
  /* If the source documents are flat, only works for JSON */
  var sourceFlat = params.sourceFlat == "TRUE" ? true : false;
  /* Fields that is going to be returned. If empty all. */
  var extFields = (params.extfields) ? JSON.parse(params.extfields) : null;

  context.outputTypes = ['application/json'];

  var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory, fieldQuery);

  switch(params.return) {
    case 'data':
       var addFields = {};
       if (params.fields) {
         addFields = JSON.parse(params.fields);
       }
      //return rfmlUtilities.getResultData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat);
      return rfmlUtilities.getResultNdJson(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat);
      break;
    case 'rowCount':
      return cts.estimate(whereQuery);
      break;
    //return whereQuery;
    default:
     return rfmlUtilities.getResultMetadata(whereQuery, getRows, relevanceScores, docUri, extFields);
   }
 }

 function saveDframe(context, params, input) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var qText = (params.q) ? params.q : "";
  var collections = (params.collection) ? JSON.parse(params.collection): null;
  var directory = (params.directory) ? JSON.parse(params.directory): null;
  var pageLength = params.pageLength;
  var pageStart = (parseInt(params.start) > 0) ? parseInt(params.start) : 1;
  var returnFormat = params.return;
  var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
  var docUri = params.docUri == "TRUE" ? true : false;
  var saveCollection = params.saveCollection;
  var saveDirectory = params.saveDirectory;
  var sourceFlat = params.sourceFlat == "TRUE" ? true : false;

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
  var addFields = {};
  if (params.fields) {
      addFields = JSON.parse(params.fields);
  }
     /* save all result from the query into a new documents
     using directory and collection parameters */
  var saved = rfmlUtilities.saveDfData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, saveCollection, saveDirectory, sourceFlat);
  context.outputStatus = [204, 'ml.data.frame data Saved'];
}


function rmRfmlData(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var collection = params.collection;
  var directory = params.directory;

  context.outputTypes = ['application/json'];

  var delUris = cts.uris("", null,cts.andQuery([cts.collectionQuery(collection), cts.directoryQuery(directory)])).toArray();
  for (var i = 0; i < delUris.length; i++) {
     xdmp.documentDelete(delUris[i]);
  }
  context.outputStatus = [204, 'ml.data.frame data Deleted'];
}
 exports.GET = getDframe;
 exports.PUT = saveDframe;
 exports.DELETE = rmRfmlData;
