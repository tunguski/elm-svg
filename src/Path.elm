module Path exposing
    ( Path, empty, toString
    , moveTo, lineTo, horizontalTo, verticalTo, curveTo, quadTo, arcTo, close
    , polyline, polygon
    )

{-| A builder for the SVG `<path>` `d` attribute — the most general drawing primitive (straight
runs, Bézier curves, elliptical arcs). No SVG here, just the string maths, so it is unit-tested and
usable by any renderer (see [`Draw.path`](Draw)).

    Path.empty
        |> Path.moveTo 10 10
        |> Path.lineTo 90 10
        |> Path.curveTo 90 90 10 90 10 50
        |> Path.close
        |> Path.toString
        --> "M 10 10 L 90 10 C 90 90 10 90 10 50 Z"

@docs Path, empty, toString
@docs moveTo, lineTo, horizontalTo, verticalTo, curveTo, quadTo, arcTo, close
@docs polyline, polygon

-}


{-| A path, accumulated as a sequence of drawing commands. -}
type Path
    = Path (List String)


{-| The empty path. -}
empty : Path
empty =
    Path []


push : String -> Path -> Path
push cmd (Path cmds) =
    Path (cmds ++ [ cmd ])


{-| Move the pen to `(x, y)` without drawing (starts a new sub-path). -}
moveTo : Float -> Float -> Path -> Path
moveTo x y =
    push ("M " ++ n x ++ " " ++ n y)


{-| Draw a straight line to `(x, y)`. -}
lineTo : Float -> Float -> Path -> Path
lineTo x y =
    push ("L " ++ n x ++ " " ++ n y)


{-| Draw a horizontal line to `x`. -}
horizontalTo : Float -> Path -> Path
horizontalTo x =
    push ("H " ++ n x)


{-| Draw a vertical line to `y`. -}
verticalTo : Float -> Path -> Path
verticalTo y =
    push ("V " ++ n y)


{-| Cubic Bézier curve with control points `(x1, y1)` and `(x2, y2)` to `(x, y)`. -}
curveTo : Float -> Float -> Float -> Float -> Float -> Float -> Path -> Path
curveTo x1 y1 x2 y2 x y =
    push ("C " ++ n x1 ++ " " ++ n y1 ++ " " ++ n x2 ++ " " ++ n y2 ++ " " ++ n x ++ " " ++ n y)


{-| Quadratic Bézier curve with control point `(cx, cy)` to `(x, y)`. -}
quadTo : Float -> Float -> Float -> Float -> Path -> Path
quadTo cx cy x y =
    push ("Q " ++ n cx ++ " " ++ n cy ++ " " ++ n x ++ " " ++ n y)


{-| Elliptical arc to `(x, y)`: radii `rx`/`ry`, x-axis `rotation`, and the `largeArc`/`sweep`
flags (each drawn as `1` when `True`). -}
arcTo : Float -> Float -> Float -> Bool -> Bool -> Float -> Float -> Path -> Path
arcTo rx ry rotation largeArc sweep x y =
    push
        ("A "
            ++ n rx
            ++ " "
            ++ n ry
            ++ " "
            ++ n rotation
            ++ " "
            ++ flag largeArc
            ++ " "
            ++ flag sweep
            ++ " "
            ++ n x
            ++ " "
            ++ n y
        )


{-| Close the current sub-path with a straight line back to its start. -}
close : Path -> Path
close =
    push "Z"


{-| Render the path's `d` string. -}
toString : Path -> String
toString (Path cmds) =
    String.join " " cmds


{-| An open path through the points (a `moveTo` then `lineTo`s). -}
polyline : List ( Float, Float ) -> Path
polyline pts =
    case pts of
        ( x, y ) :: rest ->
            List.foldl (\( px, py ) p -> lineTo px py p) (moveTo x y empty) rest

        [] ->
            empty


{-| A closed path through the points. -}
polygon : List ( Float, Float ) -> Path
polygon pts =
    close (polyline pts)


flag : Bool -> String
flag b =
    if b then
        "1"

    else
        "0"


n : Float -> String
n f =
    if toFloat (round f) == f && abs f < 1.0e12 then
        String.fromInt (round f)

    else
        String.fromFloat (toFloat (round (f * 1000)) / 1000)
