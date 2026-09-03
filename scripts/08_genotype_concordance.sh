#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Genotype concordance for shared variants
# ============================================================
#
# Compares genotypes between local and external VCFs for the
# variants previously identified as shared by:
#
#   06_variant_concordance.sh
#
# bcftools isec outputs:
#
#   0002.vcf -> shared variants represented from local VCF
#   0003.vcf -> shared variants represented from external VCF
#
# Genotypes are canonicalized before comparison:
#
#   0|1 -> 0/1
#   1|0 -> 0/1
#   1/0 -> 0/1
#
# Missing or partially missing genotypes are classified as
# non-comparable.
#
# Requirements:
#   - BCFtools
#   - awk
#
# Usage:
#
#   bash scripts/08_genotype_concordance.sh \
#       /path/to/concordance_directory
#
# The input directory must contain:
#
#   isec/
#
# ============================================================


# ------------------------------------------------------------
# 1. Argument
# ------------------------------------------------------------

CONCORDANCE_DIR="${1:-}"

if [[ -z "$CONCORDANCE_DIR" ]]; then
    echo "Usage:"
    echo "  bash scripts/08_genotype_concordance.sh <concordance_directory>"
    exit 1
fi


# ------------------------------------------------------------
# 2. Check inputs and dependency
# ------------------------------------------------------------

ISEC_DIR="$CONCORDANCE_DIR/isec"

if [[ ! -d "$ISEC_DIR" ]]; then
    echo "ERROR: isec directory not found:"
    echo "  $ISEC_DIR"
    exit 1
fi

if ! command -v bcftools >/dev/null 2>&1; then
    echo "ERROR: BCFtools was not found in PATH."
    exit 1
fi


# ------------------------------------------------------------
# 3. Output file
# ------------------------------------------------------------

OUTPUT="$CONCORDANCE_DIR/genotype_concordance.tsv"

printf "Sample\tShared\tGT_comparable\tGT_concordant\tGT_discordant\tGT_missing\tGT_concordance_percent\n" \
    > "$OUTPUT"


# ------------------------------------------------------------
# 4. Temporary directory
# ------------------------------------------------------------

TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT


# ------------------------------------------------------------
# 5. Process each sample
# ------------------------------------------------------------

mapfile -t SAMPLE_DIRS < <(
    find "$ISEC_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        | sort
)

