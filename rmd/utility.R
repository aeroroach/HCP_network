check_data_avai_1 <- function(data, date_col1) {
  
  col1 <- enquo(date_col1)
  
  col1_min <- paste0("min_", as_label(col1))
  col1_max <- paste0("max_", as_label(col1))
  
  data %>% 
    summarise(!!col1_min := min(!!col1), 
              !!col1_max := max(!!col1)
    ) -> tmp_result
  
  glimpse(tmp_result)
}

check_data_avai_2 <- function(data, date_col1, date_col2) {
  
  col1 <- enquo(date_col1)
  col2 <- enquo(date_col2)
  
  col1_min <- paste0("min_", as_label(col1))
  col1_max <- paste0("max_", as_label(col1))
  col2_min <- paste0("min_", as_label(col2))
  col2_max <- paste0("max_", as_label(col2))
    
  data %>% 
    summarise(!!col1_min := min(!!col1), 
              !!col1_max := max(!!col1),
              !!col2_min := min(!!col2), 
              !!col2_max := max(!!col2)
    ) -> tmp_result
              
  glimpse(tmp_result)
}

vis_tidy_graph_filter <- function(graph_obj, score, no_fil = 100) {
  
  key_measure <- enquo(score)
  
  graph_obj %>% 
    activate(nodes) %>% 
    rename(value = !!key_measure) %>% 
    mutate(title = paste0('<p style="color:black"><b>',label,"</b></br>",
                         as_label(key_measure)," : ",round(value, digits = 3), "</br>",
                         title, "</p>")) %>%
    arrange(value) %>% 
    top_n(no_fil) %>% 
    visIgraph(idToLabel = F, physics = T, type = "full") %>% 
    visGroups(groupname = "Speaker", color = list(background = "lightgreen", 
                                                  border = "darkgreen",
                                                  highlight = "green")) %>%
    visGroups(groupname = "None", color = list(background = "lightgrey", 
                                               border = "grey",
                                               highlight = "grey")) %>%
    visLegend(width = 0.05, position = "right") %>% 
    visInteraction(navigationButtons = TRUE)
  
}

getting_period <- function(year = 3) {
  
  begin_date <- floor_date(today("Asia/Bangkok") %m-% years(year), unit = "month")
  end_date <- ceiling_date(today("Asia/Bangkok") %m-% months(1), unit = "month") %m-% days(1)
  
  target <- list(begin = begin_date, 
                 end = end_date)
  
  return(target)
  
}
