context("ml.col.def")

mlHost <- "localhost"
mlPort <- "8088"
mlUser <- "admin"
mlUserPwd <- "admin"

test_that("ml.col.def methods", {
  skip_on_cran()
  myConn<-ml.connect(host = mlHost, port = mlPort, username = mlUser, password = mlUserPwd)
  mlIris <- as.ml.data.frame(myConn, iris, "iris-test")
  expect_equal(mlIris$Petal.Width@.name, "Petal.Width")
  rm.ml.data.frame(mlIris)
})

