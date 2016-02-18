context("ml.col.def")
ml.connect(host = "192.168.33.10", port = "8020", username = "admin", password = "Pass1234")
test_that("ml.col.def methods", {
  mlIris <- as.ml.data.frame(iris, "iris-test")
  expect_equal(mlIris$Petal.Width@.name, "Petal.Width")
  rm.ml.data.frame(mlIris)
})

