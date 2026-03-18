# =============================================================================
# Figure 2: Forest Plot of SARS-CoV-2 Associations with iGAS
# iGAS-COVID Analysis Pipeline
# Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
#
# Produces: Figure2_Forest_Plot.pdf
#   Panel A: Acute-only IRRs (per 1-SD increase in 2-week lagged SARS-CoV-2)
#            by age group and pandemic period
#   Panel B: Cumulative SARS-CoV-2 IRRs from joint acute+cumulative models
#            by age group and pandemic period
#
# Input:  forest_plot_data_complete.csv
#         (IRR, 95% CI, p-value for each model/period/age group combination)
#
# Data file columns:
#   Panel, Period, Age_Group, Model_Type, IRR, CI_Lower, CI_Upper, P_Value
#
# Dependencies: ggplot2, dplyr, patchwork
# =============================================================================

# iGAS-COVID Figure 2: Forest Plot of COVID-19 Effects
# ============================================================================
# Panel A: Acute-only effects (P1 vs P2, by age)
# Panel B: Cumulative effects from joint models (P1 vs P2, by age)
# ============================================================================

library(ggplot2)
library(dplyr)
library(patchwork)

# ============================================================================
# LOAD DATA
# ============================================================================

# Load the complete forest plot data
forest_data <- read.csv("~/Dropbox/CIHR RSV:Flu:COVID/IGAS manuscript/Figures/Forest plot/forest_plot_data_complete.csv", stringsAsFactors = FALSE)

# Clean up and prepare data
forest_data <- forest_data %>%
  mutate(
    # Create cleaner age group labels
    Age_Group = factor(Age_Group, 
                       levels = c("Overall", "Pediatric (0-19)", "Adults (20-64)", "Elderly (≥65)")),
    # Create period labels
    Period = factor(Period, levels = c("P1", "P2"),
                    labels = c("Period 1\n(Mar 2020-Aug 2022)", 
                               "Period 2\n(Sep 2022-Mar 2024)"))
  )
    # Add significance markers
    # Add significance markers - handle string p-values
   # Sig = case_when(
    #  P_Value == "<0.001" ~ "***",
     # TRUE ~ {
      #  p_num <- suppressWarnings(as.numeric(P_Value))
       # case_when(
        #  is.na(p_num) ~ "",
         # p_num < 0.001 ~ "***",
          #p_num < 0.01 ~ "**",
          #p_num < 0.05 ~ "*",
          #TRUE ~ ""
        #)
      #}
    #)

# ============================================================================
# PANEL A: ACUTE-ONLY EFFECTS
# ============================================================================

plot_acute <- forest_data %>%
  filter(Panel == "A") %>%
  ggplot(aes(x = IRR, y = Age_Group, color = Period, shape = Period)) +
  # Reference line at IRR = 1.0
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50", linewidth = 0.5) +
  # Confidence intervals
  geom_errorbarh(aes(xmin = CI_Lower, xmax = CI_Upper), 
                 height = 0.2, linewidth = 0.8,
                 position = position_dodge(width = 0.5)) +
  # Point estimates
  geom_point(size = 3, position = position_dodge(width = 0.5)) +
  # Scale and labels
  scale_x_log10(
    breaks = c(0.5, 0.75, 1.0, 1.5, 2.0, 2.5),
    labels = c("0.5", "0.75", "1.0", "1.5", "2.0", "2.5")
  ) +
  scale_color_manual(
    name = "",
    values = c("Period 1\n(Mar 2020-Aug 2022)" = "#377EB8", 
               "Period 2\n(Sep 2022-Mar 2024)" = "#E41A1C")
  ) +
  scale_shape_manual(
    name = "",
    values = c("Period 1\n(Mar 2020-Aug 2022)" = 16, 
               "Period 2\n(Sep 2022-Mar 2024)" = 17)
  ) +
  labs(
    x = "Incidence Rate Ratio (IRR)",
    y = "",
    title = "A. Acute SARS-CoV-2 Effects"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    plot.title = element_text(face = "bold", size = 12),
    axis.text.y = element_text(size = 10),
    panel.grid.major.x = element_line(color = "gray90", linewidth = 0.3)
  )

