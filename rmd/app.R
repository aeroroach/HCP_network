# specialty_tbl %>% 
#   filter(cust_main_specialty_regroup == "Internal Medicine") -> tmp_main
# 
# tmp_main$cust_2nd_specialty_regroup


library("dplyr")
library("shiny")

data("world.cities", package = "maps")

ui <- fluidPage(
  sliderInput(inputId = "n", label = "n", min = 10, max = 30, value = 10),
  selectInput(inputId = "cities", label = "Select City", choices = NULL)
)

server <- function(input, output, session) {
  
  choices_cities <- reactive({
    choices_cities <- world.cities %>%
      arrange(desc(pop)) %>%
      top_n(n = input$n, wt = pop) 
  })
  
  observe({
    updateSelectInput(session = session, inputId = "cities", choices = choices_cities()$name)
  })
}

shinyApp(ui = ui, server = server)
