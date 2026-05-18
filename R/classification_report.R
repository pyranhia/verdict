#' Classification report for multiclass models
#'
#' Returns per-class precision, recall, F1-score, and support, plus macro and
#' weighted averages. Inspired by `sklearn.metrics.classification_report`.
#'
#' @param data A data frame containing columns for truth and predictions.
#' @param truth The column name (unquoted) of the true class labels (factor).
#' @param estimate The column name (unquoted) of the predicted class labels
#'   (factor with the same levels as `truth`).
#' @param ... Currently unused. Reserved for future arguments.
#'
#' @return A tibble with one row per class plus two summary rows (`"macro avg"`
#'   and `"weighted avg"`), and columns `class`, `precision`, `recall`, `f1`,
#'   `support`.
#'
#' @examples
#' library(tibble)
#' truth <- factor(c("cat", "cat", "dog", "dog", "fish", "fish"),
#'                 levels = c("cat", "dog", "fish"))
#' pred  <- factor(c("cat", "dog", "dog", "dog", "fish", "cat"),
#'                 levels = c("cat", "dog", "fish"))
#' df <- tibble(truth = truth, pred = pred)
#'
#' classification_report(df, truth, pred)
#'
#' @export
classification_report <- function(data, truth, estimate, ...) {
  truth_col    <- rlang::as_name(rlang::ensym(truth))
  estimate_col <- rlang::as_name(rlang::ensym(estimate))

  classes <- levels(data[[truth_col]])

  per_class <- .compute_per_class(data[[truth_col]], data[[estimate_col]], classes)

  macro_avg <- tibble::tibble(
    class     = "macro avg",
    precision = mean(per_class$precision, na.rm = TRUE),
    recall    = mean(per_class$recall,    na.rm = TRUE),
    f1        = mean(per_class$f1,        na.rm = TRUE),
    support   = sum(per_class$support)
  )

  weighted_avg <- tibble::tibble(
    class     = "weighted avg",
    precision = stats::weighted.mean(per_class$precision, per_class$support, na.rm = TRUE),
    recall    = stats::weighted.mean(per_class$recall,    per_class$support, na.rm = TRUE),
    f1        = stats::weighted.mean(per_class$f1,        per_class$support, na.rm = TRUE),
    support   = sum(per_class$support)
  )

  dplyr::bind_rows(per_class, macro_avg, weighted_avg)
}
