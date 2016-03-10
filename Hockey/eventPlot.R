library(dplyr)
library(ggplot2)
library(reshape2)

eventPlot <- function(pbp.in, info.in, evnt.in, strn.in, colors.in, show.pen = TRUE){
  # Plot comparison graph given the event type and strength
  #
  # Args:
  #   pbp.in:     pbp object
  #   info.in:    info object
  #   evnt.in:    Character vector of event(s) to report on. Valid options are "GOAL", "FAC", 
  #               "PENL", "BLOCK", "SHOT", "MISS", "GIVE", "TAKE", "CORSI", "FENWICK"
  #   strn.in:    Strength. Valid options are "EV", "SH", "PP", "ALL"
  #   colors.in:  Vector of length 2 containing the colors to be used for plotting, with 
  #               value names == team names. 
  #   show.pen:   TRUE or FALSE indicating whether or not to display penalty spans
  #
  # Returns:
  #  Plots a graph of event comparison by team
  #
  # TODO:
  #  Add optl parm to add vline for given event
  #  Handle teams with similar primary colors
  #  Add logic for penalties that don't last their full duration due to goal scored, addl penalties
  #  Add support for vector of events, strengths

  events <- c("GOAL", "FAC", "PENL", "BLOCK", "SHOT", "MISS", "GIVE", "TAKE", "CORSI", "FENWICK",
              "HIT")
  evnt.in <- switch(evnt.in,
                    "Goal" = "GOAL",
                    "Faceoff" = "FAC",
                    "Penalty" = "PENL",
                    "Block" = "BLOCK",
                    "Shot" = "SHOT",
                    "Miss" = "MISS",
                    "Giveaway" = "GIVE",
                    "Takeaway" = "TAKE",
                    "Corsi" = "CORSI",
                    "Fenwick" = "FENWICK",
                    "Hit" = "HIT"
                    )
  if (evnt.in == "CORSI") {
    evnt <- c("SHOT", "MISS", "BLOCK", "GOAL")
  } else if (evnt.in == "FENWICK") {
    evnt <- c("SHOT", "MISS", "GOAL")
  } else {
    evnt <- evnt.in
  }

  strn.in <- switch(strn.in,
                    "All" = "ALL",
                    "Even" = "EV",
                    "Power Play" = "PP",
                    "Short Handed" = "SH"
              )
  if (strn.in == "ALL") {
    strn <- c("EV", "PP", "SH")
  } else {
    strn <- strn.in
  }
  
  home <- info.in$home
  away <- info.in$away
  
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

  goals <- data.frame(goalTime = pbp.in[pbp.in$event == "GOAL", "totalElapsed"],
                      team = pbp.in[pbp.in$event == "GOAL", "primaryTeam"], 
                      stringsAsFactors = FALSE)
  g <- ggplot(data = pbp.sub, aes(totalElapsed, evNum, color = primaryTeam)) + 
    geom_vline(xintercept = pbp.in[pbp.in$event == "PEND", "totalElapsed"], color = "lightgrey") +
    geom_step(size = 1) + 
    scale_color_manual(values = colors.in[goals$team]) +
    geom_vline(data = goals, aes(xintercept = goalTime), color = colors.in[goals$team], 
               linetype = "longdash") +
    ggtitle(paste(away, "@", home, info.in$date, "\n",
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
    annotate("text", label = "@lustyandlewd", x = (max(pbp.in$totalElapsed) / 1.07)
             , y = max(pbp.sub$evNum)/50) 

  if (show.pen) {
    penl.idx <-pbp.in$event == "PENL"
    penalties <- data.frame(penStart = pbp.in[penl.idx, "totalElapsed"],
                            primaryTeam = pbp.in[penl.idx, "primaryTeam"],
                            length = pbp.in[penl.idx, "penTime"],
                            strength = pbp.in[penl.idx, "strength"], 
                            stringsAsFactors = FALSE)
    penalties$penEnd <- penalties$penStart + as.numeric(penalties$length)
    pens <- list()
    for (i in 1:nrow(penalties)) {
     pens[[i]] <- geom_area(data = melt(penalties[i, ], id = c("primaryTeam", "strength", "length")),
                            aes(x = value, y = max(pbp.sub$evNum)), position = "stack", alpha = 0.1, 
                            fill = colors.in[penalties[i, "primaryTeam"]], show.legend = FALSE) 
    }
    g <- g + unlist(pens)
  }
  
  g 
}

colorDiff <- function(x, y) {
  # Calculate the distance between colors
  #
  # Args:
  #   x:  RGB hex color
  #   y:  The other RGB hex color
  #
  # Returns:
  #  Integer value denoting the RGB Euclidean distance between colors
  #
  
  cols <- col2rgb(c(x, y))
  sum((cols[, 1] - cols[, 2]) ^ 2) ^ 0.5
}

# Create vector of each team's primary/secondary color for viz
team.colors = c(ANA = "#91764B", ARI = "#841F27", BOS = "#FFC422", 
                BUF = "#002E62", CGY = "#E03A3E", CAR = "#8E8E90", 
                CHI = "#E3263A", COL = "#8B2942", CBJ = "#00285C", 
                DAL = "#006A4E", DET = "#EC1F26", EDM = "#E66A20", 
                FLA = "#C8213F", L.A = "#AFB7BA", MIN = "#025736", 
                MTL = "#213770", NSH = "#FDBB2F", N.J = "#E03A3E", 
                NYI = "#F57D31", NYR = "#0161AB", OTT = "#D69F0F", 
                PHI = "#F47940", PIT = "#D1BD80", S.J = "#05535D", 
                STL = "#0546A0", T.B = "#013E7D", TOR = "#003777", 
                VAN = "#047A4A", WSH = "#CF132B", WPG = "#002E62",
                ANA.alt = "#000000", ARI.alt = "#EFE1C6", BOS.alt = "#000000", 
                BUF.alt = "#FDBB2F", CGY.alt = "#FFC758", CAR.alt = "#E03A3E", 
                CHI.alt = "#000000", COL.alt = "#01548A", CBJ.alt = "#E03A3E", 
                DAL.alt = "#000000", DET.alt = "#EC1F26", EDM.alt = "#003777", 
                FLA.alt = "#D59C05", L.A.alt = "#000000", MIN.alt = "#BF2B37", 
                MTL.alt = "#BF2F38", NSH.alt = "#002E62", N.J.alt = "#000000", 
                NYI.alt = "#00529B", NYR.alt = "#E6393F", OTT.alt = "#E4173E", 
                PHI.alt = "#000000", PIT.alt = "#000000", S.J.alt = "#F38F20", 
                STL.alt = "#FFC325", T.B.alt = "#C0C0C0", TOR.alt = "#003777", 
                VAN.alt = "#07346F", WSH.alt = "#00214E", WPG.alt = "#A8A9AD"
                )
# 
# season <- 2015
# gameId <- 20877
# 
# pbp <- read.csv(paste0("pbp/", season, "_", gameId, ".pbp"), na.strings = "", 
#                 stringsAsFactors = FALSE)
# info <- read.csv(paste0("pbp/", season, "_", gameId, ".info"), stringsAsFactors = FALSE)
# 
# home <- info$home
# away <- info$away
# 
# away.col <- ifelse (colorDiff(team.colors[home], team.colors[away]) > 80,
#                     team.colors[away],
#                     team.colors[paste0(away, ".alt")])
# gameColors <- c(team.colors[home], away.col)
# names(gameColors)[2] <- info$away
# 
# eventPlot(pbp, info, "Hit", "Power Play", gameColors, show.pen = TRUE)

