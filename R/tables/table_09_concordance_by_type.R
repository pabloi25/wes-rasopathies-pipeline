# ============================================================
# Tabla 9 - Concordancia estratificada por tipo de variante
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla9 <- data.frame(
  Tipo_variante = c(
    "SNP",
    "INDEL"
  ),

  Sarek = c(
    453998,
    21716
  ),

  Empresa = c(
    437712,
    21623
  ),

  Compartidas = c(
    418214,
    17932
  ),

  Solo_Sarek = c(
    35784,
    3784
  ),

  Solo_Empresa = c(
    19498,
    3691
  ),

  Sarek_compartido = c(
    92.12,
    82.58
  ),

  Empresa_compartido = c(
    95.55,
    82.93
  ),

  Jaccard = c(
    88.32,
    70.58
  )
)

# ------------------------------------------------------------
# Crear tabla
# ------------------------------------------------------------

ft <- flextable(tabla9)

ft <- set_header_labels(
  ft,
  Tipo_variante = "Tipo de\nvariante",
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
    "Sarek",
    "Empresa",
    "Compartidas",
    "Solo_Sarek",
    "Solo_Empresa"
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
  size = 9.5,
  part = "all"
)

ft <- bold(
  ft,
  part = "header"
)

ft <- align(
  ft,
  j = "Tipo_variante",
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
  caption = "Tabla 9. Concordancia de las variantes estratificadas."
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
  target = "table_09_concordance_by_type.docx"
)
