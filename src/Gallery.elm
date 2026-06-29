module Gallery exposing (Model, Msg, init, update, view)

{-| The landing page: two tabs — **Charts** ([`Examples`](Examples)) and **Drawings**
([`Drawings`](Drawings)). Each tab is a grid of clickable cards; clicking one opens a detail page
showing the larger view and the full, self-contained Elm source ([`Example`](Example)) that
reproduces it.

@docs Model, Msg, init, update, view

-}

import Drawings
import Example exposing (Example)
import Examples
import Html exposing (Html, button, code, div, h3, p, pre, section, span, text)
import Html.Attributes as HA
import Html.Events as HE


type Tab
    = ChartsTab
    | DrawingsTab


{-| Which palette is open, the interactive drawing's click count, and the selected example (if any). -}
type alias Model =
    { tab : Tab, beats : Int, selected : Maybe Int }


{-| Switch palette, open/close an example's detail, or click the interactive drawing. -}
type Msg
    = Show Tab
    | Select Int
    | Back
    | Bump


{-| Start on the charts palette, nothing selected. -}
init : Model
init =
    { tab = ChartsTab, beats = 0, selected = Nothing }


{-| -}
update : Msg -> Model -> Model
update msg model =
    case msg of
        Show t ->
            { model | tab = t, selected = Nothing }

        Select i ->
            { model | selected = Just i }

        Back ->
            { model | selected = Nothing }

        Bump ->
            { model | beats = model.beats + 1 }


{-| The tab bar plus either the grid or a selected example's detail. -}
view : Model -> Html Msg
view model =
    let
        exs =
            case model.tab of
                ChartsTab ->
                    Examples.examples 380

                DrawingsTab ->
                    Drawings.examples model.beats Bump
    in
    section [ HA.class "es-examples" ]
        [ div [ HA.class "es-tabs" ]
            [ tab model ChartsTab "Charts"
            , tab model DrawingsTab "Drawings"
            ]
        , case model.selected |> Maybe.andThen (\i -> nth i exs) of
            Just ex ->
                detail ex

            Nothing ->
                grid exs
        ]


grid : List (Example Msg) -> Html Msg
grid exs =
    section [ HA.class "es-grid" ] (List.indexedMap gridCard exs)


gridCard : Int -> Example Msg -> Html Msg
gridCard i ex =
    div [ HA.class "es-card es-clickable", HE.onClick (Select i) ]
        [ h3 [] [ text ex.title ]
        , div [ HA.class "es-chart-box" ] [ ex.view ]
        , p [ HA.class "es-note" ] [ text ex.note ]
        , span [ HA.class "es-open" ] [ text "View code →" ]
        ]


detail : Example Msg -> Html Msg
detail ex =
    div [ HA.class "es-detail" ]
        [ button [ HA.class "es-back", HE.onClick Back ] [ text "← Back to the gallery" ]
        , h3 [ HA.class "es-detail-title" ] [ text ex.title ]
        , p [ HA.class "es-note" ] [ text ex.note ]
        , div [ HA.class "es-detail-view" ] [ ex.view ]
        , pre [ HA.class "es-code-full" ] [ code [] [ text ex.code ] ]
        ]


tab : Model -> Tab -> String -> Html Msg
tab model t label =
    button
        [ HA.class
            ("es-tab"
                ++ (if model.tab == t then
                        " es-tab-on"

                    else
                        ""
                   )
            )
        , HE.onClick (Show t)
        ]
        [ text label ]


nth : Int -> List a -> Maybe a
nth i xs =
    List.head (List.drop i xs)
