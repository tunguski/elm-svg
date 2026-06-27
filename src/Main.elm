module Main exposing (main)

{-| The elm-svg site — a **workspace of your own charts**, drawn by the library.

This module is a thin host: it wires the reusable [`Workspace`](Workspace) component to a browser
(localStorage) backend and a local user, and hands it the chart-document configuration from
[`ChartDoc`](ChartDoc). You get many-chart management, naming, search, copy, sharing/permissions,
comments and CSV / JSON export for free; the chart editor (a kind selector, a data box and a live
preview) is drawn with the library's own [`Chart`](Chart) module.

It is the same `Workspace` component that powers elm-notebook — over a completely different
document — which is the point: the workspace is reusable.

-}

import Browser
import ChartDoc exposing (ChartDoc, ChartMsg)
import Html exposing (Html, a, div, footer, h1, header, p, span, text)
import Html.Attributes as HA
import Workspace
import Workspace.Backend exposing (Backend, Context)
import Workspace.Browser


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- WIRING ---------------------------------------------------------------------


ctx : Context
ctx =
    { user = "me", groups = [] }


backend : Backend (Workspace.Msg ChartMsg)
backend =
    Workspace.Browser.backend "elm-svg"



-- MODEL ----------------------------------------------------------------------


type alias Model =
    { ws : Workspace.Model ChartDoc }


type Msg
    = WsMsg (Workspace.Msg ChartMsg)


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( ws, cmd ) =
            Workspace.init backend
    in
    ( { ws = ws }, Cmd.map WsMsg cmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update (WsMsg m) model =
    let
        ( ws, cmd ) =
            Workspace.update ChartDoc.config backend ctx m model.ws
    in
    ( { ws = ws }, Cmd.map WsMsg cmd )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map WsMsg (Workspace.subscriptions model.ws)



-- VIEW -----------------------------------------------------------------------


view : Model -> Html Msg
view model =
    div [ HA.class "es-app" ]
        [ header [ HA.class "es-hero" ]
            [ h1 [] [ text "elm-svg" ]
            , p [ HA.class "es-lead" ]
                [ text "Create and manage your own charts — bar, line and scatter — drawn by the "
                , a [ HA.href "https://github.com/tunguski/elm-svg" ] [ text "elm-svg" ]
                , text " library, in a workspace built on "
                , a [ HA.href "https://github.com/tunguski/elm-workspace" ] [ text "elm-workspace" ]
                , text ". Charts are saved in your browser; share, comment and export them."
                ]
            ]
        , Html.map WsMsg (Workspace.view ChartDoc.config backend ctx model.ws)
        , footer [ HA.class "es-foot" ]
            [ a [ HA.href "tests.html" ] [ text "Test report" ]
            , text " · "
            , a [ HA.href "https://github.com/tunguski/elm-svg" ] [ text "GitHub" ]
            , text " · "
            , a [ HA.href "https://tunguski.github.io/" ] [ text "More projects" ]
            ]
        ]
