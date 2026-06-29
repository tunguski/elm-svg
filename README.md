# elm-svg

A small, **dependency-free SVG charting library** in Elm, for the
[elm-lang](https://github.com/tunguski/elm-lang) compiler.

Live site: **https://tunguski.github.io/elm-svg/** — a small **workspace** where you create and
manage your own charts (saved in your browser): name / open / search / copy / delete them, set
sharing & permissions, comment, and export their data to CSV / JSON. That whole experience comes
from the reusable [elm-workspace](https://github.com/tunguski/elm-workspace) library (vendored under
`vendor/`); the chart **document** and its live editor are this repo, drawn with `Chart` below.

One call gives you a chart:

```elm
import Chart

-- category charts: List ( String, Float )
Chart.bars Chart.defaults [ ( "Jan", 120 ), ( "Feb", 98 ), ( "Mar", 145 ) ]
Chart.line Chart.defaults temps           -- (label, value) with a zero baseline
Chart.area Chart.defaults sales           -- a line, filled to the baseline
Chart.hbars Chart.defaults ranking      -- horizontal bars (long labels / rankings)
Chart.lollipop Chart.defaults sales     -- stems topped with dots (a lighter bar)
Chart.histogram Chart.defaults numbers  -- bins a raw List Float into a distribution
Chart.density Chart.defaults numbers    -- smooth kernel-density curve of a List Float
Chart.boxplot Chart.defaults samples    -- List ( String, List Float ) — quartiles + whiskers
Chart.waterfall Chart.defaults steps    -- (label, delta) bridge bars to a running total
Chart.gauge Chart.defaults 0 100 72     -- a single KPI value as a dial
Chart.bullet Chart.defaults kpi         -- { value, target, max, bands } KPI with a target tick
Chart.sparkline (Chart.sized 200 48) ys -- a tiny, axis-less inline line

-- proportion / part-to-whole
Chart.pie Chart.defaults share
Chart.donut (Chart.withInner 0.6 Chart.defaults) share
Chart.rose Chart.defaults winds           -- polar area (Nightingale rose): radius by value
Chart.radialBars Chart.defaults share     -- concentric arc bars, sweep by value
Chart.funnel Chart.defaults stages        -- narrowing conversion stages
Chart.treemap Chart.defaults parts        -- nested rectangles, area by value

-- point / multi-series charts
Chart.scatter Chart.defaults points       -- raw (x, y); add Chart.withTrend True for a fit line
Chart.scatterErr Chart.defaults xyerr     -- List ( Float, Float, Float ) — y ± error bars
Chart.bubble Chart.defaults xysize        -- List ( Float, Float, Float ) — area = size
Chart.multiLine Chart.defaults serieses   -- List ( String, List (Float, Float) ), with a legend
Chart.stackedArea Chart.defaults serieses
Chart.streamgraph Chart.defaults serieses -- stack flowing around a centred baseline
Chart.radar Chart.defaults axes serieses  -- spider chart over shared axes
Chart.bump Chart.defaults league          -- List ( String, List Float ) — rank per period
Chart.slope Chart.defaults "2019" "2024" ranks  -- (label, before, after) two-period change
Chart.dumbbell Chart.defaults ranges      -- (label, low, high) range per category
Chart.pyramid Chart.defaults "M" "F" ages -- back-to-back (label, left, right) bars

-- segmented bars: List ( String, List ( String, Float ) ) — (category, [(series, value)])
Chart.stackedBars Chart.defaults revenue
Chart.groupedBars Chart.defaults revenue
Chart.percentBars Chart.defaults revenue  -- each category normalised to 100%
Chart.pareto Chart.defaults defects       -- sorted bars + cumulative % line (right axis)

-- financial: List ( String, open, high, low, close )
Chart.candlestick Chart.defaults ohlc

-- a grid: column labels, row labels, rows of values
Chart.heatmap Chart.defaults cols rows grid

-- a schedule: List ( String, start, end )
Chart.gantt Chart.defaults schedule
```

Each function returns an `Svg msg` you drop straight into a page. Numeric axes draw **1·2·5
gridlines** and tick labels (X and Y); multi-series charts draw a **legend**; every mark carries a
native `<title>` **hover tooltip** (no Elm state). Line and area series can be **smoothed**
(`Chart.withCurve True`) or **stepped** (`Chart.withStep True`); add **reference lines and bands**
(`Chart.withRefLine` / `Chart.withRefBand`), a scatter **trend line** (`Chart.withTrend True`), or
custom **number formatting** for the axis and value labels (`Chart.withFormat Format.percent`). The
axis and legend are tunable too — `withYDomain` / `withYTicks` / `withMargins` and `withLegend`
(any corner, or `NoLegend`). The
number-crunching — domain→pixel mapping (linear or **log**), bounds and ticks, number/coordinate
formatting, slicing a circle, binning a sample, blending colours, spline smoothing, quartiles and
least-squares fits — lives in separate, fully unit-tested [`Scale`](src/Scale.elm),
[`Arc`](src/Arc.elm), [`Curve`](src/Curve.elm), [`Stat`](src/Stat.elm) and [`Format`](src/Format.elm)
modules.

## Theming

The `Config` carries a small theme. Build it through the composable constructors (never
`{ Chart.defaults | … }` — see the gotchas below):

```elm
Chart.sized 460 260
    |> Chart.darken                       -- dark theme, keeping the size
    |> Chart.withTitle "Quarterly revenue"
    |> Chart.withAxisTitles "quarter" "£k"
    |> Chart.withValues True              -- value labels on bars
    |> Chart.withGrid False               -- hide the gridlines
```

### Styling

Colours, fills and the legend are all configurable:

```elm
cfg
    |> Chart.withPalette [ "#264653", "#2a9d8f", "#e9c46a", "#f4a261" ]  -- series colours
    |> Chart.withColorScale "#fff5eb" "#d94801"   -- heatmap/bubble/bullet ramp
    |> Chart.withGradient True                    -- gradient fills on bars/areas/slices
    |> Chart.withPlotBackground "#f5f7fb"         -- panel behind the data
    |> Chart.withBorder "#c2ccdc"                 -- border around the plot
    |> Chart.withFont "Georgia, serif" 11         -- typography
    |> Chart.withDots 5                           -- marker radius
    |> Chart.withStroke 3                         -- line width
    |> Chart.withLegend Chart.TopLeft             -- corner, or Chart.NoLegend
    |> Chart.withLegendRow True                   -- horizontal legend
    |> Chart.withLegendTitle "Series"
    |> Chart.withHidden [ "cos" ]                 -- show/hide series (dimmed in the legend)
```

`withHidden` is the basis of a **dynamic, clickable legend**: keep the hidden-name list in your
model, toggle it on a legend click, and re-render — the chart stays a pure function of that state.

## Modules

- **`Scale`** — linear **and log** scales (`linear` / `log` / `convert` / `invert`), bounds and
  ticks (`niceBounds`, `ticks`, and the rounded `niceNum` / `niceTicks` / `niceBoundsRounded`),
  histogram `binCounts`, colour `interpolateColor`, and coordinate formatting (`num` / `point` /
  `pointsString`). No SVG, so it is exhaustively tested.
- **`Arc`** — the pie/donut maths: `slices` (values → angular slices) and `wedgePoints` /
  `ringPoints` (slices → polygon point-lists). Also pure and tested.
- **`Curve`** — `smooth` / `catmullRom`: a point list → a smooth spline sampled as points (so a
  plain `<polyline>` renders the curve). Pure and tested.
- **`Stat`** — `mean` / `median` / `quantile` / `quartiles` / `stdDev` / `linearRegression` / `kde`:
  the summary stats behind box plots, trend lines and density curves. Pure and tested.
- **`Format`** — `decimals` / `percent` / `compact` / `prefixed` / `suffixed`: ready-made
  `Float -> String` formatters for `Chart.withFormat`. Pure and tested.
- **`Layout`** — `treemap`: tiles a box into value-proportional rectangles by recursive binary
  slicing. Pure and tested.
- **`Chart`** — ~37 chart types over plain Elm data: `bars`, `hbars`, `lollipop`, `line`, `area`,
  `scatter`, `scatterErr`, `bubble`, `multiLine`, `slope`, `dumbbell`, `pyramid`, `bump`,
  `stackedArea`, `streamgraph`, `stackedBars`, `groupedBars`, `percentBars`, `pareto`, `histogram`,
  `density`, `pie`, `donut`, `radar`, `funnel`, `rose`, `radialBars`, `boxplot`, `candlestick`,
  `heatmap`, `sparkline`, `waterfall`, `gauge`, `bullet`, `treemap`, `gantt`; the `Config`
  constructors for **style** (`sized`, `darken`, `withColor`, `withPalette`, `withGradient`,
  `withColorScale`, `withPlotBackground`, `withBorder`, `withFont`, `withDots`, `withStroke`),
  **annotation** (`withTitle`, `withAxisTitles`, `withValues`, `withCurve`, `withStep`, `withTrend`,
  `withFormat`, `withRefLine`, `withRefBand`, `withTips`), **axis/layout** (`withGrid`, `withInner`,
  `withYDomain`, `withYTicks`, `withMargins`) and **legend** (`withLegend`, `withLegendRow`,
  `withLegendTitle`, `withHidden`); and the building blocks (`frame`, `xAxis`, `legend`, `polylineOf`,
  `dotsOf`) for bespoke charts.

## Gotchas it bakes in

This library targets the elm-lang JS backend, and encodes a few of its quirks so you don't trip
on them:

- **Several `Svg.Attributes` are unbound** — `class` (so no CSS classes; every colour is set
  **inline** from the [`Config`](src/Chart.elm)) and also `id` / `offset` / `stop-color` /
  `stop-opacity`. The gradient `<defs>` therefore set those through the generic, bound
  `Html.Attributes.attribute "name" value` escape hatch, which works on SVG nodes.
- **A record update on a record alias imported from another module miscompiles** (the un-updated
  fields come back `undefined`). So tweak a `Config` with the provided constructors —
  `Chart.sized w h`, `Chart.darken`, `Chart.withGrid on` — which do the update *inside* `Chart`,
  rather than `{ Chart.defaults | width = … }` at your own call site. The `with*` constructors take
  a `Config` and return one, so they chain with `|>`.
- **`let` bindings are evaluated in source order, without hoisting.** A binding that is built
  eagerly (e.g. `List.indexedMap …`) may not reference a *later* binding in the same `let` — at
  evaluation time that name is still `undefined` and you get a runtime `reading 'n'` crash. Define
  helpers **above** the bindings that use them.

Pie, donut and radar areas are drawn as filled `<polyline>`s (which close themselves under `fill`),
sidestepping the unbound `<path>` element rather than relying on arc path commands.

## Use it in another project

Each elm-lang project is its own repo, so reuse is by **vendoring**: copy `src/Chart.elm` and the
pure modules it uses (`Scale`, `Arc`, `Curve`, `Stat`, `Format`, `Layout`) into your project's source path and
import `Chart`. (This is how `elm-notebook` draws its cell charts.)

## Develop

With this repo checked out next to a built [`elm-lang`](https://github.com/tunguski/elm-lang)
(so `../../elm.sh` exists):

```sh
ELM=../../elm.sh ./test.sh     # run the headless Scale test suite
ELM=../../elm.sh ./build.sh    # compile the demo gallery → build/elm-svg.html
```

`.github/workflows/pages.yml` runs the same in CI and deploys to GitHub Pages, gated on the
tests passing.

Part of the [elm-lang](https://github.com/tunguski/elm-lang) ecosystem.
