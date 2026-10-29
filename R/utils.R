#' Compute per-class precision, recall, F1, and support
#'
#' Counts come from the full confusion matrix, so predictions involving
#' classes not in `classes` (e.g. excluded ones) still count as FP/FN.
#'
#' Undefined ratios follow sklearn's `zero_division = 0`: a class never
#' predicted gets precision 0, a class absent from `truth` gets recall 0, each
#' with a warning. A class absent from both gets NA everywhere and is ignored
#' by the averages.
#'
#' @param truth Factor of true labels.
#' @param estimate Factor of predicted labels.
#' @param classes Character vector of class levels.
#' @return A tibble with one row per class.
#' @noRd
.compute_per_class <- function(truth, estimate, classes) {
  cm <- table(truth, estimate)
  tp <- diag(cm)[classes]
  n_pred <- colSums(cm)[classes]
  n_true <- rowSums(cm)[classes]
  fp <- n_pred - tp
  fn <- n_true - tp

  empty         <- n_true == 0 & n_pred == 0
  never_pred    <- n_true > 0 & n_pred == 0
  absent_truth  <- n_true == 0 & n_pred > 0

  .warn_classes(never_pred, "never predicted; their precision is set to 0")
  .warn_classes(absent_truth, "absent from `truth`; their recall is set to 0")
  .warn_classes(empty, "absent from both `truth` and `estimate`; they are left out of the averages")

  precision <- ifelse(n_pred == 0, 0, tp / n_pred)
  recall    <- ifelse(n_true == 0, 0, tp / n_true)
  f1        <- ifelse(empty, NA_real_, 2 * tp / (2 * tp + fp + fn))
  precision[empty] <- NA_real_
  recall[empty]    <- NA_real_

  tibble::tibble(
    class     = classes,
    precision = unname(precision),
    recall    = unname(recall),
    f1        = unname(f1),
    support   = as.integer(n_true)
  )
}

#' Warn about the classes flagged in a named logical vector
#' @noRd
.warn_classes <- function(flag, msg) {
  if (any(flag)) {
    rlang::warn(paste0(
      "Some classes are ", msg, ": ",
      paste(names(flag)[flag], collapse = ", ")
    ))
  }
}

#' Validate truth/estimate columns and handle missing values
#'
#' Shared by classification_report() and the single-metric functions.
#'
#' @param data A data frame.
#' @param truth_col,estimate_col Column names (strings).
#' @param na_rm If `TRUE`, drop rows where either column is NA; otherwise
#'   abort when NAs are present.
#' @return A list with elements `truth` and `estimate` (factors).
#' @noRd
.prepare_inputs <- function(data, truth_col, estimate_col, na_rm) {
  truth    <- data[[truth_col]]
  estimate <- data[[estimate_col]]

  for (col in c(truth_col, estimate_col)) {
    if (!is.factor(data[[col]])) {
      rlang::abort(paste0("`", col, "` must be a factor."))
    }
  }
  if (!identical(levels(truth), levels(estimate))) {
    rlang::abort(paste0(
      "`", truth_col, "` and `", estimate_col, "` must have the same levels, in the same order."
    ))
  }

  missing <- is.na(truth) | is.na(estimate)
  if (any(missing)) {
    if (!na_rm) {
      rlang::abort("`truth` or `estimate` contains missing values; use `na_rm = TRUE` to drop them.")
    }
    truth    <- truth[!missing]
    estimate <- estimate[!missing]
  }

  list(truth = truth, estimate = estimate)
}

#' Apply `classes_exclude` validation and filtering to a set of class levels
#'
#' Shared by classification_report() and the single-metric functions
#' (precision(), recall(), f1_meas()).
#'
#' @param classes Character vector of class levels (e.g. from `levels(truth)`).
#' @param classes_exclude Character vector of class names to exclude, or
#'   `NULL`.
#' @return The filtered character vector of classes.
#' @noRd
.apply_classes_exclude <- function(classes, classes_exclude) {
  if (is.null(classes_exclude)) {
    return(classes)
  }

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

  classes
}

#' Compute a single averaged metric with optional class exclusion
#'
#' Shared engine behind precision(), recall(), and f1_meas(). Reuses
#' `.compute_per_class()` and averages the requested column according to
#' `estimator`, after applying `classes_exclude` with the same validation
#' logic as classification_report().
#'
#' @param data A data frame containing columns for truth and predictions.
#' @param truth Unquoted column name of true class labels (factor).
#' @param estimate Unquoted column name of predicted class labels (factor).
#' @param metric_col One of `"precision"`, `"recall"`, `"f1"` — the
#'   per-class column (from `.compute_per_class()`) to average.
#' @param estimator One of `"macro"` or `"macro_weighted"`.
#' @param classes_exclude Character vector of class names to exclude, or
#'   `NULL`.
#' @param na_rm Passed to `.prepare_inputs()`.
#' @return A tibble with one row and columns `.metric`, `.estimator`,
#'   `.estimate`.
#' @noRd
.verdict_metric <- function(data, truth, estimate, metric_col, estimator, classes_exclude, na_rm) {
  truth_col    <- rlang::as_name(rlang::ensym(truth))
  estimate_col <- rlang::as_name(rlang::ensym(estimate))

  estimator <- rlang::arg_match(estimator, c("macro", "macro_weighted"))

  inputs  <- .prepare_inputs(data, truth_col, estimate_col, na_rm)
  classes <- .apply_classes_exclude(levels(inputs$truth), classes_exclude)

  per_class <- .compute_per_class(inputs$truth, inputs$estimate, classes)

  estimate_value <- if (estimator == "macro") {
    mean(per_class[[metric_col]], na.rm = TRUE)
  } else {
    stats::weighted.mean(per_class[[metric_col]], per_class$support, na.rm = TRUE)
  }

  tibble::tibble(
    .metric    = metric_col,
    .estimator = estimator,
    .estimate  = estimate_value
  )
}
