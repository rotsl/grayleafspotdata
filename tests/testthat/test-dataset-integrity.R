test_that("grayleafspot_images is available", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_true(exists("grayleafspot_images"))
})

test_that("grayleafspot_images is a data frame", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_s3_class(grayleafspot_images, "data.frame")
})

test_that("image manifest has 49 rows (matches authoritative deposit count)", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_equal(nrow(grayleafspot_images), 49L)
})

test_that("required image columns exist", {
  data("grayleafspot_images", package = "grayleafspotdata")
  required <- c(
    "file_id",
    "filename",
    "relative_path",
    "extension",
    "media_type",
    "file_size_bytes",
    "sha256",
    "study_accession",
    "study_repository",
    "study_url",
    "biostudies_file_url",
    "acquisition_group",
    "plate_id",
    "metadata_file",
    "analysis_directory",
    "organism",
    "metadata_source",
    "local_manifest_source"
  )
  expect_true(all(required %in% names(grayleafspot_images)))
})

test_that("study_accession is uniformly S-BSST3199", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_true(
    all(grayleafspot_images$study_accession == "S-BSST3199")
  )
})

test_that("study_url is uniformly the canonical BioStudies URL", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_true(
    all(
      grayleafspot_images$study_url ==
        "https://www.ebi.ac.uk/biostudies/studies/S-BSST3199"
    )
  )
})

test_that("relative_path values are relative, not absolute", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_false(any(grepl("^/", grayleafspot_images$relative_path)))
  expect_false(any(grepl("^[A-Za-z]:[/\\\\]", grayleafspot_images$relative_path)))
})

test_that("filenames are populated", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_false(anyNA(grayleafspot_images$filename))
  expect_false(any(grayleafspot_images$filename == ""))
})

test_that("file_id is a positive integer sequence 1..n", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_type(grayleafspot_images$file_id, "double")
  expect_true(all(grayleafspot_images$file_id == seq_len(nrow(grayleafspot_images))))
})

test_that("extension values are lowercased", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_true(all(tolower(grayleafspot_images$extension) == grayleafspot_images$extension))
})

test_that("acquisition_group is one of 30jan or 6feb", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_true(all(
    grayleafspot_images$acquisition_group %in% c("30jan", "6feb")
  ))
})

test_that("plate counts match the authoritative deposit (P001 + P02..P12)", {
  data("grayleafspot_images", package = "grayleafspotdata")
  plates <- unique(grayleafspot_images$plate_id)
  expect_setequal(
    plates,
    c("P001", "P02", "P03", "P04", "P05", "P06",
      "P07", "P08", "P09", "P10", "P11", "P12")
  )
})

test_that("organism is Magnaporthe for all rows", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_true(all(grayleafspot_images$organism == "Magnaporthe"))
})

test_that("relative_path values are unique", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_equal(anyDuplicated(grayleafspot_images$relative_path), 0L)
})

test_that("filename values are unique", {
  data("grayleafspot_images", package = "grayleafspotdata")
  expect_equal(anyDuplicated(grayleafspot_images$filename), 0L)
})

test_that("sha256 values, when present, are lowercase hex 64 chars", {
  data("grayleafspot_images", package = "grayleafspotdata")
  vals <- na.omit(grayleafspot_images$sha256)
  if (length(vals) > 0L) {
    expect_true(all(grepl("^[0-9a-f]{64}$", vals)))
  }
})

# ---- grayleafspot_files ----

test_that("grayleafspot_files is available", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_true(exists("grayleafspot_files"))
})

test_that("grayleafspot_files is a data frame", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_s3_class(grayleafspot_files, "data.frame")
})

test_that("file manifest has 6 top-level rows", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_equal(nrow(grayleafspot_files), 6L)
})

test_that("required file columns exist", {
  data("grayleafspot_files", package = "grayleafspotdata")
  required <- c(
    "file_id",
    "filename",
    "relative_path",
    "extension",
    "media_type",
    "file_size_bytes",
    "sha256",
    "study_accession",
    "study_url",
    "biostudies_file_url",
    "description"
  )
  expect_true(all(required %in% names(grayleafspot_files)))
})

test_that("all top-level rows carry a SHA-256", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_false(anyNA(grayleafspot_files$sha256))
  expect_true(all(grepl("^[0-9a-f]{64}$", grayleafspot_files$sha256)))
})

test_that("all top-level rows carry a file size", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_false(anyNA(grayleafspot_files$file_size_bytes))
})

test_that("top-level rows carry S-BSST3199 and the canonical URL", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_true(all(grayleafspot_files$study_accession == "S-BSST3199"))
  expect_true(all(
    grayleafspot_files$study_url == "https://www.ebi.ac.uk/biostudies/studies/S-BSST3199"
  ))
})

test_that("biostudies_file_url values follow the documented template", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_true(all(grepl(
    "^https://www\\.ebi\\.ac\\.uk/biostudies/files/S-BSST3199/.+$",
    grayleafspot_files$biostudies_file_url
  )))
})

test_that("file_id is a positive integer sequence 1..n", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_type(grayleafspot_files$file_id, "double")
  expect_true(all(grayleafspot_files$file_id == seq_len(nrow(grayleafspot_files))))
})

test_that("top-level sha256 values are unique", {
  data("grayleafspot_files", package = "grayleafspotdata")
  expect_equal(anyDuplicated(grayleafspot_files$sha256), 0L)
})

test_that("raw_images.zip is the largest top-level file", {
  data("grayleafspot_files", package = "grayleafspotdata")
  largest <- grayleafspot_files[
    which.max(grayleafspot_files$file_size_bytes),
  ]
  expect_equal(largest$filename, "raw_images.zip")
  expect_true(largest$file_size_bytes > 1e8)
})

# ---- cross-dataset sanity ----

test_that("both datasets load independently and do not depend on network", {
  e <- new.env()
  data("grayleafspot_images", package = "grayleafspotdata", envir = e)
  data("grayleafspot_files",  package = "grayleafspotdata", envir = e)
  expect_true(exists("grayleafspot_images", envir = e))
  expect_true(exists("grayleafspot_files",  envir = e))
})

test_that("no programmatic dependency on grayleafspotr is introduced", {
  # Sanity check that the data package has not accidentally introduced
  # a programmatic dependency on grayleafspotr. The compatibility
  # relationship must remain documentation-only.
  pd <- packageDescription("grayleafspotdata")
  deps_fields <- c("Depends", "Imports", "Suggests", "Remotes", "LinkingTo")
  for (field in deps_fields) {
    if (field %in% names(pd)) {
      expect_false(
        grepl("grayleafspotr", pd[[field]], fixed = TRUE),
        info = sprintf("Field %s must not reference grayleafspotr; got: %s",
                       field, pd[[field]])
      )
    }
  }
})
