#' Ensure a Directory Exists
#'
#' Internal helper to create a directory path when it is missing.
#'
#' @param path Directory path.
#' @return Invisibly returns `NULL`.
#' @keywords internal
#' @noRd
ensure_dir = function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }
}

#' Build Export File Paths
#'
#' Internal helper that creates format-specific folders and output file paths.
#'
#' @param filename Base file name.
#' @param base_dir Base export directory.
#' @param subfolder Subfolder under `base_dir`.
#' @param formats Character vector of output formats.
#' @param suffix Optional suffix appended to `filename`.
#' @return Named character vector of output file paths.
#' @keywords internal
#' @noRd
build_export_files = function(
  filename,
  base_dir,
  subfolder,
  formats = c("svg", "png", "eps"),
  suffix = NULL
) {
  stopifnot(is.character(filename), length(filename) == 1)

  if (!is.null(suffix)) {
    filename = paste0(filename, suffix)
  }

  dirs = stats::setNames(
    object = file.path(base_dir, subfolder, formats),
    nm = formats
  )

  invisible(lapply(dirs, ensure_dir))

  files = stats::setNames(
    object = file.path(dirs, paste0(filename, ".", formats)),
    nm = formats
  )

  files
}

#' Save a Plot in Multiple Formats
#'
#' Internal helper to write a ggplot object to all target file paths.
#'
#' @param plot A ggplot-compatible plot object.
#' @param files Named vector/list of file paths keyed by format.
#' @param width Plot width.
#' @param height Plot height.
#' @param dpi DPI used for raster formats.
#' @param bg Background color.
#' @param units Size units for width and height.
#' @param suppress_eps_warnings Whether to suppress EPS warnings.
#' @return Invisibly returns `files`.
#' @keywords internal
#' @noRd
save_ggplot_formats = function(
  plot,
  files,
  width,
  height,
  dpi = 300,
  bg = "white",
  units = "in",
  suppress_eps_warnings = TRUE
) {
  for (fmt in names(files)) {
    if (fmt == "png") {
      ggplot2::ggsave(
        filename = files[[fmt]],
        plot = plot,
        device = fmt,
        width = width,
        height = height,
        units = units,
        dpi = dpi,
        bg = bg
      )
    } else if (fmt == "eps" && isTRUE(suppress_eps_warnings)) {
      suppressWarnings(
        ggplot2::ggsave(
          filename = files[[fmt]],
          plot = plot,
          device = fmt,
          width = width,
          height = height,
          units = units,
          bg = bg
        )
      )
    } else {
      ggplot2::ggsave(
        filename = files[[fmt]],
        plot = plot,
        device = fmt,
        width = width,
        height = height,
        units = units,
        bg = bg
      )
    }
  }

  invisible(files)
}

#' Save a ggplot to Multiple Export Formats
#'
#' @param plot A ggplot-compatible plot object.
#' @param filename Base output filename without extension.
#' @param base_dir Base export directory.
#' @param subfolder Subfolder under `base_dir`.
#' @param formats Character vector of output formats.
#' @param width Plot width.
#' @param height Plot height.
#' @param dpi DPI used for raster formats.
#' @param bg Background color.
#' @param units Size units for width and height.
#'
#' @return Invisibly returns named file paths by format.
#' @export
#'
#' @examples
#' \dontrun{
#' p = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
#' save_plot(plot = p, filename = "scatter")
#' }
save_plot = function(
  plot,
  filename,
  base_dir = "exports",
  subfolder = "charts",
  formats = c("svg", "png", "eps"),
  width = 7,
  height = 5,
  dpi = 300,
  bg = "white",
  units = "in"
) {
  files = build_export_files(
    filename = filename,
    base_dir = base_dir,
    subfolder = subfolder,
    formats = formats
  )

  save_ggplot_formats(
    plot = plot,
    files = files,
    width = width,
    height = height,
    dpi = dpi,
    bg = bg,
    units = units
  )

  invisible(files)
}

