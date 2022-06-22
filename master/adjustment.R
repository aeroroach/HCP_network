library(tidyverse)

spec_master <- read_csv("master/spec_regroup.csv")

spec_master %>% 
  filter(str_detect(cust_main_specialty_regroup, regex("onco", ignore_case = T)) | 
           str_detect(cust_2nd_specialty_regroup, regex("onco", ignore_case = T))) -> onco

onco %>% 
  mutate(cust_main_specialty_regroup = "Oncology") -> onco 

spec_master %>% 
  filter(!(str_detect(cust_main_specialty_regroup, regex("onco", ignore_case = T)) | 
           str_detect(cust_2nd_specialty_regroup, regex("onco", ignore_case = T)))) -> spec_ex

spec_ex %>% 
  bind_rows(onco) -> spec_ex
 
write_csv(spec_ex, "master/spec_regroup.csv")
