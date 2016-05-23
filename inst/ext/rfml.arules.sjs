/* The function returns frequent itemsets based on itemField that occurs at minimum supp times
   and consist of minimum minlen and maximum maxlen items.
   whereQuery is used to limit the data used and must be a cts.query */
function getFreqItemSets(itemField, whereQuery, supp, totTrans ,minlen, maxlen) {
  /* calculate the minimum support count */
  var minTransSupp = supp;
  var frequentItemSets = {};

  /* for minlen to maxlen */
  for (var i = minlen; i <= maxlen; i++) {
    var elementRefs = [];
    for (var j = 1; j <= i; j++) {
    	elementRefs.push(cts.elementReference(xs.QName(itemField)));
      //fn.QName((fieldQuery[field].xmlns != "NA") ? fieldQuery[field].xmlns : "",field)
    }
    var itemSetFreq = [];
    for (var item of cts.valueTuples(elementRefs, 'ordered', whereQuery)) {
     var freq = cts.frequency(item);
     if (freq >= minTransSupp) {
         /* using toObject to ensure we are storing a array */
         itemSetFreq.push({"itemSet":item.toObject(), "absSupport":freq, "support": freq/totTrans});
      }
    }
    if (itemSetFreq.length > 0) {
      frequentItemSets[i] = itemSetFreq;
    }
  }

  return frequentItemSets;
}

function getAssociationRules(frequentItemSets, minConfidence, minLen) {
  /* internal helper functions */

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
    }

    var allSubSets = [];
    array.sort();
    for (var i = 1; i < array.length; i++) {
      op(i, array, [], allSubSets);
    }
    allSubSets.push(array);
    return allSubSets;
  }
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
    if (currentItemSet.length >= minLen ) {
      var diffItemSet = getDiffArray(currentItemSet, subsetItemSet);

      /* Apriori only creates rules with one item in the RHS (Consequent)! */
      if (diffItemSet.length === 1 || (subsetItemSet.length === 1 && diffItemSet.length === 0)) {
        var itemSupport = frequencies[currentItemSet.toString()];
        var subsetSupport = frequencies[subsetItemSet.toString()];
        var confidence = itemSupport / subsetSupport;
        var diffItemSetSupport = frequencies[diffItemSet.toString()];
        var lift = (itemSupport / (subsetSupport * diffItemSetSupport))
        if (!isNaN(confidence) && confidence >= minConfidence) {
          var lhs = [];
          /* to support rules with only one item (empty LHS)
             They will have same confidence as support and always a lift of 1 */
          if (diffItemSet.length === 0) {
            confidence = itemSupport;
            diffItemSet = subsetItemSet;
            lift = 1;
          } else {
            lhs = subsetItemSet;
          }
          associationRules.push({"lhs":lhs ,"rhs":diffItemSet, "support":itemSupport, "confidence":confidence, "lift":lift });
        }
      }
    }
  };

  /* main logic */
  var frequencies = {};
  var currentItemSet;
  var associationRules = [];
  /*
     Walk through all itemsets and get the rules for them.
     itemsets are grouped by the number of items they have.
     1,2,3 etc
   */
  for (var k in frequentItemSets) {
    /* get the all itemsets that has the same number of items */
    for (var i = 0; i< frequentItemSets[k].length; i++) {
      /* Generate a objects with the frequencies of all itemsets, needed to calculate Lift of a rule
          Key is the itemset as a string.
          Ex ["18th century schooner", "1900s Vintage Bi-Plane", "1903 Ford Model A"]
          =>
          "18th century schooner,1900s Vintage Bi-Plane,1903 Ford Model A" */
      frequencies[frequentItemSets[k][i].itemSet.toString()] = frequentItemSets[k][i].support;

      currentItemSet = frequentItemSets[k][i].itemSet;
       /* toAllSubSets generates all possible subsets, including the itemset, of a itemset
       ex array = ["I1", "I2", "I5"] then
      allSubSets = [["I1"], ["I2"], ["I5"], ["I1", "I2"], ["I1", "I5"], ["I2", "I5"], ["I1", "I2", "I5"]]
      Adn then to each subset generate and save rules:
      */
      toAllSubSets(currentItemSet).forEach(saveAssociationRuleFound);
    }
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
  var collections = (params.collection) ? JSON.parse(params.collection): null;
  var directory = (params.directory) ? JSON.parse(params.directory): null;
  var minSupport = params.supp ? params.supp === 0 ? 0 : params.supp : 0.15;
  var minItems = params.minlen ? params.minlen === 0 ? 0 : params.minlen : 1;
  /* We keep a seperated variable for the minum items in a rule */
  var minRItems = minItems;
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
  if (target == "rules") {
    /* If we also are going to generate rules we need single itemssets */
    minItems = 1;
  }
  var freqItemsSets = getFreqItemSets(field, whereQuery, minAbsSupp,transLength, minItems, maxItems);
  var arulesDoc = {};
  if (target == "rules") {
    /* Get the associationRules */
    arulesDoc = {'rules': getAssociationRules(freqItemsSets,minConf, minRItems)};
  } else {
    arulesDoc = {'itemsets': freqItemsSets};
  }
  return arulesDoc;
}
exports.GET = arules;
