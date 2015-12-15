# context("ml.data.frame")
#
#
# test_that("can create a ml.data.frame based on iris dataset", {
#   mlIris <- as.ml.data.frame(iris, "iris")
#   expect_true(is.ml.data.frame(mlIris))
#   expect_equal(mlIris@.nrows, 300)
# })
#
# test_that("ml.data.frame methods", {
#   mlIris <- ml.data.frame(query = "setosa", collection = "iris")
#   expect_equal(mlIris@.nrows, 100)
#   #dim(mlIris)
#   #colnames(mlIris)
#   #head(mlIris)
#   #names(mlIris)
#   #mlIris$newField <- mlIris$iris1Petal.Width
#   #mlIris$newField2 <- mlIris$iris1Petal.Width + dmlIris$iris1Petal.Length
#   #mlIris$newField3 <- mlIris$iris1Petal.Width + 10
#   #mlIris$abs_width <- abs(mlIris$iris1Petal.Width)
#   #mlIris$abs_newField3 <- abs(mlIris$newField3)
#   #head(mlIris)
#   #localDf <- as.data.frame(mlIris)
# })
#
