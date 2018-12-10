# Last Man Standing

This script can be used to manage a game of Last Man Standing. 

# Requirements

This script uses [Ren-C](https://github.com/metaeducation/Ren-C) ([pre-built](http://metaeducation.s3.amazonaws.com/index.html)).

# Example Game

Create a Rebol file with the following structure. Do as an argument to the LastMan.reb script. Changes to this file can be reloaded into the web app while running.

```rebol
#!./last-man.reb

Rebol [
    Title: "Last Man Standing: December 2018"
    Date: 1-Dec-2018
    Players: [
        Chris     "Chris Ross-Gill"  chris@rebol.info           $10
        Han       "Han Solo"         han@rebol.info             $10
        Luke      "Luke Skywalker"   luke@rebol.info            $10
    ]
    Teams: http://reb4.me/x/EPL-2018-19.reb
    Comment: "With apologies to George Lucas"
]

Week of 15-Dec-2018

7:30 "Man. City" "Everton"
10:00 "Crystal Palace" "Leicester"
10:00 "Huddersfield" "Newcastle"
10:00 "Watford" "Cardiff"
10:00 "Tottenham" "Burnley"
10:00 "Wolves" "Bournemouth"
12:30 "Fulham" "West Ham"

Week of 8-Dec-2018

7:30 "Bournemouth" "Liverpool" 0x4
10:00 "Arsenal" "Huddersfield" 1x0
10:00 "Burnley" "Brighton" 1x0
10:00 "Cardiff" "Southampton" 1x0
10:00 "Man. Utd" "Fulham" 4x1
10:00 "West Ham" "Crystal Palace" 3x2
12:30 "Chelsea" "Man. City" 2x0
14:45 "Leicester" "Tottenham" 0x2

"Burnley" Chris
"Leicester" Luke
"Man. Utd" Han
```

The `Teams` value in the header should point (`file!` | `url!`) to a Rebol file containing `text! [file! | url! | binary!]` pairs with team name and image.

```rebol
"Bournemouth" %bournemouth.png
"Liverpool" %liverpool.png
...
```
