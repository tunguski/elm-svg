module Examples exposing (examples)

{-| The elm-svg **charts** showcase — the list of [`Example`](Example)s, each carrying the live chart
and the complete, self-contained Elm source (data + config + call) that reproduces it. The data
definitions in the code are *derived* from the same values that are rendered, so they always match.
The host ([`Gallery`](Gallery)) shows them as clickable cards with a code detail view.

@docs examples

-}

import Chart
import Example exposing (Example)
import Format
import Html exposing (Html)


sales : List ( String, Float )
sales =
    [ ( "Jan", 120 ), ( "Feb", 98 ), ( "Mar", 145 ), ( "Apr", 132 ), ( "May", 168 ), ( "Jun", 180 ) ]


temps : List ( String, Float )
temps =
    [ ( "Mon", -3 ), ( "Tue", 1 ), ( "Wed", 4 ), ( "Thu", 2 ), ( "Fri", 7 ), ( "Sat", 9 ), ( "Sun", 5 ) ]


cloud : List ( Float, Float )
cloud =
    [ ( 1, 2 ), ( 2, 3.2 ), ( 3, 2.8 ), ( 4, 5 ), ( 5, 4.4 ), ( 6, 6.1 ), ( 7, 5.5 ), ( 8, 7.8 ), ( 9, 7.2 ), ( 10, 9 ) ]


waves : List ( String, List ( Float, Float ) )
waves =
    [ ( "sin", List.map (\i -> ( toFloat i, sin (toFloat i / 3) * 4 + 5 )) (List.range 0 24) )
    , ( "cos", List.map (\i -> ( toFloat i, cos (toFloat i / 3) * 3 + 5 )) (List.range 0 24) )
    ]


bands : List ( String, List ( Float, Float ) )
bands =
    [ ( "organic", List.map (\i -> ( toFloat i, 3 + sin (toFloat i / 4) * 1.5 )) (List.range 0 12) )
    , ( "paid", List.map (\i -> ( toFloat i, 2 + cos (toFloat i / 5) )) (List.range 0 12) )
    , ( "referral", List.map (\i -> ( toFloat i, 1.2 + sin (toFloat i / 3) * 0.6 )) (List.range 0 12) )
    ]


revenue : List ( String, List ( String, Float ) )
revenue =
    [ ( "Q1", [ ( "Web", 30 ), ( "Mobile", 20 ), ( "Store", 12 ) ] )
    , ( "Q2", [ ( "Web", 36 ), ( "Mobile", 28 ), ( "Store", 14 ) ] )
    , ( "Q3", [ ( "Web", 33 ), ( "Mobile", 35 ), ( "Store", 11 ) ] )
    , ( "Q4", [ ( "Web", 42 ), ( "Mobile", 39 ), ( "Store", 16 ) ] )
    ]


share : List ( String, Float )
share =
    [ ( "Chrome", 64 ), ( "Safari", 19 ), ( "Edge", 9 ), ( "Firefox", 5 ), ( "Other", 3 ) ]


languages : List ( String, Float )
languages =
    [ ( "Rust", 87 ), ( "Elm", 74 ), ( "Go", 69 ), ( "Haskell", 58 ), ( "C", 46 ) ]


planets : List ( Float, Float, Float )
planets =
    -- distance from sun (AU), mean temperature (°C), mass (Earths)
    [ ( 0.39, 167, 0.055 ), ( 0.72, 464, 0.82 ), ( 1.0, 15, 1.0 ), ( 1.52, -65, 0.11 ), ( 5.2, -110, 318 ), ( 9.5, -140, 95 ) ]


scores : List Float
scores =
    [ 52, 61, 58, 67, 70, 72, 75, 74, 78, 80, 81, 83, 85, 84, 86, 88, 90, 91, 77, 69, 73, 79, 82, 87, 65, 71, 76, 84, 89, 92, 68, 74, 80, 85, 63, 77, 81, 88 ]


