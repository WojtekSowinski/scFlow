bioc_pkgs<-c(
  'batchelor',
  'BiocGenerics',
  'BiocStyle',
  'biomaRt',
  'ComplexHeatmap',
  'DelayedArray',
  'DelayedMatrixStats',
  'DropletUtils',
  'edgeR',
  'GenomicRanges',
  'graph',
  'IRanges',
  'limma',
  'MAST',
  'multtest',
  'orthogene',
  'preprocessCore',
  'rhdf5',
  'S4Vectors',
  'scater',
  'SingleCellExperiment',
  'SummarizedExperiment'
)

requireNamespace("BiocManager")
BiocManager::install(bioc_pkgs, ask=F, type = "source")
