from lxml import html
import requests
import sys
import re

#implement default args
season = sys.argv[1]
gameId = sys.argv[2]

awayPage = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/TV0' + gameId + '.HTM')
# awayPage = requests.get('http://www.nhl.com/scores/htmlreports/20142015/TV030227.HTM')
awayTree = html.fromstring(awayPage.text)
awayPlayers = awayTree.xpath('//table/tr[position()=4]/td/table/tr/td[@class="playerHeading + border"]/text()')

#get period, shift start, shift duration
awayShifts = awayTree.xpath('//table[position() = 1]/tr[position()=4]/td/table/tr[contains(@class, "Color")]/td[position() = 2 or position() = 3 or position() = 5]/text()')

#get the total number of shifts for each player
shiftCount = awayTree.xpath('//td[@colspan="8"]/table/tr[position() = last()]/td[position() = 2]/text()')

x = []

cum = 0
temp = []
for i in range(0, len(awayPlayers)):
	temp = []
	#append player name 
	temp.append(awayPlayers[i][awayPlayers[i].index(',') + 2 : ] + awayPlayers[i][awayPlayers[i].index(' ') : awayPlayers[i].index(',') ])
	temp.append(awayShifts[cum * 3 : (cum + int(shiftCount[i])) * 3])
	cum += int(shiftCount[i])
	x.append(temp)

ret = []
for i in range(0, len(awayPlayers)):
	temp = ['F'] * 4800 #TODO change 3600 to actual seconds in game (use GEND from pbp page, or see if its game info page, etc)
	for j in range(0, len(x[i][1]) - 1, 3):
		shiftStart = (((int(x[i][1][j]) - 1) * 1200) + int(x[i][1][j + 1][ : x[i][1][j + 1].index(':')]) * 60) + int(x[i][1][j + 1][x[i][1][j + 1].index(':') + 1 : x[i][1][j + 1].index(' ')])
#									#period														#shift start min												turn min to sec						seconds portion of shift start
		shiftLength = (int(x[i][1][j + 2][ : x[i][1][j + 2].index(':')]) * 60) + int(x[i][1][j + 2][x[i][1][j + 2].index(':') + 1 : ])
#											#minutes of shift length													#seconds portion of shift length
		for k in range(shiftStart, shiftStart + shiftLength):
			temp[k - 1] = 'T'
	ret.append(awayPlayers[i])
	ret.append(temp)

nisky through 1240 secs T is working
2nd period, 40 seconds elapsed

f = open("/mnt/hgfs/VM/" + season + "_" + gameId + "_pbp", 'w')
cnt = 0
f.write('season,gameId,id,per,strength,elapsed,remaining,event,primaryTeam,primaryPlayer,secondaryTeam,secondaryPlayer,zone,shotType,distance,miss,stop,penType,penTime,firstAssist,secondAssist\r\n')

while cnt < len(plays):
	fieldCnt = 0
	f.write(season + ', ' + gameId + ', ')
	while fieldCnt < len(plays[cnt]):
		f.write(plays[cnt][fieldCnt].encode('utf-8'))
		if fieldCnt != len(plays[cnt])- 1:
			f.write(', ')
		else:
			f.write('\r\n')
		fieldCnt += 1
	cnt += 1

f.close()
