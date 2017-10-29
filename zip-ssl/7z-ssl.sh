#!/usr/bin/bash
# What: 7z/zip using idrsa public key
# $Header: c:/cvs/repo/mosh/perl/7z-ssl.sh,v 1.65 2017-10-29 14:56:10 a Exp $
# GPL(C) moshahmed/at/gmail
# from: https://travis-ci.org/okigan/e7z
#   see https://wiki.openssl.org/index.php/Command_Line_Utilities

function die() { 1>&2 echo -e "$*" ; exit ;}
function warn() { 1>&2 echo -e "$*" ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo "$*" ;fi ;}
function need_file(){ test -f "$1" || die "need_file $*" ;}
function need_dir(){ test -d "$1" || die "need_dir $*" ;}

CMD=${0##*\\}


function usage() {
  keyfile=\$HOME/.ssh/id_rsa
  pemfile=$keyfile
1>&2 echo "
What: $CMD [Options] [Actions] [archive] [args] .. 7z/zip encrypt args into archive with openssl id_rsa
Actions:
  -a archive paths  .. pack    paths into archive (*.7z or *.zip)
  -x archive        .. extract files from archive (*.7z or *.zip)
Options:
  -key keyfile   .. keyfile, e.g. ~/.ssh/.id_rsa
  -pem pemfile   .. keyfile.pem.pub, 
    pemfile made with, ssh-keygen -f keyfile -e -m PKCS8 > pemfile
  -v=1           .. verbose
Example Usage:
  # keyfile=$keyfile
  # pemfile=$pemfile
  # ssh-keygen -f \$keyfile -e -m PKCS8 > \$pemfile
  # $CMD -pem \$pemfile -a archive.zip *.txt    # pack, no passphrase needed.
  # $CMD -key \$keyfile -x archive.zip          # unpack, need private key passphrase
"
  echo "$*"
  exit
}

keyfile=$HOME/.ssh/id_rsa
pemfile=$HOME/.ssh/id_rsa.pem.pub
otpfile=$TMP/otp.ssl # encrypted otp with keyfile
archive=
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
    # break after actions, remaining args
    -a) action=$1 ; archive=${2:?"Need archive"} ; shift 2; args=$* ; break ;;
    -x) action=$1 ; archive=${2:?"Need archive"} ; shift 2; args=$* ; break ;;
    *) usage "Unknown option:'$*'" ;;
  esac
  shift
done

if [[ -z "$action" ]] ;then
  usage
fi

case $archive in
  *.7z | *.zip )  ;;
  *)  die "archive should be *.zip or *.7z" ;;
esac

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
    case $archive in
      *.7z) cat $otpfile |
        7z a            $archive -si$otpfile
        7z u  -p$otp    $archive    $args ;;
      *.zip)
        zip -j           $archive $otpfile
        zip -u -P "$otp" $archive $args ;;
    esac
    need_file $archive
    ;;
  -x) need_file $archive
    # Extract otp from archive using keyfile
    case $archive in
      *.7z) otp=$(7z x -so $archive $otpfile | openssl pkeyutl -decrypt -inkey $keyfile ) ;;
      *.zip) otp=$(unzip -p $archive $otpfile | openssl pkeyutl -decrypt -inkey $keyfile ) ;;
      esac
    if [[ -z "$otp" ]] ;then
      die "No otp=$otp in $archive/$otpfile"
    fi
    info "# Decrypting $archive with otp=$otp"
    case $archive in
      *.7z) 7z x $archive -p$otp $args -x!$otpfile ;;
      *.zip) unzip -P "$otp" $archive $args -x $otpfile_base ;;
    esac  
    ;;
  *) usage "Nothing to do '$action'?" ;;
esac
