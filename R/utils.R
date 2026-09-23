#' Compute per-class precision, recall, F1, and support
#'
#' @param truth Factor of true labels.
#' @param estimate Factor of predicted labels.
#' @param classes Character vector of class levels.
#' @return A tibble with one row per class.
#' @noRd
.compute_per_class <- function(truth, estimate, classes) {
  rows <- lapply(classes, function(cls) {
    tp <- sum(truth == cls & estimate == cls)
    fp <- sum(truth != cls & estimate == cls)
    fn <- sum(truth == cls & estimate != cls)

    precision <- if ((tp + fp) == 0) NA_real_ else tp / (tp + fp)
    recall    <- if ((tp + fn) == 0) NA_real_ else tp / (tp + fn)
    f1        <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) {
      NA_real_
    } else {
      2 * precision * recall / (precision + recall)
    }

    tibble::tibble(
      class     = cls,
      precision = precision,
      recall    = recall,
      f1        = f1,
      support   = as.integer(sum(truth == cls))
    )
  })

  dplyr::bind_rows(rows)
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
#' @return A tibble with one row and columns `.metric`, `.estimator`,
#'   `.estimate`.
#' @noRd
.verdict_metric <- function(data, truth, estimate, metric_col, estimator, classes_exclude) {
  truth_col    <- rlang::as_name(rlang::ensym(truth))
  estimate_col <- rlang::as_name(rlang::ensym(estimate))

  estimator <- rlang::arg_match(estimator, c("macro", "macro_weighted"))

  classes <- .apply_classes_exclude(levels(data[[truth_col]]), classes_exclude)

  per_class <- .compute_per_class(data[[truth_col]], data[[estimate_col]], classes)

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
