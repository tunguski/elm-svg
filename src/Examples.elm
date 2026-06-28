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
    [ ( "a", List.map (\i -> ( toFloat i, sin (toFloat i / 3) * 4 + 5 )) (List.range 0 24) )
    , ( "b", List.map (\i -> ( toFloat i, cos (toFloat i / 3) * 3 + 5 )) (List.range 0 24) )
    ]


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
            [ card "Bar chart" "Chart.bars cfg sales" "Categorical values; a zero baseline is always shown." (Chart.bars cfg sales)
            , card "Line chart" "Chart.line cfg temps" "A value per category, with markers. Negative values dip below the baseline." (Chart.line cfg temps)
            , card "Scatter plot" "Chart.scatter cfg cloud" "Raw (x, y) points, each axis scaled to its own data." (Chart.scatter cfg cloud)
            , card "Multi-series" "Chart.multiLine cfg waves" "Several named series, each in a palette colour." (Chart.multiLine cfg waves)
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