radarAxes : List String
radarAxes =
    [ "Speed", "Power", "Range", "Defense", "Agility", "Support" ]


squads : List ( String, List Float )
squads =
    [ ( "Red", [ 8, 6, 4, 7, 9, 5 ] ), ( "Blue", [ 5, 9, 7, 6, 4, 8 ] ) ]


samples : List ( String, List Float )
samples =
    [ ( "Class A", [ 62, 65, 68, 70, 72, 75, 78, 80, 85 ] )
    , ( "Class B", [ 55, 60, 63, 66, 70, 73, 77, 82, 90 ] )
    , ( "Class C", [ 70, 72, 74, 75, 77, 79, 80, 82, 84 ] )
    ]


ohlc : List ( String, Float, Float, Float, Float )
ohlc =
    [ ( "Mon", 100, 108, 98, 105 )
    , ( "Tue", 105, 110, 103, 104 )
    , ( "Wed", 104, 112, 102, 111 )
    , ( "Thu", 111, 115, 107, 109 )
    , ( "Fri", 109, 113, 105, 112 )
    ]


heatCols : List String
heatCols =
    [ "Mon", "Tue", "Wed", "Thu", "Fri" ]


heatRows : List String
heatRows =
    [ "9am", "12pm", "3pm", "6pm" ]


heatVals : List (List Float)
heatVals =
    [ [ 2, 5, 4, 6, 8 ]
    , [ 9, 12, 10, 14, 15 ]
    , [ 6, 8, 7, 9, 11 ]
    , [ 3, 4, 6, 5, 7 ]
    ]


trail : List Float
trail =
    [ 3, 4, 3.5, 5, 4.5, 6, 5.5, 7, 6.5, 8, 7.5, 9 ]


cashflow : List ( String, Float )
cashflow =
    [ ( "Start", 50 ), ( "Sales", 80 ), ( "Refund", -20 ), ( "Costs", -35 ), ( "Tax", -12 ) ]


ranks : List ( String, Float, Float )
ranks =
    [ ( "Rust", 70, 87 ), ( "Elm", 60, 74 ), ( "Go", 75, 69 ), ( "Haskell", 50, 58 ), ( "C", 55, 46 ) ]


measured : List ( Float, Float, Float )
measured =
    [ ( 1, 2.1, 0.4 ), ( 2, 3.0, 0.5 ), ( 3, 2.6, 0.3 ), ( 4, 4.2, 0.6 ), ( 5, 4.0, 0.4 ), ( 6, 5.3, 0.5 ) ]


teams : List ( String, Float )
teams =
    [ ( "Engineering", 42 ), ( "Sales", 28 ), ( "Support", 16 ), ( "Design", 10 ), ( "Ops", 8 ), ( "Legal", 4 ) ]


funnelData : List ( String, Float )
funnelData =
    [ ( "Visits", 1000 ), ( "Signups", 620 ), ( "Trials", 380 ), ( "Paid", 145 ), ( "Renewed", 98 ) ]


schedule : List ( String, Float, Float )
schedule =
    [ ( "Design", 0, 3 ), ( "Build", 2, 7 ), ( "Test", 6, 9 ), ( "Docs", 8, 10 ), ( "Launch", 10, 11 ) ]


ranges : List ( String, Float, Float )
ranges =
    [ ( "Jan", 2, 9 ), ( "Feb", 3, 11 ), ( "Mar", 6, 15 ), ( "Apr", 9, 19 ), ( "May", 13, 23 ) ]


defects : List ( String, Float )
defects =
    [ ( "Scratch", 42 ), ( "Dent", 30 ), ( "Crack", 18 ), ( "Stain", 12 ), ( "Chip", 8 ), ( "Other", 5 ) ]


winds : List ( String, Float )
winds =
    [ ( "N", 8 ), ( "NE", 5 ), ( "E", 3 ), ( "SE", 6 ), ( "S", 9 ), ( "SW", 7 ), ( "W", 4 ), ( "NW", 6 ) ]


