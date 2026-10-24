#!/bin/sh

THRAPL_BIN="${BATS_TEST_DIRNAME}/../thrapl"

##
# Check that we can unshare, by actually attempting to unshare lol
tr_can_unshare_user() {
  unshare --user --map-root-user --mount -- \
    unshare --user --map-user="$(id -u)" --map-group="$(id -g)" -- true >/dev/null 2>&1
}

##
# Path to test fixture directory
tr_fixture_root() {
  printf -- '%s/fixture' "${BATS_TEST_TMPDIR}"
}

##
# Path to a fake rapl domain
# $1 domain name
tr_rapl_dir() {
  printf -- '%s/sys/class/powercap/%s' "$(tr_fixture_root)" "$1"
}

##
# Global setup of fixture system
tr_setup_fixture() {
  mkdir -p "$(tr_fixture_root)/sys/class/powercap"
}

##
# Add a fake rapl domain
# $1 domain name
# $2 enabled
# $3 PL1 microwatts
# $4 PL2 microwatts
# $5 PL4 microwatts, the file is not created if empty
tr_add_rapl() {
  tr_add_rapl__dir="$(tr_rapl_dir "$1")"

  # Replace any existing domain so files from a previous setup do not linger
  rm -rf "${tr_add_rapl__dir}"
  mkdir -p "${tr_add_rapl__dir}"
  printf -- '%s\n' "$2" >"${tr_add_rapl__dir}/enabled"
  printf -- 'long_term\n' >"${tr_add_rapl__dir}/constraint_0_name"
  printf -- '%s\n' "$3" >"${tr_add_rapl__dir}/constraint_0_power_limit_uw"
  printf -- 'short_term\n' >"${tr_add_rapl__dir}/constraint_1_name"
  printf -- '%s\n' "$4" >"${tr_add_rapl__dir}/constraint_1_power_limit_uw"

  if [ -n "$5" ]; then
    printf -- 'peak_power\n' >"${tr_add_rapl__dir}/constraint_2_name"
    printf -- '%s\n' "$5" >"${tr_add_rapl__dir}/constraint_2_power_limit_uw"
  fi

  unset tr_add_rapl__dir
}

##
# Remove a fake rapl domain
# $1 domain name
tr_remove_rapl() {
  rm -rf "$(tr_rapl_dir "$1")"
}

##
# Read a fake rapl constraint power limit
# $1 domain name
# $2 constraint number
tr_power_limit() {
  cat "$(tr_rapl_dir "$1")/constraint_$2_power_limit_uw"
}

# Runs inside a private mount namespace with fixtures set up
tr_run() {
  tr_run__mode="$1"
  shift

  # We always enter a user namespace as a fake root to set up the mounts.
  # The "non root" mode then nests another user namespace to drop back to our own user.
  tr_run__drop=""
  if [ "${tr_run__mode}" != "root" ]; then
    tr_run__drop="unshare --user --map-user=$(id -u) --map-group=$(id -g) --"
  fi

  ##
  # Syntax here is sh -c "blahblah" (arg$0), ($arg1) ...
  # in this case, arg$0 is ignored since we don't use $0 in our embedded script
  #
  # shellcheck disable=SC2016
  run unshare --user --map-root-user --mount -- sh -c '
    fixture="$1"
    thrapl_bin="$2"
    drop="$3"

    shift
    shift
    shift

    mount --bind "${fixture}/sys/class/powercap" /sys/class/powercap || exit 99

    exec ${drop} "${thrapl_bin}" "$@"
  ' __test_shell__ "$(tr_fixture_root)" "${THRAPL_BIN}" "${tr_run__drop}" "$@"

  unset tr_run__mode
  unset tr_run__drop
}
