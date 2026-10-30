#' Plankton classifier predictions on ZooCAM images
#'
#' Test set predictions of a weighted random forest trained on the native
#' features of the ZooCAMNet dataset, at the grouped taxonomic level. The
#' model is a lighter version of the "Nat + RF" model of Panaïotis et al.
#' (2026), fitted with tidymodels. As in most plankton
#' imaging datasets, non-living particles (detritus, bubbles, fibers...)
#' make up a large share of the objects; see [zoocam_taxa] for which classes
#' are planktonic.
#'
#' @format A tibble with 193,039 rows and 3 columns:
#' \describe{
#'   \item{objid}{EcoTaxa object identifier.}
#'   \item{truth}{True class, a factor with 40 levels.}
#'   \item{pred}{Predicted class, a factor with the same levels as `truth`.}
#' }
#'
#' @source Images and features: Romagnan, J.-B., Panaïotis, T., Bourriau, P.,
#'   et al. (2024). ZooCAMNet: plankton images captured with the ZooCAM.
#'   SEANOE. \doi{10.17882/101928}. Licensed under CC BY 4.0.
#'
#'   Model: Panaïotis, T., et al. (2026). Earth System Science Data, 18, 945.
#'   \doi{10.5194/essd-18-945-2026}.
#'
#'   The script that builds this dataset is in `data-raw/zoocam_tidymodels.R` in the
#'   package source.
#'
#' @examples
#' non_plankton <- zoocam_taxa$class[!zoocam_taxa$plankton]
#' classification_report(zoocam, truth, pred, classes_exclude = non_plankton)
"zoocam"

#' Planktonic status of the ZooCAM classes
#'
#' Whether each class of [zoocam] is planktonic. Non-planktonic classes
#' (detritus, bubbles, artefacts, plastics...) are typically passed to
#' `classes_exclude`.
#'
#' @format A tibble with 40 rows and 2 columns:
#' \describe{
#'   \item{class}{Class name, matching the levels of `zoocam$truth`.}
#'   \item{plankton}{`TRUE` for planktonic classes.}
#' }
#'
#' @source Romagnan, J.-B., Panaïotis, T., Bourriau, P., et al. (2024).
#'   ZooCAMNet: plankton images captured with the ZooCAM. SEANOE.
#'   \doi{10.17882/101928}. Licensed under CC BY 4.0.
"zoocam_taxa"
