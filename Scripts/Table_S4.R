##
## Resource-dependent generosity
##
## by Ziano, Liu and Crosetto
##
## Replication Package
##
## This version: 0.1, 11 Nov 2024
##
##
## This file generates Table S4 from the paper

# raw data for the regression
ts4 <- s1 %>% 
  select(donation, resource, desirability, fung, perish, socnorm, dmu, valuation = bid) %>% 
  mutate(dmu = dmu -4) %>% 
  rename(perishability = perish, fungibility = fung, 
         marginal_utility= dmu, social_norm = socnorm)

# regression
r1 <- lmer(donation ~ 1+ desirability + perishability + fungibility + marginal_utility  + valuation + social_norm + (1 | resource) , 
           data = ts4)

# nicely formatted table
tab_model(r1, p.val = "satterthwaite", show.se = TRUE, file = "Tables/Table_S4.html")

# export to .png image
webshot("Tables/Table_S4.html", "Tables/Table_S4.png", selector = "table")