library(here)
library(rredlist)
library(rgbif)
library(CoordinateCleaner)

# Usage: Rscript scripts/build_input.R orchids family Orchidaceae
args <- commandArgs(trailingOnly = TRUE)

group <- if (length(args) > 0) args[1] else "orchids"
rank <- if (length(args) > 1) args[2] else "family"
taxon <- if (length(args) > 2) args[3] else "Orchidaceae"

stopifnot(rank %in% c("class", "order", "family"))

# COL XR is GBIF's default taxonomy since rgbif 3.9.0, names and occurrences both use it
stopifnot(packageVersion("rgbif") >= "3.9.0")
checklist_key <- "7ddf754f-d193-4cc9-b351-99906754a03b"

# Credentials are read from .Renviron: IUCN_REDLIST_KEY, GBIF_USER, GBIF_PWD, GBIF_EMAIL
stopifnot(nzchar(Sys.getenv(c("IUCN_REDLIST_KEY", "GBIF_USER", "GBIF_PWD", "GBIF_EMAIL"))))

out_dir <- here("input", group)
cache_dir <- file.path(out_dir, "cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

labeled_categories <- c("LC", "NT", "VU", "EN", "CR")
extinct_categories <- c("EX", "EW")

# 1. Latest global Red List assessments, cached because the API allows about two calls per second
assessments_file <- file.path(cache_dir, "iucn_assessments.rds")

if (!file.exists(assessments_file)) {
  rl_taxon <- switch(rank, class = rl_class, order = rl_order, family = rl_family)
  found <- rl_taxon(taxon, latest = TRUE, scope_code = 1)$assessments

  # Same filters again in R in case the API ignores them
  is_global <- vapply(found$scopes, function(s) "1" %in% s$code, logical(1))
  found <- found[found$latest & is_global, ]

  details <- rl_assessment_list(unique(found$assessment_id))
  saveRDS(details, assessments_file)
}

details <- Filter(Negate(is.null), readRDS(assessments_file))

iucn <- data.frame(
  iucn_name = vapply(details, function(a) a$taxon$scientific_name, character(1)),
  category = vapply(details, function(a) a$red_list_category$code, character(1))
)

# Species only, subspecies and subpopulations have more than two words
iucn <- iucn[lengths(strsplit(iucn$iucn_name, " ")) == 2, ]

# 2. Match Red List names to COL XR, only exact matches are kept
match_args <- list(name_data = data.frame(scientificName = unique(iucn$iucn_name)), checklistKey = checklist_key)
match_args[[rank]] <- taxon
matched <- as.data.frame(do.call(name_backbone_checklist, match_args))

exact <- matched[matched$matchType == "EXACT" & !is.na(matched$speciesKey), ]
iucn$speciesKey <- exact$speciesKey[match(iucn$iucn_name, exact$verbatim_name)]

unmatched <- iucn[is.na(iucn$speciesKey), ]
iucn <- iucn[!is.na(iucn$speciesKey), ]

# Two Red List names can be synonyms of one accepted species, conflicting categories are dropped
n_categories <- tapply(iucn$category, iucn$speciesKey, function(x) length(unique(x)))
conflicts <- names(n_categories)[n_categories > 1]
iucn <- iucn[!iucn$speciesKey %in% conflicts & !duplicated(iucn$speciesKey), ]

# 3. GBIF occurrences, one row per species and 0.01 degree cell, the key is kept so the same download is reused
key_file <- file.path(out_dir, "gbif_download_key.txt")

if (!file.exists(key_file)) {
  taxon_column <- if (rank == "order") '"order"' else rank
  sql <- sprintf(paste(
    "SELECT specieskey, species, ROUND(decimallatitude, 2) AS lat, ROUND(decimallongitude, 2) AS lon, COUNT(*) AS n",
    "FROM occurrence",
    "WHERE %s = '%s'",
    "AND specieskey IS NOT NULL",
    "AND decimallatitude IS NOT NULL",
    "AND decimallongitude IS NOT NULL",
    "AND hasgeospatialissues = FALSE",
    "AND occurrencestatus = 'PRESENT'",
    "AND basisofrecord NOT IN ('FOSSIL_SPECIMEN', 'LIVING_SPECIMEN')",
    "GROUP BY specieskey, species, lat, lon"
  ), taxon_column, taxon)
  writeLines(as.character(occ_download_sql(sql)), key_file)
}

gbif_key <- readLines(key_file)
occ_download_wait(gbif_key, status_ping = 60)
occ <- as.data.frame(occ_download_import(occ_download_get(gbif_key, path = cache_dir)))

occ <- data.frame(
  speciesKey = as.character(occ$specieskey),
  species = occ$species,
  decimallongitude = occ$lon,
  decimallatitude = occ$lat
)
occ <- occ[!is.na(occ$species) & occ$species != "", ]

# 4. Coordinate cleaning
occ <- clean_coordinates(
  occ,
  lon = "decimallongitude",
  lat = "decimallatitude",
  species = "species",
  value = "clean"
)

# 5. Split into training and prediction
labeled <- iucn[iucn$category %in% labeled_categories, ]
excluded <- c(labeled$speciesKey, iucn$speciesKey[iucn$category %in% extinct_categories], conflicts)

training_occ <- occ[occ$speciesKey %in% labeled$speciesKey, ]

# Assessed species whose names did not match are kept out of prediction too
prediction_occ <- occ[!occ$speciesKey %in% excluded & !occ$species %in% unmatched$iucn_name, ]

training_labels <- data.frame(
  species = training_occ$species[match(labeled$speciesKey, training_occ$speciesKey)],
  labels = labeled$category
)
training_labels <- training_labels[!is.na(training_labels$species), ]

columns <- c("species", "decimallongitude", "decimallatitude")
write.csv(training_occ[, columns], file.path(out_dir, "training_occ.csv"), row.names = FALSE)
write.csv(training_labels, file.path(out_dir, "training_labels.csv"), row.names = FALSE)
write.csv(prediction_occ[, columns], file.path(out_dir, "prediction_occ.csv"), row.names = FALSE)

# Names that need a look by hand, kept in the cache because they are Red List data
write.csv(unmatched, file.path(cache_dir, "iucn_unmatched.csv"), row.names = FALSE)
write.csv(iucn[iucn$speciesKey %in% conflicts, ], file.path(cache_dir, "iucn_conflicts.csv"), row.names = FALSE)

# 6. Provenance
sources <- data.frame(
  item = c("built", "group", "rank", "taxon", "checklist_key", "red_list_version", "gbif_download_key", "gbif_doi",
           "training_species", "prediction_species", "unmatched_iucn_names", "conflicting_species",
           "rredlist", "rgbif", "CoordinateCleaner"),
  value = c(format(Sys.Date()), group, rank, taxon, checklist_key, rl_version(), gbif_key, occ_download_meta(gbif_key)$doi,
            nrow(training_labels), length(unique(prediction_occ$speciesKey)), nrow(unmatched), length(conflicts),
            as.character(packageVersion("rredlist")), as.character(packageVersion("rgbif")),
            as.character(packageVersion("CoordinateCleaner")))
)
write.csv(sources, file.path(out_dir, "sources.csv"), row.names = FALSE)

print(sources)

# Check against the orchid example data in IUCNN
if (group == "orchids") {
  old <- new.env()
  utils::data("training_labels", package = "IUCNN", envir = old)
  shared <- intersect(old$training_labels$species, training_labels$species)
  same <- old$training_labels$labels[match(shared, old$training_labels$species)] ==
    training_labels$labels[match(shared, training_labels$species)]
  message(length(shared), " of ", nrow(old$training_labels), " IUCNN example species are in the new labels, ",
          round(100 * mean(same), 1), "% with the same category")
}
