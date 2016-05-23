function dbInit(context, params) {
  var rfmlVersion = params.rfmlVersion;
  var rfmInitDate = params.initDate;
  var mlVersion = xdmp.version();
  context.outputTypes = ['application/json'];

  xdmp.documentInsert("/rfml/rfmlInfo.json", {"rfmlVersion":rfmlVersion, "rfmInitDate":rfmInitDate, "mlVersion": mlVersion }, xdmp.permission("rest-reader", "read"), "rfml")

  context.outputStatus = [204, 'rfml info Saved'];
  return null;
}

function dbCheck(context, params) {
  context.outputTypes = ['application/json'];
  return fn.doc("/rfml/rfmlInfo.json");
}

function dbDel(context, params) {
 xdmp.documentDelete("/rfml/rfmlInfo.json")
 context.outputStatus = [204, 'rfml info deleted'];
 return null;
}

exports.GET = dbCheck;
exports.PUT = dbInit;
exports.DELETE = dbDel;
