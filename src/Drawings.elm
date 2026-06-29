module Drawings exposing (examples)

{-| The second showcase palette: **general-purpose drawings** built with [`Draw`](Draw),
[`Path`](Path) and [`Animate`](Animate) — shapes, curves, transforms, SMIL animation, and both
flavours of interactivity. Each is an [`Example`](Example) carrying its live view and full source.

@docs examples

-}

import Animate
import Draw
import Example exposing (Example)
import Path


{-| The drawing examples. `beats` is the click count of the interactive card; `onBeat` is the
message it sends when clicked. -}
examples : Int -> msg -> List (Example msg)
examples beats onBeat =
    [ { title = "Shapes", note = "The primitives, each piped through fill/stroke modifiers.", code = shapesSrc, view = shapes }
    , { title = "Paths & curves", note = "Bézier curves via the pure Path builder — here, a heart.", code = heartSrc, view = heart }
    , { title = "Transforms & groups", note = "A burst of one bar, rotated around a centre.", code = burstSrc, view = burst }
    , { title = "Composition", note = "Primitives composed into a face.", code = smileySrc, view = smiley }
    , { title = "Spinner (animated)", note = "SMIL rotation — no Elm state, no requestAnimationFrame.", code = spinnerSrc, view = spinner }
    , { title = "Pulse & fade (animated)", note = "Looping attribute animations.", code = pulseSrc, view = pulse }
    , { title = "Hover & click (SMIL)", note = "Interactivity with zero Elm state — hover the square, click the circle.", code = smilSrc, view = interactiveSmil }
    , { title = "Interactive (stateful)", note = "Model-driven: click the shape to add a side and recolour.", code = counterSrc, view = counter beats onBeat }
    ]



-- DRAWINGS -------------------------------------------------------------------


shapes : Example.View msg
shapes =
    Draw.svg 220 140
        [ Draw.rect 12 24 52 52 |> Draw.fill "#5b6ef5" |> Draw.rounded 8
        , Draw.circle 110 50 26 |> Draw.fill "#06d6a0"
        , Draw.ellipse 178 50 26 17 |> Draw.fill "#ef476f"
        , Draw.line 12 104 208 104 |> Draw.stroke "#073b4c" |> Draw.strokeWidth 3
        , Draw.polygon [ ( 30, 130 ), ( 70, 130 ), ( 50, 96 ) ] |> Draw.fill "#ffd166"
        , Draw.polyline [ ( 90, 128 ), ( 120, 100 ), ( 150, 124 ), ( 180, 96 ) ] |> Draw.stroke "#7c3aed" |> Draw.strokeWidth 3
        ]


shapesSrc : String
shapesSrc =
    """import Draw

view =
    Draw.svg 220 140
        [ Draw.rect 12 24 52 52 |> Draw.fill "#5b6ef5" |> Draw.rounded 8
        , Draw.circle 110 50 26 |> Draw.fill "#06d6a0"
        , Draw.ellipse 178 50 26 17 |> Draw.fill "#ef476f"
        , Draw.line 12 104 208 104 |> Draw.stroke "#073b4c" |> Draw.strokeWidth 3
        , Draw.polygon [ ( 30, 130 ), ( 70, 130 ), ( 50, 96 ) ] |> Draw.fill "#ffd166"
        , Draw.polyline [ ( 90, 128 ), ( 120, 100 ), ( 150, 124 ), ( 180, 96 ) ] |> Draw.stroke "#7c3aed" |> Draw.strokeWidth 3
        ]"""


heart : Example.View msg
heart =
    Draw.svg 220 140 [ Draw.path heartD |> Draw.fill "#ef476f" |> Draw.stroke "#b5179e" |> Draw.strokeWidth 2 ]


heartD : String
heartD =
    Path.empty
        |> Path.moveTo 110 122
        |> Path.curveTo 36 80 54 28 110 58
        |> Path.curveTo 166 28 184 80 110 122
        |> Path.close
        |> Path.toString


