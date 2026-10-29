# verdict (development version)

* Classes with zero true positives now get F1 = 0 instead of `NA`. They
  were previously dropped from the macro and weighted averages, which
  inflated those averages.
* Undefined precision (class never predicted) or recall (class absent from
  `truth`) is now set to 0 with a warning, matching scikit-learn's default
  `zero_division` behaviour. Classes absent from both `truth` and
  `estimate` get `NA` and are left out of the averages.
* New `na_rm` argument (default `TRUE`): rows with a missing `truth` or
  `estimate` are dropped instead of causing an error.
* `truth` and `estimate` must now be factors with identical levels, with
  an informative error otherwise.

# verdict 0.1.0

First functional release.

* `classification_report()`: per-class precision, recall, F1-score, and
  support, plus macro and weighted averages — the `classification_report()`
  equivalent yardstick doesn't have (tidymodels/yardstick#308,
  tidymodels/yardstick#326).
* `classes_exclude` argument on `classification_report()`: exclude specific
  classes from the average computations, motivated by imbalanced multiclass
  problems such as plankton image classification where a dominant
  "detritus" class biases aggregate metrics.
* `precision()`, `recall()`, `f1_meas()`: single-value metrics matching
  yardstick's output format (`.metric`/`.estimator`/`.estimate`), with the
  same `classes_exclude` support and an `estimator` argument (`"macro"` or
  `"macro_weighted"`).
