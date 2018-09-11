#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INPUT="$DIR/payload.sh"
POPCORN=0
BIN=""
HET_BIN="REPLACE_WITH_BIN_aarch64 REPLACE_WITH_BIN_x86-64"
ARGS=""
CLEAN=1

function die {
  echo "ERROR: $1"
  exit 1
}

function print_help {
  echo "create-runnable.sh -- create a script with a binary and arguments"
  echo
  echo "Usage: create-runnable.sh -b BIN -a ARGS"
  echo "Options:"
  echo "  -b BIN  : benchmark binary"
  echo "  -a ARGS : all arguments (specify all in quotes)"
  echo "  -p      : for running on heterogeneous-ISA Popcorn setup --" \
       "requires binaries for all ISAs (denoted by ISA suffix)"
  echo "  -n      : don't clean up any intermediate files created"
  echo
  echo "Note: the args should include THREADS to be replaced by a thread" \
       "count if applicable"
}

while [[ $1 != "" ]]; do
  case $1 in
    -h | --help) print_help; exit 0;;
    -b) BIN=$2; shift;;
    -a) ARGS="$2"; shift;;
    -p) POPCORN=1;;
    -n) CLEAN=0;;
  esac
  shift
done

if [[ $BIN == "" ]]; then die "please specify a binary with -b"; fi
RAW_BIN=$(basename $BIN)
OUTPUT="${BIN}-run"

if [[ $POPCORN -eq 1 ]]; then
  HET_BIN="${HET_BIN//REPLACE_WITH_BIN/$BIN}"
  for bin in $HET_BIN; do
    if [[ ! -f $bin ]]; then die "binary '$bin' doesn't exist"; fi
  done
  TARBALL=${BIN}.tar.bz2
  echo "Creating Popcorn multi-ISA tarball '$TARBALL'"
  tar -cjf $TARBALL $HET_BIN
  BIN=$TARBALL
else
  if [[ ! -f $BIN ]]; then die "binary '$BIN' doesn't exist"; fi
  HET_BIN=""
fi


echo "Creating a runnable script for '$RAW_BIN $ARGS' -> $OUTPUT"
cat $INPUT | \
  sed -e "s/REPLACE_WITH_ARGS/$ARGS/g" \
      -e "s/REPLACE_WITH_BIN/$RAW_BIN/g" \
      -e "s/IS_TARBALL/$POPCORN/g" \
      -e "s/REPLACE_WITH_MANIFEST/$HET_BIN/g" > $OUTPUT
echo "BINARY:" >> $OUTPUT
cat $BIN >> $OUTPUT
chmod +x $OUTPUT

if [[ $POPCORN -eq 1 ]] && [[ $CLEAN -eq 1 ]]; then
  rm -f $TARBALL
fi