#' Save Survival Plot Layouts to Multiple Export Formats
#'
#' Saves both a combined plot (main + optional table/cumevents) and the main
#' plot alone.
#'
#' @param survplot A list-like object containing `plot`, `table`,
#'   and optionally `cumevents` ggplot objects (e.g., from
#'   `survminer::ggsurvplot`).
#' @param filename Base output filename without extension.
#' @param base_dir Base export directory.
#' @param subfolder Subfolder under `base_dir`.
#' @param formats Character vector of output formats.
#' @param width Plot width.
#' @param height_main Height of the main plot.
#' @param heights Relative heights for main plot and table.
#' @param cumevents_height Relative height for cumevents section.
#' @param dpi DPI used for raster formats.
#' @param bg Background color.
#' @param units Size units for width and height.
#' @param include_table Whether to include the risk table when available.
#' @param include_cumevents Whether to include cumevents when available.
#' @param combined_suffix Suffix for combined plot files.
#' @param main_suffix Suffix for main plot files.
#'
#' @return Invisibly returns a list with `combined` and `main` file maps.
#' @export
#'
#' @examples
#' \dontrun{
#' sp = list(
#'   plot = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_line(),
#'   table = ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) + ggplot2::geom_boxplot(),
#'   cumevents = NULL
#' )
#' save_surv_plots(sp, filename = "survival")
#' }
save_surv_plots = function(
  survplot,
  filename,
  base_dir = "exports",
  subfolder = "charts",
  formats = c("svg", "png", "eps"),
  width = 6,
  height_main = 5,
  heights = c(2.2, 0.5),
  cumevents_height = 0.6,
  dpi = 300,
  bg = "white",
  units = "in",
  include_table = TRUE,
  include_cumevents = FALSE,
  combined_suffix = "_with_table",
  main_suffix = "_without_table"
) {
  if (!requireNamespace("patchwork", quietly = TRUE)) {
    stop(
      "Package `patchwork` is required for `save_surv_plots()`. Install it with `install.packages('patchwork')`.",
      call. = FALSE
    )
  }

  p_main = survplot$plot
  p_table = survplot$table
  p_cum = survplot$cumevents

  if (is.null(p_main)) {
    stop("`survplot$plot` is NULL. Expected a ggsurvplot object.", call. = FALSE)
  }

  has_table = isTRUE(include_table) && !is.null(p_table)
  has_cum = isTRUE(include_cumevents) && !is.null(p_cum)

  if (has_table && has_cum) {
    comb = (p_main / p_table / p_cum) +
      patchwork::plot_layout(heights = c(heights, cumevents_height))
    height_comb = height_main * (sum(c(heights, cumevents_height)) / heights[1])
  } else if (has_table) {
    comb = (p_main / p_table) +
      patchwork::plot_layout(heights = heights)
    height_comb = height_main * (sum(heights) / heights[1])
  } else {
    comb = p_main
    height_comb = height_main
  }

  files_combined = build_export_files(
    filename = filename,
    base_dir = base_dir,
    subfolder = subfolder,
    formats = formats,
    suffix = combined_suffix
  )

  files_main = build_export_files(
    filename = filename,
    base_dir = base_dir,
    subfolder = subfolder,
    formats = formats,
    suffix = main_suffix
  )

  save_ggplot_formats(
    plot = comb,
    files = files_combined,
    width = width,
    height = height_comb,
    dpi = dpi,
    bg = bg,
    units = units
  )

  save_ggplot_formats(
    plot = p_main,
    files = files_main,
    width = width,
    height = height_main,
    dpi = dpi,
    bg = bg,
    units = units
  )

  invisible(list(
    combined = files_combined,
    main = files_main
  ))
}

#' Export gtsummary or gt Tables to HTML and DOCX
#'
#' @param x A `gtsummary` object or a `gt_tbl` object.
#' @param filename Base output filename without extension.
#' @param base_dir Base export directory.
#' @param html_subfolder Subfolder for HTML output under `base_dir`.
#' @param docx_subfolder Subfolder for DOCX output under `base_dir`.
#' @param export_html Whether to export HTML output.
#' @param export_docx Whether to export DOCX output.
#' @param apply_theme Whether to apply table styling options.
#' @param data_row_padding Padding in pixels for data rows.
#' @param row_group_padding Padding in pixels for row groups.
#' @param table_font_size_pct Table font size as percent.
#'
#' @return Invisibly returns a list with `gt_table`, `html_file`, and `docx_file`.
#' @export
#'
#' @examples
#' \dontrun{
#' tb = gt::gt(head(mtcars))
#' export_gtsummary_table(tb, filename = "my-table", export_docx = FALSE)
#' }
export_gtsummary_table = function(
  x,
  filename,
  base_dir = "exports",
  html_subfolder = "tables/html",
  docx_subfolder = "tables/docx",
  export_html = TRUE,
  export_docx = TRUE,
  apply_theme = TRUE,
  data_row_padding = 4,
  row_group_padding = 4,
  table_font_size_pct = 85
) {
  html_file = NULL
  docx_file = NULL

  if (inherits(x, "gtsummary")) {
    if (!requireNamespace("gtsummary", quietly = TRUE)) {
      stop("Package `gtsummary` is required for gtsummary objects.", call. = FALSE)
    }
    tb_gt = gtsummary::as_gt(x)
  } else if (inherits(x, "gt_tbl")) {
    tb_gt = x
  } else {
    stop("`x` must be a gtsummary object or a gt_tbl.", call. = FALSE)
  }

  if (isTRUE(apply_theme)) {
    tb_gt = gt::tab_options(
      data = tb_gt,
      data_row.padding = gt::px(data_row_padding),
      row_group.padding = gt::px(row_group_padding),
      table.font.size = gt::pct(table_font_size_pct)
    )
  }

  if (isTRUE(export_html)) {
    html_dir = file.path(base_dir, html_subfolder)
    ensure_dir(html_dir)

    html_file = file.path(html_dir, paste0(filename, ".html"))

    gt::gtsave(
      data = tb_gt,
      filename = html_file
    )
  }

  if (isTRUE(export_docx)) {
    if (!inherits(x, "gtsummary")) {
      warning(
        "DOCX export is only supported for the original gtsummary object. HTML export was completed.",
        call. = FALSE
      )
    } else {
      if (!requireNamespace("flextable", quietly = TRUE)) {
        stop("Package `flextable` is required for DOCX export.", call. = FALSE)
      }

      docx_dir = file.path(base_dir, docx_subfolder)
      ensure_dir(docx_dir)

      docx_file = file.path(docx_dir, paste0(filename, ".docx"))

      ft = gtsummary::as_flex_table(x)

      flextable::save_as_docx(
        " " = ft,
        path = docx_file
      )
    }
  }

  invisible(list(
    gt_table = tb_gt,
    html_file = html_file,
    docx_file = docx_file
  ))
}
