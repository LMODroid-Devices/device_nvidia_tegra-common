# Copyright (C) 2021 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ "$EUID" -ne 0 ]; then
  echo "Flash scripts must be run as root";
  exit -1;
fi;

# Start up error checking
CommandCheck () {
  CMD="$1";
  MORE="$2";
  command -v ${CMD} >/dev/null 2>&1 || { echo >&2 "${CMD} is required, but not installed."; [ ! -z "${MORE}" ] && echo >&2 "${MORE}"; echo >&2 "Aborting."; return -1; }

  return 0;
}

for COMMAND_CHECK in 'xxd' 'fdtput'; do
  if ! CommandCheck ${COMMAND_CHECK}; then
    return -1;
  fi;
done;

declare -A APXPRODUCT;
APXPRODUCT[t210]="7721";
APXPRODUCT[t210nano]="7f21";
APXPRODUCT[t186]="7c18";
APXPRODUCT[t194]="7019";
APXPRODUCT[t194nx]="7e19";
APXPRODUCT[t234]="7023;7223;7323;7423;7523;7623";

declare AVAILABLE_INTERFACES=();
declare INTERFACE;

declare -A MODULEINFO;
declare -A CARRIERINFO;

# Get list of devices in apx mode for the given tegra version
function get_interfaces()
{
  IFS=";" read -r -a pids <<< "${APXPRODUCT[${TARGET_TEGRA_VERSION}]}";

  shopt -s globstar
  for devnumpath in /sys/bus/usb/devices/usb*/**/devnum; do
    if [ "$(cat $(dirname ${devnumpath})/idVendor)"  == "0955" ]; then
      for pid in "${pids[@]}"; do
        if [ "$(cat $(dirname ${devnumpath})/idProduct)" == "${pid}" ]; then
          keyfound=0;
          for key in "${AVAILABLE_INTERFACES[@]}"; do
            if [ "$(cat $(dirname ${devnumpath})/busnum)-$(cat $(dirname ${devnumpath})/devpath)" == "${key}" ]; then
              keyfound=1;
              break;
            fi;
          done;
          if [ $keyfound -eq 0 ]; then
            AVAILABLE_INTERFACES+=("$(cat $(dirname ${devnumpath})/busnum)-$(cat $(dirname ${devnumpath})/devpath)");
          fi;
          break;
        fi;
      done;
    fi;
  done;

  if [ ${#AVAILABLE_INTERFACES[@]} -eq 0 ]; then
    echo "No ${TARGET_TEGRA_VERSION} devices in RCM mode found";
    return -1;
  fi;

  return 0;
}

# Get board info from the module eeprom
function get_eeprominfo()
{
  local EEPROMCMD="dump eeprom boardinfo eeprom_boardinfo.bin";
  if [ "${TARGET_TEGRA_VERSION}" == "t234" ]; then
    EEPROMCMD="dump eeprom cvm eeprom_boardinfo.bin";
  fi;
  if [ "${1}" == "true" ]; then
    EEPROMCMD+="; dump eeprom baseinfo eeprom_baseinfo.bin";
  fi;
  if [ "${TARGET_TEGRA_VERSION}" == "t194" -o "${TARGET_TEGRA_VERSION}" == "t194nx" -o "${TARGET_TEGRA_VERSION}" == "t234" ]; then
    EEPROMCMD+="; reboot recovery";
  fi;

  tegraflash.py \
    "${FLASH_CMD_EEPROM[@]}" \
    --instance ${INTERFACE} \
    --cmd "${EEPROMCMD}" \
    > /dev/null;

  if [ ! -f eeprom_boardinfo.bin ]; then
    MODULEINFO[boardid]="";
    return;
  fi;

  MODULEINFO[eepromver]=$(dd if=eeprom_boardinfo.bin bs=1 count=1 status=none |xxd -p);
  MODULEINFO[assetnum]=$(dd if=eeprom_boardinfo.bin bs=1 skip=74 count=15 status=none |tr -dc '[[:print:]]');
  MODULEINFO[partnum]=$(dd if=eeprom_boardinfo.bin bs=1 skip=20 count=30 status=none |tr -dc '[[:print:]]');
  if [ ${MODULEINFO[eepromver]} -eq 2 ]; then
    MODULEINFO[boardid]=$(dd if=eeprom_boardinfo.bin bs=1 skip=25 count=4 status=none);
    MODULEINFO[sku]=$(dd if=eeprom_boardinfo.bin bs=1 skip=30 count=4 status=none);
    MODULEINFO[fab]=$(dd if=eeprom_boardinfo.bin bs=1 skip=35 count=3 status=none);
    MODULEINFO[revmaj]=$(dd if=eeprom_boardinfo.bin bs=1 skip=39 count=1 status=none);
    MODULEINFO[revmin]=$(dd if=eeprom_boardinfo.bin bs=1 skip=41 count=1 status=none);
  else
    MODULEINFO[boardid]=$((16#$(dd if=eeprom_boardinfo.bin bs=1 skip=4 count=2 status=none |xxd -p |tac -rs .. |tr -d '\n')));
    MODULEINFO[sku]=$((16#$(dd if=eeprom_boardinfo.bin bs=1 skip=6 count=2 status=none |xxd -p |tac -rs .. |tr -d '\n')));
    MODULEINFO[fab]=$((16#$(dd if=eeprom_boardinfo.bin bs=1 skip=8 count=1 status=none |xxd -p)));
    MODULEINFO[revmaj]=$((16#$(dd if=eeprom_boardinfo.bin bs=1 skip=9 count=1 status=none |xxd -p)));
    MODULEINFO[revmin]=$((16#$(dd if=eeprom_boardinfo.bin bs=1 skip=10 count=1 status=none |xxd -p)));
  fi;
  MODULEINFO[version]=$(dd if=eeprom_boardinfo.bin bs=1 skip=35 count=3 status=none);
  if [ "${TARGET_TEGRA_VERSION}" = "t234" ]; then
    MODULEINFO[chipskurev]=$((16#$(dd if=chip_info.bin_bak bs=1 skip=0 count=1 status=none |xxd -p)));
    rm chip_info.bin_bak;
  fi;

  rm eeprom_boardinfo.bin;

  if [ "${1}" == "true" ]; then
    if [ ! -f eeprom_baseinfo.bin ]; then
      CARRIERINFO[boardid]="";
      return;
    fi;

    CARRIERINFO[assetnum]=$(dd if=eeprom_baseinfo.bin bs=1 skip=74 count=15 status=none |tr -dc '[[:print:]]');
    CARRIERINFO[boardid]=$((16#$(dd if=eeprom_baseinfo.bin bs=1 skip=4 count=2 status=none |xxd -p |tac -rs .. |tr -d '\n')));
    CARRIERINFO[sku]=$((16#$(dd if=eeprom_baseinfo.bin bs=1 skip=6 count=2 status=none |xxd -p |tac -rs .. |tr -d '\n')));
    CARRIERINFO[fab]=$((16#$(dd if=eeprom_baseinfo.bin bs=1 skip=8 count=1 status=none |xxd -p)));
    CARRIERINFO[revmaj]=$((16#$(dd if=eeprom_baseinfo.bin bs=1 skip=9 count=1 status=none |xxd -p)));
    CARRIERINFO[revmin]=$((16#$(dd if=eeprom_baseinfo.bin bs=1 skip=10 count=1 status=none |xxd -p)));
    CARRIERINFO[version]=$(dd if=eeprom_baseinfo.bin bs=1 skip=35 count=3 status=none);

    rm eeprom_baseinfo.bin;
  fi;
}

# Find device matching given module and carrier board ids.
function check_compatibility()
{
  local MODULEID=${1};
  local CARRIERID=${2};
  local TEMPVERSION=;

  # t210 rcm applet cannot fetch carrier board eeprom, attempts to do so return the modulue eeprom silently
  # t194 nx cannot fetch carrier board eeprom due to bug that will not be fixed per
  #  https://forums.developer.nvidia.com/t/xavier-nx-apx-carrier-board-eeprom-read/191908/3
  # t234 does not support reading cvb at all
  # This means only t186 and t194-agx support reading cvb, so whitelist on those
  local CHECKBASEINFO="false";
  if [ ! -z "${CARRIERID}" ] && [ "${TARGET_TEGRA_VERSION}" = "t186" -o "${TARGET_TEGRA_VERSION}" = "t194" ]; then
    CHECKBASEINFO="true";
  fi;

  echo "Checking compatibility.";

  declare -A INTERFACES_COPY;
  for key in "${!AVAILABLE_INTERFACES[@]}"; do
    INTERFACES_COPY["$key"]="${AVAILABLE_INTERFACES["$key"]}";
  done;

  for intfnum in "${!INTERFACES_COPY[@]}"; do
    INTERFACE=${INTERFACES_COPY[$intfnum]};
    get_eeprominfo "${CHECKBASEINFO}";
    unset 'INTERFACE'

    if [ "${MODULEINFO[boardid]}" != "${MODULEID}" ]; then
      unset "AVAILABLE_INTERFACES[$intfnum]";
    elif [ "${CHECKBASEINFO}" = "true" -a "${CARRIERINFO[boardid]}" != "${CARRIERID}" ]; then
      unset "AVAILABLE_INTERFACES[$intfnum]";
    fi;
  done;

  if [ ${#AVAILABLE_INTERFACES[@]} -eq 0 ]; then
    echo "No compatible devices found.";
    return -1;
  fi;

  if [ ${#AVAILABLE_INTERFACES[@]} -ge 2 ]; then
    echo "Multiple compatible devices found. Please disconnect all but one and try again.";
    return -1;
  fi;

  INTERFACE="${AVAILABLE_INTERFACES[0]}";
  return 0;
}

# Add tnspec efi var to a dtbo
function generate_tnspec_dtbo()
{
  if [ -z "${1}" ]; then return -1; fi;

  local TNSPEC=$(printf "p%04d-%04d+p%04d-%04d.android\0" ${MODULEINFO[boardid]} ${MODULEINFO[sku]} ${CARRIERINFO[boardid]} ${CARRIERINFO[sku]} |xxd -p |sed 's/../& /g');
  fdtput -p -t bx ${1} /fragment@0/__overlay__/firmware/uefi/variables/gNVIDIAPublicVariableGuid/TegraPlatformSpec data ${TNSPEC};
  fdtput -p ${1} /fragment@0/__overlay__/firmware/uefi/variables/gNVIDIAPublicVariableGuid/TegraPlatformSpec runtime;
  fdtput -p ${1} /fragment@0/__overlay__/firmware/uefi/variables/gNVIDIAPublicVariableGuid/TegraPlatformSpec locked;

  return 0;
}

function generate_version_bootblob_v3()
{
  if [ -z "${1}" -o -z "${2}" ]; then return -1; fi;
  local LINEAGEVER=${2};

  echo "NV4" > ${1};
  echo "# R${LINEAGEVER%.*} , REVISION: ${LINEAGEVER#*.}" >> ${1};
  echo "BOARDID=${MODULEINFO[boardid]} BOARDSKU=$(printf %04d ${MODULEINFO[sku]}) FAB=" >> ${1};
  date '+%Y%m%d%H%M%S' >> ${1};
  local CRC32=$(python -c 'import zlib; print("%X"%(zlib.crc32(open("'"${1}"'", "rb").read()) & 0xFFFFFFFF))');
  local BYTECOUNT=$(wc -c ${1} |awk '{ print $1 }');
  echo "BYTES:${BYTECOUNT} CRC32:${CRC32}" >> ${1};

  return 0;
}

function generate_version_bootblob_v4()
{
  if [ -z "${1}" -o -z "${2}" ]; then return -1; fi;
  local LINEAGEVER=${2};

  echo "NV4" > ${1};
  echo "# R${LINEAGEVER%.*} , REVISION: ${LINEAGEVER#*.}" >> ${1};
  echo "BOARDID=${MODULEINFO[boardid]} BOARDSKU=$(printf %04d ${MODULEINFO[sku]}) FAB=" >> ${1};
  date '+%Y%m%d%H%M%S' >> ${1};
  echo "$(printf "0x%x" $(( ${LINEAGEVER%.*}<<16 | ${LINEAGEVER#*.}<<8 )) )" >> ${1};
  local CRC32=$(python -c 'import zlib; print("%X"%(zlib.crc32(open("'"${1}"'", "rb").read()) & 0xFFFFFFFF))');
  local BYTECOUNT=$(wc -c ${1} |awk '{ print $1 }');
  echo "BYTES:${BYTECOUNT} CRC32:${CRC32}" >> ${1};

  return 0;
}

# Compatibility functions for older flash pacakges
function check_module_compatibility()
{
  export FLASH_CMD_EEPROM=("${FLASH_CMD_BASIC[@]}")
  echo "WARNING: Checking module compatibility individually is deprecated"
  echo "Please convert to unified check_compatibility"
  check_compatibility "${1}" "";
  return $?;
}

function check_carrier_compatibility()
{
  echo "WARNING: Checking carrier compatibility indivually is no longer supported"
  echo "Continuing assuming success"
  return 0;
}
