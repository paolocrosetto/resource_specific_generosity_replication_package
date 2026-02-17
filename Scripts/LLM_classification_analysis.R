## this file imports the SAV datafile of the Nov 25 open-ended questions
## and exports it ti csv
## in order to later feed the data to the LLM
## that will classify the texts according to their main motive

library(tidyverse)
library(haven)
library(hrbrthemes)
library(gt)
library(gtExtras)

#### 1. getting and cleaning original data ####
df <- read_sav("Data/Self-other Resource Allocation Open-Ended Pitt - Fall 2025 #251010_cleaned.sav")

## selecting variables of interest
df <- df %>% 
  filter(DuplicateIDExclude1Include0 == 0) %>%  ## get rid of duplicate IDs
  select(ID = ResponseId, money_other = dv_money_other, resource_other = dv_nonmoney_other, 
         explain_money = fr_money, 
         explain_nonmoney = fr_nonmoney, 
         explain_diff = explain, 
         resource = nonmoneyresource)

## computing some qualitative variables
df <- df %>% 
  mutate(equal_split_always = money_other == 5 & resource_other == 5, 
         equal_split_money = money_other == 5, 
         equal_split_resource = resource_other == 5, 
         more_generous_money = money_other > resource_other, 
         more_generous_resource = money_other < resource_other, 
         equally_generous = money_other == resource_other)

#### 2. read in and merge the classifications from the LLM ####

# money
LLM_money <- read_csv("Data/classified_money.csv") %>% 
  select(ID, class_money = classification) %>% 
  filter(class_money != "ERROR")

## 17 were classified as "ERROR" because of a problem in the run. 
## those were rerun and were fine
LLM_money_error <- read_csv("Data/classified_money_errors.csv") %>% 
  select(ID, class_money = classification)

# binding
LLM_money <- LLM_money %>% bind_rows(LLM_money_error)

# nonmoney
LLM_nonmoney <- read_csv("Data/classified_nonmoney.csv") %>% 
  select(ID, class_nonmoney = classification_nonmoney)%>% 
  filter(class_nonmoney != "ERROR")


## 68 were classified as "ERROR" because of a problem in the run. 
## those were rerun and were fine
LLM_nonmoney_error <- read_csv("Data/classified_nonmoney_errors.csv") %>% 
  select(ID, class_nonmoney = classification_nonmoney)

# binding
LLM_nonmoney <- LLM_nonmoney %>% bind_rows(LLM_nonmoney_error)

# difference
LLM_diff <- read_csv("Data/classified_diff.csv") %>% 
  select(ID, class_diff = classification_diff)

class <- LLM_money %>% 
  left_join(LLM_nonmoney, by = "ID") %>% 
  left_join(LLM_diff, by = "ID")

## merge
df <- df %>% 
  left_join(class, by = join_by(ID))

# cleanup
rm(LLM_diff, LLM_money, LLM_nonmoney, class)


#### 3. main table ####

## overall table



## first: let's look at money
money_table <- df %>% 
  select(ID, money_other, contains("_money")) %>% 
  mutate(choice = case_when(money_other == 5 ~ "Equal Split", 
                            money_other < 5  ~ "More to Self", 
                            money_other > 5  ~ "More to Other")) %>% 
  group_by(choice, class_money) %>% 
  tally() %>% 
  mutate(total = sum(n), share = n/sum(n)) %>% 
  select(-n) %>% 
  mutate(resource = "money") %>% 
  pivot_wider(names_from = class_money, values_from = share)

## second: other resources
resource_table <- df %>% 
  select(ID, resource_other, resource, class_nonmoney) %>% 
  mutate(choice = case_when(resource_other == 5 ~ "Equal Split", 
                            resource_other < 5  ~ "More to Self", 
                            resource_other > 5  ~ "More to Other")) %>% 
  group_by(choice, resource, class_nonmoney) %>% 
  tally() %>% 
  mutate(total = sum(n), share = n/sum(n)) %>% 
  select(-n) %>% 
  pivot_wider(names_from = class_nonmoney, values_from = share)

## third: difference
diff_table <- df %>% 
  select(ID, money_other, resource_other, resource, class_diff) %>% 
  mutate(diff = case_when(money_other < resource_other ~ "More generous with resource", 
                          money_other == resource_other ~ "Equally generous", 
                          money_other > resource_other ~ "More generous with money")) %>% 
  group_by(diff, resource, class_diff) %>% 
  tally() %>% 
  mutate(total = sum(n), share = n/sum(n)) %>% 
  select(-n) %>% 
  pivot_wider(names_from = class_diff, values_from = share)


