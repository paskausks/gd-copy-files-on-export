<img src="icon.svg" width="128" height="128">

# Copy Files On Export, a Godot addon

Copy Files On Export is an addon for [Godot 4](https://godotengine.org) which allows you to define a set of files which will be copied alongside the project when it is exported! Useful if you want to include a README or other files for your users without having to copy the files manually or set up automation via external means.

![Screenshot of the addon's settings section in Project ](media/screenshot1.png)

The minimum supported Godot version is Godot 4.2, although it likely also works on older Godot 4 releases.

## Installation

First, make sure you have a valid Godot engine version

Download the ZIP from github and put the `addons` folder in your project root or just look up the addon on the Godot AssetLib and press Download!

Then head to the _Project_ → _Project Settings_ → _Plugins_ and check the box next to the "Copy Files On Export" addon. In the project settings, a new tab with the same name should appear. If not, restarting Godot should fix it!

## Usage

To configure the addon, head to _Project_ → _Project Settings_ → _Copy Files On Export_. The table in that section defines the file mappings which will be copied to the export location. Click `Add` to add a new mapping. Then press `Select` and navigate to the file you wish to include in your export destination. Then for `Path in export location` type a valid path which defines the destination of the mapped file. The following formats should work:

* `some-file.txt`
* `foo/bar/some-file.txt`
* `/foo/bar/some-file.txt`
* `./foo/bar/some-file.txt`
* etc.

For example, if you define the following set of files:

| File                                    | Path in export location          |
|-----------------------------------------|----------------------------------|
| res://README.txt                        | README.txt                       |
| res://LICENCE.txt                       | LICENCE.txt                      |
| res://assets/fonts/fira_sans/LICENSE.md | licenses/fira-sans-SIL.md        |
| res://assets/backgrounds/city.png       | goodies/wallpapers/city.png      |
| res://addons/dialogue_manager/LICENSE   | licenses/dialogue-manager-MIT.md |

After exporting your project your target folder (or ZIP file) will have the following structure:

```
.
├── goodies/
│   └── wallpapers/
│       └── city.png
├── licenses/
│   ├── dialogue-manager-MIT.md
│   └── fira-sans-SIL.md
├── LICENSE.txt
├── README.txt
├── your_game.exe
└── your_game.pck
```

(On MacOS, the data will be placed alongside the `*.app`)

## Troubleshooting

If you are experiencing problems, don't hesitate to open an issue here in the repository. This is an initial release and bugs are to be expected.

## Thanks

Thanks to Janis Dimants for icons and testing on Windows!
