# IUCNN risk database

## Structure

```
risk_database/
├── input/
│   ├── amphibians/
│   ├── reptiles/
│   ├── chondrichthyans/
│   ├── freshwater/
│   ├── orchids/
│   │   ├── training_occ.csv
│   │   ├── training_labels.csv
│   │   └── prediction_occ.csv
│   ├── birds/
│   ├── mammals/
├── output/
│   ├── test/
│   │   └── orchids/
│   └── releases/
│       ├── releases.csv
│       └── v1/
│           ├── orchids/
│           │   ├── nn-class/
│           │   ├── nn-reg/
│           │   ├── bnn-class/
│           │   ├── predictions_nn-class.csv
│           │   └── predictions_nn-class.rds
│           ├── manifest.csv
│           └── session_info.txt
└── scripts/
    ├── IUCNN_test.R
    └── README.md
```

## Input

Each group needs three files: `training_occ.csv`, `training_labels.csv`, and `prediction_occ.csv`. The script runs every folder in `input/` that has all three. Folders without them are skipped.

The WWF terrestrial ecoregions (`official/`) and the Human Footprint rasters for 1993 and 2009 (`human_footprint/`) are downloaded automatically the first time if they are missing. We use the same sources as IUCNN.

## Running

```
Rscript scripts/IUCNN_pipeline.R 1000            # Test run
Rscript scripts/IUCNN_pipeline.R 1000 release    # New release
```

The first argument is the maximum number of epochs for the BNN (default 1,000,000). The second is the run mode (default `test`).

## Versions

Test runs go to `output/test/` and are overwritten every time. They are not versions and should not be cited.

Releases go to `output/releases/v1`, `v2`, and so on. A new release is only created when the input changes. Each release stores the checksums of all input files (`manifest.csv`) and the R session details (`session_info.txt`). Only groups with changed input are retrained. Unchanged groups are copied from the previous release, so every version is complete. If the ecoregions or the Human Footprint change, all groups are retrained.

`output/releases/releases.csv` lists every release with its date, BNN epochs, IUCNN version, and retrained groups. Please refer to predictions by their version (e.g., v2).

## Website

`index.html` is a static page served with GitHub Pages (Settings > Pages > Deploy from a branch > `main`, `/ (root)`). It reads the release files directly, so there is nothing to build. Pushing a new release updates the site.

The landing page shows the latest release for all three models. Each species has its own view with every model and release, linked as `.../#Genus%20species`, plus links to the IUCN Red List and GBIF. To preview it locally, run `python3 -m http.server` in the repository root and open `http://localhost:8000`.
