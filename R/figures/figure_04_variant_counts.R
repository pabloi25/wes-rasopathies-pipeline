# ============================================================
# Figura 4 - Comparación del número de variantes detectadas
# ============================================================

library(ggplot2)
library(scales)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

datos <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175"
  ),

  Sarek = c(
    29912, 30336, 30206, 29428,
    29433, 29310, 30452, 29814,
    29890, 30315, 30641, 30020,
    29025, 29075, 28375, 28616
  ),

  VCF_externo = c(
    29411, 29780, 29651, 30921,
    30102, 27938, 28672, 28539,
    28132, 28668, 28883, 28351,
    27443, 27516, 27335, 27264
  )
)

# Mantener el orden de las muestras
datos$Muestra <- factor(
  datos$Muestra,
  levels = datos$Muestra
)

# ------------------------------------------------------------
# Pasar a formato largo
# ------------------------------------------------------------

datos_long <- rbind(
  data.frame(
    Muestra = datos$Muestra,
    Metodo = "Pipeline local (Sarek)",
    Variantes = datos$Sarek
  ),

  data.frame(
    Muestra = datos$Muestra,
    Metodo = "VCF externo",
    Variantes = datos$VCF_externo
  )
)

# ------------------------------------------------------------
# Figura
# ------------------------------------------------------------

figura4 <- ggplot(
  datos_long,
  aes(
    x = Muestra,
    y = Variantes,
    group = Metodo,
    color = Metodo
  )
) +

  geom_line(
    linewidth = 0.8
  ) +

  geom_point(
    size = 2.5
  ) +

  scale_color_manual(
    values = c(
      "Pipeline local (Sarek)" = "#F8766D",
      "VCF externo" = "#00BFC4"
    )
  ) +

  scale_y_continuous(
    limits = c(25000, 32300),
    breaks = seq(25000, 32000, by = 1000),
    labels = label_number(
      big.mark = ".",
      decimal.mark = ","
    )
  ) +

  labs(
    title = "Comparación del número de variantes detectadas",
    subtitle = paste(
      "Variantes localizadas dentro de las regiones target",
      "del kit SureSelect All Exon V6"
    ),
    x = "Muestras",
    y = "Número de variantes",
    color = NULL
  ) +

  theme_minimal(base_size = 11) +

  theme(
    plot.title = element_text(
      face = "bold",
      size = 15
    ),

    plot.subtitle = element_text(
      size = 10
    ),

    axis.text.x = element_text(
      angle = 45,
      hjust = 1,
      size = 8
    ),

    axis.text.y = element_text(
      size = 9
    ),

    legend.position = "top",

    legend.justification = "center",

    panel.grid.minor = element_blank(),

    plot.margin = margin(
      10, 10, 10, 10
    )
  )

# Mostrar figura
figura4

# ------------------------------------------------------------
# Guardar
# ------------------------------------------------------------

ggsave(
  filename = "figure_04_variant_counts.png",
  plot = figura4,
  width = 10,
  height = 6,
  units = "in",
  dpi = 600,
  bg = "white"
)
