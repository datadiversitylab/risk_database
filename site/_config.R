# Site configuration
# Edit this file, then run build.R

# Group folders to include, relative to the repository root
# Comment out a line to drop that group from the site
groups <- c(
  "01-amphibians",
  "02-reptiles",
  "03-chondrichthyans",
  "04-freshwater",
  "05-orchids",
  "06-birds",
  "07-mammals"
)

# Where prediction CSVs live inside each group folder
predictions_subdir <- "data/processed"

# Column names expected in every prediction CSV
# species_col is the only one you may need to change
species_col <- "binomial"
status_col <- "predicted_status"
prob_col <- "prob_threatened"

# Optional columns, used when present and ignored when absent
taxon_key_col <- "taxon_key"
family_col <- "family"
order_col <- "order"
class_col <- "class"

# Release information, shown on every page
release_version <- "v0.1"
release_date <- format(Sys.Date())

# A species is flagged as low confidence when its predictions disagree by more
# than this much, measured as the standard deviation of prob_threatened
# across models
disagreement_cutoff <- 0.15
