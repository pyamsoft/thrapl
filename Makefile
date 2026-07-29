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

include config.mk

# Directory for script resources
RES_DIR=res

# certain system files will only properly work situated at /usr
SYSTEM_PREFIX=/usr

SCRIPT_INSTALL_SRC="thrapl"
DOC_INSTALL_SRC="README.md"
LICENSE_INSTALL_SRC="LICENSE"
BASH_INSTALL_SRC="$(RES_DIR)/shell/bash/bash_completion"
SYSTEMD_SERVICE_INSTALL_SRC="$(RES_DIR)/systemd/thrapl@.service"
SYSTEMD_SERVICE_SLEEP_INSTALL_SRC="$(RES_DIR)/systemd/thrapl-sleep@.service"

SCRIPT_INSTALL_TARGET="$(DESTDIR)/$(PREFIX)/bin/$(NAME)"
DOC_INSTALL_TARGET="$(DESTDIR)/$(PREFIX)/share/doc/$(NAME)/README.md"
LICENSE_INSTALL_TARGET="$(DESTDIR)/$(PREFIX)/share/doc/$(NAME)/LICENSE"
BASH_INSTALL_TARGET="$(DESTDIR)/$(SYSTEM_PREFIX)/share/bash-completion/completions/$(NAME)"
SYSTEMD_SERVICE_INSTALL_TARGET="$(DESTDIR)/$(SYSTEM_PREFIX)/lib/systemd/system/$(NAME)@.service"
SYSTEMD_SERVICE_SLEEP_INSTALL_TARGET="$(DESTDIR)/$(SYSTEM_PREFIX)/lib/systemd/system/$(NAME)-sleep@.service"

.PHONY: all install uninstall edit \
	install-doc install-license install-script install-res \
	install-bash \
	install-systemd install-systemd-thrapl install-systemd-thrapl-sleep \
	uninstall-script uninstall-doc uninstall-license uninstall-res \
	uninstall-bash \
	uninstall-systemd uninstall-systemd-thrapl uninstall-systemd-thrapl-sleep

all:
	@echo "Targets"
	@echo " install uninstall edit"
	@echo $(TARGET)

edit:
ifndef EDITOR
	@echo "No \$$EDITOR defined. Editing config.mk using vi"
	@vi -- config.mk
else
	@echo "Editing config.mk using \$$EDITOR ($(EDITOR))"
	@$(EDITOR) -- config.mk
endif

install:
	@echo "Installing..."
	@$(MAKE) install-script
	@$(MAKE) install-res
ifeq ($(INCLUDE_DOC), 1)
	@$(MAKE) install-doc
endif

ifeq ($(INCLUDE_LICENSE), 1)
	@$(MAKE) install-license
endif

install-script:
	@echo "  INSTALL  $(SCRIPT_INSTALL_TARGET)"
	@mkdir -p "$(shell dirname $(SCRIPT_INSTALL_TARGET))"
	@install -Dm 755 "$(SCRIPT_INSTALL_SRC)" "$(SCRIPT_INSTALL_TARGET)"

install-doc:
	@echo "  INSTALL  $(DOC_INSTALL_TARGET)"
	@mkdir -p "$(shell dirname $(DOC_INSTALL_TARGET))"
	@install -Dm 644 "$(DOC_INSTALL_SRC)" "$(DOC_INSTALL_TARGET)"

install-license:
	@echo "  INSTALL  $(LICENSE_INSTALL_TARGET)"
	@mkdir -p "$(shell dirname $(LICENSE_INSTALL_TARGET))"
	@install -Dm 644 "$(LICENSE_INSTALL_SRC)" "$(LICENSE_INSTALL_TARGET)"

install-res:
ifeq ($(INCLUDE_BASH_COMPLETION), 1)
	@$(MAKE) install-bash
endif
ifeq ($(INCLUDE_SYSTEMD_UNIT), 1)
	@$(MAKE) install-systemd
