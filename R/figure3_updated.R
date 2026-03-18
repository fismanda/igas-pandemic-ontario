# =============================================================================
# Figure 3: Population Attributable Fractions for SARS-CoV-2 Effects
# iGAS-COVID Analysis Pipeline
# Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
#
# Produces: Figure3_PAF.pdf
#   Panel A: Acute-only counterfactual
#            Observed model prediction vs. counterfactual (SARS-CoV-2=0)
#            Acute PAF = 34.3% overall pandemic
#   Panel B: Acute + cumulative counterfactual
#            Cumulative PAF = 66.7% overall pandemic
#
# Input:  counterfactual set.csv
#         Exported from Stata after running Section 11 of 07_analysis.do
#         Variables: date, total_obs, total_cf, total_obs_ac, total_cf_ac
#         One row per date (summed across age/sex panels in Stata)
#
# Dependencies: ggplot2, dplyr, patchwork, tidyr
#
# Note: File path to input data must be updated; original path was
#       within CIHI SAE and is not accessible externally.
# =============================================================================

#Figure 3: Population Attributable Fractions
#Updated with acute-only and acute+cumulative counterfactuals

library(ggplot2)
library(dplyr)
library(patchwork)
library(tidyr)

#*************************************
#* READ DATA
#*************************************

data <- read.csv("~/data/1907/Shared/DF IGAS/Data files/counterfactual set.csv")
data$date <- as.Date(data$date, format = "%d%b%Y")

# Keep one row per date (data repeated across PHUs)
data <- data %>%
  distinct(date, .keep_all = TRUE) %>%
  filter(date >= as.Date("2020-03-31") & date <= as.Date("2024-06-06"))

#*************************************
#* PANEL A: ACUTE-ONLY COUNTERFACTUAL
#*************************************

data_a <- data %>%
  select(date, total_obs, total_cf) %>%
  pivot_longer(
    cols = c(total_obs, total_cf),
    names_to = "series",
    values_to = "cases"
  ) %>%
  mutate(
    series = factor(series,
                    levels = c("total_obs", "total_cf"),
                    labels = c("Model Prediction\n(with SARS-CoV-2)",
                               "Counterfactual\n(without SARS-CoV-2)"))
  )

panel_a <- ggplot(data_a, aes(x = date, y = cases, color = series)) +
  annotate("rect",
           xmin = as.Date("2020-03-31"),
           xmax = as.Date("2022-08-31"),
           ymin = -Inf, ymax = Inf,
           fill = "lightblue", alpha = 0.3) +
  annotate("rect",
           xmin = as.Date("2022-09-01"),
           xmax = as.Date("2024-06-06"),
           ymin = -Inf, ymax = Inf,
           fill = "orange", alpha = 0.3) +
  geom_line(linewidth = 1) +
  scale_color_manual(
    name = "",
    values = c("Model Prediction\n(with SARS-CoV-2)" = "red",
               "Counterfactual\n(without SARS-CoV-2)" = "blue")
  ) +
  labs(
    x = "Date",
    y = "Weekly iGAS Cases",
    title = "A. Acute Effects Only",
    subtitle = "Overall Population (PAF = 34.3%)"
  ) +
  scale_x_date(
    breaks = seq(as.Date("2020-01-01"), as.Date("2025-01-01"), by = "1 year"),
    date_labels = "%Y"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(size = 10, color = "gray30")
  )

#*************************************
#* PANEL B: ACUTE + CUMULATIVE COUNTERFACTUAL
#*************************************

data_b <- data %>%
  select(date, total_obs_ac, total_cf_ac) %>%
  pivot_longer(
    cols = c(total_obs_ac, total_cf_ac),
    names_to = "series",
    values_to = "cases"
  ) %>%
  mutate(
    series = factor(series,
                    levels = c("total_obs_ac", "total_cf_ac"),
                    labels = c("Model Prediction\n(with SARS-CoV-2)",
                               "Counterfactual\n(without SARS-CoV-2)"))
  )

panel_b <- ggplot(data_b, aes(x = date, y = cases, color = series)) +
  annotate("rect",
           xmin = as.Date("2020-03-31"),
           xmax = as.Date("2022-08-31"),
           ymin = -Inf, ymax = Inf,
           fill = "lightblue", alpha = 0.3) +
  annotate("rect",
           xmin = as.Date("2022-09-01"),
           xmax = as.Date("2024-06-06"),
           ymin = -Inf, ymax = Inf,
           fill = "orange", alpha = 0.3) +
  geom_line(linewidth = 1) +
  scale_color_manual(
    name = "",
    values = c("Model Prediction\n(with SARS-CoV-2)" = "red",
               "Counterfactual\n(without SARS-CoV-2)" = "blue")
  ) +
  labs(
    x = "Date",
    y = "Weekly iGAS Cases",
    title = "B. Acute + Cumulative Effects",
    subtitle = "Overall Population (PAF = 66.7%)"
  ) +
  scale_x_date(
    breaks = seq(as.Date("2020-01-01"), as.Date("2025-01-01"), by = "1 year"),
    date_labels = "%Y"
  ) +
  theme_classic(base_size = 12) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold"),
    plot.subtitle = element_text(size = 10, color = "gray30")
  )

#*************************************
#* PANEL C: AGE-STRATIFIED PAF BARS
#*************************************

paf_data <- data.frame(
  age_group = rep(c("Overall", "0-19 years", "20-64 years", "65+ years"), 2),
  model = c(rep("Acute Only", 4), rep("Acute +\nCumulative", 4)),
  paf = c(34.3, 16.5, 32.6, 39.1,
          66.7, 98.5, 65.5, 96.1)
)

paf_data$age_group <- factor(paf_data$age_group,
                              levels = c("Overall", "0-19 years", "20-64 years", "65+ years"))
paf_data$model <- factor(paf_data$model,
                          levels = c("Acute Only", "Acute +\nCumulative"))

panel_c <- ggplot(paf_data, aes(x = age_group, y = paf, fill = model)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6, alpha = 0.85) +
  geom_text(aes(label = sprintf("%.1f%%", paf)),
            position = position_dodge(width = 0.7),
            vjust = -0.5, size = 3.5, fontface = "bold") +
  scale_fill_manual(
    name = "",
    values = c("Acute Only" = "#377EB8",
               "Acute +\nCumulative" = "#E41A1C")
  ) +
  labs(
    x = "Age Group",
    y = "Population Attributable Fraction (%)",
    title = "C. Age-Stratified Attributable Fractions"
  ) +
  scale_y_continuous(limits = c(0, 110), expand = c(0, 0)) +
  theme_classic(base_size = 12) +
  theme(
    panel.grid.major.x = element_blank(),
    plot.title = element_text(face = "bold"),
    axis.text.x = element_text(angle = 0, hjust = 0.5),
    legend.position = "bottom"
  )

#*************************************
#* COMBINE PANELS
#*************************************

figure3 <- ((panel_a + panel_b) / panel_c) +
  plot_layout(heights = c(1, 0.8), guides = "collect") &
  theme(legend.position = "bottom")

#*************************************
#* SAVE
#*************************************

ggsave("Figure3_PAF.pdf", figure3, width = 14, height = 10)
ggsave("Figure3_PAF.png", figure3, width = 14, height = 10, dpi = 300)
