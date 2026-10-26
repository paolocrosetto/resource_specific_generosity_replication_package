##
## Resource-specific generosity
##
##
## Replication Package
##
## This version: 0.9, Apr 2026
##
##
## This file generates the overall numbers used in the abstract


abstract <- df %>% 
  mutate(incentives = study == "Study 1", 
         money = resource == "Money",
         share = donation/pie)

abstract %>% 
  group_by(money) %>% 
  summarise(mean(share))

abstract %>% 
  group_by(money, incentives) %>% 
  summarise(mean(share))
