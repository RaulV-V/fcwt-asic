#!/usr/bin/env bash
# fCWT accelerator toolchain check
# Run from ~/FPGA/CWT:  bash check_tools.sh

PROJ="$HOME/FPGA/CWT"
cd "$PROJ" || { echo "Can't find $PROJ"; exit 1; }
[ -f .venv/bin/activate ] && source .venv/bin/activate

ok=0; missing=0
check() {
  local name="$1"; local cmd="$2"
  if out=$(eval "$cmd" 2>/dev/null | head -n1) && [ -n "$out" ]; then
    printf "  [OK]      %-14s %s\n" "$name" "$out"; ok=$((ok+1))
  else
    printf "  [MISSING] %-14s\n" "$name"; missing=$((missing+1))
  fi
}
pycheck() {
  local mod="$1"
  if v=$(python3 -c "import $mod; print(getattr($mod,'__version__','installed'))" 2>/dev/null); then
    printf "  [OK]      %-14s %s\n" "py:$mod" "$v"; ok=$((ok+1))
  else
    printf "  [MISSING] %-14s\n" "py:$mod"; missing=$((missing+1))
  fi
}

echo "== System =="
check "OS"        "grep PRETTY_NAME /etc/os-release | cut -d= -f2"
check "WSL"       "uname -r | grep -i microsoft"

echo "== Version control =="
check "git"       "git --version"
check "git user"  "git config --global user.name"
check "git email" "git config --global user.email"
check "gh CLI"    "gh --version"
check "ssh key"   "ls ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub 2>/dev/null"
check "gh login"  "gh auth status 2>&1 | grep -i 'logged in'"
check "repo init" "git -C $PROJ rev-parse --is-inside-work-tree"
check "remote"    "git -C $PROJ remote get-url origin"

echo "== HDL simulation =="
check "iverilog"  "iverilog -V 2>&1"
check "verilator" "verilator --version"
check "gtkwave"   "command -v gtkwave && echo found"
check "make"      "make --version"

echo "== Synthesis =="
check "yosys"     "yosys -V"

echo "== Python (golden model + cocotb) =="
check "venv"      "[ -n \"\$VIRTUAL_ENV\" ] && echo \$VIRTUAL_ENV"
check "python3"   "python3 --version"
check "pip"       "python3 -m pip --version"
pycheck numpy
pycheck scipy
pycheck matplotlib
pycheck cocotb
pycheck fcwt

echo
echo "OK: $ok   MISSING: $missing"
