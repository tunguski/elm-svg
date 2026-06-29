module Example exposing (Example, View)

{-| One showcase entry: a title, a one-line note, the **complete** Elm source that reproduces it
(data + config + the producing call), and the live rendered view. [`Gallery`](Gallery) shows these
as clickable cards and, when one is selected, a detail page with the larger view and its code.

@docs Example, View

-}

import Html exposing (Html)


{-| A rendered example view (`Svg msg` unifies with this). -}
type alias View msg =
    Html msg


{-| A showcase entry. -}
type alias Example msg =
    { title : String
    , note : String
    , code : String
    , view : View msg
    }
