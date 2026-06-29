module Layout exposing (Rect, treemap)

{-| The pure rectangle maths behind a **treemap**: tiling a box so each value gets an area in
proportion to its share of the total. No SVG here — it returns plain rectangles, so it is
unit-tested and a renderer just draws them.

The algorithm is recursive binary slicing: split the values into two groups of roughly equal sum,
split the box along its longer side in that proportion, and recurse. Rectangles come back in the
same order as the values given (sort the values first if you want the largest tiles placed first).

@docs Rect, treemap

-}


{-| A rectangle as `( x, y, width, height )`. -}
type alias Rect =
    ( Float, Float, Float, Float )


{-| Tile `box` so each value in `values` gets a sub-rectangle proportional to its share, returned in
input order. Non-positive values are treated as zero; an empty list yields no rectangles.
-}
treemap : Rect -> List Float -> List Rect
treemap box values =
    layout box (List.map (Basics.max 0) values)


layout : Rect -> List Float -> List Rect
layout (( x, y, w, h ) as box) values =
    case values of
        [] ->
            []

        [ _ ] ->
            [ box ]

        _ ->
            let
                total =
                    List.sum values

                ( left, right ) =
                    split values

                frac =
                    if total <= 0 then
                        toFloat (List.length left) / toFloat (List.length values)

                    else
                        List.sum left / total
            in
            if w >= h then
                layout ( x, y, w * frac, h ) left ++ layout ( x + w * frac, y, w * (1 - frac), h ) right

            else
                layout ( x, y, w, h * frac ) left ++ layout ( x, y + h * frac, w, h * (1 - frac) ) right


{-| Split a list into a non-empty prefix whose sum first reaches half the total, and the rest. -}
split : List Float -> ( List Float, List Float )
split values =
    splitGo (List.sum values / 2) 0 [] values


splitGo : Float -> Float -> List Float -> List Float -> ( List Float, List Float )
splitGo half acc taken rest =
    case rest of
        [] ->
            ( List.reverse taken, [] )

        [ last ] ->
            -- always leave the final value for the right side, so neither side is ever empty
            ( List.reverse taken, [ last ] )

        v :: more ->
            if taken /= [] && acc >= half then
                ( List.reverse taken, rest )

            else
                splitGo half (acc + v) (v :: taken) more
