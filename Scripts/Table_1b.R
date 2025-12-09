library(gt)
library(gtExtras)

dt <- read_csv("Data/table_effects.csv")

dt %>% 
  gt() %>% 
  gt_theme_538() %>% 
  fmt_missing(
    columns = everything(),  # or specify columns like c(donation, cohens_d)
    missing_text = ""
  ) %>% 
  tab_style(
    style = cell_text(align = "center"),
    locations = list(
      cells_body(),
      cells_column_labels()
    )
  ) 
