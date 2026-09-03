#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Exact variant concordance between local and external VCFs
# ============================================================
#
# For each sample, this script:
#
#   1. Normalizes the local VCF
#   2. Normalizes the harmonized external VCF
#   3. Splits multiallelic records
#   4. Left-aligns/normalizes variants against GRCh38
#   5. Restricts both VCFs to the same WES target BED
#   6. Performs an exact allele intersection with bcftools isec
#   7. Calculates:
#
#        - Local variants
#        - External variants
#        - Shared variants
#        - Local-only variants
#        - External-only variants
#        - Percentage of local variants shared
#        - Percentage of external variants shared
#        - Jaccard index
#
# Exact concordance is defined after normalization by identical:
#
#   CHROM + POS + REF + ALT
#
# Requirements:
#   - BCFtools
#
# Usage:
#
#   bash scripts/06_variant_concordance.sh \
#       /path/to/local_vcfs \
#       /path/to/external_grch38_vcfs \
#       /path/to/GRCh38_reference.fasta \
#       /path/to/target_regions.bed \
#       /path/to/output_directory
#
# Expected filenames:
#
#   Local:
#       SAMPLE.filtered.vcf.gz
#
#   External:
#       SAMPLE_GRCh38.vcf.gz
#
# ============================================================


# ------------------------------------------------------------
# 1. Arguments
# ------------------------------------------------------------

LOCAL_DIR="${1:-}"
EXTERNAL_DIR="${2:-}"
REFERENCE="${3:-}"
BED="${4:-}"
OUTPUT_DIR="${5:-}"

if [[ -z "$LOCAL_DIR" || \
      -z "$EXTERNAL_DIR" || \
      -z "$REFERENCE" || \
      -z "$BED" || \
      -z "$OUTPUT_DIR" ]]; then

    echo "Usage:"
    echo "  bash scripts/06_variant_concordance.sh \\"
    echo "      <local_vcf_directory> \\"
    echo "      <external_vcf_directory> \\"
    echo "      <GRCh38_reference.fasta> \\"
    echo "      <target_regions.bed> \\"
    echo "      <output_directory>"

    exit 1
fi


# ------------------------------------------------------------
# 2. Check inputs and dependencies
# ------------------------------------------------------------

if [[ ! -d "$LOCAL_DIR" ]]; then
    echo "ERROR: Local VCF directory not found: $LOCAL_DIR"
    exit 1
fi

if [[ ! -d "$EXTERNAL_DIR" ]]; then
    echo "ERROR: External VCF directory not found: $EXTERNAL_DIR"
    exit 1
fi

if [[ ! -f "$REFERENCE" ]]; then
    echo "ERROR: Reference genome not found: $REFERENCE"
    exit 1
fi

if [[ ! -f "$BED" ]]; then
    echo "ERROR: Target BED not found: $BED"
    exit 1
fi

if ! command -v bcftools >/dev/null 2>&1; then
    echo "ERROR: BCFtools was not found in PATH."
    echo "Activate the environment containing BCFtools before running this script."
    exit 1
fi


# ------------------------------------------------------------
# 3. Create output directories
# ------------------------------------------------------------

mkdir -p "$OUTPUT_DIR/local_normalized"
mkdir -p "$OUTPUT_DIR/external_normalized"
mkdir -p "$OUTPUT_DIR/isec"


# ------------------------------------------------------------
# 4. Find local VCF files
# ------------------------------------------------------------

mapfile -t LOCAL_VCFS < <(
    find "$LOCAL_DIR" \
        -maxdepth 1 \
        -type f \
        -name "*.filtered.vcf.gz" \
        | sort
)

