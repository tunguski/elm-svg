module Main exposing (main)

{-| The elm-svg site — a [`Workspace.Site`](Workspace-Site).

The landing (`#`) is the original showcase gallery of live charts (see [`Examples`](Examples)), with
a size slider. The workspace (`#workspace`, `#<uuid>`) lets visitors create and manage their own
charts, saved in the browser, over the [`ChartDoc`](ChartDoc) document.

The routing, navbar, hero and footer chrome all live in [`Workspace.Site`](Workspace-Site); this
module only declares what is specific to elm-svg. The landing's own state is the chart size (a
`Float`), and its messages are the new size.

-}

import ChartDoc exposing (ChartDoc, ChartMsg)
import Examples
import Html exposing (text)
import Workspace.Site


main : Program () (Workspace.Site.Model ChartDoc Float) (Workspace.Site.Msg ChartMsg Float)
main =
    Workspace.Site.program
        { title = "elm-svg"
        , namespace = "elm-svg"
        , logo = "logo.svg"
        , eyebrow = "elm · svg charts"
        , lead =
            [ text "A small, dependency-free SVG charting library in Elm — bar, line, scatter and "
            , text "multi-series charts over plain data, with the scale maths in a separately-tested "
            , text "module. Open the "
            , Workspace.Site.workspaceLink [ text "Workspace" ]
            , text " to create and save your own charts."
            ]
        , repoUrl = "https://github.com/tunguski/elm-svg"
        , workspace = ChartDoc.config
        , context = { user = "me", groups = [] }
        , landing =
            { init = 380
            , update = \newSize _ -> ( newSize, Cmd.none )
            , subscriptions = \_ -> Sub.none
            , view = \size -> Examples.view size identity
            , copyToWorkspace = \_ _ -> Nothing
            }
        }