if [[ ${#SAMPLE_DIRS[@]} -eq 0 ]]; then
    echo "ERROR: No sample directories were found in: $ISEC_DIR"
    exit 1
fi


for SAMPLE_DIR in "${SAMPLE_DIRS[@]}"; do

    SAMPLE=$(basename "$SAMPLE_DIR")

    LOCAL_SHARED="$SAMPLE_DIR/0002.vcf"
    EXTERNAL_SHARED="$SAMPLE_DIR/0003.vcf"

    echo "Processing: $SAMPLE"


    # --------------------------------------------------------
    # Check shared VCF files
    # --------------------------------------------------------

    if [[ ! -f "$LOCAL_SHARED" || ! -f "$EXTERNAL_SHARED" ]]; then
        echo "ERROR: Shared VCF files not found for $SAMPLE"
        exit 1
    fi


    # --------------------------------------------------------
    # Each VCF is expected to contain one sample
    # --------------------------------------------------------

    LOCAL_SAMPLE_COUNT=$(
        bcftools query -l "$LOCAL_SHARED" |
        wc -l |
        tr -d ' '
    )

    EXTERNAL_SAMPLE_COUNT=$(
        bcftools query -l "$EXTERNAL_SHARED" |
        wc -l |
        tr -d ' '
    )

    if [[ "$LOCAL_SAMPLE_COUNT" -ne 1 || "$EXTERNAL_SAMPLE_COUNT" -ne 1 ]]; then
        echo "ERROR: Expected one genotype sample per VCF for $SAMPLE"
        exit 1
    fi


    # --------------------------------------------------------
    # Extract CHROM, POS, REF, ALT and GT
    # --------------------------------------------------------

    LOCAL_GT="$TMP_DIR/${SAMPLE}_local.tsv"
    EXTERNAL_GT="$TMP_DIR/${SAMPLE}_external.tsv"

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' \
        "$LOCAL_SHARED" \
        > "$LOCAL_GT"

    bcftools query \
        -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT]\n' \
        "$EXTERNAL_SHARED" \
        > "$EXTERNAL_GT"


    # --------------------------------------------------------
    # Compare genotypes
    # --------------------------------------------------------

    RESULT=$(
        awk -F'\t' '

        # ----------------------------------------------------
        # Canonicalize genotype representation
        # ----------------------------------------------------
        #
        # Examples:
        #
        #   0|1 -> 0/1
        #   1/0 -> 0/1
        #
        # Missing alleles return "."
        # ----------------------------------------------------

        function canon(gt, alleles, n, i, j, tmp, out) {

            gsub(/\|/, "/", gt)

            if (gt == "." || gt == "./.")
                return "."

            n = split(gt, alleles, "/")

            for (i = 1; i <= n; i++) {
                if (alleles[i] == ".")
                    return "."
            }

            # Sort allele numbers
            for (i = 1; i <= n; i++) {
                for (j = i + 1; j <= n; j++) {
                    if ((alleles[i] + 0) > (alleles[j] + 0)) {
                        tmp = alleles[i]
                        alleles[i] = alleles[j]
                        alleles[j] = tmp
                    }
                }
            }

            out = alleles[1]

            for (i = 2; i <= n; i++)
                out = out "/" alleles[i]

            return out
        }


        # ----------------------------------------------------
        # Read local genotypes
        # ----------------------------------------------------

        NR == FNR {

            key = $1 ":" $2 ":" $3 ":" $4

            local_gt[key] = canon($5)

            next
        }


        # ----------------------------------------------------
        # Compare external genotypes
        # ----------------------------------------------------

        {

            key = $1 ":" $2 ":" $3 ":" $4

            external_gt = canon($5)

            shared++

            if (!(key in local_gt)) {
                missing++
                next
            }

            if (local_gt[key] == "." || external_gt == ".") {

                missing++

            } else {

                comparable++

                if (local_gt[key] == external_gt)
                    concordant++
                else
                    discordant++
            }
        }


        # ----------------------------------------------------
        # Results
        # ----------------------------------------------------

        END {

            if (comparable > 0)
                pct = (concordant / comparable) * 100
            else
                pct = 0

            printf "%d\t%d\t%d\t%d\t%d\t%.2f", \
                shared+0, \
                comparable+0, \
                concordant+0, \
                discordant+0, \
                missing+0, \
                pct
        }

        ' "$LOCAL_GT" "$EXTERNAL_GT"
    )


    # --------------------------------------------------------
    # Write sample result
    # --------------------------------------------------------

    printf "%s\t%s\n" \
        "$SAMPLE" \
        "$RESULT" \
        >> "$OUTPUT"

done


# ------------------------------------------------------------
# 6. Calculate global genotype concordance
# ------------------------------------------------------------

GLOBAL_SHARED=$(
    awk -F'\t' '
        NR > 1 {sum += $2}
        END {print sum+0}
    ' "$OUTPUT"
)

GLOBAL_COMPARABLE=$(
    awk -F'\t' '
        NR > 1 {sum += $3}
        END {print sum+0}
    ' "$OUTPUT"
)

GLOBAL_CONCORDANT=$(
    awk -F'\t' '
        NR > 1 {sum += $4}
        END {print sum+0}
    ' "$OUTPUT"
)

GLOBAL_DISCORDANT=$(
    awk -F'\t' '
        NR > 1 {sum += $5}
        END {print sum+0}
    ' "$OUTPUT"
)

GLOBAL_MISSING=$(
    awk -F'\t' '
        NR > 1 {sum += $6}
        END {print sum+0}
    ' "$OUTPUT"
)

GLOBAL_PERCENT=$(
    awk \
        -v c="$GLOBAL_CONCORDANT" \
        -v n="$GLOBAL_COMPARABLE" '
        BEGIN {
            if (n > 0)
                printf "%.2f", (c/n)*100
            else
                printf "0.00"
        }
    '
)


# ------------------------------------------------------------
# 7. Internal consistency checks
# ------------------------------------------------------------

if [[ $((GLOBAL_COMPARABLE + GLOBAL_MISSING)) -ne "$GLOBAL_SHARED" ]]; then
    echo "ERROR: Comparable + missing genotypes do not equal shared variants."
    exit 1
fi

if [[ $((GLOBAL_CONCORDANT + GLOBAL_DISCORDANT)) -ne "$GLOBAL_COMPARABLE" ]]; then
    echo "ERROR: Concordant + discordant genotypes do not equal comparable genotypes."
    exit 1
fi


# ------------------------------------------------------------
# 8. Add global row
# ------------------------------------------------------------

printf "Global\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$GLOBAL_SHARED" \
    "$GLOBAL_COMPARABLE" \
    "$GLOBAL_CONCORDANT" \
    "$GLOBAL_DISCORDANT" \
    "$GLOBAL_MISSING" \
    "$GLOBAL_PERCENT" \
    >> "$OUTPUT"


# ------------------------------------------------------------
# 9. Final report
# ------------------------------------------------------------

echo
echo "============================================================"
echo "Genotype concordance analysis completed"
echo "============================================================"
echo "Shared variants : $GLOBAL_SHARED"
echo "GT comparable   : $GLOBAL_COMPARABLE"
echo "GT concordant   : $GLOBAL_CONCORDANT"
echo "GT discordant   : $GLOBAL_DISCORDANT"
echo "GT missing      : $GLOBAL_MISSING"
echo "Concordance (%) : $GLOBAL_PERCENT"
echo
echo "Output:"
echo "  $OUTPUT"
echo "============================================================"
