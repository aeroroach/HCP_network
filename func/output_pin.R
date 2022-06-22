
# Preparing output --------------------------------------------------------

# Speaker profile
route_hcp %>% 
  activate(nodes) %>% 
  as_tibble() %>% 
  filter(group == "Speaker") -> speaker_w_score

# Non speaker
route_hcp %>% 
  activate(nodes) %>% 
  as_tibble() %>% 
  filter(group == "None") -> non_speaker_prof

# Time stamp
data_time <- list(begin_date = begin_date, 
                  end_date = end_date)

# Province
list_province <- sort(unique(c(node_list$cust_prmry_addr_state)))

# Spec table
node_list %>% 
  distinct(cust_main_specialty_regroup, cust_2nd_specialty_regroup) %>% 
  arrange(cust_main_specialty_regroup, cust_2nd_specialty_regroup) -> specialty_tbl

# Board initialization ----------------------------------------------------

board_path <- config::get("board_path")
board <- board_folder(board_path, versioned = T)

# writing pins ------------------------------------------------------------

board %>% pin_write(route_hcp, "route_hcp", type = "rds")

board %>% pin_write(speaker_w_score, "spk_list", type = "rds")

board %>% pin_write(non_speaker_prof, "non_spk_list", type = "rds")

board %>% pin_write(data_time, "data_time", type = "rds")

board %>% pin_write(list_province, "list_province", type = "rds")

board %>% pin_write(specialty_tbl, "specialty_tbl", type = "rds")

# prune version -----------------------------------------------------------

board %>% pin_versions_prune("route_hcp", n = 5)

board %>% pin_versions_prune("spk_list", n = 5)

board %>% pin_versions_prune("non_spk_list", n = 5)

board %>% pin_versions_prune("data_time", n = 5)

board %>% pin_versions_prune("list_province", n = 5)

board %>% pin_versions_prune("specialty_tbl", n = 5)
