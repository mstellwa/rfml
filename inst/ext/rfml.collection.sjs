function getCollections(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var qText = (params.q) ? params.q : "";
  var whereQuery;
  if (qText != '') {
      whereQuery = rfmlUtilities.getCtsQuery(qText, null, null, null);
  };
  context.outputTypes = ['application/json'];

  return cts.collections(null,null, whereQuery);
}

 exports.GET = getCollections;
