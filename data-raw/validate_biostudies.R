#!/usr/bin/env Rscript
# ----------------------------------------------------------------------------
# validate_biostudies.R
#
# Cross-checks the local manifest against the authoritative BioStudies
# record S-BSST3199. Produces a human-readable report at
# validation/biostudies-validation.md.
#
# Per package policy (see .Rbuildignore), the validation/ directory is
# excluded from the built tarball. The report is a developer artifact.
#
# Run from the package root:
#   Rscript data-raw/validate_biostudies.R
# ----------------------------------------------------------------------------

suppressWarnings({
  library(utils)
})

# --- endpoints ---------------------------------------------------------------

BIOSTUDIES_API <- "https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199"
BIOSTUDIES_FILES_API <- "https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199/files"
DATASET_MANIFEST_URL <- "https://www.ebi.ac.uk/biostudies/files/S-BSST3199/dataset_manifest.csv"
SHA256SUMS_URL <- "https://www.ebi.ac.uk/biostudies/files/S-BSST3199/SHA256SUMS.txt"

STUDY_ACCESSION <- "S-BSST3199"
STUDY_URL <- "https://www.ebi.ac.uk/biostudies/studies/S-BSST3199"

# --- fetch helpers -----------------------------------------------------------

fetch_json <- function(url) {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  jsonlite::fromJSON(readLines(tmp, warn = FALSE, encoding = "UTF-8"))
}

fetch_text <- function(url) {
  tmp <- tempfile()
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  readLines(tmp, encoding = "UTF-8", warn = FALSE)
}

fetch_csv <- function(url) {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  utils::read.csv(tmp, stringsAsFactors = FALSE, encoding = "UTF-8")
}

# --- fetch authoritative state ----------------------------------------------

message("[validate_biostudies] Fetching BioStudies study metadata ...")
bs_study <- fetch_json(BIOSTUDIES_API)
bs_files <- fetch_json(BIOSTUDIES_FILES_API)
remote_dataset_manifest <- fetch_csv(DATASET_MANIFEST_URL)
remote_sha_lines <- fetch_text(SHA256SUMS_URL)

# Parse remote SHA256SUMS.txt into a data frame of (relative_path, sha256).
sha_pairs <- lapply(remote_sha_lines, function(line) {
  line <- trimws(line)
  if (!nzchar(line)) return(NULL)
  m <- regmatches(line, regexec("^([0-9a-f]{64})\\s+(.+)$", line))[[1]]
  if (length(m) != 3L) return(NULL)
  path <- m[3L]
  if (startsWith(path, "./")) path <- sub("^\\./", "", path)
  data.frame(relative_path = path, sha256 = m[2L], stringsAsFactors = FALSE)
})
remote_sha_df <- do.call(rbind, sha_pairs[!vapply(sha_pairs, is.null, logical(1L))])

# --- load local manifest -----------------------------------------------------

message("[validate_biostudies] Loading local manifest from data/ ...")
local_env <- new.env()
load("data/grayleafspot_images.rda", envir = local_env)
load("data/grayleafspot_files.rda",  envir = local_env)
local_images <- local_env$grayleafspot_images
local_files  <- local_env$grayleafspot_files

# --- checks ------------------------------------------------------------------

report_lines <- character()
push <- function(s) report_lines <<- c(report_lines, s)

push("# BioStudies S-BSST3199 Validation Report")
push("")
push(sprintf("- Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")))
push(sprintf("- Study URL: %s", STUDY_URL))
push(sprintf("- Study accession: %s", STUDY_ACCESSION))
push("")

push("## 1. Authoritative metadata sanity")
push("")
get_attr <- function(attrs, name) {
  if (is.null(attrs)) return(NA_character_)
  hits <- vapply(attrs, function(a) identical(a$name, name), logical(1L))
  if (any(hits)) as.character(attrs[[which(hits)[1L]]]$value) else NA_character_
}
push(sprintf("- BioStudies Title attribute: %s", get_attr(bs_study$attributes, "Title")))
push(sprintf("- BioStudies DOI attribute: %s",  get_attr(bs_study$attributes, "DOI")))
push(sprintf("- BioStudies ReleaseDate attribute: %s", get_attr(bs_study$attributes, "ReleaseDate")))
push("")

push("## 2. Local manifest structure")
push("")
push(sprintf("- grayleafspot_images rows: %d", nrow(local_images)))
push(sprintf("- grayleafspot_files rows: %d",  nrow(local_files)))
push(sprintf("- grayleafspot_images columns: %s",
              paste(names(local_images), collapse = ", ")))
push("")

push("## 3. Accession consistency")
push("")
all_accession_ok <- all(local_images$study_accession == STUDY_ACCESSION, na.rm = TRUE)
push(sprintf("- All image rows carry accession %s: %s",
              STUDY_ACCESSION, if (all_accession_ok) "YES" else "NO"))
push("")

