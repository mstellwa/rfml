context("ml.lm")

myConn <- ml.connect(port = "8088")

test_that("lm works", {
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  lm <- ml.lm(Sepal.Length~Sepal.Width, mlIris)
  expect_match(lm$intercept, "6.52")
  expect_match(lm$coefficients, "-0.22")
  expect_match(lm$rsquared, "0.01")
  rm.ml.data.frame(mlIris)
})
