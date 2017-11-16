#!/usr/bin/bash
# What: 7z/zip using idrsa public key
# $Header: c:/cvs/repo/mosh/mbin/7z-ssl.sh,v 1.73 2017-11-16 03:09:37 a Exp $
# GPL(C) moshahmed/at/gmail
# from: https://travis-ci.org/okigan/e7z
#   see https://wiki.openssl.org/index.php/Command_Line_Utilities

function die() { 1>&2 echo -e "$*" ; exit ;}
function warn() { 1>&2 echo -e "$*" ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo "$*" ;fi ;}
function need_file(){ test -f "$1" || die "need_file $*" ;}
function need_dir(){ test -d "$1" || die "need_dir $*" ;}

CMD=${0##*\\} 
CMD=${CMD%*}

function usage() {
  keyfile=\$HOME/.ssh/id_rsa
  pemfile=$keyfile.pem.pub
1>&2 echo "
What: $CMD [Options] [Actions] [archive] [args] .. 7z/zip encrypt args into archive with openssl id_rsa
Actions:
  a archive paths  .. pack    paths into archive
  x archive        .. extract files from archive
                      archive: *.zip or *.7z or *.gtz (gpg+tar).
Options:
  -keyfile=~/.ssh/.id_rsa
  -pemfile=~/.ssh/keyfile.pem.pub, generated: ssh-keygen -f keyfile -e -m PKCS8 > pemfile
  -otp=read      .. ask user for otp
  -otp=pass      .. override random otp.
  -v=1           .. verbose
Setup
  keyfile=$keyfile
  pemfile=$pemfile
  ssh-keygen -f \$keyfile -e -m PKCS8 > \$pemfile
Example
  $CMD -pemfile=\$pemfile a archive.zip -r dir *.txt # pack, no passphrase needed.
  $CMD -keyfile=\$keyfile x archive.zip          # unpack, need private key passphrase
Test:
  rm -fv x.7z date*.txt
  date > date.txt
  $CMD a x.7z  date.txt
  $CMD a x.zip date.txt
  $CMD x x.7z -aou
  diff date*.txt
"
  echo "$*"
  exit
}

keyfile=$HOME/.ssh/id_rsa
pemfile=$HOME/.ssh/id_rsa.pem.pub
otpfile=$TMP/otp.ssl # encrypted otp with keyfile
otpfile_base=$(basename $otpfile)
archive=
verbose=
action=
args=

# Options
while [ $# -gt 0 ]  ;do
  case $1 in
    -keyfile=*) keyfile=${1#-keyfile=} ;;
    -pemfile=*) pemfile=${1#-permfile=} ;;
    -otp=read) read -s -p "otp:" otp ;;
    -otp=*) otp=${1#-otp=} ;;
    -v) verbose=1 ;;
    -v=*) verbose=${1#-*=} ;;
    # break after actions, remaining args to archiver
    a) action=$1 ; archive=${2:?"Need archive"} ; shift 2; args=$* ; break ;;
    x) action=$1 ; archive=${2:?"Need archive"} ; shift 2; args=$* ; break ;;
    *) usage "Unknown option:'$*'" ;;
  esac
  shift
done

if [[ -z "$action" ]] ;then
  usage
fi

case $archive in
  *.7z | *.zip )  ;;
  *.gtz) ;;
  *) die "Unsupported archive type $archive" ;;
esac

info "=== action=$action, archive=$archive, keyfile=$keyfile, args=$args"

case $action in
  a)
    # Generate otp (one time password)
    case $archive in
    *.gtz) ;; # No otpfile.
    *.zip | *.7z )
      if [[ -z "$otp" ]] ;then
        otp=$(openssl rand -hex 32|dos2unix)
        info "# Generated otp=$otp"
      fi
      need_file $pemfile "\nDo: ssh-keygen -f $keyfile -e -m PKCS8 > $pemfile"
      echo $otp |
        openssl pkeyutl -encrypt -pubin -inkey $pemfile -out $otpfile
      need_file $otpfile
      info "# Encryped opt with $pemfile to otpfile=$otpfile"
      ;;
    esac
    # Save encrypted otp = otpfile = ssl_enc(keyfile,otp) in the archive
    info "# Encrypting $archive with otp in otpfile=$otpfile, otp=$otp"
    case $archive in
      *.7z) cat $otpfile |
        7z a            $archive -si$otpfile_base
        7z u  -p$otp    $archive    $args
        7z l $archive
        ;;
      *.zip)
        zip -j           $archive $otpfile
        zip -u -P "$otp" $archive $args
        unzip -lv $archive
        ;;
      *.gtz)
        if [[ -z "$otp" ]] ;then
          read -s -p "gpg password:" otp
        fi
        tar -cvf - $args |
        gpg --symmetric --passphrase=$otp --set-filename $args > $archive
        ;;
    esac
    need_file $archive
    warn "Wrote $archive"
    ;;
  x) need_file $archive
    if [[ -z "$otp" ]] ;then
      # Extract otp from archive using keyfile
      case $archive in
        *.7z ) otp=$(7z x -so $archive $otpfile_base | openssl pkeyutl -decrypt -inkey $keyfile ) ;;
        *.zip) otp=$(unzip -p $archive $otpfile_base | openssl pkeyutl -decrypt -inkey $keyfile ) ;;
        *.gtz) if [[ -z "$otp" ]] ;then
                read -s -p "gpg password:" otp
              fi ;;
      esac
    fi
    if [[ -z "$otp" ]] ;then
      die "No otp in $archive/$otpfile"
    fi
    info "# Decrypting $archive with otp=$otp"
    case $archive in
      *.7z | *.zip )  7z x $archive -p$otp $args -x!$otpfile_base ;;
      # *.zip) unzip -P "$otp" $archive $args -x $otpfile_base ;;
      *.gtz) gpg -o- "--passphrase=$otp" $archive | tar -xvf - ;;
    esac  
    ;;
  *) usage "Nothing to do '$action'?" ;;
esac