ages : List ( String, Float, Float )
ages =
    [ ( "0–19", 22, 21 ), ( "20–39", 28, 27 ), ( "40–59", 26, 27 ), ( "60–79", 17, 19 ), ( "80+", 5, 8 ) ]


league : List ( String, List Float )
league =
    [ ( "Lions", [ 10, 14, 12, 18, 22 ] )
    , ( "Bears", [ 12, 11, 15, 14, 16 ] )
    , ( "Hawks", [ 8, 13, 17, 16, 20 ] )
    , ( "Wolves", [ 14, 10, 9, 12, 13 ] )
    ]


activity : List Float
activity =
    List.map (\i -> toFloat (modBy 5 (i * 7 + 3)) + toFloat (modBy 3 i)) (List.range 0 48)


flows : List ( String, String, Float )
flows =
    [ ( "Search", "Signup", 50 )
    , ( "Search", "Bounce", 30 )
    , ( "Social", "Signup", 25 )
    , ( "Social", "Bounce", 35 )
    , ( "Direct", "Signup", 40 )
    , ( "Direct", "Bounce", 15 )
    ]



-- THE EXAMPLES ---------------------------------------------------------------


{-| Every chart example, with its live view and reproducing source, at the given size. -}
examples : Float -> List (Example msg)
examples size =
    let
        cfg =
            Chart.sized size (size * 0.55)

        salesD =
            def "sales" (listOf sf sales)

        tempsD =
            def "temps" (listOf sf temps)

        cloudD =
            def "cloud" (listOf ff cloud)

        revenueD =
            def "revenue" (listOf slsf revenue)

        shareD =
            def "share" (listOf sf share)

        scoresD =
            def "scores" (listOf nm scores)
    in
    [ ex "Bar chart" "Categorical values over gridlines, labelled per bar; a zero baseline is always shown." [ salesD ] """Chart.bars (Chart.withValues True cfg) sales""" (Chart.bars (Chart.withValues True cfg) sales)
    , ex "Line chart" "A value per category, with markers. Negative values dip below the baseline." [ tempsD ] """Chart.line cfg temps""" (Chart.line cfg temps)
    , ex "Area chart" "A line with the region down to the baseline filled." [ salesD ] """Chart.area (Chart.withColor "#0f9d58" cfg) sales""" (Chart.area (Chart.withColor "#0f9d58" cfg) sales)
    , ex "Scatter plot" "Raw (x, y) points, each axis scaled to its own data." [ cloudD ] """Chart.scatter cfg cloud""" (Chart.scatter cfg cloud)
    , ex "Multi-series" "Several named series, each in a palette colour, with a legend." [ wavesSrc ] """Chart.multiLine cfg waves""" (Chart.multiLine cfg waves)
    , ex "Bump chart" "Each series' rank per period, connected — how an ordering shifts over time." [ def "league" (listOf slf league) ] """Chart.bump cfg league""" (Chart.bump cfg league)
    , ex "Show / hide series" "Hide series by name (dimmed in the legend) — drive a clickable legend from your model." [ wavesSrc ] """Chart.multiLine (Chart.withHidden [ "cos" ] cfg) waves""" (Chart.multiLine (Chart.withHidden [ "cos" ] cfg) waves)
    , ex "Stacked area" "Named series stacked into translucent filled bands." [ bandsSrc ] """Chart.stackedArea cfg bands""" (Chart.stackedArea cfg bands)
    , ex "Streamgraph" "The same series flowing around a centred baseline." [ bandsSrc ] """Chart.streamgraph cfg bands""" (Chart.streamgraph cfg bands)
    , ex "Legend placement" "Move the legend to any corner — or hide it with NoLegend." [ wavesSrc ] """Chart.multiLine (Chart.withLegend Chart.BottomLeft cfg) waves""" (Chart.multiLine (Chart.withLegend Chart.BottomLeft cfg) waves)
    , ex "Legend row + title" "A horizontal legend with a heading." [ wavesSrc ] """Chart.multiLine (Chart.withLegendTitle "Series" (Chart.withLegendRow True (Chart.withLegend Chart.TopLeft cfg))) waves""" (Chart.multiLine (Chart.withLegendTitle "Series" (Chart.withLegendRow True (Chart.withLegend Chart.TopLeft cfg))) waves)
    , ex "Stacked bars" "Each category split into stacked, colour-keyed segments." [ revenueD ] """Chart.stackedBars cfg revenue""" (Chart.stackedBars cfg revenue)
    , ex "Grouped bars" "The same data as side-by-side bars per category." [ revenueD ] """Chart.groupedBars cfg revenue""" (Chart.groupedBars cfg revenue)
    , ex "100% stacked" "Each category normalised to 100% — compares composition, not totals." [ revenueD ] """Chart.percentBars cfg revenue""" (Chart.percentBars cfg revenue)
    , ex "Pareto" "Sorted bars with a cumulative-% line on a right axis — the 80/20 view." [ def "defects" (listOf sf defects) ] """Chart.pareto cfg defects""" (Chart.pareto cfg defects)
    , ex "Pie chart" "Slices sized by value, summing to the whole." [ shareD ] """Chart.pie cfg share""" (Chart.pie cfg share)
    , ex "Custom palette" "Bring your own series colours with Chart.withPalette." [ shareD ] """Chart.pie (Chart.withPalette [ "#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51" ] cfg) share""" (Chart.pie (Chart.withPalette [ "#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51" ] cfg) share)
    , ex "Gradient fills" "Vertical gradient fills on bars, areas and slices." [ salesD ] """Chart.bars (Chart.withGradient True cfg) sales""" (Chart.bars (Chart.withGradient True cfg) sales)
    , ex "Plot panel & border" "A panel behind the data and a border around the plot area." [ tempsD ] """Chart.line (Chart.withPlotBackground "#f5f7fb" (Chart.withBorder "#c2ccdc" cfg)) temps""" (Chart.line (Chart.withPlotBackground "#f5f7fb" (Chart.withBorder "#c2ccdc" cfg)) temps)
    , ex "Donut chart" "A pie with a hole — set by Chart.withInner." [ shareD ] """Chart.donut (Chart.withInner 0.6 cfg) share""" (Chart.donut (Chart.withInner 0.6 cfg) share)
    , ex "Funnel" "Narrowing stages for a conversion flow; hover for share of the first." [ def "funnelData" (listOf sf funnelData) ] """Chart.funnel cfg funnelData""" (Chart.funnel cfg funnelData)
    , ex "Polar area" "Equal-angle slices with radius by value — a Nightingale rose." [ def "winds" (listOf sf winds) ] """Chart.rose cfg winds""" (Chart.rose cfg winds)
    , ex "Radial bars" "Concentric arcs, one ring per category, sweep by value." [ shareD ] """Chart.radialBars cfg share""" (Chart.radialBars cfg share)
    , ex "Horizontal bars" "Categories down the left, values across — good for long labels and rankings." [ def "languages" (listOf sf languages) ] """Chart.hbars cfg languages""" (Chart.hbars cfg languages)
    , ex "Bubble chart" "A third dimension as bubble area, coloured along a sequential ramp. Hover for values." [ def "planets" (listOf fff planets) ] """Chart.bubble cfg planets""" (Chart.bubble cfg planets)
    , ex "Histogram" "A raw list of numbers binned into a distribution." [ scoresD ] """Chart.histogram cfg scores""" (Chart.histogram cfg scores)
    , ex "Density" "A smooth kernel-density curve — the continuous companion to a histogram." [ scoresD ] """Chart.density cfg scores""" (Chart.density cfg scores)
    , ex "Radar chart" "Several series compared across shared axes." [ def "radarAxes" (listOf qt radarAxes), def "squads" (listOf slf squads) ] """Chart.radar cfg radarAxes squads""" (Chart.radar cfg radarAxes squads)
    , ex "Smooth line" "The same line, smoothed with a Catmull-Rom curve." [ tempsD ] """Chart.line (Chart.withCurve True cfg) temps""" (Chart.line (Chart.withCurve True cfg) temps)
    , ex "Stepped line" "A stair step — for values that hold then jump." [ tempsD ] """Chart.line (Chart.withStep True cfg) temps""" (Chart.line (Chart.withStep True cfg) temps)
    , ex "Mark styling" "Tune typography, line weight and marker size." [ tempsD ] """Chart.line (Chart.withStroke 3.5 (Chart.withDots 5 (Chart.withFont "Georgia, serif" 11 cfg))) temps""" (Chart.line (Chart.withStroke 3.5 (Chart.withDots 5 (Chart.withFont "Georgia, serif" 11 cfg))) temps)
    , ex "Box plots" "Quartiles, median and whiskers per sample, from the tested Stat module." [ def "samples" (listOf slf samples) ] """Chart.boxplot cfg samples""" (Chart.boxplot cfg samples)
    , ex "Violin plot" "A mirrored kernel-density curve per sample — the smooth cousin of a box plot." [ def "samples" (listOf slf samples) ] """Chart.violin cfg samples""" (Chart.violin cfg samples)
    , ex "Waffle chart" "100 cells apportioned by share (largest-remainder), one colour per category." [ shareD ] """Chart.waffle cfg share""" (Chart.waffle cfg share)
    , ex "Calendar heatmap" "Daily values laid out as weeks × weekdays, shaded by value." [ activitySrc ] """Chart.calendar cfg 2 activity""" (Chart.calendar cfg 2 activity)
    , ex "Mosaic / Marimekko" "Stacked bars with variable column widths — width by category total, height 100%." [ revenueD ] """Chart.mosaic cfg revenue""" (Chart.mosaic cfg revenue)
    , ex "Sankey diagram" "Two-level flows from sources to targets, banded by volume." [ def "flows" (listOf ssf2 flows) ] """Chart.sankey cfg flows""" (Chart.sankey cfg flows)
    , ex "Point annotation" "Ring-and-label callouts at data points, set with Chart.withMarker." [ cloudD ] """Chart.scatter (Chart.withMarker 6 6.1 "peak" cfg) cloud""" (Chart.scatter (Chart.withMarker 6 6.1 "peak" cfg) cloud)
    , ex "Candlestick" "Open/high/low/close — up days green, down days red." [ def "ohlc" (listOf ohlcT ohlc) ] """Chart.candlestick cfg ohlc""" (Chart.candlestick cfg ohlc)
    , ex "Heatmap" "A grid shaded along a colour ramp; hover for values." [ heatColsD, heatRowsD, heatValsD ] """Chart.heatmap cfg heatCols heatRows heatVals""" (Chart.heatmap cfg heatCols heatRows heatVals)
    , ex "Custom colour scale" "Set the sequential ramp for heatmaps, bubbles and bullets." [ heatColsD, heatRowsD, heatValsD ] """Chart.heatmap (Chart.withColorScale "#fff5eb" "#d94801" cfg) heatCols heatRows heatVals""" (Chart.heatmap (Chart.withColorScale "#fff5eb" "#d94801" cfg) heatCols heatRows heatVals)
    , ex "Treemap" "Nested rectangles sized by value, tiled by the Layout module." [ def "teams" (listOf sf teams) ] """Chart.treemap cfg teams""" (Chart.treemap cfg teams)
    , ex "Gantt" "Task bars spanning their start–end on a shared time axis." [ def "schedule" (listOf sff schedule) ] """Chart.gantt cfg schedule""" (Chart.gantt cfg schedule)
    , ex "Trend line" "A least-squares regression line over the points." [ cloudD ] """Chart.scatter (Chart.withTrend True cfg) cloud""" (Chart.scatter (Chart.withTrend True cfg) cloud)
    , ex "Error bars" "Points with a vertical y ± error whisker each." [ def "measured" (listOf fff measured) ] """Chart.scatterErr cfg measured""" (Chart.scatterErr cfg measured)
    , ex "Reference marks" "A target line and a tolerance band behind the data." [ salesD ] """Chart.bars (Chart.withRefLine 160 "goal" (Chart.withRefBand 150 175 "ok" cfg)) sales""" (Chart.bars (Chart.withRefLine 160 "goal" (Chart.withRefBand 150 175 "ok" cfg)) sales)
    , ex "Sparkline" "A tiny, axis-less line for inline use." [ def "trail" (listOf nm trail) ] """Chart.sparkline (Chart.sized 220 52) trail""" (Chart.sparkline (Chart.sized 220 52) trail)
    , ex "Waterfall" "Floating bars bridge a start value to an end through up/down contributions." [ def "cashflow" (listOf sf cashflow) ] """Chart.waterfall cfg cashflow""" (Chart.waterfall cfg cashflow)
    , ex "Gauge" "A single headline value as a dial — for KPIs on a dashboard." [] """Chart.gauge cfg 0 100 72""" (Chart.gauge cfg 0 100 72)
    , ex "Bullet" "A compact KPI: measure bar over qualitative bands with a target tick." [] """Chart.bullet cfg { value = 72, target = 85, max = 100, bands = [ 50, 75 ] }""" (Chart.bullet cfg { value = 72, target = 85, max = 100, bands = [ 50, 75 ] })
    , ex "Lollipop" "Stems topped with dots — a lighter alternative to bars." [ salesD ] """Chart.lollipop cfg sales""" (Chart.lollipop cfg sales)
    , ex "Slope chart" "Value or rank changes between two periods — green up, red down." [ def "ranks" (listOf sff ranks) ] """Chart.slope cfg "2019" "2024" ranks""" (Chart.slope cfg "2019" "2024" ranks)
    , ex "Dumbbell" "A low–high range per category, as two connected dots." [ def "ranges" (listOf sff ranges) ] """Chart.dumbbell cfg ranges""" (Chart.dumbbell cfg ranges)
    , ex "Population pyramid" "Back-to-back bars comparing two groups across categories." [ def "ages" (listOf sff ages) ] """Chart.pyramid cfg "Male" "Female" ages""" (Chart.pyramid cfg "Male" "Female" ages)
    , ex "Formatted axis" "Number formatting on ticks and value labels — money, percent, compact k/M." [ salesD ] """Chart.bars (Chart.withFormat (Format.prefixed "$" (Format.decimals 0)) (Chart.withValues True cfg)) sales""" (Chart.bars (Chart.withFormat (Format.prefixed "$" (Format.decimals 0)) (Chart.withValues True cfg)) sales)
    , ex "Pinned axis" "A fixed Y domain and tick count, instead of fitting to the data." [ tempsD ] """Chart.line (Chart.withYTicks 5 (Chart.withYDomain -10 15 cfg)) temps""" (Chart.line (Chart.withYTicks 5 (Chart.withYDomain -10 15 cfg)) temps)
    , ex "Titled & dark" "Chart and axis titles, on the dark theme — Chart.darken keeps the slider size." [ salesD ] """Chart.bars (Chart.withTitle "Sales" (Chart.withAxisTitles "month" "" (Chart.darken cfg))) sales""" (Chart.bars (Chart.withTitle "Sales" (Chart.withAxisTitles "month" "" (Chart.darken cfg))) sales)
    ]



