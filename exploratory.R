library(dplyr)
library(ggplot2)

eventPlot <- function(pbp.in, evnt.in, strn.in){
  # Plot comparison graph given the event type and strength
  #
  # Args:
  #   pbp.in:     pbp object
  #   evnt.in:    Character vector of event(s) to report on. Valid options are "GOAL", "FAC", 
  #               "PENL", "BLOCK", "SHOT", "MISS", "GIVE", "TAKE", "CORSI", "FENWICK"
  #   strn.in:    Strength. Valid options are "EV", "SH", "PP", "ALL"
  #
  # Returns:
  #  Plots a graph of event comparison by team
  #
  # TODO:
  #  Add option for penalties as a colored span
  #  Add optl parm to add vline for given event
  #  Handle teams with similar primary colors
  #  Add logic for penalties that don't last their full duration due to goal scored, addl penalties

  events <- c("GOAL", "FAC", "PENL", "BLOCK", "SHOT", "MISS", "GIVE", "TAKE", "CORSI", "FENWICK")

  if (! evnt.in %in% events){
    stop("Event not found in play by play")
  }
  
  if (evnt.in == "CORSI") {
    evnt <- c("SHOT", "MISS", "BLOCK", "GOAL")
  } else if (evnt.in == "FENWICK") {
    evnt <- c("SHOT", "MISS", "GOAL")
  } else {
    evnt <- evnt.in
  }
  
  if (strn.in == "ALL") {
    strn <- c("EV", "PP", "SH")
  } else {
    strn <- strn.in
  }
  
  pbp.in$totalElapsed <- as.numeric(gsub(":", ".", pbp.in$totalElapsed))
  # Cumulatively count all the events by primary team
  pbp.sub <- pbp.in %>%  filter(event %in% evnt, strength %in% strn) %>% group_by(primaryTeam) %>% 
    mutate(evNum = row_number())
  pbp.sub <- as.data.frame(pbp.sub)
  
  # Append dummy row to continue line to end of game and from 0 to first event
  for (i in c(away, home)){
    apnd <- pbp.sub[1, ]
    apnd$evNum <- ifelse(nrow(pbp.sub[pbp.sub$primaryTeam == i, ]) > 0,
                         max(pbp.sub[pbp.sub$primaryTeam == i, "evNum"]), 
                         0
                  )
    apnd$totalElapsed <- max(pbp.in$totalElapsed) 
    apnd$primaryTeam <- i
    pbp.sub <- rbind(pbp.sub, apnd)
    # If looking at faceoffs, don't append 0th event for team that wins opening draw
    if (("FAC" %in% evnt & pbp.in[2, "primaryTeam"] == i))
      next
    apnd$evNum <- 0
    apnd$totalElapsed <- 0
    pbp.sub <- rbind(pbp.sub, apnd)
  }

  penl.idx <-pbp.in$event == "PENL"
  penalties <- data.frame(penStart = pbp.in[penl.idx, "totalElapsed"],
                          primaryTeam = pbp.in[penl.idx, "primaryTeam"],
                          length = pbp.in[penl.idx, "penTime"],
                          strength = pbp.in[penl.idx, "strength"], 
                          stringsAsFactors = FALSE)
  penalties$penEnd <- penalties$penStart + as.numeric(penalties$length)
  goals <- data.frame(goalTime = pbp.in[pbp.in$event == "GOAL", "totalElapsed"],
                      team = pbp.in[pbp.in$event == "GOAL", "primaryTeam"], 
                      stringsAsFactors = FALSE)
  g <- ggplot(data = pbp.sub, aes(totalElapsed, evNum, color = primaryTeam)) + 
    geom_vline(xintercept = pbp.in[pbp.in$event == "PEND", "totalElapsed"], color = "lightgrey") +
    geom_step(size = 1) + 
    scale_color_manual(values = team.colors[goals$team]) +
    geom_vline(data = goals, aes(xintercept = goalTime), color = team.colors[goals$team], 
               linetype = "longdash") +
    ggtitle(paste(away, "@", home, info$date, "\n",
                  tolower(evnt.in), "count by game time,",
                  tolower(strn.in), "strength")) +
    ylab(paste(tolower(evnt.in), "count")) +
    xlab("Game time") +
    theme(legend.position = c(0, 1), 
          legend.justification = c(0, 1), 
          legend.title = element_blank(), 
          legend.key = element_rect(fill = "white"), 
          legend.text = element_text(size = 16),
          axis.title = element_text(size = 16),
          axis.text = element_text(size = 14), 
          panel.background = element_rect(color = "black", fill = "white"),
          plot.background = element_rect(fill = "white", color = "white"),
          plot.title = element_text(size = 18)) +
    scale_x_continuous(expand = c(0, .5)) +
    scale_y_continuous(expand = c(0, max(pbp.sub$evNum))/100) +
    annotate("text", label = "@lustyandlewd", x = 58, y = 1) 

  pens <- list()
  for (i in 1:nrow(penalties)) {
   pens[[i]] <- geom_area(data = melt(penalties[i, ], id = c("primaryTeam", "strength", "length")),
                          aes(x = value, y = max(pbp.sub$evNum)), position = "stack", alpha = 0.1, 
                          fill = team.colors[penalties[i, "primaryTeam"]], show.legend = FALSE) 
  }
  g + unlist(pens)
   
}

# Create vector of each team's primary color for viz
team.colors = c(ANA = "#91764B", ARI = "#841F27", BOS = "#FFC422", 
                BUF = "#002E62", CGY = "#E03A3E", CAR = "#8E8E90", 
                CHI = "#E3263A", COL = "#8B2942", CBJ = "#00285C", 
                DAL = "#006A4E", DET = "#EC1F26", EDM = "#E66A20", 
                FLA = "#C8213F", `L.A` = "#AFB7BA", MIN = "#025736", 
                MTL = "#213770", NSH = "#FDBB2F", NJD = "#E03A3E", 
                NYI = "#F57D31", NYR = "#0161AB", OTT = "#D69F0F", 
                PHI = "#F47940", PIT = "#D1BD80", `S.J` = "#05535D", 
                STL = "#0546A0", TBL = "#013E7D", TOR = "#003777", 
                VAN = "#047A4A", WSH = "#CF132B", WPG = "#002E62")
color.DF <- data.frame(team = as.factor(names(team.colors)), color = team.colors)

season <- 2015
gameId <- 20858

pbp <- read.csv(paste0("pbp/", season, "_", gameId, ".pbp"), na.strings = "", 
                stringsAsFactors = FALSE)
info <- read.csv(paste0("pbp/", season, "_", gameId, ".info"), stringsAsFactors = FALSE)

home <- info$home
away <- info$away

eventPlot(pbp, "CORSI", "EV")
