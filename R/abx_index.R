#' Function to calculate antibiotics index for vancomycin
#'
#' @param df A dataframe of samples as columns and bacterial taxons as rows. Labeling of taxons in rows should follow Greengenes annotations and be separated by double underscores (e.g. k__Bacteria;p__Bacteroidetes)
#' @param abx Antibiotics of interest to calculate index
#'
#' @return The calculated antibiotics index for each sample
#' @export
#'
#' @examples
#' \dontrun{
#' vancomycin_index(test_df)
#' }
#'
vancomycin_index <- function(df, delim = "; ", weighted = T, plot = F, plot_order = F) {
  abx <- "vancomycin"
  taxa <- split_levels(row.names(df), delim)
  suscept_vector <- get_suscept_vector(taxa, abx)

  abx_idx_vactor <- lapply(as.data.frame(df), calc_index, suscept_vector, weighted)

  if(plot) {
    abx_idx_plot(abx_idx_vactor, plot_order)
  }
  else {
    return(abx_idx_vactor)
  }
}

#have to use pull(unite(d_adf, col = "new", sep = "; ")) to generate the names and then do assignment
#test on vancomycin dataset
##make visializations functions?
#make a plot

nitroimidazoles_index <- function(df, delim = "; ", weighted = T, plot = F, plot_order = F) {
  abx <- "nitroimidazole"
  taxa <- split_levels(row.names(df), delim)
  suscept_vector <- get_suscept_vector(taxa, abx)

  abx_idx_vactor <- lapply(as.data.frame(df), calc_index, suscept_vector, weighted)

  if(plot) {
    abx_idx_plot(abx_idx_vactor, plot_order)
  }
  else {
    return(abx_idx_vactor)
  }
}

fluoroquinolone_index <- function(df, delim = "; ", weighted = T, plot = F, plot_order = F) {
  abx <- "fluoroquinolone"
  taxa <- split_levels(row.names(df), delim)
  suscept_vector <- get_suscept_vector(taxa, abx)

  abx_idx_vactor <- lapply(as.data.frame(df), calc_index, suscept_vector, weighted)

  if(plot) {
    abx_idx_plot(abx_idx_vactor, plot_order)
  }
  else {
    return(abx_idx_vactor)
  }
}

polymyxin_n_aztreonam_index <- function(df, delim = "; ", weighted = T, plot = F, plot_order = F) {
  abx <- "polymyxin_n_aztreonam"
  taxa <- split_levels(row.names(df), delim)
  suscept_vector <- get_suscept_vector(taxa, abx)

  abx_idx_vactor <- lapply(as.data.frame(df), calc_index, suscept_vector, weighted)

  if(plot) {
    abx_idx_plot(abx_idx_vactor, plot_order)
  }
  else {
    return(abx_idx_vactor)
  }
}

gram_pos_index <- function(df, delim = "; ", weighted = T, plot = F, plot_order = F) {
  abx <- "glycopeptides_macrolides_oxazolidinones_lincosamides_lipopeptides_amoxicillin"
  taxa <- split_levels(row.names(df), delim)
  suscept_vector <- get_suscept_vector(taxa, abx)

  abx_idx_vactor <- lapply(as.data.frame(df), calc_index, suscept_vector, weighted)

  if(plot) {
    abx_idx_plot(abx_idx_vactor, plot_order)
  }
  else {
    return(abx_idx_vactor)
  }
}

##split taxa name using row names
split_levels <- function(row_names, delim = delim) {

  taxa_df <- as.data.frame(do.call(rbind, strsplit(row_names, split = delim)))
  colnames(taxa_df) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
  ##if species is missiing or NA, keep as blank
  taxa_df$Species <- ifelse(!(taxa_df$Species %in% c("s__", "", "s__NA", "NA") | is.na(taxa_df$Species)), as.character(taxa_df$Species), "")
  ##add genus name if missing in species column
  taxa_df$Species <- ifelse((mapply(grepl, taxa_df$Genus, taxa_df$Species) | taxa_df$Species == ""), as.character(taxa_df$Species), paste(as.character(taxa_df$Genus), as.character(taxa_df$Species)))

  simplified_taxa_df <- as.data.frame(lapply(taxa_df, function(x) {gsub("[kpcofgs]__|NA", "", x)}))
  return(simplified_taxa_df)

}

