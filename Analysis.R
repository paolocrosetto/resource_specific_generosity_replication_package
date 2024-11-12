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
## This file replicates the figures and tables in the main text of the paper

#### 0. Libraries ####

library(tidyverse)        # R dialect used in this file

library(hrbrthemes)       # ggplot fancy theme
library(patchwork)        # combine ggplots into one plot

library(kableExtra)       # nice-looking table export

#### 1. Data ####

df <- read_csv("Data/all_studies_clean.csv")



#### 2. Figure 1 ####

source("Scripts/Figure_1.R")


#### 3. Table 1 ####

source("Scripts/Table_1.R")

