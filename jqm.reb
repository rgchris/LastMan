Rebol [
    Title: "jQuery Mobile Page Builder"
    Author: "Christopher Ross-Gill"
    Date: 30-Dec-2017
    ; Home: 'tbd
    File: %jqm.reb
    Version: 0.1.0
    Purpose: "Build JQuery Mobile pages for web apps."
    Type: module
    Name: rgchris.jqm
    Needs: [<rsp>]
    Exports: [build-jqm]
    History: [
    ]
]

no-content: ""

section-builder: func [proto [block!] body [block!] return: [function!]][
    func [
        params [block! blank!]
        content [string! block!]
        /local yield
    ] compose/only [
        params: make (make object! proto) any [:params []]
        yield: delimit compose [(content)] newline
        unspaced bind (body) params ; newline
    ]
]

app: section-builder [
    title: "My App"
    style: _
][
    <!DOCTYPE html> 
    | <html>
        | <head>
            | <meta charset="utf-8">
            | <title> :title </title>
            | <link rel="stylesheet" href="//code.jquery.com/mobile/1.4.5/jquery.mobile-1.4.5.min.css" />
            | <script src="//code.jquery.com/jquery-1.11.1.min.js"></script>
            | <script src="//code.jquery.com/mobile/1.4.5/jquery.mobile-1.4.5.min.js"></script>
            if style [
                for-each value compose [(style)][
                    switch type-of style [
                        :file! :url! [
                            unspaced [| build-tag compose [link href (style) rel "stylesheet" type "text/css"]]
                        ]
                        :string! [
                            unspaced [
                                | <style type="text/css">
                                | sanitize trim/auto style
                                | </style>
                            ]
                        ]
                        (no-content)
                    ]
                ]
            ]
        | </head> 
        | <body>
        | yield
        | </body>
    | </html>
]

h4: section-builder [
    id: style: _
][
    | build-tag [h4 style (if style [trim/lines copy :style]) id :id] yield </h4>
]

page: section-builder [
    title: "Page Title"
    footer: []
    id: class: style: back: _
][
    | build-tag [div data-role "page" id :id style (if style [trim/lines copy :style])]
        | <div data-role="header">
            | <h1> :title </h1>
            unspaced collect [
                if back [
                    keep '|
                    keep build-tag [a data-rel "back" href (mold form back)]
                    keep ["Back" </a>]
                ]
            ]
        | </div>
        | <div role="main" class="ui-content">
            yield
        | </div>
        | <div data-role="footer" data-position="fixed">
            footer
        | </div>
    | </div>
]

build-jqm: func [params [block!] content [block!]][
    app bind params 'app bind content 'app
]
