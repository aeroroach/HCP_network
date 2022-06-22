# weight init -------------------------------------------------------------

eif_weight <- 10
event_weight <- 5
primary_weight <- 3
other_weight <- 1
sym_weight <- 7

# master regroup ----------------------------------------------------------

spec_master <- read_csv("master/spec_regroup.csv")

spec_master <- lazy_dt(spec_master)

# Small mtg Edge List ---------------------------------------------------------

event_select %>% 
  select(from = cust_ak_attendee, to = cust_ak_speaker) %>% 
  mutate(init_weight = event_weight) %>% 
  group_by(from, to) %>% 
  summarise(weight = sum(init_weight)) %>% 
  collect() %>% 
  lazy_dt() -> event_edge_list

# EIF Edge List -----------------------------------------------------------

event_eif %>% 
  collect() %>% 
  lazy_dt() -> event_eif

# Prepare self join
event_eif %>% 
  rename(from = cust_ak_speaker) -> eif_from

event_eif %>% 
  rename(to = cust_ak_speaker) -> eif_to

eif_from %>% 
  left_join(eif_to, by = "evnt_key") %>% 
  filter(from != to) %>% 
  as_tibble() -> eif_network

# Aggregate with weight
eif_network %>% 
  lazy_dt() %>% 
  mutate(init_weight = eif_weight) %>% 
  group_by(from, to) %>% 
  summarise(weight = sum(init_weight)) -> eif_network

# Sym Edge List -----------------------------------------------------------

event_sym %>% 
  collect() %>% 
  lazy_dt() -> event_sym

# Prepare self join
event_sym %>% 
  rename(from = cust_ak_speaker) -> sym_from

event_sym %>% 
  rename(to = cust_ak_speaker) -> sym_to

sym_from %>% 
  left_join(sym_to, by = "evnt_key") %>% 
  filter(from != to) %>% 
  as_tibble() -> sym_network

# Aggregate with weight
sym_network %>% 
  lazy_dt() %>% 
  mutate(init_weight = sym_weight) %>% 
  group_by(from, to) %>% 
  summarise(weight = sum(init_weight)) -> sym_network

# Speaker Profile ---------------------------------------------------------

speaker_prof_tbl %>% 
  collect() %>% 
  rename(id = cust_ak_speaker) %>% 
  lazy_dt() -> speaker_prof_tbl
         
# HCO Correlation ---------------------------------------------------------

# Preparing self join
cust %>% 
  left_join(cust_child, by = c("cust_veeva_id"="child_account_vod")) %>% 
  collect() %>% 
  arrange(cust_ak) %>% 
  lazy_dt() -> cust_with_child 

# Cleansing
cust_with_child %>% 
  mutate(cust_2nd_specialty_code = if_else(is.na(cust_2nd_specialty_code), "None", cust_2nd_specialty_code)) %>% 
  left_join(spec_master, by = c("cust_main_specialty_code", "cust_2nd_specialty_code")) %>% 
  filter(!is.na(cust_main_specialty_regroup), !is.na(cust_2nd_specialty_regroup)) %>% 
  select(cust_ak, cust_name, cust_veeva_id, 
         cust_main_specialty_regroup, cust_2nd_specialty_regroup,
         cust_prmry_addr_state, cust_prmry_parent_name, parent_account_vod, primary_vod) -> cust_with_child


cust_with_child %>% 
  select(cust_ak, cust_main_specialty_regroup, parent_account_vod, primary_vod) %>% 
  rename(cust_ak_to = cust_ak) -> hcp_to

cust_with_child %>% 
  select(cust_ak,cust_main_specialty_regroup, parent_account_vod) %>% 
  rename(cust_ak_from = cust_ak) -> hcp_from

# Perform self join
hcp_from %>% 
  left_join(hcp_to, by = c("cust_main_specialty_regroup", "parent_account_vod")) %>% 
  filter(cust_ak_from != cust_ak_to) -> hcp_network

# Aggregate with weight
hcp_network %>% 
  mutate(init_weight = ifelse(primary_vod == "Yes", primary_weight, other_weight)) %>% 
  select(from = cust_ak_from, to = cust_ak_to, init_weight) %>% 
  group_by(from, to) %>% 
  summarise(weight = sum(init_weight)) -> hcp_network

# Perform operation
event_edge_list %>% 
  filter(!is.na(from), !is.na(to)) %>% 
  as_tibble() -> event_edge_list

eif_network %>% 
  as_tibble() -> eif_network

sym_network %>% 
  as_tibble() -> sym_network

hcp_network %>% 
  as_tibble() -> hcp_network

# Combine edge ------------------------------------------------------------

edge_list <- bind_rows(event_edge_list ,hcp_network, eif_network, sym_network)

edge_list %>% 
  lazy_dt() %>% 
  group_by(from, to) %>% 
  summarise(weight = sum(weight)) -> edge_list

# Node list ---------------------------------------------------------------

cust %>%
  select(!cust_veeva_id) %>%
  rename(id = cust_ak, label = cust_name) %>% 
  collect() %>% 
  lazy_dt() -> node_list

# Mapping with speaker list -----------------------------------------------

node_list %>%
  left_join(speaker_prof_tbl, by = "id") %>%
  mutate(group = ifelse(is.na(group),"None", group),
         qualf_name = ifelse(is.na(qualf_name), "None", qualf_name)) -> node_list

# Impute value ------------------------------------------------------------

node_list %>% 
  mutate(cust_2nd_specialty_code = if_else(is.na(cust_2nd_specialty_code), "None", cust_2nd_specialty_code)) -> node_list

node_list %>% 
  left_join(spec_master, by = c("cust_main_specialty_code", "cust_2nd_specialty_code")) %>% 
  filter(!is.na(cust_main_specialty_regroup), !is.na(cust_2nd_specialty_regroup)) %>% 
  select(id, label, group, qualf_name,
         cust_main_specialty_regroup, cust_2nd_specialty_regroup, 
         cust_prmry_addr_state, cust_prmry_parent_name, group) %>% 
  distinct() -> node_list

# Perform operation

edge_list %>% 
  as_tibble() -> edge_list

node_list %>% 
  as_tibble() -> node_list

# Filtering invalid HCP ---------------------------------------------------

edge_list %>%
  semi_join(node_list, by = c("from"="id")) %>%
  semi_join(node_list, by = c("to"="id")) -> edge_list
