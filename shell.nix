# nix.shell: PicoRV32 Development Environment
#
# This file allows you to use the Nix Package Manager (https://nixos.org/nix)
# in order to download, install, and prepare a working environment for doing
# PicoRV32/PicoSoC development on _any_ existing Linux distribution, provided
# the Nix package manager is installed.
#
# Current included tools:
#
#   - Synthesis: Recent Yosys and SymbiYosys
#   - Place and Route: arachne-pnr and nextpnr (ICE40, ECP5, Python, no GUI)
#   - Packing: Project IceStorm (Trellis tools may be included later?)
#   - SMT Solvers: Z3 4.7.x, Yices 2.6.x, and Boolector 3.0.x
#   - Verification: Recent Verilator, Recent (unreleased) Icarus Verilog
#   - A bare-metal RISC-V cross compiler toolchain, based on GCC 8.2.x
#
# With these tools, you can immediately begin development, simulation, firmware
# hacking, etc with almost no need to fiddle with recent tools yourself. Almost
# all of the tools will be downloaded on-demand (except the GCC toolchain)
# meaning you don't have to compile any recent tools yourself. Due to the
# "hermetic" nature of Nix, these packages should also work on practically any
# Linux distribution, as well.
#
# (This environment should also be suitable for running riscv-formal test
# harnesses on PicoRV32, as well. In fact it is probably useful for almost
# _any_ RTL implementation of the RV32I core.)
#
# Usage
# -----
#
# At the top-level of the picorv32 directory, simply run the 'nix-shell' command,
# which will then drop you into a bash prompt:
#
#
#     $ nix-shell
#     ...
#     [nix-shell:~/src/picorv32]$
#
#
# When you run 'nix-shell', you will automatically begin downloading all of the
# various tools you need from an upstream "cache", so most of this will execute
# very quickly. However, this may take a while, as you will at least have to
# build a cross-compiled RISC-V toolchain, which may take some time. (These
# binaries are not available from the cache, so they must be built by you.) Once
# you have done this once, you do not need to do it again.
#
# At this point, once you are inside the shell, you can begin running tests
# like normal. For example, to run the Verilator tests with the included test
# firmware, which is substantially faster than Icarus:
#
#     [nix-shell:~/src/picorv32]$ make test_verilator TOOLCHAIN_PREFIX=riscv32-unknown-elf-
#     ...
#
#
# Note that you must override TOOLCHAIN_PREFIX (in the top-level Makefile, it
# looks in /opt by default).
#
# This will work immediately with no extra fiddling necessary. You can also run
# formal verification tests using a provided SMT solver, for example, yices and
# boolector (Z3 is not used since it does not complete in a reasonable amount
# of time for these examples):
#
#     [nix-shell:~/src/picorv32]$ make check-yices check-boolector
#     ...
#
# You can also run the PicoSoC tests and build bitstreams. To run the
# simulation tests and then build bitstreams for the HX8K and IceBreaker
# boards:
#
#     [nix-shell:~/src/picorv32]$ cd picosoc/
#     [nix-shell:~/src/picorv32/picosoc]$ make hx8ksynsim icebsynsim
#     ...
#     [nix-shell:~/src/picorv32/picosoc]$ make hx8kdemo.bin icebreaker.bin
#     ...
#
# The HX8K simulation and IceBreaker simulation will be synthesized with Yosys
# and then run with Icarus Verilog. The bitstreams for HX8K and IceBreaker will
# be P&R'd with arachne-pnr and nextpnr, respectively.
#

{ 
  pkgs ? import <nixpkgs> {},
}:
let 
  cross = import <nixpkgs> {
    crossSystem = {
      config = "riscv32-unknown-none-elf";
      gcc = {
        arch = "rv32imc";
      };
      libc = "newlib";
    };
  };
in
pkgs.mkShell rec {
  name = "picorv32-shell";
  
  # These inputs are native, as they are to be used on the host!
  buildInputs = with pkgs; [ python3 gcc
      yosys sby nextpnr arachne-pnr icestorm
      z3 boolector yices
      iverilog verilator
  ] ++ [ cross.buildPackages.gcc ];

  shellHook = ''
    # Add a prefix 'esp-rs' to the shell prompt
    export PS1="(picorv32)$PS1"
    export TOOLCHAIN_PREFIX=riscv32-unknown-none-elf-
  '';
}
