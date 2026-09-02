#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Characterization of filtered germline variants
# ============================================================
#
# Reconstructed analysis script for the variant-characterization
# stage of the study.
#
# For each filtered VCF, the script calculates:
#
#   - Total number of variant records
#   - PASS records
#   - PASS percentage
#   - Number of SNPs
#   - Number of indels
#   - Non-PASS records
#   - LowMQ occurrences
#   - LowQD occurrences
#   - HighFS occurrences
#   - LowQual occurrences
#   - Records failing more than one filter
#
# Individual FILTER labels are not mutually exclusive.
# For example, a record labelled "LowMQ;LowQD" contributes to:
#
#   LowMQ = 1
#   LowQD = 1
#   Combined = 1
#   No_PASS = 1
#
# Therefore, the sum of individual FILTER categories can be
# greater than the total number of non-PASS records.
#
# Requirements:
#   - BCFtools
#   - awk
#
# Usage:
#
#   bash scripts/03_characterize_variants.sh \
#       /path/to/filtered_vcfs \
#       results/variant_characterization
#
# ============================================================


# ------------------------------------------------------------
# 1. Read command-line arguments
# ------------------------------------------------------------

INPUT_DIR="${1:-}"
OUTPUT_DIR="${2:-}"

if [[ -z "$INPUT_DIR" || -z "$OUTPUT_DIR" ]]; then
    echo "Usage:"
    echo "  bash scripts/03_characterize_variants.sh <input_directory> <output_directory>"
    exit 1
fi


# ------------------------------------------------------------
# 2. Check input directory and dependencies
# ------------------------------------------------------------

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "ERROR: Input directory not found: $INPUT_DIR"
    exit 1
fi

if ! command -v bcftools >/dev/null 2>&1; then
    echo "ERROR: BCFtools was not found in PATH."
    echo "Activate the environment containing BCFtools before running this script."
    exit 1
fi


# ------------------------------------------------------------
# 3. Find filtered VCF files
# ------------------------------------------------------------

mapfile -t VCF_FILES < <(
    find "$INPUT_DIR" -maxdepth 1 -type f \
        \( -name "*.filtered.vcf.gz" -o -name "*.filtered.vcf" \) \
        | sort
)

