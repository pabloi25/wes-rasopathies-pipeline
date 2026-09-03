# ============================================================
# Table 4 - WES target coverage metrics
# ============================================================
#
# Generates the table summarizing mean target coverage and
# the percentage of target bases covered at >=10X, >=20X
# and >=30X.
#
# Output:
#   table_04_coverage_metrics.docx
#
# Requirements:
#   flextable
#   officer
#
# Usage:
#   Rscript R/tables/table_04_coverage_metrics.R
#
# ============================================================


# ------------------------------------------------------------
# 1. Load packages
# ------------------------------------------------------------

library(flextable)
library(officer)


# ------------------------------------------------------------
# 2. Data
# ------------------------------------------------------------

tabla4 <- data.frame(
  
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175"
  ),
  
  Cobertura_media = c(
    51.05, 66.76, 48.50, 40.84,
    36.51, 40.72, 49.62, 45.04,
    55.18, 52.43, 81.45, 42.57,
    67.54, 56.65, 37.96, 56.68
  ),
  
  Bases_10X = c(
    96, 97, 95, 83,
    85, 92, 95, 94,
    96, 96, 96, 90,
    95, 95, 89, 96
  ),
  
  Bases_20X = c(
    85, 89, 83, 64,
    65, 76, 84, 81,
    87, 86, 89, 73,
    85, 84, 72, 86
  ),
  
  Bases_30X = c(
    70, 78, 68, 50,
    48, 58, 69, 64,
    74, 73, 79, 56,
    74, 71, 54, 73
  )
)


# ------------------------------------------------------------
# 3. Create flextable
# ------------------------------------------------------------

ft <- flextable(tabla4)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  Cobertura_media = "Cobertura media\ntarget (X)",
  Bases_10X = "Bases target\n≥10X (%)",
  Bases_20X = "Bases target\n≥20X (%)",
  Bases_30X = "Bases target\n≥30X (%)"
)


# ------------------------------------------------------------
# 4. Number formatting
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = "Cobertura_media",
  digits = 2,
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = c("Bases_10X", "Bases_20X", "Bases_30X"),
  digits = 0,
  decimal.mark = ","
)


# ------------------------------------------------------------
# 5. Table style
# ------------------------------------------------------------

ft <- theme_booktabs(ft)

ft <- font(
  ft,
  fontname = "Calibri",
  part = "all"
)

ft <- fontsize(
  ft,
  size = 9.5,
  part = "all"
)

ft <- bold(
  ft,
  part = "header"
)

ft <- align(
  ft,
  j = "Muestra",
  align = "left",
  part = "all"
)

ft <- align(
  ft,
  j = 2:5,
  align = "center",
  part = "all"
)

ft <- valign(
  ft,
  valign = "center",
  part = "all"
)

ft <- padding(
  ft,
  padding.top = 3,
  padding.bottom = 3,
  part = "all"
)

ft <- autofit(ft)


# ------------------------------------------------------------
# 6. Caption
# ------------------------------------------------------------

ft <- set_caption(
  ft,
  caption = paste(
    "Tabla 4. Cobertura media y porcentaje de bases de las",
    "regiones objetivo cubiertas a diferentes umbrales",
    "de profundidad."
  )
)


# ------------------------------------------------------------
# 7. Export to Word
# ------------------------------------------------------------

doc <- read_docx()

doc <- body_add_flextable(
  doc,
  value = ft
)

print(
  doc,
  target = "table_04_coverage_metrics.docx"
)

cat(
  "Table created successfully:\n",
  "table_04_coverage_metrics.docx\n"
)
