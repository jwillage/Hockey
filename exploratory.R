library(dplyr)

eventPlot <- function(pbp.in, event, strn){
  # Plot comparison graph given the event type and strength
  #
  # Args:
  #   pbp.in:     pbp object
  #   event:       Character vector of event(s) to report on. Valid options are "goal", "fac", 
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
  pbp.sub <- pbp.in %>%  filter(event %in% event, strength == strn) %>% group_by(primaryTeam) %>% 
    mutate(evNum = row_number())
  pbp.sub <- as.data.frame(pbp.sub)
  
  # Append dummy row to continue line to end of game
  for (i in teams){
    apnd <- pbp.sub[1, ]
    apnd$evNum <- with(subset(pbp.sub, primaryTeam == i), max(evNum))
    apnd$totalElapsed <- max(pbp.in$totalElapsed) 
    apnd$primaryTeam <- i
    pbp.sub <- rbind(pbp.sub, apnd)
  }
  
  title <- c(paste0(paste0(teams, collapse = " @ "), " Game ", gameId),
             paste(paste0(event, collapse = " "), "count by game time"))
  with(subset(pbp.sub, primaryTeam == away), 
       plot(totalElapsed, evNum, col = team.colors[away], type = "s", lwd = 2, main = title, 
            ylab = paste(paste0(event, collapse = " "), "count"), xlab = "Game Time"))
  with(subset(pbp.sub, primaryTeam == home), 
       lines(totalElapsed, evNum, col = team.colors[home], lwd = 2, type = "s"))
  
  for (i in teams){
    abline(v = as.numeric(gsub(":", ".", 
                               (pbp.in[pbp.in$event == "GOAL" & pbp.in$primaryTeam == i,
                                       "totalElapsed"]))), 
           lty = 2, col = team.colors[i])
  }
  
  legend("topleft", legend = c(home, away), lty = "solid", lwd = 2, 
         col = c(team.colors[home], team.colors[away]))
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
png("img/2015_20783.png")
eventPlot(pbp, corsi, "EV")
dev.off()
