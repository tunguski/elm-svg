module Curve exposing (smooth, catmullRom)

{-| Turning a polyline into a smooth curve, by sampling a **Catmull-Rom spline** through the points.
No SVG here — it takes a list of `(x, y)` points and returns a longer list of points that bends
smoothly through every original one, which a renderer then strokes as an ordinary `<polyline>` (so
no SVG `<path>` curve commands are needed). Pure, so it is unit-tested.

@docs smooth, catmullRom

-}


{-| Smooth a point list with a Catmull-Rom spline at the default resolution (8 samples per segment).
The original points are preserved (the curve passes exactly through them); fewer than three points
are returned unchanged.
-}
smooth : List ( Float, Float ) -> List ( Float, Float )
smooth pts =
    catmullRom 8 pts


{-| Catmull-Rom smoothing with an explicit number of `samples` per segment (clamped to at least 1).
A list of N points becomes roughly `(N-1) * samples + 1` points following a curve tangent to the
data at each original point.
-}
catmullRom : Int -> List ( Float, Float ) -> List ( Float, Float )
catmullRom samples pts =
    let
        n =
            List.length pts
    in
    if n < 3 then
        pts

    else
        let
            arr =
                pts

            steps =
                Basics.max 1 samples

            -- for segment p1→p2, the neighbours are p0 (before) and p3 (after), clamped at the ends
            seg i =
                let
                    p0 =
                        at arr (i - 1)

                    p1 =
                        at arr i

                    p2 =
                        at arr (i + 1)

                    p3 =
                        at arr (i + 2)
                in
                List.map (\s -> point p0 p1 p2 p3 (toFloat s / toFloat steps)) (List.range 0 (steps - 1))

            body =
                List.concatMap seg (List.range 0 (n - 2))

            last =
                at arr (n - 1)
        in
        body ++ [ last ]


at : List ( Float, Float ) -> Int -> ( Float, Float )
at pts i =
    let
        n =
            List.length pts

        j =
            clamp 0 (n - 1) i
    in
    case List.head (List.drop j pts) of
        Just p ->
            p

        Nothing ->
            ( 0, 0 )


{-| One point of the Catmull-Rom segment p1→p2 at parameter t in [0, 1]. -}
point : ( Float, Float ) -> ( Float, Float ) -> ( Float, Float ) -> ( Float, Float ) -> Float -> ( Float, Float )
point ( x0, y0 ) ( x1, y1 ) ( x2, y2 ) ( x3, y3 ) t =
    ( crom x0 x1 x2 x3 t, crom y0 y1 y2 y3 t )


crom : Float -> Float -> Float -> Float -> Float -> Float
crom p0 p1 p2 p3 t =
    let
        t2 =
            t * t

        t3 =
            t2 * t
    in
    0.5
        * (((2 * p1)
                + ((p2 - p0) * t)
                + (((2 * p0) - (5 * p1) + (4 * p2) - p3) * t2)
                + ((-p0 + (3 * p1) - (3 * p2) + p3) * t3)
           )
          )
