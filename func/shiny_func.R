
vis_tidy_graph_filter <- function(graph_obj, score = "eigen", no_fil = 100) {
  
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
    visEdges(arrows =list(to = list(enabled = F)),
             color = list(color = "#95A5A6", highlight = "#2E4049")) %>%
    visOptions(height = "600px", 
               highlightNearest = TRUE, nodesIdSelection = TRUE) %>% 
    visGroups(groupname = "Speaker", color = list(background = "#00857C", 
                                                  border = "#0C2340",
                                                  highlight = "#6ECEB2")) %>%
    visGroups(groupname = "None", color = list(background = "#95A5A6", 
                                               border = "#0C2340",
                                               highlight = "#95A5A6")) %>%
    visInteraction(navigationButtons = TRUE)
  
}