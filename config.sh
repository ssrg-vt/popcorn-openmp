# Machine configurations -- customize for your setup

# Break machine string into constituent components
function item {
  echo $1 | sed -e 's/:/\n/g' | head -n $2 | tail -n 1
}

function arch {
  item "$1" 1
}

function machine {
  item "$1" 2
}

HETEROGENEOUS_MACHINES="x86-64:echo5 aarch64:fox5"
HETEROGENEOUS_LEADER="x86-64:echo5"

function set_heterogeneous {
  MACHINES="$HETEROGENEOUS_MACHINES"
  LEADER="$HETEROGENEOUS_LEADER"
}

#HOMOGENEOUS_MACHINES="x86-64:mir0 x86-64:mir1 x86-64:mir2 x86-64:mir3
#                      x86-64:mir4 x86-64:mir5 x86-64:mir6 x86-64:mir7"
HOMOGENEOUS_MACHINES="x86-64:mir6 x86-64:mir7"
HOMOGENEOUS_LEADER="x86-64:mir7"

function set_homogeneous {
  MACHINES="$HOMOGENEOUS_MACHINES"
  LEADER="$HOMOGENEOUS_LEADER"
}

VM_MACHINES="aarch64:popcorn@10.1.1.121 x86-64:popcorn@10.1.1.120"
VM_LEADER="x86-64:popcorn@10.1.1.120"

function set_vm {
  MACHINES="$VM_MACHINES"
  LEADER="$VM_LEADER"
}

