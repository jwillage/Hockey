library(shiny)
library(shinyjs)

shinyUI(
  fluidPage(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
                      @import url('//fonts.googleapis.com/css?family=Lobster|Cabin:400,700');
                      h1 {
                        font-family: 'Lobster', cursive;
                        font-weight: 500;
                        line-height: 1.1;
                        color: #48ca3b;
                          font-size: 400%;
                      }
                      #outer {
                        height: 10em;
                        line-height: 10em;
                      }

                      .nav.nav-pills{
                        align:right;
                        #background-color: silver;
                        float:right;
                      }

                      .blank{
                        background-color: transparent;
                        border-style: none;
                      }

                      button:focus {outline:0;}
                      "))
      ),
    headerPanel("Hockey"),
    tabsetPanel(position = "right", type = "pill",
      tabPanel("Viz",
      
    fluidRow(
      column(3, offset = 0,
             br(), br(),br(),
             numericInput("season", "Season", value = 2015, min = 2013, max = 2015),
             numericInput("gameId", "Game ID", value = 20973, min = 20002, max = 20984),
             selectInput("event", "Event", choices = c("Corsi", "Fenwick", "Goal", "Faceoff", 
                                                       "Penalty", "Block", "Shot","Miss", 
                                                       "Giveaway", "Takeaway", "Hit")),
             selectInput("strength", "Strength", choices = c("Even", "Power Play", "Short Handed",
                                                             "All")),
             #submitButton("Go"),
             
             HTML("<div>
                  <button type='submit' class='blank'>
                  <img height= 50 width = 100  src = 'img/go.png' />
                  </button>
                  </div>")
             ),
      column(9,
            plotOutput('resultPlot', width = "850px", height = "500px")
      )
    )
      ),
    tabPanel("Code", 
             fluidRow(
               column(9, offset = 1, 
               "", br(),br(),br(),
               strong("pbp.py"),
               HTML("<script>
               function toggleText() {
                 $('.text').toggle();
               }
             function toggleText2() {
                 $('.text2').toggle();
             }
              function toggleText3() {
                 $('.text3').toggle();
              }
             </script>
               <div onclick='toggleText()'>
               <div class='text' style='display:none'>Show</div>
               <div class='text' >Hide<br><br>
            "),
               pre(
               "
           from lxml import html
           import requests
           import sys
           import re
           import argparse
           
           parser = argparse.ArgumentParser(description='Process PBP file')
           parser.add_argument('season', type = str, \
                               help = 'Beginning year of season, ie \'2015\' for the 2015-2016 season')
           parser.add_argument('gameId', type = str, \
                               help = 'NHL game Id, used for Official Game Reports, ie \'20858\'')
           args = parser.parse_args()
           season = args.season
           gameId = args.gameId
           
           page = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + \
                               '/PL0' + gameId + '.HTM')
           tree = html.fromstring(page.text)
           tokens = tree.xpath('//tr[@class=\"evenColor\"]/td/text()')
           away = tree.xpath('//table[position()=1]/tr[position()=3]/td[position()=7]/text()')[0][0:3]
           home = tree.xpath('//table[position()=1]/tr[position()=3]/td[position()=8]/text()')[0][0:3]
           date = tree.xpath('//table/tr/td/table/tr/td/table/tr/td[position()=2]/table/' \
                             'tr[position()=4]/td/text()')[1].split(', ', 1)[1]
           plays = []
           temp=[]
           x = 0
           while x < len(tokens):
             try:
               temp = tokens[x:x + 6]
               splitList = tokens[x + 6].split(' ')
               playerPos = [ i for i, word in enumerate(splitList) if word.startswith('#') ]
               if temp[5] == 'SHOT':
                 temp.append(splitList[0]) # shooting team
               if splitList[playerPos[0] + 1].endswith(','):	# single word player
                 temp.append(splitList[playerPos[0] + 1][0 : -1])
               else:
                 temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2][0 : -1])
               temp.extend(('', ''))
               temp.append(splitList[-4]) # zone
               temp.append(splitList[-5][0 : -1]) # shot type
               temp.append(splitList[-2]) # distance
               elif temp[5] == 'BLOCK':
                 temp.append(splitList[0]) # shooting team
               if splitList[playerPos[0] + 2] == 'BLOCKED':	# single word player
                 temp.append(splitList[playerPos[0] + 1])
               else:
                 temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
               temp.append(splitList[splitList.index('BY') + 2]) # blocking team
               if splitList[playerPos[1] + 1].endswith(','):	# single word player
                 temp.append(splitList[playerPos[1] + 1][0 : -1])
               else:
                 temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2][0 : -1])
               temp.append(splitList[-2]) # zone
               temp.append(splitList[-3][:-1]) # shotType
               elif temp[5] == 'FAC':	
                 vs = splitList.index('vs')
               temp.append(splitList[0]) # winning team
               if temp[-1] == splitList[5]:	# if winning team == away
                 if splitList[playerPos[0] + 2] != '`':	# multi word player
                 temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
               else:		# single word player
                 temp.append(splitList[playerPos[0] + 1])
               temp.append(splitList[9]) # losing home team 
               if playerPos[1] + 1 != len(splitList) - 1:	# multi word player
                 temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2])
               else:		# single word player
                 temp.append(splitList[playerPos[1] + 1])
               else:	# winning team == home
                 if playerPos[1] + 1 != len(splitList) - 1:	# multi word player home
                 temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2])
               else:		# single word player	home
                 temp.append(splitList[playerPos[1] + 1])
               temp.append(splitList[playerPos[0] - 1]) # away team	
               if splitList[playerPos[0] + 2] != 'vs':	# multi word player
                 temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
               else:		# single word player
                 temp.append(splitList[playerPos[0] + 1])
               temp.append(splitList[2]) # zone
               elif temp[5] == 'HIT':			
                 temp.append(splitList[0]) # hitting team
               if splitList[playerPos[0] + 2] != 'HIT':	# multi word player
                 temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
               else:		# single word player
                 temp.append(splitList[playerPos[0] + 1])
               temp.append(splitList[splitList.index('HIT') + 1]) # team receiving hit
               if splitList[playerPos[1] + 1].endswith(','):	# single word player, hit
                 temp.append(splitList[playerPos[1] + 1][0 : -1])
               else:	# multi word player, hit
                 temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2][0 : -1])
               temp.append(splitList[-2]) # zone
               elif temp[5] == 'MISS':
                 temp.append(splitList[0]) # shooting team
               if splitList[playerPos[0] + 1].endswith(','):	# single word player, shooter
                 temp.append(splitList[playerPos[0] + 1][0 : -1]) # player
               temp.extend(('', ''))
               temp.append(splitList[-4]) #zone
               temp.append(splitList[3][0 : -1]) #shotType
               temp.append(splitList[-2]) #distance
               temp.append(splitList[4])	#result
               else:	# multi word player, shooter
                 temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2][0 : -1])	#player
               temp.extend(('', ''))
               temp.append(splitList[-4]) # zone
               temp.append(splitList[4][0 : -1]) # shotType
               temp.append(splitList[-2]) # distance
               temp.append(splitList[5])	# result 
               elif temp[5] == 'GIVE' or temp[5] == 'TAKE':
                 temp.append(splitList[0][:3].encode('ascii', 'ignore'))	# giveaway team
               if splitList[playerPos[0] + 1].endswith(','):	# single word player
                 temp.append(splitList[playerPos[0] + 1][0 : -1].encode('ascii', 'ignore'))
               else:	# multi word player
                 temp.append(splitList[playerPos[0] + 1].encode('ascii', 'ignore') + ' ' + \
                             splitList[playerPos[0] + 2][0 : -1].encode('ascii', 'ignore'))
               temp.extend(('', ''))
               temp.append(splitList[-2].encode('ascii', 'ignore'))	# zone
               elif temp[5] == 'PSTR' or temp[5] == 'PEND' or temp[5] == 'GEND': 
                 temp[2] = ''
               elif temp[5] == 'STOP': 
                 temp[2] = ''
               temp.extend(['' for i in xrange(4)])
               temp.append(splitList[0])	# stoppage reason, includes comma seperated tv timout if applicable
               elif temp[5] == 'GOAL':
                 temp.append(splitList[0])	# scoring team
               if splitList[playerPos[0] + 1].endswith(','):	# single word player
                 temp.append(splitList[playerPos[0] + 1][0 : splitList[playerPos[0] + 1].index('(')])
               else:	# multi word player
                 temp.append(splitList[playerPos[0] + 1] + ' ' + \
                             splitList[playerPos[0] + 2][0 : splitList[playerPos[0] + 1].index('(')])
               temp.extend(('', ''))
               temp.append(splitList[4])	# zone
               temp.append(splitList[3][:-1])	# shot type
               temp.append(splitList[6]) # dist 
               if tokens[x + 7][0:6] == 'Assist':	
                 temp.extend(['' for i in xrange(4)])
               assists = tokens[x + 7].split(' ')
               playerPos = [ i for i, word in enumerate(assists) if word.startswith('#') ]
               if assists[playerPos[0] + 1].find(')') != -1:	# single word player
                 temp.append(assists[playerPos[0] + 1][0 : assists[playerPos[0] + 1].index('(')])
               else:	#multi word player
                 temp.append(assists[playerPos[0] + 1] + ' ' + \
                             assists[playerPos[0] + 2][0 : assists[playerPos[0] + 2].index('(')])
               if tokens[x + 7][6:7] == 's':
                 if assists[playerPos[1] + 1][-1] == ')':	# single word player
                 temp.append(assists[playerPos[1] + 1][0 : assists[playerPos[1] + 1].index('(')])
               else:	#multi word player
                 temp.append(assists[playerPos[1] + 1] + ' ' + \
                             assists[playerPos[1] + 2][0 : assists[playerPos[1] + 1].index('(')])
               else:
                 temp.append('')
               x += 1
               elif temp[5] == 'PENL':
                 splitList = tokens[x + 6].encode('ascii', 'replace').split(' ')
               temp.append(splitList[0]) # Penalized team
               mindex = [s for s in splitList if 'min' in s][0]
               if splitList[1].find('TEAM') == -1: # Player penalty
                 if splitList[playerPos[0] + 1].find('?') != -1:	# single word player
                 temp.append(splitList[playerPos[0] + 1][0:splitList[playerPos[0] + 1].index('?')])	
               if splitList[splitList.index(mindex) - 1].find('?') == -1 : # multi word penalty if no '?'
                 penType = splitList[playerPos[0] + 1][splitList[playerPos[0] + 1].index('?') + 1 : ] + \
               ' ' + splitList[splitList.index(mindex) - 1] \
               [0 : splitList[splitList.index(mindex) - 1].index('(')]
               penTime = splitList[splitList.index(mindex) - 1] \
               [splitList[splitList.index(mindex) - 1].index('(') + 1 : ]
               else:
                 penType = splitList[playerPos[0] + 1] \
               [splitList[playerPos[0] + 1].index('?') + 1 : \
                splitList[playerPos[0] + 1].index('(')]
               penTime = splitList[playerPos[0] + 1][splitList[playerPos[0] + 1].index('(') + 1 : ]
               else: # multi word player
                 temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2] \
                             [0:splitList[playerPos[0] + 2].index('?')])
               if splitList[splitList.index(mindex) - 1].find('?') == -1 : # multi word penalty
                 penType = splitList[playerPos[0] + 2][splitList[playerPos[0] + 2].index('?') + 1 : ] + \
               ' ' + splitList[splitList.index(mindex) - 1] \
               [0 : splitList[splitList.index(mindex) - 1].index('(')]
               penTime = splitList[splitList.index(mindex) - 1] \
               [splitList[splitList.index(mindex) - 1].index('(') + 1 : ]
               else:
                 penType = splitList[playerPos[0] + 2] \
               [splitList[playerPos[0] + 2].index('?') + 1 : \
                splitList[playerPos[0] + 2].index('(')]
               penTime = splitList[playerPos[0] + 2][splitList[playerPos[0] + 2].index('(') + 1 : ]
               if (tokens[x + 6].find('Drawn') != -1):
                 temp.append(splitList[playerPos[1] - 1])	# drawn by player's team name
               if playerPos[1] + 1 == len(splitList) - 1: # single word player
                 temp.append(splitList[playerPos[1] + 1])
               else:	# multi word player
                 temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2])
               else:
                 temp.extend(('', ''))
               temp.append(splitList[splitList.index('Zone') - 1]) # zone
               else: # Team penalty
                 temp.append('TEAM')
               temp.extend(('', '', '')) # Zone not always entered. Always leave blank for consistency 
               if splitList[1].find('Too') == -1:
                 penType = 'Unknown'
               else:
                 penType = 'Too many men'
               penTime = tokens[x + 6].encode('ascii', 'replace') \
               [tokens[x + 6].find('(') + 1:tokens[x + 6].find('(') + 2]
               temp.extend(('', '', '', ''))
               temp.append(penType)
               temp.append(penTime)
               plays.append(temp)
               if(temp[5] != 'GEND'):
                 j = 7
               while((tokens[x + j] == \'\\r\\n\' or tokens[x + j].encode('ascii', 'ignore') == '')):
                 j += 1
               x += j
               else:
                 x += 11
           except ValueError:
             print('Exception on play ' + str(len(plays)))
             j = 7
             while((tokens[x + j] == \'\\r\\n\' or tokens[x + j].encode('ascii', 'ignore') == '')):
               j += 1
             x += j
             continue
           
           
           info = open('/Users/jw186027/Documents/Personal/Analytics/Sports/Hockey/pbp/' + season + '_' + 
                         gameId + '.info', 'w')
           info.write('season,gameId,date,home,away\\r\\n')
           info.write(season + ',' + gameId + ',' + '\"' + date + '\",' + home + ',' + away + '\\r\\n')
           info.close()
           
           # f = open('/mnt/hgfs/VM/' + season + '_' + gameId + '_pbp', 'w')
           f = open('/Users/jw186027/Documents/Personal/Analytics/Sports/Hockey/pbp/' + season + '_' + gameId +
                      '.pbp', 'w')
           cnt = 0
           f.write('totalElapsed,id,per,strength,elapsed,remaining,event,primaryTeam,primaryPlayer,' \
                   'secondaryTeam,secondaryPlayer,zone,shotType,distance,miss,stop,penType,penTime,' \
                   'firstAssist,secondAssist\\r\\n')
           
           while cnt < len(plays):
             fieldCnt = 0
           #convert period elapsed time to game elapsed time
           f.write(str(((int(plays[cnt][1])-1)*20) +  int(plays[cnt][3][0 : plays[cnt][3].index(':')])) + 
                     ':' + 	str(plays[cnt][3][plays[cnt][3].index(':') + 1 : ]) + ', ')
           while fieldCnt < len(plays[cnt]):
             f.write(plays[cnt][fieldCnt].encode('utf-8'))
           if fieldCnt != len(plays[cnt])- 1:
             f.write(',')
           else:
             f.write('\\r\\n')
           fieldCnt += 1
           cnt += 1
           
           f.close()
               "
               ) # pre
               , HTML(" </div>
               </div>"),
               strong("eventPlot.R"),
               HTML("
                    <div onclick='toggleText2()'>
                    <div class='text2' style='display:none'>Show</div>
                    <div class='text2' >Hide<br><br>
                    "),
               pre("

library(dplyr)
library(ggplot2)
library(reshape2)

eventPlot <- function(pbp.in, info.in, evnt.in, strn.in, colors.in, show.pen = TRUE){
  # Plot comparison graph given the event type and strength
  #
  # Args:
  #   pbp.in:     pbp object
  #   info.in:    info object
  #   evnt.in:    Character vector of event(s) to report on. Valid options are 'GOAL', 'FAC', 
  #               'PENL', 'BLOCK', 'SHOT', 'MISS', 'GIVE', 'TAKE', 'CORSI', 'FENWICK', 'HIT'
  #   strn.in:    Strength. Valid options are 'EV', 'SH', 'PP', 'ALL'
  #   colors.in:  Vector of length 2 containing the colors to be used for plotting, with 
  #               value names == team names. 
  #   show.pen:   TRUE or FALSE indicating whether or not to display penalty spans
  #
  # Returns:
  #  Plots a graph of event comparison by team
  #
  # TODO:
  #  Add support for vector of events, strengths
  
  events <- c('GOAL', 'FAC', 'PENL', 'BLOCK', 'SHOT', 'MISS', 'GIVE', 'TAKE', 'CORSI', 'FENWICK')
  evnt.in <- switch(evnt.in,
                    'Goal' = 'GOAL',
                    'Faceoff' = 'FAC',
                    'Penalty' = 'PENL',
                    'Block' = 'BLOCK',
                    'Shot' = 'SHOT',
                    'Miss' = 'MISS',
                    'Giveaway' = 'GIVE',
                    'Takeaway' = 'TAKE',
                    'Corsi' = 'CORSI',
                    'Fenwick' = 'FENWICK'
  )
  
  if (! evnt.in %in% events){
    stop('Event not found in play by play')
  }
  
  if (evnt.in == 'CORSI') {
    evnt <- c('SHOT', 'MISS', 'BLOCK', 'GOAL')
  } else if (evnt.in == 'FENWICK') {
    evnt <- c('SHOT', 'MISS', 'GOAL')
  } else {
    evnt <- evnt.in
  }
  
  strn.in <- switch(strn.in,
                    'All' = 'ALL',
                    'Even' = 'EV',
                    'Power Play' = 'PP',
                    'Short Handed' = 'SH'
  )
  if (strn.in == 'ALL') {
    strn <- c('EV', 'PP', 'SH')
  } else {
    strn <- strn.in
  }
  
  home <- info.in$home
  away <- info.in$away
  
  pbp.in$totalElapsed <- as.numeric(gsub(':', '.', pbp.in$totalElapsed))
  # Cumulatively count all the events by primary team
  pbp.sub <- pbp.in %>%  filter(event %in% evnt, strength %in% strn) %>% group_by(primaryTeam) %>% 
    mutate(evNum = row_number())
  pbp.sub <- as.data.frame(pbp.sub)
  
  # Append dummy row to continue line to end of game and from 0 to first event
  for (i in c(away, home)){
    apnd <- pbp.sub[1, ]
    apnd$evNum <- ifelse(nrow(pbp.sub[pbp.sub$primaryTeam == i, ]) > 0,
                         max(pbp.sub[pbp.sub$primaryTeam == i, 'evNum']), 
                         0
    )
    apnd$totalElapsed <- max(pbp.in$totalElapsed) 
    apnd$primaryTeam <- i
    pbp.sub <- rbind(pbp.sub, apnd)
    # If looking at faceoffs, don't append 0th event for team that wins opening draw
    if (('FAC' %in% evnt & pbp.in[2, 'primaryTeam'] == i))
      next
    apnd$evNum <- 0
    apnd$totalElapsed <- 0
    pbp.sub <- rbind(pbp.sub, apnd)
  }
  
  goals <- data.frame(goalTime = pbp.in[pbp.in$event == 'GOAL', 'totalElapsed'],
                      team = pbp.in[pbp.in$event == 'GOAL', 'primaryTeam'], 
                      stringsAsFactors = FALSE)
  g <- ggplot(data = pbp.sub, aes(totalElapsed, evNum, color = primaryTeam)) + 
    geom_vline(xintercept = pbp.in[pbp.in$event == 'PEND', 'totalElapsed'], color = 'lightgrey') +
    geom_step(size = 1) + 
    scale_color_manual(values = colors.in[goals$team]) +
    geom_vline(data = goals, aes(xintercept = goalTime), color = colors.in[goals$team], 
               linetype = 'longdash') +
    ggtitle(paste(away, '@', home, info.in$date, '\\n',
                  tolower(evnt.in), 'count by game time,',
                  tolower(strn.in), 'strength')) +
    ylab(paste(tolower(evnt.in), 'count')) +
    xlab('Game time') +
    theme(legend.position = c(0, 1), 
          legend.justification = c(0, 1), 
          legend.title = element_blank(), 
          legend.key = element_rect(fill = 'white'), 
          legend.text = element_text(size = 16),
          axis.title = element_text(size = 16),
          axis.text = element_text(size = 14), 
          panel.background = element_rect(color = 'black', fill = 'white'),
          plot.background = element_rect(fill = 'white', color = 'white'),
          plot.title = element_text(size = 18)) +
    scale_x_continuous(expand = c(0, .5)) +
    scale_y_continuous(expand = c(0, max(pbp.sub$evNum))/100) +
    annotate('text', label = '@lustyandlewd', x = (max(pbp.in$totalElapsed) / 1.07)
             , y = max(pbp.sub$evNum)/50) 
  
  if (show.pen) {
    penl.idx <-pbp.in$event == 'PENL'
    penalties <- data.frame(penStart = pbp.in[penl.idx, 'totalElapsed'],
                            primaryTeam = pbp.in[penl.idx, 'primaryTeam'],
                            length = pbp.in[penl.idx, 'penTime'],
                            strength = pbp.in[penl.idx, 'strength'], 
                            stringsAsFactors = FALSE)
    penalties$penEnd <- penalties$penStart + as.numeric(penalties$length)
    pens <- list()
    for (i in 1:nrow(penalties)) {
      pens[[i]] <- geom_area(data = melt(penalties[i, ], id = c('primaryTeam', 'strength', 'length')),
                             aes(x = value, y = max(pbp.sub$evNum)), position = 'stack', alpha = 0.1, 
                             fill = colors.in[penalties[i, 'primaryTeam']], show.legend = FALSE) 
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
team.colors = c(ANA = '#91764B', ARI = '#841F27', BOS = '#FFC422', 
                BUF = '#002E62', CGY = '#E03A3E', CAR = '#8E8E90', 
                CHI = '#E3263A', COL = '#8B2942', CBJ = '#00285C', 
                DAL = '#006A4E', DET = '#EC1F26', EDM = '#E66A20', 
                FLA = '#C8213F', `L.A` = '#AFB7BA', MIN = '#025736', 
                MTL = '#213770', NSH = '#FDBB2F', `N.J` = '#E03A3E', 
                NYI = '#F57D31', NYR = '#0161AB', OTT = '#D69F0F', 
                PHI = '#F47940', PIT = '#D1BD80', `S.J` = '#05535D', 
                STL = '#0546A0', `T.B` = '#013E7D', TOR = '#003777', 
                VAN = '#047A4A', WSH = '#CF132B', WPG = '#002E62',
                ANA.alt = '#000000', ARI.alt = '#EFE1C6', BOS.alt = '#000000', 
                BUF.alt = '#FDBB2F', CGY.alt = '#FFC758', CAR.alt = '#E03A3E', 
                CHI.alt = '#000000', COL.alt = '#01548A', CBJ.alt = '#E03A3E', 
                DAL.alt = '#000000', DET.alt = '#EC1F26', EDM.alt = '#003777', 
                FLA.alt = '#D59C05', L.A.alt = '#000000', MIN.alt = '#BF2B37', 
                MTL.alt = '#BF2F38', NSH.alt = '#002E62', N.J.alt = '#000000', 
                NYI.alt = '#00529B', NYR.alt = '#E6393F', OTT.alt = '#E4173E', 
                PHI.alt = '#000000', PIT.alt = '#000000', S.J.alt = '#F38F20', 
                STL.alt = '#FFC325', T.B.alt = '#C0C0C0', TOR.alt = '#003777', 
                VAN.alt = '#07346F', WSH.alt = '#00214E', WPG.alt = '#A8A9AD'
)
                ") # pre
               , HTML(" </div>
               </div>"),
               strong("colors.R"),
               HTML("
                    <div onclick='toggleText3()'>
                    <div class='text3' style='display:none'>Show</div>
                    <div class='text3' >Hide<br><br>
                    "),
               pre("
source('exploratory.R')

colorInv <- function(x) {
  # Finds the inverse of a color
  #
  # Args:
  #   x:  RGB hex color
  #
  # Returns:
  #  Inverse hexadecimal character representation of the input string
  #
  
  inv <- as.hexmode(255 - col2rgb(x))
  paste0('#', paste0(inv, collapse = ''))
}

plot(c(1, 29), c(1, 29), type = 'n', xlab = '', ylab = '',axes = FALSE,
     main = 'Pairwise Compairson of Team's Primary Colors')
axis(1, at = seq(0.5, 29.5, by = 1), labels = names(team.colors[1:30]), las = 2)
axis(2, at = seq(0.5, 29.5, by = 1), labels = names(team.colors[1:30]), las = 2)

for (i in 1:30){
  for (j in 1:30){
    polygon(c(i - 1, i, i, i - 1), c(j - 1, j - 1, j, j - 1), col = team.colors[j])
    polygon(c(j, j - 1, j - 1, j), c(i, i, i - 1, i), col = team.colors[j])
  }
}

for (i in 1:30){
  for (j in 1:30){
    diff <- colorDiff(team.colors[i], team.colors[j])
    if (diff < 75){
      text(i - 0.5, j - 0.5, labels = as.character(round(diff)), cex = 0.75, 
           col = colorInv(team.colors[i]), font = 2)
    }
  }
}

mtext('@lustyandlewd', 1, at = 25, padj = 5)

                ") # pre
               , HTML(" </div>
               </div>")
               ) # column
             ) # fluidRow
    ) # tab
    ) # tabSet
  ) # fluidPage
) # shinyUI