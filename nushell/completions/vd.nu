# Nushell completions for vd — VisiData, a terminal interface for tabular data
# Built against VisiData 3.4.
#
# `vd --help` prints two lines and points at the website, so nothing here comes
# from it. The flags below were read off the argument loop in visidata/main.py
# and the option registry of the installed build.
#
# VisiData takes ANY of its ~273 settings as a command-line flag: it strips the
# dashes off an argument and looks the name up in the option registry, so
# `--default-width 30` and `--color-default red` are both valid. Declaring all
# of them would bury the handful anyone types, so this file carries the options
# that make sense before the interface is up, and leaves the rest — mostly the
# color_* and disp_* display settings, which belong in .visidatarc — undeclared.
# An undeclared flag still works; it just does not complete.
#
# Two of VisiData's short flags are two letters, -if and -of, which a Nushell
# signature cannot express: the (-x) short form holds exactly one character.
# -if is a second spelling of -f, and --output-filetype covers -of. Likewise -r
# is not a short form of --dir-depth but a preset for it, meaning "recurse all
# the way", so it is documented here rather than declared.

# Extracted from the open_* loaders of the installed VisiData 3.4. VisiData
# offers no runtime command that lists them, so this is a snapshot: a filetype
# added by a plugin will still work, it just will not appear in the menu.
const filetypes = [
    airtable arrow arrows babyl claude conll conllu csv dir dta eml f5log fdir
    fec fixed forg frictionless gdrive geojson git grep gsheets h5 html jrnl
    jsonl jsonla jsonobj lsv maildir mbox mbtiles mh mmdf mnu msgpack npy npz
    ods org orgdir pandas parquet pbf pcap pdf png psv puz pyprof rec reddit
    sas7bdat scrape shp spss sqlite syspaste tar toml tsv ttf txt usv vcf vd
    vdj vds vdsql vdx xd xls xlsb xlsx xml xpt yml zip zulip
]

export extern main [
    ...inputs: path # files, URLs or directories to open; - reads stdin
    --version (-v) # print version

    --filetype (-f): string@$filetypes # input filetype, overriding the file extension
    --output-filetype: string@$filetypes # filetype for the output path, overriding its extension
    --save-filetype: string@$filetypes # default filetype to save as
    --output (-o): path # save the final visible sheet here on exit
    --output-cell (-O): string # print the cursor cell display value on exit

    --batch (-b) # replay with no interface, status to stdout
    --interactive (-i) # run interactive mode after a batch replay
    --play (-p): path # .vdj file to replay
    --preplay (-P): string # longnames to run before the replay
    --replay-wait (-w): float # seconds to wait between replayed commands

    --global (-g) # apply the following options to every sheet
    --nonglobal (-n) # apply the following options only to the next input
    --nothing (-N) # no config, no plugins, nothing extra
    --config (-c): path # config file to exec in Python
    --imports: string # imports to preload before .visidatarc
    --plugins-autoload # autoload plugins
    --debug # exit on error and show the stacktrace
    --profile # enable profiling on threads

    --delimiter (-d): string # field delimiter for the tsv and csv filetypes
    --encoding: string # encoding passed to codecs.open when reading
    --encoding-errors: string # encoding_errors passed to codecs.open
    --header: int # parse the first N rows as column names
    --skip: int # skip N rows before the header
    --clean-names # rewrite column and sheet names as valid Python identifiers

    --csv-delimiter: string # delimiter passed to csv.reader
    --csv-dialect: string # dialect passed to csv.reader
    --csv-quotechar: string # quotechar passed to csv.reader
    --json-indent: int # indent to use when saving json

    --dir-depth: int # folder recursion depth on DirSheet; -r presets this to recurse all the way
    --dir-hidden # load hidden files on DirSheet
    --load-lazy # load subsheets lazily instead of always

    --confirm: string@[a y] # confirm interactive prompts: a asks, y assumes yes
    --overwrite: string@[c n] # overwriting existing files: c checks, n refuses
    --regex-flags: string # flags passed to re.compile, from AILMSUX
    --default-width: int # default column width
    --default-height: int # default column height
    --col-cache-size: int # max cache entries per cached column
    --visibility: int # visibility level
    --undo # enable undo and redo
    --fancy-chooser # nicer selection interface for aggregators and jointype
]
