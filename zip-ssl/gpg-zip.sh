#!/usr/bin/bash
# GPL(C) moshahmed@gmail.com 2016-01-29
# from https://github.com/github-archive/windows-msysgit/blob/master/bin/gpg-zip
# $Id: gpg-zip.sh,v 1.30 2017-10-12 16:55:42 a Exp $

# gpg-archive - gpg-ized tar using the same format as PGP's PGP Zip.
# (C) 2005 FSF This file is part of GnuPG.
# Despite the name, PGP Zip format is actually an OpenPGP-wrapped tar file.
# To be compatible with PGP, this must be a USTAR format tar file.
# Unclear on whether there is a distinction here between
# the GNU or POSIX variant of USTAR.

function die() { 1>&2 echo "$*" ; exit ;}
function warn() { 1>&2 echo $* ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo $* ;fi ;}
function need_file(){ test -f "$1" || die "need_file $1" ;}
function need_dir(){ test -d "$1" || die "need_dir $1" ;}

function make_gpg_key() {
  warn "== make_gpg_key GPASS=$GPASS GNUPGHOME=$GNUPHOME"
  cat > foo <<EOF_FOO
      %echo Generating a basic OpenPGP key
      Key-Type: DSA
      Key-Length: 1024
      Subkey-Type: ELG-E
      Subkey-Length: 1024
      Name-Real: Mosh.Hmi
      Name-Comment: test
      Name-Email: mosh+Hmi@hmi-tech.net
      Expire-Date: 0
      Passphrase: $GPASS
      %commit
      %echo done
EOF_FOO
  gpg --batch --gen-key foo
}

CMD=${0##*\\}

TAR=tar

# GPG=c:/tools/gpg215/bin/gpg.exe .. this doesn't work with mosh.hmi
# GPG=c:/tools/gpg4win/gpg2.exe
# GPG=c:/bin14/gpg14/gpg.exe
GPG=gpg

GPG_VERSION=$( $GPG --version | grep "^gpg" )

gpg_args=-q
tar_args=

usage="\
cvs id $Id: gpg-zip.sh,v 1.30 2017-10-12 16:55:42 a Exp $
Usage: $CMD OPTIONS INFILES INDIRS .. Encrypt/decrypt/sign files into archive
Options:
  [-h|--help]
  [-ls|--list-archive]
  [-d|--decrypt] OR
  [-e|--encrypt] OR [-c|--symmetric]
  [[-o|--output] OUTFILE]
  [-0] no default options
  [--gpg GPG_EXE] [--gpg-args ARGS] gpg_args+=ARGS
  [--tar TAR_EXE] [--tar-args ARGS] tar_args+=ARGS
  [-v=1] verbose
  [-p=password]
  [-selftest]

  GPG=$GPG, TAR=$TAR,
  GPG_VERSION=$GPG_VERSION

Examples
Encrypt dir for default public key
  > gpg-zip -e -o out.gtz dir         .. Archive dir for default pubkey
  > gpg-zip -e -r john -o out.gtz dir .. Archive dir for john
  > gpg-zip -0 -e -o out.gtz dir      .. Ask for userid/pub key

Encrypt and decrypt dir with symmetric key (no userid).
  > gpg-zip -c --gpg-args --force-mdc -o out.gtz dir
  > gpg-zip -d out.gtz

Decrypt manually:
  > gpg -d out.gtz
  > tar -tvf out.tar .. to view
  > tar -xvf out.tar .. to restore
"

verbose=

while test $# -gt 0 ; do
  case $1 in
    -h | -\? | --help | --h*) die "$usage" ;;
    --list-archive|-ls)
      action=list
      shift
      ;;
    --encrypt | -e)
      gpg_args="$gpg_args --encrypt"
      action=create
      shift
      ;;
    --decrypt | -d)
      gpg_args="$gpg_args --decrypt"
      action=unpack
      shift
      ;;
    --symmetric | -c)
      gpg_args="$gpg_args --symmetric"
      action=create
      shift
      ;;
    --sign | -s)
      gpg_args="$gpg_args --sign"
      action=create
      shift
      ;;
    --recipient | -r)
      gpg_args="$gpg_args --recipient $2"
      shift 2
      ;;
    --local-user | -u)
      gpg_args="$gpg_args --local-user $2"
      shift 2
      ;;
    --output | -o)
      gpg_args="$gpg_args --output $2"
      shift 2
      ;;
    -0)
      gpg_args="$gpg_args --no-options"
      shift
      ;;
    -v)
      verbose=1
      shift
      ;;
    -v=*)
      verbose=${1#-*=}
      shift
      ;;
    --version)
      echo "gpg-zip (GnuPG) $VERSION"
      exit 0
      ;;
    --gpg)
      GPG=$1
      shift
      ;;
    --gpg-args)
      gpg_args="$gpg_args $2"
      shift 2
      ;;
    --tar)
      TAR=$1
      shift
      ;;
    --tar-args)
      tar_args="$tar_args $2"
      shift 2
      ;;
    -selftest) action=selftest ; shift ;;
    -p=*) GPASS=${1#-p=} ; shift;
      if [[ -z "$GPASS" ]] ;then
        read -s -p "password=" GPASS
      fi
      info "hash(password)=$(echo $GPASS | sha256sum | perl -lane 'print $F[0]')"
      gpg_args="$gpg_args --passphrase=$GPASS"
      ;;
    --) shift ; break ;;
    -*) die "$usage Unknown option '$1'" ;;
    *) break ;;
  esac
done

case $action in
create)
  warn "== Packing $@ =="
  info "$TAR -cf - "$@" | $GPG --set-filename x.tar $gpg_args" 1>&2
        $TAR -cf - "$@" | $GPG --set-filename x.tar $gpg_args
;;
unpack)
  warn "== Unpacking $@ =="
  info "$GPG $gpg_args $1 | $TAR $tar_args -xvf -" 1>&2
        $GPG $gpg_args $1 | $TAR $tar_args -xvf -
;;
list)
  warn "== Listing $@ =="
  info "$GPG $gpg_args $1 | $TAR $tar_args -tf -" 1>&2
        $GPG $gpg_args $1 | $TAR $tar_args -tf -
;;
selftest)
  export GNUPGHOME="$(mktemp -d)"
  cd $GNUPGHOME
  GPASS=x
  make_gpg_key
  warn "== selftest $@ =="
  OUT=out.gtz
  rm -f $OUT
  date > date.1
  date > date.2
  bash $0 -v=$verbose -0 -e -r Mosh.Hmi -o $OUT date.1 date.2
  need_file $OUT
  mv date.1 date.1.old
  mv date.2 date.2.old
  bash $0 -v=$verbose -p=$GPASS -0 -d -ls $OUT
  bash $0 -v=$verbose -p=$GPASS -0 -d $OUT
  diff date.1 date.1.old ; error=$?
  if [ $error -eq 0 ] ; then
    warn "test passed"
  else
    warn "test failed"
  fi
  ;;
*)
  die "$usage"
  ;;
esac
