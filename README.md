# diffusion
dwi pipelines and tools

## Participant lists

Scripts reading participant codes use a **local** `participants.txt`: one pseudocode per line, without headings. Blank lines and lines beginning with `#` are ignored. These files are Git-ignored; do not commit participant pseudocodes.

Example (replace placeholders with your own IDs in local file):

```text
SUBJECT_CODE_A
SUBJECT_CODE_B
```

- `connectomics/generate_connectome.sh [participants.txt]`: processes every ID in list.
- `misc/dti_alps.sh [participants.txt]`: processes every ID in list (session 1).
- `preprocessing/custom_fba_pipeline/LongitudinalPopulationTemplate.sh`: STEP 1 selects template-building subset from `participants.txt`, or path in `PARTICIPANTS_FILE` environment variable. STEP 0 separately reads `Allparticipants_Session3.txt` for full-cohort data transfer; those lists are intentionally distinct.
- Other preprocessing scripts accept individual participant IDs as command-line arguments rather than embedding them in source.

**Cluster portability:** Scripts marked `HARD-CODED MYRIAD PATH` or `HARD-CODED STORAGE PATHS` still contain project-specific paths. Replace paths before running on another system. Comments flag these paths; cluster-specific paths have not been changed. In particular, longitudinal FBA script represents historical multi-step workflow and needs workflow validation before unattended execution.
