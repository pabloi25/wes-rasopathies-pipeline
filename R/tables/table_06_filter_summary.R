# ============================================================
# Tabla 6 - Distribución de variantes PASS y no PASS
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla6 <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175",
    "Promedio", "Total"
  ),
  
  PASS = c(
    28644, 28725, 28695, 28073,
    28265, 28015, 28947, 28519,
    28294, 28898, 29008, 28632,
    27456, 27654, 27188, 27108,
    28258, 452121
  ),
  
  LowMQ = c(
    864, 1072, 1122, 996,
    844, 928, 1046, 877,
    1114, 1000, 1206, 1028,
    1162, 1033, 877, 1064,
    1015, 16233
  ),
  
  LowQD = c(
    450, 566, 437, 393,
    348, 397, 487, 450,
    539, 455, 480, 412,
    458, 443, 340, 480,
    446, 7135
  ),
  
  HighFS = c(
    16, 48, 11, 9,
    8, 7, 25, 8,
    18, 20, 47, 5,
    38, 25, 2, 28,
    20, 315
  ),
  
  Combinados = c(
    62, 75, 59, 43,
    32, 37, 53, 40,
    73, 57, 97, 56,
    87, 78, 32, 63,
    59, 944
  ),
  
  No_PASS_total = c(
    1268, 1611, 1511, 1355,
    1168, 1295, 1505, 1295,
    1596, 1417, 1633, 1388,
    1569, 1421, 1187, 1508,
    1420, 22727
  )
)

# ------------------------------------------------------------
# Crear tabla
# ------------------------------------------------------------

ft <- flextable(tabla6)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  PASS = "PASS",
  LowMQ = "LowMQ",
  LowQD = "LowQD",
  HighFS = "HighFS",
  Combinados = "Combinados",
  No_PASS_total = "No PASS\ntotal"
)

# ------------------------------------------------------------
# Formato numérico
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = 2:7,
  digits = 0,
  big.mark = ".",
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
  j = 2:7,
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

# Promedio y Total en negrita
ft <- bold(
  ft,
  i = c(17, 18),
  part = "body"
)

ft <- autofit(ft)

# ------------------------------------------------------------
# Título
# ------------------------------------------------------------

ft <- set_caption(
  ft,
  caption = paste(
    "Tabla 6. Distribución de variantes PASS y no PASS",
    "según los criterios de filtrado técnico aplicados",
    "mediante GATK VariantFiltration."
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
  target = "table_06_filter_summary.docx"
)
