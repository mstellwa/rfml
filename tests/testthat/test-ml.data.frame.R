context("ml.data.frame")

ml.connect()

test_that("can create and delete a ml.data.frame based on iris dataset", {
   mlIris <- as.ml.data.frame(iris, "iris-test")
   expect_is(mlIris, "ml.data.frame")
   expect_true(is.ml.data.frame(mlIris))
   expect_equal(mlIris@.nrows, 150)
   expect_true(rm.ml.data.frame(mlIris))
 })

test_that("can create a ml.data.frame based on search", {
   mlIris <- as.ml.data.frame(iris, "iris-test")
   mlIris2 <- ml.data.frame(collection = "iris-test")
   expect_is(mlIris2, "ml.data.frame")
   expect_true(is.ml.data.frame(mlIris2))
   expect_equal(mlIris2@.nrows, 150)
   expect_equal(nrow(mlIris2), 150)
   mlIris3 <- ml.data.frame(query = "setosa", collection = "iris-test")
   expect_equal(mlIris3@.nrows, 50)
   expect_equal(nrow(mlIris3), 50)
   mlIris4 <- ml.data.frame(query = "virginica", collection = "iris-test", directory = "/rfml/admin/iris-test/")
   expect_equal(mlIris4@.nrows, 50)
   expect_equal(nrow(mlIris4), 50)
   rm.ml.data.frame(mlIris)
})

test_that("can create new fields on a ml.data.frame", {
  mlIris <- as.ml.data.frame(iris, "iris-test")
  mlIris$SepLength <- mlIris$Sepal.Length
  expect_is(mlIris$SepLength, "ml.col.def")
  expect_match(mlIris$SepLength@.expr, "rfmlResult['Sepal.Length']", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 1)
  expect_equal(length(mlIris@.col.name), 6)
  mlIris$SepLength10 <- mlIris$Sepal.Length * 10
  expect_output(mlIris$SepLength10@.expr, "(rfmlResult['Sepal.Length']*10)", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 2)
  expect_equal(length(mlIris@.col.name), 7)
  mlIris$SepRatio <- mlIris$Sepal.Length / mlIris$Sepal.Width
  expect_output(mlIris$SepRatio@.expr, "(rfmlResult['Sepal.Length']/rfmlResult['Sepal.Width'])", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 3)
  expect_equal(length(mlIris@.col.name), 8)
  mlIris$SepLengthAbs <- abs(mlIris$Sepal.Length)
  expect_output(mlIris$SepLengthAbs@.expr, "fn.abs(rfmlResult['Sepal.Length'])", fixed=TRUE)
  expect_equal(length(mlIris@.col.defs), 4)
  expect_equal(length(mlIris@.col.name), 9)
  rm.ml.data.frame(mlIris)
})
test_that("sub select on a ml.data.frame", {
  mlIris <- as.ml.data.frame(iris, "iris-test")
  mlIris2 <- mlIris[1:3]
  expect_equal(length(mlIris2@.col.name), 3)
  #mlIris2@.col.name [1] "Sepal.Length" "Sepal.Width"  "Petal.Length"
  mlIris3 <- mlIris[,1:3]
  expect_equal(length(mlIris3@.col.name), 3)
  # mlIris3@.col.name [1] "Sepal.Length" "Sepal.Width"  "Petal.Length"
  mlIris4 <- mlIris[,c("Sepal.Length","Sepal.Width","Petal.Length")]
  expect_equal(length(mlIris4@.col.name), 3)
  mlIris5 <- mlIris[mlIris$Species=="setosa", 1:3]
  expect_equal(nchar(mlIris5@.queryArgs$`rs:fieldQuery`), 86)
  expect_true(mlIris5@.extracted)
  expect_equal(length(mlIris5@.col.name), 3)
  mlIris6 <- mlIris[mlIris$Species=="setosa",]
  expect_equal(nchar(mlIris6@.queryArgs$`rs:fieldQuery`), 86)
  expect_equal(length(mlIris6@.col.name), 5)
  expect_false(mlIris6@.extracted)
  mlIris7 <- mlIris["setosa",]
  expect_output(mlIris7@.queryArgs$`rs:q`, "setosa")
  expect_equal(length(mlIris7@.col.name), 5)
  rm.ml.data.frame(mlIris)
})

