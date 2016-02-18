context("ml.lm")

ml.connect(host = "192.168.33.10", port = "8020", username = "admin", password = "Pass1234")

test_that("lm works", {
  mlIris <- as.ml.data.frame(iris, "iris")
  lm <- ml.lm(Sepal.Length~Sepal.Width, mlIris)
  expect_match(lm$intercept, "6.52622255089448")
  expect_match(lm$coefficients, "-0.2233610611299")
  expect_match(lm$rsquared, "0.0138226541410807")
  rm.ml.data.frame(mlIris)
})