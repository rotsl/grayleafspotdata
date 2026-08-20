# CRAN comments

## Resubmission

This is a resubmission of version 0.1.0. The previous incoming checks
reported three NOTEs. This revision makes the following changes:

- `CITATION.cff` remains in the source repository but is excluded from
  the CRAN source package. Package citations continue to use
  `inst/CITATION`.
- The two Harvard Dataverse entries in `inst/CITATION` use their DOI
  fields without redundant URLs that returned HTTP status 202.

The words reported as possibly misspelled in `DESCRIPTION` are correct:

- `S-BSST3199` is the EMBL-EBI BioStudies accession.
- `EMBL-EBI` and `BioStudies` are repository names.
- `Magnaporthe` is the fungal genus.
- `morphometric` and `petri` are standard scientific terms.

## Test environment

- macOS 27.0 (aarch64-apple-darwin20), R 4.5.1, local
  `R CMD check --as-cran`.

## R CMD check results

0 errors, 0 warnings, 4 notes.

1. The incoming feasibility check reports that this is a new submission.
2. The local check could not verify the current time.
3. The local check could not check `README.md` because pandoc is not
   installed.
4. The local HTML check skipped validation because the installed HTML
   Tidy version is too old.

The clock, pandoc, and HTML Tidy notes are limitations of the local test
environment. The network-backed incoming feasibility check found no
invalid URLs or ORCID IDs.

## Package purpose

This data package provides two data frames that describe files deposited
in EMBL-EBI BioStudies under accession S-BSST3199. It has no runtime
functions and no imports beyond R. The research files remain in
BioStudies and are not bundled with the package.

## Downstream dependencies

None. This is a new package with no reverse dependencies.
