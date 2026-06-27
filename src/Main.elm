module Main exposing (main)

{-| The elm-svg showcase — a single page of live charts drawn by the library.

A `Browser.element` app renders a gallery of `Chart.*` calls over sample data (bar, line,
scatter, multi-series), each with the one line of code that produced it and a short note. A
control at the top scales every chart at once, to show the charts are resolution-independent
(they are drawn with a `viewBox`).

-}

import Browser
import Chart
import Html exposing (Html, a, button, code, div, footer, h1, h2, header, p, pre, section, span, text)
import Html.Attributes as HA
import Html.Events as HE


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( { size = 380 }, Cmd.none )
        , update = \msg model -> ( update msg model, Cmd.none )
        , view = view
        , subscriptions = always Sub.none
        }


type alias Model =
    { size : Float }


type Msg
    = SetSize Float


update : Msg -> Model -> Model
update (SetSize s) model =
    { model | size = s }



-- DATA -----------------------------------------------------------------------


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



-- VIEW -----------------------------------------------------------------------


view : Model -> Html Msg
view model =
    let
        cfg =
            Chart.sized model.size (model.size * 0.55)
    in
    div [ HA.class "es-app" ]
        [ header [ HA.class "es-hero" ]
            [ h1 [] [ text "elm-svg" ]
            , p [ HA.class "es-lead" ]
                [ text "A small, dependency-free SVG charting library in Elm — "
                , code [] [ text "Chart.bars" ]
                , text ", "
                , code [] [ text "Chart.line" ]
                , text ", "
                , code [] [ text "Chart.scatter" ]
                , text " and "
                , code [] [ text "Chart.multiLine" ]
                , text ", with the scale maths in a separately-tested "
                , code [] [ text "Scale" ]
                , text " module."
                ]
            , div [ HA.class "es-sizer" ]
                [ span [] [ text "Scale all charts:" ]
                , sizeButton model 300 "S"
                , sizeButton model 380 "M"
                , sizeButton model 460 "L"
                ]
            ]
        , section [ HA.class "es-grid" ]
            [ card "Bar chart" "Chart.bars cfg sales" "Categorical values; a zero baseline is always shown." (Chart.bars cfg sales)
            , card "Line chart" "Chart.line cfg temps" "A value per category, with markers. Negative values dip below the baseline." (Chart.line cfg temps)
            , card "Scatter plot" "Chart.scatter cfg cloud" "Raw (x, y) points, each axis scaled to its own data." (Chart.scatter cfg cloud)
            , card "Multi-series" "Chart.multiLine cfg waves" "Several named series, each in a palette colour." (Chart.multiLine cfg waves)
            ]
        , footer [ HA.class "es-foot" ]
            [ text "elm-svg — part of the "
            , a [ HA.href "https://github.com/tunguski/elm-lang" ] [ text "elm-lang" ]
            , text " ecosystem · "
            , a [ HA.href "tests.html" ] [ text "test report" ]
            , text " · "
            , a [ HA.href "https://tunguski.github.io/" ] [ text "more projects" ]
            ]
        ]


sizeButton : Model -> Float -> String -> Html Msg
sizeButton model s label =
    button
        [ HA.class
            ("es-size"
                ++ (if model.size == s then
                        " es-size-on"

                    else
                        ""
                   )
            )
        , HE.onClick (SetSize s)
        ]
        [ text label ]


card : String -> String -> String -> Html Msg -> Html Msg
card title snippet note chart =
    div [ HA.class "es-card" ]
        [ h2 [] [ text title ]
        , div [ HA.class "es-chart-box" ] [ chart ]
        , pre [ HA.class "es-code" ] [ code [] [ text snippet ] ]
        , p [ HA.class "es-note" ] [ text note ]
        ]
