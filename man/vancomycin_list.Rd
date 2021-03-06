% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/abx_index.R
\name{vancomycin_list}
\alias{vancomycin_list}
\title{Function to return taxon susceptible or resistant to Vancomycin}
\usage{
vancomycin_list(abundance, lineage)
}
\arguments{
\item{abundance}{A list of relative abundances of bacterial taxons for a single sample}

\item{lineage}{Name of taxonomy lineage for each relative abundance in a sample (e.g. k__Bacteria; p__Bacteroidetes; c__Bacteroidia etc.)}
}
\value{
A dataframe of taxa abundances and whether they are susceptible or resistant to vancomycin
}
\description{
Function to return taxon susceptible or resistant to Vancomycin
}
\examples{
do.call(rbind, apply(abx_test_df, 2, vancomycin_list, row.names(abx_test_df)))

}
