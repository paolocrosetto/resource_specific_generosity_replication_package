##
## Resource-specific generosity
##
##
## Replication Package
##
## This version: 0.1, 11 Nov 2024
##
##
## This file generates Table S1 from the paper

# compute contents of the table
ts1 <- s1 %>% 
  mutate(resource = as.factor(resource), 
         resource = fct_relevel(resource, "Money", "Pen", "KitKat", "Coke cans")) %>% 
  group_by(resource) %>% 
  summarise(mean = mean(donation), sd = sd(donation))
  
# export the table
ts1 %>% 
  gt() %>% 
  tab_header(title = "Mean and Standard Deviation of Number of Units of Resource (Out of Ten Units) Allocated to the Other Participant in a Dictator Game (Study 1).") %>% 
  cols_label(
    mean = "Mean", 
    sd = "SD", 
    resource = ""
  ) %>% 
  fmt_number(columns = -resource, decimals = 3) %>% 
  gtsave(filename = "Tables/Table_S1.png")
    