-- CODE ASSEMBLY --------------------------------------------------------------


ex : String -> String -> List String -> String -> Html msg -> Example msg
ex title note datas call view =
    let
        imports =
            if String.contains "Format." call then
                "import Chart\nimport Format\n\n\n"

            else
                "import Chart\n\n\n"

        dataBlock =
            if List.isEmpty datas then
                ""

            else
                String.join "\n\n\n" datas ++ "\n\n\n"

        cfgBlock =
            if String.contains "cfg" call then
                "cfg =\n    Chart.sized 380 209\n\n\n"

            else
                ""
    in
    { title = title
    , note = note
    , code = imports ++ dataBlock ++ cfgBlock ++ "chart =\n    " ++ call
    , view = view
    }


def : String -> String -> String
def name body =
    name ++ " =\n    " ++ body


wavesSrc : String
wavesSrc =
    """waves =
    [ ( "sin", List.map (\\i -> ( toFloat i, sin (toFloat i / 3) * 4 + 5 )) (List.range 0 24) )
    , ( "cos", List.map (\\i -> ( toFloat i, cos (toFloat i / 3) * 3 + 5 )) (List.range 0 24) )
    ]"""


bandsSrc : String
bandsSrc =
    """bands =
    [ ( "organic", List.map (\\i -> ( toFloat i, 3 + sin (toFloat i / 4) * 1.5 )) (List.range 0 12) )
    , ( "paid", List.map (\\i -> ( toFloat i, 2 + cos (toFloat i / 5) )) (List.range 0 12) )
    , ( "referral", List.map (\\i -> ( toFloat i, 1.2 + sin (toFloat i / 3) * 0.6 )) (List.range 0 12) )
    ]"""



