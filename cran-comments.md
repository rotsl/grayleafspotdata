# CRAN comments

## Test environment

- macOS 27.0 (aarch64-apple-darwin20), R 4.5.1, local `R CMD check --as-cran`.

## R CMD check results

0 errors, 0 warnings, 4 notes.

1. `checking for future file timestamps ... NOTE: unable to verify current time`
   Local network/time-source limitation of the test environment, not a package issue.

2. `checking top-level files ... NOTE: Files 'README.md' or 'NEWS.md' cannot be checked without 'pandoc' being installed`
   `pandoc` was not installed in the local test environment.

3. `checking top-level files ... NOTE: Non-standard file/directory found at top level: 'CITATION.cff'` and the matching `checking package subdirectories ... NOTE: Found the following CITATION file in a non-standard place: CITATION.cff`
   Intentional. The package ships both `CITATION.cff` (for GitHub/Zenodo-style tooling) and `inst/CITATION` (the source `citation()` reads). This is documented in README.md.

4. `checking HTML version of manual ... NOTE: Skipping checking HTML validation: 'tidy' doesn't look like recent enough HTML Tidy`
   Local `tidy` binary is older than the check expects.

Notes 1, 2, and 4 are artifacts of the local test environment and are not expected to reproduce on CRAN's own build machines.

## Package purpose

This is a small data-manifest package (two exported data frames, no runtime functions, zero declared Imports/Depends beyond R itself) describing files deposited in a public research data record (EMBL-EBI BioStudies accession S-BSST3199, DOI 10.6019/S-BSST3199). It does not embed the underlying research files; it documents where to find them and their checksums. It is a new, independent submission and does not affect any existing CRAN package.

## Downstream dependencies

None. This is a first submission with no reverse dependencies.
