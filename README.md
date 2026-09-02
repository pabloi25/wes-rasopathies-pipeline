# WES RASopathies Pipeline

Reproducible bioinformatics workflow and analysis scripts developed for the local processing and evaluation of whole-exome sequencing (WES) data in patients with suspected RASopathies.

This repository contains the scripts, configurations and analysis procedures used as part of a Master's Thesis in Bioinformatics.

## Overview

The workflow was designed to process WES data from raw FASTQ files to filtered VCF files using a standardized and reproducible bioinformatics pipeline.

The study included 16 whole-exome sequencing samples and comprised the following main stages:

1. Quality control of sequencing data
2. Read alignment and preprocessing
3. Germline variant calling
4. Variant quality filtering
5. Coverage and sequencing quality assessment
6. Harmonization of external VCF files
7. Variant normalization
8. Restriction to common target regions
9. Variant concordance analysis
10. Genotype concordance analysis
11. Functional annotation and variant prioritization
12. Computational reproducibility assessment

## Workflow

```text
FASTQ
  │
  ▼
Quality control
  │
  ▼
nf-core/sarek
  │
  ├── Read preprocessing
  ├── Alignment to GRCh38
  ├── Post-alignment processing
  └── GATK HaplotypeCaller
  │
  ▼
VCF
  │
  ▼
VariantFiltration
  │
  ▼
Filtered VCF
  │
  ├── Quality metrics
  ├── Variant annotation
  ├── Variant prioritization
  │
  └── Concordance analysis
           ▲
           │
External VCF
  │
  ├── Genome-build harmonization
  ├── Liftover when required
  ├── Variant normalization
  └── Target-region restriction
```

## Main tools

The workflow uses:

- nf-core/sarek
- Nextflow
- GATK
- BWA
- SAMtools
- BCFtools
- fastp
- FastQC
- MultiQC
- mosdepth
- Ensembl Variant Effect Predictor (VEP)
- R

Detailed software versions are provided in `metadata/software_versions.tsv`.

## Reference genome and target regions

Analyses were performed using the GRCh38 human reference genome and the Agilent SureSelect All Exon V6 target regions.

External VCF files generated using a different genome build were harmonized to GRCh38 before comparison.

## Variant comparison

Local and external VCF files were normalized and restricted to the same target regions before comparison.

Variants were considered concordant when chromosome, genomic position, reference allele and alternate allele were identical.

The analyses included:

- Shared and exclusive variants
- Jaccard index
- Concordance stratified by variant type
- Genotype concordance

## Computational reproducibility

A subset of samples was independently reprocessed from the original FASTQ files on a different computational system while maintaining the same analytical configuration.

Reproducibility was evaluated using:

- Total variant counts
- Shared and exclusive variants
- FILTER status
- Genotype concordance
- Jaccard index
- MD5 hashes of non-header VCF records

## Repository structure

```text
wes-rasopathies-pipeline/
│
├── README.md
├── LICENSE
├── .gitignore
├── config/
├── scripts/
├── R/
│   ├── tables/
│   └── figures/
├── metadata/
├── docs/
└── example_data/
```

## Data availability

This repository does not contain raw sequencing data, patient VCF files, clinical reports or other individual-level genomic information.

Scripts and example configurations are provided to document and reproduce the analytical procedures without exposing patient data.

## Study scope

The analyses in this repository evaluate technical performance, concordance and computational reproducibility of the implemented workflow.

Comparison with external VCF files should not be interpreted as formal analytical validation against a ground-truth variant set.

## Author

Pablo Francisco Isa  and Luis Castillo
Master's Thesis in Bioinformatics