get_suscept_vector <- function(row_names, abx) {

  #merge taxa levels by row with the LTP dataframe and count rows that were NA; TODO: combine both sapply functions
  not_merged <- function(single_row_name) {
    is_missing <- FALSE
    each_taxa_row <- Filter(function(x) all(x!=""), single_row_name)
    filteredsubset <- merge(each_taxa_row, LTP, by = colnames(each_taxa_row), all.x = TRUE)
    if(is.na(any(filteredsubset[, abx]))) {
      is_missing <- TRUE
    }

    return(is_missing)
  }

  missing_vector <- sapply(1:nrow(row_names), function(row_num){not_merged(row_names[row_num,])})

  #merge taxa levels by row with the LTP dataframe and calculate weighted antibiotics index for that row
  merge_LTP <- function(single_row_name) {
    each_taxa_row <- Filter(function(x) all(x!=""), single_row_name)
    filteredsubset <- merge(each_taxa_row, LTP, by = colnames(each_taxa_row), all.x = TRUE)

    if(is.na(any(filteredsubset[, abx]))) {
      filteredsubset[, abx] <- 0
    }

    return(sum(filteredsubset[, abx])/nrow(filteredsubset))
  }

  #apply merge function with taxonomic row
  suscept_vector <- sapply(1:nrow(row_names), function(row_num){merge_LTP(row_names[row_num,])})

  print("These taxa were treated as resistant because they were not found in LTP database")
  print(row_names[missing_vector, ])

  return(suscept_vector)

}

calc_index <- function(sample_vector, suscept_vector, weighted) {

  TF_suscept_vector <- suscept_vector > 0.5
  sum_suscept_taxa <- sum(sample_vector[TF_suscept_vector]*suscept_vector[TF_suscept_vector])

  if(!weighted) {
    sum_suscept_taxa <- sum(sample_vector[TF_suscept_vector])
  }

  return(log10(sum_suscept_taxa/(1-sum_suscept_taxa)))
}

abx_idx_plot <- function(abx_vector, order = F) {
  ##infinite values are replaced to 10
  show_name <- TRUE

  plotting_vector <- gsub(-Inf, -10, abx_vector)
  plotting_vector <- as.numeric(gsub(Inf, 10, plotting_vector))

  if(order) {
    plotting_vector <- sort(plotting_vector, decreasing = TRUE)
  }

  vector_cols <- ifelse(plotting_vector > 0, "green", "red")

  if(length(plotting_vector) > 50) {
    show_name <- FALSE
  }

  barplot(unlist(plotting_vector), xlab = "Samples", ylab = "Antibiotics index", names.arg = show_name, col = vector_cols, border = NA, space = 0)

}


##tetracycline isn't implemented yet
tetracycline <- function(taxa) { ##excluding resistance through acquired mobile elements, only trying to get intrinsic resistance
  ##All bacteria are theoretically susceptible to tetracycline except these bacteria for which some resistant clinical strains were isolated
  resistance <- c("g__Acinetobacter s__baumannii",
                      "g__Bacteroides s__fragilis",
                      "g__Escherichia s__coli",
                      "g__Enterobacter",
                      "g__Enterococcus s__faecalis",
                      "g__Klebsiella pneumoniae", ##Klebsiella generally susceptible
                      "g__Pseudomonas s__aeruginosa",
                      "g__Proteus s__mirabilis",
                      "g__Staphylococcus s__aureus",
                      "g__Stenotrophomonas s__maltophilia",
                      "g__Serratia s__marcescens", ##Intrinsic bacterial multidrug efflux pumps: doi:10.1101/cshperspect.a025387, Table 2
                      "g__Salmonella s__typhimurium", "g__Campylobacter s__jejuni", ##DOI: 10.1038/nrmicro1464
                      "g__Bacteroides") #80% of Bacteroides are resistant to tetracyclines due to mobile elements: DOI: 10.1128/mBio.00569-13

  tetra_resist <- !grepl(paste0(resistance, collapse = "|"), taxa)

  return(tetra_resist)

  ##Include distribution of tet protection genes on mobile elements? http://faculty.washington.edu/marilynr/, https://doi.org/10.1016/j.femsle.2005.02.034
  ##Can use the Clinical and Laboratory Standards Institute (CLSI) guideline for assessing resistance?
}

##review paper basing drug class: https://doi.org/10.1016/j.bcp.2017.01.003

#TODO: Import library that can extend the full taxonomic levels in row names