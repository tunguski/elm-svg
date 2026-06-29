module Animate exposing
    ( loop, loopValues, spin, onEvent, transition
    )

{-| Declarative **SMIL animation** for SVG: animation nodes you attach to a [`Draw`](Draw) shape
with [`Draw.withChild`](Draw#withChild). The browser runs them — no Elm state, subscriptions or
`requestAnimationFrame` needed, and they keep working in a static document.

    Draw.circle 40 40 12
        |> Draw.fill "#06d6a0"
        |> Draw.withChild (Animate.loop "r" "12" "18" "1s")        -- pulsing radius
        |> Draw.withChild (Animate.onEvent "mouseover" "fill" "#06d6a0" "#ef476f" "0.3s")

`begin="mouseover"` / `begin="click"` make an animation **interactive** with no model wiring at all;
for model-driven interactivity use the [`Draw`](Draw) event handlers instead.

Backend note: SMIL attributes (`attributeName`, `from`, `dur`, …) aren't bound as `Svg.Attributes`,
so they go through the generic, bound `Html.Attributes.attribute` escape hatch.

@docs loop, loopValues, spin, onEvent, transition

-}

import Html.Attributes as HA
import Svg exposing (Svg)


a : String -> String -> Svg.Attribute msg
a name v =
    HA.attribute name v


{-| Repeat an attribute animation forever, `from` → `to` over `dur` (e.g. `loop "opacity" "1" "0.3"
"1.5s"`). -}
loop : String -> String -> String -> String -> Svg msg
loop attrName from to dur =
    Svg.animate
        [ a "attributeName" attrName, a "from" from, a "to" to, a "dur" dur, a "repeatCount" "indefinite" ]
        []


{-| Repeat through an explicit `values` list forever (e.g. `loopValues "r" "12;18;12" "1.2s"` to
pulse out and back). -}
loopValues : String -> String -> String -> Svg msg
loopValues attrName values dur =
    Svg.animate
        [ a "attributeName" attrName, a "values" values, a "dur" dur, a "repeatCount" "indefinite" ]
        []


{-| Spin the shape forever about the pivot `(cx, cy)` over `dur` — the classic loading spinner. -}
spin : Float -> Float -> String -> Svg msg
spin cx cy dur =
    Svg.animateTransform
        [ a "attributeName" "transform"
        , a "type" "rotate"
        , a "from" ("0 " ++ nf cx ++ " " ++ nf cy)
        , a "to" ("360 " ++ nf cx ++ " " ++ nf cy)
        , a "dur" dur
        , a "repeatCount" "indefinite"
        ]
        []


{-| Animate an attribute once when an SVG event fires (`"click"`, `"mouseover"`, …) and hold the end
value — interactivity with no Elm state. -}
onEvent : String -> String -> String -> String -> String -> Svg msg
onEvent event attrName from to dur =
    Svg.animate
        [ a "attributeName" attrName, a "from" from, a "to" to, a "dur" dur, a "begin" event, a "fill" "freeze" ]
        []


{-| Animate an attribute once on load, `from` → `to`, and hold — a one-shot entrance transition. -}
transition : String -> String -> String -> String -> Svg msg
transition attrName from to dur =
    Svg.animate
        [ a "attributeName" attrName, a "from" from, a "to" to, a "dur" dur, a "fill" "freeze" ]
        []


nf : Float -> String
nf f =
    if toFloat (round f) == f && abs f < 1.0e12 then
        String.fromInt (round f)

    else
        String.fromFloat (toFloat (round (f * 1000)) / 1000)
