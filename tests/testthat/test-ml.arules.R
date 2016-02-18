context("ml.arules")

ml.connect(host = "192.168.33.10", port = "8020", username = "admin", password = "Pass1234")

test_that("ml.arules works", {
  mlBaskets <- ml.load.sample.data("baskets", "baskets-test")
  db <- "techdeck-demo-content"
  pwd = "Pass1234"
  expect_message(ml.add.index(mlBaskets$lineItem1productName, "string", db, password = pwd), "Range element index created on productName")
  itemsets <- ml.arules(mlBaskets, mlBaskets$lineItem1productName, support = 0.22, confidence = 0.01, target = "frequent itemsets")
  expect_is(itemsets, "itemsets")
  expect_equal(length(itemsets), 13)
  rules <- ml.arules(mlBaskets, mlBaskets$lineItem1productName, support = 0.22, confidence = 0.01)
  expect_is(rules, "rules")
  expect_equal(length(rules), 24)
  rm.ml.data.frame(mlBaskets)
})


