# ============================================================
# Figura 3 - Profundidad y cobertura de las regiones objetivo
# ============================================================

library(ggplot2)
library(patchwork)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

cobertura <- data.frame(
  Muestra = c(
    "AX0008", "AX0018", "AX0050", "AX22005",
    "AX22018", "AX22043", "AX22046", "AX22050",
    "AX22054", "AX23001", "AX23026", "AX23030",
    "AX23044", "AX23069", "AX23134", "AX23175"
  ),
  
  Cobertura_media = c(
    51.05, 66.76, 48.50, 40.84,
    36.51, 40.72, 49.62, 45.04,
    55.18, 52.43, 81.45, 42.57,
    67.54, 56.65, 37.96, 56.68
  ),
  
  Bases_30X = c(
    70, 78, 68, 50,
    48, 58, 69, 64,
    74, 73, 79, 56,
    74, 71, 54, 73
  )
)

# ------------------------------------------------------------
# Ordenar las muestras según cobertura media
# ------------------------------------------------------------

cobertura <- cobertura[
  order(cobertura$Cobertura_media, decreasing = TRUE),
]

cobertura$Muestra <- factor(
  cobertura$Muestra,
  levels = rev(cobertura$Muestra)
)

# ------------------------------------------------------------
# Panel A - Cobertura media
# ------------------------------------------------------------

p1 <- ggplot(
  cobertura,
  aes(x = Cobertura_media, y = Muestra)
) +
  geom_col(
    fill = "#FFA500",
    width = 0.8
  ) +
  geom_text(
    aes(
      label = paste0(
        format(
          round(Cobertura_media, 1),
          decimal.mark = ",",
          nsmall = 1
        ),
        "X"
      )
    ),
    hjust = -0.15,
    size = 3
  ) +
  scale_x_continuous(
    limits = c(0, 90),
    breaks = c(0, 25, 50, 75)
  ) +
  labs(
    x = "Cobertura media (X)",
    y = NULL
  ) +
  theme_classic(base_size = 10) +
  theme(
    axis.text.y = element_text(size = 8),
    plot.margin = margin(5, 15, 5, 5)
  )

# ------------------------------------------------------------
# Panel B - Bases cubiertas a ≥30X
# ------------------------------------------------------------

p2 <- ggplot(
  cobertura,
  aes(x = Bases_30X, y = Muestra)
) +
  geom_col(
    fill = "#87CEEB",
    width = 0.8
  ) +
  geom_text(
    aes(label = paste0(Bases_30X, "%")),
    hjust = -0.15,
    size = 3
  ) +
  scale_x_continuous(
    limits = c(0, 100),
    breaks = c(0, 25, 50, 75, 100)
  ) +
  labs(
    x = "Bases target con cobertura ≥30X (%)",
    y = NULL
  ) +
  theme_classic(base_size = 10) +
  theme(
    axis.text.y = element_text(size = 8),
    plot.margin = margin(5, 15, 5, 5)
  )

# ------------------------------------------------------------
# Unir paneles
# ------------------------------------------------------------

figura3 <- p1 + p2 +
  plot_annotation(
    tag_levels = "A"
  ) &
  theme(
    plot.tag = element_text(
      size = 13,
      face = "plain"
    )
  )

# Mostrar figura
figura3

# ------------------------------------------------------------
# Guardar figura
# ------------------------------------------------------------

ggsave(
  filename = "figure_03_coverage.png",
  plot = figura3,
  width = 10,
  height = 5,
  units = "in",
  dpi = 600,
  bg = "white"
)
