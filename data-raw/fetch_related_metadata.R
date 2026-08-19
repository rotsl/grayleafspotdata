#!/usr/bin/env Rscript
# ----------------------------------------------------------------------------
# fetch_related_metadata.R
#
# Retrieves authoritative metadata for the three persistent records
# referenced by this package and writes them to
# inst/extdata/related_works.json. Re-run this before any formal
# release so the JSON sidecar reflects the latest upstream metadata.
#
# Records retrieved:
#   1. EMBL-EBI BioStudies accession S-BSST3199
#        endpoint: https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199
#        endpoint (files): https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199/files
#   2. Harvard Dataverse DOI 10.7910/DVN/SR2HBR
#        endpoint: https://dataverse.harvard.edu/api/datasets/:persistentId?persistentId=doi:10.7910/DVN/SR2HBR
#   3. Harvard Dataverse DOI 10.7910/DVN/7BJLIQ
#        endpoint: https://dataverse.harvard.edu/api/datasets/:persistentId?persistentId=doi:10.7910/DVN/7BJLIQ
#
# Run from the package root:
#   Rscript data-raw/fetch_related_metadata.R
# ----------------------------------------------------------------------------

suppressWarnings({
  library(utils)
})

# --- endpoints ---------------------------------------------------------------

BIOSTUDIES_API <- "https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199"
BIOSTUDIES_FILES_API <- "https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199/files"
BIOSTUDIES_STUDY_URL <- "https://www.ebi.ac.uk/biostudies/studies/S-BSST3199"
DATAVERSE_ENDPOINT <- function(doi) {
  sprintf("https://dataverse.harvard.edu/api/datasets/:persistentId?persistentId=doi:%s", doi)
}
DATAVERSE_LANDING <- function(doi) {
  sprintf("https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:%s", doi)
}
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L) b else a

# --- fetch helpers -----------------------------------------------------------

fetch_json <- function(url) {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp), add = TRUE)
  utils::download.file(url, tmp, mode = "wb", quiet = TRUE)
  txt <- readLines(tmp, warn = FALSE, encoding = "UTF-8")
  jsonlite::fromJSON(txt)
}

# --- BioStudies ---------------------------------------------------------------

message("[fetch_related_metadata] Fetching BioStudies S-BSST3199 ...")
bs_json  <- fetch_json(BIOSTUDIES_API)
bs_files <- fetch_json(BIOSTUDIES_FILES_API)

get_attr <- function(attrs, name) {
  if (is.null(attrs)) return(NA_character_)
  hits <- vapply(attrs, function(a) identical(a$name, name), logical(1L))
  if (any(hits)) as.character(attrs[[which(hits)[1L]]]$value) else NA_character_
}

bs_record <- list(
  identifier        = "S-BSST3199",
  identifier_type   = "BioStudies accession",
  repository        = "EMBL-EBI BioStudies",
  doi               = get_attr(bs_json$attributes, "DOI"),
  title             = get_attr(bs_json$attributes, "Title"),
  description       = get_attr(bs_json$section$attributes, "Description"),
  release_date      = get_attr(bs_json$attributes, "ReleaseDate"),
  template          = get_attr(bs_json$attributes, "Template"),
  publication_date  = get_attr(bs_json$attributes, "ReleaseDate"),
  version           = NA_character_,
  resource_type     = "biological image dataset with derived analysis outputs",
  authors           = "Rohan R (Norwich Biosciences Institutes, ORCID 0009-0005-9225-1775)",
  canonical_url     = BIOSTUDIES_STUDY_URL,
  relationship      = "canonical source dataset",
  retrieved_at      = as.character(Sys.Date()),
  notes             = sprintf("Top-level deposited files: %d", length(bs_files$items))
)

# --- Dataverse ----------------------------------------------------------------

