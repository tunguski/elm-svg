module Drawings exposing (grid)

{-| The second showcase palette: **general-purpose drawings** built with [`Draw`](Draw),
[`Path`](Path) and [`Animate`](Animate) — shapes, curves, transforms, SMIL animation, and both
flavours of interactivity (state-free SMIL `begin="…"` triggers, and a model-driven click counter).

@docs grid

-}

import Animate
import Draw exposing (Shape)
import Html exposing (Html, code, div, h3, p, pre, section, text)
import Html.Attributes as HA
import Path


{-| The grid of drawing cards. `beats` is the click count of the interactive card; `onBeat` is the
message it sends when clicked. -}
grid : Int -> msg -> Html msg
grid beats onBeat =
    section [ HA.class "es-grid" ]
        [ card "Shapes" "Draw.rect · circle · ellipse · line · polygon" "The primitives, each piped through fill/stroke modifiers." shapes
        , card "Paths & curves" "Draw.path (Path.… |> Path.toString)" "Bézier curves via the pure Path builder — here, a heart." heart
        , card "Transforms & groups" "Draw.group [ … ] |> Draw.rotate …" "A burst of one bar, rotated around a centre." burst
        , card "Composition" "circle + circle + path" "Primitives composed into a face." smiley
        , card "Spinner (animated)" "shape |> Draw.withChild (Animate.spin …)" "SMIL rotation — no Elm state, no requestAnimationFrame." spinner
        , card "Pulse & fade (animated)" "Animate.loopValues \"r\" \"14;26;14\" …" "Looping attribute animations." pulse
        , card "Hover & click (SMIL)" "Animate.onEvent \"mouseover\" \"fill\" …" "Interactivity with zero Elm state — hover the square, click the circle." interactiveSmil
        , card "Interactive (stateful)" "Draw.polygon … |> Draw.onClick Bump" "Model-driven: click the shape to add a side and recolour." (counter beats onBeat)
        ]



-- DRAWINGS -------------------------------------------------------------------


shapes : Html msg
shapes =
    Draw.svg 220 140
        [ Draw.rect 12 24 52 52 |> Draw.fill "#5b6ef5" |> Draw.rounded 8
        , Draw.circle 110 50 26 |> Draw.fill "#06d6a0"
        , Draw.ellipse 178 50 26 17 |> Draw.fill "#ef476f"
        , Draw.line 12 104 208 104 |> Draw.stroke "#073b4c" |> Draw.strokeWidth 3
        , Draw.polygon [ ( 30, 130 ), ( 70, 130 ), ( 50, 96 ) ] |> Draw.fill "#ffd166"
        , Draw.polyline [ ( 90, 128 ), ( 120, 100 ), ( 150, 124 ), ( 180, 96 ) ] |> Draw.stroke "#7c3aed" |> Draw.strokeWidth 3
        ]


heart : Html msg
heart =
    let
        d =
            Path.empty
                |> Path.moveTo 110 122
                |> Path.curveTo 36 80 54 28 110 58
                |> Path.curveTo 166 28 184 80 110 122
                |> Path.close
                |> Path.toString
    in
    Draw.svg 220 140 [ Draw.path d |> Draw.fill "#ef476f" |> Draw.stroke "#b5179e" |> Draw.strokeWidth 2 ]


burst : Html msg
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


smiley : Html msg
smiley =
    let
        smile =
            Path.empty |> Path.moveTo 82 86 |> Path.quadTo 110 114 138 86 |> Path.toString
    in
    Draw.svg 220 140
        [ Draw.circle 110 70 54 |> Draw.fill "#ffd166" |> Draw.stroke "#073b4c" |> Draw.strokeWidth 3
        , Draw.circle 90 58 7 |> Draw.fill "#073b4c"
        , Draw.circle 130 58 7 |> Draw.fill "#073b4c"
        , Draw.path smile |> Draw.stroke "#073b4c" |> Draw.strokeWidth 4
        ]


spinner : Html msg
spinner =
    let
        arc =
            Path.empty |> Path.moveTo 110 34 |> Path.arcTo 36 36 0 True True 74 70 |> Path.toString
    in
    Draw.svg 220 140
        [ Draw.circle 110 70 36 |> Draw.noFill |> Draw.stroke "#e7ecf4" |> Draw.strokeWidth 8
        , Draw.path arc
            |> Draw.noFill
            |> Draw.stroke "#5b6ef5"
            |> Draw.strokeWidth 8
            |> Draw.withChild (Animate.spin 110 70 "1s")
        ]


pulse : Html msg
pulse =
    Draw.svg 220 140
        [ Draw.circle 70 70 18 |> Draw.fill "#06d6a0" |> Draw.withChild (Animate.loopValues "r" "14;26;14" "1.4s")
        , Draw.circle 150 70 22 |> Draw.fill "#5b6ef5" |> Draw.withChild (Animate.loop "opacity" "1" "0.2" "1.2s")
        ]


interactiveSmil : Html msg
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


counter : Int -> msg -> Html msg
counter beats onBeat =
    Draw.svg 220 140
        [ Draw.polygon (ngon 110 74 44 (3 + modBy 6 beats))
            |> Draw.fill (petal beats)
            |> Draw.onClick onBeat
        , Draw.text 12 22 ("clicks: " ++ String.fromInt beats) |> Draw.fill "#073b4c"
        ]



-- HELPERS --------------------------------------------------------------------


{-| The vertices of a regular n-gon centred at `(cx, cy)`, radius `r`, first point at the top. -}
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


card : String -> String -> String -> Html msg -> Html msg
card title snippet note drawing =
    div [ HA.class "es-card" ]
        [ h3 [] [ text title ]
        , div [ HA.class "es-chart-box" ] [ drawing ]
        , pre [ HA.class "es-code" ] [ code [] [ text snippet ] ]
        , p [ HA.class "es-note" ] [ text note ]
        ]
