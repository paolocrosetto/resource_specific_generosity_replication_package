##
## Resource-dependent generosity
##
##
## Replication Package
##
## This version: 0.1, 11 Nov 2024
##
##
## This file generates Table 1 from the paper

## this file:
##
## - computes the distance in perc pints (linear distance) between money and all other resources by study
## - generates a table and a plot of that


#### computing ####

# compute a money-t-each-of-other distance by subject 
# this can be done only for studies 1 to 5 but not 4, as 4 is between-subjects

distance_to_money_ind <- df %>% 
  mutate(share = donation/pie) %>% 
  select(ID, study, resource, share) %>% 
  pivot_wider(names_from = resource, values_from = share) %>% 
  group_by(ID, study) %>% 
  mutate(across(everything(), ~ - Money + .x)) %>% 
  pivot_longer(-ID & -study, names_to = "resource", values_to = "diff") %>% 
  filter(!is.na(diff)) %>% 
  filter(resource != "Money")

distance_to_money <- distance_to_money_ind %>% 
  group_by(study, resource) %>% 
  summarise(m = mean(diff), 
            sem = sd(diff)/sqrt(n())) %>% 
  mutate(cil = m - 1.96*sem,
         cih = m + 1.96*sem) %>% 
  select(study, resource, diff = m, cil, cih) 

# study 4, 7, S1 and S2 are between-subjects, 
# so we compute first the mean, then subtract, and then build conf int afterwards

distance_to_money_between <- function(stud) {
  df %>% 
    filter(study == stud) %>% 
    mutate(share = donation/pie) %>% 
    select(ID, study, resource, share) %>% 
    group_by(study, resource) %>% 
    summarise(m = mean(share), 
              sd = sd(share), 
              n = n()) %>% 
    mutate(m_money = .$m[.$resource == "Money"], 
           sd_money = .$sd[.$resource == "Money"],
           n_money = .$n[.$resource == "Money"]) %>% 
    mutate(diff = - m_money + m, 
           cil = m - m_money - 1.96*sqrt(sd/n + sd/n_money),
           cih = m - m_money + 1.96*sqrt(sd/n + sd/n_money)) %>% 
    select(study, resource, diff, cil, cih) %>% 
    filter(resource != "Money")
}

dist_s4 <- distance_to_money_between("Study 4")
dist_s7 <- distance_to_money_between("Study 7")
dist_sS1 <- distance_to_money_between("Study S1")
dist_sS2 <- distance_to_money_between("Study S2")



# merge the two
distance_to_money <- distance_to_money %>% 
  bind_rows(dist_s4) %>% 
  bind_rows(dist_s7) %>% 
  bind_rows(dist_sS1) %>% 
  bind_rows(dist_sS2) %>% 
  mutate(resource = as.factor(resource)) %>% 
  group_by(study) %>% 
  mutate(resource = fct_reorder(resource,-diff)) %>% 
  arrange(study, resource)


# share of money to self
share_money_self <- df %>% 
  filter(resource == "Money") %>% 
  mutate(share_self = donation/pie) %>% 
  group_by(study) %>% 
  summarise(share_self = mean(share_self)) %>% 
  mutate(share_self = paste0(100*round(share_self,3), "%"))

# computing cohen's d for each study and each contrast

cohens_d_results <- df %>%
  filter(!is.na(donation)) %>%
  mutate(resource = factor(resource)) %>%  
  group_by(study) %>%
  group_modify(~ {
    data_study <- .x

    # Extract Money donations
    donations_money <- data_study %>%
      filter(resource == "Money") %>%
      pull(donation)

    # For each non-Money resource, compute Cohen's d vs. Money
    data_study %>%
      filter(resource != "Money") %>%
      group_by(resource) %>%
      summarise(
        cohens_d = {
          donations_other <- donation
          d <- cohens_d(
            c(donations_money, donations_other),
            c(rep("Money", length(donations_money)),
              rep(resource[1], length(donations_other)))
          )
          d$Cohens_d %>% as.numeric()
        },
        .groups = "drop"
      )
  })

p_values <- df %>%
  filter(!is.na(donation)) %>%
  mutate(resource = factor(resource)) %>% 
  group_by(study) %>%
  group_modify(~ {
    data_study <- .x
    
    # Extract Money donations
    donations_money <- data_study %>%
      filter(resource == "Money") %>%
      pull(donation)
    
    # For each non-Money resource, compute Cohen's d vs. Money
    data_study %>%
      filter(resource != "Money") %>%
      group_by(resource) %>%
      summarise(
        p = {
          donations_other <- donation
          t <- t.test(donations_money, donations_other)
          t$p.value
        },
        .groups = "drop"
      )
  })


# coloring the cells
effect_color_d <- function(d) {
  case_when(
    abs(d) < 0.2 ~ "#BFBFBF",
    abs(d) < 0.5 ~ "#7F7F7F",
    abs(d) < 0.8 ~ "#3F3F3F",
    TRUE         ~ "#000000"
  )
}

