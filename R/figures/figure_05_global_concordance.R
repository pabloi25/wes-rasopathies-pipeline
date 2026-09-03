# ============================================================
# Figura 5 - Concordancia global de variantes
# ============================================================

library(ggplot2)
library(scales)

# ------------------------------------------------------------
# Datos
# ------------------------------------------------------------

datos <- data.frame(
  Categoria = c(
    "Compartidas",
    "Solo pipeline local",
    "Solo VCF externo"
  ),
  
  Variantes = c(
    436210,
    39935,
    23228
  )
)

# Orden de las categorías en la figura
datos$Categoria <- factor(
  datos$Categoria,
  levels = c(
    "Solo VCF externo",
    "Solo pipeline local",
    "Compartidas"
  )
)

# ------------------------------------------------------------
# Figura
# ------------------------------------------------------------

figura5 <- ggplot(
  datos,
  aes(
    x = Variantes,
    y = Categoria,
    fill = Categoria
  )
) +
  
  geom_col(
    width = 0.58
  ) +
  
  geom_text(
    aes(
      label = label_number(
        big.mark = ".",
        decimal.mark = ",",
        accuracy = 1
      )(Variantes)
    ),
    hjust = -0.15,
    size = 4.2,
    fontface = "bold"
  ) +
  
  scale_fill_manual(
    values = c(
      "Compartidas" = "#7CAE00",
      "Solo pipeline local" = "#F8766D",
      "Solo VCF externo" = "#00BFC4"
    )
  ) +
  
  scale_x_continuous(
    limits = c(0, 520000),
    breaks = seq(0, 500000, by = 100000),
    labels = label_number(
      big.mark = ".",
      decimal.mark = ",",
      accuracy = 1
    ),
    expand = expansion(mult = c(0, 0))
  ) +
  
  scale_y_discrete(
    expand = expansion(add = c(0.7, 0.3))
  ) +
  
  annotate(
    "text",
    x = 500000,
    y = 0.55,
    label = "Índice de Jaccard global = 87,35 %",
    hjust = 1,
    size = 4,
    fontface = "italic"
  ) +
  
  labs(
    x = "Número de variantes",
    y = NULL
  ) +
  
  theme_minimal(base_size = 11) +
  
  theme(
    legend.position = "none",
    
    axis.text.y = element_text(
      size = 11,
      face = "bold"
    ),
    
    axis.text.x = element_text(
      size = 9
    ),
    
    axis.title.x = element_text(
      size = 11
    ),
    
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank(),
    
    plot.margin = margin(
      15, 25, 15, 15
    )
  )

# Mostrar figura
figura5

# ------------------------------------------------------------
# Guardar
# ------------------------------------------------------------

ggsave(
  filename = "figure_05_global_concordance.png",
  plot = figura5,
  width = 10,
  height = 5.5,
  units = "in",
  dpi = 600,
  bg = "white"
)
