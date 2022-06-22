# Workbench ---------------------------------------------------------------

board_path <- config::get("board_path")
board <- board_folder(board_path, versioned = T)

# board %>% pin_list

board %>% pin_read("route_hcp") -> hcp_graph

board %>% pin_read("spk_list") -> spk_prof_tbl

board %>% pin_read("non_spk_list") -> non_spk_tbl

list_score <- c("eigen", "betweeness")

board %>% pin_read("list_province") -> list_province

board %>% pin_read("specialty_tbl") -> specialty_tbl

list_main_spec <- unique(sort(specialty_tbl$cust_main_specialty_regroup))

specialty_tbl %>% 
  filter(cust_main_specialty_regroup == "Internal Medicine") -> init_sub

init_sub <- init_sub$cust_2nd_specialty_regroup

board %>% pin_read("data_time") -> data_time

begin_date <- data_time$begin_date

end_date <- data_time$end_date

n_node_filter <- 30

# Laptop ------------------------------------------------------------------

# hcp_graph <- readRDS("rmd/output/hcp_graph_obj.RDS")
# 
# spk_prof_tbl <- read_csv("rmd/output/speaker_prof_tbl.csv")
# 
# spk_prof_tbl %>% 
#   select(!degree) %>% 
#   mutate(betweeness = round(betweeness/100, digits = 2)) -> spk_prof_tbl
# 
# non_spk_tbl <- read_csv("rmd/output/node_non_speaker.csv")
# 
# non_spk_tbl %>% 
#   select(!c(degree, group)) %>% 
#   mutate(betweeness = round(betweeness/100, digits = 2)) -> non_spk_tbl
# 
# list_score <- c("eigen", "betweeness")
# 
# list_province <- sort(unique(c(spk_prof_tbl$cust_prmry_addr_state, non_spk_tbl$cust_prmry_addr_state)))
# 
# list_spec <- sort(unique(c(spk_prof_tbl$cust_main_specialty_code, non_spk_tbl$cust_main_specialty_code)))
# 
# begin_date <- format(ymd("2019-01-01"), "%Y-%m")
# end_date <- format(ymd("2021-12-31"), "%Y-%m")