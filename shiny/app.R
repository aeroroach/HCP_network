library(tidyverse)
library(shiny)
library(DT)
library(tidygraph)
library(visNetwork)
library(shinythemes)
library(lubridate)
library(shinyWidgets)
library(shinycssloaders)
library(pins)

Sys.setlocale("LC_ALL", "th_TH.utf8")
Sys.setenv(R_CONFIG_ACTIVE = "production")
options(spinner.color = "#00857C", spinner.type = 2, spinner.color.background = "#fff",
        DT.options = list(pageLength = 10, dom = 'ftp',
                          columnDefs = list(list(width = '150px', targets = c(2,4,5,6))),
                          scrollX = TRUE))

# Loading object ----------------------------------------------------------

source("func/shiny_load.R")

# UI ----------------------------------------------------------------------

ui <- fluidPage(theme = shinytheme("flatly"),

    titlePanel("TH HCP Network"),
    
    column(6,
           fluidRow(
             
             column(3,
                    pickerInput("pick_score", 
                                label = "Circle Size", 
                                choices = list_score,
                                selected = "eigen"
                    )
             ),
             column(3,
                    pickerInput("pick_spec", 
                                label = "Main Specialty", 
                                choices = list_main_spec, 
                                selected = "Oncology"
                    )
             ), 
             column(3,
                    pickerInput("pick_sub_spec", 
                                label = "Sub Specialty", 
                                choices = init_sub,
                                selected = init_sub,
                                multiple = T, 
                                options = list(`actions-box` = T)
                    )
             ),
             column(3, 
                    pickerInput("pick_province", 
                                label = "Province", 
                                choices = list_province, 
                                selected = list_province,
                                multiple = T,
                                options = list(`actions-box` = T, 
                                               `live-search` = T)
                    )),
             
             tabsetPanel(
               tabPanel("Speaker", 
                        DTOutput("tbl_speaker") %>% 
                          withSpinner()
               ),
               
               tabPanel("Non Speaker",
                        DTOutput("tbl_non_speaker") %>% 
                          withSpinner()
               ),
               
               tabPanel("Highlight",
                        DTOutput("tbl_highlight") %>% 
                          withSpinner()
               )
               
             )
             
           )
    ),

    column(6,
           fluidRow(
             textOutput("data_as"),
           ),
           
           fluidRow(
             visNetworkOutput("hcp_visNetwork") %>% 
               withSpinner()
           ),
           textOutput("test_dt_input"),
           )
)

# Server ------------------------------------------------------------------