if [[ ${#VCF_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No filtered VCF files were found in: $INPUT_DIR"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"


# ------------------------------------------------------------
# 4. Define output files
# ------------------------------------------------------------

VARIANT_OUTPUT="$OUTPUT_DIR/variant_summary.tsv"
FILTER_OUTPUT="$OUTPUT_DIR/filter_summary.tsv"
GLOBAL_OUTPUT="$OUTPUT_DIR/global_summary.tsv"

printf "Sample\tTotal_variants\tPASS\tSNPs\tIndels\tPASS_percent\n" \
    > "$VARIANT_OUTPUT"

printf "Sample\tPASS\tLowMQ\tLowQD\tHighFS\tLowQual\tCombined\tNo_PASS_total\n" \
    > "$FILTER_OUTPUT"


# ------------------------------------------------------------
# 5. Process each VCF
# ------------------------------------------------------------

for VCF in "${VCF_FILES[@]}"; do

    filename=$(basename "$VCF")

    SAMPLE="$filename"
    SAMPLE="${SAMPLE%.filtered.vcf.gz}"
    SAMPLE="${SAMPLE%.filtered.vcf}"

    echo "Processing: $SAMPLE"

    # --------------------------------------------------------
    # Total number of VCF records
    # --------------------------------------------------------

    TOTAL=$(
        bcftools query -f '%CHROM\n' "$VCF" |
        wc -l |
        tr -d ' '
    )


    # --------------------------------------------------------
    # Extract FILTER column once
    # --------------------------------------------------------

    FILTER_TMP=$(mktemp)

    bcftools query -f '%FILTER\n' "$VCF" > "$FILTER_TMP"


    # Exact PASS records
    PASS=$(
        awk '
            $0 == "PASS" {n++}
            END {print n+0}
        ' "$FILTER_TMP"
    )


    # Any record not labelled PASS
    NO_PASS=$(
        awk '
            $0 != "PASS" {n++}
            END {print n+0}
        ' "$FILTER_TMP"
    )


    # --------------------------------------------------------
    # Individual FILTER labels
    # --------------------------------------------------------

    LOW_MQ=$(
        awk -F';' '
            {
                for (i=1; i<=NF; i++)
                    if ($i == "LowMQ") n++
            }
            END {print n+0}
        ' "$FILTER_TMP"
    )

    LOW_QD=$(
        awk -F';' '
            {
                for (i=1; i<=NF; i++)
                    if ($i == "LowQD") n++
            }
            END {print n+0}
        ' "$FILTER_TMP"
    )

    HIGH_FS=$(
        awk -F';' '
            {
                for (i=1; i<=NF; i++)
                    if ($i == "HighFS") n++
            }
            END {print n+0}
        ' "$FILTER_TMP"
    )

    LOW_QUAL=$(
        awk -F';' '
            {
                for (i=1; i<=NF; i++)
                    if ($i == "LowQual") n++
            }
            END {print n+0}
        ' "$FILTER_TMP"
    )


    # --------------------------------------------------------
    # Records failing more than one filter
    # --------------------------------------------------------

    COMBINED=$(
        awk -F';' '
            NF > 1 {n++}
            END {print n+0}
        ' "$FILTER_TMP"
    )


    # --------------------------------------------------------
    # SNP and indel counts using bcftools stats
    # --------------------------------------------------------

    STATS_TMP=$(mktemp)

    bcftools stats "$VCF" > "$STATS_TMP"

    SNPS=$(
        awk -F'\t' '
            $1 == "SN" && $3 == "number of SNPs:" {
                print $4
                exit
            }
        ' "$STATS_TMP"
    )

    INDELS=$(
        awk -F'\t' '
            $1 == "SN" && $3 == "number of indels:" {
                print $4
                exit
            }
        ' "$STATS_TMP"
    )

    SNPS="${SNPS:-0}"
    INDELS="${INDELS:-0}"


    # --------------------------------------------------------
    # PASS percentage
    # --------------------------------------------------------

    PASS_PERCENT=$(
        awk -v pass="$PASS" -v total="$TOTAL" '
            BEGIN {
                if (total > 0)
                    printf "%.2f", (pass / total) * 100
                else
                    printf "0.00"
            }
        '
    )


    # --------------------------------------------------------
    # Internal consistency check
    # --------------------------------------------------------

    if [[ $((PASS + NO_PASS)) -ne "$TOTAL" ]]; then
        echo "ERROR: PASS + No_PASS does not equal total records for $SAMPLE"
        rm -f "$FILTER_TMP" "$STATS_TMP"
        exit 1
    fi


    # --------------------------------------------------------
    # Write results
    # --------------------------------------------------------

    printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$TOTAL" \
        "$PASS" \
        "$SNPS" \
        "$INDELS" \
        "$PASS_PERCENT" \
        >> "$VARIANT_OUTPUT"

    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
        "$SAMPLE" \
        "$PASS" \
        "$LOW_MQ" \
        "$LOW_QD" \
        "$HIGH_FS" \
        "$LOW_QUAL" \
        "$COMBINED" \
        "$NO_PASS" \
        >> "$FILTER_OUTPUT"


    rm -f "$FILTER_TMP" "$STATS_TMP"

done


# ------------------------------------------------------------
# 6. Calculate global summary
# ------------------------------------------------------------

TOTAL_VARIANTS=$(
    awk -F'\t' '
        NR > 1 {sum += $2}
        END {print sum+0}
    ' "$VARIANT_OUTPUT"
)

TOTAL_PASS=$(
    awk -F'\t' '
        NR > 1 {sum += $3}
        END {print sum+0}
    ' "$VARIANT_OUTPUT"
)

TOTAL_NO_PASS=$(
    awk -F'\t' '
        NR > 1 {sum += $8}
        END {print sum+0}
    ' "$FILTER_OUTPUT"
)

TOTAL_LOWMQ=$(
    awk -F'\t' '
        NR > 1 {sum += $3}
        END {print sum+0}
    ' "$FILTER_OUTPUT"
)

TOTAL_LOWQD=$(
    awk -F'\t' '
        NR > 1 {sum += $4}
        END {print sum+0}
    ' "$FILTER_OUTPUT"
)

TOTAL_HIGHFS=$(
    awk -F'\t' '
        NR > 1 {sum += $5}
        END {print sum+0}
    ' "$FILTER_OUTPUT"
)

TOTAL_LOWQUAL=$(
    awk -F'\t' '
        NR > 1 {sum += $6}
        END {print sum+0}
    ' "$FILTER_OUTPUT"
)

TOTAL_COMBINED=$(
    awk -F'\t' '
        NR > 1 {sum += $7}
        END {print sum+0}
    ' "$FILTER_OUTPUT"
)

NUMBER_SAMPLES="${#VCF_FILES[@]}"

GLOBAL_PASS_PERCENT=$(
    awk -v pass="$TOTAL_PASS" -v total="$TOTAL_VARIANTS" '
        BEGIN {
            printf "%.2f", (pass / total) * 100
        }
    '
)

MEAN_NO_PASS=$(
    awk -v n="$TOTAL_NO_PASS" -v samples="$NUMBER_SAMPLES" '
        BEGIN {
            printf "%.2f", n / samples
        }
    '
)


# ------------------------------------------------------------
# 7. Write global summary
# ------------------------------------------------------------

printf "Metric\tValue\n" > "$GLOBAL_OUTPUT"

printf "Samples\t%s\n" "$NUMBER_SAMPLES" >> "$GLOBAL_OUTPUT"
printf "Total_variants\t%s\n" "$TOTAL_VARIANTS" >> "$GLOBAL_OUTPUT"
printf "PASS\t%s\n" "$TOTAL_PASS" >> "$GLOBAL_OUTPUT"
printf "No_PASS\t%s\n" "$TOTAL_NO_PASS" >> "$GLOBAL_OUTPUT"
printf "PASS_percent\t%s\n" "$GLOBAL_PASS_PERCENT" >> "$GLOBAL_OUTPUT"
printf "Mean_No_PASS_per_sample\t%s\n" "$MEAN_NO_PASS" >> "$GLOBAL_OUTPUT"
printf "LowMQ\t%s\n" "$TOTAL_LOWMQ" >> "$GLOBAL_OUTPUT"
printf "LowQD\t%s\n" "$TOTAL_LOWQD" >> "$GLOBAL_OUTPUT"
printf "HighFS\t%s\n" "$TOTAL_HIGHFS" >> "$GLOBAL_OUTPUT"
printf "LowQual\t%s\n" "$TOTAL_LOWQUAL" >> "$GLOBAL_OUTPUT"
printf "Combined\t%s\n" "$TOTAL_COMBINED" >> "$GLOBAL_OUTPUT"


# ------------------------------------------------------------
# 8. Report
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Variant characterization completed"
echo "============================================================"
echo "Samples       : $NUMBER_SAMPLES"
echo "Total records : $TOTAL_VARIANTS"
echo "PASS          : $TOTAL_PASS"
echo "No PASS       : $TOTAL_NO_PASS"
echo "PASS (%)      : $GLOBAL_PASS_PERCENT"
echo
echo "LowMQ         : $TOTAL_LOWMQ"
echo "LowQD         : $TOTAL_LOWQD"
echo "HighFS        : $TOTAL_HIGHFS"
echo "LowQual       : $TOTAL_LOWQUAL"
echo "Combined      : $TOTAL_COMBINED"
echo
echo "Output files:"
echo "  $VARIANT_OUTPUT"
echo "  $FILTER_OUTPUT"
echo "  $GLOBAL_OUTPUT"
echo "============================================================"
