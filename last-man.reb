#!/usr/local/bin/ren-c

Rebol [
    Title: "Last Man Standing"
    Date: 13-Oct-2017
    Author: "Christopher Ross-Gill"
    Needs: [
        <rsp> <httpd> <webform>
        %jqm.reb
    ]
]

if find any [system/script/args []] "--version" [print system/script/header/date quit]

source: all [
    not tail? system/script/args
    source: local-to-file take system/script/args
]

else [
    do make error! "Last Man data file not supplied or does not exist."
]

LMS.jpg: read %LMS.jpg

cardinals: [
    "One" "Two" "Three" "Four" "Five" "Six" "Seven" "Eight" "Nine" "Ten"
    "Eleven" "Twelve" "Thirteen" "Fourteen" "Fifteen" "Sixteen" "Seventeen" "Eighteen"
]

teams: -team-: players: -player-: _

match!: make object! [
    time: home: away: score: _
]

player!: make object! [
    nick: name: email: paid: picks: points: fell: has-won: _
]

week!: make object! [
    date: number: name: starters: matches: match-by-team: picks: player-picks: points: undecided: eliminated: is-next?: is-playing?: has-played?: _
]

load-lms: func [
    target [file!]
    /local week-no competition header players -player- current mark err
][
    competition: any [attempt [load/header target] reduce [_]]

    ; Basic Conformance Check
    case [
        not object? header: take competition [
            make error! "No Header"
        ]

        not all [
            in header 'teams
            find [file! url!] to word! type of header/teams
        ][
            make error! "No Teams file specified"
        ]

        not parse teams: load header/teams [
            some [string! [file! | url! | binary!]]
        ][
            make error! "Could not parse team file"
        ]

        empty? remove -team-: collect [
            foreach team words-of teams: make map! lock teams [
                keep '| keep team
            ]
        ][
            make error! "No Teams"
        ]

        not all [
            in header 'players
            block? players: header/players
        ][
            make error! "No Players specified"
        ]

        empty? remove -player-: collect [
            foreach [nick name email paid] players [
                keep '| keep to lit-word! nick
            ]
        ][
            make error! "No Players"
        ]

        not parse competition [
            (current: _)
            some [
                ['Week 'of set current date! | mark: (err: "Expected Week Start") fail]
                some [
                    [time! | mark: (err: "Expected Time") fail]
                    [-team- | mark: (err: "Expected Home Team") fail]
                    [-team- | mark: (err: "Expected Away Team") fail]
                    [pair! | insert (_)]
                ]
                any [-team- any -player-]
                opt [$10 any -player-]
            ]
        ][
            make error! spaced [current unspaced [err ","] "got:" mold mark/1]
        ]
    ]

    else [
        week-no: 0

        foreach team words-of teams [
            poke teams team make object! [
                target: teams/:team
                image: switch probe type of teams/:team [
                    :file! :url! [
                        read teams/:team
                    ]

                    :binary! [
                        teams/:team
                    ]

                    (
                        return make error! spaced [
                            "Team badge for" team "not correctly specified."
                        ]
                    )
                ]
                source: unspaced [
                    {<img width="22" height="22" src="data:image/png;base64,}
                    enbase image
                    {" style="position:relative;left:-4px;top:-1px;display:inline-block;margin:0 -2px -5px 0;">}
                ]
            ]
        ]

        players: make map! collect [
            foreach [nick name email paid] players [
                keep nick
                keep make player! compose/only [
                    nick: (to lit-word! nick)
                    name: (name)
                    email: (email)
                    paid: (paid)
                    picks: (make block! 10)
                    points: 0
                ]
            ]
        ]

        make object! compose [
            players: (:players)

            live-players: words-of players

            weeks: collect [
                use [mark this week match team player have-picked][
                    week: [
                        mark: 'Week 'of date! (
                            keep mark/3
                            bind week keep this: make week! [
                                date: mark/3
                                matches: make block! 10
                                match-by-team: make map! 10
                                picks: make map! 0
                                player-picks: make map! 0
                                points: make map! 0
                                eliminated: make block! 10
                                bought-back: make block! 10
                            ]
                        )
                        some [
                            copy match [time! -team- -team- [pair! | blank!]] (
                                append matches match: make match! [
                                    time: this/date
                                    time/time: match/1
                                    lock home: match/2
                                    lock away: match/3
                                    score: match/4
                                ]
                                match-by-team/(match/home): match-by-team/(match/away): match
                                points/(match/home): 0
                                points/(match/away): 0
                            )
                        ]
                        any [
                            set team -team- (
                                unless find points team [
                                    return make error! spaced ["Team" mold team "not playing in week:" date]
                                ]
                            )
                            copy have-picked any [
                                set player -player-
                                (poke player-picks player team)
                            ]
                            (unless empty? have-picked [poke picks lock team have-picked])
                        ]
                        opt [
                            $10 any [
                                set player -player-
                                (
                                    append bought-back player
                                    players/:player/paid: me + $10
                                )
                            ]
                        ]
                    ]

                    parse competition [some week]
                ]
            ]

            weeks: make map! sort/skip weeks 2

            this-week: _

            weeks-played: collect [
                for-each week words-of weeks [
                    week: weeks/:week
                    week/number: week-no: me + 1
                    week/name: spaced ["Week" pick cardinals week/number]
                    week/starters: copy live-players
                    week/is-playing?: week/date = now/date
                    week/has-played?: week/date < now/date

                    case [
                        any [
                            week/has-played?
                            week/is-playing?
                        ][
                            new-line/all week/matches true

                            ; assess scores for each team
                            for-each match week/matches [
                                either pair? match/score [
                                    week/points/(match/home): case [
                                        match/score/1 < match/score/2 [2]
                                        match/score/1 = match/score/2 [1]
                                        /else [0]
                                    ]
                                    week/points/(match/away): case [
                                        match/score/1 > match/score/2 [2]
                                        match/score/1 = match/score/2 [1]
                                        /else [0]
                                    ]
                                ][
                                    either week/has-played? [
                                        return make error! spaced ["Score Missing:" week/name]
                                    ][
                                        week/points/(match/home): week/points/(match/away): 0
                                    ]
                                ]
                            ]

                            unless empty? missing-picks: difference words-of week/player-picks week/starters [
                                either week/is-playing? [
                                    remove-each player missing-picks [
                                        for-each team sort words-of week/match-by-team [
                                            unless find players/:player/picks team [
                                                append any [
                                                    select week/picks team
                                                    week/picks/(team): make block! 0
                                                ] players/:player/nick
                                                week/player-picks/(player): team
                                                break
                                            ]
                                        ]
                                        block? find words-of week/player-picks player
                                    ]
                                    week/undecided: :missing-picks
                                ][
                                    return make error! spaced ["Missing picks from" mold new-line/all missing-picks no "on" week/date]
                                ]
                            ]

                            for-each player words-of players [
                                case [
                                    find week/starters player [
                                        player: players/:player
                                        either find player/picks week/player-picks/(player/nick) [
                                            return make error! spaced [
                                                "Player" mold form player "has already picked" week/player-picks/(player/nick)
                                            ]
                                        ][
                                            append player/picks new-line new-line/all reduce [
                                                week/name
                                                week/player-picks/(player/nick)
                                                week/match-by-team/(week/player-picks/(player/nick))
                                                week/points/(week/player-picks/(player/nick))
                                                block? find week/bought-back player/nick
                                            ] no yes

                                            player/points: me + week/points/(week/player-picks/(player/nick))

                                            if find week/bought-back player/nick [
                                                player/points: 0
                                            ]

                                            if player/points > 1 [
                                                player/fell: week/date
                                                append week/eliminated player
                                                remove find live-players player/nick
                                            ]
                                        ]
                                    ]

                                    date? players/:player/fell [
                                        players/:player/points: me + 2
                                        append players/:player/picks [
                                            _ _ _ _ _
                                        ]
                                        if select week/player-picks player [
                                            return make error! spaced [
                                                "Player" mold form player "was eliminated before" week/name
                                            ]
                                        ]
                                    ]

                                    /else [
                                        return make error! "Player not fallen nor starter"
                                    ]
                                ]
                            ]

                            while [empty? live-players][
                                live-players: collect [
                                    for-each player week/starters [
                                        players/:player/points: players/:player/points - 1
                                        if players/:player/points < 2 [
                                            players/:player/fell: _
                                            remove find week/eliminated player
                                            keep player
                                        ]
                                    ]
                                ]
                            ]

                            if tail? next live-players [
                                players/(live-players/1)/has-won: yes
                            ]

                            if week/is-playing? [
                                this-week: :week
                            ]

                            keep week
                        ]

                        /else [
                            week/is-next?: true

                            for-each player words-of week/player-picks [
                                unless find week/starters player [
                                    return make error! spaced [
                                        "Player" mold form player "was eliminated before" week/name
                                    ]
                                ]
                            ]

                            week/undecided: difference week/starters words-of week/player-picks

                            this-week: any [this-week week]

                            keep week

                            break
                        ]
                    ]
                ]
            ]

            ranked-players: sort/compare map-each player words-of players [players/:player] func [first second][
                either first/points = second/points [
                    first/nick < second/nick
                ][
                    first/points < second/points
                ]
            ]
        ]
    ]
]

nickname-of: func [player [word! object!]][
    if object? player [player: player/nick]
    replace/all form player "_" "&nbsp;"
]

pp-score: func [score [pair! blank!]][
    either score [
        unspaced [
            round/to score/1 1
            "-"
            round/to score/2 1
        ]
    ][
        "vs."
    ]
]

pp-date: func [date [date!] /short][
    date: make object! [
        weekday: pick system/locale/days date/weekday
        day: date/day
        ordinal: switch day [
            1 21 31 ["st"]
            2 22 ["nd"]
            3 23 ["rd"]
            ("th")
        ]
        month: pick system/locale/months date/month
        year: date/year
    ]

    unspaced either short [
        [date/month " " date/day date/ordinal]
    ][
        [date/weekday " " date/day date/ordinal " " date/month ", " date/year]
    ]
]

badge-base: %/badge?
base-style: {font-size: 13px; font-family: "Helvetica"; text-shadow: none;}
badge-style: {position:relative;left:-4px;top:-1px;display:inline-block;margin:0 -2px -5px 0;}
coin-style: {display:inline-block;width:22px;border-radius:50%;color:#333;border:1px solid rgba(238,238,238,0.4);text-align:center;position:relative;left:4px;}

footer-buttons: {
    <div data-role="navbar" data-iconpos="top">
        <ul>
            <li><a href="/reload" data-ajax="false" data-icon="refresh">Reload</a></li>
            <li><a href="/quit" data-icon="delete">Quit</a></li>
        </ul>
    </div>
}

home-of: load-rsp {
    <ul data-role="listview" data-inset="true">
        <li><a href="#addresses">Addresses</a></li>
        <li><a href="#fixtures">Fixtures</a></li>
        <li><a href="#picks">Picks</a></li>
        <li><a href="#history">History</a></li>
    </ul>
}

addresses-of: load-rsp {
    <pre><%== 
        unspaced remove collect [
            foreach player words-of players [
                keep ",^^/" keep players/:player/name keep " <" keep players/:player/email keep ">"
            ]
        ]
     %></pre>
}

fixtures-of: load-rsp {
    <%
        for-each week collect [
            if this-week [keep this-week]
            if this-week <> last weeks-played [
                keep last weeks-played
            ]
        ][ %>
    <h4 style="margin-bottom:0;text-transform:uppercase;"><%= week/name %> Fixtures</h4>
    <h2 style="margin-top:0;"><%== pp-date week/date %></h2>
    <table width="100%" cellpadding="5" style="max-width:580px;line-height:1.5;font-size:13px">
    <%
            for-each match week/matches [
     %>
        <tr>
            <td valign="top" align="right" width="26"><%! img width 22 src (join-of badge-base match/home) style (badge-style) %></td>
            <td valign="top" align="left" width="130">
                <b style="text-transform:uppercase;"><%== match/home %></b>
            </td>
            <td valign="top" align="center"><%== match/time/time %></td>
            <td valign="top" align="right" width="130">
                <b style="text-transform:uppercase;"><%== match/away %></b>
            </td>
            <td valign="top" align="left" width="26"><%! img width 22 src (join-of badge-base match/away) style (badge-style) %></td>
        </tr>
    <% 
            ] %>
    </table>
    <%
        ] %>
}

history-of: load-rsp {
    <div style="width:100%;overflow:auto;">
        <table cellpadding="10" style="line-height:22px;white-space:nowrap;font-size:13px">
        <% for-each player ranked-players [ %>
            <% either player/fell [ %><tr style="text-decoration:line-through;opacity:0.4;"><% ][ %><tr><% ] %>
                <% 
                    either player/has-won [
                     %><td valign="top" align="right" bgcolor="#cea"><% 
                    ][
                     %><td valign="top" align="right"><%
                    ]
                 %><b><%= nickname-of player %><% 
                    if all [player/points = 1 not player/has-won][
                         %><sup>*</sup><% 
                    ] %></b>&nbsp;</td><% 

                    for-each [week selection match points bought-back?] player/picks [
                        %><%! 
                            td valign "top" bgcolor (
                                case [
                                    player/has-won [#cea]
                                    blank? points [_]
                                    zero? points [_]
                                    points = 1 [#fc9]
                                    points = 2 [#f99]
                                ]
                            )
                            title (
                                if selection [
                                    unspaced [
                                        pp-date/short match/time ", " match/home " " pp-score match/score " " match/away
                                    ]
                                ]
                            )
                        %><% 
                            if selection [ %><%= teams/:selection/source %> <%= selection %><% if bought-back? [ %> <span style="<%= coin-style %>">$</span><% ] ]
                         %></td><% 
                    ]
                 %>
            </tr>
        <% ] %>
        </table>
    </div>
}

current-picks-of: load-rsp {
    <% if this-week [ %>
    <h4 style="margin-bottom:0;text-transform:uppercase;"><%= this-week/name %></h4>
    <h2 style="margin-top:0;"><%== pp-date this-week/date %></h2>
    <% unless empty? this-week/undecided [ %>
    <p>Waiting on: <b><%= 
        unspaced remove collect [
            for-each player this-week/undecided [
                keep ", " keep nickname-of player
            ]
        ]
    %></b></p>
    <% ] %>
    <table width="100%" cellpadding="5" style="min-width:320px;max-width:580px;line-height:1.5;">
    <% 
        for-each match this-week/matches [
            if any [
                find words-of this-week/picks match/home
                find words-of this-week/picks match/away
            ][
     %>
        <tr>
            <td valign="top" align="right" width="26"><%= teams/(match/home)/source %></td>
            <td valign="top" align="left" width="130">
                <b style="text-transform:uppercase;"><%== match/home %></b><small><% 
                    foreach player any [select this-week/picks match/home []][
                         %><br><%= nickname-of player %><% 
                    ]
                 %></small>
            </td>
            <td valign="top" align="center"><%== match/time/time %></td>
            <td valign="top" align="right" width="130">
                <b style="text-transform:uppercase;"><%== match/away %></b><small><% 
                    foreach player any [select this-week/picks match/away []][
                         %><br><%= nickname-of player %><% 
                    ]
                 %></small>
            </td>
            <td valign="top" align="left" width="26"><%= teams/(match/away)/source %></td>
        </tr>
    <% 
            ]
        ]
     %>
    </table>
    <% ] <!-- this week --> %>
}

undecided-of: load-rsp {
    <% if all [
        this-week not empty? this-week/undecided
    ][ %>
        <p>To: <% foreach player this-week/undecided [ %>
            <%== players/:player/name %> &lt;<%== players/:player/email %>&gt;,
        <% ] %></p>
    <% ] %>
    <form action="/send-fixtures" method="POST">
        <textarea name="message"></textarea>
        <%= fixtures-of competition %>
        <button type="submit">Send</button>
    </form>
}

form-error: load-rsp {
    <h2>Error: <%== competition/message %></h2>
    <pre style="border:1px solid #ccc;border-radius:.6em;padding:1em;overflow:auto;"><%== mold competition %></pre>
}

render-app: func [competition [object! error!]][
    switch type-of competition [
        :object! [
            build-jqm [
                title: "Last Man Standing"
            ][
                page [
                    title: "Home"
                    footer: :footer-buttons
                    style: :base-style
                ] home-of competition

                page [
                    title: "Addresses"
                    back: %/
                    id: "addresses"
                    style: :base-style
                ] addresses-of competition

                page [
                    title: "Fixtures"
                    back: %/
                    id: "fixtures"
                    style: :base-style
                ] fixtures-of competition

                page [
                    title: "History"
                    back: %/
                    id: "history"
                    style: :base-style
                ] history-of competition

                page [
                    title: "Picks"
                    back: %/
                    id: "picks"
                    style: :base-style
                ] current-picks-of competition
            ]
        ]

        :error! [
            build-jqm [
                title: "Last Man Standing: Error"
            ][
                page [
                    title: "Error"
                    footer: :footer-buttons
                    style: :base-style
                ] form-error body-of :competition
            ]
        ]
    ]
]

if error? set 'competition load-lms source [
    probe competition
    quit
]


server: open [
    scheme: 'httpd 8080 [
        switch request/action [
            "GET /" [
                render render-app competition
            ]

            "GET /reload" [
                set 'competition load-lms source
                redirect/as %/ 303
                ; help competition/this-week
                ; probe competition/this-week/picks
            ]

            "GET /send-fixtures" [
                ; not fully implemented yet
                render build-jqm [
                    title: "Undecided Players"
                ][
                    page _ undecided-of competition
                ]
            ]

            "POST /send-fixtures" [
                ; not implemented yet--needs Send + MIME
                render build-jqm [
                    title: "Undecided Players"
                ][
                    page _ [
                        "<h1>Sent Fixtures!</h1>" |
                        mold load-webform request/content
                    ]
                ]
            ]

            "GET /send-picks" [
                ; not implemented yet--needs Send + MIME
                render build-jqm [
                    title: "Send Picks"
                ][
                    page _  [
                        
                    ]
                ]
            ]

            "GET /badge" [
                either badge: select teams attempt [url-decode to string! request/query-string][
                    response/status: 200
                    response/type: "image/png"
                    response/content: badge/image
                ][
                    response/content: "Not Found"
                ]
            ]

            "GET /favicon.ico" [
                render LMS.jpg
                response/type: 'image/jpeg
            ]

            "GET /quit" [
                render build-jqm [title: "Quitting"][page _ "I'm Out!"]
                response/kill?: true
            ]

            (
                response/content: "Phooey"
            )
        ]
    ]
]

; browse http://localhost:8080

while [open? server][
    ; used to test aspects of HTTPd
    wait [server 1000]
    print ["Is Open?" pick ['yes 'no] open? server/locals/subport]
]

print "Done"
