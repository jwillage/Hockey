from lxml import html
import requests
import sys
import json
import urllib2

#implement default args
season = sys.argv[1]
gameId = sys.argv[2]

# url = version with args
url = "http://live.nhl.com/GameData/20142015/2014030221/PlayByPlay.json"
allPlays = json.load(urllib2.urlopen(url))
textPlays = str(allPlays)
filteredPlays = substr(allPlays, index(allPlays, '{"aoi"')