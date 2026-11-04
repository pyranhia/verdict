#' Classification report for multiclass models
#'
#' Returns per-class precision, recall, F1-score, and support, plus micro,
#' macro, and weighted averages.
#'
#' @param data A data frame containing columns for truth and predictions.
#' @param truth The column name (unquoted) of the true class labels (factor).
#' @param estimate The column name (unquoted) of the predicted class labels
#'   (factor with the same levels as `truth`).
#' @param classes_exclude Character vector of class names to exclude from the
#'   report. Excluded classes have no row in the output and do not contribute
#'   to the averages or total support, except that an observation of an
#'   excluded class predicted as an included one counts as a false positive
#'   in the micro avg. Default `NULL` includes all classes.
#' @param na_rm If `TRUE` (default), rows where `truth` or `estimate` is
#'   missing are dropped. If `FALSE`, missing values raise an error.
#' @param ... Currently unused. Reserved for future arguments.
#'
#' @details
#' Undefined ratios are set to 0, as with scikit-learn's default
#' `zero_division` behaviour: a class that is never predicted gets precision
#' 0, and a class absent from `truth` gets recall 0. A warning lists the
#' classes concerned. A class absent from both `truth` and `estimate` gets
#' `NA` metrics and is left out of the averages.
#'
#' The micro avg pools true positives, predictions, and true labels over the
#' included classes before computing precision, recall, and F1. Without
#' `classes_exclude`, all three equal accuracy: scikit-learn shows this row
#' as `"accuracy"`, and as `"micro avg"` only when `labels` is a subset of
#' the classes.
#'
#' @return A tibble with one row per included class plus three summary rows
#'   (`"micro avg"`, `"macro avg"`, and `"weighted avg"`), and columns
#'   `class`, `precision`, `recall`, `f1`, `support`.
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
#' # Focus on mammals: exclude "fish" from the averages
#' classification_report(df, truth, pred, classes_exclude = "fish")
#'
#' @export
classification_report <- function(
  data,
  truth,
  estimate,
  classes_exclude = NULL,
  na_rm = TRUE,
  ...
) {
  truth_col <- rlang::as_name(rlang::ensym(truth))
  estimate_col <- rlang::as_name(rlang::ensym(estimate))

  inputs <- .prepare_inputs(data, truth_col, estimate_col, na_rm)
  classes <- .apply_classes_exclude(levels(inputs$truth), classes_exclude)

  per_class <- .compute_per_class(inputs$truth, inputs$estimate, classes)
  micro_avg <- .compute_micro(inputs$truth, inputs$estimate, classes)

  macro_avg <- tibble::tibble(
    class = "macro avg",
    precision = mean(per_class$precision, na.rm = TRUE),
    recall = mean(per_class$recall, na.rm = TRUE),
    f1 = mean(per_class$f1, na.rm = TRUE),
    support = sum(per_class$support)
  )

  weighted_avg <- tibble::tibble(
    class = "weighted avg",
    precision = stats::weighted.mean(
      per_class$precision,
      per_class$support,
      na.rm = TRUE
    ),
    recall = stats::weighted.mean(
      per_class$recall,
      per_class$support,
      na.rm = TRUE
    ),
    f1 = stats::weighted.mean(per_class$f1, per_class$support, na.rm = TRUE),
    support = sum(per_class$support)
  )

  dplyr::bind_rows(per_class, micro_avg, macro_avg, weighted_avg)
}
