# researchExports

Minimal export helpers for research reporting workflows.

## Installation

```r
remotes::install_github("<REPLACE_WITH_USERNAME>/researchExports")
library(researchExports)
```

## Usage

### `save_plot()`

```r
p = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
  ggplot2::geom_point()

save_plot(
  plot = p,
  filename = "mtcars-scatter",
  base_dir = "exports"
)
```

### `save_surv_plots()`

```r
# Minimal object with the same slots expected from survminer::ggsurvplot
survplot_obj = list(
  plot = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_line(),
  table = ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) + ggplot2::geom_boxplot(),
  cumevents = ggplot2::ggplot(mtcars, ggplot2::aes(wt, qsec)) + ggplot2::geom_point()
)

save_surv_plots(
  survplot = survplot_obj,
  filename = "survival-layout",
  base_dir = "exports",
  include_table = TRUE,
  include_cumevents = FALSE
)
```

### `export_gtsummary_table()`

```r
tbl = gt::gt(head(mtcars))

export_gtsummary_table(
  x = tbl,
  filename = "mtcars-table",
  base_dir = "exports",
  export_html = TRUE,
  export_docx = FALSE
)
```
