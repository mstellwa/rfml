function get(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var qText = (params.q) ? params.q : "";
  var whereQuery;
  if (qText != '') {
      whereQuery = rfmlUtilities.getCtsQuery(qText, null, null);
  };
  context.outputTypes = ['application/json'];

  return cts.collections(null,null, whereQuery);
}
function deleteFunction(context, params) {
  var collections = params.collection;
  //declareUpdate();
  xdmp.collectionDelete(collections);
  context.outputTypes = ['application/json'];
  return null;
}

 exports.GET = get;
 exports.DELETE = deleteFunction;
