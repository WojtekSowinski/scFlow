context("annotation")
test_that("ensembl mapping works", {
  expect_equal(map_ensembl_gene_id(ensembl_ids = "ENSG00000130707",
                                   mappings = "external_gene_name")[[1]],
               "ASS1")
  expect_equal(map_ensembl_gene_id(ensembl_ids = "ENSG00000130707")[[1]],
               "ENSG00000130707")
})
