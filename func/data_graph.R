
# Convert ID --------------------------------------------------------------

node_list %>% 
  mutate(id = as.character(id)) -> node_list

edge_list %>% 
  mutate(from = as.character(from), 
         to = as.character(to)) -> edge_list

# Covert to graph ---------------------------------------------------------

route_hcp <- tbl_graph(nodes = node_list, edges = edge_list,
                       node_key = "id",
                       directed = T)

route_hcp %>%
  morph(to_split, cust_main_specialty_regroup) %>% 
  activate(nodes) %>%
  mutate(eigen = round(centrality_pagerank(weights = weight, 
                                           directed = T) * 10000, digits = 2),
         betweeness = round(centrality_betweenness(weights = weight, 
                                                   directed = T) / 10, digits = 2)) %>% 
  unmorph() -> route_hcp
