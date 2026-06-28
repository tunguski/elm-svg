module Main exposing (main)

{-| The elm-svg site.

Two views, switched by a top nav and reflected in the URL hash so a page is safe to reload and
links are shareable:

  - **Examples** (`#`) — the original showcase gallery of live charts drawn by the library
    (see [`Examples`](Examples)).
  - **Workspace** (`#workspace`, and `#doc/<uuid>` per chart) — create and manage your own charts,
    saved in the browser, via the reusable [`Workspace`](Workspace) component over the
    [`ChartDoc`](ChartDoc) document.

-}

import Browser
import Browser.Navigation as Nav
import ChartDoc exposing (ChartDoc, ChartMsg)
import Examples
import Html exposing (Html, a, button, div, footer, h1, header, nav, p, span, text)
import Html.Attributes as HA
import Html.Events as HE
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


type Route
    = ExamplesRoute
    | Wsp


type alias Model =
    { route : Route
    , ws : Workspace.Model ChartDoc
    , size : Float
    }


type Msg
    = WsMsg (Workspace.Msg ChartMsg)
    | SetRoute Route
    | SetSize Float
    | GotHash String


init : () -> ( Model, Cmd Msg )
init _ =
    let
        ( ws, wsCmd ) =
            Workspace.init backend
    in
    ( { route = ExamplesRoute, ws = ws, size = 380 }
    , Cmd.batch [ Cmd.map WsMsg wsCmd, Nav.getHash GotHash ]
    )



-- UPDATE ---------------------------------------------------------------------


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotHash raw ->
            applyHash raw model

        _ ->
            let
                ( next, cmd ) =
                    updateInner msg model
            in
            ( next, Cmd.batch [ cmd, syncHash model next ] )


updateInner : Msg -> Model -> ( Model, Cmd Msg )
updateInner msg model =
    case msg of
        WsMsg m ->
            let
                ( ws, cmd ) =
                    Workspace.update ChartDoc.config backend ctx m model.ws
            in
            ( { model | ws = ws }, Cmd.map WsMsg cmd )

        SetRoute route ->
            ( { model | route = route }, Cmd.none )

        SetSize s ->
            ( { model | size = s }, Cmd.none )

        GotHash _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map WsMsg (Workspace.subscriptions model.ws)



-- ROUTING --------------------------------------------------------------------


toHash : Model -> String
toHash model =
    case model.route of
        ExamplesRoute ->
            ""

        Wsp ->
            case model.ws.open of
                Just stored ->
                    stored.meta.id

                Nothing ->
                    "workspace"


syncHash : Model -> Model -> Cmd Msg
syncHash old next =
    if toHash old == toHash next then
        Cmd.none

    else
        Nav.setHash (toHash next)


applyHash : String -> Model -> ( Model, Cmd Msg )
applyHash raw model =
    let
        h =
            normalizeHash raw
    in
    if h == "" then
        ( { model | route = ExamplesRoute }, Cmd.none )

    else if h == "workspace" then
        ( { model | route = Wsp }, Cmd.none )

    else
        -- any other hash is a document id (a uuid)
        ( { model | route = Wsp }
        , Cmd.map WsMsg (Workspace.openDocument backend h)
        )


normalizeHash : String -> String
normalizeHash raw =
    raw |> dropPrefixChar '#' |> dropPrefixChar '/'


dropPrefixChar : Char -> String -> String
dropPrefixChar c s =
    if String.startsWith (String.fromChar c) s then
        String.dropLeft 1 s

    else
        s



-- VIEW -----------------------------------------------------------------------


view : Model -> Html Msg
view model =
    div [ HA.class "es-app" ]
        [ topNav model.route
        , case model.route of
            ExamplesRoute ->
                div []
                    [ hero
                    , Examples.view model.size SetSize
                    ]

            Wsp ->
                Html.map WsMsg (Workspace.view ChartDoc.config backend ctx model.ws)
        , pageFooter
        ]


topNav : Route -> Html Msg
topNav route =
    nav [ HA.class "es-topnav" ]
        [ span [ HA.class "es-brand" ] [ text "elm-svg" ]
        , div [ HA.class "es-topnav-tabs" ]
            [ tab "Examples" (route == ExamplesRoute) (SetRoute ExamplesRoute)
            , tab "Workspace" (route == Wsp) (SetRoute Wsp)
            ]
        ]


tab : String -> Bool -> Msg -> Html Msg
tab label active msg =
    button
        [ HA.class
            ("es-tab"
                ++ (if active then
                        " es-tab-active"

                    else
                        ""
                   )
            )
        , HE.onClick msg
        ]
        [ text label ]


hero : Html Msg
hero =
    header [ HA.class "es-hero" ]
        [ h1 [] [ text "elm-svg" ]
        , p [ HA.class "es-lead" ]
            [ text "A small, dependency-free SVG charting library in Elm — bar, line, scatter and "
            , text "multi-series charts over plain data, with the scale maths in a separately-tested "
            , text "module. Open the "
            , button [ HA.class "es-inline-link", HE.onClick (SetRoute Wsp) ] [ text "Workspace" ]
            , text " to create and save your own charts."
            ]
        ]


pageFooter : Html Msg
pageFooter =
    footer [ HA.class "es-foot" ]
        [ text "elm-svg — part of the "
        , a [ HA.href "https://github.com/tunguski/elm-lang" ] [ text "elm-lang" ]
        , text " ecosystem · "
        , a [ HA.href "tests.html" ] [ text "test report" ]
        , text " · "
        , a [ HA.href "https://tunguski.github.io/" ] [ text "more projects" ]
        ]
