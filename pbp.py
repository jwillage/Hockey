from lxml import html
import requests
import sys
import re

#implement default args
season = sys.argv[1]
gameId = sys.argv[2]

page = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/PL0' + gameId + '.HTM')
#page = requests.get('http://www.nhl.com/scores/htmlreports/20142015/PL030226.HTM')
tree = html.fromstring(page.text)
tokens = tree.xpath('//tr[@class="evenColor"]/td/text()')
plays = []
temp=[]

#check penl with no break and for pentype, time, st louis
x = 0
while x < len(tokens):
	temp = tokens[x:x + 6]
	splitList = tokens[x + 6].split(' ')
	playerPos = [ i for i, word in enumerate(splitList) if word.startswith('#') ]
	if temp[5] == 'SHOT':
		temp.append(splitList[0]) #shooting team
		if splitList[playerPos[0] + 1].endswith(','):	#single word player
			temp.append(splitList[playerPos[0] + 1][0 : -1])
		else:
			temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2][0 : -1])
		temp.append('')
		temp.append('')
		temp.append(splitList[-4]) #zone
		temp.append(splitList[-5][0 : -1]) #shot type
		temp.append(splitList[-2]) #distance
	elif temp[5] == 'BLOCK':
		temp.append(splitList[0]) #shooting team
		if splitList[playerPos[0] + 2] == 'BLOCKED':	#single word player
			temp.append(splitList[playerPos[0] + 1])
		else:
			temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
		temp.append(splitList[splitList.index('BY') + 2]) #blocking team
		if splitList[playerPos[1] + 1].endswith(','):	#single word player
			temp.append(splitList[playerPos[1] + 1][0 : -1])
		else:
			temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2][0 : -1])
		temp.append(splitList[-2]) #zone
		temp.append(splitList[-3][:-1]) #shotType
	elif temp[5] == 'FAC':	
		vs = splitList.index('vs')
		temp.append(splitList[0]) #winning team
		if temp[-1] == splitList[5]:	#if winning team = away team
			if splitList[playerPos[0] + 2] != '`':	#multi word player
				temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
			else:		#single word player
				temp.append(splitList[playerPos[0] + 1])
			temp.append(splitList[9]) #losing home team #TODO fix for 30224 317, st louis vs laich. try append(splitList[splitList.index('vs') + 1])
			if playerPos[1] + 1 != len(splitList) - 1:	#multi word player
				temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2])
			else:		#single word player
				temp.append(splitList[playerPos[1] + 1])
		else:	#home team won
			if playerPos[1] + 1 != len(splitList) - 1:	#multi word player	home
				temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2])
			else:		#single word player	home
				temp.append(splitList[playerPos[1] + 1])
			temp.append(splitList[playerPos[0] - 1]) #away team	
			if splitList[playerPos[0] + 2] != 'vs':	#multi word player
				temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
			else:		#single word player
				temp.append(splitList[playerPos[0] + 1])
		temp.append(splitList[2]) #zone
	elif temp[5] == 'HIT':			
		temp.append(splitList[0]) #hitting team
		if splitList[playerPos[0] + 2] != 'HIT':	#multi word player
			temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2])
		else:		#single word player
			temp.append(splitList[playerPos[0] + 1])
		temp.append(splitList[splitList.index('HIT') + 1]) #hit team
		if splitList[playerPos[1] + 1].endswith(','):	#single word player, hit
			temp.append(splitList[playerPos[1] + 1][0 : -1])
		else:	#multi word player, hit
			temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2][0 : -1])
		temp.append(splitList[-2]) #zone
	elif temp[5] == 'MISS':
		temp.append(splitList[0]) #shooting team
		if splitList[playerPos[0] + 1].endswith(','):	#single word player, shooter
			temp.append(splitList[playerPos[0] + 1][0 : -1]) #player name
			temp.append('')
			temp.append('')
			temp.append(splitList[-4]) #zone
			temp.append(splitList[3][0 : -1]) #shotType
			temp.append(splitList[-2]) #distance
			temp.append(splitList[4])	#result
		else:	#multi word player, shooter
			temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2][0 : -1])	#player name
			temp.append('')
			temp.append('')
			temp.append(splitList[-4]) #zone
			temp.append(splitList[4][0 : -1]) #shotType
			temp.append(splitList[-2]) #distance
			temp.append(splitList[5])	#result 
	elif temp[5] == 'GIVE' or temp[5] == 'TAKE':
		temp.append(splitList[0][:3].encode('ascii', 'ignore'))	#giveaway team
		if splitList[playerPos[0] + 1].endswith(','):	#single word player
			temp.append(splitList[playerPos[0] + 1][0 : -1].encode('ascii', 'ignore'))
		else:	#multi word player
			temp.append(splitList[playerPos[0] + 1].encode('ascii', 'ignore') + ' ' + splitList[playerPos[0] + 2][0 : -1].encode('ascii', 'ignore'))
		temp.append('')
		temp.append('')
		temp.append(splitList[-2].encode('ascii', 'ignore'))	#zone
	elif temp[5] == 'PSTR' or temp[5] == 'PEND' or temp[5] == 'GEND': #move gend and stop to the same (one has addl space?)
		temp[2] = ''
	elif temp[5] == 'STOP': 
		temp[2] = ''
		for a in range(0, 8, 1):
			temp.append('')
		temp.append(splitList[0])	#stoppage reason	#includes comma seperated tv timout if applicable, TODO fix and add mutli word stoppage reasons
	elif temp[5] == 'GOAL':
		temp.append(splitList[0])	#scoring team
		if splitList[playerPos[0] + 1].endswith(','):	#single word player
			temp.append(splitList[playerPos[0] + 1][0 : splitList[playerPos[0] + 1].index('(')])
		else:	#multi word player
			temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2][0 : splitList[playerPos[0] + 1].index('(')])
		temp.append('')
		temp.append('')
		temp.append(splitList[4])	#zone
		temp.append(splitList[3][:-1])	#shot type
		temp.append(splitList[6]) #dist 
		if tokens[x + 7][0:6] == 'Assist':	
			for a in range(0, 4, 1):
				temp.append('')
			assists = tokens[x + 7].split(' ')
			playerPos = [ i for i, word in enumerate(assists) if word.startswith('#') ]
			if assists[playerPos[0] + 1].find(')') != -1:	#single word player
				temp.append(assists[playerPos[0] + 1][0 : assists[playerPos[0] + 1].index('(')])
			else:	#multi word player
				temp.append(assists[playerPos[0] + 1] + ' ' + assists[playerPos[0] + 2][0 : assists[playerPos[0] + 2].index('(')])
			if tokens[x + 7][6:7] == 's':
				if assists[playerPos[1] + 1][-1] == ')':	#single word player
					temp.append(assists[playerPos[1] + 1][0 : assists[playerPos[1] + 1].index('(')])
				else:	#multi word player
					temp.append(assists[playerPos[1] + 1] + ' ' + assists[playerPos[1] + 2][0 : assists[playerPos[1] + 1].index('(')])
			else:
				temp.append('')
			x += 1
	elif temp[5] == 'PENL':
	#TODO multi word penl, ie game 30226 NYR #45 SHEPPARD Delaying Game-Puck over glass(2 min), Def. Zone
	#TODO major penalties and misconductsie 30224  265, 269	WSH #6 GLEASON Fighting (maj)(5 min), Def. Zone Drawn By: NYR #15 GLASS
	#TODO penalty shot ie 30224 300
		splitList = tokens[x + 6].encode('ascii', 'replace').split(' ')
		temp.append(splitList[0]) #team
		if splitList[playerPos[0] + 1].find('?') != -1:	#single word player
			temp.append(splitList[playerPos[0] + 1][0:splitList[playerPos[0] + 1].index('?')])	
			if splitList[splitList.index('min),') - 1].find('?') == -1 : #multi word penalty
				penType = splitList[playerPos[0] + 1][splitList[playerPos[0] + 1].index('?') + 1 : ] + ' ' + splitList[splitList.index('min),') - 1][0 : splitList[splitList.index('min),') - 1].index('(')]
				penTime = splitList[splitList.index('min),') - 1][splitList[splitList.index('min),') - 1].index('(') + 1 : ]
			else:
				penType = splitList[playerPos[0] + 1][splitList[playerPos[0] + 1].index('?') + 1 : splitList[playerPos[0] + 1].index('(')]
				penTime = splitList[playerPos[0] + 1][splitList[playerPos[0] + 1].index('(') + 1 : ]
		else: #multi word player
			temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2][0:splitList[playerPos[0] + 2].index('?')])
			if splitList[splitList.index('min),') - 1].find('?') == -1 : #multi word penalty
				penType = splitList[playerPos[0] + 2][splitList[playerPos[0] + 2].index('?') + 1 : ] + ' ' + splitList[splitList.index('min),') - 1][0 : splitList[splitList.index('min),') - 1].index('(')]
				penTime = splitList[splitList.index('min),') - 1][splitList[splitList.index('min),') - 1].index('(') + 1 : ]
			else:
				penType = splitList[playerPos[0] + 2][splitList[playerPos[0] + 2].index('?') + 1 : splitList[playerPos[0] + 2].index('(')]
				penTime = splitList[playerPos[0] + 2][splitList[playerPos[0] + 2].index('(') + 1 : ]
		if len(playerPos) > 1:	#if drawn by another player
			temp.append(splitList[playerPos[1] - 1])	#drawn by player's team name
			if playerPos[1] + 1 == len(splitList) - 1: #single word player
				temp.append(splitList[playerPos[1] + 1])
			else:	#multi word player
				temp.append(splitList[playerPos[1] + 1] + ' ' + splitList[playerPos[1] + 2])
		else:
			temp.append('')
			temp.append('')
		temp.append(splitList[splitList.index('Zone') - 1]) #zone
		for a in range(0, 4, 1):
			temp.append('')
		temp.append(penType)
		temp.append(penTime)
	plays.append(temp)
	x += 9

f = open("/mnt/hgfs/VM/" + season + "_" + gameId + "_pbp", 'w')
cnt = 0
f.write('season,gameId,totalElapsed,id,per,strength,elapsed,remaining,event,primaryTeam,primaryPlayer,secondaryTeam,secondaryPlayer,zone,shotType,distance,miss,stop,penType,penTime,firstAssist,secondAssist\r\n')

while cnt < len(plays):
	fieldCnt = 0
	f.write(season + ', ' + gameId + ', ' )
	#convert period elapsed time to game elapsed time
	f.write(str(((int(plays[cnt][1])-1)*20) +  int(plays[cnt][3][0 : plays[cnt][3].index(':')])) + ':' + 	str(plays[cnt][3][plays[cnt][3].index(':') + 1 : ]) + ', ')
	while fieldCnt < len(plays[cnt]):
		f.write(plays[cnt][fieldCnt].encode('utf-8'))
		if fieldCnt != len(plays[cnt])- 1:
			f.write(', ')
		else:
			f.write('\r\n')
		fieldCnt += 1
	cnt += 1

f.close()
