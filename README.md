
# verdict

<!-- badges: start -->

[![R-CMD-check](https://github.com/pyranhia/verdict/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/pyranhia/verdict/actns/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**verdict** is an R package that extends
[yardstick](https://yardstick.tidymodels.org/) with flexible evaluation
tools for multiclass classification models.

It fills two gaps in yardstick:

- No `classification_report()` returning per-class precision, recall,
  F1, and support ([yardstick
  \#308](https://github.com/tidymodels/yardstick/issues/308), open since
  2022; see also
  [\#326](https://github.com/tidymodels/yardstick/issues/326))
- No way to exclude specific classes from aggregate metric computation

**Motivation:** benchmarking plankton image classifiers ([Panaïotis et
al., 2026, *Earth System Science
Data*](https://essd.copernicus.org/articles/18/945/2026/)). Real-world
plankton datasets are usually dominated by non-living particles (marine
snow, bubbles, etc.) grouped into a “detritus” class. A classifier that
always predicts this majority class can reach high overall accuracy
while giving no insight into the rarer, ecologically meaningful classes.
Macro and weighted averages inherit that same bias; hence the need to
exclude “detritus” (or any other irrelevant class) from precision,
recall, and F1 averages.

## Installation

``` r
# Development version from GitHub
# install.packages("remotes")
remotes::install_github("pyranhia/verdict")
```

## Usage

``` r
library(verdict)
library(tibble)

truth <- factor(
  c("cat", "cat", "dog", "dog", "dog", "fish", "fish", "fish"),
  levels = c("cat", "dog", "fish")
)
pred <- factor(
  c("cat", "dog", "dog", "dog", "cat", "fish", "fish", "dog"),
  levels = c("cat", "dog", "fish")
)
df <- tibble(truth = truth, pred = pred)

classification_report(df, truth, pred)
#> # A tibble: 5 × 5
#>   class        precision recall    f1 support
#>   <chr>            <dbl>  <dbl> <dbl>   <int>
#> 1 cat              0.5    0.5   0.5         2
#> 2 dog              0.5    0.667 0.571       3
#> 3 fish             1      0.667 0.8         3
#> 4 macro avg        0.667  0.611 0.624       8
#> 5 weighted avg     0.688  0.625 0.639       8
```

Excluding a class (e.g. a dominant, uninformative “detritus” class) from
the averages:

``` r
classification_report(df, truth, pred, classes_exclude = "fish")
#> # A tibble: 4 × 5
#>   class        precision recall    f1 support
#>   <chr>            <dbl>  <dbl> <dbl>   <int>
#> 1 cat                0.5  0.5   0.5         2
#> 2 dog                0.5  0.667 0.571       3
#> 3 macro avg          0.5  0.583 0.536       5
#> 4 weighted avg       0.5  0.6   0.543       5
```

Single-value metrics, matching yardstick’s output format
(`.metric`/`.estimator`/`.estimate`), also support `classes_exclude`:

``` r
precision(df, truth, pred)
#> # A tibble: 1 × 3
#>   .metric   .estimator .estimate
#>   <chr>     <chr>          <dbl>
#> 1 precision macro          0.667
recall(df, truth, pred, estimator = "macro_weighted")
#> # A tibble: 1 × 3
#>   .metric .estimator     .estimate
#>   <chr>   <chr>              <dbl>
#> 1 recall  macro_weighted     0.625
f1_meas(df, truth, pred, classes_exclude = "fish")
#> # A tibble: 1 × 3
#>   .metric .estimator .estimate
#>   <chr>   <chr>          <dbl>
#> 1 f1      macro          0.536
```

## Development

See [`NEWS.md`](NEWS.md) for the release history.

Planned next: full integration with yardstick’s S3 metric protocol
(`class_metric_summarizer`), so `precision()`, `recall()`, and
`f1_meas()` can be used directly in `metric_set()` and `tune_grid()`.

## Related work

- [yardstick](https://yardstick.tidymodels.org/): tidy models metric
  estimation