effect_color_p <- function(p) {
  case_when(
    p <= .05 ~ "#000000", 
    p > .05  ~ "#800000"
  )
}

#### table ####

kable <- distance_to_money %>% 
  left_join(cohens_d_results) %>% 
  left_join(p_values) %>% 
  mutate(across(-resource & -cohens_d & - p,  ~100*round(.x, 3)), 
         cohens_d = round(cohens_d, 2), 
         p = round(p, 3)) %>% 
  ungroup() %>% 
  arrange(study, diff) %>% 
  mutate(diff = paste0("+", diff, "  [", cil, " ; ", cih, "]")) %>% 
  mutate(p_fmt = ifelse(p < 0.001, "<.001", sprintf("%.3f", p))) %>% 
  mutate(cohens_d = cell_spec(cohens_d, format = "latex", color = effect_color_d(cohens_d))) %>% 
  mutate(p_fmt = cell_spec(p_fmt, format = "latex", color = effect_color_p(p))) %>% 
  select(resource, diff, p_fmt, cohens_d) %>% 
  kbl(format = "latex", booktabs = T, col.names = NULL, align = c('lccc'), escape = F) %>% 
  kable_styling(full_width = T, ) %>% 
  add_header_above(c(" " = 1, "Allocated share change" = 1, "p-value" = 1, "Cohen's" = 1)) %>% 
  column_spec(1, width = "4.2cm") %>% 
  column_spec(2, width = "4.2cm") %>% 
  pack_rows(paste0("Study 1 -- ",share_money_self$share_self[share_money_self$study == "Study 1"], " money to other"), 1, 4) %>% 
  pack_rows(paste0("Study 2 -- ",share_money_self$share_self[share_money_self$study == "Study 2"], " money to other"), 5, 11) %>% 
  pack_rows(paste0("Study 3 -- ",share_money_self$share_self[share_money_self$study == "Study 3"], " money to other"), 12, 19) %>% 
  pack_rows(paste0("Study 4 -- ",share_money_self$share_self[share_money_self$study == "Study 4"], " money to other"), 20, 21) %>% 
  pack_rows(paste0("Study 5 -- ",share_money_self$share_self[share_money_self$study == "Study 5"], " money to other"), 22, 24) %>% 
  pack_rows(paste0("Study 6 -- ",share_money_self$share_self[share_money_self$study == "Study 6"], " money to other"), 25, 26) %>% 
  pack_rows(paste0("Study 7 -- ",share_money_self$share_self[share_money_self$study == "Study 7"], " money to other"), 27, 32) %>% 
  pack_rows(paste0("Study 8 -- ",share_money_self$share_self[share_money_self$study == "Study 8"], " money to other"), 33, 35) %>% 
  pack_rows(paste0("Study S1 -- ",share_money_self$share_self[share_money_self$study == "Study S1"], " money to other"), 36, 37) %>% 
  pack_rows(paste0("Study S2 -- ",share_money_self$share_self[share_money_self$study == "Study S2"], " money to other"), 38, 39) 


save_kable(kable, "Table_1_try.png")
save_kable(kable, "Table_1_try.pdf")

## computing numbers for abstract
## study 1
df %>% 
  filter(study == "Study 1") %>% 
  mutate(restype = if_else(resource == "Money", "Money","Other")) %>% 
  group_by(restype) %>% 
  mutate(share = donation/pie) %>% 
  summarise(m = mean(share, na.rm = T))

## all other studies
df %>% 
  mutate(incentives = study == "Study 1") %>% 
  mutate(restype = case_when(resource == "Money" ~ "Money", 
                               study != "Study 7" & 
                               str_detect(resource, "\\+") == F & 
                               str_detect(resource, "\\:") == F   ~ "Other", 
                             TRUE ~ "Manipulated")) %>% 
  group_by(restype, incentives) %>% 
  mutate(share = donation/pie) %>% 
  summarise(m = 100*round(mean(share, na.rm = T), 4)) %>% 
  filter(restype != "Manipulated") %>% 
  pivot_wider(names_from = restype, values_from = m) %>% 
  mutate(delta = Other - Money)

## overall
df %>% 
  mutate(incentives = study == "Study 1") %>% 
  mutate(restype = case_when(resource == "Money" ~ "Money", 
                             study != "Study 7" & 
                               str_detect(resource, "\\+") == F & 
                               str_detect(resource, "\\:") == F   ~ "Other", 
                             TRUE ~ "Manipulated")) %>% 
  group_by(restype) %>% 
  mutate(share = donation/pie) %>% 
  summarise(m = 100*round(mean(share, na.rm = T), 4)) %>% 
  filter(restype != "Manipulated") %>% 
  pivot_wider(names_from = restype, values_from = m) %>% 
  mutate(delta = Other - Money)
