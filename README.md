# Replication Package for "Resource-Specific Generosity"

This repository contains all data and scripts to replicate the results of the paper *Resource-Specific Generosity*.

## Dependencies

The analysis for the main plot and table of the paper requires `R` and some extra packages, in particular `tidyverse` and some plot theming (`hrbrthemes`) and compositing (`patchwork`) packages.

## Running the replication package

Run `Analysis.R`. It should take less than 3 minutes. The script produces all Figures and Plots, that are saved in the relevant subfolder.

## LLM classification

The repo also contains the python scripts needed to replicate our LLM classification exercise on the open-ended responses provided by subjects in Study 5. The `Analysis.R` script does *not* rerun the LLM classification, but just takes the output of its original run of November 2025 and reproduces Tables 10 and 11 in the manuscript. Should you wish to rerun the LLM classification itself, follow the `README.txt` in the `/LLM` folder.
