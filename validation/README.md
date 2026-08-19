# validation/

This directory holds developer-only validation artifacts. It is
excluded from the built source tarball via `.Rbuildignore`. None
of the files here ship to end users.

The directory is populated by `data-raw/validate_biostudies.R`,
which is a developer script that:

- fetches the authoritative BioStudies record S-BSST3199 (study
  metadata, files API listing, `dataset_manifest.csv`,
  `SHA256SUMS.txt`),
- loads the local `.rda` files,
- cross-checks image row counts, filenames, top-level SHA-256
  values, top-level file sizes, and per-image SHA-256 coverage,
- writes a Markdown report to
  `validation/biostudies-validation.md`.

To regenerate the report:

```r
source("data-raw/validate_biostudies.R")
```

The report's overall verdict is either `PASS` or `PARTIAL`. A
`PARTIAL` verdict points to the specific section that needs
attention. Do not publish a new release of the package while the
report shows `PARTIAL` without understanding each item.

If you see a SHA-256 mismatch, treat it as a provenance issue, not
a routine warning. Open both the local and remote values (the
report lists both) and figure out which side changed before doing
anything else.
