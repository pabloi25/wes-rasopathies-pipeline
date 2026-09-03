# ============================================================
# Tabla 10 - Concordancia genotípica de las variantes
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla10 <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175",
    "Global"
  ),

  GT_comparables = c(
    27791, 28223, 28247, 28870,
    28903, 26568, 27436, 27058,
    26823, 27431, 27633, 27006,
    26156, 26277, 25911, 25871,
    436204
  ),

  GT_concordantes = c(
    27680, 28132, 28162, 28602,
    28739, 26488, 27348, 26970,
    26757, 27321, 27554, 26878,
    26050, 26199, 25804, 25780,
    434464
  ),

  GT_discordantes = c(
    111, 91, 85, 268,
    164, 80, 88, 88,
    66, 110, 79, 128,
    106, 78, 107, 91,
    1740
  )
)

# ------------------------------------------------------------
# Calcular concordancia genotípica
# ------------------------------------------------------------

tabla10$Concordancia_GT <- round(
  (tabla10$GT_concordantes / tabla10$GT_comparables) * 100,
  2
)

# ------------------------------------------------------------
# Crear tabla
# ------------------------------------------------------------

ft <- flextable(tabla10)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  GT_comparables = "GT\ncomparables",
  GT_concordantes = "GT\nconcordantes",
  GT_discordantes = "GT\ndiscordantes",
  Concordancia_GT = "Concordancia\nGT (%)"
)

# ------------------------------------------------------------
# Formato numérico
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = c(
    "GT_comparables",
    "GT_concordantes",
    "GT_discordantes"
  ),
  digits = 0,
  big.mark = ".",
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = "Concordancia_GT",
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
  caption = "Tabla 10. Concordancia genotípica de las variantes."
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
  target = "table_10_genotype_concordance.docx"
)
