context("[.ml.data.frame")

mlHost <- "localhost"
mlPort <- "8088"
mlUser <- "admin"
mlUserPwd <- "admin"
mlAdmin <- "admin"
mlAdminPwd <- "admin"
mlDb <- "rfml"

test_that("sub select on a ml.data.frame", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  mlIris2 <- mlIris[1:3]
  expect_equal(length(mlIris2@.col.name), 3)
  expect_true(mlIris2@.extracted)
  mlIris3 <- mlIris[,1:3]
  expect_equal(length(mlIris3@.col.name), 3)
  expect_true(mlIris3@.extracted)
  mlIris4 <- mlIris[,c("Sepal.Length","Sepal.Width","Petal.Length")]
  expect_equal(length(mlIris4@.col.name), 3)
  expect_true(mlIris4@.extracted)
  mlIris5 <- mlIris[mlIris$Species=="setosa", 1:3]
  expect_equal(nchar(mlIris5@.queryArgs$`rs:fieldQuery`), 99)
  expect_true(mlIris5@.extracted)
  expect_equal(length(mlIris5@.col.name), 3)
  mlIris6 <- mlIris[mlIris$Species=="setosa",]
  expect_equal(nchar(mlIris6@.queryArgs$`rs:fieldQuery`), 99)
  expect_equal(length(mlIris6@.col.name), 5)
  expect_false(mlIris6@.extracted)
  mlIris7 <- mlIris["setosa",]
  expect_output(print(mlIris7@.queryArgs$`rs:q`), "setosa")
  expect_equal(length(mlIris7@.col.name), 5)
  rm.ml.data.frame(mlIris)
})

test_that("can aggregate ml.data.frame using sub select", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  expect_equal(mlIris[,max("Sepal.Length")], 7.9)
  expect_equal(mlIris[mlIris$Species=="setosa",max("Sepal.Length")], 5.8)
  testVals <- mlIris[,c(max("Sepal.Length"),min("Sepal.Length"), median("Sepal.Length"), sd("Sepal.Length"))]
  expect_equal(testVals[1], 7.9)
  expect_equal(testVals[2], 4.3)
  expect_equal(testVals[3], 5.8)
  expect_equal(testVals[4], 0.828066128)
  testVals <- mlIris[mlIris$Species=="setosa",c(max("Sepal.Length"),min("Sepal.Length"), median("Sepal.Length"), sd("Sepal.Length"))]
  expect_equal(testVals[1], 5.8)
  expect_equal(testVals[2], 4.3)
  expect_equal(testVals[3], 5)
  expect_equal(testVals[4], 0.3524897)
  rm.ml.data.frame(mlIris)
})

