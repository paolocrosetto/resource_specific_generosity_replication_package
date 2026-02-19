  ##
  ## Resource-specific generosity
  ##
  ##
  ## Replication Package
  ##
  ## This version: 0.1, 11 Nov 2024
  ##
  ##
  ## This file generates Table S2 from the paper
  
  
  
  Table_S2 <- jmv::ANOVA(
    formula = donation ~ resource,
    data = s1 %>%  mutate(resource = as.factor(resource), 
                          resource = fct_relevel(resource, "Money", "Pen", "KitKat", "Coke cans")),
    postHoc = ~ resource,
    postHocES = "d")
  
  Table_S2$postHoc[[1]] %>% 
    as_tibble() %>% 
    select(resource1, resource2, t, ptukey, d) %>% 
    gt() %>% 
    fmt_number(columns = c("t", "ptukey", "d"), decimals = 3) %>% 
    gtsave("Tables/Table_S2.png")
  
  
  
  
