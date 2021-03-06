# devtools::use_package('tools')
# devtools::use_package('biom')
# devtools::use_package('reshape2')
# devtools::use_package('dplyr')
# devtools::use_package('ggplot2')
# devtools::use_package('vegan')
# devtools::use_package('nlme')
# devtools::use_package('grid')
# devtools::use_package('scales')
# devtools::use_package('VennDiagram', 'Suggests')

.onAttach = function(libname, pkgname) {
  packageStartupMessage(paste0("You're using mctoolsr (v.", 
                        utils::packageVersion('mctoolsr'), 
                        "). Direct inquiries to:",
                        "\n'https://github.com/leffj/mctoolsr'"))
}

.onLoad = function(libname, pkgname) {
  op = options()
  op.devtools = list(
    mctoolsr.path = "",
    mctoolsr.install.args = "",
    mctoolsr.name = "mctoolsr",
    mctoolsr.desc.author = '"Jonathan W. Leff <jonathan.leff@colorado.edu> [aut, cre]"',
    mctoolsr.desc.license = "GPL-3",
    mctoolsr.desc.suggests = NULL,
    mctoolsr.desc = list()
  )
  toset = !(names(op.devtools) %in% names(op))
  if(any(toset)) options(op.devtools[toset])
  
  invisible()
}