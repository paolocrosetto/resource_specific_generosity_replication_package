##
## Resource-dependent generosity
##
##
## Replication Package
##
## This version: 0.1, 11 Nov 2024
##
##
## This file generates Figure 1 from the paper

## prepare the data for plotting
plotme <- df %>% 
  mutate(share = donation/pie) %>% 
  group_by(study, resource) %>% 
  summarise(m = mean(share), 
            sem = sd(share)/sqrt(n())) %>% 
  mutate(cil = m - qt(0.975, df = n() - 1)*sem,
         cih = m + qt(0.975, df = n() - 1)*sem) %>% 
  select(study, resource, share = m, cil, cih) %>% 
  mutate(resource = as.factor(resource)) %>% 
  group_by(study) %>% 
  mutate(resource = fct_reorder(resource,-share)) %>% 
  arrange(study, resource)

## function to create a plot for one study
study_plot <- function(selected_study){
  out <- plotme %>% 
    filter(study == selected_study) %>% 
    ggplot()+
    aes(share, fct_reorder(resource,-share), color = share)+
    geom_segment(aes(x = cil, xend = cih, yend = fct_reorder(resource,-share)), color = "grey85", linewidth = 2.3, lineend = "round")+
    geom_point(size = 3)+
    facet_grid(study~., scales = "free_y", space = "free_y")+
    scale_x_percent(limits = c(0.08,0.72), breaks = seq(0.1,0.7,0.1))+
    theme_ipsum_rc()+
    scale_color_viridis_c()+
    theme(strip.text = element_text(face = "bold"), 
          legend.position = "none",
          panel.grid.minor.x = element_blank(), 
          panel.grid.major.y = element_line(linetype = "dotted"), 
          plot.background = element_rect(fill = "white", color = "white"))
  
  if (selected_study == "Study 5") {
    out <- out + labs(y = "", x = "Share donated")
  } else {
    out <- out + labs(y = "", x = "") 
  }
}

## generate plots for each study
ps1 <- study_plot("Study 1")
ps2 <- study_plot("Study 2")
ps3 <- study_plot("Study 3")
ps4 <- study_plot("Study 4")
ps5 <- study_plot("Study 5")


## stitch the plots into one meta-plot
ps1 + plot_spacer() + 
  ps2 + plot_spacer() + 
  ps3 + plot_spacer() + 
  ps4 + plot_spacer() + 
  ps5 + 
  plot_layout(ncol = 1, heights = c(5,-2,8,-2,9,-2,3,-2,4))

## save the plot to file
ggsave("Figures/Figure_1.png", width = 9/1.1, height = 12/1.1, units = "in", dpi = "retina")