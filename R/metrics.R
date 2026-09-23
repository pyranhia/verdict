#' Precision, recall, and F1-score with class exclusion
#'
#' Single-value precision, recall, and F1-score, matching the yardstick
#' output format (`.metric`, `.estimator`, `.estimate`), with support for
#' excluding specific classes from the average — the same `classes_exclude`
#' logic as [classification_report()].
#'
#' @param data A data frame containing columns for truth and predictions.
#' @param truth The column name (unquoted) of the true class labels (factor).
#' @param estimate The column name (unquoted) of the predicted class labels
#'   (factor with the same levels as `truth`).
#' @param estimator One of `"macro"` (default) or `"macro_weighted"`. Matches
#'   the corresponding `estimator` values in yardstick: `"macro"` averages
#'   per-class scores unweighted, `"macro_weighted"` weights by support.
#' @param classes_exclude Character vector of class names to exclude from the
#'   average. Excluded classes do not contribute to the metric. Default
#'   `NULL` includes all classes.
#' @param ... Currently unused. Reserved for future arguments.
#'
#' @return A tibble with one row and columns `.metric`, `.estimator`,
#'   `.estimate`, matching the yardstick metric output format.
#'
#' @examples
#' library(tibble)
#' truth <- factor(c("cat", "cat", "dog", "dog", "fish", "fish"),
#'                 levels = c("cat", "dog", "fish"))
#' pred  <- factor(c("cat", "dog", "dog", "dog", "fish", "cat"),
#'                 levels = c("cat", "dog", "fish"))
#' df <- tibble(truth = truth, pred = pred)
#'
#' # Default: unweighted mean across classes ("macro")
#' precision(df, truth, pred)
#'
#' # Weight each class's score by its support instead
#' precision(df, truth, pred, estimator = "macro_weighted")
#'
#' # Drop "fish" from the average entirely (still "macro" by default)
#' precision(df, truth, pred, classes_exclude = "fish")
#'
#' # Combine both: weighted average over the remaining classes
#' precision(df, truth, pred, estimator = "macro_weighted", classes_exclude = "fish")
#'
#' # recall() and f1_meas() take the same arguments
#' recall(df, truth, pred, estimator = "macro_weighted")
#' f1_meas(df, truth, pred, classes_exclude = "fish")
#'
#' @name verdict_metrics
NULL

#' @rdname verdict_metrics
#' @export
precision <- function(data, truth, estimate, estimator = "macro", classes_exclude = NULL, ...) {
  .verdict_metric(data, {{ truth }}, {{ estimate }}, "precision", estimator, classes_exclude)
}

#' @rdname verdict_metrics
#' @export
recall <- function(data, truth, estimate, estimator = "macro", classes_exclude = NULL, ...) {
  .verdict_metric(data, {{ truth }}, {{ estimate }}, "recall", estimator, classes_exclude)
}

#' @rdname verdict_metrics
#' @export
f1_meas <- function(data, truth, estimate, estimator = "macro", classes_exclude = NULL, ...) {
  .verdict_metric(data, {{ truth }}, {{ estimate }}, "f1", estimator, classes_exclude)
}
