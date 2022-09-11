#!/usr/bin/bash
# What: 7z/zip with public key
# GPL(C) moshahmed/at/gmail
# Refs:
#   https://travis-ci.org/okigan/e7z
#   https://wiki.openssl.org/index.php/Command_Line_Utilities

function die()  { 1>&2 echo -e "$*" ; exit ;}
function warn() { 1>&2 echo -e "$*"        ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo "$*" ;fi ;}
function need_exe(){ [[ -x "$(command -v $1)" ]] || die "Need_exe $1" ;}
function need_file(){ test -f "$1" || die "need_file $*" ;}
function need_dir(){  test -d "$1" || die "need_dir $*"  ;}
function need_val(){  test -n "$1" || die "need_val $2"  ;}

CMD=${0##*\\} ; CMD=${CMD%.*}
SCRIPT=$(realpath -s "$0")

TMP=${TMP:=/tmp}
[[ -d "$TMP" ]] || TMP=.

keyfile=$HOME/.ssh/id_rsa
if [[ "$OS" =~ Windows* ]] ; then
  packer=7z
  keyfile=$(cygpath -wam $keyfile)
  TMP=$(cygpath -wam $TMP)
else
  packer=7za
fi

need_exe $packer

pubfile=$keyfile.pub
otpfile=$TMP/otp.ssl # encrypted otp with keyfile.
archive=
verbose=
action=
args=

function usage_7zs() {
  PASSPHRASE=abcde
1>&2 echo "
What: $CMD [Options] Actions archive [args] paths .. pubkey encrypted archive.
Actions:
  a .. Pack paths into archive encrypted with otp (one time password).
       Also pack otpfile (otp encrypted with ssh pubfile) into archive.
  l .. list archive
  x .. Unpack files from archive (*.zip or *.7z)
       First extract otp=(otpfile from archive decrypted with ssh keyfile+PASSPHRASE),
       Then use otp to extract remaining files.
Options:
  -keyfile $keyfile     .. default private key keyfile.pem
  -pubfile $keyfile.pub .. default public  key keyfile.pem.pub
  -makekey keyfile PASSPHRASE .. PASSPHRASE must be blank or more than 4 chars.
    eg. -makekey keyfile.pem $PASSPHRASE
        ssh-keygen -m PEM -t rsa -b 4096 -P \"$PASSPHRASE\" -f keyfile.pem -q
        ssh-keygen -f keyfile.pem -e -m PKCS8 -q > keyfile.pem.pub
  -otp=read  .. ask user for otp
  -otp=pass  .. use this pass as otp, default is 256bit: openssl rand -hex 32
  -haveotp otpfile .. extract otp from otpfile and saves same otp in a new otpfile.
      otp_to_otpfile: openssl pkeyutl -encrypt -pubin -inkey pubfile -base64
      otpfile_to_otp: openssl pkeyutl -decrypt        -inkey keyfile -base64
  -test      .. self test
  -h, -v=1, -debug .. help, verbose, debug
Example
1 Pack zip with otp=(in otpfile in archive locked with pubfile).
  > $CMD a archive.zip -r dir *.txt
2 Unpack zip with otp=(in otpfile in archive)+keyfile+PASSPHRASE
  > $CMD x archive.zip
3 Create keyfile to Pack(a=archive)/Unpack(x=extract)/List(l=list) archive
  > $CMD -makekey keyfile.pem              .. passphrase=abcde
  > $CMD -keyfile keyfile.pem a archive.7z -r [dir-or-files-to-pack eg. "*.txt"]
  > $CMD -keyfile keyfile.pem l archive.7z .. List   archive, needs passphrase
  > $CMD -keyfile keyfile.pem x archive.7z .. Unpack archive, needs passphrase
"
  echo "$*"
  exit
}

function test_7zs() {
  TMP=$TMP/test_7zs
  mkdir -p $TMP
  cd $TMP || die "Need $TMP"
  pwd

  [[ -n  "$verbose" ]] && verbose=-v=1
  # OR $CMD a x.zip date.txt
  # extract, decrypt otp with ssh key (needs PASSPHRASE)

  keyfile=$PWD/7z-ssh-id_rsa.pem
  if [[ "$OS" =~ Windows* ]] ; then
    keyfile=$(cygpath -wam $keyfile)
  fi

  # PASSPHRASE=abcde
  read -s -p "PASSPHRASE (blank or more than 4 chars, eg:$PASSPHRASE):" PASSPHRASE
  echo ""
  if [[ 0 < "${#PASSPHRASE}" && "${#PASSPHRASE}" < 5 ]] ;then
    echo "PASSPHRASE must be blank or more than 4 chars" ; exit
  fi

  rm -f $keyfile $keyfile.pub
  echo "# 1.== Creating keyfile=$keyfile with PASSPHRASE=$PASSPHRASE"
  bash $SCRIPT $verbose -makekey $keyfile "$PASSPHRASE"
  file $keyfile*

  echo "# 2.== Test1 7zip"
  date > date.txt
  echo "# Packing date.7z with keyfile=$keyfile.pub"
  bash $SCRIPT $verbose -keyfile $keyfile a date.7z  date.txt > /dev/null
  echo "# Extracting with otp=decrypt(otpfile=$otpfile,keyfile=$keyfile with PASSPHRASE=$PASSPHRASE)"
  echo "# Unzipping date.7z with otp"
  bash $SCRIPT $verbose -keyfile $keyfile x date.7z -aou      > /dev/null
  echo "# Listing archive: $packer l date.7z"
  $packer l         date.7z | grep 202[0-9]
  echo "# diff " date*.txt
  diff date*.txt && echo "Success" || echo "Fail"
  rm -f date.7z date.zip date*.txt

  echo "# 3.== Test2 zip"
  date > date.txt
  echo "# Packing date.zip with keyfile=$keyfile.pub"
  bash $SCRIPT $verbose -keyfile $keyfile a date.zip  date.txt > /dev/null
  echo "# Extracting with otp=decrypt(otpfile=$otpfile,keyfile=$keyfile with PASSPHRASE=$PASSPHRASE)"
  echo "# Unzipping date.zip with otp"
  bash $SCRIPT $verbose -keyfile $keyfile x date.zip -aou      > /dev/null
  echo  "# Listing archive: unzip -lv date.zip"
  unzip -lv date.zip | grep 202[0-9]
  echo "# diff" date*.txt
  diff date*.txt && echo "Success" || echo "Fail"

  if [[ "$debug" ]]; then
    pwd ; ls -al .
  else
    echo "# Cleanup"
    rm -f date.7z date.zip date*.txt
  fi
  exit
}

function makekey() {
  keyfile=${1:?"Need keyfile name"}
  PASSPHRASE=${2}
  # PASSPHRASE=${2:?"Need passphrase"}
  if [[ -n "$PASSPHRASE" ]] ;then
    ssh-keygen -m PEM -t rsa -b 4096 -C 7zs-$(date +%F) -P "$PASSPHRASE" -f $keyfile -q
    ssh-keygen -f $keyfile -P "$PASSPHRASE" -e -m PKCS8 -q > $keyfile.pub
  else
    # interactive, it will ask user for PASSPHRASE
    ssh-keygen -m PEM -t rsa -b 4096 -C 7zs-$(date +%F)  -f $keyfile -q
    ssh-keygen -f $keyfile  -e -m PKCS8 -q > $keyfile.pub
  fi
  ls -al $keyfile $keyfile.pub
}

# Options
while [ $# -gt 0 ]  ;do
  case $1 in
    -otp=read) read -s -p "otp:" otp ;;
    -otp=*) otp=${1#-otp=} ;;
    -keyfile) shift; keyfile=$1 ; need_file $keyfile keyfile ;
              pubfile=$keyfile.pub ;;
    -pubfile) shift; pubfile=$1 ; need_file $pubfile pubfile ;;
    -makekey) shift; makekey $* ; exit ;;
    -haveotp) shift; haveotp=$1 ; need_file $haveotp haveotp
      need_file $keyfile keyfile
      otp=$(base64 -d $haveotp | openssl pkeyutl -decrypt -inkey $keyfile )
      need_val "$otp" otp
      info "# In $haveotp found otp=$otp"
      ;;
    -test) test_7zs ; exit ;;
    -h) usage_7zs ;;
    -v) verbose=1 ;;
    -v=*) verbose=${1#-*=} ;;
    -debug)   set -x; debug=1 ;;
    -*) usage_7zs "Unknown option '$1'" ;;
    # break after action, remaining args to archiver
    # x       ) action=$1 ; archive=${2:?"Need archive"} ; shift 2; args=$* ; break ;;
    a | x | l ) action=$1 ; archive=${2:?"Need archive"} ; shift 2; args=$* ; break ;;
    *) usage_7zs "Unknown action:'$*'" ;;
  esac
  shift
