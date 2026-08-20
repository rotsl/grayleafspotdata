# grayleafspotdata

A machine-readable manifest for the BioStudies record **S-BSST3199**,
the time-series *Magnaporthe* colony image dataset deposited at
EMBL-EBI. The package is a small data catalogue: it ships one
data frame describing what is in S-BSST3199 and where each file
lives, but it does **not** ship the 49 source images themselves.

## Overview

This is a stand-alone R data package. It is not a fork of, and does
not depend on, the `grayleafspotr` analysis software. The two
packages can be used together, but no R-level dependency exists in
either direction. The relationship is documentation-only.

The BioStudies record S-BSST3199 contains:

- 49 original petri-dish images of *Magnaporthe* colonies from 12 plates
- 12 plate-level `image_metadata.csv` files
- 12 extracted analysis output directories produced by `metrics-petri` 3.0.0
- The `metrics-petri` 3.0.0 source archive (archived separately at Harvard Dataverse, DOI 10.7910/DVN/SR2HBR)

Two acquisition groups are present. The 30 January group has 5
images of plate P001. The 6 February group has 44 images across
plates P002 through P012, four per plate. Total: 49 source images.

## Primary dataset

| Field | Value |
|---|---|
| Repository | EMBL-EBI BioStudies |
| Accession | S-BSST3199 |
| DOI | 10.6019/S-BSST3199 |
| Title | Time-series *Magnaporthe* colony images from twelve petri dishes and morphometric analysis results generated using metrics-petri 3.0.0 |
| Release date | 2026-07-09 |
| Author / depositor | Rohan R, Norwich Biosciences Institutes (ORCID 0009-0005-9225-1775) |
| Canonical URL | https://www.ebi.ac.uk/biostudies/studies/S-BSST3199 |

## What this package contains

- `grayleafspot_images`: a data frame with 49 rows, one per
  source image. Columns include `filename`,
  `relative_path`, `acquisition_group`, `plate_id`,
  `metadata_file`, `analysis_directory`, `study_accession`,
  `study_url`, and provenance notes.
- `grayleafspot_files`: a data frame with 6 rows, one per
  top-level deposited file in S-BSST3199. Each row carries a
  SHA-256 checksum (from the deposited `SHA256SUMS.txt`), a file
  size (from the BioStudies files API), and a direct BioStudies
  file URL.
- `inst/extdata/related_works.json`: machine-readable metadata
  for the three persistent records linked from this package.
- `inst/extdata/dataset_metadata.json`: a small JSON sidecar
  summarising the primary dataset and compatible software.
- `inst/extdata/build_summary.json`: a small JSON report of the
  last manifest generation run (row counts, coverage, duplicates).
- `inst/CITATION`: an R CITATION file distinguishing four
  separately-citable resources.
- `CITATION.cff`: a CFF 1.2.0 citation file for repository hosting
  services. The CRAN source package excludes this file because R uses
  `inst/CITATION` for package citations.
- `data-raw/build_manifest.R`, `data-raw/fetch_related_metadata.R`,
  `data-raw/validate_biostudies.R`: developer scripts for
  regenerating the `.rda` files and the JSON sidecars from
  authoritative sources.

## What this package does not contain

The 49 source images. The package does not embed
`raw_images.zip` (≈ 146 MB), does not embed
`metrics-petri-3.0.0.zip` (≈ 24 MB), and does not embed the
individual `image_metadata.csv` files. The original files remain
hosted by BioStudies. If you need a copy, fetch them from the
canonical record:

```
https://www.ebi.ac.uk/biostudies/studies/S-BSST3199
```

The package also does not depend on `grayleafspotr`. Users may
install `grayleafspotr` separately if they want to run analysis
workflows on the downloaded images. No `Depends`, `Imports`,
`Suggests`, `Remotes`, or `LinkingTo` field references it.

## Data access

The manifest is installed when you install this package. The images
themselves live at BioStudies. To download them, use either the
BioStudies web interface or the documented file URL pattern:

```
https://www.ebi.ac.uk/biostudies/files/S-BSST3199/<flattened_filename>
```

For example, the top-level `dataset_manifest.csv` is reachable at:

```
https://www.ebi.ac.uk/biostudies/files/S-BSST3199/dataset_manifest.csv
```

The 49 individual source images are packaged inside
`raw_images.zip`, so they do not have per-image direct URLs in the
current BioStudies layout. To get one, download and extract
`raw_images.zip`.

## Dataset object

Two exported datasets are available after the package loads:

- `grayleafspot_images`: 49 rows, 18 columns.
- `grayleafspot_files`: 6 rows, 11 columns.

Column definitions and provenance notes for each are in the roxygen
documentation (`?grayleafspot_images`, `?grayleafspot_files`).

## Example

```r
library(grayleafspotdata)

data("grayleafspot_images")
data("grayleafspot_files")

head(grayleafspot_images)
nrow(grayleafspot_images)
# 49

unique(grayleafspot_images$study_accession)
# "S-BSST3199"

table(grayleafspot_images$acquisition_group, grayleafspot_images$plate_id)

# Files with verified SHA-256 (the six top-level deposited files)
grayleafspot_files[, c("filename", "file_size_bytes", "sha256")]
```

If you also install `grayleafspotr` separately, the manifest can
guide file discovery for downstream analysis. No code in this
package calls `grayleafspotr`.