-- VALUE → ELM SOURCE ---------------------------------------------------------


qt : String -> String
qt s =
    "\"" ++ s ++ "\""


nm : Float -> String
nm f =
    if toFloat (round f) == f && abs f < 1.0e12 then
        String.fromInt (round f)

    else
        String.fromFloat f


brk : List String -> String
brk items =
    "[ " ++ String.join ", " items ++ " ]"


listOf : (a -> String) -> List a -> String
listOf f xs =
    brk (List.map f xs)


sf : ( String, Float ) -> String
sf ( a, b ) =
    "( " ++ qt a ++ ", " ++ nm b ++ " )"


ff : ( Float, Float ) -> String
ff ( a, b ) =
    "( " ++ nm a ++ ", " ++ nm b ++ " )"


fff : ( Float, Float, Float ) -> String
fff ( a, b, c ) =
    "( " ++ nm a ++ ", " ++ nm b ++ ", " ++ nm c ++ " )"


sff : ( String, Float, Float ) -> String
sff ( a, b, c ) =
    "( " ++ qt a ++ ", " ++ nm b ++ ", " ++ nm c ++ " )"


ohlcT : ( String, Float, Float, Float, Float ) -> String
ohlcT ( a, o, h, l, c ) =
    "( " ++ qt a ++ ", " ++ nm o ++ ", " ++ nm h ++ ", " ++ nm l ++ ", " ++ nm c ++ " )"


slf : ( String, List Float ) -> String
slf ( a, bs ) =
    "( " ++ qt a ++ ", " ++ listOf nm bs ++ " )"


slsf : ( String, List ( String, Float ) ) -> String
slsf ( a, bs ) =
    "( " ++ qt a ++ ", " ++ listOf sf bs ++ " )"


ssf2 : ( String, String, Float ) -> String
ssf2 ( a, b, v ) =
    "( " ++ qt a ++ ", " ++ qt b ++ ", " ++ nm v ++ " )"


activitySrc : String
activitySrc =
    """activity =
    List.map (\\i -> toFloat (modBy 5 (i * 7 + 3)) + toFloat (modBy 3 i)) (List.range 0 48)"""


heatColsD : String
heatColsD =
    def "heatCols" (listOf qt heatCols)


heatRowsD : String
heatRowsD =
    def "heatRows" (listOf qt heatRows)


heatValsD : String
heatValsD =
    def "heatVals" (listOf (\r -> listOf nm r) heatVals)