if [[ ${#LOCAL_VCFS[@]} -eq 0 ]]; then
    echo "ERROR: No *.filtered.vcf.gz files were found in: $LOCAL_DIR"
    exit 1
fi


# ------------------------------------------------------------
# 5. Output summary file
# ------------------------------------------------------------

SUMMARY="$OUTPUT_DIR/variant_concordance.tsv"

printf "Sample\tLocal\tExternal\tShared\tOnly_local\tOnly_external\tLocal_shared_percent\tExternal_shared_percent\tJaccard_percent\n" \
    > "$SUMMARY"


# ------------------------------------------------------------
# 6. Process each sample
# ------------------------------------------------------------

for LOCAL_VCF in "${LOCAL_VCFS[@]}"; do

    filename=$(basename "$LOCAL_VCF")
    SAMPLE="${filename%.filtered.vcf.gz}"

    EXTERNAL_VCF="$EXTERNAL_DIR/${SAMPLE}_GRCh38.vcf.gz"

    echo
    echo "============================================================"
    echo "Processing: $SAMPLE"
    echo "============================================================"


    # --------------------------------------------------------
    # Check corresponding external VCF
    # --------------------------------------------------------

    if [[ ! -f "$EXTERNAL_VCF" ]]; then
        echo "ERROR: External VCF not found for sample: $SAMPLE"
        echo "Expected: $EXTERNAL_VCF"
        exit 1
    fi


    # --------------------------------------------------------
    # 6.1 Normalize local VCF
    # --------------------------------------------------------
    #
    # -f:
    #   normalize alleles using the GRCh38 reference
    #
    # -m -any:
    #   split multiallelic records into separate biallelic records
    #
    # Normalization is performed BEFORE target restriction because
    # indel normalization can modify genomic representation.
    # --------------------------------------------------------

    LOCAL_FULL="$OUTPUT_DIR/local_normalized/${SAMPLE}.full.vcf.gz"
    LOCAL_TARGET="$OUTPUT_DIR/local_normalized/${SAMPLE}.vcf.gz"

    bcftools norm \
        -f "$REFERENCE" \
        -m -any \
        "$LOCAL_VCF" \
        -Oz \
        -o "$LOCAL_FULL"

    bcftools index \
        -f \
        -t \
        "$LOCAL_FULL"


    # --------------------------------------------------------
    # 6.2 Restrict normalized local VCF to target BED
    # --------------------------------------------------------

    bcftools view \
        -R "$BED" \
        "$LOCAL_FULL" \
        -Oz \
        -o "$LOCAL_TARGET"

    bcftools index \
        -f \
        -t \
        "$LOCAL_TARGET"


    # --------------------------------------------------------
    # 6.3 Normalize external VCF
    # --------------------------------------------------------

    EXTERNAL_FULL="$OUTPUT_DIR/external_normalized/${SAMPLE}.full.vcf.gz"
    EXTERNAL_TARGET="$OUTPUT_DIR/external_normalized/${SAMPLE}.vcf.gz"

    bcftools norm \
        -f "$REFERENCE" \
        -m -any \
        "$EXTERNAL_VCF" \
        -Oz \
        -o "$EXTERNAL_FULL"

    bcftools index \
        -f \
        -t \
        "$EXTERNAL_FULL"


    # --------------------------------------------------------
    # 6.4 Restrict normalized external VCF to target BED
    # --------------------------------------------------------

    bcftools view \
        -R "$BED" \
        "$EXTERNAL_FULL" \
        -Oz \
        -o "$EXTERNAL_TARGET"

    bcftools index \
        -f \
        -t \
        "$EXTERNAL_TARGET"


    # --------------------------------------------------------
    # 6.5 Exact allele intersection
    # --------------------------------------------------------
    #
    # -c none:
    #   variants are considered compatible only when REF and ALT
    #   alleles match exactly at the same genomic position.
    #
    # For two input VCFs, bcftools isec produces:
    #
    #   0000.vcf -> only local
    #   0001.vcf -> only external
    #   0002.vcf -> shared records represented from local VCF
    #   0003.vcf -> shared records represented from external VCF
    #
    # --------------------------------------------------------

    ISEC_DIR="$OUTPUT_DIR/isec/${SAMPLE}"

    rm -rf "$ISEC_DIR"

    bcftools isec \
        -c none \
        -p "$ISEC_DIR" \
        "$LOCAL_TARGET" \
        "$EXTERNAL_TARGET"


    # --------------------------------------------------------
    # 6.6 Count variants
    # --------------------------------------------------------

    LOCAL_N=$(
        bcftools view -H "$LOCAL_TARGET" |
        wc -l |
        tr -d ' '
    )

    EXTERNAL_N=$(
        bcftools view -H "$EXTERNAL_TARGET" |
        wc -l |
        tr -d ' '
    )

    ONLY_LOCAL=$(
        bcftools view -H "$ISEC_DIR/0000.vcf" |
        wc -l |
        tr -d ' '
    )

    ONLY_EXTERNAL=$(
        bcftools view -H "$ISEC_DIR/0001.vcf" |
        wc -l |
        tr -d ' '
    )

    SHARED=$(
        bcftools view -H "$ISEC_DIR/0002.vcf" |
        wc -l |
        tr -d ' '
    )


    # --------------------------------------------------------
    # 6.7 Internal consistency checks
    # --------------------------------------------------------

    if [[ $((SHARED + ONLY_LOCAL)) -ne "$LOCAL_N" ]]; then
        echo "ERROR: Local counts are inconsistent for $SAMPLE"
        exit 1
    fi

    if [[ $((SHARED + ONLY_EXTERNAL)) -ne "$EXTERNAL_N" ]]; then
        echo "ERROR: External counts are inconsistent for $SAMPLE"
        exit 1
    fi


    # --------------------------------------------------------
    # 6.8 Calculate directional sharing percentages
    # --------------------------------------------------------

    LOCAL_SHARED_PERCENT=$(
        awk -v c="$SHARED" -v n="$LOCAL_N" '
            BEGIN {
                if (n > 0)
                    printf "%.2f", (c/n)*100
                else
                    printf "0.00"
            }
        '
    )

    EXTERNAL_SHARED_PERCENT=$(
        awk -v c="$SHARED" -v n="$EXTERNAL_N" '
            BEGIN {
                if (n > 0)
                    printf "%.2f", (c/n)*100
                else
                    printf "0.00"
            }
        '
    )


    # --------------------------------------------------------
    # 6.9 Calculate Jaccard index
    # --------------------------------------------------------
    #
    # Jaccard =
    #
    # shared /
    # (shared + only_local + only_external)
    #
    # --------------------------------------------------------

    JACCARD=$(
        awk \
            -v c="$SHARED" \
            -v ol="$ONLY_LOCAL" \
            -v oe="$ONLY_EXTERNAL" '
            BEGIN {
                union = c + ol + oe

                if (union > 0)
                    printf "%.2f", (c/union)*100
                else
                    printf "0.00"
            }
        '
    )


    # --------------------------------------------------------
    # 6.10 Write sample results
    # --------------------------------------------------------

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$LOCAL_N" \
        "$EXTERNAL_N" \
        "$SHARED" \
        "$ONLY_LOCAL" \
        "$ONLY_EXTERNAL" \
        "$LOCAL_SHARED_PERCENT" \
        "$EXTERNAL_SHARED_PERCENT" \
        "$JACCARD" \
        >> "$SUMMARY"

done


# ------------------------------------------------------------
# 7. Calculate global concordance
# ------------------------------------------------------------

GLOBAL_LOCAL=$(
    awk -F'\t' '
        NR > 1 {sum += $2}
        END {print sum+0}
    ' "$SUMMARY"
)

GLOBAL_EXTERNAL=$(
    awk -F'\t' '
        NR > 1 {sum += $3}
        END {print sum+0}
    ' "$SUMMARY"
)

GLOBAL_SHARED=$(
    awk -F'\t' '
        NR > 1 {sum += $4}
        END {print sum+0}
    ' "$SUMMARY"
)

GLOBAL_ONLY_LOCAL=$(
    awk -F'\t' '
        NR > 1 {sum += $5}
        END {print sum+0}
    ' "$SUMMARY"
)

GLOBAL_ONLY_EXTERNAL=$(
    awk -F'\t' '
        NR > 1 {sum += $6}
        END {print sum+0}
    ' "$SUMMARY"
)


GLOBAL_LOCAL_SHARED_PERCENT=$(
    awk -v c="$GLOBAL_SHARED" -v n="$GLOBAL_LOCAL" '
        BEGIN {
            if (n > 0)
                printf "%.2f", (c/n)*100
            else
                printf "0.00"
        }
    '
)

GLOBAL_EXTERNAL_SHARED_PERCENT=$(
    awk -v c="$GLOBAL_SHARED" -v n="$GLOBAL_EXTERNAL" '
        BEGIN {
            if (n > 0)
                printf "%.2f", (c/n)*100
            else
                printf "0.00"
        }
    '
)

GLOBAL_JACCARD=$(
    awk \
        -v c="$GLOBAL_SHARED" \
        -v ol="$GLOBAL_ONLY_LOCAL" \
        -v oe="$GLOBAL_ONLY_EXTERNAL" '
        BEGIN {
            union = c + ol + oe

            if (union > 0)
                printf "%.2f", (c/union)*100
            else
                printf "0.00"
        }
    '
)


# ------------------------------------------------------------
# 8. Add global row
# ------------------------------------------------------------

printf "Global\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$GLOBAL_LOCAL" \
    "$GLOBAL_EXTERNAL" \
    "$GLOBAL_SHARED" \
    "$GLOBAL_ONLY_LOCAL" \
    "$GLOBAL_ONLY_EXTERNAL" \
    "$GLOBAL_LOCAL_SHARED_PERCENT" \
    "$GLOBAL_EXTERNAL_SHARED_PERCENT" \
    "$GLOBAL_JACCARD" \
    >> "$SUMMARY"


# ------------------------------------------------------------
# 9. Final report
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Variant concordance analysis completed"
echo "============================================================"
echo "Samples             : ${#LOCAL_VCFS[@]}"
echo
echo "Local variants      : $GLOBAL_LOCAL"
echo "External variants   : $GLOBAL_EXTERNAL"
echo "Shared              : $GLOBAL_SHARED"
echo "Only local          : $GLOBAL_ONLY_LOCAL"
echo "Only external       : $GLOBAL_ONLY_EXTERNAL"
echo
echo "Local shared (%)    : $GLOBAL_LOCAL_SHARED_PERCENT"
echo "External shared (%) : $GLOBAL_EXTERNAL_SHARED_PERCENT"
echo "Jaccard (%)         : $GLOBAL_JACCARD"
echo
echo "Output:"
echo "  $SUMMARY"
echo "============================================================"
