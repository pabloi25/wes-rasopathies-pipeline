# ============================================================
# Tabla 5 - Distribución general de variantes
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla5 <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175"
  ),
  
  Variantes_totales = c(
    29912, 30336, 30206, 29428,
    29433, 29310, 30452, 29814,
    29890, 30315, 30641, 30020,
    29025, 29075, 28375, 28616
  ),
  
  Variantes_PASS = c(
    28644, 28725, 28695, 28073,
    28265, 28015, 28947, 28519,
    28294, 28898, 29008, 28632,
    27456, 27654, 27188, 27108
  ),
  
  SNPs = c(
    28545, 28984, 28853, 28219,
    28211, 28061, 29096, 28481,
    28552, 28999, 29266, 28657,
    27646, 27786, 27107, 27343
  ),
  
  Indels = c(
    1375, 1357, 1356, 1214,
    1223, 1254, 1362, 1338,
    1341, 1322, 1379, 1371,
    1385, 1293, 1270, 1276
  ),
  
  PASS_pct = c(
    95.76, 94.68, 94.99, 95.39,
    96.03, 95.58, 95.05, 95.65,
    94.66, 95.32, 94.67, 95.37,
    94.59, 95.11, 95.81, 94.73
  )
)

# ------------------------------------------------------------
# Tabla
# ------------------------------------------------------------

ft <- flextable(tabla5)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  Variantes_totales = "Variantes\ntotales",
  Variantes_PASS = "Variantes\nPASS",
  SNPs = "SNPs",
  Indels = "Indels",
  PASS_pct = "PASS\n(%)"
)

# ------------------------------------------------------------
# Formato numérico
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = c(
    "Variantes_totales",
    "Variantes_PASS",
    "SNPs",
    "Indels"
  ),
  digits = 0,
  big.mark = ".",
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = "PASS_pct",
  digits = 2,
  decimal.mark = ","
)

# ------------------------------------------------------------
# Estilo
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
# Título
# ------------------------------------------------------------

ft <- set_caption(
  ft,
  caption = paste(
    "Tabla 5. Distribución general de las variantes",
    "genómicas detectadas por muestra."
  )
)

# ------------------------------------------------------------
# Exportar
# ------------------------------------------------------------

doc <- read_docx()

doc <- body_add_flextable(
  doc,
  value = ft
)

print(
  doc,
  target = "table_05_variant_summary.docx"
)
