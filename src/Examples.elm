module Examples exposing (view)

{-| The elm-svg **showcase** — a gallery of live charts drawn by the library (bar, line, scatter,
multi-series), each with the one line of code that produced it. A size control scales every chart
at once, to show the charts are resolution-independent (drawn with a `viewBox`).

This is the site's "Examples" landing; the host wires the size state and a "Workspace" link around
it. It is parameterised by the current `size` and the message that sets it, so it stays a pure view.

@docs view

-}

import Chart
import Html exposing (Html, code, div, h3, p, pre, section, span, text)
import Html.Attributes as HA
import Html.Events as HE


sales : List ( String, Float )
sales =
    [ ( "Jan", 120 ), ( "Feb", 98 ), ( "Mar", 145 ), ( "Apr", 132 ), ( "May", 168 ), ( "Jun", 180 ) ]


temps : List ( String, Float )
temps =
    [ ( "Mon", -3 ), ( "Tue", 1 ), ( "Wed", 4 ), ( "Thu", 2 ), ( "Fri", 7 ), ( "Sat", 9 ), ( "Sun", 5 ) ]


cloud : List ( Float, Float )
cloud =
    [ ( 1, 2 ), ( 2, 3.2 ), ( 3, 2.8 ), ( 4, 5 ), ( 5, 4.4 ), ( 6, 6.1 ), ( 7, 5.5 ), ( 8, 7.8 ), ( 9, 7.2 ), ( 10, 9 ) ]


waves : List ( String, List ( Float, Float ) )
waves =
    [ ( "sin", List.map (\i -> ( toFloat i, sin (toFloat i / 3) * 4 + 5 )) (List.range 0 24) )
    , ( "cos", List.map (\i -> ( toFloat i, cos (toFloat i / 3) * 3 + 5 )) (List.range 0 24) )
    ]


bands : List ( String, List ( Float, Float ) )
bands =
    [ ( "organic", List.map (\i -> ( toFloat i, 3 + sin (toFloat i / 4) * 1.5 )) (List.range 0 12) )
    , ( "paid", List.map (\i -> ( toFloat i, 2 + cos (toFloat i / 5) )) (List.range 0 12) )
    , ( "referral", List.map (\i -> ( toFloat i, 1.2 + sin (toFloat i / 3) * 0.6 )) (List.range 0 12) )
    ]


revenue : List ( String, List ( String, Float ) )
revenue =
    [ ( "Q1", [ ( "Web", 30 ), ( "Mobile", 20 ), ( "Store", 12 ) ] )
    , ( "Q2", [ ( "Web", 36 ), ( "Mobile", 28 ), ( "Store", 14 ) ] )
    , ( "Q3", [ ( "Web", 33 ), ( "Mobile", 35 ), ( "Store", 11 ) ] )
    , ( "Q4", [ ( "Web", 42 ), ( "Mobile", 39 ), ( "Store", 16 ) ] )
    ]


share : List ( String, Float )
share =
    [ ( "Chrome", 64 ), ( "Safari", 19 ), ( "Edge", 9 ), ( "Firefox", 5 ), ( "Other", 3 ) ]


languages : List ( String, Float )
languages =
    [ ( "Rust", 87 ), ( "Elm", 74 ), ( "Go", 69 ), ( "Haskell", 58 ), ( "C", 46 ) ]


planets : List ( Float, Float, Float )
planets =
    -- distance from sun (AU), mean temperature (°C), mass (Earths)
    [ ( 0.39, 167, 0.055 ), ( 0.72, 464, 0.82 ), ( 1.0, 15, 1.0 ), ( 1.52, -65, 0.11 ), ( 5.2, -110, 318 ), ( 9.5, -140, 95 ) ]


scores : List Float
scores =
    [ 52, 61, 58, 67, 70, 72, 75, 74, 78, 80, 81, 83, 85, 84, 86, 88, 90, 91, 77, 69, 73, 79, 82, 87, 65, 71, 76, 84, 89, 92, 68, 74, 80, 85, 63, 77, 81, 88 ]


radarAxes : List String
radarAxes =
    [ "Speed", "Power", "Range", "Defense", "Agility", "Support" ]