server <- function(input, output, session) {
  
# Dynamic drop-down -------------------------------------------------------

  sub_spec_react <- reactive({
    specialty_tbl %>% 
      filter(cust_main_specialty_regroup == input$pick_spec) -> list_sub_spec
    
    list_sub_spec$cust_2nd_specialty_regroup
    
  })
  
# Reactive input ----------------------------------------------------------

  spk_prof_react <- reactive({

    spk_prof_tbl %>%
      filter(cust_main_specialty_regroup == input$pick_spec, cust_prmry_addr_state %in% input$pick_province, 
             cust_2nd_specialty_regroup %in% input$pick_sub_spec) %>%
      select(id, label, qualf_name, cust_2nd_specialty_regroup, cust_prmry_addr_state, cust_prmry_parent_name, 
             eigen, betweeness) %>%
      semi_join(hcp_filter_node(), by = "id") %>% 
      arrange(desc(!!rlang::sym(input$pick_score)))
  })

  non_spk_react <- reactive({

    score <- input$pick_score

    non_spk_tbl %>%
      filter(cust_main_specialty_regroup == input$pick_spec, cust_prmry_addr_state %in% input$pick_province, 
             cust_2nd_specialty_regroup %in% input$pick_sub_spec) %>%
      select(id, label, qualf_name, cust_2nd_specialty_regroup, cust_prmry_addr_state, cust_prmry_parent_name, 
             eigen, betweeness) %>% 
      semi_join(hcp_filter_node(), by = "id") %>%
      arrange(desc(!!rlang::sym(input$pick_score)))
  })

  dt_spk_click <- reactive({
    spk_prof_react()$id[input$tbl_speaker_rows_selected]
  })

  dt_non_click <- reactive({
    non_spk_react()$id[input$tbl_non_speaker_rows_selected]
  })

  hcp_graph_react <- reactive({

    hcp_graph %>%
      activate(nodes) %>%
      arrange(desc(!!rlang::sym(input$pick_score))) %>%
      filter(cust_prmry_addr_state %in% input$pick_province ,
             cust_main_specialty_regroup == input$pick_spec, 
             cust_2nd_specialty_regroup %in% input$pick_sub_spec) %>%
      rename(value = !!rlang::sym(input$pick_score)) %>%
      mutate(title = paste0('<p style="color:black"><b>',label,"</b></br>",
                            input$pick_score," : ",round(value, digits = 3), "</br>",
                            cust_prmry_parent_name, "</p>")) %>%
      filter(row_number() <= n_node_filter)

  })

  hcp_filter_node <- reactive({

    hcp_graph_react() %>%
      activate(nodes) %>%
      as_tibble()

  })

  hcp_filter_edge <- reactive({

    hcp_graph_react() %>%
      activate(edges) %>%
      mutate(id_from = .N()$id[from],
             id_to = .N()$id[to]) %>%
      as_tibble() %>%
      select(from = id_from, to = id_to, width = weight) %>%
      mutate(width = width/5)

  })
  
  dt_highlight_react <- reactive({
    
    dt_click <- c(dt_spk_click(), dt_non_click())[1]
    
    if (length(dt_click)) {
      
      hcp_graph_react() %>% 
        activate(nodes) %>% 
        filter(node_is_adjacent(id %in% dt_click, include_to = F)) %>% 
        as_tibble() %>% 
        arrange(desc(value)) %>% 
        select(!c(group, cust_main_specialty_regroup, title))
      
      }
    
  })


# Output ------------------------------------------------------------------

  output$data_as <- renderText(paste("Data as of",begin_date,"to",end_date, ": The graph show only top 30 HCPs by selected score"))

  dt_colname <- c("id", "Name", "Qualification", "2nd Specialty", "Province", "HCO", "Eigen", "Betweeness")
  
  output$tbl_speaker <- renderDT(spk_prof_react(), selection = 'single',
                                 options = list(
                                   autoWidth = T,
                                   initComplete = JS(
                                     "function(settings, json) {",
                                     "$(this.api().table().header()).css({'background-color': '#00857C', 'color': '#fff'});",
                                     "}")),
                                 colnames = dt_colname
  )

  output$tbl_non_speaker <- renderDT(non_spk_react(), selection = 'single',
                                     options = list(
                                       autoWidth = T,
                                       initComplete = JS(
                                         "function(settings, json) {",
                                         "$(this.api().table().header()).css({'background-color': '#95A5A6', 'color': '#2E4049'});",
                                         "}")),
                                     colnames = dt_colname
  )
  
  output$tbl_highlight <- renderDT(dt_highlight_react(), selection = "none",
                                   options = list(
                                     autoWidth = T,
                                     initComplete = JS(
                                       "function(settings, json) {",
                                       "$(this.api().table().header()).css({'background-color': '#95A5A6', 'color': '#2E4049'});",
                                       "}")),
                                   colnames = dt_colname
                                   )

  output$hcp_visNetwork <- renderVisNetwork({

    visNetwork(hcp_filter_node(), hcp_filter_edge()) %>%
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
                                                 highlight = list(background = "#F7F7F7",
                                                                  border = "#0C2340"))) %>%
      visInteraction(navigationButtons = TRUE)
  })

   observe({
     visNetworkProxy("hcp_visNetwork", session = session) %>%
       visSelectNodes(id = c(dt_spk_click(), dt_non_click()))
   })
   
   observe({
     updatePickerInput(session = session,
                       inputId = "pick_sub_spec",
                       choices = sub_spec_react(),
                       selected = sub_spec_react())
   })
   

# Test Output -------------------------------------------------------------

   # output$test_dt_input <- renderText(c(dt_spk_click(), dt_non_click()))
    
}


# Run app -----------------------------------------------------------------

 
shinyApp(ui = ui, server = server)
