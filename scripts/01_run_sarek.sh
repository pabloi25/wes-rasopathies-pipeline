#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# nf-core/sarek WES processing
# ============================================================
#
# FASTQ -> alignment -> preprocessing/BQSR -> HaplotypeCaller
#
# nf-core/sarek: 3.4.0
# Nextflow: 23.10.1
# Execution profile: Conda
#
# The default HaplotypeCaller filtering step is skipped because
# GATK CNNScoreVariants is not supported by the Conda profile.
# Variant filtering is performed separately with GATK
# VariantFiltration (see 02_variant_filtering.sh).
#
# Usage:
#   bash scripts/01_run_sarek.sh \
#       config/samplesheet_example.csv \
#       /path/to/target_regions.bed \
#       results
# ============================================================

SAMPLESHEET="${1:-}"
INTERVALS="${2:-}"
OUTDIR="${3:-results}"

if [[ -z "$SAMPLESHEET" || -z "$INTERVALS" ]]; then
    echo "Usage:"
    echo "  bash scripts/01_run_sarek.sh <samplesheet.csv> <target_regions.bed> [outdir]"
    exit 1
fi

echo "============================================================"
echo "Running nf-core/sarek"
echo "Samplesheet : $SAMPLESHEET"
echo "Intervals   : $INTERVALS"
echo "Output      : $OUTDIR"
echo "============================================================"

unset JAVA_HOME

NXF_VER=23.10.1 nextflow run nf-core/sarek \
    -r 3.4.0 \
    -profile conda \
    --input "$SAMPLESHEET" \
    --genome GATK.GRCh38 \
    --wes \
    --outdir "$OUTDIR" \
    --save_reference \
    --intervals "$INTERVALS" \
    --tools haplotypecaller \
    --skip_tools haplotypecaller_filter \
    --max_memory '17.GB' \
    --max_cpus 10

echo "============================================================"
echo "Sarek processing completed."
echo "HaplotypeCaller VCFs are ready for hard filtering."
echo "============================================================"
