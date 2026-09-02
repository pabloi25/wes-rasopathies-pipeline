#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# GATK hard filtering of germline WES variants
# ============================================================
#
# Applies the hard-filtering criteria used in the study:
#
#   QD   < 2.0  -> LowQD
#   QUAL < 20.0 -> LowQual
#   FS   > 60.0 -> HighFS
#   MQ   < 40.0 -> LowMQ
#
# GATK VariantFiltration: 4.6.2.0
#
# IMPORTANT:
# VariantFiltration labels variants that fail the specified
# criteria in the FILTER field. It does not remove them.
#
# Usage:
#   bash scripts/02_variant_filtering.sh \
#       input.haplotypecaller.vcf.gz \
#       output.filtered.vcf.gz
# ============================================================

INPUT_VCF="${1:-}"
OUTPUT_VCF="${2:-}"

if [[ -z "$INPUT_VCF" || -z "$OUTPUT_VCF" ]]; then
    echo "Usage:"
    echo "  bash scripts/02_variant_filtering.sh <input.vcf.gz> <output.vcf.gz>"
    exit 1
fi

if [[ ! -f "$INPUT_VCF" ]]; then
    echo "ERROR: Input VCF not found: $INPUT_VCF"
    exit 1
fi

if ! command -v gatk >/dev/null 2>&1; then
    echo "ERROR: GATK was not found in PATH."
    echo "Activate the environment containing GATK before running this script."
    exit 1
fi

echo "============================================================"
echo "Running GATK VariantFiltration"
echo "Input  : $INPUT_VCF"
echo "Output : $OUTPUT_VCF"
echo "============================================================"

gatk VariantFiltration \
    -V "$INPUT_VCF" \
    --filter-expression "QD < 2.0" \
    --filter-name "LowQD" \
    --filter-expression "QUAL < 20.0" \
    --filter-name "LowQual" \
    --filter-expression "FS > 60.0" \
    --filter-name "HighFS" \
    --filter-expression "MQ < 40.0" \
    --filter-name "LowMQ" \
    -O "$OUTPUT_VCF"

echo "============================================================"
echo "Variant filtering completed successfully."
echo "Filtered variants were labelled in the FILTER field."
echo "============================================================"
