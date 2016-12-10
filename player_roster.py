from lxml import html
import requests
import sys

#implement default args
season = sys.argv[1]
gameId = sys.argv[2]

page = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/PL0' + gameId + '.HTM')
#page = requests.get('http://www.nhl.com/scores/htmlreports/20142015/PL030226.HTM')
tree = html.fromstring(page.text)
teams = tree.xpath('//td[@class="heading + bborder"][@align="center"][@width="10%"]')
awayName, homeName = teams[0].text[0 : 3], teams[1].text[0 : 3]

page = requests.get('http://www.nhl.com/scores/htmlreports/' + season + str(int(season) + 1) + '/RO0' + gameId + '.HTM')
#page = requests.get('http://www.nhl.com/scores/htmlreports/20142015/RO030226.HTM')
tree = html.fromstring(page.text)

away = tree.xpath('//table/tr[position()=4]/td/table/tr[position()=1]/td[position()=1]/table/tr[position()>1]/td[@class]')
home = tree.xpath('//table/tr[position()=4]/td/table/tr[position()=1]/td[position()=2]/table/tr[position()>1]/td[@class]')

#f = open('roster', 'w')
f = open("/mnt/hgfs/VM/" + season + "_" + gameId + "_roster", 'w')

for x in range(0, len(away), 3):
	f.write(season + ', ' + gameId + ', ')
	f.write(awayName + ',')
	f.write(str(away[x].text) + ',')
	f.write(str(away[x + 1].text) + ',')
	try:
		if str(away[x + 2].attrib).index('italic'):
			f.write(away[x + 2].text[0 : away[x + 2].text.index('(') - 2])	#remove (C) or (A) from name
			if away[x + 2].text[away[x + 2].text.index('(') + 1] == 'C':
				f.write(',captain')
			else:
				f.write(',assistant')
		else:	#should not hit, should go to exception
			f.write(away[x + 2].text + ',')
	except ValueError:
		f.write(away[x + 2].text + ',')
	try:
		if str(away[x + 2].attrib).index('bold'):
			f.write(',starter\r\n')
		else:	#should not hit, should go to exception
			f.write(',\r\n')
	except ValueError:
		f.write(',\r\n')

for x in range(0, len(home), 3):
	f.write(season + ', ' + gameId + ', ')
	f.write(homeName + ',')
	f.write(str(home[x].text) + ',')
	f.write(str(home[x + 1].text) + ',')
	try:
		if str(home[x + 2].attrib).index('italic'):
			f.write(home[x + 2].text[0 : home[x + 2].text.index('(') - 2])	#remove (C) or (A) from name
			if home[x + 2].text[home[x + 2].text.index('(') + 1] == 'C':
				f.write(',captain')
			else:
				f.write(',assistant')
		else:	#should not hit, should go to exception
			f.write(home[x + 2].text + ',')
	except ValueError:
		f.write(home[x + 2].text + ',')
	try:
		if str(home[x + 2].attrib).index('bold'):
			f.write(',starter\r\n')
		else:	#should not hit, should go to exception
			f.write(',\r\n')
	except ValueError:
		f.write(',\r\n')


f.close()
