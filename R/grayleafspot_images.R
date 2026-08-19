#' Image manifest for the S-BSST3199 Magnaporthe colony dataset
#'
#' A machine-readable manifest describing the 49 source image files
#' associated with the research dataset deposited in EMBL-EBI
#' BioStudies under accession S-BSST3199. The study is titled
#' "Time-series Magnaporthe colony images from twelve petri dishes and
#' morphometric analysis results generated using metrics-petri 3.0.0".
#'
#' The original image files are not bundled with this R package. They
#' remain available from the authoritative BioStudies record at
#' \url{https://www.ebi.ac.uk/biostudies/studies/S-BSST3199}.
#'
#' This manifest can be used on its own, or together with
#' image-analysis software such as \code{grayleafspotr}. No R-level
#' dependency on \code{grayleafspotr} is introduced.
#'
#' @format A data frame with 49 rows and one row per deposited source
#' image. Columns:
#' \describe{
#'   \item{file_id}{Integer row identifier, 1 to 49.}
#'   \item{filename}{Original image filename as listed in
#'     \code{dataset_manifest.csv} (e.g.
#'     \code{20260204_P001_30JAN_WT_PCBM_CTRL_d05_TOP.JPG}).}
#'   \item{relative_path}{Inferred path of the image inside the
#'     BioStudies deposit (e.g.
#'     \code{raw_images/30jan/20260204_P001_30JAN_WT_PCBM_CTRL_d05_TOP.JPG}).
#'     Derived from the directory pattern of the related
#'     \code{metadata_file} value. Never an absolute path.}
#'   \item{extension}{File extension, lowercased (e.g. \code{.jpg}).}
#'   \item{media_type}{Declared media type (e.g. \code{image/jpeg}).}
#'   \item{file_size_bytes}{File size in bytes. \code{NA} when not
#'     available from the deposited metadata. The 49 individual
#'     images are packaged inside \code{raw_images.zip}; per-image
#'     sizes are not exposed separately by the BioStudies record.}
#'   \item{sha256}{SHA-256 checksum as lowercase hexadecimal.
#'     \code{NA} for individual image rows because the BioStudies
#'     \code{SHA256SUMS.txt} only publishes top-level deposit checksums.
#'     Populate this column by re-running
#'     \code{data-raw/build_manifest.R} against a local copy of the
#'     dataset directory.}
#'   \item{study_accession}{BioStudies accession, \code{S-BSST3199}.}
#'   \item{study_repository}{Hosting repository name,
#'     \code{EMBL-EBI BioStudies}.}
#'   \item{study_url}{Canonical BioStudies study URL.}
#'   \item{biostudies_file_url}{Direct BioStudies file URL when one can
#'     be established. \code{NA} for individual image rows because the
#'     images are inside \code{raw_images.zip}, not directly retrievable
#'     per-image.}
#'   \item{acquisition_group}{Acquisition group identifier as listed
#'     in \code{dataset_manifest.csv}: \code{30jan} or \code{6feb}.}
#'   \item{plate_id}{Plate identifier as listed in
#'     \code{dataset_manifest.csv}: \code{P001} for the 30 January
#'     group, \code{P02} to \code{P12} for the 6 February group.}
#'   \item{metadata_file}{Path of the plate-level
#'     \code{image_metadata.csv} file as listed in
#'     \code{dataset_manifest.csv}.}
#'   \item{analysis_directory}{Path of the plate-level analysis output
#'     directory as listed in \code{dataset_manifest.csv}.}
#'   \item{organism}{Study-level organism. The BioStudies record
#'     identifies the colonies as \emph{Magnaporthe}; propagated to all
#'     rows.}
#'   \item{metadata_source}{Free-text provenance note describing where
#'     the per-row values were obtained from.}
#'   \item{local_manifest_source}{Identifier of the local source
#'     directory used by \code{data-raw/build_manifest.R} when
#'     per-image checksums were computed. \code{NA} in the published
#'     build because the build was generated from the remote BioStudies
#'     record only.}
#' }
#'
#' @source EMBL-EBI BioStudies accession S-BSST3199, file
#' \code{dataset_manifest.csv}. Retrieved 2026-08-18 from
#' \url{https://www.ebi.ac.uk/biostudies/files/S-BSST3199/dataset_manifest.csv}.
#' Study landing page:
#' \url{https://www.ebi.ac.uk/biostudies/studies/S-BSST3199}.
#'
#' @references Related research outputs include:
#' \itemize{
#'   \item EMBL-EBI BioStudies accession S-BSST3199, DOI
#'     \doi{10.6019/S-BSST3199}.
#'   \item Harvard Dataverse record DOI \doi{10.7910/DVN/SR2HBR}
#'     (metrics-petri 3.0.0 software archive).
#'   \item Harvard Dataverse record DOI \doi{10.7910/DVN/7BJLIQ}
#'     (U-Net validation dataset for fungal colony segmentation).
#' }
#'
#' @keywords datasets
"grayleafspot_images"

#' Top-level deposited file manifest for S-BSST3199
#'
#' A machine-readable manifest of the six top-level research files
#' deposited directly in the BioStudies record S-BSST3199 (excluding
#' the macOS \code{.DS_Store} artifact). These are the files listed
#' in the deposited \code{SHA256SUMS.txt} checksum file. SHA-256
#' values and file sizes are populated because BioStudies exposes them
#' at this level.
#'
#' Use this dataset to verify the integrity of the deposited archive
#' without downloading every byte of \code{raw_images.zip}, or to
#' locate each top-level file's canonical BioStudies URL.
#'
#' @format A data frame with 6 rows and one row per deposited
#' top-level file. Columns:
#' \describe{
#'   \item{file_id}{Integer row identifier, 1 to 6.}
#'   \item{filename}{Flattened filename as served by the BioStudies
#'     file URL endpoint (e.g. \code{README.txt},
#'     \code{metrics-petri-3.0.0.zip}).}
#'   \item{relative_path}{Path inside the BioStudies deposit as
#'     recorded in \code{SHA256SUMS.txt} (e.g.
#'     \code{metadata/dataset_manifest.csv},
#'     \code{software/metrics-petri-3.0.0.zip}).}
#'   \item{extension}{File extension, lowercased.}
#'   \item{media_type}{Declared media type.}
#'   \item{file_size_bytes}{File size in bytes, from the BioStudies
#'     files API.}
#'   \item{sha256}{SHA-256 checksum from the deposited
#'     \code{SHA256SUMS.txt}, lowercase hexadecimal.}
#'   \item{study_accession}{BioStudies accession, \code{S-BSST3199}.}
#'   \item{study_url}{Canonical BioStudies study URL.}
#'   \item{biostudies_file_url}{Direct BioStudies file URL.}
#'   \item{description}{Description of the file as listed by the
#'     BioStudies files API.}
#' }
#'
#' @source EMBL-EBI BioStudies accession S-BSST3199. Files API listing
#' retrieved 2026-08-18 from
#' \url{https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199/files}.
#' SHA-256 values retrieved 2026-08-18 from
#' \url{https://www.ebi.ac.uk/biostudies/files/S-BSST3199/SHA256SUMS.txt}.
#'
#' @references EMBL-EBI BioStudies accession S-BSST3199, DOI
#' \doi{10.6019/S-BSST3199}.
#'
#' @keywords datasets
"grayleafspot_files"
