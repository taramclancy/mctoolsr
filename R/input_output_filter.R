# mctoolsr

###################################
# LOADING/FILTER SAMPLE FUNCTIONS #
###################################

#' @title Load a taxa table for use with mctoolsr
#' @description Load in a taxa table (aka. an OTU table) and a corresponding 
#'  mapping file with metadata values. The samples in the loaded taxa table 
#'  and mapping file will be in the same order and only samples in both will 
#'  be loaded. The function can optionally filter samples of a specific type 
#'  based on the mapping file. This can also be done later via the filter_data() 
#'  function.
#' @param tab_fp Taxa table filepath.
#' @param map_fp Metadata mapping filepath.
#' @param filter_cat The map_fp header string for the factor you would like 
#'  to use to filter samples.
#' @param filter_vals The values within the filter category (vector or single 
#'  value) you would like to use to remove samples from the imported data.
#' @param keep_vals Alternatively, keep only samples represented by these 
#'  values.
#' @return A list variable with (1) the loaded taxa table, and (2) the loaded 
#'  mapping file.
#' @examples 
#' \dontrun{
#' load_taxa_table("filepath_to_OTU_table.txt", "filepath_to_mapping_file.txt",
#'   "sample_type", filter_vals = "blank")
#' }
load_taxa_table = function(tab_fp, map_fp, filter_cat, filter_vals, keep_vals){
  # load data
  if(tools::file_ext(tab_fp) == 'biom'){
    data_b = biom::read_biom(tab_fp)
    data = as.data.frame(as.matrix(biom::biom_data(data_b)))
    data_taxonomy = mctoolsr:::.compile_taxonomy(data_b)
  }
  else if(tools::file_ext(tab_fp) == 'txt'){
    if(readChar(tab_fp, nchars = 4) == "#OTU"){
      data = read.table(tab_fp, sep='\t', comment.char='', header=T, 
                        check.names=F, row.names=1)
    } else {
      data = read.table(tab_fp, sep='\t', skip=1, comment.char='', header=T, 
                        check.names=F, row.names=1)
    }
    if(names(data)[ncol(data)] == 'taxonomy'){
      data_taxonomy = .parse_taxonomy(data$taxonomy)
      row.names(data_taxonomy) = row.names(data)
      data$taxonomy = NULL
    }
  }
  else stop('Input file must be either biom (.biom) or tab-delimited (.txt) format.')
  map = read.table(map_fp, sep = '\t', comment.char = '', header = T, 
                   check.names = F, row.names = 1)
  if(class(map) != 'data.frame') warning('Mapping file should have more than one metadata column.')
  # optionally, subset data
    # cant subset if trying to filter out certain values and keep certain values
    # use one or the other
  if(!missing(filter_cat)){
    map.f = .filt_map(map, filter_cat, filter_vals, keep_vals)
  } else map.f = map
  # match up data from dissimilarity matrix with mapping file
  mctoolsr:::.match_data_components(data, map.f, data_taxonomy)
}

#' @title Load a dissimilarity matrix for use with mctoolsr
#' @description Load in a dissimilarity matrix and a corresponding metadata
#'  mapping file
#' @param dm_fp Dissimilarity matrix filepath (tab-delimited text).
#' @param map_fp Metadata mapping filepath.
#' @param filter_cat The map_fp header string for the factor you would like 
#'  to use to filter samples.
#' @param filter_vals The values within the filter category (vector or single 
#'  value) you would like to use to remove samples from the imported data.
#' @param keep_vals Alternatively, keep only samples represented by these 
#'  values.
#' @return A list variable with (1) the loaded dissimilarity matrix, and (2) 
#'  the loaded mapping file.
#' @examples 
#' \dontrun{
#' load_dm("filepath_to_dissim_matrix.txt", "filepath_to_mapping_file.txt",
#'   "sample_type", filter_vals = "blank")
#' }
load_dm = function(dm_fp, map_fp, filter_cat, filter_vals, keep_vals){
  dm = read.table(dm_fp,sep='\t',comment.char='',header=T,check.names=F,row.names=1)
  map = read.table(map_fp,sep='\t',comment.char='',header=T,check.names=F,row.names=1)
  # optionally, subset data
  # cant subset if trying to filter out certain values and keep certain values
  # use one or the other
  if(!missing(filter_cat)){
    map.f = .filt_map(map, filter_cat, filter_vals, keep_vals)
  } else map.f = map
  # match up data from dissimilarity matrix with mapping file
  samplesToUse = intersect(names(dm), row.names(map.f))
  dm.use = as.dist(dm[match(samplesToUse,names(dm)), match(samplesToUse,names(dm))])
  map.use = map.f[match(samplesToUse,row.names(map.f)), ]
  # output
  list(dm_loaded = dm.use, map_loaded = map.use)
}