money_table %>% 
  bind_rows(resource_table) %>% 
  mutate(resource = str_to_title(resource),
         resource = as.factor(resource), 
         resource = fct_relevel(resource, "Money", "Time", "Food")) %>% 
  mutate(choice = as.factor(choice), 
         choice = fct_relevel(choice, "More to Self", "Equal Split")) %>% 
  arrange(resource, choice) %>% 
  select(choice, N = total, resource, 
         SOCIALNORM, DESIRABILITY, SATIATION, FUNGIBILITY, PERISHABILITY, OTHER) %>% 
  group_by(resource) %>% 
  gt() %>% 
  gt_theme_538() %>% 
  fmt_percent(columns = -choice & -N) %>% 
  sub_missing(missing_text = "-") %>% 
  cols_align(columns = choice, align = "left") %>% 
  data_color(columns = -choice & -N, 
             direction = "row", 
             method = "bin", 
             palette = "calecopal::desert", 
             domain = c(0,1),
             na_color = "grey95") %>% 
  tab_style(
    style = list(cell_text(weight = "bold", align = "left", size = "large")),
    locations = cells_row_groups()
  ) %>% 
  cols_label(choice = "") %>% 
  tab_options(
    data_row.padding = px(2), 
    heading.padding = px(1),
    summary_row.padding = px(1), 
    footnotes.padding = px(2),
    row_group.padding = px(10),
    table.font.size = px(17), 
    table.font.names = "Roboto Condensed"
  ) %>% 
  tab_style(
    style = cell_text(weight = "bold"),            # make text bold
    locations = cells_column_labels(everything())  # target all column names
  ) %>% 
  tab_style(
    style = list(cell_text(weight = "bold")), 
    locations = cells_body(columns = N)
  ) %>% 
  tab_style(
    style = list(cell_text(style = "italic")), 
    locations = cells_body(columns = choice)
  ) %>% 
  opt_table_font(
    google_font("Titilium Web")
  ) %>% 
  tab_header(
    title = "Classification of open-ended questions justifying split", 
    subtitle = "For money and other resources. Classified by OpenAI GTP4o."
  ) %>% 
  gtsave("temp.html")

webshot2::webshot("temp.html",
                  "Tables/Table_10.png",
                  expand = 30, zoom = 2,
                  selector = "table")

## diff table
diff_table%>% 
  ungroup() %>% 
  mutate(resource = paste0("Money vs ", str_to_title(resource)),
         resource = as.factor(resource), 
         resource = fct_relevel(resource, "Money vs Time", "Money vs Food")) %>% 
  mutate(choice = as.factor(diff), 
         choice = fct_relevel(choice, "More generous with money", "Equally generous")) %>% 
  select(-diff) %>% 
  select(choice, everything()) %>% 
  arrange(resource, choice) %>% 
  select(choice, N = total, resource, 
         SOCIALNORM, DESIRABILITY, SATIATION, FUNGIBILITY, PERISHABILITY, OTHER) %>% 
  group_by(resource) %>% 
  gt() %>% 
  gt_theme_538() %>% 
  fmt_percent(columns = -choice & -N) %>% 
  sub_missing(missing_text = "-") %>% 
  cols_align(columns = choice, align = "left") %>% 
  data_color(columns = -choice & -N, 
             direction = "row", 
             method = "bin", 
             palette = "calecopal::desert", 
             domain = c(0,1),
             na_color = "grey95") %>% 
  tab_style(
    style = list(cell_text(weight = "bold", align = "left", size = "large")),
    locations = cells_row_groups()
  ) %>% 
  cols_label(choice = "") %>% 
  tab_options(
    data_row.padding = px(2), 
    heading.padding = px(1),
    summary_row.padding = px(1), 
    footnotes.padding = px(2),
    row_group.padding = px(10),
    table.font.size = px(17), 
    table.font.names = "Roboto Condensed"
  ) %>% 
  tab_style(
    style = cell_text(weight = "bold"),            # make text bold
    locations = cells_column_labels(everything())  # target all column names
  ) %>% 
  tab_style(
    style = list(cell_text(weight = "bold")), 
    locations = cells_body(columns = N)
  ) %>% 
  tab_style(
    style = list(cell_text(style = "italic")), 
    locations = cells_body(columns = choice)
  ) %>% 
  opt_table_font(
    google_font("Titilium Web")
  ) %>% 
  tab_header(
    title = "Classification of open-ended questions justifying difference in splits", 
    subtitle = "For money vs other resource. Classified by OpenAI GTP4o."
  ) %>% 
  gtsave("temp.html")

webshot2::webshot("temp.html",
                  "Tables/Table_11.png",
                  expand = 30, zoom = 2,
                  selector = "table")
  
## cleanup
rm(money_table, diff_table, resource_table)
rm(LLM_money_error, LLM_nonmoney_error)
file.remove("temp.html")
