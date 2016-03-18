/*
  Returns either a list of all collections or a sample structure of a specific collection
*/
// query
function getCollections(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var qText = (params.q) ? params.q : "";
  /* If we have a collection we will get the structure */
  var collection = (params.collection) ? params.collection : "";
  var whereQuery;
  if (qText != '' || collection != '') {
      whereQuery = rfmlUtilities.getCtsQuery(qText, collection, null, null);
  };
  context.outputTypes = ['application/json'];
  if (collection != '') {
    return rfmlUtilities.getResultMetadata(whereQuery, 30, false, false, {});
  } else {
    var lsColl = cts.collections(null,null, whereQuery);
    return xdmp.toJsonString(lsColl);
  }
}

 exports.GET = getCollections;
