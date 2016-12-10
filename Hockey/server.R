source("eventPlot.R")

shinyServer(
  function(input, output, session) {

    onclick("toggleAdvanced", toggle(id = "advanced", anim = TRUE))
    
    observeEvent(input$btn, {
      # Change the following line for more examples
      toggle("element")
      print("togs")
    })
    
    
    output$resultPlot <- renderPlot({
      py <- paste("python ../pbp.py", input$season, input$gameId)
      system(py)
      pbp <- read.csv(paste0("../pbp/", input$season, "_", input$gameId, ".pbp"), na.strings = "", 
                      stringsAsFactors = FALSE)
      info <- read.csv(paste0("../pbp/", input$season, "_", input$gameId, ".info"), 
                       stringsAsFactors = FALSE)
      
      home <- info$home
      away <- info$away
      
      away.col <- ifelse (colorDiff(team.colors[home], team.colors[away]) > 80,
                          team.colors[away],
                          team.colors[paste0(away, ".alt")])
      gameColors <- c(team.colors[home], away.col)
      names(gameColors)[2] <- info$away
      
      eventPlot(pbp, info, input$event, input$strength, gameColors, show.pen = TRUE)
    })
  }
)