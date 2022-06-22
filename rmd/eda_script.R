
# Investigate data --------------------------------------------------------

speaker_qual %>% 
  count(qualf_name) %>% 
  arrange(desc(n))

glimpse(small_mtg_joined)

small_mtg_R <- collect(small_mtg_joined)

count(cust, cust_prmry_parent_cls_of_trade)

cust %>% 
  filter(cust_prmry_parent_cls_of_trade == "Research/Training Hospital") %>% 
  distinct(cust_prmry_parent_name) %>% 
  collect() -> research_hco

event_edge_list %>% collect() -> event_edge_list_R

hcp_edge %>%
  ungroup() %>% 
  count()

event_list <- union(unique(event_edge_list$from), unique(event_edge_list$to))

setdiff(event_list, node_list$id)
# 1235529 <<< Missing in Node List

edge_list %>% 
  filter(from != "1235529", to != "1235529") -> test_edge
# It Worked!

cust %>% 
  filter(cust_key == "1235529") %>% 
  collect() -> root_cause

small_mtg %>% 
  left_join(event_speaker, by ="evnt_key") %>% 
  left_join(speaker_profile, by ="spk_key") %>%
  left_join(speaker_qual, by ="spk_key") %>% 
  filter(!is.na(spk_key)) %>% 
  left_join(cust, by = c("cust_key_speaker"="cust_key"), suffix = c("", "_speaker")) %>%
  left_join(event_attendee, by = "evnt_key") %>%
  left_join(cust, by = "cust_key", suffix = c("", "_attendee")) %>% 
  arrange(evnt_key) %>% 
  collect() -> small_R


# Test writing table in HHIE ----------------------------------------------


speaker_tbl <- read_csv("rmd/output/speaker_prof_tbl.csv")

# speaker_db <- copy_to(con, speaker_tbl,
#                       name = "cim_iss_th_conf_pub.speaker_test",
#                       overwrite = T,
#                       temporary = T
#                       )

speaker_db <- rs_create_table(speaker_tbl, dbcon = con, 
                              table_name = "cim_iss_th_conf_pub.speaker_test")

# Investigate join data --------------------------------------------------------


