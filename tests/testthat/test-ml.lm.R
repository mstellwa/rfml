context("ml.lm")

mlHost <- "localhost"
mlPort <- "8088"
mlUser <- "admin"
mlUserPwd <- "admin"

test_that("lm works", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  lm <- ml.lm(Sepal.Length~Sepal.Width, mlIris)
  expect_match(lm$intercept, "6.52")
  expect_match(lm$coefficients, "-0.22")
  expect_match(lm$rsquared, "0.01")
  rm.ml.data.frame(mlIris)
})