endif

install-bash:
	@echo "  INSTALL  $(BASH_INSTALL_TARGET)"
	@mkdir -p "$(shell dirname $(BASH_INSTALL_TARGET))"
	@install -Dm 644 "$(BASH_INSTALL_SRC)" "$(BASH_INSTALL_TARGET)"

install-systemd:
	@$(MAKE) install-systemd-thrapl
	@$(MAKE) install-systemd-thrapl-sleep

install-systemd-thrapl:
	@echo "  INSTALL  $(SYSTEMD_SERVICE_INSTALL_TARGET)"
	@mkdir -p "$(shell dirname $(SYSTEMD_SERVICE_INSTALL_TARGET))"
	@install -Dm 644 "$(SYSTEMD_SERVICE_INSTALL_SRC)" "$(SYSTEMD_SERVICE_INSTALL_TARGET)"
	@sed -i "s|%PREFIX%|$(PREFIX)|" "$(SYSTEMD_SERVICE_INSTALL_TARGET)"

install-systemd-thrapl-sleep:
	@echo "  INSTALL  $(SYSTEMD_SERVICE_SLEEP_INSTALL_TARGET)"
	@mkdir -p "$(shell dirname $(SYSTEMD_SERVICE_SLEEP_INSTALL_TARGET))"
	@install -Dm 644 "$(SYSTEMD_SERVICE_SLEEP_INSTALL_SRC)" "$(SYSTEMD_SERVICE_SLEEP_INSTALL_TARGET)"
	@sed -i "s|%PREFIX%|$(PREFIX)|" "$(SYSTEMD_SERVICE_SLEEP_INSTALL_TARGET)"

uninstall:
	@echo "Uninstalling..."
	@$(MAKE) uninstall-script
	@$(MAKE) uninstall-res
ifeq ($(INCLUDE_DOC), 1)
	@$(MAKE) uninstall-doc
endif
ifeq ($(INCLUDE_LICENSE), 1)
	@$(MAKE) uninstall-license
endif

uninstall-script:
	@echo "  UNINSTALL  $(SCRIPT_INSTALL_TARGET)"
	@rm -f "$(SCRIPT_INSTALL_TARGET)"

uninstall-doc:
	@echo "  UNINSTALL  $(DOC_INSTALL_TARGET)"
	@rm -f "$(DOC_INSTALL_TARGET)"
	@rmdir --ignore-fail-on-non-empty "$(shell dirname $(DOC_INSTALL_TARGET))"

uninstall-license:
	@echo "  UNINSTALL  $(LICENSE_INSTALL_TARGET)"
	@rm -f "$(LICENSE_INSTALL_TARGET)"
	@rmdir --ignore-fail-on-non-empty "$(shell dirname $(LICENSE_INSTALL_TARGET))"

uninstall-res:
ifeq ($(INCLUDE_BASH_COMPLETION), 1)
	@$(MAKE) uninstall-bash
endif
ifeq ($(INCLUDE_SYSTEMD_UNIT), 1)
	@$(MAKE) uninstall-systemd
endif

uninstall-bash:
	@echo "  UNINSTALL  $(BASH_INSTALL_TARGET)"
	@rm -f "$(BASH_INSTALL_TARGET)"

uninstall-systemd:
	@$(MAKE) uninstall-systemd-thrapl
	@$(MAKE) uninstall-systemd-thrapl-sleep

uninstall-systemd-thrapl:
	@echo "  UNINSTALL  $(SYSTEMD_SERVICE_INSTALL_TARGET)"
	@rm -f "$(SYSTEMD_SERVICE_INSTALL_TARGET)"

uninstall-systemd-thrapl-sleep:
	@echo "  UNINSTALL  $(SYSTEMD_SERVICE_SLEEP_INSTALL_TARGET)"
	@rm -f "$(SYSTEMD_SERVICE_SLEEP_INSTALL_TARGET)"