done

if [[ -z "$action" ]] ;then
  usage_7zs
fi

case $archive in
  *.7z | *.zip )  ;;
  *) die "Unsupported archive $archive" ;;
esac

info "=== action=$action, archive=$archive, keyfile=$keyfile, args=$args"

case $action in
  a) # Generate otp (one time password)
    if [[ -z "$otp" ]] ;then
      otp=$(openssl rand -hex 32)
      if [[ "$OS" =~ Windows* ]] ; then
        otp=$(echo "$otp" |dos2unix)
      fi
      info "# Generated otp=$otp"
    fi
    need_file $pubfile "\nDo: ssh-keygen -f $keyfile -e -m PKCS8 > $pubfile"
    # encrypt(otp) into otpfile
    echo $otp |
      openssl pkeyutl -encrypt -pubin -inkey $pubfile | base64 > $otpfile
    need_file $otpfile
    info "# Encrypted otp with $pubfile to otpfile=$otpfile"
    # Save encrypted otp = otpfile = ssl_enc(keyfile,otp) in the archive
    info "# Encrypting $archive with otp in otpfile=$otpfile, otp=$otp"
    otpfile_base=$(basename $otpfile)
    case $archive in
      *.7z) cat $otpfile |
             $packer a            $archive -si$otpfile_base
        echo $packer u  -p$otp    $archive    $args
             $packer u  -p$otp    $archive    $args
             $packer l $archive
        ;;
      *.zip)
        zip -j           $archive $otpfile
        zip -u -P "$otp" $archive $args
        unzip -lv $archive
        ;;
    esac
    need_file $archive
    warn "# Wrote $archive"
    ;;
  x | l) need_file $archive
    otpfile_base=$(basename $otpfile)
    if [[ -z "$otp" ]] ;then
      # Extract otp from archive using keyfile
      #   openssl will ask for PASSPHRASE of keyfile
      otp=$($packer x -so $archive $otpfile_base | base64 -d | openssl pkeyutl -decrypt -inkey $keyfile )
    fi
    need_val "$otp" otp
    info "# Decrypting action=$action $archive with otp=$otp"
    $packer $action $archive -p$otp $args -x!$otpfile_base
    ;;
  *) usage_7zs "Nothing to do '$action'?" ;;
esac
