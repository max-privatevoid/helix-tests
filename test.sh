#!/usr/bin/env -S nix shell bash tmux coreutils diffutils findutils -c bash
test_tmux="tmux -S /tmp/helix-tmux-test-$(id -u)-$$"
DELAY=${DELAY:-0.1}

sk() {
  for key in "$@"; do
    $test_tmux send-keys $key
    sleep $DELAY
  done
}

rm -rf work/
mkdir -p work
export TEMP_HOME="$(mktemp -d)"
export HOME="$TEMP_HOME"
for tst in $(find commands -type f -exec basename {} \;); do
  echo TESTING: $tst
  cp input/$tst.nix work/$tst.nix
  $test_tmux new-session -d hx work/$tst.nix
  sleep $DELAY
  sk '//\*MARKER\*/' Enter d
  cat commands/$tst | while read cmd; do
    sk "$cmd"
  done
  sk '/*DONE*/' Escape :wq Enter
  $test_tmux kill-server 2>/dev/null || true
  diff -C 10 --color work/$tst.nix output/$tst.nix && echo PASSED: $tst
done
rm -rf "$TEMP_HOME"
