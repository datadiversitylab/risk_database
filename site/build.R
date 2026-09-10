# Build the JSON the site reads in the browser
# Run from the site folder with: Rscript build.R
# Safe to run before any predictions exist, the pages handle empty data

source("_config.R")
library(jsonlite)

out <- "data"
dir.create(file.path(out, "species"), recursive = TRUE, showWarnings = FALSE)

# A stable, URL safe identifier
# Uses the taxon key when the CSV has one, otherwise a slug of the species name
make_id <- function(species, taxon_key = NULL) {
  if (!is.null(taxon_key) && !is.na(taxon_key) && nzchar(as.character(taxon_key))) {
    return(as.character(taxon_key))
  }
  tolower(gsub("[^A-Za-z0-9]+", "-", species))
}

# Split modelname_date.csv into its two parts
parse_filename <- function(f) {
  base <- sub("\\.csv$", "", basename(f))
  parts <- regmatches(base, regexec("^(.*)_([0-9]{4}-[0-9]{2}-[0-9]{2})$", base))[[1]]
  if (length(parts) == 3) {
    list(model = parts[2], date = parts[3])
  } else {
    list(model = base, date = NA_character_)
  }
}

# Read every prediction file for one group
read_group <- function(group) {
  dir <- file.path("..", group, predictions_subdir)
  if (!dir.exists(dir)) return(NULL)
  files <- list.files(dir, pattern = "\\.csv$", full.names = TRUE)
  if (length(files) == 0) return(NULL)

  rows <- lapply(files, function(f) {
    d <- read.csv(f, stringsAsFactors = FALSE)
    if (!all(c(species_col, status_col, prob_col) %in% names(d))) {
      warning("Skipping ", basename(f), ", missing required columns")
      return(NULL)
    }
    meta <- parse_filename(f)
    data.frame(
      group = group,
      species = d[[species_col]],
      status = d[[status_col]],
      prob = suppressWarnings(as.numeric(d[[prob_col]])),
      model = meta$model,
      date = meta$date,
      taxon_key = if (taxon_key_col %in% names(d)) as.character(d[[taxon_key_col]]) else NA_character_,
      family = if (family_col %in% names(d)) d[[family_col]] else NA_character_,
      order = if (order_col %in% names(d)) d[[order_col]] else NA_character_,
      class = if (class_col %in% names(d)) d[[class_col]] else NA_character_,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

all_rows <- do.call(rbind, lapply(groups, read_group))

# Empty build, the site still renders and says so
if (is.null(all_rows) || nrow(all_rows) == 0) {
  message("No prediction files found, writing empty data")
  write_json(list(), file.path(out, "index.json"), auto_unbox = TRUE)
  write_json(list(), file.path(out, "groups.json"), auto_unbox = TRUE)
  write_json(list(version = release_version, date = release_date, n_species = 0,
                  n_groups = 0, n_models = 0),
             file.path(out, "release.json"), auto_unbox = TRUE)
  quit(save = "no")
}

all_rows$id <- mapply(make_id, all_rows$species, all_rows$taxon_key, USE.NAMES = FALSE)

# One record per species, carrying every prediction made for it
species_ids <- unique(all_rows$id)
index <- vector("list", length(species_ids))

for (i in seq_along(species_ids)) {
  sid <- species_ids[i]
  d <- all_rows[all_rows$id == sid, ]
  probs <- d$prob[is.finite(d$prob)]

  spread <- if (length(probs) > 1) sd(probs) else 0
  consensus <- if (length(probs) > 0) median(probs) else NA_real_
  modal <- names(sort(table(d$status), decreasing = TRUE))[1]

  record <- list(
    id = sid,
    species = d$species[1],
    group = d$group[1],
    taxonomy = list(class = d$class[1], order = d$order[1], family = d$family[1]),
    consensus_prob = round(consensus, 3),
    consensus_status = modal,
    spread = round(spread, 3),
    low_confidence = spread > disagreement_cutoff,
    n_models = nrow(d),
    predictions = lapply(seq_len(nrow(d)), function(k) {
      list(model = d$model[k], date = d$date[k], status = d$status[k],
           prob = round(d$prob[k], 3))
    })
  )

  write_json(record, file.path(out, "species", paste0(sid, ".json")), auto_unbox = TRUE)

  index[[i]] <- list(id = sid, species = d$species[1], group = d$group[1],
                     family = d$family[1], status = modal,
                     prob = round(consensus, 3), low = spread > disagreement_cutoff,
                     n = nrow(d))
}

write_json(index, file.path(out, "index.json"), auto_unbox = TRUE)

# Per group summary
group_summary <- lapply(unique(all_rows$group), function(g) {
  d <- all_rows[all_rows$group == g, ]
  list(group = g, n_species = length(unique(d$id)),
       models = sort(unique(d$model)), dates = sort(unique(na.omit(d$date))))
})
write_json(group_summary, file.path(out, "groups.json"), auto_unbox = TRUE)

write_json(list(version = release_version, date = release_date,
                n_species = length(species_ids), n_groups = length(unique(all_rows$group)),
                n_models = length(unique(all_rows$model))),
           file.path(out, "release.json"), auto_unbox = TRUE)

message("Wrote ", length(species_ids), " species across ",
        length(unique(all_rows$group)), " groups")
