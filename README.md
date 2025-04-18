# paxchange
[![Continuous Integration and Deployment](https://github.com/Skycoder42/paxchange/actions/workflows/ci.yml/badge.svg)](https://github.com/Skycoder42/paxchange/actions/workflows/ci.yml)
[![AUR Version](https://img.shields.io/aur/version/paxchange)](https://aur.archlinux.org/packages/paxchange)


Simple dart script to passively synchronize installed pacman packages between systems.

## Installation
- Archlinux / Manjaro: https://aur.archlinux.org/packages/paxchange

## Usage
```
Simple dart script to passively synchronize installed pacman packages between systems.

Usage: paxchange <command> [arguments]

Global options:
-h, --help             Print this usage information.
-c, --config=<path>    Path to the configuration file to be used.
                       (defaults to "/etc/paxchange.json")

Available commands:
  install   Triggers installation of all packages for this machine.
  review    Review the package diff for the given machine.
  update    Update the package diff with the current system package configuration.
```

### Install
```
Triggers installation of all packages for this machine.

This will start the install command with all packages listed in the package file
of this machine, by only packages that are not already installed will be
installed. If you need fine control over which packages to install, run the
review command instead.

Usage: paxchange install [arguments]
-h, --help                   Print this usage information.
-n, --machine-name=<name>    Specify a custom machine name to install packages for. By default, this machine is used.
    --[no-]confirm           When disabled, the pacman installation will run without confirmation. Use carefully!
                             (defaults to on)
```

### Review
```
Review the package diff for the given machine.

Usage: paxchange review [arguments]
-h, --help                     Print this usage information.
-n, --machine-name=<name>      Specify a custom machine name to review the diff for. By default, this machine is used.
    --[no-]include-optional    When enabled, the cleanup will include packages that are referenced as optional dependency.
```

### Update
```
Update the package diff with the current system package configuration.

Usage: paxchange update [arguments]
-h, --help                        Print this usage information.
-e, --[no-]set-exit-on-changed    Causes the tool to exit with code 2 if packages have changed.
```
