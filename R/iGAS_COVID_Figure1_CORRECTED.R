# =============================================================================
# Figure 1: Temporal Trends in iGAS Incidence
# iGAS-COVID Analysis Pipeline
# Fisman DN, Lee CE, Wilson NJ, Barton-Forbes M, Mann SK, Tuite AR
#
# Produces: Figure1_Temporal_Trends.pdf
#   Panel A: Overall weekly iGAS incidence per 100,000 (2011-2024)
#            with shaded pandemic periods and fitted seasonal trend
#   Panel B: Age-stratified incidence (0-19, 20-64, >=65 years)
#
# Input:  Stata analysis dataset exported to CSV from CIHI SAE
#         Variables required: date, week_igas, week_pop, age2/age_group,
#                             gender2, pandemic1, pandemic2
#
# Dependencies: ggplot2, dplyr, lubridate, patchwork, scales
#
# Notes:
#   - pandemic2 coded as -1 in exported dataset (not 1)
#   - age2 renamed to age_group on import
#   - Population aggregated across age/sex BEFORE incidence calculation
#     to avoid 6 overlapping lines in Panel A
# =============================================================================

# iGAS-COVID Manuscript Figure 1 - CORRECTED VERSION
# ============================================================================
# This code generates Figure 1 with proper population aggregation
# 
# KEY FIXES:
# 1. plot_temporal_overall now aggregates across age/gender before calculating incidence
# 2. pandemic2 comparison uses == -1 (not == 1) to match your data
# 3. Handles age2 variable renaming to age_group
# ============================================================================

# Load required packages
library(ggplot2)
library(dplyr)
library(lubridate)
library(patchwork)
library(scales)

# Set theme for all plots
theme_set(theme_bw(base_size = 12))

# ============================================================================
# FIGURE 1: TEMPORAL TRENDS IN iGAS INCIDENCE
# ============================================================================

# Panel A: Overall weekly incidence - CORRECTED
# Now properly aggregates across all age groups and gender
plot_temporal_overall <- function(data) {
  
  # FIRST: Aggregate cases and population across all age/gender groups
  data <- data %>%
    group_by(date) %>%
    summarise(
      total_cases = sum(week_igas),
      total_pop = sum(week_pop),
      pandemic1 = first(pandemic1),  # Same value for all groups on a date
      pandemic2 = first(pandemic2),
      .groups = "drop"
    ) %>%
    # THEN: Calculate incidence on aggregated data
    mutate(
      incidence_100k = (total_cases / total_pop) * 100000,
      period = case_when(
        pandemic1 == 1 ~ "Pandemic 1",
        pandemic2 == -1 ~ "Pandemic 2",  # FIXED: -1, not 1
        TRUE ~ "Pre-pandemic"
      )
    )
  
  # Create plot
  p <- ggplot(data, aes(x = date, y = incidence_100k)) +
    # Shaded regions for pandemic periods
    annotate("rect", 
             xmin = as.Date("2020-03-01"), 
             xmax = as.Date("2022-08-31"),
             ymin = -Inf, ymax = Inf, 
             fill = "lightblue", alpha = 0.2) +
    annotate("rect", 
             xmin = as.Date("2022-09-01"), 
             xmax = as.Date("2024-03-31"),
             ymin = -Inf, ymax = Inf, 
             fill = "orange", alpha = 0.2) +
    # Observed incidence line
    geom_line(linewidth = 0.7, color = "black") +
    # Smoothed trend
    geom_smooth(method = "loess", span = 0.1, 
                se = TRUE, color = "red", linewidth = 0.5,
                linetype = "dashed") +
    # Labels and formatting
    labs(
      x = "Date",
      y = "iGAS Incidence\n(per 100,000 population per week)",
      title = "A. Overall Population"
    ) +
    scale_x_date(
      breaks = seq(as.Date("2011-01-01"), as.Date("2024-12-31"), by = "2 years"),
      date_labels = "%Y"
    ) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold")
    )
  
  return(p)
}

# Panel B: Age-stratified trends - ALREADY CORRECT
# This properly aggregates within each age group
plot_temporal_age <- function(data) {
  
  # Calculate incidence by age group (aggregates across gender)
  data <- data %>%
    group_by(date, age_group) %>%
    summarise(
      total_cases = sum(week_igas),
      total_pop = sum(week_pop),
      .groups = "drop"
    ) %>%
    mutate(incidence_100k = (total_cases / total_pop) * 100000)
  
  p <- ggplot(data, aes(x = date, y = incidence_100k, color = age_group)) +
    # Shaded regions
    annotate("rect", 
             xmin = as.Date("2020-03-01"), 
             xmax = as.Date("2022-08-31"),
             ymin = -Inf, ymax = Inf, 
             fill = "lightblue", alpha = 0.1) +
    annotate("rect", 
             xmin = as.Date("2022-09-01"), 
             xmax = as.Date("2024-03-31"),
             ymin = -Inf, ymax = Inf, 
             fill = "orange", alpha = 0.1) +
    # Lines by age group
    geom_line(linewidth = 0.8) +
    # Color palette
    scale_color_manual(
      name = "Age Group",
      values = c("0-19" = "#E41A1C", "20-64" = "#377EB8", "65+" = "#4DAF4A"),
      labels = c("0-19 years", "20-64 years", "≥65 years")
    ) +
    labs(
      x = "Date",
      y = "iGAS Incidence\n(per 100,000 per week)",
      title = "B. Age-Stratified"
    ) +
    scale_x_date(
      breaks = seq(as.Date("2011-01-01"), as.Date("2024-12-31"), by = "2 years"),
      date_labels = "%Y"
    ) +
    theme(
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold")
    )
  
  return(p)
}

# ============================================================================
# GENERATE FIGURE 1
# ============================================================================

# Example usage:
# Assumes you have loaded your data as 'data'

# Prepare data with correct column names
data_age <- data %>%
  rename(age_group = age2)  # Rename to match what function expects

# Generate combined figure
figure1 <- plot_temporal_overall(data) / plot_temporal_age(data_age)

# Save as PDF
ggsave("Figure1_Temporal_Trends.pdf", figure1, width = 10, height = 8)

# ============================================================================
# KEY DIFFERENCES FROM ORIGINAL:
# 
# 1. plot_temporal_overall: 
#    - Now does group_by(date) and sums cases/population BEFORE calculating incidence
#    - This gives true overall incidence, not 6 overlapping lines
#
# 2. pandemic2 comparison:
#    - Changed from pandemic2 == 1 to pandemic2 == -1 to match your data
#
# 3. Data preparation:
#    - Added rename step to convert age2 to age_group
# ============================================================================
