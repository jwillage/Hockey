# Python
Python scripts to scrape NHL data and prepare for analysis

##Play By Play (pbp.py)
pbp.py scrapes the play by play (pbp) data from NHL.com's HTML report. The data is written out to a file, with each line containing details such as play-id, time, event type, primary and secondary team and player, shot type and distance, penalty type and drawing player, etc. Output is written in a standardized format that can be further consumed by a database, BI/discovery tool, or scripts.

###Arguments
python pbp.py season gameId

Argument | Description
--- | ---
**season** | The begining year of the season. For instance, a game that occurs on December 1, 2014 would have season `2014`. A game that occurs on March 1, 2015 would have season `2014`, as it is part of the 2014-2015 season.
**gameID** | The NHL-assigned id for that game in the season. This can be found on the NHL site in the last part of any link to that game (usually after the season number). From a Game Recap page, all of the Official Game Report links end in gameID. Regular season IDs are `20000` through `21230`. 

###Output
The output is a structured, comma-separated file in the format of season_gameID_pbp.csv. The first row is the column headings.

Column | Description
--- | ---
**season** | The begining year of the game's season. See the `season` argument for details.
**gameID** | The gameID for the game. See the `gameID` argument for details. This is used in conjunction with the `season` to join various files that make up a game (roster, shifts, etc).
**id** | A unique identifier tied to the sequence of events for each play of the game. This value is the same as the NHL pbp '#' column. 
**period** | Period the play occured
**elapsed** | Time elapsed in the period
**remaining** | Time remaining in the period
**event** | Type of event. Possible values are the following: <table><tbody><tr><td>PSTR</td><td>Period start</td></tr><tr><td>FAC</td><td>Faceoff </td></tr><tr><td>HIT</td><td>Hit</td></tr><tr><td>STOP</td><td>Stoppage of play</td></tr><tr><td>MISS</td><td>Missed shot</td></tr><tr><td>GIVE</td><td>Giveaway</td></tr><tr><td>TAKE</td><td>Takeaway</td></tr><tr><td>SHOT</td><td>Shot on goal</td></tr><tr><td>BLOCK</td><td>Blocked shot</td></tr><tr><td>PEND</td><td>Period end</td></tr><tr><td>GEND</td><td>Game end</td></tr><tr><td>GOAL</td><td>Goal scored</td></tr><tr><td>PENL</td><td>Penalty assessed</td></tr></tbody></table>
**primaryTeam** | The primary team involved in the event, based on event type: <table><tbody><tr><td>FAC</td><td>Winning team </td></tr><tr><td>HIT</td><td>Team whose player delivered the hit</td></tr><tr><td>MISS</td><td>Team that missed the shot</td></tr><tr><td>GIVE</td><td>Team that gave the puck away</td></tr><tr><td>TAKE</td><td>Team that took the puck away</td></tr><tr><td>SHOT</td><td>Team that had a shot on goal</td></tr><tr><td>BLOCK</td><td>Team that had their shot blocked</td></tr><tr><td>GOAL</td><td>Team that scored the goal</td></tr><tr><td>PENL</td><td>Team that had penalty assessed</td></tr></tbody></table>
**primaryPlay** | The primary player involved in the event, based on event type: <table><tbody><tr><td>FAC</td><td>Player who won the faceoff </td></tr><tr><td>HIT</td><td>Player that delivered the hit</td></tr><tr><td>MISS</td><td>Player who missed the shot</td></tr><tr><td>GIVE</td><td>Player who gave the puck away</td></tr><tr><td>TAKE</td><td>Player who took the puck away</td></tr><tr><td>SHOT</td><td>Player who had a shot on goal</td></tr><tr><td>BLOCK</td><td>Player who had their shot blocked</td></tr><tr><td>GOAL</td><td>Player who scored the goal</td></tr><tr><td>PENL</td><td>Player who had penalty assessed to them</td></tr></tbody></table>
**secondaryTeam** | The secondary team involved in the event, based on event type: <table><tbody><tr><td>FAC</td><td>Losing team </td></tr><tr><td>HIT</td><td>Team whose player received the hit</td></tr><tr><td>BLOCK</td><td>Team who blocked the opposing shot</td></tr><tr><td>PENL</td><td>Team that drew the penalty</td></tr></tbody></table>
**secondaryPlayer** | The secondary player involved in the event, based on event type: <table><tbody><tr><td>FAC</td><td>Losing player </td></tr><tr><td>HIT</td><td>Player who received the hit</td></tr><tr><td>BLOCK</td><td>Player who blocked the opposing shot</td></tr><tr><td>PENL</td><td>Player who drew the penalty</td></tr></tbody></table>
**zone** | Zone which the event occured. Zone is relative to the primary team. For instance, a faceoff with zone `Off.` indicates the winning team was in their offensive zone, and the losing team was in their defensive zone. Blocks are almost always in the `Def.` zone, as the primary team is the blocking team.
**shotType** | Type of shot that was taken. This field is populated for events `BLOCK`, `MISS`, `SHOT`, and `GOAL`
**distance** | Distance in feet of the shot. This field is populated for events `MISS`, `SHOT`, and `GOAL`
**miss** | How the shot missed. Possible values are `Goalpost`, `Over`, and `Wide`
**stop** | Reason for stoppage
**penType** | Reason for penalty
**penTime** | Time served for penalty
**firstAssist** | Player with the primary assist of the goal, if one exists
**secondAssist** | Player with the secondary assist of the goal, if one exists

###To Do
* Implement default arguments for testing purposes, or gracefully return error
* Add a column that represents the elapsed/remaining for the entire game, not just the period


