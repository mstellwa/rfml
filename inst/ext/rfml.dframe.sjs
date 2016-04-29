
/******************************************************************************
 * Primnary GET function
 ******************************************************************************/
 function getDframe(context, params) {
   //console.log("getDframe start: %d", Date.now());
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
   var sourceFlat = params.sourceFlat == "TRUE" ? true : false;
   var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;
   var extFields = (params.extfields) ? JSON.parse(params.extfields) : null;
   var fieldQuery = (params.fieldQuery) ? JSON.parse(params.fieldQuery) : null;

   /*var outputTypes = [];
   for (var i = 0; i < pageLength; i++) {
     outputTypes.push('application/json');
   }*/
   //context.outputTypes = outputTypes;// ['application/json'];
   context.outputTypes = ['application/json'];//['text/plain'];

   var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory, fieldQuery);
   if (params.return == 'data') {
     var addFields = {};
     if (params.fields) {
       addFields = JSON.parse(params.fields);
     }
    //return rfmlUtilities.getResultData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat);
    return rfmlUtilities.getResultNdJson(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat);
    //return xdmp.arrayValues(rfmlUtilities.getResultData(whereQuery, pageStart, getRows, relevanceScores, docUri, addFields, extFields, sourceFlat).results);
   } else {
     return rfmlUtilities.getResultMetadata(whereQuery, getRows, relevanceScores, docUri, extFields);
   };
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
