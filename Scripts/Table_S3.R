##
## Resource-specific generosity
##
##
## Replication Package
##
## This version: 0.1, 11 Nov 2024
##
##
## This file generates Table S3 from the paper

# format data for computation and compute means and st.dev
ts1 <- s1 %>% 
  select(resource, desirability, fung, perish, socnorm, dmu) %>% 
  mutate(dmu = dmu -4) %>% 
  rename(perishability = perish, fungibility = fung, 
         `marginal utility`= dmu, `social norm`= socnorm) %>% 
  group_by(resource)  %>% 
  summarise(across(everything(), 
                   function(x) paste0(format(round(mean(x),2), nsmall = 2), 
                                      " (", round(sd(x), 2),
                                      ")"))) %>% 
  arrange(desc(desirability))

ts1 %>% 
  gt() %>% 
  tab_header(title = "Mean (SD) of Likert ratings by resources, Study 1") %>% 
  gtsave("Tables/Table_S3.png")
