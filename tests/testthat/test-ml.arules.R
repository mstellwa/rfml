context("ml.arules")

mlHost <- "localhost"
mlPort <- "8088"
mlUser <- "admin"
mlUserPwd <- "admin"
mlAdmin <- "admin"
mlAdminPwd <- "admin"
mlDb <- "rfml"

test_that("ml.arules works", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlBaskets <- ml.load.sample.data(myConn, "baskets", "baskets-test")
  expect_message(ml.add.index(x = mlBaskets$cr1ls1lm11productName, scalarType = "string", host = mlHost,database =  mlDb, adminuser = mlAdmin, password = mlAdminPwd), "Range element index created on productName")
  # We need to wait so that the index gets updated before using a function that leverage it
  Sys.sleep(10)
  itemsets <- ml.arules(mlBaskets, mlBaskets$cr1ls1lm11productName, support = 0.22, confidence = 0.01, target = "frequent itemsets")
  expect_is(itemsets, "itemsets")
  expect_equal(length(itemsets), 13)
  rules <- ml.arules(mlBaskets, mlBaskets$cr1ls1lm11productName, support = 0.22, confidence = 0.01)
  expect_is(rules, "rules")
  expect_equal(length(rules), 23)
  rm.ml.data.frame(mlBaskets)
})


