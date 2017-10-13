#!/usr/bin/bash
# What: 7z using public key for win7
# $Header: c:/cvs/repo/mosh/perl/7z-ssl.sh,v 1.47 2017-10-13 10:57:47 a Exp $
# GPL(C) moshahmed/at/gmail

function die() { 1>&2 echo "$*" ; exit ;}
function warn() { 1>&2 echo $* ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo $* ;fi ;}
function need_file(){ test -f "$1" || die "need_file $1" ;}
function need_dir(){ test -d "$1" || die "need_dir $1" ;}

CMD=${0##*\\}
zipper=7z

export TMPDIR="$(mktemp -d)"
log=$TMPDIR/run.log
keyfile=$TMPDIR/id_rsa.tmp
otpfile=$TMPDIR/otp.ssl # encrypted otp with keyfile
archive=$TMPDIR/test.7z
verbose=
action=
args=

function usage() { 1>&2 echo "
What: $CMD [Options] [actions] [7z options] .. 7z encrypt with openssl id_rsa
  From: https://travis-ci.org/okigan/e7z
  See https://wiki.openssl.org/index.php/Command_Line_Utilities
Options:
  -k keyfile   .. keyfile=~/.ssh/.id_rsa (default $keyfile)
  -lcd dir     .. chdir dir
  -v=1         .. verbose
Actions:
  -a           .. archive
  -l           .. list archive
  -x           .. extract
Actions-setup:
  -K keyfile   .. make keyfile using ssh-keygen
  -o otpfile   .. extract otp from otpfile using keyfile
  -t           .. test
Where:
  TMPDIR=mktemp -d, zipper=$zipper
Example Usage:
  $CMD -K id_rsa                        # first time, create id_rsa keypair
  $CMD -k id_rsa -a archive.7z *.txt    # pack
  $CMD           -l archive.7z          # list
  $CMD -k id_rsa -x archive.7z          # unpack
"
  echo $*
  exit
}

function testme() {
  need_dir $TMPDIR
  cd $TMPDIR
  if [[ ! -e "$keyfile" ]] ;then
    ssh-keygen -t rsa -f $keyfile -q -N ""
    info "# Generated openssl rsa keyfile=$keyfile"
  fi
  need_file $keyfile
  date > date.txt
  bash $0 -v=$verbose -k $keyfile -a $archive date.txt # >> $log 2>&1
  need_file $archive
  bash $0 -v=$verbose -k $keyfile -x $archive -oout # >> $log 2>&1
  need_file out/date.txt
  diff   $PWD/date.txt $PWD/out/date.txt ; error=$?
  if [ $error -eq 0 ] ; then
    warn "test passed"
  else
    warn "test failed"
  fi
}

function make_ssh_key() {
  local keyfile=$1
  warn "Creating keypair keyfile=$keyfile with ssh-keygen"
  ssh-keygen -t rsa -f $keyfile -q
  need_file $keyfile
  need_file $keyfile.pub
}

# Options
while [ $# -gt 0 ]  ;do
  case $1 in
    -lcd) dir=${2:Need-lcd-dir} ; shift; need_dir $dir ; cd $dir ;;
    -k) keyfile=${2:?Need-keyfile}; shift ;;
    -K) keyfile=${2:?}; shift;
        make_ssh_key $keyfile
        exit ;;
    -v=*) verbose=${1#-*=} ; info verbose=$verbose ;;
    -v) verbose=1 ;;
    # break after actions, remaining args for 7z
    -a) action=$1 ; archive=${2:?} ; shift ; shift; args=$* ; break ;;
    -o) action=$1 ; otpfile=${2:?} ; shift ; shift; args=$* ; break ;;
    -x) action=$1 ; archive=${2:?} ; shift ; shift; args=$* ; break ;;
    -l) action=$1 ; archive=${2:?} ; shift ; shift; args=$* ; break ;;
    -t) testme ; exit ;;
    *) usage "Unknown option:'$*'" ;;
  esac
  shift
done

info "=== action=$action, archive=$archive, keyfile=$keyfile, args=$args"
case $action in
  -o) warn otp=$(cat $otpfile | openssl pkeyutl -decrypt -inkey $keyfile) ; exit ;;
  -a)
    # generate otp (one time password)
    otp=$(openssl rand -hex 32|dos2unix)
    # Save encrypted otp = ssl_enc(keyfile,otp) in the archive, -si from stdin.
    echo $otp | openssl pkeyutl -encrypt -inkey $keyfile -out $otpfile
    need_file $otpfile
    info "# Generated otp=$otp "
    info "# Encryped opt with $keyfile to otpfile=$otpfile"
    # save otpfile unencrypted
    # cat $otpfile | $zipper a $archive -si$otpfile
    info "$zipper a        $archive $otpfile"
    info "$zipper u -p$otp $archive $args"
    $zipper a        $archive $otpfile  >> $log 2>&1
    $zipper u -p$otp $archive $args  >> $log 2>&1
    need_file $archive
    info "# Encrypted $archive with otpfile=$otpfile=$otp"
    # Extract otp from archive using ssl keyfile, -so to stdout.
    if [[ -n "$verbose" ]] ;then
      $zipper l $archive >> $log 2>&1
    fi
    otp2=`$zipper x -so $archive ${otpfile//*\/} | openssl pkeyutl -decrypt -inkey $keyfile`
    # check top can be extracted correctly from archive with ssl using keyfile
    if [[ "$otp2" != "$otp" ]] ;then
      die "# opt extraction error otp=$otp!=$otp2 in $archive in $otpfile"
    else
      info "# opt extracted correctly"
    fi
    ;;
  -l) # list archive
    warn "$zipper l $archive"
    $zipper l $archive -p$otp $args -x!$otpfile | perl -lne 'print if m/^---/.../^---/'
    ;;
  -x)
    # Extract otp from archive using ssl keyfile, -so to stdout.
    otp=`$zipper x -so $archive ${otpfile//*\/} | openssl pkeyutl -decrypt -inkey $keyfile 2>> $log`
    if [[ -z "$otp" ]] ;then
      die "No otp=$otp in $archive in $otpfile"
    fi
    # use otp to extract archive.
    otpbase=${otpfile//*\/}
    warn "# $zipper x $archive -p$otp $args -x!$otpbase"
            $zipper x $archive -p$otp $args -x!$otpbase >> $log 2>&1
    info "# Decrypted $archive with otp=$otp"
    ;;
  *) usage "Nothing to do '$action'?" ;;
esac
