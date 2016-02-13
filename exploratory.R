library(dplyr)

eventPlot <- function(pbp.in, evnt, strn){
  # Plot comparison graph given the event type and strength
  #
  # Args:
  #   pbp.in:     pbp object
  #   evnt:       Character vector of event(s) to report on. Valid options are "goal", "fac", 
  #               "penl", "block", "shot", "miss", "give"
  #   strn:       Strength. Valid options are "EV", "SH", "PP"
  #
  # Returns:
  #  Plots a graph of event comparison by team
  #
  # TODO:
  #  Add vlines at PEND markers
  #  Error check parms, convert "corsi", "fenwick", etc to literals
  #  Add option for penalties as a colored span
  
  pbp.in$totalElapsed <- as.numeric(gsub(":", ".", pbp.in$totalElapsed))
  # Cumulatively count all the events by primary team
  pbp.sub <- pbp.in %>%  filter(event %in% evnt, strength == strn) %>% group_by(primaryTeam) %>% 
    mutate(evNum = row_number())
  pbp.sub <- as.data.frame(pbp.sub)
  
  # Append dummy row to continue line to end of game and from 0 to first event
  for (i in teams){
    apnd <- pbp.sub[1, ]
    apnd$evNum <- with(subset(pbp.sub, primaryTeam == i), max(evNum))
    apnd$totalElapsed <- max(pbp.in$totalElapsed) 
    apnd$primaryTeam <- i
    pbp.sub <- rbind(pbp.sub, apnd)
    apnd$evNum <- 0
    apnd$totalElapsed <- 0
    pbp.sub <- rbind(pbp.sub, apnd)
  }

  goals <- data.frame(goalTime = pbp.in[pbp.in$event == "GOAL", "totalElapsed"],
                      team = pbp.in[pbp.in$event == "GOAL", "primaryTeam"], 
                      stringsAsFactors = FALSE)
  ggplot(data = pbp.sub, aes(totalElapsed, evNum, color = primaryTeam)) + 
    geom_step(size = 1) + 
    scale_color_manual(values = team.colors[goals$team]) +
    geom_vline(data = goals, aes(xintercept = goalTime), color = team.colors[goals$team], 
               linetype = "longdash") +
    geom_vline(xintercept = pbp.in[pbp.in$event == "PEND", "totalElapsed"], color = "lightgrey") +
    ggtitle(paste0(paste0(teams, collapse = " @ "), " Game ", gameId, "\n", 
                   tolower(paste(paste0(evnt, collapse = ", "))), " count by game time")) +
    ylab(paste(tolower(paste0(evnt, collapse = ", ")), "count")) +
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
    scale_y_continuous(expand = c(0, .5)) 
  
}

season <- 2015
gameId <- 20783

pbp <- read.csv(paste0("pbp/", season, "_", gameId, ".pbp"), na.strings = "", 
                stringsAsFactors = FALSE)
info <- read.csv(paste0("pbp/", season, "_", gameId, ".info"), stringsAsFactors = FALSE)

home <- info$home
away <- info$away
teams <- c(away, home)

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

corsi <- c("SHOT", "MISS", "BLOCK", "GOAL")
eventPlot(pbp, corsi, "EV")
