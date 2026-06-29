module Main exposing (main)

{-| The elm-svg site — a [`Workspace.Site`](Workspace-Site).

The landing (`#`) is a two-tab showcase — **Charts** and **Drawings** (see [`Gallery`](Gallery)).
The workspace (`#workspace`, `#<uuid>`) lets visitors create and manage their own charts, saved in
the browser, over the [`ChartDoc`](ChartDoc) document.

The routing, navbar, hero and footer chrome all live in [`Workspace.Site`](Workspace-Site); this
module only declares what is specific to elm-svg. The landing's own state/messages are
[`Gallery`](Gallery)'s.

-}

import ChartDoc exposing (ChartDoc, ChartMsg)
import Gallery
import Html exposing (text)
import Workspace.Site


main : Program () (Workspace.Site.Model ChartDoc Gallery.Model) (Workspace.Site.Msg ChartMsg Gallery.Msg)
main =
    Workspace.Site.program
        { title = "elm-svg"
        , namespace = "elm-svg"
        , logo = "logo.svg"
        , eyebrow = "elm · svg toolkit"
        , lead =
            [ text "A small, dependency-free SVG library in Elm — dozens of chart types over plain "
            , text "data, plus a general-purpose drawing toolkit (shapes, paths, transforms, SMIL "
            , text "animation and interactivity). Open the "
            , Workspace.Site.workspaceLink [ text "Workspace" ]
            , text " to create and save your own charts."
            ]
        , repoUrl = "https://github.com/tunguski/elm-svg"
        , workspace = ChartDoc.config
        , context = { user = "me", groups = [] }
        , landing =
            { init = Gallery.init
            , update = \msg model -> ( Gallery.update msg model, Cmd.none )
            , subscriptions = \_ -> Sub.none
            , view = Gallery.view
            , copyToWorkspace = \_ _ -> Nothing
            }
        }
