library(dplyr)

season <- 2015
gameId <- 20003
corsi <- c("SHOT", "MISS", "BLOCK", "GOAL")

eventPlot <- function(pbp.in, evnt, strn){
  # Plot comparison graph given the event type and strength
  #
  # Args:
  #   pbp.in: pbp object
  #   evnt:   Character vector of event(s) to report on. Valid options are "goal", "fac", "penl", 
  #           "block", "shot", "miss", "give"
  #   strn:   Strength. Valid options are "EV", "SH", "PP"
  #
  # Returns:
  #  Plots a graph of event comparison by team
  #
  # TODO:
  #  Change ylab based on event

  pbp.in$evNum <- 0
  # Cumulatively count all the events by primary team
  pbp.sub <- pbp.in %>%  filter(event %in% evnt, strength == strn) %>% group_by(primaryTeam) %>% 
             mutate(evNum = row_number())
  pbp.sub <- as.data.frame(pbp.sub)
  pbp.sub$totalElapsed <- strptime(pbp.sub$totalElapsed, "%M:%S")
  
  with(subset(pbp.sub, primaryTeam == away), 
       plot(totalElapsed, evNum, col = team.colors[away], type = "s", lwd = 2, main = evnt, 
            ylab = "Faceoffs Won", xlab = "Game Time"))
  with(subset(pbp.sub, primaryTeam == home), 
       lines(totalElapsed, evNum, col = team.colors[home], lwd = 2, type = "s"))
  
  #abline(v = as.POSIXct(pbp[which(pbp$event == "GOAL"), "totalElapsed"]), lty = 2,
  #       col = pbp[which(pbp$event == "GOAL"), "primaryTeam"])
  # to specify color, easiest to add each team's goals separately
  
  abline(v = as.POSIXct(strptime(pbp.in[which(pbp.in$event == "GOAL" & pbp.in$primaryTeam == away), 
                                        "totalElapsed"], "%M:%S")), 
         lty = 2, col = team.colors[away])
  abline(v = as.POSIXct(strptime(pbp.in[which(pbp.in$event == "GOAL" & pbp.in$primaryTeam == home), 
                                        "totalElapsed"], "%M:%S")), 
         lty = 2, col = team.colors[home])
  legend("right", legend = c(home, away), lty = "solid", lwd = 2, 
         col = c(team.colors[home], team.colors[away]))
  
  # ggplot(data = subset(pbp, event == "FAC"), 
  #       aes (x = totalElapsed, y = evNum, col = primaryTeam)) + geom_line()
  
}


pbp <- read.csv(paste0("C:/Users/JW186027/Documents/VM/", season, "_", gameId, "_", "pbp"), 
                na.strings = "", stringsAsFactors = FALSE)
pbp$primaryTeam <- as.factor(pbp$primaryTeam)
pbp$event <- as.factor(pbp$event)

# TODO assign home and away based on something other than level order
home <- levels(pbp$primaryTeam)[1]
away <- levels(pbp$primaryTeam)[2]


# Create vector of each team's primary color for viz
team.colors = c(ANA = "#91764B", ARI = "#841F27", BOS = "#FFC422", 
                BUF = "#002E62", CGY = "#E03A3E", CAR = "#8E8E90", 
                CHI = "#E3263A", COL = "#8B2942", CBJ = "#00285C", 
                DAL = "#006A4E", DET = "#EC1F26", EDM = "#E66A20", 
                FLA = "#C8213F", LAK = "#AFB7BA", MIN = "#025736", 
                MTL = "#213770", NSH = "#FDBB2F", NJD = "#E03A3E", 
                NYI = "#F57D31", NYR = "#0161AB", OTT = "#D69F0F", 
                PHI = "#F47940", PIT = "#D1BD80", SJS = "#05535D", 
                STL = "#0546A0", TBL = "#013E7D", TOR = "#003777", 
                VAN = "#047A4A", WSH = "#CF132B", WPG = "#002E62")
color.DF <- data.frame(team = as.factor(names(team.colors)), color = team.colors)

par(mfrow = c(2, 1))
eventPlot(pbp, "FAC", "EV")
eventPlot(pbp, corsi, "EV")
