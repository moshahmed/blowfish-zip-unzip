#!/usr/bin/bash
# What: zip using public key for win7
# $Header: c:/cvs/repo/mosh/perl/zip-ssl.sh,v 1.30 2017-10-27 02:38:37 a Exp $
# GPL(C) moshahmed/at/gmail

function die() { 1>&2 echo -e "$*" ; exit ;}
function warn() { 1>&2 echo -e "$*" ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo "$*" ;fi ;}
function need_file(){ test -f "$1" || die "need_file $*" ;}
function need_dir(){ test -d "$1" || die "need_dir $*" ;}

CMD=${0##*\\}

function usage() { 1>&2 echo "
What: $CMD [Options] [actions] [archive] .. zip encrypt with openssl id_rsa
  See https://wiki.openssl.org/index.php/Command_Line_Utilities
    and https://wiki.openssl.org/index.php/Command_Line_Utilities
Actions:
  -a file.zip files         .. archive files into file.zip
  -x file.zip               .. extract files from file.zip
Options:
  -key keyfile   .. keyfile, e.g. ~/.ssh/.id_rsa
  -pem pemfile   .. keyfile.pem.pub, 
    pemfile made with, ssh-keygen -f keyfile -e -m PKCS8 > pemfile
  -v=1           .. verbose
Example Usage:
  $CMD -pem id_rsa.pem.pub -a archive.zip *.txt    # pack
  $CMD -key id_rsa         -x archive.zip          # unpack
"
  echo "$*"
  exit
}

zipper=zip
unzipper=unzip

export TMPDIR=$TMP
need_dir $TMPDIR

log=$TMPDIR/run.log
keyfile=$HOME/.ssh/id_rsa
pemfile=$HOME/.ssh/id_rsa.pem.pub
otpfile=otp.ssl # encrypted otp with keyfile
archive=$TMPDIR/test.zip
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
    # break after actions, remaining args for zip
    -a) action=$1 ; archive=${2:?"Need archive.zip"} ; shift 2; args=$* ; break ;;
    -x) action=$1 ; archive=${2:?"Need archive.zip"} ; shift 2; args=$* ; break ;;
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
    # Save encrypted otp = otpfile = ssl_enc(keyfile,otp) in the archive
    info "# Encrypting $archive with otpfile=$otpfile=$otp"
    $zipper -j           $archive $otpfile
    $zipper -u -P "$otp" $archive $args
    need_file $archive
    ;;
  -x)
    need_file $archive
    # Extract otp from archive using keyfile
    otp=$($zipper x -so $archive $otpfile | openssl pkeyutl -decrypt -inkey $keyfile )
    if [[ -z "$otp" ]] ;then
      die "No otp=$otp in $archive/$otpfile"
    fi
    info "# Decrypting $archive with otp=$otp"
    $unzipper -P "$otp" $archive $args -x $otpfile_base
    ;;
  *) usage "Nothing to do '$action'?" ;;
esac
