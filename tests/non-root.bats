#!/usr/bin/env bats
#
# $ bats tests/non-root.bats

load test_helper

_PL1=35000000
_PL2=60000000
_PL4=175000000

setup() {
  if ! tr_can_unshare_user; then
    skip "unprivileged user namespaces (unshare --user) are not available"
  fi

  if [ "$(id -u)" -eq 0 ]; then
    skip "run this suite as non-root (use bin/test)"
  fi

  tr_setup_fixture
  tr_add_rapl "intel-rapl:0" 1 "${_PL1}" "${_PL2}" "${_PL4}"
  tr_add_rapl "intel-rapl-mmio:0" 1 "${_PL1}" "${_PL2}" "${_PL4}"
}

##
# Every -S failure in this suite must leave the fixture untouched
_assert_unchanged() {
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq "${_PL1}" ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq "${_PL2}" ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 0)" -eq "${_PL1}" ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 1)" -eq "${_PL2}" ]
}

@test "-V prints the version and exits 0" {
  tr_run nonroot -V
  [ "${status}" -eq 0 ]
  [[ "${output}" == "thrapl <"* ]]
}

@test "-H prints usage and exits 0" {
  tr_run nonroot -H
  [ "${status}" -eq 0 ]
  [[ "${output}" == "thrapl <"* ]]
  [[ "${output}" == *"[general]"* ]]
}

@test "no arguments prints usage and exits 0" {
  tr_run nonroot
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"[general]"* ]]
}

@test "unknown command prints usage and exits 0" {
  tr_run nonroot bogus
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"[general]"* ]]
}

@test "missing intel-rapl domain exits 2" {
  tr_remove_rapl "intel-rapl:0"

  tr_run nonroot -G
  [ "${status}" -eq 2 ]
  [[ "${output}" == *"thrapl is not supported on your system."* ]]
}

@test "disabled intel-rapl domain exits 2" {
  tr_add_rapl "intel-rapl:0" 0 "${_PL1}" "${_PL2}" "${_PL4}"

  tr_run nonroot -G
  [ "${status}" -eq 2 ]
  [[ "${output}" == *"do not have intel_rapl enabled"* ]]
}

@test "-G reports PL1, PL2, and PL4 for both rapl domains" {
  tr_run nonroot -G
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"[intel-rapl:0]"* ]]
  [[ "${output}" == *"[intel-rapl-mmio:0]"* ]]
  [[ "${output}" == *"PL1 (sustained)   -> 35W [35000000]"* ]]
  [[ "${output}" == *"PL2 (turbo)       -> 60W [60000000]"* ]]
  [[ "${output}" == *"PL4 (system max)  -> 175W [175000000]"* ]]
}

@test "-G skips a missing mmio domain" {
  tr_remove_rapl "intel-rapl-mmio:0"

  tr_run nonroot -G
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"[intel-rapl:0]"* ]]
  [[ "${output}" != *"[intel-rapl-mmio:0]"* ]]
}

@test "-G reports N/A for a missing PL4" {
  tr_add_rapl "intel-rapl:0" 1 "${_PL1}" "${_PL2}"

  tr_run nonroot -G
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"PL4 (system max)  -> N/A"* ]]
}

@test "-G and -S can not be combined" {
  tr_run nonroot -G -S 35:60
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"Cannot use --set mode when already in --get mode"* ]]

  tr_run nonroot -S 35:60 -G
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"Cannot use --get mode when already in --set mode"* ]]
}

@test "-S with valid values is blocked by the root check" {
  for args in "-S 40:70" "--set 40:70" "-S --pl1 40" "-S --pl2 70" "-S --pl1 40 --pl2 70" "-dS 40:70"; do
    # shellcheck disable=SC2086
    tr_run nonroot ${args}
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"You must be root."* ]]
  done

  _assert_unchanged
}

@test "-S without a value is rejected" {
  tr_run nonroot -S
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"--set requires <pl1:pl2>, --pl1 <value>, or --pl2 <value>"* ]]
  [[ "${output}" != *"You must be root."* ]]
}

@test "-S rejects a malformed <pl1:pl2>" {
  for value in 35 :60 35:; do
    tr_run nonroot -S "${value}"
    [ "${status}" -ne 0 ]
    [[ "${output}" == *"Set value must be <pl1:pl2>, got: ${value}"* ]]
    [[ "${output}" != *"You must be root."* ]]
  done

  tr_run nonroot -S 35:60:70
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"You must provide a PL2 numeric value in whole watts: (60:70)"* ]]
  [[ "${output}" != *"You must be root."* ]]

  tr_run nonroot -S abc:60
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"You must provide a PL1 numeric value in whole watts: (abc)"* ]]
  [[ "${output}" != *"You must be root."* ]]

  _assert_unchanged
}

@test "-S rejects <pl1:pl2> combined with --pl1 or --pl2" {
  tr_run nonroot -S 35:60 --pl1 30
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"Cannot combine <pl1:pl2> with --pl1 or --pl2"* ]]
  [[ "${output}" != *"You must be root."* ]]
}

@test "--pl1 and --pl2 require a value" {
  tr_run nonroot -S --pl1
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"--pl1 requires a value in whole watts"* ]]

  tr_run nonroot -S --pl1 --pl2 50
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"--pl1 requires a value in whole watts"* ]]

  tr_run nonroot -S --pl2 abc
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"You must provide a PL2 numeric value in whole watts: (abc)"* ]]
  [[ "${output}" != *"You must be root."* ]]
}

@test "--pl1 and --pl2 are rejected outside of --set mode" {
  tr_run nonroot --pl1 30
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"Cannot use --pl1 outside of --set mode"* ]]

  tr_run nonroot -G --pl2 30
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"Cannot use --pl2 outside of --set mode"* ]]
}

@test "-S rejects PL1 greater than PL2" {
  tr_run nonroot -S 60:35
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"PL1 (60W) can not be greater than PL2 (35W)"* ]]
  [[ "${output}" != *"You must be root."* ]]
}

@test "-S rejects a single PL that crosses the current other PL" {
  tr_run nonroot -S --pl2 20
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"PL1 (35W) can not be greater than PL2 (20W)"* ]]

  tr_run nonroot -S --pl1 70
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"PL1 (70W) can not be greater than PL2 (60W)"* ]]
}

@test "-S caps values at PL4" {
  tr_run nonroot -S --pl2 176
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"PL2 value out of range: (176) must be 175W or less"* ]]

  tr_run nonroot -S --pl2 175
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"You must be root."* ]]
}

@test "-S caps values at the lowest PL4 across rapl domains" {
  tr_add_rapl "intel-rapl-mmio:0" 1 "${_PL1}" "${_PL2}" 150000000

  tr_run nonroot -S --pl2 151
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"PL2 value out of range: (151) must be 150W or less"* ]]
}

@test "-S caps values at 200W when PL4 is not available" {
  tr_add_rapl "intel-rapl:0" 1 "${_PL1}" "${_PL2}"
  tr_add_rapl "intel-rapl-mmio:0" 1 "${_PL1}" "${_PL2}" 0

  tr_run nonroot -S --pl2 201
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"PL2 value out of range: (201) must be 200W or less"* ]]

  tr_run nonroot -S --pl2 200
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"You must be root."* ]]
}

@test "-S rejects a value too large for shell arithmetic" {
  tr_run nonroot -S --pl1 99999999999999999999
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"PL1 value out of range"* ]]
  [[ "${output}" != *"You must be root."* ]]
}
