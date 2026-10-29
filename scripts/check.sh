#!/bin/sh
# dsh-computer-use preflight: checks the Cua Driver pieces this bundle needs.
set -u

echo "dsh-computer-use preflight"
echo "--------------------------"

if command -v cua-driver >/dev/null 2>&1; then
  echo "cua-driver: $(cua-driver --version 2>&1 | head -1)"
  echo "permissions:"
  cua-driver permissions status 2>&1 | sed 's/^/  /' | head -6
else
  echo "cua-driver: NOT FOUND"
  echo "  Install Cua Driver: https://github.com/trycua/cua"
  echo "  Then run: cua-driver permissions grant"
fi

echo
echo "Next: install this bundle with DSH Plugin Manager, then open a NEW chat."
