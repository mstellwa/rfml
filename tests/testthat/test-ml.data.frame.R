context("ml.data.frame")

mlHost <- "localhost"
mlPort <- "8088"
mlUser <- "admin"
mlUserPwd <- "admin"
mlAdmin <- "admin"
mlAdminPwd <- "admin"
mlDb <- "rfml"

test_that("can create and delete a ml.data.frame based on iris dataset using json format", {
   skip_on_cran()
   myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
   mlIris <- as.ml.data.frame(myConn, iris, "iris-test-json", format = "json")
   expect_is(mlIris, "ml.data.frame")
   expect_true(is.ml.data.frame(mlIris))
   expect_equal(mlIris@.nrows, 150)
   expect_true(rm.ml.data.frame(mlIris))
 })

test_that("can create and delete a ml.data.frame based on iris dataset using xml format", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test-xml", format = "XML")
  expect_is(mlIris, "ml.data.frame")
  expect_true(is.ml.data.frame(mlIris))
  expect_equal(mlIris@.nrows, 150)
  expect_true(rm.ml.data.frame(mlIris))
})

test_that("can create a ml.data.frame based on search", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
   mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
   mlIris2 <- ml.data.frame(myConn, collection = "iris-test")
   expect_is(mlIris2, "ml.data.frame")
   expect_true(is.ml.data.frame(mlIris2))
   expect_equal(mlIris2@.nrows, 150)
   expect_equal(nrow(mlIris2), 150)
   mlIris3 <- ml.data.frame(myConn, query = "setosa", collection = "iris-test")
   expect_equal(mlIris3@.nrows, 50)
   expect_equal(nrow(mlIris3), 50)
   mlIris4 <- ml.data.frame(myConn, query = "virginica", collection = "iris-test", directory = "/rfml/admin/iris-test/")
   expect_equal(mlIris4@.nrows, 50)
   expect_equal(nrow(mlIris4), 50)
   rm.ml.data.frame(mlIris)
})

test_that("can create a ml.data.frame based on fieldQuery", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  mlIris2 <- ml.data.frame(myConn, fieldFilter = "Species == virginica", collection = "iris-test")
  expect_equal(mlIris2@.nrows, 50)
  expect_equal(nrow(mlIris2), 50)

  expect_message(ml.add.index(x = mlIris$Petal.Length, scalarType = "decimal", host = mlHost, database =  mlDb, adminuser = mlAdmin, password = mlAdminPwd), "Range element index created on Petal.Length")
  # We need to wait so that the index gets updated before using a function that leverage it
  Sys.sleep(10)
  mlIris3 <- ml.data.frame(myConn, fieldFilter = "Petal.Length > 4.5", collection = "iris-test")
  expect_equal(mlIris3@.nrows, 63)
  expect_equal(nrow(mlIris3), 63)
  mlIris4 <- ml.data.frame(myConn, query = "virginica", fieldFilter = "Petal.Length > 5", collection = "iris-test", directory = "/rfml/admin/iris-test/")
  expect_equal(mlIris4@.nrows, 41)
  expect_equal(nrow(mlIris4), 41)
  rm.ml.data.frame(mlIris)
})

test_that("can create new fields on a ml.data.frame", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn,iris, "iris-test")
  mlIris$SepLength <- mlIris$Sepal.Length
  expect_is(mlIris$SepLength, "ml.col.def")
  expect_match(mlIris$SepLength@.expr, "rfmlResult['Sepal.Length']", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 1)
  expect_equal(length(mlIris@.col.name), 6)
  mlIris$SepLength10 <- mlIris$Sepal.Length * 10
  expect_output(print(mlIris$SepLength10@.expr), "(rfmlResult['Sepal.Length']*10)", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 2)
  expect_equal(length(mlIris@.col.name), 7)
  mlIris$SepRatio <- mlIris$Sepal.Length / mlIris$Sepal.Width
  expect_output(print(mlIris$SepRatio@.expr), "(rfmlResult['Sepal.Length']/rfmlResult['Sepal.Width'])", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 3)
  expect_equal(length(mlIris@.col.name), 8)
  mlIris$SepLengthAbs <- abs(mlIris$Sepal.Length)
  expect_output(print(mlIris$SepLengthAbs@.expr), "fn.abs(rfmlResult['Sepal.Length'])", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 4)
  expect_equal(length(mlIris@.col.name), 9)
  rm.ml.data.frame(mlIris)
})

test_that("can create data based on a ml.data.frame", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  mlIris$SepLength <- mlIris$Sepal.Length
  mlIris$SepLength10 <- mlIris$Sepal.Length * 10
  mlIris$SepRatio <- mlIris$Sepal.Length / mlIris$Sepal.Width
  mlIris$SepLengthAbs <- abs(mlIris$Sepal.Length)
  newIris <- as.ml.data.frame(x = mlIris, name = "newIris-test" )
  expect_equal(nrow(newIris), 150)
  expect_equal(length(newIris@.col.name), 9)
  expect_equal(length(newIris@.col.defs), 0)
  rm.ml.data.frame(mlIris)
  rm.ml.data.frame(newIris)
})


