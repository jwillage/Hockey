from lxml import html
import requests
import sys
import re

#implement default args
season = sys.argv[1]
gameId = sys.argv[2]

awayPage = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/TV0' + gameId + '.HTM')
# awayPage = requests.get('http://www.nhl.com/scores/htmlreports/20142015/TV030227.HTM')
homePage = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/TH0' + gameId + '.HTM')
# homePage = requests.get('http://www.nhl.com/scores/htmlreports/20142015/TH030227.HTM')
awayTree = html.fromstring(awayPage.text)
awayPlayers = awayTree.xpath('//table/tr[position()=4]/td/table/tr/td[@class="playerHeading + border"]/text()')
homeTree = html.fromstring(homePage.text)
homePlayers = homeTree.xpath('//table/tr[position()=4]/td/table/tr/td[@class="playerHeading + border"]/text()')


#get period, shift start, shift duration
awayShifts = awayTree.xpath('//table[position() = 1]/tr[position()=4]/td/table/tr[contains(@class, "Color")]/td[position() = 2 or position() = 3 or position() = 5]/text()')
homeShifts = homeTree.xpath('//table[position() = 1]/tr[position()=4]/td/table/tr[contains(@class, "Color")]/td[position() = 2 or position() = 3 or position() = 5]/text()')

#get the total number of shifts for each player
awayShiftCount = awayTree.xpath('//td[@colspan="8"]/table/tr[position() = last()]/td[position() = 2]/text()')
homeShiftCount = homeTree.xpath('//td[@colspan="8"]/table/tr[position() = last()]/td[position() = 2]/text()')

awayTokens = []
homeTokens = []

cum = 0
for i in range(0, len(awayPlayers)):
	temp = awayShifts[cum * 3 : (cum + int(awayShiftCount[i])) * 3]
	cum += int(awayShiftCount[i])
	awayTokens.append(temp)

cum = 0
for i in range(0, len(homePlayers)):
	temp = homeShifts[cum * 3 : (cum + int(homeShiftCount[i])) * 3]
	cum += int(homeShiftCount[i])
	homeTokens.append(temp)

awayRet = []

#shift start time is exclusive ie players are on the ice at 0. if a player is also on-ice at 2, that is the third second (0, 1, 2)
#but you can also be on the ice for the end of period (20:00)
for i in range(0, len(awayPlayers)):
	temp = ['F'] * 4805 #TODO change 3600 to actual seconds in game (use GEND from pbp page, or see if its game info page, etc)
	#4 periods = 4800 + 1 for player name + 4 for each period start at 0:00
	#append player name 
	temp[0] = awayPlayers[i][awayPlayers[i].index(',') + 2 : ] + awayPlayers[i][awayPlayers[i].index(' ') : awayPlayers[i].index(',') ]
	for j in range(0, len(awayTokens[i][0]) - 1, 3):
		shiftStart = (((int(awayTokens[i][0][j]) - 1) * 1200) + int(awayTokens[i][0][j + 1][ : awayTokens[i][0][j + 1].index(':')]) * 60) + int(awayTokens[i][0][j + 1][awayTokens[i][0][j + 1].index(':') + 1 : awayTokens[i][0][j + 1].index(' ')])
#									#period														#shift start min												turn min to sec						seconds portion of shift start
		shiftLength = (int(awayTokens[i][0][j + 2][ : awayTokens[i][0][j + 2].index(':')]) * 60) + int(awayTokens[i][0][j + 2][awayTokens[i][0][j + 2].index(':') + 1 : ])
#											#minutes of shift length													#seconds portion of shift length
		for k in range(shiftStart, shiftStart + shiftLength):
			#if the name is not appended at the start, change to temp[k-1]
			temp[k + 1] = 'T'
	awayRet.append(temp)

homeRet = []

#shift start time is exclusive ie players are on the ice at 0. if a player is also on-ice at 2, that is the third second (0, 1, 2)
#but you can also be on the ice for the end of period (20:00)
for i in range(0, len(homePlayers)):
	temp = ['F'] * 4805 #TODO change 3600 to actual seconds in game (use GEND from pbp page, or see if its game info page, etc)
	#4 periods = 4800 + 1 for player name + 4 for each period start at 0:00
	#append player name 
	temp[0] = homePlayers[i][homePlayers[i].index(',') + 2 : ] + homePlayers[i][homePlayers[i].index(' ') : homePlayers[i].index(',') ]
	for j in range(0, len(homeTokens[i][0]) - 1, 3):
		shiftStart = (((int(homeTokens[i][0][j]) - 1) * 1200) + int(homeTokens[i][0][j + 1][ : homeTokens[i][0][j + 1].index(':')]) * 60) + int(homeTokens[i][0][j + 1][homeTokens[i][0][j + 1].index(':') + 1 : homeTokens[i][0][j + 1].index(' ')])
#									#period														#shift start min												turn min to sec						seconds portion of shift start
		shiftLength = (int(homeTokens[i][0][j + 2][ : homeTokens[i][0][j + 2].index(':')]) * 60) + int(homeTokens[i][0][j + 2][homeTokens[i][0][j + 2].index(':') + 1 : ])
#											#minutes of shift length													#seconds portion of shift length
		for k in range(shiftStart, shiftStart + shiftLength):
			#if the name is not appended at the start, change to temp[k-1]
			temp[k + 1] = 'T'
	homeRet.append(temp)


f = open("/mnt/hgfs/VM/" + season + "_" + gameId + "_shifts", 'w')

cnt = 0
while cnt < len(awayRet):
	fieldCnt = 0
	f.write(season + ', ' + gameId + ', away, ' )
	while fieldCnt < len(awayRet[cnt]):
		f.write(awayRet[cnt][fieldCnt])
		if fieldCnt != len(awayRet[cnt])- 1:
			f.write(', ')
		else:
			f.write('\r\n')
		fieldCnt += 1
	cnt += 1

cnt = 0
while cnt < len(homeRet):
	fieldCnt = 0
	f.write(season + ', ' + gameId + ', home, ')
	while fieldCnt < len(homeRet[cnt]):
		f.write(homeRet[cnt][fieldCnt])
		if fieldCnt != len(homeRet[cnt])- 1:
			f.write(', ')
		else:
			f.write('\r\n')
		fieldCnt += 1
	cnt += 1

f.close()
