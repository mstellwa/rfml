/* The function returns frequent itemsets based on itemField that occurs at minimum supp times
   and consist of minimum minlen and maximum maxlen items.
   whereQuery is used to limit the data used and must be a cts.query */
function getFreqItemSets(itemField, whereQuery, supp, totTrans ,minlen, maxlen) {
  /* calculate the minimum support count */
  var minTransSupp = supp;
  var frequentItemSets = {};
  var itemSetSize = 1;
  /* for minlen to maxlen */
  for (var i = minlen; i <= maxlen; i++) {
    var elementRefs = [];
    for (var j = 1; j <= i; j++) {
    	elementRefs.push(cts.elementReference(xs.QName(itemField)));
    };
    var itemSet = cts.valueTuples(elementRefs, 'ordered', whereQuery);
    var itemSetFreq = [];
    for (var item of itemSet) {
     var freq = cts.frequency(item);
     if (freq >= minTransSupp) {
         // using toObject to ensure we are storing a array
        itemSetFreq.push({"itemSet":item.toObject(), "absSupport":freq, "support": freq/totTrans});
     }
    }
    if (itemSetFreq.length > 0) {
      frequentItemSets[itemSetSize] = itemSetFreq
      itemSetSize += 1;
    }
  }

  return frequentItemSets;
}

function getAssociationRules(frequentItemSets, minConfidence) {
  /* internal helper functions */

  /* returns the itemset from f */
  var extractItemSet = function (f) {
    return f.itemSet;
  };
  /* Generates all possible subsets, including the itemset, of a itemset
     ex array = ["I1", "I2", "I5"] then
    allSubSets = [["I1"], ["I2"], ["I5"], ["I1", "I2"], ["I1", "I5"], ["I2", "I5"], ["I1", "I2", "I5"]] */
  var toAllSubSets = function (array) {
    var op = function (n, sourceArray, currentArray, allSubSets) {
      if (n === 0) {
        if (currentArray.length > 0) {
          allSubSets[allSubSets.length] = currentArray;
        }
      } else {
        for (var j = 0; j < sourceArray.length; j++) {
          var nextN = n - 1, nextArray = sourceArray.slice(j + 1), updatedCurrentSubSet = currentArray.concat([sourceArray[j]]);
          op(nextN, nextArray, updatedCurrentSubSet, allSubSets);
        }
      }
    };

    var allSubSets = [];
    array.sort();
    for (var i = 1; i < array.length; i++) {
      op(i, array, [], allSubSets);
    }
    allSubSets.push(array);
    return allSubSets;
  };
  /*
    Returns a array which contains the elements that is in arrayA but not in arrayB
    ex. arrayB = ["I1"], arrayA = ["I1", "I2", "I5"]
    diffArray = ["I2", "I5"]
  */
  var getDiffArray = function (arrayA, arrayB) {
    var diffArray = [];
    arrayA.forEach(function (e) {
      if (arrayB.indexOf(e) === -1)
        diffArray.push(e);
    });
    return diffArray;
  };

  /* create and save the rules, if they apply to the confidence threshold */
  var saveAssociationRuleFound = function (subsetItemSet) {
    var diffItemSet = getDiffArray(currentItemSet, subsetItemSet);
    if (diffItemSet.length > 0) {
      var itemSupport = frequencies[currentItemSet.toString()];
      var subsetSupport = frequencies[subsetItemSet.toString()];
      var confidence = itemSupport / subsetSupport;
      var diffItemSetSupport = frequencies[diffItemSet.toString()];
      var lift = (itemSupport / (subsetSupport * diffItemSetSupport ))
      if (!isNaN(confidence) && confidence >= minConfidence) {
        associationRules.push({"lhs":subsetItemSet,"rhs":diffItemSet, "support":itemSupport, "confidence":confidence, "lift":lift });
      }
    }
  };

  /*
    for a itemset, generate all possible subsets, and for each subset
    generate and add rules to associationRules
  */
  var saveAllAssociationRulesFound = function (itemSet) {
    currentItemSet = itemSet;
    toAllSubSets(currentItemSet).forEach(saveAssociationRuleFound);
  };

  /* main logic */
  var frequencies = {};
  var currentItemSet;
  var associationRules = [];
  /*
    Generate a objects with the frequencies of all itemsets
    Key is the itemset as a string.
    Ex ["18th century schooner", "1900s Vintage Bi-Plane", "1903 Ford Model A"]
        =>
       "18th century schooner,1900s Vintage Bi-Plane,1903 Ford Model A"
  */
  for (var itemSets in frequentItemSets) {
    for (var i = 0; i< frequentItemSets[itemSets].length; i++) {
      frequencies[frequentItemSets[itemSets][i].itemSet.toString()] = frequentItemSets[itemSets][i].support;
    };
  };

  /*
     Walk through all itemsets and get the rules for them.
     itemsets are grouped by the number of items they have.
     1,2,3 etc
   */
  for (var k in frequentItemSets) {
    /* get the all itemsets that has the same number of items */
    var itemSets = frequentItemSets[k].map(extractItemSet);
    if (itemSets.length === 0 || itemSets[0].length <= 1) {
      continue;
    }
    /* for each itemset add the rules into associationRules */
    itemSets.forEach(saveAllAssociationRulesFound);
  };
  return associationRules;
}

/******************************************************************************
 * Primnary GET function
 ******************************************************************************/
function arules(context, params) {
  var rfmlUtilities = require('/ext/rfml/rfmlUtilities.sjs');
  /* parmeters */
  var qText = (params.q) ? params.q : "";
  var collections = params.collection;
  var directory = params.directory;
  var minSupport = params.supp ? params.supp === 0 ? 0 : params.supp : 0.15;
  var minItems = params.minlen ? params.minlen === 0 ? 0 : params.minlen : 1;
  var maxItems = params.maxlen ? params.maxlen === 0 ? 0 : params.maxlen : 2;
  var minConf = params.conf ? params.conf === 0 ? 0 : params.conf : 0.5;
  var target = (params.target) ? params.target : "rules";

  var extFields;
  var fieldQuery;

  if (params.extfields) {
    extFields = JSON.parse(params.extfields);
  }

  context.outputTypes = ['application/json'];

  var fields = {};
  if (params.fields) {
     fields = JSON.parse(params.fields);
     /* Get the orginal name of the flatten fields */
    var orgFields = [];
    for (var field in fields) {
      orgFields.push({"name": fields[field].orgField, "format": fields[field].orgFormat});
     }
  }
  if (orgFields.length != 1 ) {
    /* we need to return a error if using more than one field */
    return null;
  }

  var field = orgFields[0].name;

  if (params.fieldQuery) {
    fieldQuery = JSON.parse(params.fieldQuery);
  }
  var whereQuery = rfmlUtilities.getCtsQuery(qText, collections, directory, fieldQuery);
  var transLength = cts.estimate(whereQuery);
  var minAbsSupp = transLength * minSupport;

  /* Get the frequent itemsets */
  var freqItemsSets = getFreqItemSets(field, whereQuery, minAbsSupp,transLength, minItems, maxItems);
  var associationRules;
  if (target == "rules") {
    /* Get the associationRules */
    associationRules = getAssociationRules(freqItemsSets,minConf);
  }
  //return associationRules;
  var arulesDoc = {'itemsets': freqItemsSets,'rules': associationRules};
  return arulesDoc;
}
exports.GET = arules;
