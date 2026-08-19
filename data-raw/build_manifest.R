#!/usr/bin/env Rscript
# ----------------------------------------------------------------------------
# build_manifest.R
#
# Deterministically rebuilds data/grayleafspot_images.rda and
# data/grayleafspot_files.rda from the authoritative BioStudies record
# S-BSST3199, optionally enriched with per-file SHA-256 checksums from
# a local copy of the deposited dataset.
#
# Two input modes:
#   1. Remote-only mode (default). Reads the BioStudies dataset_manifest.csv
#      and SHA256SUMS.txt directly from
#      https://www.ebi.ac.uk/biostudies/files/S-BSST3199/...
#      This populates every column except per-image file_size_bytes and
#      per-image sha256, which remain NA because the BioStudies record
#      does not expose per-image checksums (only top-level zip checksums).
#
#   2. Local-audit mode. If Sys.getenv("GRAYLEAFSPOT_DATA_DIR") points at
#      an existing directory, the script additionally walks the local
#      copy of the deposited dataset, computes per-file SHA-256 with
#      openssl::sha256, joins them onto the manifest, and fills
#      local_manifest_source with the resolved dataset_dir path.
#
# Output:
#   data/grayleafspot_images.rda
#   data/grayleafspot_files.rda
#   inst/extdata/build_summary.json
#
# Run from the package root:
#   Rscript data-raw/build_manifest.R
# ----------------------------------------------------------------------------

suppressWarnings({
  library(utils)   # read.csv, write.csv, download.file
})

# --- constants ---------------------------------------------------------------

