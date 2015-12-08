/******************************************************************************
 * Gets data using jsearch, add additional fields and flatten the result
 ******************************************************************************/
function getDataJS(whereQuery, getRows, relevanceScores, docUri, fields) {
  var jsearch = require('/MarkLogic/jsearch.sjs');
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var xml2json = require('/ext/rfml/xml2json.sjs');

  return  jsearch.documents()
                .where(whereQuery)
                .slice(0,getRows)
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
                        if (docUri) {
                          flatDoc.docUri = match.uri;
                        };
                        if (relevanceScores) {
                          flatDoc.score = match.score;
                          flatDoc.confidence = match.confidence;
                          flatDoc.fitness = match.fitness;
                        };
                        flatDoc = rfmlUtilities.flattenJsonObject(resultContent, flatDoc, "", false);
                        for (var field in fields) {
                            var fieldName = field;
                            var fieldDef = fields[field].fieldDef;
                            flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
                        };

                        return flatDoc;

                  })
                  .result();
}
/******************************************************************************
 * Gets data using cts.search, add additional fields and flatten the result
 ******************************************************************************/
function getDataCts(whereQuery, getRows, relevanceScores, docUri, fields) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  var xml2json = require('/ext/rfml/xml2json.sjs');
  var resultContent;
  var flatResult = [];
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
    var flatDoc = {};
     /* add additional fields */
    if (docUri) {
      flatDoc.docUri = fn.documentUri(result);
    }
    if (relevanceScores) {
      flatDoc.score = cts.score(result);
      flatDoc.confidence = cts.confidence(result);
      flatDoc.fitness = cts.fitness(result);
    }

    flatDoc =  rfmlUtilities.flattenJsonObject(resultContent, flatDoc, "", false, result.documentFormat);
    for (var field in fields) {
      var fieldName = field;
      var fieldDef = fields[field].fieldDef;
      flatDoc[fieldName] = eval(fieldDef.replace(/rfmlResult/g, "flatDoc"));
    };

    flatResult.push(flatDoc);
  };
  return {"results":flatResult};
}
/******************************************************************************
 * Gets data using cts.search/jsearch, add additional fields and flatten the result
 ******************************************************************************/
function resultData(whereQuery, getRows, relevanceScores, docUri, fields) {
  var mlVersion = xdmp.version();
    /* Check version and do diffrently */
  if (mlVersion >= "8.0-4") {
      return getDataJS(whereQuery, getRows, relevanceScores, docUri, fields);
  } else {
     return getDataCts(whereQuery, getRows, relevanceScores, docUri, fields)
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
                        docFields = rfmlUtilities.flattenJsonObject(resultContent, docFields, "", true, orgFormat);

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
    docFields =  rfmlUtilities.flattenJsonObject(resultContent, docFields, "", true, result.documentFormat);
  };
  var dfInfoDoc = {
    "ctsQuery": whereQuery,
    "nrows": nEstimate,
    "dataFrameFields": docFields
  };
  return dfInfoDoc;
}
function resultMetadata(whereQuery, getRows, relevanceScores, docUri) {
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
  var returnFormat = params.return;
  var relevanceScores = params.relevanceScores == "TRUE" ? true : false;
  var docUri = params.docUri == "TRUE" ? true : false;

  var getRows = (parseInt(pageLength) > 0) ? parseInt(pageLength) : 30;

  context.outputTypes = ['application/json'];

  var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory );

  if (params.return == 'data') {
    var fields = {};
    if (params.fields) {
      fields = JSON.parse(params.fields);
    }
    return resultData(whereQuery, getRows, relevanceScores, docUri, fields);
  } else {
    return resultMetadata(whereQuery, getRows, relevanceScores, docUri);
  };
}
exports.GET = get;
