# Build the `zoocam` and `zoocam_taxa` datasets
#
# A lighter version of the "Nat + RF" model of Panaïotis et al. (2026, ESSD,
# https://doi.org/10.5194/essd-18-945-2026) on ZooCAMNet with tidymodels: a
# weighted random forest on the native ZooCAM features, at the grouped
# taxonomic level (`taxon_level2`), using the paper's train/test split. Only
# the test set predictions are shipped with the package.
#
# Data: Romagnan et al. (2024). ZooCAMNet: plankton images captured with the
# ZooCAM. SEANOE. https://doi.org/10.17882/101928 (CC BY 4.0)
#
# Run from the package root. Needs tidymodels and ranger (not verdict
# dependencies): renv::install(c("tidymodels", "ranger"))

if (!file.exists("DESCRIPTION") || !dir.exists("data-raw")) {
  stop("Run this script from the package root: Rscript data-raw/zoocam_tidymodels.R")
}

library(tidymodels)

set.seed(20261029)

# Parameters, chosen to keep the fit light rather than to match the paper
# exactly: fewer trees, larger terminal nodes, and each tree sees only a
# random fraction of the training set. The number of trees is fixed, so the
# validation set is not used.
n_trees         <- 200
min_node_size   <- 10
weight_power    <- 0.25  # w_i = (max(n) / n_i)^weight_power, on training counts
sample_fraction <- 0.1

raw_dir <- "data-raw/zoocam"
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)


## Download --------------------------------------------------------------------

# The archive is 4 GB, mostly images: stream it and keep only the two CSV files.
members <- c("ZooCamNet/taxa.csv.gz", "ZooCamNet/features_native.csv.gz")
if (!all(file.exists(file.path(raw_dir, members)))) {
  url <- "https://www.seanoe.org/data/00907/101928/data/113094.tar"
  cmd <- paste("curl -sL", url, "| tar -x -C", raw_dir, "-f -", paste(members, collapse = " "))
  status <- system(cmd)
  stopifnot(status == 0, all(file.exists(file.path(raw_dir, members))))
}


## Read and prepare ------------------------------------------------------------

taxa     <- read.csv(gzfile(file.path(raw_dir, members[1])))
features <- read.csv(gzfile(file.path(raw_dir, members[2])))

df <- taxa |>
  select(objid, taxon = taxon_level2, plankton, set) |>
  inner_join(features, by = "objid")
stopifnot(nrow(df) == nrow(taxa))

feature_cols <- setdiff(names(features), "objid")

# Fail loudly rather than silently imputing
n_missing <- colSums(is.na(df[feature_cols]))
if (any(n_missing > 0)) {
  stop("Missing values in features: ", paste(names(n_missing)[n_missing > 0], collapse = ", "))
}

classes <- sort(unique(df$taxon))
df$taxon <- factor(df$taxon, levels = classes)

train <- filter(df, set == "train")
test  <- filter(df, set == "test")


## Fit -------------------------------------------------------------------------

# Class weights in the splitting rule, in factor-level order
n_train <- table(train$taxon)
class_weights <- as.numeric((max(n_train) / n_train)^weight_power)

rf_spec <- rand_forest(
  trees = n_trees,
  mtry  = floor(sqrt(length(feature_cols))),
  min_n = min_node_size
) |>
  set_engine(
    "ranger",
    class.weights   = class_weights,
    sample.fraction = sample_fraction,
    seed            = 20261029
  ) |>
  set_mode("classification")

rf_wf <- workflow() |>
  add_variables(outcomes = taxon, predictors = all_of(feature_cols)) |>
  add_model(rf_spec)

rf_fit <- fit(rf_wf, data = train)


## Predict on the test set -----------------------------------------------------

zoocam <- augment(rf_fit, new_data = test) |>
  transmute(objid, truth = taxon, pred = .pred_class)
stopifnot(identical(levels(zoocam$pred), classes))

zoocam_taxa <- df |>
  distinct(class = as.character(taxon), plankton) |>
  arrange(class) |>
  as_tibble()
stopifnot(nrow(zoocam_taxa) == length(classes))

usethis::use_data(zoocam, zoocam_taxa, overwrite = TRUE, compress = "xz")
file.size(c("data/zoocam.rda", "data/zoocam_taxa.rda"))


## Compare with the paper (Table S8, Nat + RF, grouped classes) ----------------

# Loaded after tidymodels so verdict's precision()/recall() mask yardstick's
devtools::load_all()

non_plankton <- zoocam_taxa$class[!zoocam_taxa$plankton]

all_classes   <- classification_report(zoocam, truth, pred)
plankton_only <- classification_report(zoocam, truth, pred, classes_exclude = non_plankton)

comparison <- tribble(
  ~metric,                          ~paper, ~verdict,
  "Accuracy",                         0.83, mean(zoocam$truth == zoocam$pred),
  "Balanced accuracy",                0.54, all_classes$recall[all_classes$class == "macro avg"],
  "Macro F1",                         0.55, all_classes$f1[all_classes$class == "macro avg"],
  "Micro F1",                         0.83, mean(zoocam$truth == zoocam$pred),
  # The paper's plankton precision/recall: unclear whether macro or weighted,
  # so both are reported.
  "Plankton precision (macro)",       0.89, plankton_only$precision[plankton_only$class == "macro avg"],
  "Plankton precision (weighted)",    0.89, plankton_only$precision[plankton_only$class == "weighted avg"],
  "Plankton recall (macro)",          0.86, plankton_only$recall[plankton_only$class == "macro avg"],
  "Plankton recall (weighted)",       0.86, plankton_only$recall[plankton_only$class == "weighted avg"]
)
print(comparison, n = Inf)
