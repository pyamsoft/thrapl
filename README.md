# thrapl

Easily adjust PL1 (Sustained) and PL2 (Turbo) wattage using the intel_rapl driver

### Requirements

- The intel_rapl driver and a system which makes use of it
  (as far as I know, Intel x86 CPUs only)

- coreutils  
  The standard GNU tools for things like cat, tr, grep, and awk. These are
  generally expected on all modern Linux based systems. If you are in a
  situation where your machine does not have these basic tools, support cannot
  be offered at this time.

- Reading Comprehension and Understanding  
  You are also expected to read and understand the settings in the configuration
  file: config.mk.

### Installation

The installation follows a basic process:

```
$ make edit
# make install
```

While building, there are a couple of options that one may configure or
change:

- The directory to install to (defaults to /usr/local)
- Install bash completion (defaults to Yes)
- Install systemd related unit files (defaults to Yes)
- Install this README as documentation (defaults to Yes)

#### Distribution Specific Installations

At this time, only ArchLinux is officially supported via the Arch User
Repository (AUR).

thrapl comes with a PKGBUILD provided in the assets directory.  
The _stable/PKGBUILD_ will pull the latest released version from GitHub
and compile it for ArchLinux.  
The _git/PKGBUILD_ will pull the latest version from the dev repository on
GitHub and compile it for ArchLinux.

Debian package management and RedHat package management based distributions
are currently unofficially supported through the **checkinstall** program
and this is the recommended way to install the package until an actual
package can be constructed. Please see the `docheckinstall` script in
`assets/checkinstall`

Any other package management based distributions can look to using
**checkinstall** but are otherwise entirely unsupported by the developer at
this time.

### Versioning

The versioning is rather arbitrary. The scheme is as follows:  
 X.Y.Z

X is the major version number, it will only be updated when the program is
significantly updated. Y is the minor version number, it will be updated when
features are added to existing versions. Z is the bugfix version number, it
will be updated generally whenever a bug is fixed or patched.

### Usage

The script by default is named **thrapl**  
When called without any options, the program will display something like
the following:  

#TODO(Peter): Screenshot

When called with the _-G --get_ option, the program will display something
like the following:  
#TODO(Peter): Screenshot

When called with the _-S --set_ option, the program will display something
like the following:  
#TODO(Peter): Screenshot

The _-G --get_ option can be called by a normal user.

The _-S --set_ option can only be called by a user with root permissions, and
takes either a `<pl1>:<pl2>` pair, or one or both of `--pl1 <value>` and
`--pl2 <value>`.

The _-S --set_ option operates on the concept of watts being the base unit,
while the sysfs device class layer uses microwatts. The thrapl tool will
automatically convert your watt value to microwatts.

This means that you would call something like:
```
# thrapl -S 35:60
# thrapl -S --pl1 35
# thrapl -S --pl2 60
# thrapl -S --pl1 35 --pl2 60
```
To set your PL1 wattage value to 35 watts and PL2 wattage value to 60 watts
(35_000_000 and 60_000_000 in sysfs)

Values are written to both the `intel-rapl` and, if present, the
`intel-rapl-mmio` domain, since the hardware enforces the lower of the two.

PL4 (peak power) is displayed by _-G --get_ but can not be modified.

_By default, calling the -S option with no extra arguments will return an
error_

The _--delay_ option delays the execution of the set commands by 5 seconds.
This works around a boot issue where values are set too early and can be
overwritten by another system component.

### systemd

The systemd units are templates which take the `<pl1>:<pl2>` value as their
instance name. For example, to set PL1 to 35 watts and PL2 to 60 watts at
boot and again on resume from sleep:
```
# systemctl enable thrapl@35:60.service thrapl-sleep@35:60.service
```

## Development

thrapl is developed in the open on Github at:

```
https://github.com/pyamsoft/thrapl
```

## Issues

Check the issues page on GitHub for any notes about outstanding or existing
issues. If you encounter a problem with thrapl of which no such
issue already exists please feel free to help the developer by creating an
issue ticket.

## License

GPLv2

```
  The GPLv2 License

    Copyright (C) 2026 pyamsoft

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
```
