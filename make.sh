#!/bin/bash

# Benchmarks should define the following:
#   BIN             : name of the binary
#   CREATE_RUNNABLE : whether to embed the binary in a runnable script
#   ARGS            : if CREATE_RUNNABLE == 1, arguments to the runnable

source ../config.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ALL_BIN="${BIN}_aarch64 ${BIN}_x86-64"
DEST="~"

TYPE=""
HOSTTY="heterogeneous"

function print_help {
  echo "Default: copy to heterogeneous hosts, empty type argument for make"
  echo "Options:"
  echo "  -h | --help  : print help & exit"
  echo "  -type=TYPE   : add type argument to make command"
  echo "  -dest=DEST   : destination directory on hosts for copied binaries"
  echo "  -noscp       : don't copy binaries to any hosts"
  echo "  -homogeneous : copy to homogeneous hosts"
  echo "  -vm          : copy to VM hosts"
  echo
  echo "Note: set heterogeneous, homogeneous & vm configuration in config.sh"
}

# Argument parsing
for arg in $@; do
  case $arg in
    -h | --help) print_help; exit 0;;
    -type=*) TYPE="${arg#-type=}";;
    -dest=*) DEST="${arg#-dest=}";;
    -noscp) HOSTTY="none";;
    -homogeneous) HOSTTY="homogeneous";;
    -vm) HOSTTY="vm";;
  esac
done

# Set hosts to which we'll copy binaries
case $HOSTTY in
  heterogeneous) set_heterogeneous;;
  homogeneous) set_homogeneous;;
  vm) set_vm;;
  none) ;;
  *) echo "Invalid run configuration '$HOSTTY'"; exit 1;;
esac

make clean
make type=$TYPE CLASS=$CLASS
MAKE_RESULT="$?"

# Check that all binaries were generated
for bin in $ALL_BIN; do
  if [[ ! -f $bin ]]; then
    echo "Binary '$bin' doesn't exist"
    exit $MAKE_RESULT;
  fi
done

# If we're not copying, finish with make's exit code
if [[ $HOSTTY == "none" ]]; then exit $MAKE_RESULT; fi

# Set up the binaries for execution on the destination machines according to
# whether or not we're creating a runnable
if [[ $CREATE_RUNNABLE -eq 1 ]]; then
  $DIR/utils/create-runnable.sh -b $BIN -a "${ARGS//\//\\\/}" -p
  for m in $MACHINES; do
    machine=$(machine $m)
    scp ${BIN}-run $machine:$DEST
    if [[ $m != $LEADER ]]; then ssh $machine "cd $DEST; ./${BIN}-run -s"; fi
  done
else
  tarball=${BIN}.tar.bz2
  echo "Tarring up binaries into $tarball"

  tar -cjf $tarball $ALL_BIN
  for m in $MACHINES; do
    arch=$(arch $m)
    machine=$(machine $m)
    scp $tarball $machine:$DEST
    ssh $machine "cd $DEST; tar -xf ./$tarball; rm ./$tarball"
    if [[ $HOSTTY == "heterogeneous" ]] || [[ $HOSTTY == "vm" ]]; then
      ssh $machine "if [[ -f $DEST/$BIN ]]; then rm -f $DEST/$BIN; fi; \
                    ln $DEST/${BIN}_${arch} $DEST/$BIN"
    fi
  done
  rm $tarball
fi

