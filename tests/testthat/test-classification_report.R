truth <- factor(c("cat", "cat", "dog", "dog", "dog", "fish", "fish", "fish"),
                levels = c("cat", "dog", "fish"))
pred  <- factor(c("cat", "dog", "dog", "dog", "cat", "fish", "fish", "dog"),
                levels = c("cat", "dog", "fish"))
df <- tibble::tibble(truth = truth, pred = pred)

# --- Output structure ---

test_that("classification_report returns a tibble", {
  result <- classification_report(df, truth, pred)
  expect_s3_class(result, "tbl_df")
})

test_that("output has expected columns", {
  result <- classification_report(df, truth, pred)
  expect_named(result, c("class", "precision", "recall", "f1", "support"))
})

test_that("output has correct number of rows (n classes + 2 averages)", {
  result <- classification_report(df, truth, pred)
  expect_equal(nrow(result), 5L)
})

test_that("average rows have correct labels", {
  result <- classification_report(df, truth, pred)
  expect_true("macro avg" %in% result$class)
  expect_true("weighted avg" %in% result$class)
})

# --- Numeric values ---

test_that("per-class support is correct", {
  result <- classification_report(df, truth, pred)
  expect_equal(result$support[result$class == "cat"],  2L)
  expect_equal(result$support[result$class == "dog"],  3L)
  expect_equal(result$support[result$class == "fish"], 3L)
})

test_that("per-class metrics are correct", {
  result <- classification_report(df, truth, pred)
  expect_equal(result$precision[result$class == "cat"],  0.5,  tolerance = 1e-3)
  expect_equal(result$recall[result$class == "cat"],     0.5,  tolerance = 1e-3)
  expect_equal(result$f1[result$class == "cat"],         0.5,  tolerance = 1e-3)
  expect_equal(result$precision[result$class == "dog"],  0.5,  tolerance = 1e-3)
  expect_equal(result$recall[result$class == "dog"],     2/3,  tolerance = 1e-3)
  expect_equal(result$f1[result$class == "dog"],         4/7,  tolerance = 1e-3)
  expect_equal(result$precision[result$class == "fish"], 1.0,  tolerance = 1e-3)
  expect_equal(result$recall[result$class == "fish"],    2/3,  tolerance = 1e-3)
  expect_equal(result$f1[result$class == "fish"],        0.8,  tolerance = 1e-3)
})

test_that("macro average is correct", {
  result <- classification_report(df, truth, pred)
  expect_equal(result$precision[result$class == "macro avg"], (0.5 + 0.5 + 1.0) / 3, tolerance = 1e-3)
  expect_equal(result$recall[result$class == "macro avg"],    (0.5 + 2/3 + 2/3) / 3, tolerance = 1e-3)
  expect_equal(result$f1[result$class == "macro avg"],        (0.5 + 4/7 + 0.8) / 3, tolerance = 1e-3)
})

test_that("weighted average is correct", {
  result <- classification_report(df, truth, pred)
  expect_equal(result$precision[result$class == "weighted avg"], (0.5*2 + 0.5*3 + 1.0*3) / 8, tolerance = 1e-3)
  expect_equal(result$recall[result$class == "weighted avg"],    (0.5*2 + 2/3*3 + 2/3*3) / 8, tolerance = 1e-3)
  expect_equal(result$f1[result$class == "weighted avg"],        (0.5*2 + 4/7*3 + 0.8*3) / 8, tolerance = 1e-3)
})

# --- classes_exclude ---

test_that("excluded class has no row in the output", {
  result <- classification_report(df, truth, pred, classes_exclude = "dog")
  expect_false("dog" %in% result$class)
  expect_equal(sort(result$class), sort(c("cat", "fish", "macro avg", "weighted avg")))
})

test_that("macro avg is recomputed over the remaining classes only", {
  result <- classification_report(df, truth, pred, classes_exclude = "dog")
  expect_equal(result$precision[result$class == "macro avg"], (0.5 + 1.0) / 2, tolerance = 1e-3)
  expect_equal(result$recall[result$class == "macro avg"],    (0.5 + 2/3) / 2, tolerance = 1e-3)
  expect_equal(result$f1[result$class == "macro avg"],        (0.5 + 0.8) / 2, tolerance = 1e-3)
})

test_that("weighted avg is recomputed over the remaining classes only", {
  result <- classification_report(df, truth, pred, classes_exclude = "dog")
  expect_equal(result$precision[result$class == "weighted avg"], (0.5*2 + 1.0*3) / 5, tolerance = 1e-3)
  expect_equal(result$recall[result$class == "weighted avg"],    (0.5*2 + 2/3*3) / 5, tolerance = 1e-3)
  expect_equal(result$f1[result$class == "weighted avg"],        (0.5*2 + 0.8*3) / 5, tolerance = 1e-3)
})

test_that("total support excludes the excluded class", {
  result <- classification_report(df, truth, pred, classes_exclude = "dog")
  expect_equal(result$support[result$class == "macro avg"],    5L)
  expect_equal(result$support[result$class == "weighted avg"], 5L)
})

test_that("unknown class name raises an error", {
  expect_error(
    classification_report(df, truth, pred, classes_exclude = "bird"),
    "not found in `truth`"
  )
})

test_that("excluding all classes raises an error", {
  expect_error(
    classification_report(df, truth, pred, classes_exclude = c("cat", "dog", "fish")),
    "excludes all classes"
  )
})

test_that("classes_exclude = NULL matches default behaviour", {
  expect_equal(
    classification_report(df, truth, pred),
    classification_report(df, truth, pred, classes_exclude = NULL)
  )
})