heartSrc : String
heartSrc =
    """import Draw
import Path

heartD =
    Path.empty
        |> Path.moveTo 110 122
        |> Path.curveTo 36 80 54 28 110 58
        |> Path.curveTo 166 28 184 80 110 122
        |> Path.close
        |> Path.toString

view =
    Draw.svg 220 140
        [ Draw.path heartD |> Draw.fill "#ef476f" |> Draw.stroke "#b5179e" |> Draw.strokeWidth 2 ]"""


burst : Example.View msg
burst =
    Draw.svg 220 140
        [ Draw.group
            (List.map
                (\i ->
                    Draw.rect 105 18 10 44
                        |> Draw.fill (petal i)
                        |> Draw.rounded 4
                        |> Draw.rotate (toFloat i * 30) 110 70
                )
                (List.range 0 11)
            )
        ]


burstSrc : String
burstSrc =
    """import Draw

view =
    Draw.svg 220 140
        [ Draw.group
            (List.map
                (\\i ->
                    Draw.rect 105 18 10 44
                        |> Draw.fill (petal i)
                        |> Draw.rounded 4
                        |> Draw.rotate (toFloat i * 30) 110 70
                )
                (List.range 0 11)
            )
        ]"""


smiley : Example.View msg
smiley =
    Draw.svg 220 140
        [ Draw.circle 110 70 54 |> Draw.fill "#ffd166" |> Draw.stroke "#073b4c" |> Draw.strokeWidth 3
        , Draw.circle 90 58 7 |> Draw.fill "#073b4c"
        , Draw.circle 130 58 7 |> Draw.fill "#073b4c"
        , Draw.path smileD |> Draw.stroke "#073b4c" |> Draw.strokeWidth 4
        ]


smileD : String
smileD =
    Path.empty |> Path.moveTo 82 86 |> Path.quadTo 110 114 138 86 |> Path.toString


smileySrc : String
smileySrc =
    """import Draw
import Path

view =
    Draw.svg 220 140
        [ Draw.circle 110 70 54 |> Draw.fill "#ffd166" |> Draw.stroke "#073b4c" |> Draw.strokeWidth 3
        , Draw.circle 90 58 7 |> Draw.fill "#073b4c"
        , Draw.circle 130 58 7 |> Draw.fill "#073b4c"
        , Draw.path (Path.empty |> Path.moveTo 82 86 |> Path.quadTo 110 114 138 86 |> Path.toString)
            |> Draw.stroke "#073b4c" |> Draw.strokeWidth 4
        ]"""


spinner : Example.View msg
spinner =
    Draw.svg 220 140
        [ Draw.circle 110 70 36 |> Draw.noFill |> Draw.stroke "#e7ecf4" |> Draw.strokeWidth 8
        , Draw.path spinnerArc
            |> Draw.noFill
            |> Draw.stroke "#5b6ef5"
            |> Draw.strokeWidth 8
            |> Draw.withChild (Animate.spin 110 70 "1s")
        ]


spinnerArc : String
spinnerArc =
    Path.empty |> Path.moveTo 110 34 |> Path.arcTo 36 36 0 True True 74 70 |> Path.toString


spinnerSrc : String
spinnerSrc =
    """import Animate
import Draw
import Path

view =
    Draw.svg 220 140
        [ Draw.circle 110 70 36 |> Draw.noFill |> Draw.stroke "#e7ecf4" |> Draw.strokeWidth 8
        , Draw.path (Path.empty |> Path.moveTo 110 34 |> Path.arcTo 36 36 0 True True 74 70 |> Path.toString)
            |> Draw.noFill |> Draw.stroke "#5b6ef5" |> Draw.strokeWidth 8
            |> Draw.withChild (Animate.spin 110 70 "1s")
        ]"""


pulse : Example.View msg
pulse =
    Draw.svg 220 140
        [ Draw.circle 70 70 18 |> Draw.fill "#06d6a0" |> Draw.withChild (Animate.loopValues "r" "14;26;14" "1.4s")
        , Draw.circle 150 70 22 |> Draw.fill "#5b6ef5" |> Draw.withChild (Animate.loop "opacity" "1" "0.2" "1.2s")
        ]


