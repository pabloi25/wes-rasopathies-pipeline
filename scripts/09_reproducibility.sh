#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Computational reproducibility assessment
# ============================================================
#
# Compares original and independently reprocessed VCF files.
#
# For each sample, the script evaluates:
#
#   - Total variant records
#   - PASS records
#   - Non-PASS records
#   - Shared variants
#   - Variants exclusive to each execution
#   - Jaccard index
#   - Genotype concordance
#   - MD5 hash of non-header VCF records
#
# No normalization is performed because this analysis evaluates
# reproducibility of the same pipeline configuration applied to
# the same FASTQ input in independent executions.
#
# Expected filenames:
#
#   Original:
#       SAMPLE.filtered.vcf
#
#   Repetition:
#       SAMPLE_replica.vcf
#
# Requirements:
#   - BCFtools
#   - awk
#   - md5sum
#
# Usage:
#
#   bash scripts/09_reproducibility.sh \
#       /path/to/original_vcfs \
#       /path/to/repeated_vcfs \
#       /path/to/output_directory
#
# ============================================================


# ------------------------------------------------------------
# 1. Arguments
# ------------------------------------------------------------

ORIGINAL_DIR="${1:-}"
REPEAT_DIR="${2:-}"
OUTPUT_DIR="${3:-}"

