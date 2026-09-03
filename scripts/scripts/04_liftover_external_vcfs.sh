#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Harmonization of external VCF files to GRCh38
# ============================================================
#
# Converts external VCF files generated on b37/GRCh37 to GRCh38
# using GATK LiftoverVcf.
#
# GATK VariantFiltration/Liftover environment: 4.6.2.0
#
# Liftover settings used in the study:
#
#   --RECOVER_SWAPPED_REF_ALT true
#   --WRITE_ORIGINAL_POSITION true
#   --WRITE_ORIGINAL_ALLELES true
#
# Variants that cannot be converted are written to a separate
# rejected VCF.
#
# Usage:
#
#   bash scripts/04_liftover_external_vcfs.sh \
#       /path/to/input_vcfs \
#       /path/to/output_directory \
#       /path/to/b37ToHg38.over.chain \
#       /path/to/Homo_sapiens_assembly38.fasta
#
# Input files are expected to follow:
#
#   SAMPLE_FILTER_VARIANTS.vcf.gz
#
# ============================================================


# ------------------------------------------------------------
# 1. Arguments
# ------------------------------------------------------------

INPUT_DIR="${1:-}"
OUTPUT_DIR="${2:-}"
CHAIN="${3:-}"
REFERENCE="${4:-}"

if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" || -z "$CHAIN" || -z "$REFERENCE" ]]; then
    echo "Usage:"
    echo "  bash scripts/04_liftover_external_vcfs.sh \\"
    echo "      <input_vcf_directory> \\"
    echo "      <output_directory> \\"
    echo "      <b37ToHg38.over.chain> \\"
    echo "      <GRCh38_reference.fasta>"
    exit 1
fi


# ------------------------------------------------------------
# 2. Check files and dependencies
# ------------------------------------------------------------

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "ERROR: Input directory not found: $INPUT_DIR"
    exit 1
fi

if [[ ! -f "$CHAIN" ]]; then
    echo "ERROR: Liftover chain not found: $CHAIN"
    exit 1
fi

if [[ ! -f "$REFERENCE" ]]; then
    echo "ERROR: Reference genome not found: $REFERENCE"
    exit 1
fi

if ! command -v gatk >/dev/null 2>&1; then
    echo "ERROR: GATK was not found in PATH."
    echo "Activate the environment containing GATK before running this script."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"


# ------------------------------------------------------------
# 3. Find external VCFs
# ------------------------------------------------------------

mapfile -t VCF_FILES < <(
    find "$INPUT_DIR" \
        -maxdepth 1 \
        -type f \
        -name "*_FILTER_VARIANTS.vcf.gz" \
        | sort
)

if [[ ${#VCF_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No external VCF files were found."
    exit 1
fi


# ------------------------------------------------------------
# 4. Liftover
# ------------------------------------------------------------

for VCF in "${VCF_FILES[@]}"; do

    filename=$(basename "$VCF")
    SAMPLE="${filename%_FILTER_VARIANTS.vcf.gz}"

    echo "============================================================"
    echo "Processing: $SAMPLE"
    echo "============================================================"

    gatk LiftoverVcf \
        -I "$VCF" \
        -O "$OUTPUT_DIR/${SAMPLE}_GRCh38.vcf.gz" \
        -CHAIN "$CHAIN" \
        -REJECT "$OUTPUT_DIR/${SAMPLE}_rejected.vcf.gz" \
        -R "$REFERENCE" \
        --RECOVER_SWAPPED_REF_ALT true \
        --CREATE_INDEX true \
        --WRITE_ORIGINAL_POSITION true \
        --WRITE_ORIGINAL_ALLELES true \
        --MAX_RECORDS_IN_RAM 100000

done

echo
echo "============================================================"
echo "Liftover completed successfully."
echo "Output directory: $OUTPUT_DIR"
echo "============================================================"
