context("ml.col.def")
ml.connect(port = "8088")
test_that("ml.col.def methods", {
  mlIris <- as.ml.data.frame(iris, "iris-test")
  expect_equal(mlIris$Petal.Width@.name, "Petal.Width")
  rm.ml.data.frame(mlIris)
})

