# ============================================================
# Tabla 11 - Priorización y clasificación de variantes
# ============================================================

library(flextable)
library(officer)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

tabla11 <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175"
  ),

  Gen = c(
    "SOS1", "PTPN11", "PTPN11", "NF1",
    "PTPN11", "—", "PTPN11", "RIT1",
    "RAF1", "PTPN11", "RIT1", "SOS1",
    "—", "SOS1", "NF1", "—"
  ),

  Variante = c(
    "c.2536G>A\np.Glu846Lys",
    "c.1510A>G\np.Met504Val",
    "c.214G>T\np.Ala72Ser",
    "c.888+1G>A",
    "c.106A>G\np.Tyr279Cys",
    "—",
    "c.188A>G\np.Tyr63Cys",
    "c.284G>C\np.Gly95Ala",
    "c.1457A>G\np.Asp486Gly",
    "c.923A>G\np.Asn308Ser",
    "c.246T>A\np.Phe82Leu",
    "c.1432C>T\np.Pro478Ser",
    "—",
    "c.1432C>T\np.Pro478Ser",
    "c.5488C>T\np.Arg1830Cys",
    "—"
  ),

  Clasificacion_local = c(
    "VUS",
    "Patogénica",
    "Patogénica",
    "Patogénica",
    "Probablemente patogénica",
    "Sin candidata",
    "Patogénica",
    "Probablemente patogénica",
    "Patogénica",
    "Patogénica",
    "Patogénica",
    "VUS",
    "Sin candidata",
    "VUS",
    "Patogénica",
    "Sin candidata"
  ),

  Clasificacion_externa = c(
    "Probablemente patogénica",
    "Patogénica",
    "Probablemente patogénica",
    "Patogénica",
    "Probablemente patogénica",
    "Sin candidata",
    "Patogénica",
    "Probablemente patogénica",
    "Probablemente patogénica",
    "Probablemente patogénica",
    "Patogénica",
    "Probablemente patogénica",
    "Sin candidata",
    "Probablemente patogénica",
    "Patogénica",
    "Sin candidata"
  ),

  Concordancia = c(
    "No", "Sí", "No", "Sí",
    "Sí", "Sí", "Sí", "Sí",
    "No", "No", "Sí", "No",
    "Sí", "No", "Sí", "Sí"
  ),

  stringsAsFactors = FALSE
)

# ------------------------------------------------------------
# Crear tabla
# ------------------------------------------------------------

ft <- flextable(tabla11)

ft <- set_header_labels(
  ft,
  Muestra = "Muestra",
  Gen = "Gen",
  Variante = "Variante",
  Clasificacion_local = "Clasificación\nlocal",
  Clasificacion_externa = "Clasificación\nexterna",
  Concordancia = "Concordancia"
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
  j = c("Muestra", "Gen"),
  align = "left",
  part = "all"
)

ft <- align(
  ft,
  j = c(
    "Variante",
    "Clasificacion_local",
    "Clasificacion_externa",
    "Concordancia"
  ),
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
    "Tabla 11. Priorización y clasificación de las",
    "variantes genéticas priorizadas."
  )
)

# ------------------------------------------------------------
# Nota al pie
# ------------------------------------------------------------

ft <- add_footer_lines(
  ft,
  values = paste(
    "La concordancia refiere a la coincidencia de la categoría de",
    "clasificación entre ambos análisis. En AX23069, el análisis local",
    "priorizó adicionalmente una variante VUS en RASA2",
    "(c.4GCG[3]; p.Ala5del), no identificada como candidata",
    "en el análisis externo."
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
  target = "table_11_variant_prioritization.docx"
)
