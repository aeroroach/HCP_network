
# Getting target date -----------------------------------------------------

target <- getting_period(year = 3)

begin_date <- target$begin
end_date <- target$end

# Event data --------------------------------------------------------------

event <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_f_event"))

event_speaker <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_f_event_speaker"))

speaker_profile <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_d_speaker"))

speaker_qual <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_d_speaker_qualification"))

event_attendee <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_f_event_attendee"))

# Customer data -----------------------------------------------------------

cust <- tbl(con, sql("SELECT * FROM cim_cdm_pub.vw_d_customer"))

cust_child <- tbl(con, sql("SELECT * FROM cim_lc_pub.vw_c302_009_child_account"))

# Filtering active records ------------------------------------------------

# Event

event %>% 
  filter(evnt_end_date >= begin_date, 
         evnt_end_date <= end_date, 
         dm_deleted_flag == "N",
         dm_current_flag == "Y",
         evnt_status == "Closed", 
         is.na(parent_evnt_id)) -> event

event_speaker %>% 
  filter(dm_deleted_flag == "N") -> event_speaker

speaker_profile %>% 
  filter(dm_current_flag == "Y", 
         dm_deleted_flag == "N") -> speaker_profile

speaker_qual %>% 
  filter(dm_current_flag == "Y", 
         dm_deleted_flag == "N") -> speaker_qual

event_attendee %>% 
  filter(dm_current_flag == "Y", 
         dm_deleted_flag == "N") -> event_attendee

# Customer

cust %>% 
  filter(cust_status_code_local == "Active", 
         cust_class_of_trade == "Physician", 
         dm_deleted_flag == "N", 
         dm_current_flag == "Y") -> cust

cust_child %>% 
  filter(da_deleted_flag == "N") -> cust_child

# Select relevance column -------------------------------------------------

event %>%  
  select(evnt_key, evnt_id, evnt_id, parent_evnt_id, 
         evnt_name, evnt_type, evnt_subtype) -> event

event_speaker %>% select(evnt_key, spk_key) -> event_speaker

speaker_profile %>% select(spk_key, cust_ak) %>%
  rename(cust_ak_speaker = cust_ak) -> speaker_profile

speaker_qual %>% select(spk_key, qualf_name) -> speaker_qual

event_attendee %>% 
  select(cust_ak_attendee = cust_ak, evnt_key) %>% 
  filter(!is.na(cust_ak_attendee)) -> event_attendee

cust %>%
  select(cust_ak ,cust_name, cust_veeva_id, cust_main_specialty_code, cust_2nd_specialty_code,
         cust_prmry_addr_state, cust_prmry_parent_name) -> cust

cust_child %>% 
  select(child_account_vod, parent_account_vod, primary_vod) -> cust_child

# Joining -----------------------------------------------------------------

# Small Meeting
event %>% 
  filter(evnt_type == "Small Meeting with External Speaker") %>% 
  left_join(event_speaker, by ="evnt_key") %>% 
  left_join(speaker_profile, by ="spk_key") %>%
  filter(!is.na(spk_key)) %>% 
  left_join(cust, by = c("cust_ak_speaker"="cust_ak"), suffix = c("", "_speaker")) %>%
  left_join(event_attendee, by = "evnt_key") %>%
  left_join(cust, by = c("cust_ak_attendee"="cust_ak"), suffix = c("", "_attendee")) %>% 
  arrange(evnt_key) %>% 
  filter(cust_main_specialty_code_attendee != "Nurse") -> event_select

event_select %>% 
  select(cust_ak_speaker, cust_ak_attendee) %>% 
  compute() -> event_select

# EIF Meeting
event %>% 
  filter(evnt_type == "EIF - Expert Input Forum") %>%
  left_join(event_speaker, by ="evnt_key") %>% 
  left_join(speaker_profile, by ="spk_key") %>%
  filter(!is.na(spk_key)) %>%
  left_join(cust, by = c("cust_ak_speaker"="cust_ak"), suffix = c("", "_speaker")) %>%
  arrange(evnt_key) -> event_eif

event_eif %>% 
  select(evnt_key, cust_ak_speaker) %>% 
  compute() -> event_eif

# Symposium Meeting
event %>% 
  filter(evnt_type %in% c("Sales Initiated Lecture/Symposium", "HQ Initiated Lecture/Symposia")) %>%
  left_join(event_speaker, by ="evnt_key") %>% 
  left_join(speaker_profile, by ="spk_key") %>%
  filter(!is.na(spk_key)) %>%
  left_join(cust, by = c("cust_ak_speaker"="cust_ak"), suffix = c("", "_speaker")) %>%
  arrange(evnt_key) -> event_sym

event_sym %>% 
  select(evnt_key, cust_ak_speaker) %>% 
  compute() -> event_sym

event_sym %>% 
  count(evnt_key) %>% 
  filter(n > 1) -> sym_filter

event_sym %>% 
  semi_join(sym_filter, by = "evnt_key") %>% 
  compute() -> event_sym

# Speaker Profile Table

speaker_profile %>% 
  left_join(speaker_qual, by ="spk_key") %>% 
  mutate(group = "Speaker") %>% 
  select(!spk_key) %>% 
  compute() -> speaker_prof_tbl
