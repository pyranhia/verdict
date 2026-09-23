#' Classification report for multiclass models
#'
#' Returns per-class precision, recall, F1-score, and support, plus macro and
#' weighted averages.
#'
#' @param data A data frame containing columns for truth and predictions.
#' @param truth The column name (unquoted) of the true class labels (factor).
#' @param estimate The column name (unquoted) of the predicted class labels
#'   (factor with the same levels as `truth`).
#' @param classes_exclude Character vector of class names to exclude from the
#'   report. Excluded classes have no row in the output and do not contribute
#'   to the macro avg, weighted avg, or total support. Default `NULL`
#'   includes all classes.
#' @param ... Currently unused. Reserved for future arguments.
#'
#' @return A tibble with one row per included class plus two summary rows
#'   (`"macro avg"` and `"weighted avg"`), and columns `class`, `precision`,
#'   `recall`, `f1`, `support`.
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
classification_report <- function(data, truth, estimate, classes_exclude = NULL, ...) {
  truth_col    <- rlang::as_name(rlang::ensym(truth))
  estimate_col <- rlang::as_name(rlang::ensym(estimate))

  classes <- levels(data[[truth_col]])

  if (!is.null(classes_exclude)) {
    unknown <- setdiff(classes_exclude, classes)
    if (length(unknown) > 0) {
      rlang::abort(paste0(
        "`classes_exclude` contains class(es) not found in `truth`: ",
        paste(unknown, collapse = ", ")
      ))
    }
    classes <- setdiff(classes, classes_exclude)
    if (length(classes) == 0) {
      rlang::abort("`classes_exclude` excludes all classes; nothing left to report.")
    }
  }

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
