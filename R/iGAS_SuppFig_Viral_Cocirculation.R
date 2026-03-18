# =============================================================================
# Supplementary Figure S4: Respiratory Virus Co-Circulation Patterns
# iGAS-COVID Analysis Pipeline
# Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
#
# Produces: FigureS4_Viral_Cocirculation.pdf
#   Normalized weekly viral exposures (SD units) during pandemic period
#   Shows: SARS-CoV-2, combined influenza, influenza A, influenza B, RSV
#
# Input:  Main analysis dataset (CSV export from Stata)
#         Variables required: date, norm_sars, norm_flu, norm_flua,
#                             norm_flub, norm_rsv
#
# Justifies:
#   (1) SARS-CoV-2 dominance over other resp viruses during pandemic
#   (2) Combined flu variable approach (flu A+B move together)
#   (3) Minimal flu B circulation during pandemic period
#
# Dependencies: tidyverse
#
# Note: Input file path must be updated; original data accessed within
#       CIHI Secure Access Environment.
# =============================================================================

# SUPPLEMENTARY FIGURE S2: VIRAL CO-CIRCULATION PATTERNS
# ============================================================================
# Shows normalized weekly viral exposures during pandemic period
# Justifies: (1) SARS-CoV-2 dominance, (2) Combined flu approach, (3) Flu B exclusion
# ============================================================================

library(tidyverse)

# ============================================================================
# LOAD DATA
# ============================================================================

# Load your main dataset
data <- read.csv("path/to/your/data.csv")

# Convert date
data$date <- as.Date(data$date, format = "%d%b%Y")

# Filter to pandemic period
data <- data %>%
  filter(date >= as.Date("2020-03-01") & date <= as.Date("2024-06-06"))

# ============================================================================
# PREPARE DATA FOR PLOTTING
# ============================================================================

# Get one value per date (these are population-level, same for all age/sex)
viral_data <- data %>%
  group_by(date) %>%
  summarise(
    norm_sars = mean(norm_sars, na.rm = TRUE),
    norm_flu = mean(norm_flu, na.rm = TRUE),
    norm_flua = mean(norm_flua, na.rm = TRUE),
    norm_flub = mean(norm_flub, na.rm = TRUE),
    norm_rsv = mean(norm_rsv, na.rm = TRUE),
    .groups = "drop"
  )

# Reshape for plotting
viral_long <- viral_data %>%
  pivot_longer(
    cols = c(norm_sars, norm_flu, norm_flua, norm_flub, norm_rsv),
    names_to = "virus",
    values_to = "normalized"
  ) %>%
  mutate(
    virus = factor(virus,
                   levels = c("norm_sars", "norm_rsv", "norm_flu", "norm_flua", "norm_flub"),
                   labels = c("SARS-CoV-2", "RSV", "Influenza (Combined)", 
                              "Influenza A", "Influenza B"))
  )

# ============================================================================
# CREATE PLOT
# ============================================================================

supp_fig_s2 <- ggplot(viral_long, aes(x = date, y = normalized, color = virus)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(
    name = "",
    values = c("SARS-CoV-2" = "#377EB8",           # Blue (dominant)
               "RSV" = "#984EA3",                   # Purple
               "Influenza (Combined)" = "#E41A1C", # Red
               "Influenza A" = "#4DAF4A",          # Green
               "Influenza B" = "#FF7F00")          # Orange
  ) +
  labs(
    x = "Date",
    y = "Normalized Viral Activity (SD units)",
    title = "Supplementary Figure S2: Respiratory Virus Co-Circulation During Pandemic",
    caption = "Note: All viral measures normalized to standard deviation units for comparability.\nInfluenza B activity was minimal throughout the pandemic period, justifying use of combined influenza measure.\nSARS-CoV-2 activity substantially exceeded other respiratory viruses."
  ) +
  scale_x_date(
    breaks = seq(as.Date("2020-01-01"), as.Date("2025-01-01"), by = "1 year"),
    date_labels = "%b %Y"
  ) +
  scale_y_continuous(
    limits = c(0, NA),
    expand = expansion(mult = c(0, 0.05))
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "right",
    plot.title = element_text(face = "bold", size = 12),
    plot.caption = element_text(hjust = 0, size = 9),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

# ============================================================================
# SAVE FIGURE
# ============================================================================

ggsave("SuppFig_S2_Viral_Cocirculation.pdf", supp_fig_s2, 
       width = 12, height = 6, dpi = 300)

ggsave("SuppFig_S2_Viral_Cocirculation.png", supp_fig_s2, 
       width = 12, height = 6, dpi = 300)

# Display
print(supp_fig_s2)
