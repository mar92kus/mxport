# mxport

`mxport` is a lightweight R package for consistent export of research outputs.

It provides small, reusable helpers to:

- Save `ggplot2` plots in multiple formats (`svg`, `png`, `eps`)
- Export survival plot layouts (main plot plus optional risk table/cumulative events)
- Export `gtsummary`/`gt` tables to HTML and, when applicable, DOCX
- Convert exported HTML tables to PDF and SVG

The package is designed for scripts and reports where you want predictable file paths,
repeatable export settings, and minimal setup.

## Installation

```r
remotes::install_github("mar92kus/mxport")
library(mxport)
```

## Usage

Set your working directory to your project folder so `base_dir = "exports"`
creates output inside that project.

```r
setwd("/path/to/your/project")
```

### `save_plot()`

```r
p = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
  ggplot2::geom_point()

mxport::save_plot(
  plot = p,
  filename = "mtcars-scatter",
  base_dir = "exports"
)
```

Arguments:

| Argument | Default | Description |
|---|---|---|
| `plot` | (required) | ggplot-compatible plot object to export. |
| `filename` | (required) | Base output filename without extension. |
| `base_dir` | `"exports"` | Base export directory. |
| `subfolder` | `"charts"` | Subfolder under `base_dir` for plot outputs. |
| `formats` | `c("svg", "png", "eps")` | Output formats to write. |
| `width` | `7` | Plot width. |
| `height` | `5` | Plot height. |
| `dpi` | `300` | DPI for raster output (e.g., PNG). |
| `bg` | `"white"` | Background color. |
| `units` | `"in"` | Size units (`in`, `cm`, `mm`). |

### `save_surv_plots()`

```r
# Minimal object with the same slots expected from survminer::ggsurvplot
survplot_obj = list(
  plot = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_line(),
  table = ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) + ggplot2::geom_boxplot(),
  cumevents = ggplot2::ggplot(mtcars, ggplot2::aes(wt, qsec)) + ggplot2::geom_point()
)

mxport::save_surv_plots(
  survplot = survplot_obj,
  filename = "survival-layout",
  base_dir = "exports",
  include_table = TRUE,
  include_cumevents = FALSE
)
```

Arguments:

| Argument | Default | Description |
|---|---|---|
| `survplot` | (required) | List-like object with `plot`, `table`, and optional `cumevents`. |
| `filename` | (required) | Base output filename without extension. |
| `base_dir` | `"exports"` | Base export directory. |
| `subfolder` | `"charts"` | Subfolder under `base_dir` for outputs. |
| `formats` | `c("svg", "png", "eps")` | Output formats to write. |
| `width` | `6` | Plot width. |
| `height_main` | `5` | Height for main survival plot. |
| `heights` | `c(2.2, 0.5)` | Relative heights for main plot and table. |
| `cumevents_height` | `0.6` | Relative height for cumevents panel. |
| `dpi` | `300` | DPI for raster output. |
| `bg` | `"white"` | Background color. |
| `units` | `"in"` | Size units (`in`, `cm`, `mm`). |
| `include_table` | `TRUE` | Include risk table in combined output when available. |
| `include_cumevents` | `FALSE` | Include cumevents panel in combined output when available. |
| `combined_suffix` | `"_with_table"` | Suffix for combined output filenames. |
| `main_suffix` | `"_without_table"` | Suffix for main-only output filenames. |

### `export_gtsummary_table()`

```r
tbl = gtsummary::tbl_summary(
  data = transform(mtcars, am = factor(am)),
  by = am
)

mxport::export_gtsummary_table(
  x = tbl,
  filename = "mtcars-table",
  base_dir = "exports",
  export_html = TRUE,
  export_docx = TRUE
)
```

Arguments:

| Argument | Default | Description |
|---|---|---|
| `x` | (required) | `gtsummary` object or `gt_tbl`. |
| `filename` | (required) | Base output filename without extension. |
| `base_dir` | `"exports"` | Base export directory. |
| `html_subfolder` | `"tables/html"` | HTML output subfolder under `base_dir`. |
| `docx_subfolder` | `"tables/docx"` | DOCX output subfolder under `base_dir`. |
| `export_html` | `TRUE` | Export HTML file. |
| `export_docx` | `TRUE` | Export DOCX file (for original `gtsummary` input). |
| `apply_theme` | `TRUE` | Apply default table styling. |
| `data_row_padding` | `4` | Data row padding in pixels. |
| `row_group_padding` | `4` | Row group padding in pixels. |
| `table_font_size_pct` | `85` | Table font size as percent. |

### `convert_html_to_svg()`

Run this once after all HTML table exports are created. It is not executed automatically by `export_gtsummary_table()`.

```r
mxport::convert_html_to_svg(
  base_dir = "exports",
  page_size = "A2" # Important: controls output page/canvas size
)
```

Arguments:

| Argument | Default | Description |
|---|---|---|
| `base_dir` | `"exports"` | Base export directory. |
| `html_subfolder` | `"tables/html"` | HTML input subfolder under `base_dir`. |
| `pdf_subfolder` | `"tables/pdf"` | PDF output subfolder under `base_dir`. |
| `svg_subfolder` | `"tables/svg"` | SVG output subfolder under `base_dir`. |
| `page_size` | `"A2"` | Page size passed to `wkhtmltopdf` before SVG conversion. |
| `quiet` | `TRUE` | Suppress CLI output from conversion commands. |
| `skip_up_to_date` | `TRUE` | Skip conversion when existing SVG is newer than source HTML. |

`convert_html_to_svg()` requires the CLI tools `wkhtmltopdf` and `pdf2svg` to
be available in your system `PATH`.
