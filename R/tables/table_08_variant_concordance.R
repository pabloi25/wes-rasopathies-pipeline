# ============================================================
# Tabla 8 - Concordancia de variantes e índice de Jaccard
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla8 <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175",
    "Global"
  ),

  Sarek = c(
    30003, 30424, 30301, 29489,
    29501, 29381, 30540, 29885,
    29965, 30406, 30740, 30101,
    29122, 29153, 28442, 28692,
    476145
  ),

  Empresa = c(
    29451, 29826, 29693, 31015,
    30191, 27966, 28710, 28577,
    28175, 28724, 28939, 28388,
    27489, 27551, 27398, 27345,
    459438
  ),

  Compartidas = c(
    27791, 28226, 28250, 28870,
    28903, 26568, 27436, 27058,
    26823, 27431, 27633, 27006,
    26156, 26277, 25911, 25871,
    436210
  ),

  Solo_Sarek = c(
    2212, 2198, 2051, 619,
    598, 2813, 3104, 2827,
    3142, 2975, 3107, 3095,
    2966, 2876, 2531, 2821,
    39935
  ),

  Solo_Empresa = c(
    1660, 1600, 1443, 2145,
    1288, 1398, 1274, 1519,
    1352, 1293, 1306, 1382,
    1333, 1274, 1487, 1474,
    23228
  ),

  Sarek_compartido = c(
    92.62, 92.77, 93.23, 97.90,
    97.97, 90.42, 89.83, 90.54,
    89.51, 90.21, 89.89, 89.71,
    89.81, 90.13, 91.10, 90.16,
    91.61
  ),

  Empresa_compartido = c(
    94.36, 94.63, 95.14, 93.08,
    95.73, 95.00, 95.56, 94.68,
    95.20, 95.49, 95.48, 95.13,
    95.15, 95.37, 94.57, 94.60,
    94.94
  ),

  Jaccard = c(
    87.77, 88.14, 88.99, 91.26,
    93.87, 86.31, 86.23, 86.16,
    85.64, 86.53, 86.22, 85.77,
    85.88, 86.36, 86.57, 85.76,
    87.35
  )
)

# ------------------------------------------------------------
# Crear tabla
# ------------------------------------------------------------

ft <- flextable(tabla8)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  Sarek = "Sarek",
  Empresa = "Empresa",
  Compartidas = "Compartidas",
  Solo_Sarek = "Solo\nSarek",
  Solo_Empresa = "Solo\nempresa",
  Sarek_compartido = "Sarek\ncompartido (%)",
  Empresa_compartido = "Empresa\ncompartido (%)",
  Jaccard = "Jaccard\n(%)"
)

# ------------------------------------------------------------
# Formato numérico
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = c(
    "Sarek", "Empresa", "Compartidas",
    "Solo_Sarek", "Solo_Empresa"
  ),
  digits = 0,
  big.mark = ".",
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = c(
    "Sarek_compartido",
    "Empresa_compartido",
    "Jaccard"
  ),
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
  size = 9,
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
  j = 2:9,
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
  padding.top = 2,
  padding.bottom = 2,
  part = "all"
)

# Fila global en negrita
ft <- bold(
  ft,
  i = 17,
  part = "body"
)

ft <- autofit(ft)

# ------------------------------------------------------------
# Título
# ------------------------------------------------------------

ft <- set_caption(
  ft,
  caption = paste(
    "Tabla 8. Variantes compartidas, exclusivas",
    "e índice de Jaccard."
  )
)

# ------------------------------------------------------------
# Nota al pie
# ------------------------------------------------------------

ft <- add_footer_lines(
  ft,
  values = paste(
    "Índice de Jaccard = variantes compartidas /",
    "(variantes compartidas + solo Sarek + solo empresa) × 100."
  )
)

ft <- fontsize(
  ft,
  size = 8.5,
  part = "footer"
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
  target = "table_08_variant_concordance.docx"
)
