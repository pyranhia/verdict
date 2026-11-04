# Example from the scikit-learn documentation of classification_report()
lv <- c("0", "1", "2")
df_sk <- tibble::tibble(
  truth = factor(c("0", "1", "2", "2", "2"), levels = lv),
  pred = factor(c("0", "0", "2", "2", "1"), levels = lv)
)

test_that("classification_report matches sklearn on its documentation example", {
  expected <- tibble::tibble(
    class = c("0", "1", "2", "macro avg", "weighted avg"),
    precision = c(1 / 2, 0, 1, 1 / 2, 7 / 10),
    recall = c(1, 0, 2 / 3, 5 / 9, 3 / 5),
    f1 = c(2 / 3, 0, 4 / 5, 22 / 45, 46 / 75),
    support = c(1L, 1L, 3L, 5L, 5L)
  )
  expect_equal(classification_report(df_sk, truth, pred), expected)
})
