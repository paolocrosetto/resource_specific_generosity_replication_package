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


# libraries
library(tidyverse)        # R dialect used in this file
library(hrbrthemes)
library(patchwork)


#### getting data #####

df <- read_csv("Data/all_studies_clean.csv")

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

# for study 5 we compute first the mean, then subtract, and then build conf int afterwards

distance_to_money_study_4 <- df %>% 
  filter(study == "Study 4") %>% 
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


# merge the two

distance_to_money <- distance_to_money %>% 
  bind_rows(distance_to_money_study_4) %>% 
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
  mutate(resource = factor(resource)) |> 
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



#### table ####

kable <- distance_to_money %>% 
  left_join(cohens_d_results) %>% 
  mutate(across(-resource & -cohens_d,  ~100*round(.x, 3)), 
         cohens_d = round(cohens_d, 2)) %>% 
  select(study, resource, diff, cohens_d) %>% 
  ungroup() %>% 
  arrange(study, diff) %>% 
  mutate(diff = paste0("+", diff, " p.p.")) %>% 
  select(-study) %>% 
  kbl(format = "latex", booktabs = T, col.names = NULL, align = c('lccc')) %>% 
  kable_styling(full_width = T, ) %>% 
  add_header_above(c(" " = 1, "Allocated share change" = 1, "Cohen's d" = 1)) %>% 
  column_spec(1, width = "4.2cm") %>% 
  pack_rows(paste0("Study 1 -- ",share_money_self$share_self[share_money_self$study == "Study 1"], " money to other"), 1, 4) %>% 
  pack_rows(paste0("Study 2 -- ",share_money_self$share_self[share_money_self$study == "Study 2"], " money to other"), 5, 11) %>% 
  pack_rows(paste0("Study 3 -- ",share_money_self$share_self[share_money_self$study == "Study 3"], " money to other"), 12, 19) %>% 
  pack_rows(paste0("Study 4 -- ",share_money_self$share_self[share_money_self$study == "Study 4"], " money to other"), 20, 21) %>% 
  pack_rows(paste0("Study 5 -- ",share_money_self$share_self[share_money_self$study == "Study 5"], " money to other"), 22, 24) 

save_kable(kable, "Tables/Table_1.pdf")
save_kable(kable, "Tables/Table_1.png")
