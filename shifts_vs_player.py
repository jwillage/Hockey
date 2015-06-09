from lxml import html
import requests
import sys
import re

#implement default args
season = sys.argv[1]
gameId = sys.argv[2]

awayPage = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/TV0' + gameId + '.HTM')
#awayPage = requests.get('http://www.nhl.com/scores/htmlreports/20142015/TV030227.HTM')
awayTree = html.fromstring(awayPage.text)
awayPlayerTokens = awayTree.xpath('//table/tr[position()=4]/td/table/tr/td[@class="playerHeading + border"]/text()')



plays = []
temp=[]


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