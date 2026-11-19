# IUCNN risk database

## Groups

    amphibians
    reptiles
    chondrichthyans
    freshwater
    orchids
    birds
    mammals

## Structure

```
risk_database/
├── input/
│   ├── orchids/
│   │   ├── training_occ.csv
│   │   ├── training_labels.csv     # Local only, not in git
│   │   ├── prediction_occ.csv
│   │   ├── gbif_download.csv
│   │   ├── sources.csv
│   │   └── cache/                  # Local only, not in git
│   ├── amphibians/
│   ├── ...
│   ├── official/
│   └── human_footprint/
├── output/
│   ├── test/
│   └── releases/
│       ├── releases.csv
│       └── v1/
│           ├── orchids/
│           │   ├── nn-class/
│           │   ├── nn-reg/
│           │   ├── bnn-class/
│           │   ├── predictions_nn-class.csv
│           │   ├── predictions_nn-class.rds
│           │   └── sources.csv
│           ├── manifest.csv
│           └── session_info.txt
├── scripts/
│   ├── build_input.R
│   └── IUCNN_pipeline.R
├── index.html
└── README.md
```

## Input

`scripts/build_input.R` builds `training_occ.csv`, `training_labels.csv`, and `prediction_occ.csv` for each group and creates its folder in `input/` if needed. The groups to build are set at the top of the script:

```r
groups <- c("orchids", "amphibians")
```

Each group is defined in the `taxa` table below it, with one row per taxon. Ranks can be `class`, `order`, or `family`. The Red List and GBIF columns are separate because the two taxonomies do not always use the same names. `resolution` is the grid size in degrees for the occurrence records. To add a group, add its rows to `taxa` and its name to `groups`.

```
Rscript scripts/build_input.R
```

Labels are the latest global IUCN Red List assessments (LC to CR). Names are matched to the Catalogue of Life Extended Release (COL XR), the taxonomy GBIF uses, and only exact matches are kept. Occurrences come from one GBIF download per group, aggregated to one record per species and grid cell, and cleaned with CoordinateCleaner. Assessed species are used for training. Data Deficient and unassessed species are predicted.

Each build writes `sources.csv` with the date, script commit, package versions, Red List version and citation, GBIF download DOI and query, filters, and species counts. It is copied into every release and shown on the website.

The script needs an IUCN Red List API key and a GBIF account in `~/.Renviron` (`IUCN_REDLIST_KEY`, `GBIF_USER`, `GBIF_PWD`, `GBIF_EMAIL`). `training_labels.csv` and `cache/` are not in git because the Red List terms do not allow sharing its data. Anyone with an API key can rebuild them. `gbif_download.csv` stores the GBIF download, so a rebuild uses the same records. Delete it to request fresh data.

`input/orchids_IUCNN/` holds the orchid example data from the IUCNN package. It is used to test the pipeline and is written from the package if the folder is missing. It is not built by `build_input.R`. Internal groups like this one are listed in `internal_groups` in `IUCNN_pipeline.R`. They are released like the other groups, but the website hides them unless "Show IUCNN example data" is checked.

The WWF terrestrial ecoregions (`official/`) and the Human Footprint rasters for 1993 and 2009 (`human_footprint/`) are downloaded automatically the first time if they are missing. We use the same sources as IUCNN.

## Running

```
Rscript scripts/IUCNN_pipeline.R 1000            # Test run
Rscript scripts/IUCNN_pipeline.R 1000 release    # New release
```

The first argument is the maximum number of epochs for the BNN (default 1,000,000). The second is the run mode (default `test`). The script runs every folder in `input/` that has the three input files.

## Versions

Test runs go to `output/test/` and are overwritten every time. They are not versions and should not be cited.

Releases go to `output/releases/v1`, `v2`, and so on. A new release is only created when the input changes. Each release stores the checksums of all input files (`manifest.csv`) and the R session details (`session_info.txt`). Only groups with changed input are retrained. Unchanged groups are copied from the previous release, so every version is complete. If the ecoregions or the Human Footprint change, all groups are retrained.

`output/releases/releases.csv` lists every release with its date, BNN epochs, IUCNN version, and retrained groups. Please refer to predictions by their version (e.g., v2).

## Website

`index.html` is a static page served with GitHub Pages (Settings > Pages > Deploy from a branch > `main`, `/ (root)`). It reads the release files directly, so there is nothing to build. Pushing a new release updates the site. The empty `.nojekyll` file tells GitHub to serve the files as they are.

The landing page shows the latest release for all three models and where the data for each group came from. Each species has its own view with every model and release, linked as `.../#Genus%20species`, plus links to the IUCN Red List and GBIF. To preview it locally, run `python3 -m http.server` in the repository root and open `http://localhost:8000`.
