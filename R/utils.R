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