dataverse_dois <- c("10.7910/DVN/SR2HBR", "10.7910/DVN/7BJLIQ")
dataverse_records <- lapply(dataverse_dois, function(doi) {
  message("[fetch_related_metadata] Fetching Dataverse ", doi, " ...")
  js <- fetch_json(DATAVERSE_ENDPOINT(doi))
  v  <- js$data$latestVersion
  mb <- v$metadataBlocks$citation$fields

  field <- function(name) {
    hit <- which(vapply(mb, function(x) identical(x$typeName, name), logical(1L)))
    if (length(hit) != 1L) return(NULL)
    mb[[hit]]$value
  }

  title_v       <- field("title")
  subtitle_v    <- field("subtitle")
  authors_v     <- field("author")
  descriptions  <- field("dsDescription")
  license_name  <- if ("license" %in% names(v)) v$license$name else NA_character_

  authors_str <- if (is.list(authors_v)) {
    paste(vapply(authors_v, function(a) a$authorName$value, character(1L)),
          collapse = "; ")
  } else NA_character_

  description_str <- if (is.list(descriptions)) {
    paste(vapply(descriptions, function(d) d$dsDescriptionValue$value, character(1L)),
          collapse = "  ")
  } else NA_character_

  files_df <- NULL
  if (!is.null(v$files) && length(v$files) > 0L) {
    files_df <- do.call(rbind, lapply(v$files, function(f) data.frame(
      filename       = f$dataFile$filename,
      size_bytes     = as.numeric(f$dataFile$filesize),
      checksum_value = f$dataFile$checksum$value,
      checksum_type  = f$dataFile$checksum$type,
      stringsAsFactors = FALSE
    )))
  }

  resource_type <- if (doi == "10.7910/DVN/SR2HBR") {
    "software archive (metrics-petri 3.0.0)"
  } else if (doi == "10.7910/DVN/7BJLIQ") {
    "validation dataset for U-Net segmentation (605 training images)"
  } else {
    "dataset"
  }

  relationship <- if (doi == "10.7910/DVN/SR2HBR") {
    "archives the metrics-petri 3.0.0 software used to generate the S-BSST3199 analysis outputs"
  } else if (doi == "10.7910/DVN/7BJLIQ") {
    "validation dataset for the metrics-petri U-Net segmentation model"
  } else {
    "related research output"
  }

  list(
    identifier       = doi,
    identifier_type  = "DOI",
    repository       = "Harvard Dataverse",
    title            = if (is.character(title_v)) title_v else NA_character_,
    subtitle         = if (is.character(subtitle_v)) subtitle_v else NA_character_,
    description      = description_str,
    authors          = authors_str,
    publication_date = js$data$publicationDate %||% NA_character_,
    version          = sprintf("v%s.%s", v$versionNumber, v$versionMinorNumber),
    license          = license_name,
    resource_type    = resource_type,
    canonical_url    = DATAVERSE_LANDING(doi),
    relationship     = relationship,
    retrieved_at     = as.character(Sys.Date()),
    files            = files_df
  )
})

# --- write related_works.json ------------------------------------------------

related_works <- list(
  records      = c(list(bs_record), dataverse_records),
  retrieved_at = as.character(Sys.Date()),
  retrieved_by = "data-raw/fetch_related_metadata.R"
)
out_path <- "inst/extdata/related_works.json"
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
jsonlite::write_json(related_works, out_path,
                     auto_unbox = TRUE, pretty = TRUE, flatten = TRUE)
message("[fetch_related_metadata] Wrote ", out_path)

# --- write dataset_metadata.json --------------------------------------------

ds_meta <- list(
  primary_dataset = list(
    repository            = "EMBL-EBI BioStudies",
    accession             = "S-BSST3199",
    doi                   = bs_record$doi,
    url                   = bs_record$canonical_url,
    title                 = bs_record$title,
    release_date          = bs_record$release_date,
    organism              = "Magnaporthe",
    n_source_images       = 49L,
    n_plates              = 12L,
    n_acquisition_groups  = 2L
  ),
  compatible_software = list(
    list(
      name         = "grayleafspotr",
      relationship = "compatible analysis software (no R-level dependency)",
      url          = "https://rotsl.r-universe.dev/builds"
    )
  ),
  related_works = lapply(related_works$records, function(r) {
    list(
      identifier       = r$identifier,
      identifier_type  = r$identifier_type,
      repository       = r$repository,
      title            = r$title,
      canonical_url    = r$canonical_url,
      relationship     = r$relationship,
      doi              = r$doi %||% NA_character_
    )
  }),
  retrieved_at = as.character(Sys.Date())
)
out_meta <- "inst/extdata/dataset_metadata.json"
jsonlite::write_json(ds_meta, out_meta,
                     auto_unbox = TRUE, pretty = TRUE, flatten = TRUE)
message("[fetch_related_metadata] Wrote ", out_meta)

invisible(related_works)
