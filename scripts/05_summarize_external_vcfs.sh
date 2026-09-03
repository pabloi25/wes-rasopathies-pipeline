#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Summary of harmonized external VCF files
# ============================================================
#
# For each external GRCh38 VCF, this script calculates:
#
#   - Total variants in GRCh38
#   - Variants within the WES target BED
#   - PASS variants within the BED
#   - Non-PASS variants within the BED
#   - PASS percentage within the BED
#
# If a corresponding *_rejected.vcf.gz file is present, the
# script also summarizes liftover performance:
#
#   - Evaluated variants
#   - Successfully lifted variants
#   - Rejected variants
#   - Liftover success percentage
#
# Requirements:
#   - BCFtools
#
# Usage:
#
#   bash scripts/05_summarize_external_vcfs.sh \
#       /path/to/harmonized_external_vcfs \
#       /path/to/target_regions.bed \
#       /path/to/output_directory
#
# Expected harmonized VCF naming:
#
#   SAMPLE_GRCh38.vcf.gz
#
# Optional rejected VCF:
#
#   SAMPLE_rejected.vcf.gz
#
# ============================================================


# ------------------------------------------------------------
# 1. Arguments
# ------------------------------------------------------------

INPUT_DIR="${1:-}"
BED="${2:-}"
OUTPUT_DIR="${3:-}"

if [[ -z "$INPUT_DIR" || -z "$BED" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage:"
    echo "  bash scripts/05_summarize_external_vcfs.sh \\"
    echo "      <harmonized_vcf_directory> \\"
    echo "      <target_regions.bed> \\"
    echo "      <output_directory>"
    exit 1
fi


# ------------------------------------------------------------
# 2. Check inputs and dependencies
# ------------------------------------------------------------

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "ERROR: Input directory not found: $INPUT_DIR"
    exit 1
fi

if [[ ! -f "$BED" ]]; then
    echo "ERROR: BED file not found: $BED"
    exit 1
fi

if ! command -v bcftools >/dev/null 2>&1; then
    echo "ERROR: BCFtools was not found in PATH."
    echo "Activate the environment containing BCFtools before running this script."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"


# ------------------------------------------------------------
# 3. Find harmonized VCF files
# ------------------------------------------------------------

mapfile -t VCF_FILES < <(
    find "$INPUT_DIR" \
        -maxdepth 1 \
        -type f \
        -name "*_GRCh38.vcf.gz" \
        | sort
)

if [[ ${#VCF_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No *_GRCh38.vcf.gz files were found in: $INPUT_DIR"
    exit 1
fi


# ------------------------------------------------------------
# 4. Output files
# ------------------------------------------------------------

COUNT_OUTPUT="$OUTPUT_DIR/external_target_counts.tsv"
FILTER_OUTPUT="$OUTPUT_DIR/external_filter_summary.tsv"
LIFTOVER_OUTPUT="$OUTPUT_DIR/liftover_summary.tsv"

printf "Sample\tTotal_GRCh38\tWithin_BED\n" \
    > "$COUNT_OUTPUT"

printf "Sample\tWithin_BED\tPASS_within_BED\tNoPASS_within_BED\tPASS_percent\n" \
    > "$FILTER_OUTPUT"

printf "Sample\tEvaluated\tLifted\tRejected\tSuccess_percent\n" \
    > "$LIFTOVER_OUTPUT"


# ------------------------------------------------------------
# 5. Process each harmonized external VCF
# ------------------------------------------------------------

for VCF in "${VCF_FILES[@]}"; do

    filename=$(basename "$VCF")
    SAMPLE="${filename%_GRCh38.vcf.gz}"

    echo "============================================================"
    echo "Processing: $SAMPLE"
    echo "============================================================"


    # --------------------------------------------------------
    # Total variants in GRCh38
    # --------------------------------------------------------

    TOTAL=$(
        bcftools view -H "$VCF" |
        wc -l |
        tr -d ' '
    )


    # --------------------------------------------------------
    # Variants within target BED
    # --------------------------------------------------------

    WITHIN_BED=$(
        bcftools view \
            -R "$BED" \
            -H "$VCF" |
        wc -l |
        tr -d ' '
    )


    # --------------------------------------------------------
    # PASS variants within target BED
    # --------------------------------------------------------

    PASS=$(
        bcftools view \
            -R "$BED" \
            -f PASS \
            -H "$VCF" |
        wc -l |
        tr -d ' '
    )

    NO_PASS=$((WITHIN_BED - PASS))


    # --------------------------------------------------------
    # PASS percentage
    # --------------------------------------------------------

    PASS_PERCENT=$(
        awk -v p="$PASS" -v t="$WITHIN_BED" '
            BEGIN {
                if (t > 0)
                    printf "%.2f", (p/t)*100
                else
                    printf "0.00"
            }
        '
    )


    # --------------------------------------------------------
    # Write target-count summary
    # --------------------------------------------------------

    printf "%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$TOTAL" \
        "$WITHIN_BED" \
        >> "$COUNT_OUTPUT"


    # --------------------------------------------------------
    # Write FILTER summary
    # --------------------------------------------------------

    printf "%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$WITHIN_BED" \
        "$PASS" \
        "$NO_PASS" \
        "$PASS_PERCENT" \
        >> "$FILTER_OUTPUT"


    # --------------------------------------------------------
    # Liftover summary
    # --------------------------------------------------------

    REJECTED_VCF="$INPUT_DIR/${SAMPLE}_rejected.vcf.gz"

    if [[ -f "$REJECTED_VCF" ]]; then

        REJECTED=$(
            bcftools view -H "$REJECTED_VCF" |
            wc -l |
            tr -d ' '
        )

        EVALUATED=$((TOTAL + REJECTED))

        SUCCESS_PERCENT=$(
            awk -v l="$TOTAL" -v t="$EVALUATED" '
                BEGIN {
                    if (t > 0)
                        printf "%.3f", (l/t)*100
                    else
                        printf "0.000"
                }
            '
        )

        printf "%s\t%s\t%s\t%s\t%s\n" \
            "$SAMPLE" \
            "$EVALUATED" \
            "$TOTAL" \
            "$REJECTED" \
            "$SUCCESS_PERCENT" \
            >> "$LIFTOVER_OUTPUT"

    fi

done


# ------------------------------------------------------------
# 6. Report
# ------------------------------------------------------------

echo
echo "============================================================"
echo "External VCF summary completed"
echo "============================================================"
echo "VCFs analyzed : ${#VCF_FILES[@]}"
echo
echo "Output files:"
echo "  $COUNT_OUTPUT"
echo "  $FILTER_OUTPUT"
echo "  $LIFTOVER_OUTPUT"
echo "============================================================"
