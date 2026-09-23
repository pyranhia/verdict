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