## Integrity and checksums

Each row in `grayleafspot_files` carries a SHA-256 value transcribed
directly from the deposited `SHA256SUMS.txt`. They are the only
checksums the BioStudies record publishes at this level.

Per-image SHA-256 values in `grayleafspot_images` are `NA` in the
published build, because the BioStudies record only checksums the
top-level `raw_images.zip` rather than its contents. To populate
per-image checksums, point `data-raw/build_manifest.R` at a local
copy of the dataset:

```r
Sys.setenv(GRAYLEAFSPOT_DATA_DIR = "/path/to/local/S-BSST3199")
source("data-raw/build_manifest.R")
```

The script will compute SHA-256 with `openssl::sha256()` (falling
back to `digest::digest(..., algo = "sha256")`) and join them onto
the manifest. No personal absolute paths are stored in the
published `.rda`. The `local_manifest_source` column records which
directory was used during regeneration; it is `NA` in the
remote-only build.

## Compatible analysis software

This data package is independent of `grayleafspotr`. The manifest
and underlying research files may be used as inputs to workflows
based on `grayleafspotr`, including builds distributed through the
relevant R-universe repositories. No dependency between this data
package and `grayleafspotr` is imposed.

Reference: <https://rotsl.r-universe.dev/builds>

If there are two separately displayed builds or sources for
`grayleafspotr` (for example, the Bioconductor-staged build at
`BiocStaging/grayleafspotr`), those are software distribution
references. They are not separate copies of the research dataset.

## Related research outputs

| Resource | Persistent identifier | Role |
|---|---|---|
| EMBL-EBI BioStudies | S-BSST3199 (DOI 10.6019/S-BSST3199) | Canonical deposited study; biological images, metadata, derived analysis outputs |
| Harvard Dataverse | DOI 10.7910/DVN/SR2HBR | metrics-petri 3.0.0 software archive |
| Harvard Dataverse | DOI 10.7910/DVN/7BJLIQ | U-Net validation dataset (605 training images) |

Each row is a distinct citable resource with its own licence,
author list, and publication date. S-BSST3199 is the canonical
record for the biological images and their derived outputs. The two
Dataverse records are related but separate: SR2HBR archives the
analysis software, and 7BJLIQ archives the U-Net model trained on
605 images.

## Citation

If you use this R manifest package, cite the package itself. If you
use the underlying biological images or analysis outputs, cite
S-BSST3199 according to the BioStudies record. If your analysis
relies on the archived software or the U-Net validation dataset,
cite the corresponding Harvard Dataverse DOI as well. Do not
merge these into a single false citation.

Citation details are in `inst/CITATION` (R `citEntry` format). The
repository root also contains `CITATION.cff` (CFF 1.2.0) for repository
hosting services, but that file is not part of the CRAN source package.

```r
library(grayleafspotdata)
citation("grayleafspotdata")
```

## Data provenance

The manifest is generated by `data-raw/build_manifest.R` from the
authoritative BioStudies record. Inputs to the build:

- `https://www.ebi.ac.uk/biostudies/files/S-BSST3199/dataset_manifest.csv` (49 image rows)
- `https://www.ebi.ac.uk/biostudies/files/S-BSST3199/SHA256SUMS.txt` (6 top-level checksums)
- `https://www.ebi.ac.uk/biostudies/api/v1/studies/S-BSST3199/files` (top-level file sizes)

Each row's `metadata_source` column records where its values came
from. The build summary at `inst/extdata/build_summary.json` records
the build date, row counts, and integrity flags.

Source-data provenance (the BioStudies record itself) is distinct
from R-package provenance (this repository). The first says where
the biological data came from. The second says how the manifest was
assembled.

## Reproducibility

The manifest regenerates deterministically. `build_manifest.R` sorts
rows by `relative_path` then `filename` before saving, so two runs
against the same inputs produce byte-identical `.rda` files (modulo
the `.rda` compression wrapper, which is itself deterministic).

To rebuild from scratch:

```r
Sys.setenv(GRAYLEAFSPOT_DATA_DIR = "/path/to/local/S-BSST3199")
source("data-raw/fetch_related_metadata.R")  # refresh JSON sidecars
source("data-raw/build_manifest.R")          # refresh .rda files
source("data-raw/validate_biostudies.R")     # write validation report
```

To re-run package checks:

```r
devtools::document()
devtools::test()
devtools::check()
```

## License

The R package source, the manifest-generation scripts, and the
machine-readable metadata files in this repository are licensed
under the MIT license. See `LICENSE` and `LICENSE.note`.

This does not change the licensing terms of the underlying
research data in BioStudies S-BSST3199, or of the related Harvard
Dataverse records. Those records are licensed independently and
remain governed by their own deposit terms (both Dataverse records
are MIT-licensed; the BioStudies record is governed by its own
deposit terms).

## Contributing / corrections

Corrections to the manifest are welcome. If a row is wrong, the
fix is to regenerate the manifest with the corrected input, not to
edit the `.rda` file by hand. Open an issue at
<https://github.com/rotsl/grayleafspotdata/issues> describing what
is wrong and how to reproduce it.

Changes that affect either `grayleafspotr` package are out of
scope here. Those packages are not modified by, or as a consequence
of, work on this repository.
