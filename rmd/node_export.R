
# Prerequisite ------------------------------------------------------------

Sys.setlocale("LC_ALL", "th_TH.utf8")
Sys.setenv(R_CONFIG_ACTIVE = "default")

library(data.table)
library(dtplyr)
library(tidyverse)
library(lubridate)
library(tidygraph)
library(pins)

# Data Loading -----------------------------------------------------------------

source("rmd/conn.R")

# Customer dimension
cust <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_d_customer"))

cust %>% 
  filter(cust_status_code_local == "Active", 
         cust_class_of_trade == "Physician", 
         dm_deleted_flag == "N", 
         dm_current_flag == "Y") %>% 
  select(cust_ak, cust_mdm_id, cust_prmry_parent_mdm_id) -> cust

cust %>% collect() -> cust_R

# Network Graph Node
board_path <- config::get("board_path")
board <- board_folder(board_path, versioned = T)

board %>% pin_read("route_hcp") -> hcp_graph

hcp_graph %>% 
  activate(nodes) %>% 
  as_tibble() -> node_list


# Joining -----------------------------------------------------------------

node_list %>% 
  left_join(cust_R %>% 
              mutate(cust_ak = as.character(cust_ak)), 
            by = c("id"="cust_ak")) -> node_join

node_join %>% 
  select(cust_mdm_id, hcp_name = label, group, qualf_name,
         cust_main_specialty_regroup, cust_2nd_specialty_regroup, cust_prmry_addr_state,
         cust_prmry_parent_mdm_id, cust_prmry_parent_name, 
         eigen, betweeness) %>% 
  mutate(eigen_bin = ntile(eigen, 5), 
         between_bin = ntile(betweeness, 5)) -> node_refine

node_refine %>% 
  mutate(eigen_class = case_when(
    eigen_bin == 1 ~ "01_low",
    eigen_bin == 2 ~ "02_med_low",
    eigen_bin == 3 ~ "03_medium",
    eigen_bin == 4 ~ "04_med_high",
    eigen_bin == 5 ~ "05_high"
    ),
    between_class = case_when(
      between_bin == 1 ~ "01_low",
      between_bin == 2 ~ "02_med_low",
      between_bin == 3 ~ "03_medium",
      between_bin == 4 ~ "04_med_high",
      between_bin == 5 ~ "05_high",
    )
  ) -> node_regroup


# Writing output ----------------------------------------------------------

write_csv(node_regroup, "rmd/output/hcp_network_score.csv")

# Disconnect --------------------------------------------------------------

DBI::dbDisconnect(con)