pulseSrc : String
pulseSrc =
    """import Animate
import Draw

view =
    Draw.svg 220 140
        [ Draw.circle 70 70 18 |> Draw.fill "#06d6a0"
            |> Draw.withChild (Animate.loopValues "r" "14;26;14" "1.4s")
        , Draw.circle 150 70 22 |> Draw.fill "#5b6ef5"
            |> Draw.withChild (Animate.loop "opacity" "1" "0.2" "1.2s")
        ]"""


interactiveSmil : Example.View msg
interactiveSmil =
    Draw.svg 220 140
        [ Draw.rect 24 44 70 60
            |> Draw.fill "#5b6ef5"
            |> Draw.rounded 8
            |> Draw.withChild (Animate.onEvent "mouseover" "fill" "#5b6ef5" "#ef476f" "0.3s")
            |> Draw.withChild (Animate.onEvent "mouseout" "fill" "#ef476f" "#5b6ef5" "0.3s")
        , Draw.text 30 122 "hover me" |> Draw.fill "#61708a"
        , Draw.circle 160 74 26
            |> Draw.fill "#ffd166"
            |> Draw.withChild (Animate.onEvent "click" "r" "26" "40" "0.4s")
        , Draw.text 138 122 "click me" |> Draw.fill "#61708a"
        ]


smilSrc : String
smilSrc =
    """import Animate
import Draw

-- begin="mouseover"/"click" makes a SMIL animation interactive with no Elm state.
view =
    Draw.svg 220 140
        [ Draw.rect 24 44 70 60 |> Draw.fill "#5b6ef5" |> Draw.rounded 8
            |> Draw.withChild (Animate.onEvent "mouseover" "fill" "#5b6ef5" "#ef476f" "0.3s")
            |> Draw.withChild (Animate.onEvent "mouseout" "fill" "#ef476f" "#5b6ef5" "0.3s")
        , Draw.circle 160 74 26 |> Draw.fill "#ffd166"
            |> Draw.withChild (Animate.onEvent "click" "r" "26" "40" "0.4s")
        ]"""


counter : Int -> msg -> Example.View msg
counter beats onBeat =
    Draw.svg 220 140
        [ Draw.polygon (ngon 110 74 44 (3 + modBy 6 beats))
            |> Draw.fill (petal beats)
            |> Draw.onClick onBeat
        , Draw.text 12 22 ("clicks: " ++ String.fromInt beats) |> Draw.fill "#073b4c"
        ]


counterSrc : String
counterSrc =
    """import Draw

-- in your update: Bump -> { model | clicks = model.clicks + 1 }
view clicks =
    Draw.svg 220 140
        [ Draw.polygon (ngon 110 74 44 (3 + modBy 6 clicks))
            |> Draw.fill (petal clicks)
            |> Draw.onClick Bump
        , Draw.text 12 22 ("clicks: " ++ String.fromInt clicks) |> Draw.fill "#073b4c"
        ]

ngon cx cy r sides =
    List.map
        (\\i ->
            let
                a = toFloat i / toFloat sides * 2 * pi - pi / 2
            in
            ( cx + r * cos a, cy + r * sin a )
        )
        (List.range 0 (sides - 1))"""



-- HELPERS --------------------------------------------------------------------


ngon : Float -> Float -> Float -> Int -> List ( Float, Float )
ngon cx cy r sides =
    List.map
        (\i ->
            let
                a =
                    toFloat i / toFloat (Basics.max 3 sides) * 2 * pi - pi / 2
            in
            ( cx + r * cos a, cy + r * sin a )
        )
        (List.range 0 (Basics.max 3 sides - 1))


petal : Int -> String
petal i =
    let
        cs =
            [ "#5b6ef5", "#06d6a0", "#ef476f", "#ffd166", "#7c3aed", "#0891b2" ]
    in
    case List.drop (modBy 6 i) cs of
        c :: _ ->
            c

        [] ->
            "#5b6ef5"
