# ============================================================
# Tabla 12 - Concordancia en el análisis de reproducibilidad
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla12 <- data.frame(
  Muestra = c(
    "AX0050",
    "AX22050",
    "AX23001"
  ),

  Variantes_original = c(
    30206,
    29814,
    30315
  ),

  Variantes_replica = c(
    30206,
    29814,
    30315
  ),

  Compartidas = c(
    30206,
    29814,
    30315
  ),

  Solo_original = c(
    0,
    0,
    0
  ),

  Solo_replica = c(
    0,
    0,
    0
  ),

  Jaccard = c(
    100,
    100,
    100
  ),

  Concordancia_GT = c(
    100,
    100,
    100
  )
)

# ------------------------------------------------------------
# Crear tabla
# ------------------------------------------------------------

ft <- flextable(tabla12)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  Variantes_original = "Variantes\noriginal",
  Variantes_replica = "Variantes\nréplica",
  Compartidas = "Compartidas",
  Solo_original = "Solo\noriginal",
  Solo_replica = "Solo\nréplica",
  Jaccard = "Jaccard\n(%)",
  Concordancia_GT = "Concordancia\nGT (%)"
)

# ------------------------------------------------------------
# Formato numérico
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = c(
    "Variantes_original",
    "Variantes_replica",
    "Compartidas",
    "Solo_original",
    "Solo_replica"
  ),
  digits = 0,
  big.mark = ".",
  decimal.mark = ","
)

ft <- colformat_num(
  ft,
  j = c(
    "Jaccard",
    "Concordancia_GT"
  ),
  digits = 0,
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
  j = 2:8,
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
    "Tabla 12. Concordancia de las variantes en el",
    "análisis de reproducibilidad."
  )
)

# ------------------------------------------------------------
# Nota al pie
# ------------------------------------------------------------

ft <- add_footer_lines(
  ft,
  values = paste(
    "La identidad de los registros VCF fue corroborada",
    "adicionalmente mediante hashes MD5 coincidentes entre",
    "la ejecución original y la réplica de cada muestra."
  )
)

ft <- fontsize(
  ft,
  size = 8.5,
  part = "footer"
)

ft <- italic(
  ft,
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
  target = "table_12_reproducibility.docx"
)
