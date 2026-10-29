lv <- c("a", "b", "c")

# --- Class never predicted (zero TP) ---
# "c" has support 2 but is never predicted: precision is 0/0, recall 0, F1 0.
df_missed <- tibble::tibble(
  truth = factor(c("a", "a", "b", "b", "c", "c"), levels = lv),
  pred  = factor(c("a", "a", "b", "b", "a", "b"), levels = lv)
)

test_that("a class with zero TP gets F1 = 0, not NA", {
  result <- suppressWarnings(classification_report(df_missed, truth, pred))
  expect_equal(result$f1[result$class == "c"], 0)
  expect_equal(result$recall[result$class == "c"], 0)
})

test_that("a class never predicted gets precision = 0 with a warning", {
  expect_warning(
    result <- classification_report(df_missed, truth, pred),
    "never predicted.*c"
  )
  expect_equal(result$precision[result$class == "c"], 0)
})

test_that("zero-TP classes count in the macro average (matches sklearn)", {
  result <- suppressWarnings(classification_report(df_missed, truth, pred))
  macro <- result[result$class == "macro avg", ]
  # sklearn: precision 0.444, recall 0.667, f1 0.533
  expect_equal(macro$precision, (2/3 + 2/3 + 0) / 3, tolerance = 1e-9)
  expect_equal(macro$recall,    (1 + 1 + 0) / 3,     tolerance = 1e-9)
  expect_equal(macro$f1,        (0.8 + 0.8 + 0) / 3, tolerance = 1e-9)
})

test_that("single-value metrics agree on zero-TP classes", {
  expect_equal(
    suppressWarnings(f1_meas(df_missed, truth, pred))$.estimate,
    (0.8 + 0.8 + 0) / 3, tolerance = 1e-9
  )
  expect_warning(precision(df_missed, truth, pred), "never predicted")
})

test_that("excluding the never-predicted class silences the warning", {
  expect_no_warning(classification_report(df_missed, truth, pred, classes_exclude = "c"))
})

# --- Class predicted but absent from truth ---
df_spurious <- tibble::tibble(
  truth = factor(c("a", "a", "b", "b"), levels = lv),
  pred  = factor(c("a", "c", "b", "b"), levels = lv)
)

test_that("a class absent from truth gets recall = 0 with a warning", {
  expect_warning(
    result <- classification_report(df_spurious, truth, pred),
    "absent from `truth`.*c"
  )
  expect_equal(result$recall[result$class == "c"], 0)
  expect_equal(result$precision[result$class == "c"], 0)
  expect_equal(result$f1[result$class == "c"], 0)
  expect_equal(result$support[result$class == "c"], 0L)
})

# --- Empty level (neither in truth nor predicted) ---
df_empty <- tibble::tibble(
  truth = factor(c("a", "a", "b", "b"), levels = lv),
  pred  = factor(c("a", "b", "b", "b"), levels = lv)
)

test_that("an empty level gets NA metrics and is left out of the averages", {
  expect_warning(
    result <- classification_report(df_empty, truth, pred),
    "absent from both.*c"
  )
  expect_true(is.na(result$f1[result$class == "c"]))
  macro <- result[result$class == "macro avg", ]
  expect_equal(macro$precision, (1 + 2/3) / 2, tolerance = 1e-9)
})

# --- Missing values ---
df_na <- tibble::tibble(
  truth = factor(c("a", "a", "b", NA, "c", "c"), levels = lv),
  pred  = factor(c("a", NA, "b", "b", "c", "c"), levels = lv)
)

test_that("rows with NA are removed by default", {
  result <- classification_report(df_na, truth, pred)
  expected <- classification_report(df_na[c(1, 3, 5, 6), ], truth, pred)
  expect_equal(result, expected)
  expect_equal(
    recall(df_na, truth, pred),
    recall(df_na[c(1, 3, 5, 6), ], truth, pred)
  )
})

test_that("na_rm = FALSE with NA present raises an error", {
  expect_error(classification_report(df_na, truth, pred, na_rm = FALSE), "missing values")
  expect_error(precision(df_na, truth, pred, na_rm = FALSE), "missing values")
})

# --- Input validation ---

test_that("truth and estimate must be factors", {
  df_chr <- tibble::tibble(truth = c("a", "b"), pred = factor(c("a", "b")))
  expect_error(classification_report(df_chr, truth, pred), "must be a factor")
})

test_that("truth and estimate must have identical levels", {
  df_lv <- tibble::tibble(
    truth = factor(c("a", "b"), levels = c("a", "b")),
    pred  = factor(c("a", "b"), levels = c("a", "b", "c"))
  )
  expect_error(classification_report(df_lv, truth, pred), "same levels")
  expect_error(f1_meas(df_lv, truth, pred), "same levels")
})
