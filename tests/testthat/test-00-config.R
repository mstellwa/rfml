context("Config")

test_that("MarkLogic database can be initiated for rfml", {
  skip_on_cran()
  ml.init.database(port = "8088")
})

test_that("MarkLogic database can be cleaned up", {
  skip_on_cran()
  ml.clear.database(port = "8088")
  expect_error(ml.connect(port="8088"), "It seems like rfml is not installed")
  ml.init.database(port = "8088")
})
