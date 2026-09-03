# ============================================================
# Table 3 - Alignment and library metrics
# ============================================================
#
# Generates the table used to summarize alignment,
# duplication and library characteristics for the WES samples.
#
# Output:
#   table_03_alignment_metrics.docx
#
# Requirements:
#   flextable
#   officer
#
# Usage:
#   Rscript R/tables/table_03_alignment_metrics.R
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

tabla3 <- data.frame(

  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175"
  ),

  Lecturas_totales = c(
    31975737, 43839738, 33061127, 23385233,
    21696821, 25080751, 30081450, 28280561,
    32835633, 31736721, 47319845, 25544051,
    40665460, 34992486, 25663506, 34935041
  ),

  Mapeo = c(
    99.99, 99.99, 99.99, 99.99,
    99.99, 99.99, 99.99, 99.99,
    99.99, 99.99, 99.99, 99.99,
    99.99, 99.99, 99.99, 99.99
  ),

  Duplicacion = c(
    13.93, 23.12, 28.96, 16.23,
    16.68, 18.75, 17.59, 17.13,
    16.55, 16.60, 19.03, 17.51,
    18.51, 22.05, 25.86, 16.66
  ),

  Tamano_biblioteca = c(
    70383331, 52659615, 32225187, 42568665,
    38228487, 40745378, 52925249, 52020617,
    62904463, 60421139, 75670251, 44562661,
    64952727, 44682889, 29203050, 63836220
  ),

  Tamano_inserto = c(
    226.5, 248.4, 267.2, 259.1,
    243.2, 249.3, 250.5, 238.6,
    257.4, 252.0, 270.6, 252.6,
    254.4, 261.1, 265.8, 238.9
  )
)


# ------------------------------------------------------------
# 3. Create flextable
# ------------------------------------------------------------

ft <- flextable(tabla3)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  Lecturas_totales = "Lecturas\ntotales",
  Mapeo = "Mapeo\n(%)",
  Duplicacion = "Duplicación\n(%)",
  Tamano_biblioteca = "Tamaño estimado\nde biblioteca",
  Tamano_inserto = "Tamaño medio\nde inserto (pb)"
)


# ------------------------------------------------------------
# 4. Number formatting
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = "Lecturas_totales",
  digits = 0,
  big.mark = ".",
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = "Mapeo",
  digits = 2,
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = "Duplicacion",
  digits = 2,
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = "Tamano_biblioteca",
  digits = 0,
  big.mark = ".",
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = "Tamano_inserto",
  digits = 1,
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
  j = 2:6,
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
    "Tabla 3. Métricas de alineamiento, duplicación y",
    "características de las bibliotecas de las 16 muestras",
    "analizadas mediante WES."
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
  target = "table_03_alignment_metrics.docx"
)

cat(
  "Table created successfully:\n",
  "table_03_alignment_metrics.docx\n"
)
