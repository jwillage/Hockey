#local
library(dplyr)
library(ggplot2)
library(reshape2)

eventPlot <- function(pbp.in, info.in, evnt.in, strn.in, colors.in, show.pen = TRUE, 
                      vline.in = NULL){
  # Plot comparison graph given the event type and strength
  #
  # Args:
  #   pbp.in:     pbp object
  #   info.in:    info object
  #   evnt.in:    Character vector of event(s) to report on. Valid options are "Goal", "Faceoff", 
  #               "Penalty", "Block", "Shot", "Miss", "Giveaway", "Takeaway", "Corsi", "Fenwick",
  #               "Hit"
  #   strn.in:    Strength. Valid options are "Even", "Short Handed", "Power Play", "All"
  #   colors.in:  Vector of length 2 containing the colors to be used for plotting, with 
  #               value names == team names. 
  #   show.pen:   TRUE or FALSE indicating whether or not to display penalty spans
  #   vline.in:   An optional event that will be displayed as vertical lines on the plot. Accepts
  #               same options as evnt.in except corsi and fenwick.
  #
  # Returns:
  #  Plots a graph of event comparison by team
  #
  # TODO:
  #  Add support for vector of events, strengths
  
  events <- c("GOAL", "FAC", "PENL", "BLOCK", "SHOT", "MISS", "GIVE", "TAKE", "CORSI", "FENWICK",
              "HIT")
  evnt.pbp <- switch(evnt.in,
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
  if (evnt.pbp == "CORSI") {
    evnt <- c("SHOT", "MISS", "BLOCK", "GOAL")
  } else if (evnt.pbp == "FENWICK") {
    evnt <- c("SHOT", "MISS", "GOAL")
  } else {
    evnt <- evnt.pbp
  }
  
  strn.pbp <- switch(strn.in,
                     "All" = "ALL",
                     "Even" = "EV",
                     "PowerPlay" = "PP",
                     "ShortHanded" = "SH"
  )
  if (strn.pbp == "ALL") {
    strn <- c("EV", "PP", "SH")
  } else {
    strn <- strn.pbp
  }
  
  home <- info.in$home
  away <- info.in$away
  
  pbp.in$totalElapsed <- as.numeric(gsub(":", ".", pbp.in$totalElapsed))
  # Cumulatively count all the events by primary team
  pbp.sub <- pbp.in %>%  filter(event %in% evnt, strength %in% strn) %>% group_by(primaryTeam) %>% 
    mutate(evNum = row_number()) %>% as.data.frame()
  
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
  
  if (! is.null(vline.in)) {
    vline.in <- switch(vline.in,
                       "Goal" = "GOAL",
                       "Faceoff" = "FAC",
                       "Penalty" = "PENL",
                       "Block" = "BLOCK",
                       "Shot" = "SHOT",
                       "Miss" = "MISS",
                       "Giveaway" = "GIVE",
                       "Takeaway" = "TAKE",
                       "Hit" = "HIT")
    tmp <- data.frame(tmpTime = pbp.in[pbp.in$event == vline.in, "totalElapsed"],
                      team = pbp.in[pbp.in$event == vline.in, "primaryTeam"], 
                      stringsAsFactors = FALSE)
    vline <- geom_vline(data = tmp, aes(xintercept = tmpTime), color = colors.in[tmp$team]) 
  } else {
    vline <- NULL
  }
  
  g <- ggplot(data = pbp.sub, aes(totalElapsed, evNum, color = primaryTeam)) + 
    geom_vline(xintercept = pbp.in[pbp.in$event == "PEND", "totalElapsed"], color = "lightgrey") +
    vline + 
    geom_step(size = 1) + 
    scale_color_manual(values = colors.in) +
    geom_vline(data = goals, aes(xintercept = goalTime), color = colors.in[goals$team], 
               linetype = "longdash", size = 1) +
    ggtitle(paste(away, "@", home, info.in$date, "\n",
                  evnt.in, "count,",
                  strn.in, "strength")) +
    ylab(paste(evnt.in, "count")) +
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
    annotate("text", label = "@coldanalytics", x = (max(pbp.in$totalElapsed) / 1.08)
             , y = max(pbp.sub$evNum) / 50) 
  
  if (show.pen) {
    penl.idx <-pbp.in$event == "PENL"
    penalties <- data.frame(penStart = pbp.in[penl.idx, "totalElapsed"],
                            primaryTeam = pbp.in[penl.idx, "primaryTeam"],
                            length = pbp.in[penl.idx, "penTime"],
                            strength = pbp.in[penl.idx, "strength"], 
                            stringsAsFactors = FALSE)
    # Clean up misc characters 
    penalties$length <- as.numeric(gsub("[^0-9]", "", penalties$length))
    penalties <- penalties[complete.cases(penalties), ]
    
    penalties$penEnd <- penalties$penStart + as.numeric(penalties$length)
    # check for abbreviated penalties
    for (i in 1:nrow(penalties)) {
      penSpan <- seq(penalties[i, "penStart"], penalties[i, "penEnd"], by = 0.01)
      penSpan <- as.numeric(as.character(penSpan))
      pp <- goals$goalTime %in% penSpan
      if (sum(pp)) {
        #not always first. match up first pen with first goal, second pen with second goal, etc
        #handle penalties which turn up with start time == end time
        penalties[i, "penEnd"] <- goals[pp, "goalTime"][1]
      }
    }
    
    pens <- list()
    for (i in 1:nrow(penalties)) {
      dat <- melt(penalties[i, ], id = c("primaryTeam", "strength", "length"))
      if (dat[1, "value"] == dat[2, "value"]) {
        # penalties that occur at the same time as a goal mess up geom height, add a phony second
        # problem should not occur after fixing the above sum(pp) block
        dat[2, "value"] <- dat[2, "value"] + 0.01
      }
      pens[[i]] <- geom_area(data = dat,
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
                DAL.alt = "#000000", DET.alt = "#C1C1C1", EDM.alt = "#003777", 
                FLA.alt = "#D59C05", L.A.alt = "#000000", MIN.alt = "#BF2B37", 
                MTL.alt = "#BF2F38", NSH.alt = "#002E62", N.J.alt = "#000000", 
                NYI.alt = "#00529B", NYR.alt = "#E6393F", OTT.alt = "#E4173E", 
                PHI.alt = "#000000", PIT.alt = "#000000", S.J.alt = "#F38F20", 
                STL.alt = "#FFC325", T.B.alt = "#C0C0C0", TOR.alt = "#003777", 
                VAN.alt = "#07346F", WSH.alt = "#00214E", WPG.alt = "#A8A9AD",
                SWE = "#FFF033", FIN = "#E2231A", NAT = "#CF132B", EUR = "#002d62",
                RUS = "#ff0000", CZE = "#222f63", USA = "#002c61", CAN = "#e21737",
                SWE.alt = "#00539b", FIN.alt = "#E2D101", NAT.alt = "#000000", EUR.alt = "#01A5E2",
                RUS.alt = "#0175E2", CZE.alt = "#CF132B", USA.alt = "#D50000", CAN.alt = "#5b5b5b"
)