#' @title Load two dissimilarity matrices for use with mctoolsr
#' @description Load in two dissimilarity matrices and a corresponding metadata
#'  mapping file. Useful for Mantel tests when dms are already generated.
#' @param dm1_fp Dissimilarity matrix filepath (tab-delimited text).
#' @param dm2_fp Dissimilarity matrix filepath (tab-delimited text).
#' @param map_fp Metadata mapping filepath.
#' @param filter_cat The map_fp header string for the factor you would like 
#'  to use to filter samples.
#' @param filter_vals The values within the filter category (vector or single 
#'  value) you would like to use to remove samples from the imported data.
#' @param keep_vals Alternatively, keep only samples represented by these 
#'  values.
#' @return A list variable with (1) the loaded dissimilarity matrix 1, (2) the
#'  loaded dissimilarity matrix 2, and (3) the loaded mapping file.
#' @examples 
#' \dontrun{
#' load_dm("filepath_to_dissim_matrix1.txt", "filepath_to_dissim_matrix1.txt", 
#'   "filepath_to_mapping_file.txt", "sample_type", filter_vals = "blank")
#' }
load_2_dms = function(dm1_fp, dm2_fp, map_fp, filter_cat, filter_vals, keep_vals){
  dm1 = read.table(dm1_fp,sep='\t',comment.char='',header=T,check.names=F,row.names=1)
  dm2 = read.table(dm2_fp,sep='\t',comment.char='',header=T,check.names=F,row.names=1)
  map = read.table(map_fp,sep='\t',comment.char='',header=T,check.names=F,row.names=1)
  # optionally, subset data
  # cant subset if trying to filter out certain values and keep certain values
  # use one or the other
  if(!missing(filter_cat)){
    map.f = .filt_map(map, filter_cat, filter_vals, keep_vals)
  } else map.f = map
  # match up data from dissimilarity matrix with mapping file
  samplesToUse = intersect(intersect(names(dm1), row.names(map.f)), names(dm2))
  dm1.use = as.dist(dm1[match(samplesToUse,names(dm1)), match(samplesToUse,names(dm1))])
  dm2.use = as.dist(dm2[match(samplesToUse,names(dm2)), match(samplesToUse,names(dm2))])
  map.use = map.f[match(samplesToUse,row.names(map.f)), ]
  # output
  list(dm1_loaded = dm1.use, dm2_loaded = dm2.use, map_loaded = map.use)
}

#' @title Filter Samples from Dataset
#' @description Filter out or keep particular samples in a dataset based on 
#'  contextual metadata.
#' @param input The input dataset as loaded by \code{load_taxa_table()}
#' @param filter_cat The map_fp header string for the factor you would like 
#'  to use to filter samples.
#' @param filter_vals The values within the filter category (vector or single 
#'  value) you would like to use to remove samples from the imported data.
#' @param keep_vals Alternatively, keep only samples represented by these 
#'  values.
#' @return A list variable with (1) the loaded dissimilarity matrix, (2) 
#'  the loaded mapping file, and optionally (3) the loaded taxonomy information
#' @examples 
#' ex_in_filt = filter_data(input = "example_input", filter_cat = "Sample_type", 
#'                          filter_vals = c("mushrooms", "strawberries"))
filter_data = function(input, filter_cat, filter_vals, keep_vals){
  # input is list from 'load_data' function
  # cant subset if trying to filter out certain values and keep certain values
  # use one or the other
  if(!missing(filter_cat)){
    map.f = .filt_map(input$map_loaded, filter_cat, filter_vals, keep_vals)
  } else map.f = map
  # match up data from dissimilarity matrix with mapping file
  if('taxonomy_loaded' %in% names(input)){
    .match_data_components(input$data_loaded, map.f, input$taxonomy_loaded)
  } else {
    .match_data_components(input$data_loaded, map.f)
  }
}

#' @title Match up samples from two datasets
#' @description Function to match up sample order from two datasets that contain
#'  some overlapping sample IDs. Sample IDs that are not present in both
#'  datasets will be dropped. The output is a list containing the two filtered
#'  datasets in the same order as they were input.
#' @param ds1, ds2 The two datasets as loaded by \code{load_taxa_table()}
#' @return A list variable with the matched ds1 as the first element and ds2
#'  as the second element
match_datasets = function(ds1, ds2){
  common_samples = intersect(names(ds1$data_loaded), names(ds2$data_loaded))
  ds1$map_loaded$common_sample = row.names(ds1$map_loaded) %in% common_samples
  ds1_filt = filter_data(ds1, 'common_sample', FALSE)
  ds1_filt$data_loaded = ds1_filt$data_loaded[, 
                                              match(common_samples, 
                                                    names(ds1_filt$data_loaded))]
  ds1_filt$map_loaded = ds1_filt$map_loaded[match(common_samples, 
                                                  row.names(ds1_filt$map_loaded)), 
                                            ]
  ds2$map_loaded$common_sample = row.names(ds2$map_loaded) %in% common_samples
  ds2_filt = filter_data(ds2, 'common_sample', FALSE)
  ds2_filt$data_loaded = ds2_filt$data_loaded[, 
                                              match(common_samples, 
                                                    names(ds2_filt$data_loaded))]
  ds2_filt$map_loaded = ds2_filt$map_loaded[match(common_samples, 
                                                  row.names(ds2_filt$map_loaded)), 
                                            ]
  list(ds1 = ds1_filt, ds2 = ds2_filt)
}

#' @title Export an OTU table as a text file
#' @description A convenient way to export a loaded OTU table as a text file. 
#'  Taxonomy strings will appear in the right most column. This is also a good
#'  way to save an OTU table to be loaded later.
#' @param input The input dataset as loaded by \code{load_taxa_table()}
#' @param out_fp The output filepath
export_otu_table = function(input, out_fp){
  table = input$data_loaded
  taxonomy = apply(input$taxonomy_loaded, 1, paste, collapse = '; ')
  out_tab = data.frame(OTU_ID = row.names(table), table, taxonomy)
  names(out_tab)[1] = '#OTU ID'
  write('#Exported from mctoolsr', out_fp)
  suppressWarnings(write.table(out_tab, out_fp, sep = '\t', row.names = FALSE, 
                               append = TRUE))
}


