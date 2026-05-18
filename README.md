
# verdict

**verdict** is an R package that extends
[yardstick](https://yardstick.tidymodels.org/) with flexible evaluation
tools for multiclass classification models.

It fills two gaps in yardstick:

- No `classification_report()` equivalent to
  [sklearn’s](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.classification_report.html)
  ([yardstick
  \#308](https://github.com/tidymodels/yardstick/issues/308))
- No way to exclude specific classes from aggregate metric computation

**Motivation:** benchmarking plankton image classifiers ([Panaïotis et
al., 2022, *Earth System Science
Data*](https://essd.copernicus.org/articles/18/945/2026/)) where a
dominant “detritus” class biases macro and weighted averages.

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

## Roadmap

| Version | Content |
|----|----|
| v1.0 | `classification_report()`: precision, recall, F1, support per class with macro and weighted averages |
| v1.1 | `classes_exclude` argument on aggregate metrics: exclude specific classes from average computation |
| v1.2 | `class_weights` argument: custom weighting independent of class frequencies |

## Related work

- [yardstick](https://yardstick.tidymodels.org/): tidy models metric
  estimation
- [sklearn.metrics.classification_report](https://scikit-learn.org/stable/modules/generated/sklearn.metrics.classification_report.html):
  the Python reference
