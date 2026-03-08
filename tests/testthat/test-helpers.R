test_that("ensure_dir creates directories and is idempotent", {
  dir_path = file.path(tempdir(), "mxport-test", "nested")

  if (dir.exists(dir_path)) {
    unlink(dir_path, recursive = TRUE, force = TRUE)
  }

  expect_false(dir.exists(dir_path))
  expect_silent(mxport:::ensure_dir(dir_path))
  expect_true(dir.exists(dir_path))

  expect_silent(mxport:::ensure_dir(dir_path))
  expect_true(dir.exists(dir_path))
})

test_that("build_export_files returns named paths and creates format dirs", {
  root = file.path(tempdir(), paste0("mxport-build-", as.integer(stats::runif(1, 1, 1e6))))
  formats = c("svg", "png")

  files = mxport:::build_export_files(
    filename = "figure-1",
    base_dir = root,
    subfolder = "charts",
    formats = formats
  )

  expect_named(files, formats)
  expect_equal(
    unname(files),
    file.path(root, "charts", formats, paste0("figure-1.", formats))
  )
  expect_true(all(dir.exists(file.path(root, "charts", formats))))
})

test_that("build_export_files validates filename input", {
  expect_error(
    mxport:::build_export_files(
      filename = c("a", "b"),
      base_dir = tempdir(),
      subfolder = "charts"
    )
  )
})

test_that("export_gtsummary_table rejects unsupported input types", {
  expect_error(
    mxport::export_gtsummary_table(
      x = 1,
      filename = "bad-input",
      base_dir = tempdir(),
      export_html = FALSE,
      export_docx = FALSE
    ),
    "must be a gtsummary object or a gt_tbl"
  )
})
