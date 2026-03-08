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
#' tb = gtsummary::tbl_summary(data = transform(mtcars, am = factor(am)), by = am)
#' export_gtsummary_table(tb, filename = "my-table", export_docx = TRUE)
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
    docx_dir = file.path(base_dir, docx_subfolder)
    ensure_dir(docx_dir)

    docx_file = file.path(docx_dir, paste0(filename, ".docx"))

    docx_saved = FALSE
    docx_errors = character(0)

    if (inherits(x, "gtsummary") && requireNamespace("flextable", quietly = TRUE)) {
      status_ft = tryCatch(
        {
          ft = gtsummary::as_flex_table(x)
          flextable::save_as_docx(" " = ft, path = docx_file)
          TRUE
        },
        error = function(e) {
          docx_errors <<- c(docx_errors, paste0("flextable export failed: ", conditionMessage(e)))
          FALSE
        }
      )

      if (isTRUE(status_ft)) {
        docx_saved = TRUE
      }
    }

    if (!isTRUE(docx_saved)) {
      status_gt = tryCatch(
        {
          gt::gtsave(
            data = tb_gt,
            filename = docx_file
          )
          TRUE
        },
        error = function(e) {
          docx_errors <<- c(docx_errors, paste0("gt::gtsave DOCX export failed: ", conditionMessage(e)))
          FALSE
        }
      )

      if (isTRUE(status_gt)) {
        docx_saved = TRUE
      }
    }

    if (!isTRUE(docx_saved)) {
      stop(
        paste(
          "DOCX export failed for `export_gtsummary_table()`.",
          "Tried flextable (when available) and gt::gtsave().",
          if (length(docx_errors) > 0) paste(docx_errors, collapse = "\n") else "",
          sep = "\n"
        ),
        call. = FALSE
      )
    }
  }

  invisible(list(
    gt_table = tb_gt,
    html_file = html_file,
    docx_file = docx_file
  ))
}
#' Convert HTML Table Exports to PDF and SVG
#'
#' Converts all `.html` files in the standard export location to `.pdf` (via
#' `wkhtmltopdf`) and `.svg` (via `pdf2svg`).
#'
#' If `page_size` is too small, long table values can wrap into unintended
#' multi-line cells. Prefer a larger `page_size` and crop the final SVG
#' manually if needed.
#'
#' @param base_dir Base export directory.
#' @param html_subfolder HTML subfolder under `base_dir`.
#' @param pdf_subfolder PDF subfolder under `base_dir`.
#' @param svg_subfolder SVG subfolder under `base_dir`.
#' @param page_size Page size passed to `wkhtmltopdf`.
#' @param quiet Whether to suppress command output.
#' @param skip_up_to_date Whether to skip files when output SVG is newer than
#'   input HTML.
#'
#' @return Invisibly returns a list with `converted`, `skipped`, `pdf_files`,
#'   and `svg_files`.
#' @export
#'
#' @examples
#' \dontrun{
#' convert_html_to_svg(base_dir = "exports")
#' }
convert_html_to_svg = function(
  base_dir = "exports",
  html_subfolder = "tables/html",
  pdf_subfolder = "tables/pdf",
  svg_subfolder = "tables/svg",
  page_size = "A2",
  quiet = TRUE,
  skip_up_to_date = TRUE
) {
  stopifnot(is.character(base_dir), length(base_dir) == 1)
  stopifnot(is.character(html_subfolder), length(html_subfolder) == 1)
  stopifnot(is.character(pdf_subfolder), length(pdf_subfolder) == 1)
  stopifnot(is.character(svg_subfolder), length(svg_subfolder) == 1)
  stopifnot(is.character(page_size), length(page_size) == 1)

  html_dir = file.path(base_dir, html_subfolder)
  pdf_dir = file.path(base_dir, pdf_subfolder)
  svg_dir = file.path(base_dir, svg_subfolder)

  if (!dir.exists(html_dir)) {
    stop(
      "No HTML export directory found: ", html_dir,
      ". Run `export_gtsummary_table(..., export_html = TRUE)` first.",
      call. = FALSE
    )
  }

  html_files = list.files(
    path = html_dir,
    pattern = "\\.html$",
    full.names = TRUE
  )

  if (length(html_files) == 0) {
    return(invisible(list(
      converted = character(0),
      skipped = character(0),
      pdf_files = character(0),
      svg_files = character(0)
    )))
  }

  wkhtmltopdf = Sys.which("wkhtmltopdf")
  pdf2svg = Sys.which("pdf2svg")
  missing_tools = character(0)

  if (!nzchar(wkhtmltopdf)) {
    missing_tools = c(missing_tools, "wkhtmltopdf")
  }

  if (!nzchar(pdf2svg)) {
    missing_tools = c(missing_tools, "pdf2svg")
  }

  if (length(missing_tools) > 0) {
    stop(
      paste(
        "Required CLI tools not found in PATH:", paste(missing_tools, collapse = ", "),
        "",
        "Install with one of:",
        "- Conda (all platforms): conda install -c conda-forge wkhtmltopdf pdf2svg",
        "- macOS (Homebrew): brew install wkhtmltopdf pdf2svg",
        "- Ubuntu/Debian: sudo apt-get install wkhtmltopdf pdf2svg",
        "- Windows (Chocolatey): choco install wkhtmltopdf pdf2svg",
        "",
        "Then verify in R:",
        "Sys.which(c(\"wkhtmltopdf\", \"pdf2svg\"))",
        sep = "\n"
      ),
      call. = FALSE
    )
  }

  ensure_dir(pdf_dir)
  ensure_dir(svg_dir)

  converted = character(0)
  skipped = character(0)
  pdf_files = character(0)
  svg_files = character(0)

  for (html_file in html_files) {
    filename = basename(html_file)
    filename = sub("\\.html$", "", filename, ignore.case = TRUE)

    pdf_file = file.path(pdf_dir, paste0(filename, ".pdf"))
    svg_file = file.path(svg_dir, paste0(filename, ".svg"))

    if (isTRUE(skip_up_to_date) && file.exists(svg_file)) {
      html_mtime = file.info(html_file)$mtime
      svg_mtime = file.info(svg_file)$mtime

      if (!is.na(html_mtime) && !is.na(svg_mtime) && svg_mtime >= html_mtime) {
        skipped = c(skipped, html_file)
        pdf_files = c(pdf_files, pdf_file)
        svg_files = c(svg_files, svg_file)
        next
      }
    }

    args_pdf = c(
      if (isTRUE(quiet)) "--quiet",
      "--page-size",
      page_size,
      html_file,
      pdf_file
    )

    status_pdf = system2(
      command = wkhtmltopdf,
      args = args_pdf,
      stdout = if (isTRUE(quiet)) FALSE else "",
      stderr = if (isTRUE(quiet)) FALSE else ""
    )

    if (!identical(status_pdf, 0L)) {
      stop("`wkhtmltopdf` failed for file: ", html_file, call. = FALSE)
    }

    status_svg = system2(
      command = pdf2svg,
      args = c(pdf_file, svg_file),
      stdout = if (isTRUE(quiet)) FALSE else "",
      stderr = if (isTRUE(quiet)) FALSE else ""
    )

    if (!identical(status_svg, 0L)) {
      stop("`pdf2svg` failed for file: ", pdf_file, call. = FALSE)
    }

    converted = c(converted, html_file)
    pdf_files = c(pdf_files, pdf_file)
    svg_files = c(svg_files, svg_file)
  }

  invisible(list(
    converted = converted,
    skipped = skipped,
    pdf_files = pdf_files,
    svg_files = svg_files
  ))
}
