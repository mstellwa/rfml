context("Config")

mlHost <- "localhost"
mlPort <- "8088"
mlAdmin <- "admin"
mlAdminPwd <- "admin"

test_that("MarkLogic database can be initiated for rfml", {
  skip_on_cran()
  ml.init.database(host=mlHost, port = mlPort, adminuser = mlAdmin, password = mlAdminPwd)
})

test_that("MarkLogic database can be cleaned up", {
  skip_on_cran()
  ml.clear.database(host=mlHost, port = mlPort, adminuser = mlAdmin, password = mlAdminPwd)
  expect_error(ml.connect(host=mlHost, port = mlPort, username = mlAdmin, password = mlAdminPwd), "It seems like rfml is not installed")
  ml.init.database(host=mlHost, port = mlPort, adminuser = mlAdmin, password = mlAdminPwd)
})