if [[ -z "$ORIGINAL_DIR" || -z "$REPEAT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage:"
    echo "  bash scripts/09_reproducibility.sh \\"
    echo "      <original_vcf_directory> \\"
    echo "      <repeated_vcf_directory> \\"
    echo "      <output_directory>"
    exit 1
fi


# ------------------------------------------------------------
# 2. Check inputs and dependencies
# ------------------------------------------------------------

if [[ ! -d "$ORIGINAL_DIR" ]]; then
    echo "ERROR: Original VCF directory not found: $ORIGINAL_DIR"
    exit 1
fi

if [[ ! -d "$REPEAT_DIR" ]]; then
    echo "ERROR: Repeated VCF directory not found: $REPEAT_DIR"
    exit 1
fi

if ! command -v bcftools >/dev/null 2>&1; then
    echo "ERROR: BCFtools was not found in PATH."
    exit 1
fi

if ! command -v md5sum >/dev/null 2>&1; then
    echo "ERROR: md5sum was not found in PATH."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT


# ------------------------------------------------------------
# 3. Output file
# ------------------------------------------------------------

OUTPUT="$OUTPUT_DIR/reproducibility_summary.tsv"

printf "Sample\tOriginal_total\tReplica_total\tOriginal_PASS\tReplica_PASS\tOriginal_noPASS\tReplica_noPASS\tShared\tOnly_original\tOnly_replica\tJaccard_percent\tGT_comparable\tGT_concordant\tGT_discordant\tGT_concordance_percent\tNonheader_MD5_identical\n" \
    > "$OUTPUT"


# ------------------------------------------------------------
# 4. Find original VCF files
# ------------------------------------------------------------

mapfile -t ORIGINAL_VCFS < <(
    find "$ORIGINAL_DIR" \
        -maxdepth 1 \
        -type f \
        -name "*.filtered.vcf" \
        | sort
)

if [[ ${#ORIGINAL_VCFS[@]} -eq 0 ]]; then
    echo "ERROR: No *.filtered.vcf files were found."
    exit 1
fi


# ------------------------------------------------------------
# 5. Process each sample
# ------------------------------------------------------------

for ORIGINAL in "${ORIGINAL_VCFS[@]}"; do

    filename=$(basename "$ORIGINAL")
    SAMPLE="${filename%.filtered.vcf}"

    REPLICA="$REPEAT_DIR/${SAMPLE}_replica.vcf"

    echo "Processing: $SAMPLE"

    if [[ ! -f "$REPLICA" ]]; then
        echo "ERROR: Replica VCF not found:"
        echo "  $REPLICA"
        exit 1
    fi


    # --------------------------------------------------------
    # Variant counts
    # --------------------------------------------------------

    ORIGINAL_TOTAL=$(bcftools view -H "$ORIGINAL" | wc -l | tr -d ' ')
    REPLICA_TOTAL=$(bcftools view -H "$REPLICA" | wc -l | tr -d ' ')

    ORIGINAL_PASS=$(bcftools view -f PASS -H "$ORIGINAL" | wc -l | tr -d ' ')
    REPLICA_PASS=$(bcftools view -f PASS -H "$REPLICA" | wc -l | tr -d ' ')

    ORIGINAL_NOPASS=$((ORIGINAL_TOTAL - ORIGINAL_PASS))
    REPLICA_NOPASS=$((REPLICA_TOTAL - REPLICA_PASS))


    # --------------------------------------------------------
    # Extract exact variant keys
    # --------------------------------------------------------

    ORIGINAL_KEYS="$TMP_DIR/${SAMPLE}_original.keys"
    REPLICA_KEYS="$TMP_DIR/${SAMPLE}_replica.keys"

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT\n' \
        "$ORIGINAL" |
        sort -u \
        > "$ORIGINAL_KEYS"

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT\n' \
        "$REPLICA" |
        sort -u \
        > "$REPLICA_KEYS"


    # --------------------------------------------------------
    # Shared and exclusive variants
    # --------------------------------------------------------

    SHARED=$(comm -12 "$ORIGINAL_KEYS" "$REPLICA_KEYS" | wc -l | tr -d ' ')
    ONLY_ORIGINAL=$(comm -23 "$ORIGINAL_KEYS" "$REPLICA_KEYS" | wc -l | tr -d ' ')
    ONLY_REPLICA=$(comm -13 "$ORIGINAL_KEYS" "$REPLICA_KEYS" | wc -l | tr -d ' ')

    JACCARD=$(
    awk \
        -v c="$SHARED" \
        -v oo="$ONLY_ORIGINAL" \
        -v orepl="$ONLY_REPLICA" '
        BEGIN {
            union = c + oo + orepl

            if (union > 0)
                printf "%.2f", (c/union)*100
            else
                printf "0.00"
        }
    '
)


    # --------------------------------------------------------
    # Genotype concordance
    # --------------------------------------------------------

    ORIGINAL_GT="$TMP_DIR/${SAMPLE}_original.gt"
    REPLICA_GT="$TMP_DIR/${SAMPLE}_replica.gt"

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' \
        "$ORIGINAL" \
        > "$ORIGINAL_GT"

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' \
        "$REPLICA" \
        > "$REPLICA_GT"

    GT_RESULT=$(
        awk -F'\t' '

        function canon(gt, a, n, i, j, tmp, out) {

            gsub(/\|/, "/", gt)

            if (gt == "." || gt == "./.")
                return "."

            n = split(gt, a, "/")

            for (i=1; i<=n; i++)
                if (a[i] == ".")
                    return "."

            for (i=1; i<=n; i++) {
                for (j=i+1; j<=n; j++) {
                    if ((a[i]+0) > (a[j]+0)) {
                        tmp=a[i]
                        a[i]=a[j]
                        a[j]=tmp
                    }
                }
            }

            out=a[1]

            for (i=2; i<=n; i++)
                out=out "/" a[i]

            return out
        }


        NR==FNR {

            key=$1 ":" $2 ":" $3 ":" $4
            gt_original[key]=canon($5)

            next
        }


        {

            key=$1 ":" $2 ":" $3 ":" $4

            if (!(key in gt_original))
                next

            gt_replica=canon($5)

            if (gt_original[key]=="." || gt_replica==".")
                next

            comparable++

            if (gt_original[key] == gt_replica)
                concordant++
            else
                discordant++
        }


        END {

            if (comparable > 0)
                pct=(concordant/comparable)*100
            else
                pct=0

            printf "%d\t%d\t%d\t%.2f", \
                comparable+0, \
                concordant+0, \
                discordant+0, \
                pct
        }

        ' "$ORIGINAL_GT" "$REPLICA_GT"
    )

    IFS=$'\t' read -r \
        GT_COMPARABLE \
        GT_CONCORDANT \
        GT_DISCORDANT \
        GT_PERCENT \
        <<< "$GT_RESULT"


    # --------------------------------------------------------
    # MD5 of non-header VCF records
    # --------------------------------------------------------

    ORIGINAL_MD5=$(
        grep -v '^#' "$ORIGINAL" |
        md5sum |
        awk '{print $1}'
    )

    REPLICA_MD5=$(
        grep -v '^#' "$REPLICA" |
        md5sum |
        awk '{print $1}'
    )

    if [[ "$ORIGINAL_MD5" == "$REPLICA_MD5" ]]; then
        MD5_IDENTICAL="YES"
    else
        MD5_IDENTICAL="NO"
    fi


    # --------------------------------------------------------
    # Write results
    # --------------------------------------------------------

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$ORIGINAL_TOTAL" \
        "$REPLICA_TOTAL" \
        "$ORIGINAL_PASS" \
        "$REPLICA_PASS" \
        "$ORIGINAL_NOPASS" \
        "$REPLICA_NOPASS" \
        "$SHARED" \
        "$ONLY_ORIGINAL" \
        "$ONLY_REPLICA" \
        "$JACCARD" \
        "$GT_COMPARABLE" \
        "$GT_CONCORDANT" \
        "$GT_DISCORDANT" \
        "$GT_PERCENT" \
        "$MD5_IDENTICAL" \
        >> "$OUTPUT"

done


# ------------------------------------------------------------
# 6. Final report
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Computational reproducibility assessment completed"
echo "============================================================"
echo "Samples analyzed: ${#ORIGINAL_VCFS[@]}"
echo
column -t -s $'\t' "$OUTPUT"
echo
echo "Output:"
echo "  $OUTPUT"
echo "============================================================"
