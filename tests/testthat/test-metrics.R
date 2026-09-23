truth <- factor(c("cat", "cat", "dog", "dog", "dog", "fish", "fish", "fish"),
                levels = c("cat", "dog", "fish"))
pred  <- factor(c("cat", "dog", "dog", "dog", "cat", "fish", "fish", "dog"),
                levels = c("cat", "dog", "fish"))
df <- tibble::tibble(truth = truth, pred = pred)

# Per-class values (from test-classification_report.R):
#   cat:  precision 0.5,  recall 0.5,  f1 0.5,   support 2
#   dog:  precision 0.5,  recall 2/3,  f1 4/7,   support 3
#   fish: precision 1.0,  recall 2/3,  f1 0.8,   support 3

# --- Output structure ---

test_that("precision() returns a one-row yardstick-shaped tibble", {
  result <- precision(df, truth, pred)
  expect_s3_class(result, "tbl_df")
  expect_named(result, c(".metric", ".estimator", ".estimate"))
  expect_equal(nrow(result), 1L)
})

test_that("recall() and f1_meas() return the same shape", {
  expect_named(recall(df, truth, pred), c(".metric", ".estimator", ".estimate"))
  expect_named(f1_meas(df, truth, pred), c(".metric", ".estimator", ".estimate"))
})

test_that(".metric column matches the function name", {
  expect_equal(precision(df, truth, pred)$.metric, "precision")
  expect_equal(recall(df, truth, pred)$.metric,    "recall")
  expect_equal(f1_meas(df, truth, pred)$.metric,   "f1")
})

# --- Default estimator ---

test_that("default estimator is macro", {
  result <- precision(df, truth, pred)
  expect_equal(result$.estimator, "macro")
})

# --- Numeric values: macro ---

test_that("macro precision/recall/f1 match classification_report()'s macro avg", {
  expect_equal(precision(df, truth, pred)$.estimate, (0.5 + 0.5 + 1.0) / 3, tolerance = 1e-3)
  expect_equal(recall(df, truth, pred)$.estimate,    (0.5 + 2/3 + 2/3) / 3, tolerance = 1e-3)
  expect_equal(f1_meas(df, truth, pred)$.estimate,   (0.5 + 4/7 + 0.8) / 3, tolerance = 1e-3)
})

# --- Numeric values: macro_weighted ---

test_that("macro_weighted precision/recall/f1 match classification_report()'s weighted avg", {
  p <- precision(df, truth, pred, estimator = "macro_weighted")
  r <- recall(df, truth, pred, estimator = "macro_weighted")
  f <- f1_meas(df, truth, pred, estimator = "macro_weighted")

  expect_equal(p$.estimator, "macro_weighted")
  expect_equal(p$.estimate, (0.5*2 + 0.5*3 + 1.0*3) / 8, tolerance = 1e-3)
  expect_equal(r$.estimate, (0.5*2 + 2/3*3 + 2/3*3) / 8, tolerance = 1e-3)
  expect_equal(f$.estimate, (0.5*2 + 4/7*3 + 0.8*3) / 8, tolerance = 1e-3)
})

test_that("invalid estimator raises an error", {
  expect_error(precision(df, truth, pred, estimator = "weighted"))
  expect_error(precision(df, truth, pred, estimator = "micro"))
})

# --- classes_exclude ---

test_that("classes_exclude changes the macro average the same way as classification_report()", {
  result <- precision(df, truth, pred, classes_exclude = "dog")
  expect_equal(result$.estimate, (0.5 + 1.0) / 2, tolerance = 1e-3)
})

test_that("classes_exclude changes the macro_weighted average the same way as classification_report()", {
  result <- recall(df, truth, pred, estimator = "macro_weighted", classes_exclude = "dog")
  expect_equal(result$.estimate, (0.5*2 + 2/3*3) / 5, tolerance = 1e-3)
})

test_that("unknown class name raises an error", {
  expect_error(
    precision(df, truth, pred, classes_exclude = "bird"),
    "not found in `truth`"
  )
})

test_that("excluding all classes raises an error", {
  expect_error(
    f1_meas(df, truth, pred, classes_exclude = c("cat", "dog", "fish")),
    "excludes all classes"
  )
})

# --- Consistency with classification_report() ---

test_that("precision()/recall()/f1_meas() agree with classification_report()'s per-metric averages", {
  report <- classification_report(df, truth, pred)
  macro_row <- report[report$class == "macro avg", ]
  weighted_row <- report[report$class == "weighted avg", ]

  expect_equal(precision(df, truth, pred)$.estimate, macro_row$precision, tolerance = 1e-9)
  expect_equal(recall(df, truth, pred)$.estimate,    macro_row$recall,    tolerance = 1e-9)
  expect_equal(f1_meas(df, truth, pred)$.estimate,   macro_row$f1,        tolerance = 1e-9)

  expect_equal(
    precision(df, truth, pred, estimator = "macro_weighted")$.estimate,
    weighted_row$precision, tolerance = 1e-9
  )
})
