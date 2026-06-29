module Gallery exposing (Model, Msg, init, update, view)

{-| The landing page: two tabs — **Charts** ([`Examples`](Examples)) and **Drawings**
([`Drawings`](Drawings)) — replacing the old size slider. The tiny bit of state is which tab is open
and the click count of the interactive drawing.

@docs Model, Msg, init, update, view

-}

import Drawings
import Examples
import Html exposing (Html, button, div, section, text)
import Html.Attributes as HA
import Html.Events as HE


type Tab
    = ChartsTab
    | DrawingsTab


{-| Which palette is showing, and the interactive drawing's click count. -}
type alias Model =
    { tab : Tab, beats : Int }


{-| Switch palette, or register a click on the interactive drawing. -}
type Msg
    = Show Tab
    | Bump


{-| Start on the charts palette. -}
init : Model
init =
    { tab = ChartsTab, beats = 0 }


{-| -}
update : Msg -> Model -> Model
update msg model =
    case msg of
        Show t ->
            { model | tab = t }

        Bump ->
            { model | beats = model.beats + 1 }


{-| The tab bar plus the selected palette. -}
view : Model -> Html Msg
view model =
    section [ HA.class "es-examples" ]
        [ div [ HA.class "es-tabs" ]
            [ tab model ChartsTab "Charts"
            , tab model DrawingsTab "Drawings"
            ]
        , case model.tab of
            ChartsTab ->
                Examples.grid 380

            DrawingsTab ->
                Drawings.grid model.beats Bump
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
