context("method-statistics")

mlHost <- "localhost"
mlPort <- "8088"
mlUser <- "admin"
mlUserPwd <- "admin"

test_that("Statistics field based methods", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  expect_equal(cor(mlIris$Sepal.Length, mlIris$Petal.Length), 0.871753775886583)
  expect_equal(cov(mlIris$Sepal.Length, mlIris$Petal.Length), 1.27431543624161)
  expect_equal(cov.pop(mlIris$Sepal.Length, mlIris$Petal.Length), 1.26582)
  expect_equal(var(mlIris$Sepal.Length), 0.685693512304251)
  expect_equal(var.pop(mlIris$Sepal.Length), 0.681122222222222)
  expect_equal(sd(mlIris$Sepal.Length), 0.828066127977863)
  expect_equal(sd.pop(mlIris$Sepal.Length), 0.825301291785141)
  expect_equal(median(mlIris$Sepal.Length), 5.8)
  expect_equal(mean(mlIris$Sepal.Length), 5.84333333333334)
  expect_equal(sum(mlIris$Sepal.Length), 876.5)
  expect_equal(max(mlIris$Sepal.Length), 7.9)
  expect_equal(min(mlIris$Sepal.Length), 4.3)
  rm.ml.data.frame(mlIris)
})

test_that("Statistics ml.data.frame based methods", {
  skip_on_cran()
  myConn <- ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  irisCor <- cor(mlIris)
  expect_equal(nrow(irisCor), 4)
  expect_equal(ncol(irisCor), 4)
  expect_equal(irisCor["Sepal.Length", "Sepal.Length"], 1)
  expect_equal(irisCor["Sepal.Length", "Petal.Length"],  0.871753775886583)
  expect_equal(irisCor["Sepal.Width", "Petal.Width"], -0.366125932536439)
  irisSum <- summary(mlIris)
  expect_true(is.table(irisSum))
  expect_match(irisSum[1,3], "Min.   :1.000  ")
  expect_match(irisSum[2,3], "1st Qu.:1.550  ")
  expect_match(irisSum[3,2], "Median :3.000  ")
  rm.ml.data.frame(mlIris)
})
