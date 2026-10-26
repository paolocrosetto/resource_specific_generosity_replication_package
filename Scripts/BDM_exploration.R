## analysing the distribution of WTP bids
## across resouces

bdm <- s1 |> 
  select(ID, period, resource, donation, bid, desirability) |> 
  arrange(ID) |> 
  filter(resource != "Money")

# means and standard deviations for text
bdm |> 
  group_by(resource) |> 
  summarise(mean_wtp = mean(bid), 
            sd_wtp = sd(bid)) |> 
  arrange(-mean_wtp)

# Table 6 -- sharing contingent on grouped valuations

money_donated <- s1 |> 
  filter(resource == "Money") |> 
  select(ID, money_donated = donation)

categories <- bdm |> 
  mutate(valuation = case_when( bid == 0 ~ "WTP = 0", 
                                bid > 0 & bid <= 0.9 ~ "WTP < 1", 
                                bid > 0.9 & bid <= 1.1 ~ "WTP ~ 1", 
                                bid > 1.1 ~ "WTP > 1")) |> 
  mutate(valuation = as.factor(valuation), 
         valuation = fct_relevel(valuation, "WTP = 0", "WTP < 1", "WTP ~ 1")) |> 
  left_join(money_donated, by = join_by(ID))

add_me <- categories |> 
  group_by(valuation) |> 
  summarise(m = mean(money_donated)) |> 
  mutate(m = sprintf("%.2f", m)) %>% 
  pivot_wider(names_from = valuation, values_from = m) |> 
  mutate(resource = "Money")

g <- categories |> 
  group_by(resource, valuation) |> 
  summarise(m = mean(donation), 
            n = n()) |> 
  mutate(dat = paste0(sprintf("%.2f", m),
                      " <span style='font-size:75%; color:#888;'>(N = ", n, ")</span>")) %>% 
  select(-m, -n) %>% 
  pivot_wider(names_from = valuation, values_from = dat) |> 
  bind_rows(add_me) |> 
  arrange(`WTP = 0`) |> 
  ungroup() |> 
  gt() |> 
  fmt_passthrough(columns = -resource, escape = FALSE) |> 
  tab_style(
    style = cell_text(weight = "bold"),
    locations = cells_body(rows = resource == "Money")
  ) |> 
  cols_label(resource = "") %>% 
  tab_spanner(columns = -resource, "Amount shared by valuation of the non-monetary resource")

gtsave(g, "Tables/Table_6.docx")
gtsave(g, "Tables/Table_6.png")

# Table 7: regressions to investigate role of WTP

res <- sort(unique(bdm$resource))

g <- bdm %>%
  group_by(resource) %>%
  group_map(~ list(
    lm(donation ~ bid, data = .x),
    lm(donation ~ bid + desirability, data = .x)
  )) |>
  purrr::list_flatten() |>
  modelsummary::modelsummary(
    stars       = TRUE,
    coef_rename = c("bid" = "WTP", 
                    "(Intercept)" = "Constant"),
    output      = "gt"
  )

for (k in seq_along(res)) g <- tab_spanner(g, label = res[k], columns = 2 * k + 0:1)
g <- cols_label(g, everything() ~ "")

# saving the table
gtsave(g, "Tables/Table_7.docx")
gtsave(g, "Tables/Table_7.png")