STUDY_ACCESSION       <- "S-BSST3199"
STUDY_URL             <- "https://www.ebi.ac.uk/biostudies/studies/S-BSST3199"
DATASET_MANIFEST_URL  <- "https://www.ebi.ac.uk/biostudies/files/S-BSST3199/dataset_manifest.csv"
SHA256SUMS_URL        <- "https://www.ebi.ac.uk/biostudies/files/S-BSST3199/SHA256SUMS.txt"
FILES_API_URL         <- "https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199/files"
FILE_URL_TEMPLATE    <- "https://www.ebi.ac.uk/biostudies/files/S-BSST3199/%s"
RETRIEVAL_DATE        <- as.character(Sys.Date())
PACKAGE_ROOT         <- normalizePath(".", winslash = "/")
DATA_DIR            <- file.path(PACKAGE_ROOT, "data")
EXTDATA_DIR         <- file.path(PACKAGE_ROOT, "inst", "extdata")
dir.create(DATA_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(EXTDATA_DIR, showWarnings = FALSE, recursive = TRUE)

# --- helpers -----------------------------------------------------------------

media_type_for <- function(filename) {
  ext <- tolower(tools::file_ext(filename))
  out <- list(
    jpg = "image/jpeg", jpeg = "image/jpeg", png = "image/png",
    csv = "text/csv",  txt  = "text/plain",
    zip = "application/zip",
    json = "application/json",
    gz  = "application/gzip",
    tar = "application/x-tar"
  )
  if (ext %in% names(out)) out[[ext]] else "application/octet-stream"
}

sha256_file <- function(path) {
  # Uses openssl::sha256(file(path)) when openssl is available, falls back
  # to digest::digest(file = path, algo = "sha256", serialize = FALSE).
  if (requireNamespace("openssl", quietly = TRUE)) {
    return( openssl::sha256(file(path)) )
  }
  if (requireNamespace("digest", quietly = TRUE)) {
    return( digest::digest(file = path, algo = "sha256", serialize = FALSE) )
  }
  stop(
    "Need either the 'openssl' package or the 'digest' package to ",
    "compute SHA-256 checksums. Install one with ",
    "install.packages(c('openssl', 'digest'))."
  )
}

read_remote_csv <- function(url) {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  utils::read.csv(tmp, stringsAsFactors = FALSE, encoding = "UTF-8")
}

read_remote_lines <- function(url) {
  tmp <- tempfile(fileext = ".txt")
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  readLines(tmp, encoding = "UTF-8")
}

# --- remote metadata fetch ----------------------------------------------------

message("[build_manifest] Fetching ", DATASET_MANIFEST_URL)
dataset_manifest <- read_remote_csv(DATASET_MANIFEST_URL)

message("[build_manifest] Fetching ", SHA256SUMS_URL)
sha_lines <- read_remote_lines(SHA256SUMS_URL)
sha_pairs <- lapply(sha_lines, function(line) {
  line <- trimws(line)
  if (!nzchar(line)) return(NULL)
  m <- regmatches(line, regexec("^([0-9a-f]{64})\\s+(.+)$", line))[[1]]
  if (length(m) != 3L) return(NULL)
  path <- m[3L]
  if (startsWith(path, "./")) path <- sub("^\\./", "", path)
  list(path = path, sha256 = m[2L])
})
sha_df <- do.call(rbind, lapply(sha_pairs[!vapply(sha_pairs, is.null, logical(1L))],
                                as.data.frame, stringsAsFactors = FALSE))
if (nrow(sha_df) > 0L) {
  sha_df$path    <- as.character(sha_df$path)
  sha_df$sha256  <- as.character(sha_df$sha256)
}

message("[build_manifest] Fetching ", FILES_API_URL)
files_api <- jsonlite::fromJSON(
  readLines(FILES_API_URL, warn = FALSE, encoding = "UTF-8")
)
files_api_items <- as.data.frame(files_api$items, stringsAsFactors = FALSE)

# --- build images frame ------------------------------------------------------

relative_path_for_image <- function(row) {
  metadata_file <- row[["metadata_file"]]
  if (!nzchar(metadata_file)) return(row[["filename"]])
  directory <- sub("/[^/]+$", "", metadata_file)
  if (!nzchar(directory)) return(row[["filename"]])
  file.path(directory, row[["filename"]])
}

n_image_rows <- nrow(dataset_manifest)
images_rows <- vector("list", n_image_rows)
for (i in seq_len(n_image_rows)) {
  row <- dataset_manifest[i, ]
  filename  <- trimws(row[["filename"]])
  rel_path  <- relative_path_for_image(row)
  images_rows[[i]] <- data.frame(
    file_id             = NA_integer_,  # filled post-sort below
    filename            = filename,
    relative_path       = rel_path,
    extension           = tolower(tools::file_ext(filename)),
    media_type          = media_type_for(filename),
    file_size_bytes     = NA_real_,
    sha256              = NA_character_,
    study_accession     = STUDY_ACCESSION,
    study_repository    = "EMBL-EBI BioStudies",
    study_url           = STUDY_URL,
    biostudies_file_url = NA_character_,
    acquisition_group   = trimws(row[["acquisition_group"]]),
    plate_id            = trimws(row[["plate_id"]]),
    metadata_file       = trimws(row[["metadata_file"]]),
    analysis_directory  = trimws(row[["analysis_directory"]]),
    organism            = "Magnaporthe",
    metadata_source     = sprintf(
      "BioStudies dataset_manifest.csv (%s, retrieved %s)",
      STUDY_ACCESSION, RETRIEVAL_DATE
    ),
    local_manifest_source = NA_character_,
    stringsAsFactors = FALSE
  )
}
grayleafspot_images <- do.call(rbind, images_rows)

# --- optional local enrichment ----------------------------------------------

dataset_dir <- Sys.getenv("GRAYLEAFSPOT_DATA_DIR", "")
if (nzchar(dataset_dir) && dir.exists(dataset_dir)) {
  message("[build_manifest] Local dataset dir detected: ", dataset_dir)
  message("[build_manifest] Walking ", dataset_dir, " recursively ...")
  all_files <- list.files(
    dataset_dir, recursive = TRUE, full.names = TRUE,
    all.files = FALSE, no.. = TRUE
  )
  local_rows <- lapply(all_files, function(abs_path) {
    rel <- sub(
      sprintf("^%s/", gsub("([.|()^{}+*?]|\\[|\\])", "\\\\\\1", dataset_dir)),
      "", abs_path, perl = TRUE
    )
    rel <- gsub("\\\\", "/", rel)  # cross-platform normalization
    data.frame(
      relative_path_local = rel,
      file_size_bytes_local = file.size(abs_path),
      sha256_local = tryCatch(sha256_file(abs_path), error = function(e) NA_character_),
      abs_path = abs_path,
      stringsAsFactors = FALSE
    )
  })
  local_df <- do.call(rbind, local_rows)
  # Match on relative_path (local_rel should equal our published rel_path for
  # images that exist on disk).
  match_idx <- match(grayleafspot_images$relative_path, local_df$relative_path_local)
  grayleafspot_images$file_size_bytes <- ifelse(
    is.na(match_idx), NA_real_, local_df$file_size_bytes_local[match_idx]
  )
  grayleafspot_images$sha256 <- ifelse(
    is.na(match_idx), NA_character_, local_df$sha256_local[match_idx]
  )
  grayleafspot_images$local_manifest_source <- ifelse(
    is.na(match_idx), NA_character_, dataset_dir
  )
  message("[build_manifest] Local enrichment matched ",
          sum(!is.na(match_idx)), " of ", nrow(grayleafspot_images), " rows.")
} else if (nzchar(dataset_dir)) {
  stop(
    "GRAYLEAFSPOT_DATA_DIR is set but does not point at an existing directory: ",
    dataset_dir
  )
} else {
  message("[build_manifest] No local dataset dir set. Building remote-only manifest.")
  message("[build_manifest] To enrich with per-image SHA-256 checksums, run:")
  message("[build_manifest]   Sys.setenv(GRAYLEAFSPOT_DATA_DIR = \"/path/to/S-BSST3199\")")
  message("[build_manifest]   source(\"data-raw/build_manifest.R\")")
}

# --- build files frame (top-level deposited files) ---------------------------

# Maps the canonical in-deposit relative path -> flattened name + description.
# .DS_Store is intentionally skipped (not research content, not served
# by the public files API).
files_meta <- data.frame(
  relative_path = c(
    "README.txt",
    "metadata/dataset_manifest.csv",
    "raw_images.zip",
    "documentation.zip",
    "software/LICENSE-MIT.txt",
    "software/metrics-petri-3.0.0.zip"
  ),
  filename = c(
    "README.txt",
    "dataset_manifest.csv",
    "raw_images.zip",
    "documentation.zip",
    "LICENSE-MIT.txt",
    "metrics-petri-3.0.0.zip"
  ),
  description = c(
    "README.txt",
    "dataset_manifest.csv",
    "Raw Images and Analysis Outputs",
    "Documentation related to the run experiments",
    "Repository License",
    "Source Code"
  ),
  stringsAsFactors = FALSE
)

# Join sha256 from sha_df on relative_path.
files_meta$sha256 <- vapply(
  files_meta$relative_path,
  function(p) {
    hit <- which(sha_df$path == p)
    if (length(hit) == 1L) sha_df$sha256[hit] else NA_character_
  },
  character(1L)
)

# File sizes come from the BioStudies files API; the API uses flattened names.
files_meta$file_size_bytes <- vapply(
  files_meta$filename,
  function(nm) {
    hit <- which(files_api_items$Name == nm)
    if (length(hit) == 1L) as.numeric(files_api_items$Size[hit]) else NA_real_
  },
  numeric(1L)
)

grayleafspot_files <- data.frame(
  file_id             = NA_integer_,  # filled post-sort
  filename            = files_meta$filename,
  relative_path       = files_meta$relative_path,
  extension           = tolower(tools::file_ext(files_meta$filename)),
  media_type          = vapply(files_meta$filename, media_type_for, character(1L)),
  file_size_bytes     = files_meta$file_size_bytes,
  sha256              = files_meta$sha256,
  study_accession     = STUDY_ACCESSION,
  study_url           = STUDY_URL,
  biostudies_file_url = sprintf(FILE_URL_TEMPLATE, files_meta$filename),
  description         = files_meta$description,
  stringsAsFactors = FALSE
)

# --- deterministic sort + persist --------------------------------------------

grayleafspot_images <- grayleafspot_images[
  order(grayleafspot_images$relative_path,
        grayleafspot_images$filename), , drop = FALSE]
grayleafspot_images$file_id <- seq_len(nrow(grayleafspot_images))

grayleafspot_files <- grayleafspot_files[
  order(grayleafspot_files$relative_path,
        grayleafspot_files$filename), , drop = FALSE]
grayleafspot_files$file_id <- seq_len(nrow(grayleafspot_files))

# Sanity checks (mirrors tests/testthat/test-dataset-integrity.R).
stopifnot(all(grayleafspot_images$study_accession == STUDY_ACCESSION))
stopifnot(!any(grepl("^/", grayleafspot_images$relative_path)))
stopifnot(!any(grepl("^[A-Za-z]:[/\\\\]", grayleafspot_images$relative_path)))
stopifnot(!anyNA(grayleafspot_images$filename))
stopifnot(!any(grayleafspot_images$filename == ""))
stopifnot(!anyNA(grayleafspot_files$sha256))
stopifnot(all(grepl("^[0-9a-f]{64}$", grayleafspot_files$sha256)))
stopifnot(!anyDuplicated(grayleafspot_images$relative_path))
stopifnot(!anyDuplicated(grayleafspot_files$sha256))

# Stable save format: xz-compressed rda, version 3.
save(
  grayleafspot_images,
  file = file.path(DATA_DIR, "grayleafspot_images.rda"),
  compress = "xz", version = 3L
)
save(
  grayleafspot_files,
  file = file.path(DATA_DIR, "grayleafspot_files.rda"),
  compress = "xz", version = 3L
)
message("[build_manifest] Wrote data/grayleafspot_images.rda (",
        nrow(grayleafspot_images), " rows)")
message("[build_manifest] Wrote data/grayleafspot_files.rda (",
        nrow(grayleafspot_files), " rows)")

# --- build summary sidecar ---------------------------------------------------

n_sha256_imgs <- sum(!is.na(grayleafspot_images$sha256))
build_summary <- list(
  study_accession             = STUDY_ACCESSION,
  study_url                   = STUDY_URL,
  retrieval_date              = RETRIEVAL_DATE,
  n_image_rows                = nrow(grayleafspot_images),
  n_acquisition_groups        = length(unique(grayleafspot_images$acquisition_group)),
  n_plates                    = length(unique(grayleafspot_images$plate_id)),
  n_top_level_files           = nrow(grayleafspot_files),
  total_top_level_bytes       = as.numeric(sum(grayleafspot_files$file_size_bytes, na.rm = TRUE)),
  sha256_coverage_images      = n_sha256_imgs / nrow(grayleafspot_images),
  sha256_coverage_top_level   = 1.0,
  duplicate_filenames_in_images        = anyDuplicated(grayleafspot_images$filename) > 0L,
  duplicate_relative_paths_in_images  = anyDuplicated(grayleafspot_images$relative_path) > 0L,
  duplicate_sha256_in_top_level        = anyDuplicated(grayleafspot_files$sha256) > 0L
)
jsonlite::write_json(build_summary,
                     file.path(EXTDATA_DIR, "build_summary.json"),
                     auto_unbox = TRUE, pretty = TRUE)
message("[build_manifest] Wrote inst/extdata/build_summary.json")

invisible(list(
  grayleafspot_images = grayleafspot_images,
  grayleafspot_files  = grayleafspot_files
))
