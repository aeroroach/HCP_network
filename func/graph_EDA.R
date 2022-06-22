library(visNetwork)

route_hcp %>%
  activate(nodes) %>%
  as_tibble() %>%
  glimpse()

route_hcp %>%
  activate(nodes) %>%
  as_tibble() %>%
  distinct(cust_main_specialty_regroup)

route_hcp %>%
  activate(nodes) %>%
  filter(cust_main_specialty_regroup == "Otorhinolaryngology") %>% 
  as_tibble() %>%
  arrange(desc(eigen)) %>% 
  glimpse()

route_hcp %>%
  activate(nodes) %>%
  arrange(desc(betweeness)) %>%
  filter(cust_main_specialty_regroup == "Internal Medicine") %>%
  rename(value = eigen) %>%
  mutate(title = paste0('<p style="color:black"><b>',label,"</b></br>",
                        "eigen"," : ",value, "</br>",
                        title, "</p>")) %>%
  filter(row_number() <= 70) -> route_selected

route_selected %>%
  activate(nodes) %>%
  as_tibble() -> node_plot

route_selected %>%
  activate(edges) %>%
  mutate(id_from = .N()$id[from],
         id_to = .N()$id[to]) %>%
  as_tibble() %>%
  select(from = id_from, to = id_to, weight) -> edge_plot

visNetwork(node_plot, edge_plot) %>%
  visIgraphLayout(physics = T) %>%
  visEdges(arrows =list(to = list(enabled = F)),
           color = list(color = "#95A5A6", highlight = "#2E4049")) %>%
  visOptions(height = "600px", highlightNearest = TRUE) %>%
  visGroups(groupname = "Speaker", color = list(background = "#00857C",
                                                border = "#0C2340",
                                                highlight = list(background = "#6ECEB2",
                                                                 border = "#0C2340"))) %>%
  visGroups(groupname = "None", color = list(background = "#95A5A6",
                                             border = "#0C2340",
                                             highlight = list(background = "#95A5A6",
                                                              border = "#0C2340"))) %>%
  visInteraction(navigationButtons = TRUE)
