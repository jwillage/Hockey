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
# page = requests.get('http://www.nhl.com/scores/htmlreports/20152016/PL020846.HTM')
tree = html.fromstring(page.text)
tokens = tree.xpath('//tr[@class="evenColor"]/td/text()')
away = tree.xpath('//table[position()=1]/tr[position()=3]/td[position()=7]/text()')[0][0:3]
home = tree.xpath('//table[position()=1]/tr[position()=3]/td[position()=8]/text()')[0][0:3]
date = tree.xpath('//table/tr/td/table/tr/td/table/tr/td[position()=2]/table/' \
                  'tr[position()=4]/td/text()')[1].split(', ', 1)[1]
plays = []
temp=[]
x = 0

while x < len(tokens):
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
		temp.append(splitList[0][:3])	# giveaway team
		if splitList[playerPos[0] + 1].endswith(','):	# single word player
			temp.append(splitList[playerPos[0] + 1][0 : -1])
		else:	# multi word player
			temp.append(splitList[playerPos[0] + 1] + ' ' + splitList[playerPos[0] + 2][0 : -1])
		temp.extend(('', ''))
		temp.append(splitList[-2])	# zone
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
			penTime = tokens[x + 6][tokens[x + 6].find('(') + 1:tokens[x + 6].find('(') + 2]
		temp.extend(('', '', '', ''))
		temp.append(penType)
		temp.append(penTime)
	plays.append(temp)
	if(temp[5] != 'GEND'):
		j = 7
		while((tokens[x + j] == '\r\n' or tokens[x + j] == '')):
			j += 1
		x += j
	else:
		x += 11

info = open('/Users/jw186027/Documents/Personal/Analytics/Sports/Hockey/pbp/' + season + '_' + 
gameId + '.info', 'w')
info.write('season,gameId,date,home,away\r\n')
info.write(season + ',' + gameId + ',' + '"' + date + '",' + home + ',' + away + '\r\n')
info.close()

# f = open('/mnt/hgfs/VM/' + season + '_' + gameId + '_pbp', 'w')
f = open('/Users/jw186027/Documents/Personal/Analytics/Sports/Hockey/pbp/' + season + '_' + gameId +
    '.pbp', 'w')
cnt = 0
f.write('totalElapsed,id,per,strength,elapsed,remaining,event,primaryTeam,primaryPlayer,' \
        'secondaryTeam,secondaryPlayer,zone,shotType,distance,miss,stop,penType,penTime,' \
        'firstAssist,secondAssist\r\n')

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
			f.write('\r\n')
		fieldCnt += 1
	cnt += 1

f.close()
