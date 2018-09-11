#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARBALL=IS_TARBALL
TARBALL_MANIFEST="REPLACE_WITH_MANIFEST"
THREADS=1
NAME="REPLACE_WITH_BIN"
ARGS="REPLACE_WITH_ARGS"
SETUP=0
CLEAN=0

function die {
  echo "ERROR: $1!"
  exit 1
}

function print_help {
  echo "Runs '$NAME $ARGS'"
  echo "Usage: $0 [ -s | -t THREADS [-c] ]"
  echo "Options:"
  echo "  -t THREADS : number of threads with which to run"
  echo "  -c         : if doing a run, clean up unpacked payload"
  echo "  -s         : unpack payload & exit"
}

function arch_suffix {
  local arch=$(uname -m)
  if [[ $arch == "x86_64" ]]; then arch="x86-64"; fi
  echo $arch
}

function setup {
  local me=$1
  local match=$(grep --text --line-number '^BINARY:$' $me | cut -d ':' -f 1)
  local payload_start=$((match + 1))
  local payload="$DIR/$(basename $NAME)"
  if [[ $TARBALL -eq 1 ]]; then
    # Extract tarball
    local tarball=${payload}.tar.bz2
    tail -n +$payload_start $me > $tarball
    if [[ ! -f $tarball ]]; then die "no tarball"; fi
    tar -xf $tarball
    for file in $TARBALL_MANIFEST; do
      if [[ ! -f $file ]]; then die "corrupted tarball, missing $file"; fi
    done

    # Create architecture-specific hardlink
    if [[ -f $payload ]]; then rm -f $payload; fi
    ln ${payload}_$(arch_suffix) $payload
    rm -f $tarball
  else
    tail -n +$payload_start $me > $payload
  fi
  chmod +x $payload
  echo $payload
}

function clean {
  if [[ $TARBALL -eq 1 ]]; then
    rm -f $TARBALL_MANIFEST
    rm -f $tarball
  fi
  rm -f $1
}

function run {
  local me=$1
  local clean=$2

  final_bin=$(setup $me)
  OMP_NUM_THREADS=$THREADS $final_bin ${ARGS//THREADS/$THREADS}

  if [[ $clean -eq 1 ]]; then clean $final_bin; fi
}

while [[ $1 != "" ]]; do
  case $1 in
    -h | --help) print_help; exit 0;;
    -t | --threads) THREADS=$2; shift;;
    -c) CLEAN=1;;
    -s) SETUP=1;;
  esac
  shift
done

if [[ $SETUP -eq 1 ]]; then
  echo "Generated final binary '$(setup $0)'"
  exit 0
fi

if [[ $THREADS -le 0 ]]; then
  echo "Please specify > 0 threads"
  print_help
  exit 1
fi

run $0 $CLEAN
exit 0