push("## 4. Image count vs remote dataset_manifest.csv")
push("")
remote_n_rows <- nrow(remote_dataset_manifest)
local_n_rows <- nrow(local_images)
match_count <- (local_n_rows == remote_n_rows)
push(sprintf("- Remote dataset_manifest.csv image rows: %d", remote_n_rows))
push(sprintf("- Local grayleafspot_images rows:        %d", local_n_rows))
push(sprintf("- Counts match: %s", if (match_count) "YES" else "NO"))
push("")

push("## 5. Filename coverage vs remote dataset_manifest.csv")
push("")
remote_filenames <- sort(unique(remote_dataset_manifest$filename))
local_filenames  <- sort(unique(local_images$filename))
missing_locally  <- setdiff(remote_filenames, local_filenames)
extra_locally    <- setdiff(local_filenames,  remote_filenames)
push(sprintf("- Unique remote filenames: %d", length(remote_filenames)))
push(sprintf("- Unique local filenames:  %d", length(local_filenames)))
push(sprintf("- Present remotely but missing locally: %d", length(missing_locally)))
push(sprintf("- Present locally but missing remotely: %d", length(extra_locally)))
if (length(missing_locally)) {
  push("")
  push("Missing locally:")
  for (f in missing_locally) push(sprintf("  - %s", f))
}
if (length(extra_locally)) {
  push("")
  push("Extra locally:")
  for (f in extra_locally) push(sprintf("  - %s", f))
}
push("")

push("## 6. Top-level file integrity (sha256 vs SHA256SUMS.txt)")
push("")
local_sha <- stats::setNames(local_files$sha256, local_files$relative_path)
remote_sha <- stats::setNames(remote_sha_df$sha256, remote_sha_df$relative_path)
common <- intersect(names(local_sha), names(remote_sha))
mismatches <- character()
for (p in common) {
  if (is.na(local_sha[p]) || is.na(remote_sha[p])) next
  if (!identical(local_sha[p], remote_sha[p])) {
    mismatches <- c(mismatches, p)
  }
}
push(sprintf("- Top-level files in local manifest: %d", length(local_sha)))
push(sprintf("- Top-level files in remote SHA256SUMS.txt: %d", length(remote_sha)))
push(sprintf("- Overlap: %d", length(common)))
push(sprintf("- SHA-256 mismatches: %d", length(mismatches)))
if (length(mismatches)) {
  push("")
  push("Mismatches:")
  for (p in mismatches) {
    push(sprintf("  - %s", p))
    push(sprintf("    local:  %s", local_sha[p]))
    push(sprintf("    remote: %s", remote_sha[p]))
  }
}
push("")

push("## 7. Top-level file sizes vs files API")
push("")
api_size <- stats::setNames(as.numeric(bs_files$items$Size), bs_files$items$Name)
local_file_size <- stats::setNames(local_files$file_size_bytes, local_files$filename)
size_mismatches <- character()
for (nm in names(local_file_size)) {
  if (!nm %in% names(api_size)) next
  if (is.na(local_file_size[nm])) next
  if (!identical(as.numeric(local_file_size[nm]), as.numeric(api_size[nm]))) {
    size_mismatches <- c(size_mismatches, nm)
  }
}
push(sprintf("- Files in API listing: %d", length(api_size)))
push(sprintf("- Files in local top-level manifest: %d", length(local_file_size)))
push(sprintf("- Size mismatches: %d", length(size_mismatches)))
if (length(size_mismatches)) {
  push("")
  push("Size mismatches:")
  for (nm in size_mismatches) {
    push(sprintf("  - %s  (local: %s bytes, API: %s bytes)",
                 nm, local_file_size[nm], api_size[nm]))
  }
}
push("")

push("## 8. Per-image SHA-256 coverage")
push("")
n_with_sha <- sum(!is.na(local_images$sha256))
push(sprintf("- Image rows with SHA-256 populated: %d / %d",
              n_with_sha, nrow(local_images)))
push(sprintf("- Coverage: %.2f%%",
              100 * n_with_sha / max(1L, nrow(local_images))))
if (n_with_sha == 0L) {
  push("")
  push("Per-image SHA-256 not yet populated. To populate, run:")
  push("  Sys.setenv(GRAYLEAFSPOT_DATA_DIR = \"/path/to/local/S-BSST3199\")")
  push("  source(\"data-raw/build_manifest.R\")")
}
push("")

push("## 9. Final status")
push("")
overall_ok <- all_accession_ok &&
  match_count &&
  length(missing_locally) == 0L &&
  length(extra_locally) == 0L &&
  length(mismatches) == 0L &&
  length(size_mismatches) == 0L
push(sprintf("- Overall: %s",
              if (overall_ok) "PASS" else "PARTIAL (see items above)"))
push("")

# --- write report ------------------------------------------------------------

dir.create("validation", showWarnings = FALSE, recursive = TRUE)
out_path <- "validation/biostudies-validation.md"
writeLines(report_lines, out_path)
message("[validate_biostudies] Wrote ", out_path)

invisible(list(
  overall_ok = overall_ok,
  local_images = local_images,
  local_files = local_files,
  remote_dataset_manifest = remote_dataset_manifest,
  remote_sha_df = remote_sha_df
))
