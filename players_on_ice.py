from lxml import html
import requests
import sys

#implement default args
season = sys.argv[1]
gameId = sys.argv[2]

page = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/PL0' + gameId + '.HTM')
#page = requests.get('http://www.nhl.com/scores/htmlreports/20142015/PL030227.HTM')
tree = html.fromstring(page.text)
teams = tree.xpath('//td[@class="heading + bborder"][@align="center"][@width="10%"]')
awayName, homeName = teams[0].text[0 : 3], teams[1].text[0 : 3]

page = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/PL0' + gameId + '.HTM')
#page = requests.get('http://www.nhl.com/scores/htmlreports/20142015/PL030222.HTM')
tree = html.fromstring(page.text)

pageText = page.text
tokens = pageText.split('<font style="cursor:hand;"') #each player + extraneous garbage
del tokens[0]
play = []
homeBool = 0
homeList = []
awayList = []

#homeNum = tree.xpath('//table/tr/td[last()]/table/tr/td/table/tr[position() = 1 ]/td/font/text()') 
#awayNum = tree.xpath('//table/tr/td[last() - 1]/table/tr/td/table/tr[position() = 1 ]/td/font/text()') 
#homePos =tree.xpath('//table/tr[position() > 3]/td[last()]/table/tr/td/table/tr[position() = 2]/td/text()')
#awayPos = tree.xpath('//table/tr[position() > 3]/td[last() - 1]/table/tr/td/table/tr[position() = 2]/td/text()')
#id = tree.xpath('//tr[@class="evenColor"]/td[position() = 1]/text()')
#below does not work because table/tr position resets for each period
#single = tree.xpath('//table/tr[position() = 10]/td[last()]/table/tr/td/table/tr[position() = 1 ]/td/font/text()') 

for token in tokens: #combine double blank section with single blank
	if 'td class' not in token: #not team's last player 
		if homeBool == 0:
			awayList.append(token[token.index('>')+1 : token.index('<')].encode('utf-8'))
		elif homeBool == 1:
			homeList.append(token[token.index('>')+1 : token.index('<')].encode('utf-8'))	
	if '<td class=" + bborder + rborder">&nbsp;</td>\r\n<td class=" + bborder">&nbsp;</td>' in token: #double blank
#	if '<td class=" + bborder + rborder">&nbsp;</td>\r\n' in token or '<td class=" + bborder">&nbsp;</td>' in token: #blank on home or away
		homeList.append(token[token.index('>')+1 : token.index('<')].encode('utf-8'))
		play[-1].append(homeList) 
		play.append([])
		play[-1].append([])
		play[-1].append([])
		if '<tr class="evenColor">' in token:
			homeBool = 0
			homeList = []
#last away player
	elif '</td>\r\n</tr>\r\n</table>\r\n</td>\r\n</tr>\r\n</table>\r\n</td>\r\n<td class="' in token:		
		awayList.append(token[token.index('>')+1 : token.index('<')].encode('utf-8'))
		homeBool = 1
		if len(play) > 0 and len(play[-1]) == 1: #a blank section prior
			play[-1].append([])
		play.append([])
		play[-1].append(awayList)
		awayList = []
		if '<tr class="evenColor">' in token:
			homeBool = 0
			play[-1].append(homeList)
			homeList = []
	elif '<tr class="evenColor">' in token: #last home player
		homeList.append(token[token.index('>')+1 : token.index('<')].encode('utf-8'))
		homeBool = 0
		play[-1].append(homeList)
		homeList = []


cnt, awayCnt, homeCnt = 0, 0, 0 
f = open("/mnt/hgfs/VM/" + season + "_" + gameId + "_players", 'w')
f_home = open("/mnt/hgfs/VM/" + season + "_" + gameId + "_players_home", 'w')
f_away = open("/mnt/hgfs/VM/" + season + "_" + gameId + "_players_away", 'w')

#f_home =open("/root/Documents/hometest", 'w')
#f_away =open("/root/Documents/awaytest", 'w')	
	
while cnt < len(play):
	awayCnt, homeCnt = 0, 0
	while awayCnt < len(play[cnt][0]):
		f_away.write(season + ', ' + gameId + ', ')
		f_away.write(str(cnt + 1) + ',')
		f_away.write(awayName + ',' + play[cnt][0][awayCnt].encode('utf-8') + '\r\n')# + ' away cnt: ' + str(awayCnt) + ' len: ' + str(len(play[cnt][0]-1))
		awayCnt += 1
	while homeCnt < len(play[cnt][1]):
		f_home.write(season + ', ' + gameId + ', ')
		f_home.write(str(cnt + 1) + ',')
		f_home.write(homeName + ',' + play[cnt][1][homeCnt].encode('utf-8') + '\r\n')
		homeCnt += 1	
	cnt += 1

f.close()