squads : List ( String, List Float )
squads =
    [ ( "Red", [ 8, 6, 4, 7, 9, 5 ] ), ( "Blue", [ 5, 9, 7, 6, 4, 8 ] ) ]


{-| The gallery, at the given size, with size buttons that send `onSize`. -}
view : Float -> (Float -> msg) -> Html msg
view size onSize =
    let
        cfg =
            Chart.sized size (size * 0.55)
    in
    section [ HA.class "es-examples" ]
        [ div [ HA.class "es-sizer" ]
            [ span [] [ text "Scale all charts:" ]
            , sizeButton onSize size 300 "S"
            , sizeButton onSize size 380 "M"
            , sizeButton onSize size 460 "L"
            ]
        , section [ HA.class "es-grid" ]
            [ card "Bar chart" "Chart.bars (Chart.withValues True cfg) sales" "Categorical values over gridlines, labelled per bar; a zero baseline is always shown." (Chart.bars (Chart.withValues True cfg) sales)
            , card "Line chart" "Chart.line cfg temps" "A value per category, with markers. Negative values dip below the baseline." (Chart.line cfg temps)
            , card "Area chart" "Chart.area (Chart.withColor \"#0f9d58\" cfg) sales" "A line with the region down to the baseline filled." (Chart.area (Chart.withColor "#0f9d58" cfg) sales)
            , card "Scatter plot" "Chart.scatter cfg cloud" "Raw (x, y) points, each axis scaled to its own data." (Chart.scatter cfg cloud)
            , card "Multi-series" "Chart.multiLine cfg waves" "Several named series, each in a palette colour, with a legend." (Chart.multiLine cfg waves)
            , card "Stacked area" "Chart.stackedArea cfg bands" "Named series stacked into translucent filled bands." (Chart.stackedArea cfg bands)
            , card "Stacked bars" "Chart.stackedBars cfg revenue" "Each category split into stacked, colour-keyed segments." (Chart.stackedBars cfg revenue)
            , card "Grouped bars" "Chart.groupedBars cfg revenue" "The same data as side-by-side bars per category." (Chart.groupedBars cfg revenue)
            , card "Pie chart" "Chart.pie cfg share" "Slices sized by value, summing to the whole." (Chart.pie cfg share)
            , card "Donut chart" "Chart.donut (Chart.withInner 0.6 cfg) share" "A pie with a hole — set by Chart.withInner." (Chart.donut (Chart.withInner 0.6 cfg) share)
            , card "Horizontal bars" "Chart.hbars cfg languages" "Categories down the left, values across — good for long labels and rankings." (Chart.hbars cfg languages)
            , card "Bubble chart" "Chart.bubble cfg planets" "A third dimension as bubble area, coloured along a sequential ramp. Hover for values." (Chart.bubble cfg planets)
            , card "Histogram" "Chart.histogram cfg scores" "A raw list of numbers binned into a distribution." (Chart.histogram cfg scores)
            , card "Radar chart" "Chart.radar cfg axes squads" "Several series compared across shared axes." (Chart.radar cfg radarAxes squads)
            , card "Smooth line" "Chart.line (Chart.withCurve True cfg) temps" "The same line, smoothed with a Catmull-Rom curve." (Chart.line (Chart.withCurve True cfg) temps)
            , card "Titled & dark" "Chart.bars (Chart.withTitle \"Sales\" …) sales" "Chart and axis titles, on the dark theme — Chart.darken keeps the slider size." (Chart.bars (Chart.withTitle "Sales" (Chart.withAxisTitles "month" "" (Chart.darken cfg))) sales)
            ]
        ]


sizeButton : (Float -> msg) -> Float -> Float -> String -> Html msg
sizeButton onSize current s label =
    Html.button
        [ HA.class
            ("es-size"
                ++ (if current == s then
                        " es-size-on"

                    else
                        ""
                   )
            )
        , HE.onClick (onSize s)
        ]
        [ text label ]


card : String -> String -> String -> Html msg -> Html msg
card title snippet note chart =
    div [ HA.class "es-card" ]
        [ h3 [] [ text title ]
        , div [ HA.class "es-chart-box" ] [ chart ]
        , pre [ HA.class "es-code" ] [ code [] [ text snippet ] ]
        , p [ HA.class "es-note" ] [ text note ]
        ]