# ============================================================================
# PANEL B: CUMULATIVE EFFECTS
# ============================================================================

plot_cumulative <- forest_data %>%
  filter(Panel == "B") %>%
  ggplot(aes(x = IRR, y = Age_Group, color = Period, shape = Period)) +
  # Reference line at IRR = 1.0
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50", linewidth = 0.5) +
  # Confidence intervals
  geom_errorbarh(aes(xmin = CI_Lower, xmax = CI_Upper), 
                 height = 0.2, linewidth = 0.8,
                 position = position_dodge(width = 0.5)) +
  # Point estimates
  geom_point(size = 3, position = position_dodge(width = 0.5)) +
  # Scale and labels
  scale_x_log10(
    breaks = c(0.95, 1.0, 1.1, 1.2, 1.3),
    labels = c("0.95", "1.0", "1.1", "1.2", "1.3")
  ) +
  scale_color_manual(
    name = "",
    values = c("Period 1\n(Mar 2020-Aug 2022)" = "#377EB8", 
               "Period 2\n(Sep 2022-Mar 2024)" = "#E41A1C")
  ) +
  scale_shape_manual(
    name = "",
    values = c("Period 1\n(Mar 2020-Aug 2022)" = 16, 
               "Period 2\n(Sep 2022-Mar 2024)" = 17)
  ) +
  labs(
    x = "Incidence Rate Ratio (IRR)",
    y = "",
    title = "B. Cumulative SARS-CoV-2 Effects",
    subtitle = "From joint models (acute + cumulative); ΔAIC = -157.5 favoring cumulative"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 9),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(size = 9, color = "gray30"),
    axis.text.y = element_text(size = 10),
    panel.grid.major.x = element_line(color = "gray90", linewidth = 0.3)
  )

# ============================================================================
# COMBINE PANELS
# ============================================================================

figure2 <- plot_acute + plot_cumulative +
  plot_layout(ncol = 2, guides = "collect") &
  theme(legend.position = "bottom")

# ============================================================================
# SAVE FIGURE
# ============================================================================

ggsave("Figure2_Forest_Plot.pdf", figure2, width = 14, height = 8)
ggsave("Figure2_Forest_Plot.png", figure2, width = 14, height = 8)
# ============================================================================
# INTERPRETATION NOTES
# ============================================================================

cat("\n=== FIGURE 2 KEY FINDINGS ===\n\n")

cat("PANEL A - ACUTE EFFECTS:\n")
cat("- P1: Weak/null effects (low COVID circulation)\n")
cat("  - Overall: 1.11 (barely significant)\n")
cat("  - Pediatric: 0.87 (null, protected by NPIs)\n")
cat("  - Adults: 1.18* (only significant group)\n")
cat("  - Elderly: 1.08 (null)\n\n")

cat("- P2: Strong effects across all groups (high circulation)\n")
cat("  - Overall: 1.91***\n")
cat("  - Pediatric: 1.78***\n")
cat("  - Adults: 1.94***\n")
cat("  - Elderly: 1.99*** (highest acute effect)\n\n")

cat("PANEL B - CUMULATIVE EFFECTS:\n")
cat("- P1: ALL NULL (low cumulative burden yet)\n")
cat("  - All IRRs near 1.0, none significant\n")
cat("  - Confirms minimal cumulative burden in P1\n\n")

cat("- P2: Strong effects, biological gradient\n")
cat("  - Pediatric: 1.27*** (HIGHEST - most vulnerable)\n")
cat("  - Overall: 1.19***\n")
cat("  - Adults: 1.18***\n")
cat("  - Elderly: 1.19***\n\n")

cat("KEY MESSAGE:\n")
cat("Cumulative burden effects EMERGE over time (null P1 → strong P2)\n")
cat("This supports progressive immune dysfunction hypothesis\n")
cat("Children show strongest cumulative effect → greatest vulnerability\n")
cat("Cumulative model decisively superior (ΔAIC = -157.5)\n")

# ============================================================================
# END OF SCRIPT
# ============================================================================

