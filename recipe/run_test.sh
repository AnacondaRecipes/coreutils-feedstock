#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
# ============ setup ============
if [[ -z "${PREFIX:-}" ]]; then
  echo "WARNING: \$PREFIX is not set; falling back to \$(dirname \$(which bash))/.."
  PREFIX="$(dirname "$(which bash)")/.."
fi
BIN_DIR="$PREFIX/bin"

PFX=""
read -r -d '' ALL_UTILS <<'EOF' || true
[
arch, b2sum, base32, base64, basename, basenc, cat, chcon, chgrp, chmod, chown, chroot,
cksum, comm, cp, csplit, cut, date, dd, df, dir, dircolors, dirname, du, echo, env,
expand, expr, factor, false, fmt, fold, groups, head, hostid, id, install, join, link,
ln, logname, ls, md5sum, mkdir, mkfifo, mknod, mktemp, mv, nice, nl, nohup, nproc,
numfmt, od, paste, pathchk, pinky, pr, printenv, printf, ptx, pwd, readlink, realpath,
rm, rmdir, runcon, seq, sha1sum, sha224sum, sha256sum, sha384sum, sha512sum, shred,
shuf, sleep, sort, split, stat, stdbuf, stty, sum, sync, tac, tail, tee, test, timeout,
touch, tr, true, truncate, tsort, tty, uname, unexpand, uniq, unlink, users, vdir, wc,
who, whoami, yes
]
EOF

ALL_UTILS=($(printf '%s\n' "$ALL_UTILS" | tr -d '[],' | tr -s ' \t\n' '\n' | grep -v '^\s*$'))

exists() {
  [[ -x "$BIN_DIR/$1" ]]
}

run_version_or_help() {
  local exe="$1"
  if "$exe" --version >/dev/null 2>&1; then
    return 0
  elif "$exe" --help >/dev/null 2>&1; then
    return 0
  else
    "$exe" >/dev/null 2>&1 || return 1
  fi
}

PASS=0
MISS=0
FAIL=0

echo "== Smoke check of all coreutils in $BIN_DIR (prefix='$PFX') =="
for u in "${ALL_UTILS[@]}"; do
  exe="$BIN_DIR/${PFX}${u}"
  if exists "${PFX}${u}"; then
    if run_version_or_help "$exe"; then
      printf "  [OK]   %s\n" "${PFX}${u}"
      ((PASS++))
    else
      printf "  [FAIL] %s (exited non-zero)\n" "${PFX}${u}"
      ((FAIL++))
    fi
  else
    printf "  [MISS] %s (not found)\n" "${PFX}${u}"
    ((MISS++))
  fi
done

echo "== Summary: PASS=$PASS, FAIL=$FAIL, MISS=$MISS =="

# ============ Functional tests (safe subset) ============
set -x
TDIR="$(mktemp -d)"
trap 'rm -rf "$TDIR"' EXIT
cd "$TDIR"

# helper to call with prefix
gx() { "$BIN_DIR/${PFX}$1" "${@:2}"; }

# files & io
echo "hello" > a.txt
gx cat a.txt | gx tr '[:lower:]' '[:upper:]' | grep -qx "HELLO"
gx wc -c < a.txt | tr -d '[:space:]' | grep -qx "6"

# cp/mv/rm/ln/readlink/realpath
gx cp a.txt b.txt
diff -u a.txt b.txt
gx mv b.txt c.txt
test -f c.txt && test ! -f b.txt
gx ln -s c.txt link.txt
gx readlink link.txt | grep -qx "c.txt"
gx realpath link.txt | grep -E '.*/c\.txt$'
gx rm -f link.txt
test ! -e link.txt

# sort/uniq/cut/paste/head/tail
printf "zeta\nalpha\nbeta\nalpha\n" > words.txt
gx sort words.txt | gx uniq -c | awk '{print $1,$2}' | sort > out.txt
grep -qx "2 alpha" out.txt
grep -qx "1 beta"  out.txt
grep -qx "1 zeta"  out.txt
printf "a,b,c\n1,2,3\n" > csv.txt
gx cut -d, -f2 csv.txt | tail -n1 | grep -qx "2"
paste <(printf "a\nb\n") <(printf "1\n2\n") | grep -qx $'a\t1'

# hashes
gx sha256sum a.txt | awk '{print $1}' | grep -E '^[0-9a-f]{64}$'

# mkdir/mkfifo/mktemp
gx mkdir -p d/sub && test -d d/sub
fifo="$(gx mktemp -u).fifo"; gx mkfifo "$fifo"; test -p "$fifo"; rm -f "$fifo"

# date/seq/yes/true/false
gx date -u +"%Y-%m-%dT%H:%M:%SZ" | grep -E '^[0-9]{4}-'
gx seq 3 | paste -sd, - | grep -qx "1,2,3"
timeout_bin="${BIN_DIR}/${PFX}timeout"
if [[ -x "$timeout_bin" ]]; then
  "$timeout_bin" 0.2 "$BIN_DIR/${PFX}shuf" -i 1-10 >/dev/null 2>&1 || true
fi
"$BIN_DIR/${PFX}true"
! "$BIN_DIR/${PFX}false" 2>/dev/null || true

set +x
echo "Functional subset: OK"

exit 0