# researchExports

`researchExports` is a lightweight R package for consistent export of research outputs.

It provides small, reusable helpers to:

- Save `ggplot2` plots in multiple formats (`svg`, `png`, `eps`)
- Export survival plot layouts (main plot plus optional risk table/cumulative events)
- Export `gtsummary`/`gt` tables to HTML and, when applicable, DOCX

The package is designed for scripts and reports where you want predictable file paths,
repeatable export settings, and minimal setup.

## Installation

```r
remotes::install_github("mar92kus/mxport")
library(researchExports)
```

## Usage

Set your working directory to your project folder so `base_dir = "exports"`
creates output inside that project (example: `rtest`).

```r
setwd("/Users/markus/Documents/Research/rtest")
```

### `save_plot()`

```r
p = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
  ggplot2::geom_point()

researchExports::save_plot(
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

researchExports::save_surv_plots(
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

researchExports::export_gtsummary_table(
  x = tbl,
  filename = "mtcars-table",
  base_dir = "exports",
  export_html = TRUE,
  export_docx = FALSE
)
```
