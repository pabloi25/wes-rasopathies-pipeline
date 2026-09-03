# ============================================================
# Tabla 7 - Comparación de variantes Sarek vs VCF externos
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla7 <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175"
  ),

  Sarek_total = c(
    29912, 30336, 30206, 29428,
    29433, 29310, 30452, 29814,
    29890, 30315, 30641, 30020,
    29025, 29075, 28375, 28616
  ),

  Empresa_total_GRCh38 = c(
    105641, 107313, 105649, 115105,
    104578, 172416, 176245, 201695,
    207317, 202824, 226002, 176272,
    188972, 163833, 231773, 259023
  ),

  Empresa_dentro_BED = c(
    29411, 29780, 29651, 30921,
    30102, 27938, 28672, 28539,
    28132, 28668, 28883, 28351,
    27443, 27516, 27335, 27264
  )
)

# ------------------------------------------------------------
# Crear tabla
# ------------------------------------------------------------

ft <- flextable(tabla7)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  Sarek_total = "Sarek\ntotal",
  Empresa_total_GRCh38 = "Empresa total\nGRCh38",
  Empresa_dentro_BED = "Empresa dentro\ndel BED"
)

# ------------------------------------------------------------
# Formato numérico
# ------------------------------------------------------------

ft <- colformat_num(
  ft,
  j = 2:4,
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
  j = 2:4,
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
    "Tabla 7. Comparación de variantes detectadas mediante",
    "Sarek y VCF externos."
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
  target = "table_07_external_counts.docx"
)
