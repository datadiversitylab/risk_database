library(here)
library(rredlist)
library(rgbif)
library(CoordinateCleaner)

# Groups to build, each gets a folder in input/
groups <- c("orchids")

# Group definitions, one row per taxon, a group can have several rows
# Ranks are class, order, or family, resolution is the grid size in degrees
taxa <- data.frame(
  group = c("amphibians", "reptiles", "chondrichthyans", "birds", "mammals", "orchids"),
  kingdom = c("Animalia", "Animalia", "Animalia", "Animalia", "Animalia", "Plantae"),
  iucn_rank = c("class", "class", "class", "class", "class", "family"),
  iucn_taxon = c("Amphibia", "Reptilia", "Chondrichthyes", "Aves", "Mammalia", "Orchidaceae"),
  gbif_rank = c("class", "class", "class", "class", "class", "family"),
  gbif_taxon = c("Amphibia", "Reptilia", "Chondrichthyes", "Aves", "Mammalia", "Orchidaceae"),
  resolution = c(0.01, 0.01, 0.01, 0.1, 0.01, 0.01)
)

stopifnot(
  all(groups %in% taxa$group),
  all(taxa$iucn_rank %in% c("class", "order", "family")),
  all(taxa$gbif_rank %in% c("class", "order", "family"))
)

# COL XR is GBIF's default taxonomy since rgbif 3.9.0, names and occurrences both use it
stopifnot(packageVersion("rgbif") >= "3.9.0")
checklist_key <- "7ddf754f-d193-4cc9-b351-99906754a03b"

# Credentials are read from .Renviron
stopifnot(nzchar(Sys.getenv(c("IUCN_REDLIST_KEY", "GBIF_USER", "GBIF_PWD", "GBIF_EMAIL"))))

labeled_categories <- c("LC", "NT", "VU", "EN", "CR")
extinct_categories <- c("EX", "EW")
cleaning_tests <- c("capitals", "centroids", "equal", "gbif", "institutions", "outliers", "seas", "zeros")
excluded_basis <- c("FOSSIL_SPECIMEN", "LIVING_SPECIMEN")

red_list_version <- rl_version()
red_list_citation <- format(rl_citation(), style = "text")
script_commit <- tryCatch(
  system2("git", c("-C", here(), "rev-parse", "--short", "HEAD"), stdout = TRUE, stderr = FALSE),
  error = function(e) NA_character_,
  warning = function(w) NA_character_
)

