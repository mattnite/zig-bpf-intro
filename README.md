# zig-bpf-intro

[![build](https://github.com/mattnite/zig-bpf-intro/workflows/build/badge.svg)](https://github.com/mattnite/zig-bpf-intro/actions)

Reminder! this repo has a git submodule, so remember to clone with
`--recursive`!

## If you are new to Zig: Getting Started

If you find yourself here it's likely from my article about using BPF with Zig.
To quickly install the Zig compiler I've made a script to install `master`. All
you need to do is:

```
sudo ./zig-install.sh
```

and that will put Zig into `/usr/local`. Test by running:

```
zig version
```

In order to build and run the example program, simply:

```
sudo zig build run
```

`sudo` is needed here because we'll be loading BPF programs and that requires
the `SYS_ADMIN` capability. TODO: improve capability aspect for education and fun

And in another terminal, just:

```
ping localhost
```

and you'll see output from our BPF wielding program. If you restart `ping`,
you might also see the cpu change (depending on whether you have multiple cpus
that is)

## Exploring

For more resources on Zig:
- [Road to 1.0](https://www.youtube.com/watch?v=Gv2I7qTux7g): A great video on the 'why' of Zig
- [Introduction to the language](ziglang.org)
- [Language Reference](https://ziglang.org/documentation/master/)
- [ziglearn.org](https://ziglearn.org/): A great third-party site that covers
  both the language and general conventions in the standard library.

For locations internal to this repo:
- `src/probe.zig` contains the BPF program
- `src/main.zig` is our main program, it loads the BPF program and initializes a
  perf buffer
- `src/common.zig` contains a function that wraps C code to instantiate a raw
  socket
- `libs/bpf` is a git submodule containing the [Zig BPF Library](https://github.com/mattnite/bpf)
- `libs/bpf/src/object.zig` contains the BPF loader code
