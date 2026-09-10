# Site

A Quarto site that reads the prediction CSVs in this repository and publishes them to
GitHub Pages.

## First run

    cd site
    Rscript build.R
    quarto preview

`build.R` reads every CSV under `../<group>/data/processed/` for the groups listed in
`_config.R`, and writes JSON into `site/data/`. The pages read that JSON in the browser.

With no prediction files present, the build writes empty data.

## Choosing which groups appear

Edit the `groups` vector in `_config.R`.

## Expected CSV format

One file per model run, named `modelname_YYYY-MM-DD.csv`, with at least these columns:

    species              Scientific name
    predicted_status     The predicted category
    prob_threatened      Probability of being threatened, between 0 and 1

These are optional and used when present: `taxon_key`, `family`, `order`, `class`.
Supplying `taxon_key` is worth it, since it becomes the species page URL and stays
stable when a name changes.

Column names are set at the top of `_config.R` if changes need to be implemented.

## Publishing

    quarto publish gh-pages

Run `build.R` first, or the site publishes with whatever data was last built. To do both
automatically, add a GitHub Action that runs `Rscript site/build.R` and then
`quarto render site`.
