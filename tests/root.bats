#!/usr/bin/env bats
#
# $ bats tests/root.bats

load test_helper

_PL1=35000000
_PL2=60000000
_PL4=175000000

setup() {
  if ! tr_can_unshare_user; then
    skip "unprivileged user namespaces (unshare --user) are not available"
  fi

  tr_setup_fixture
  tr_add_rapl "intel-rapl:0" 1 "${_PL1}" "${_PL2}" "${_PL4}"
  tr_add_rapl "intel-rapl-mmio:0" 1 "${_PL1}" "${_PL2}" "${_PL4}"
}

@test "-S <pl1:pl2> writes PL1 and PL2 to both rapl domains" {
  tr_run root -S 40:70
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq 40000000 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 70000000 ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 0)" -eq 40000000 ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 1)" -eq 70000000 ]
}

@test "--set <pl1:pl2> writes PL1 and PL2" {
  tr_run root --set 40:70
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq 40000000 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 70000000 ]
}

@test "-S prints the new values after writing" {
  tr_run root -S 40:70
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"PL1 (sustained)   -> 40W [40000000]"* ]]
  [[ "${output}" == *"PL2 (turbo)       -> 70W [70000000]"* ]]
}

@test "-S --pl1 only writes PL1" {
  tr_run root -S --pl1 30
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq 30000000 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq "${_PL2}" ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 0)" -eq 30000000 ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 1)" -eq "${_PL2}" ]
}

@test "-S --pl2 only writes PL2" {
  tr_run root -S --pl2 80
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq "${_PL1}" ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 80000000 ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 0)" -eq "${_PL1}" ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 1)" -eq 80000000 ]
}

@test "-S --pl1 --pl2 writes PL1 and PL2" {
  tr_run root -S --pl1 20 --pl2 50
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq 20000000 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 50000000 ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 0)" -eq 20000000 ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 1)" -eq 50000000 ]
}

@test "-S works with bundled short options" {
  tr_run root -dS 40:70
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq 40000000 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 70000000 ]
}

@test "-S strips leading zeros instead of reading octal" {
  tr_run root -S 010:090
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq 10000000 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 90000000 ]
}

@test "-S never modifies PL4" {
  tr_run root -S 40:175
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 2)" -eq "${_PL4}" ]
  [ "$(tr_power_limit "intel-rapl-mmio:0" 2)" -eq "${_PL4}" ]
}

@test "-S without an mmio domain only writes intel-rapl" {
  tr_remove_rapl "intel-rapl-mmio:0"

  tr_run root -S 40:70
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq 40000000 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 70000000 ]
  [ ! -e "$(tr_rapl_dir "intel-rapl-mmio:0")" ]
}

@test "-S accepts the 200W fallback cap when PL4 is not available" {
  tr_add_rapl "intel-rapl:0" 1 "${_PL1}" "${_PL2}"
  tr_remove_rapl "intel-rapl-mmio:0"

  tr_run root -S --pl2 200
  [ "${status}" -eq 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq 200000000 ]
}

@test "-S fails when a rapl write fails" {
  rm -f "$(tr_rapl_dir "intel-rapl-mmio:0")/constraint_0_power_limit_uw"

  # This will fail since its a directory not a file :)
  mkdir "$(tr_rapl_dir "intel-rapl-mmio:0")/constraint_0_power_limit_uw"

  tr_run root -S --pl1 40
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"Unable to write rapl value 40000000 (40W)"* ]]
  [[ "${output}" == *"Failed to set PL1 value 40 [40000000]"* ]]
}

@test "-S rejects invalid values before writing" {
  tr_run root -S 60:35
  [ "${status}" -ne 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 0)" -eq "${_PL1}" ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq "${_PL2}" ]

  tr_run root -S --pl2 176
  [ "${status}" -ne 0 ]
  [ "$(tr_power_limit "intel-rapl:0" 1)" -eq "${_PL2}" ]
}
