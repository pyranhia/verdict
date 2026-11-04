# Build test set predictions on ISIISNet
#
# Same model as data-raw/zoocam_tidymodels.R (a lighter version of the
# "Nat + RF" model of Panaïotis et al., 2026, ESSD,
# https://doi.org/10.5194/essd-18-945-2026), applied to ISIISNet: a random
# forest on the native features, at the grouped taxonomic level
# (`taxon_level2`), using the paper's train/test split. Unlike the paper, the
# classes are not weighted (weight_power = 0): the main vignette shows how
# misleading accuracy is for a default model.
#
# Data: Panaïotis et al. (2024). ISIISNet: plankton images captured with the
# ISIIS (In-situ Ichthyoplankton Imaging System). SEANOE.
# https://doi.org/10.17882/101950 (CC BY-NC 4.0)
#
# The licence question is not settled yet, so the predictions are saved in
# data-raw/isiis/ and not shipped with the package.
#
# Run from the package root. Needs tidymodels and ranger (not verdict
# dependencies): renv::install(c("tidymodels", "ranger"))

if (!file.exists("DESCRIPTION") || !dir.exists("data-raw")) {
  stop(
    "Run this script from the package root: Rscript data-raw/isiis_tidymodels.R"
  )
}

library(tidymodels)

set.seed(20261104)

# Same parameters as for zoocam, except for weight_power (no class weights)
# and sample_fraction: the training set is about three times smaller (286k vs
# 901k objects), so each tree sees a larger fraction of it. The number of
# trees is fixed, so the validation set is not used.
n_trees <- 200
min_node_size <- 10
weight_power <- 0 # w_i = (max(n) / n_i)^weight_power, on training counts; 0 = no weights
sample_fraction <- 0.5

raw_dir <- "data-raw/isiis"
dir.create(raw_dir, showWarnings = FALSE, recursive = TRUE)


## Download --------------------------------------------------------------------

# The archive is 760 MB, mostly images: stream it and keep only the two CSV files.
members <- c("ISIISNet/taxa.csv.gz", "ISIISNet/features_native.csv.gz")
if (!all(file.exists(file.path(raw_dir, members)))) {
  url <- "https://www.seanoe.org/data/00908/101950/data/113146.tar"
  cmd <- paste(
    "curl -sL",
    url,
    "| tar -x -C",
    raw_dir,
    "-f -",
    paste(members, collapse = " ")
  )
  status <- system(cmd)
  stopifnot(status == 0, all(file.exists(file.path(raw_dir, members))))
}


## Read and prepare ------------------------------------------------------------

taxa <- read.csv(gzfile(file.path(raw_dir, members[1])))
features <- read.csv(gzfile(file.path(raw_dir, members[2])))

df <- taxa |>
  select(objid, taxon = taxon_level2, plankton, set) |>
  inner_join(features, by = "objid")
stopifnot(nrow(df) == nrow(taxa))

feature_cols <- setdiff(names(features), "objid")

# Fail loudly rather than silently imputing
n_missing <- colSums(is.na(df[feature_cols]))
if (any(n_missing > 0)) {
  stop(
    "Missing values in features: ",
    paste(names(n_missing)[n_missing > 0], collapse = ", ")
  )
}

classes <- sort(unique(df$taxon))
df$taxon <- factor(df$taxon, levels = classes)

train <- filter(df, set == "train")
test <- filter(df, set == "test")


## Fit -------------------------------------------------------------------------

# Class weights in the splitting rule, in factor-level order
n_train <- table(train$taxon)
class_weights <- as.numeric((max(n_train) / n_train)^weight_power)

rf_spec <- rand_forest(
  trees = n_trees,
  mtry = floor(sqrt(length(feature_cols))),
  min_n = min_node_size
) |>
  set_engine(
    "ranger",
    class.weights = class_weights,
    sample.fraction = sample_fraction,
    seed = 20261104
  ) |>
  set_mode("classification")

rf_wf <- workflow() |>
  add_variables(outcomes = taxon, predictors = all_of(feature_cols)) |>
  add_model(rf_spec)

rf_fit <- fit(rf_wf, data = train)


## Predict on the test set -----------------------------------------------------

isiis <- augment(rf_fit, new_data = test) |>
  transmute(objid, truth = taxon, pred = .pred_class)
stopifnot(identical(levels(isiis$pred), classes))

isiis_taxa <- df |>
  distinct(class = as.character(taxon), plankton) |>
  arrange(class) |>
  as_tibble()
stopifnot(nrow(isiis_taxa) == length(classes))

saveRDS(isiis, file.path(raw_dir, "isiis.rds"))
saveRDS(isiis_taxa, file.path(raw_dir, "isiis_taxa.rds"))
