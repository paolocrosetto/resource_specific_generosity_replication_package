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
## This file replicates the figures and tables in the main text and the supplement of the paper

#### 0. Libraries ####

library(tidyverse)        # R dialect used in this file

library(hrbrthemes)       # ggplot fancy theme
library(patchwork)        # combine ggplots into one plot

library(kableExtra)       # nice-looking table export
library(gt)               # alternative table-creation and export package


#### 0. Main text ####

#### 0.1 Data ####

df <- read_csv("Data/all_studies_clean.csv")


#### 0.2 Figure 1 ####

source("Scripts/Figure_1.R")


#### 0.3 Table 1 ####

source("Scripts/Table_1.R")


##### 1. Supplementary material: Study 1 ####

##### 1.1 Data ####

s1 <- read_csv("Data/study_1.csv")

# renaming to match the labels used in the paper
s1 <- s1 %>% 
  mutate(resource = case_when(resource == "Food" ~ "KitKat", 
                            resource == "Water" ~ "Coke cans", 
                            resource == "Time" ~ "Minutes", 
                            TRUE ~ resource))

#### 1.2 Tables 

## Table S1
source("Scripts/Table_S1.R")


## TODO Table S2
source("Scripts/Table_S2.R")

## TODO Table S3
source("Scripts/Table_S3.R")


## TODO Table S4
source("Scripts/Table_S4.R")


