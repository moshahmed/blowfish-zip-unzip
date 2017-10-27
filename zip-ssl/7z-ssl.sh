#!/usr/bin/bash
# What: 7z using public key for win7
# $Header: c:/cvs/repo/mosh/perl/7z-ssl.sh,v 1.57 2017-10-27 02:38:37 a Exp $
# GPL(C) moshahmed/at/gmail

function die() { 1>&2 echo -e "$*" ; exit ;}
function warn() { 1>&2 echo -e "$*" ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo "$*" ;fi ;}
function need_file(){ test -f "$1" || die "need_file $*" ;}
function need_dir(){ test -d "$1" || die "need_dir $*" ;}

CMD=${0##*\\}

function usage() { 1>&2 echo "
What: $CMD [Options] [actions] [archive] .. 7z encrypt with openssl id_rsa
  From: https://travis-ci.org/okigan/e7z
    and https://wiki.openssl.org/index.php/Command_Line_Utilities
Actions:
  -a file.7z files         .. archive files into file.7z
  -x file.7z               .. extract files from file.7z
Options:
  -key keyfile   .. keyfile, e.g. ~/.ssh/.id_rsa
  -pem pemfile   .. keyfile.pem.pub, 
    pemfile made with, ssh-keygen -f keyfile -e -m PKCS8 > pemfile
  -v=1           .. verbose
Example Usage:
  $CMD -pem id_rsa.pem.pub -a archive.7z *.txt    # pack
  $CMD -key id_rsa         -x archive.7z          # unpack
"
  echo "$*"
  exit
}

zipper=7z

export TMPDIR=$TMP
need_dir $TMPDIR

log=$TMPDIR/run.log
keyfile=$HOME/.ssh/id_rsa
pemfile=$HOME/.ssh/id_rsa.pem.pub
otpfile=otp.ssl # encrypted otp with keyfile
archive=$TMPDIR/test.7z
verbose=
action=
args=

# Options
while [ $# -gt 0 ]  ;do
  case $1 in
    -key) keyfile=${2:?}; shift ;;
    -pem) pemfile=${2:?}; shift ;;
    -v) verbose=1 ;;
    -v=*) verbose=${1#-*=} ;;
    # break after actions, remaining args for 7z
    -a) action=$1 ; archive=${2:?"Need archive.7z"} ; shift 2; args=$* ; break ;;
    -x) action=$1 ; archive=${2:?"Need archive.7z"} ; shift 2; args=$* ; break ;;
    *) usage "Unknown option:'$*'" ;;
  esac
  shift
done

info "=== action=$action, archive=$archive, keyfile=$keyfile, args=$args"

case $action in
  -a)
    # Generate otp (one time password)
    otp=$(openssl rand -hex 32|dos2unix)
    info "# Generated otp=$otp"
    need_file $pemfile "\nDo: ssh-keygen -f $keyfile -e -m PKCS8 > $pemfile"
    echo $otp |
      openssl pkeyutl -encrypt -pubin -inkey $pemfile -out $otpfile
    need_file $otpfile
    info "# Encryped opt with $pemfile to otpfile=$otpfile"
    # Save encrypted otp = otpfile = ssl_enc(keyfile,otp) in the archive, -si from stdin.
    info "# Encrypting $archive with otpfile=$otpfile=$otp"
    cat $otpfile | $zipper a        $archive -si$otpfile
                   $zipper u -p$otp $archive    $args
    need_file $archive
    ;;
  -x)
    need_file $archive
    # Extract otp from archive using keyfile -so to stdout.
    otp=$($zipper x -so $archive $otpfile | openssl pkeyutl -decrypt -inkey $keyfile )
    if [[ -z "$otp" ]] ;then
      die "No otp=$otp in $archive/$otpfile"
    fi
    info "# Decrypting $archive with otp=$otp"
    $zipper x $archive -p$otp $args -x!$otpfile
    ;;
  *) usage "Nothing to do '$action'?" ;;
esac
