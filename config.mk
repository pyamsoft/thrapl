# The GPLv2 License
#
#   Copyright (C) 2026 pyamsoft
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Foundation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

##
# Name of the script
#
# You can change this, but note that it may have unforseen consequences
#
# For example, this does not currently change the content inside of
# any res/ files. Use at your own risk.
##
NAME=thrapl

##
# Install prefix
#
# Understand that this prefix will only affect the destination of the
# installed thrapl binary and the installed documentation
#
# The bash-completion and systemd unit files
# expect to be installed into the /usr directory, and may not work if they
# are installed anywhere other than the /usr directory.
#
# [/usr/local] | /usr | other
##
PREFIX?=/usr/local

##
# bash-completion
#
# Include a bash completion file
#
# 0 NO | [1 YES]
##
INCLUDE_BASH_COMPLETION?=1

##
# systemd services
#
# Include a systemd unit
#
# 0 NO | [1 YES]
##
INCLUDE_SYSTEMD_UNIT?=1

##
# Install README.md
#
# Installs a copy of the README.md file to
# $(PREFIX)/share/doc/thrapl/README.md
#
# 0 NO | [1 YES]
##
INCLUDE_DOC?=1

##
# Install copy of the MIT License
#
# Installs a copy of the MIT License
# $(PREFIX)/share/doc/thrapl/project
#
# 0 NO | [1 YES]
##
INCLUDE_LICENSE?=1

##
# Make Flags
#
# Do NOT modify these unless you know what you are doing
##
MAKEFLAGS:= $(MAKEFLAGS) --no-print-directory
