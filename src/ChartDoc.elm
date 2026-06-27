module ChartDoc exposing (ChartDoc, ChartMsg, config)

{-| A **chart** seen as a [`Workspace`](Workspace) document, so elm-svg becomes a place to create
and manage your own charts (stored in the browser) — with naming, search, copy, sharing,
permissions, comments and CSV / JSON export, all from the shared
[elm-workspace](https://github.com/tunguski/elm-workspace) library.

A chart document is just a chart **kind** plus its data as editable `label, value` text; the editor
parses that text and draws a live preview with the library's own [`Chart`](Chart) module. This is a
deliberately *different* document from elm-notebook's — proof that one workspace component fits very
different things.

@docs ChartDoc, ChartMsg, config

-}

import Chart
import Html exposing (Html, div, label, option, span, text, textarea)
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as D
import Json.Encode as E
import Workspace
import Workspace.Types exposing (Table)


{-| A chart: which kind to draw, and its data as `label, value` lines. -}
type alias ChartDoc =
    { kind : ChartKind
    , text : String
    }


type ChartKind
    = Bar
    | Line
    | Scatter


{-| Editor messages: change the chart kind, or edit the data. -}
type ChartMsg
    = SetKind String
    | SetData String



-- CONFIG ---------------------------------------------------------------------


{-| The chart document's workspace configuration. -}
config : Workspace.Config ChartDoc ChartMsg
config =
    { codec = { encode = encode, decoder = decoder }
    , empty = empty
    , kind = "chart"
    , activate = identity
    , viewDoc = viewDoc
    , updateDoc = updateDoc
    , elementsOf = \_ -> [ ( "chart", "The chart" ) ]
    , toTable = toTable
    , onImport = Just importTable
    }


empty : ChartDoc
empty =
    { kind = Bar
    , text = "Jan, 120\nFeb, 98\nMar, 145\nApr, 132\nMay, 168\nJun, 180"
    }



-- CODEC ----------------------------------------------------------------------


encode : ChartDoc -> E.Value
encode doc =
    E.object
        [ ( "kind", E.string (kindToString doc.kind) )
        , ( "text", E.string doc.text )
        ]


decoder : D.Decoder ChartDoc
decoder =
    D.map2 ChartDoc
        (D.field "kind" (D.map kindFromString D.string))
        (D.field "text" D.string)


kindToString : ChartKind -> String
kindToString kind =
    case kind of
        Bar ->
            "bar"

        Line ->
            "line"

        Scatter ->
            "scatter"


kindFromString : String -> ChartKind
kindFromString s =
    case s of
        "line" ->
            Line

        "scatter" ->
            Scatter

        _ ->
            Bar



-- DATA -----------------------------------------------------------------------


{-| Parse the `label, value` text into chart data, dropping lines that don't parse. -}
parse : String -> List ( String, Float )
parse txt =
    String.lines txt
        |> List.filterMap parseLine


parseLine : String -> Maybe ( String, Float )
parseLine line =
    case String.split "," line of
        labelPart :: valuePart :: _ ->
            case String.toFloat (String.trim valuePart) of
                Just v ->
                    Just ( String.trim labelPart, v )

                Nothing ->
                    Nothing

        _ ->
            Nothing


toTable : ChartDoc -> Maybe Table
toTable doc =
    case parse doc.text of
        [] ->
            Nothing

        data ->
            Just
                { headers = [ "label", "value" ]
                , rows = List.map (\( l, v ) -> [ l, String.fromFloat v ]) data
                }


importTable : Table -> ChartDoc -> ChartDoc
importTable table doc =
    { doc | text = String.join "\n" (List.map (String.join ", ") table.rows) }



-- UPDATE ---------------------------------------------------------------------


updateDoc : ChartMsg -> ChartDoc -> ChartDoc
updateDoc msg doc =
    case msg of
        SetKind s ->
            { doc | kind = kindFromString s }

        SetData s ->
            { doc | text = s }



-- VIEW -----------------------------------------------------------------------


viewDoc : Workspace.EditorEnv -> ChartDoc -> Html ChartMsg
viewDoc env doc =
    div [ HA.class "cd" ]
        [ if env.commentsVisible && env.commentCount "chart" > 0 then
            span [ HA.class "cd-marker" ] [ text ("💬 " ++ String.fromInt (env.commentCount "chart")) ]

          else
            text ""
        , div [ HA.class "cd-controls" ]
            [ label [ HA.class "cd-label" ] [ text "Chart type" ]
            , Html.select [ HA.class "cd-select", HE.onInput SetKind ]
                [ option [ HA.value "bar", HA.selected (doc.kind == Bar) ] [ text "Bar" ]
                , option [ HA.value "line", HA.selected (doc.kind == Line) ] [ text "Line" ]
                , option [ HA.value "scatter", HA.selected (doc.kind == Scatter) ] [ text "Scatter" ]
                ]
            ]
        , div [ HA.class "cd-preview" ] [ chartView doc ]
        , label [ HA.class "cd-label" ] [ text "Data (one “label, value” per line)" ]
        , textarea
            [ HA.class "cd-data"
            , HA.attribute "rows" "10"
            , HA.attribute "spellcheck" "false"
            , HA.value doc.text
            , HE.onInput SetData
            ]
            []
        ]


chartView : ChartDoc -> Html ChartMsg
chartView doc =
    let
        c =
            Chart.sized 560 320

        data =
            parse doc.text
    in
    case doc.kind of
        Bar ->
            Chart.bars c data

        Line ->
            Chart.line c data

        Scatter ->
            Chart.scatter c (List.indexedMap (\i ( _, v ) -> ( toFloat i, v )) data)
