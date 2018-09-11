# popcorn-openmp
A collection of OpenMP applications ported from other benchmark suites for use with Popcorn Linux

The benchmarks contained in this repository have been ported from Seoul National University's NPB [1] (C-version), PARSEC [2] and Rodinia [3].  They include small Popcorn-specific optimizations for optimized data layout and execution behavior.  Additionally, all benchmarks use a unified build system as most of the compilation process is identical across benchmarks.

### System Configuration

The build system automates both building and copying binaries to the correct locations depending on the values in ```config.sh```.  There are three default configurations

1. Heterogeneous -- a heterogeneous ARM/x86 setup
2. Homogeneous -- a homogeneous setup, assumed to be all x86
3. Virtual machine -- a virtual machine setup (can be ARM/x86, ARM/ARM, x86,x86)

You should modify ```config.sh``` to tailor it to your available machines.  In particular, you'll need to give the build system a list of architecture:hostname tuples comprising each of the setups.  For example:

```
HETEROGENEOUS_MACHINES="x86-64:echo7 aarch64:fox7"
HETEROGENEOUS_LEADER="x86-64:echo7"
```

This specifies the two machines ```echo7``` and ```fox7``` are the machines in the heterogeneous setup, ```echo7``` is an x86-64 machine, ```fox7``` is an ARM64 machine, and ```echo7``` is the leader (i.e., the machine from which applications will be started).  The build system will copy all binaries to each machine and will set them up for execution.

**Please do not commit your local config.sh to the repository!**

### Building applications

All benchmarks utilize the Makefile contained in the repository root.  Additionally, they a script to automate some of the processes for packaging and distributing the benchmarks.

To build a benchmark, enter the application's directory and execute the ```make.sh``` script:

```
$ cd blackscholes
$ ls
blackscholes.c  inputs  Makefile  make.sh
$ ./make.sh -noscp
... (build output) ...
```

Without any extra arguments, the command will build the application and try to copy the binaries to the heterogeneous setup.  Possible argument:

```
-heterogeneous : copy binaries to the heterogeneous setup (default)
-homogeneous   : copy binaries to the homogeneous setup
-vm            : copy binaries to the virtual machine setup
```

Note that for some benchmarks the build system creates a "runnable" which encapsulates both the binary and all other command line arguments needed to launch the application.  For example:

```
$ ./make.sh
... (build output) ...
Creating Popcorn multi-ISA tarball 'blackscholes.tar.bz2'
Creating a runnable script for 'blackscholes THREADS SET_PATH_TO_INPUT\/in_10M.txt \/dev\/null' -> blackscholes-run
$ ls
blackscholes_aarch64    blackscholes.c    blackscholes_x86-64    build_aarch64  inputs    make.sh
blackscholes_aarch64.o  blackscholes-run  blackscholes_x86_64.o  build_x86-64   Makefile
```

Here, ```blackscholes-run``` is a runnable created by the build system which helps automate running the application.  All the user needs to do is supply the number of threads via ```-t``` (run with ```-h``` for more options).  Note that for all applications, even those which are not created as runnables, the ```-t``` flag should be used to set the number of threads.

As mentioned previously, several of the benchmarks contain small optimizations.  To enable them, build with the ```-type``` flag:

```
$ ./make -type=optimized
```

### Running applications

By default the applications have the OpenMP loop iteration scheduler set to "runtime", meaning the user can select the scheduler via the "OMP_SCHEDULE" environment variable:

```
$ OMP_SCHEDULE=STATIC ./blackscholes-run -t 16
```

This sets the scheduler to OpenMP's static scheduler.

For Popcorn execution, the user can specify thread placement in the cluster via the "POPCORN_PLACES" environment variable:

```
$ OMP_SCHEDULE=STATIC POPCORN_PLACES={8},{8} ./blackscholes-run -t 16
```

This places 8 threads on nodes 0 and 1, respectively.  The user can specify arbitrary thread placements for up to 32 nodes (the current Popcorn Linux max) by adding extra comma-separated numbers in curly-braces.  If the user wants to place the same number of threads on all available nodes in the system, they can use the "nodes" keyword.  For example on an 8-node setup:

```
$ OMP_SCHEDULE=STATIC POPCORN_PLACES="nodes(8)" ./blackscholes-run -t 64
```

This places 8 threads on each of the nodes in the system.  To summarize, the user must both supply the **number** of threads and the thread **placement**.

[1] SNU NPB Suite -- http://aces.snu.ac.kr/software/snu-npb/
[2] PARSEC -- http://parsec.cs.princeton.edu/
[3] Rodinia -- http://lava.cs.virginia.edu/Rodinia/download_links.htm