build_group <- function(group) {

  out_dir <- here("input", group)
  cache_dir <- file.path(out_dir, "cache")
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

  definition <- taxa[taxa$group == group, ]
  stopifnot(
    length(unique(definition$kingdom)) == 1,
    length(unique(definition$resolution)) == 1
  )
  kingdom <- definition$kingdom[1]
  resolution <- definition$resolution[1]
  digits <- round(-log10(resolution))

  # GBIF taxa must exist in COL XR before anything is downloaded
  for (i in seq_len(nrow(definition))) {
    hit <- name_backbone(definition$gbif_taxon[i], rank = toupper(definition$gbif_rank[i]),
                         kingdom = kingdom, checklistKey = checklist_key)
    if (is.null(hit$matchType) || hit$matchType != "EXACT") {
      stop(definition$gbif_taxon[i], " is not an exact ", definition$gbif_rank[i], " in COL XR")
    }
  }

  # 1. Latest global Red List assessments, cached per Red List version and group definition
  definition_file <- tempfile(fileext = ".csv")
  write.csv(definition, definition_file, row.names = FALSE)
  definition_md5 <- unname(tools::md5sum(definition_file))
  assessments_file <- file.path(cache_dir, paste0("iucn_", red_list_version, "_", substr(definition_md5, 1, 8), ".rds"))

  if (!file.exists(assessments_file)) {
    ids <- c()
    for (i in seq_len(nrow(definition))) {
      rl_taxon <- switch(definition$iucn_rank[i], class = rl_class, order = rl_order, family = rl_family)
      found <- rl_taxon(definition$iucn_taxon[i], latest = TRUE, scope_code = 1)$assessments

      # Same filters again in R in case the API ignores them
      is_global <- vapply(found$scopes, function(s) "1" %in% s$code, logical(1))
      ids <- c(ids, found$assessment_id[found$latest & is_global])
    }
    saveRDS(rl_assessment_list(unique(ids)), assessments_file)
  }

  details <- Filter(Negate(is.null), readRDS(assessments_file))

  iucn <- data.frame(
    iucn_name = vapply(details, function(a) a$taxon$scientific_name, character(1)),
    category = vapply(details, function(a) a$red_list_category$code, character(1))
  )
  n_assessments <- nrow(iucn)

  # Species only, subspecies and subpopulations have more than two words
  iucn <- iucn[lengths(strsplit(iucn$iucn_name, " ")) == 2, ]

  # 2. Match Red List names to COL XR, only exact matches are kept
  matched <- as.data.frame(name_backbone_checklist(
    data.frame(scientificName = unique(iucn$iucn_name)),
    kingdom = kingdom,
    checklistKey = checklist_key
  ))

  exact <- matched[matched$matchType == "EXACT" & !is.na(matched$speciesKey), ]
  iucn$speciesKey <- exact$speciesKey[match(iucn$iucn_name, exact$verbatim_name)]

  unmatched <- iucn[is.na(iucn$speciesKey), ]
  iucn <- iucn[!is.na(iucn$speciesKey), ]

  # Two Red List names can be synonyms of one accepted species, conflicting categories are dropped
  n_categories <- tapply(iucn$category, iucn$speciesKey, function(x) length(unique(x)))
  conflicts <- names(n_categories)[n_categories > 1]
  conflicting <- iucn[iucn$speciesKey %in% conflicts, ]
  iucn <- iucn[!iucn$speciesKey %in% conflicts & !duplicated(iucn$speciesKey), ]

  # 3. GBIF occurrences, one row per species and grid cell
  taxon_filter <- paste(sprintf("%s = '%s'",
                                ifelse(definition$gbif_rank == "order", '"order"', definition$gbif_rank),
                                definition$gbif_taxon), collapse = " OR ")
  sql <- sprintf(paste(
    "SELECT specieskey, species, ROUND(decimallatitude, %d) AS lat, ROUND(decimallongitude, %d) AS lon, COUNT(*) AS n",
    "FROM occurrence",
    "WHERE kingdom = '%s' AND (%s)",
    "AND specieskey IS NOT NULL",
    "AND decimallatitude IS NOT NULL",
    "AND decimallongitude IS NOT NULL",
    "AND hasgeospatialissues = FALSE",
    "AND occurrencestatus = 'PRESENT'",
    "AND basisofrecord NOT IN (%s)",
    "GROUP BY specieskey, species, lat, lon"
  ), digits, digits, kingdom, taxon_filter, paste0("'", excluded_basis, "'", collapse = ", "))

  # The same query reuses the stored download, delete gbif_download.csv to request fresh data
  download_file <- file.path(out_dir, "gbif_download.csv")
  stored <- if (file.exists(download_file)) read.csv(download_file) else NULL

  if (is.null(stored) || stored$sql != sql) {
    stored <- data.frame(key = as.character(occ_download_sql(sql)), sql = sql)
    write.csv(stored, download_file, row.names = FALSE)
  }

  occ_download_wait(stored$key, status_ping = 60)
  occ <- as.data.frame(occ_download_import(occ_download_get(stored$key, path = cache_dir)))
  meta <- occ_download_meta(stored$key)

  occ <- data.frame(
    speciesKey = as.character(occ$specieskey),
    species = occ$species,
    decimallongitude = occ$lon,
    decimallatitude = occ$lat
  )
  occ <- occ[!is.na(occ$species) & occ$species != "", ]
  n_cells_raw <- nrow(occ)

  # 4. Coordinate cleaning
  occ <- clean_coordinates(
    occ,
    lon = "decimallongitude",
    lat = "decimallatitude",
    species = "species",
    tests = cleaning_tests,
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

  prediction_keys <- unique(prediction_occ$speciesKey)
  n_dd <- sum(prediction_keys %in% iucn$speciesKey[iucn$category == "DD"])

  columns <- c("species", "decimallongitude", "decimallatitude")
  write.csv(training_occ[, columns], file.path(out_dir, "training_occ.csv"), row.names = FALSE)
  write.csv(training_labels, file.path(out_dir, "training_labels.csv"), row.names = FALSE)
  write.csv(prediction_occ[, columns], file.path(out_dir, "prediction_occ.csv"), row.names = FALSE)

  # Names that need a look by hand, kept in the cache because they are Red List data
  write.csv(unmatched, file.path(cache_dir, "iucn_unmatched.csv"), row.names = FALSE)
  write.csv(conflicting, file.path(cache_dir, "iucn_conflicts.csv"), row.names = FALSE)

  # 6. Provenance, copied into each release and shown on the website
  doi <- if (is.null(meta$doi)) NA else meta$doi
  created <- if (is.null(meta$created)) NA else substr(meta$created, 1, 10)

  sources <- data.frame(item = c(
    "assembled", "script_commit", "r_version", "rredlist", "rgbif", "CoordinateCleaner",
    "taxa_iucn", "taxa_gbif", "kingdom",
    "red_list_version", "red_list_citation", "red_list_scope",
    "taxonomy", "taxonomy_checklist_key", "name_matching",
    "gbif_download_key", "gbif_doi", "gbif_citation", "gbif_sql",
    "grid_resolution_degrees", "excluded_basis_of_record", "cleaning_tests",
    "red_list_assessments", "red_list_names_unmatched", "species_conflicting",
    "occurrence_cells_before_cleaning", "occurrence_cells_after_cleaning",
    "training_species", "training_cells", "prediction_species", "prediction_species_dd", "prediction_species_unassessed", "prediction_cells"
  ), value = c(
    format(Sys.time(), "%Y-%m-%d %H:%M %Z"), script_commit, R.version.string,
    as.character(packageVersion("rredlist")), as.character(packageVersion("rgbif")), as.character(packageVersion("CoordinateCleaner")),
    paste(definition$iucn_rank, definition$iucn_taxon, collapse = "; "),
    paste(definition$gbif_rank, definition$gbif_taxon, collapse = "; "), kingdom,
    red_list_version, red_list_citation, "Global, latest assessment per species",
    "Catalogue of Life Extended Release (COL XR) via GBIF", checklist_key, "Exact matches only, conflicting categories dropped",
    stored$key, doi, sprintf("GBIF.org (%s) GBIF Occurrence Download https://doi.org/%s", created, doi), sql,
    resolution, paste(excluded_basis, collapse = "; "), paste(cleaning_tests, collapse = "; "),
    n_assessments, nrow(unmatched), length(conflicts),
    n_cells_raw, nrow(occ),
    nrow(training_labels), nrow(training_occ), length(prediction_keys), n_dd, length(prediction_keys) - n_dd, nrow(prediction_occ)
  ))
  write.csv(sources, file.path(out_dir, "sources.csv"), row.names = FALSE)

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

  invisible(sources)
}

# One failing group does not stop the others
status <- vapply(groups, function(group) {
  message("Building ", group)
  tryCatch({
    build_group(group)
    "built"
  }, error = function(e) {
    message("Failed ", group, ": ", conditionMessage(e))
    paste("failed:", conditionMessage(e))
  })
}, character(1))

print(data.frame(group = names(status), status = unname(status)))
