# Nushell completions for chafa - terminal graphics and character art generator

# Symbol classes for --symbols and --fill
const symbol_classes = [
    all
    ascii
    braille
    extra
    imported
    narrow
    solid
    ugly
    alnum
    bad
    diagonal
    geometric
    inverted
    none
    space
    vhalf
    alpha
    block
    digit
    half
    latin
    quad
    stipple
    wedge
    ambiguous
    border
    dot
    hhalf
    legacy
    sextant
    technical
    wide
]

def "nu-complete chafa symbols" [] {
    $symbol_classes | each {|s| {value: $s description: $"Symbol class: ($s)"} }
}

def "nu-complete chafa format" [] {
    [
        {value: "iterm" description: "iTerm2 inline images (high quality)"}
        {value: "kitty" description: "Kitty terminal graphics protocol"}
        {value: "sixels" description: "Sixel graphics (DEC terminals)"}
        {value: "symbols" description: "Unicode character art (widest support)"}
    ]
}

def "nu-complete chafa colors" [] {
    [
        {value: "none" description: "No colors (monochrome)"}
        {value: "2" description: "2 colors"}
        {value: "8" description: "8 colors"}
        {value: "16/8" description: "16 foreground / 8 background"}
        {value: "16" description: "16 colors"}
        {value: "240" description: "240 colors"}
        {value: "256" description: "256 colors"}
        {value: "full" description: "24-bit true color"}
    ]
}

def "nu-complete chafa dither" [] {
    [
        {value: "none" description: "No dithering"}
        {value: "ordered" description: "Ordered dithering (Bayer matrix)"}
        {value: "diffusion" description: "Error diffusion dithering"}
        {value: "noise" description: "Noise-based dithering (default for sixels)"}
    ]
}

def "nu-complete chafa color-extractor" [] {
    [
        {value: "average" description: "Average color (default, faster)"}
        {value: "median" description: "Median color"}
    ]
}

def "nu-complete chafa color-space" [] {
    [
        {value: "rgb" description: "RGB color space (faster, default)"}
        {value: "din99d" description: "DIN99d color space (more accurate)"}
    ]
}

def "nu-complete chafa bool" [] {
    [on off]
}

def "nu-complete chafa probe" [] {
    [
        {value: "auto" description: "Automatic probe (default)"}
        {value: "on" description: "Always probe terminal"}
        {value: "off" description: "Never probe terminal"}
    ]
}

def "nu-complete chafa passthrough" [] {
    [
        {value: "auto" description: "Automatic detection"}
        {value: "none" description: "No passthrough"}
        {value: "screen" description: "GNU Screen passthrough"}
        {value: "tmux" description: "tmux passthrough"}
    ]
}

def "nu-complete chafa exact-size" [] {
    [
        {value: "auto" description: "Automatic (default)"}
        {value: "on" description: "Match input size exactly"}
        {value: "off" description: "Allow scaling"}
    ]
}

def "nu-complete chafa link" [] {
    [
        {value: "auto" description: "Auto-detect hyperlink support"}
        {value: "on" description: "Enable clickable labels"}
        {value: "off" description: "Disable clickable labels"}
    ]
}

# Main extern definition
export extern main [
    ...files: path # Image files to display
    --files: path # Read file list from PATH (or "-" for stdin)
    --files0: path # Read NUL-separated file list from PATH
    --probe: string@"nu-complete chafa probe" # Probe terminal capabilities [auto, on, off, or timeout]
    --version # Show version
    --verbose (-v) # Be verbose
    --format (-f): string@"nu-complete chafa format" # Output format [iterm, kitty, sixels, symbols]
    --optimize (-O): int # Compression level [0-9], default 5
    --relative: string@"nu-complete chafa bool" # Use relative cursor positioning [on, off]
    --passthrough: string@"nu-complete chafa passthrough" # Graphics passthrough mode [auto, none, screen, tmux]
    --polite: string@"nu-complete chafa bool" # Polite mode [on, off]
    --align: string # Alignment (e.g. "top,left", "mid,mid")
    --clear # Clear screen before each file
    --exact-size: string@"nu-complete chafa exact-size" # Match input size exactly [auto, on, off]
    --fit-width # Fit to view width, may exceed height
    --font-ratio: string # Font width/height ratio (e.g. "1/2" or "0.5")
    --grid: string # Grid layout CxR (e.g. "4x3", "4", "auto")
    -g # Alias for --grid auto
    --label: string@"nu-complete chafa bool" # Show filename labels [on, off]
    -l # Alias for --label on
    --link: string@"nu-complete chafa link" # Clickable label hyperlinks [auto, on, off]
    --margin-bottom: int # Bottom margin rows (default 1)
    --margin-right: int # Right margin columns (default 0)
    --scale: string # Scale factor (number or "max")
    --size (-s): string # Max dimensions WxH in columns/rows
    --stretch # Stretch to fit, ignore aspect ratio
    --view-size: string # View size WxH in columns/rows
    --animate: string@"nu-complete chafa bool" # Allow animation [on, off]
    --duration (-d): number # Display duration in seconds
    --speed: string # Animation speed (multiplier or "Nfps")
    --watch # Watch file for changes
    --bg: string # Background color (name or hex)
    --colors (-c): string@"nu-complete chafa colors" # Color mode [none, 2, 8, 16/8, 16, 240, 256, full]
    --color-extractor: string@"nu-complete chafa color-extractor" # Color extraction [average, median]
    --color-space: string@"nu-complete chafa color-space" # Quantization color space [rgb, din99d]
    --dither: string@"nu-complete chafa dither" # Dither mode [none, ordered, diffusion, noise]
    --dither-grain: string # Dither grain size WxH in 1/8ths [1,2,4,8]
    --dither-intensity: number # Dither intensity multiplier [0.0-inf]
    --fg: string # Foreground color (name or hex)
    --invert # Swap foreground and background colors
    --preprocess (-p): string@"nu-complete chafa bool" # Image preprocessing [on, off]
    --threshold (-t): number # Transparency threshold [0.0-1.0]
    --threads: int # Max CPU threads (-1 for all cores)
    --work (-w): int # Work intensity [1-9], default 5
    --fg-only # Use foreground colors only
    --fill: string@"nu-complete chafa symbols" # Fill/gradient symbols
    --glyph-file: path # Load glyphs from font file
    --symbols: string@"nu-complete chafa symbols" # Output symbol classes
]
