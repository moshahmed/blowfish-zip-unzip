#!/usr/bin/bash
# What: zip using public key for win7
# $Header: c:/cvs/repo/mosh/perl/zip-ssl.sh,v 1.18 2017-10-12 16:17:15 a Exp $
# GPL(C) moshahmed/at/gmail

function die() { 1>&2 echo "$*" ; exit ;}
function warn() { 1>&2 echo $* ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo $* ;fi ;}
function need_file(){ test -f "$1" || die "need_file $1" ;}
function need_dir(){ test -d "$1" || die "need_dir $1" ;}

CMD=${0##*\\}
zipper=zip
unzipper=unzip

export TMPDIR="$(mktemp -d)"
log=$TMPDIR/run.log

keyfile=$TMPDIR/id_rsa.tmp
otpfile=$TMPDIR/otp.ssl # encrypted otp with keyfile
otpfile_base=`basename $otpfile`
archive=$TMPDIR/test.zip
verbose=
action=
args=


function usage() { 1>&2 echo "
What: $CMD  [-k keyfile] -[K|t|a|x] .. zip encrypt with openssl id_rsa
  See https://wiki.openssl.org/index.php/Command_Line_Utilities
Example Usage:
  $CMD -K id_rsa                             # first time, create id_rsa keypair
  $CMD -k id_rsa -a archive.zip *.txt        # pack
  $CMD           -l archive.zip               # list
  $CMD -k id_rsa -x archive.zip              # unpack
Where
  TMPDIR=$TMPDIR, log=$log,
  zipper=$zipper, unzipper=$unzipper
  keyfile=$keyfile, otpfile=$otpfile
Options: $CMD
  -a           .. archive
  -l           .. list archive
  -x           .. extract
  -k keyfile   .. keyfile=~/.ssh/.id_rsa (default $keyfile)
  -K keyfile   .. make keyfile using ssh-keygen
  -o otpfile   .. extract otp from otpfile using keyfile
  -lcd dir     .. chdir dir
  -t           .. test
  -v=1         .. verbose
"
  echo $*
  exit
}

# Options
while [ $# -gt 0 ]  ;do
	case $1 in
    -lcd) dir=${2:Need-lcd-dir} ; shift; need_dir $dir ; cd $dir ;;
		-k)	keyfile=${2:?Need-keyfile}; shift ;;
    -K) keyfile=${2:?}; shift;
        warn "Creating keypair keyfile=$keyfile with openssl"
        # ssh-keygen -t rsa -f $keyfile -q -N "" # blank pass phrase.
        ssh-keygen -t rsa -f $keyfile -q
        need_file $keyfile
        exit ;;
    -t) action=$1; shift ;;
		-a) action=$1 ; archive=${2:?} ; shift ; shift; args=$* ; break ;;
    -o) action=$1 ; otpfile=${2:?} ; shift ; shift; args=$* ; break ;;
		-x) action=$1 ; archive=${2:?} ; shift ; shift; args=$* ; break ;;
		-l) action=$1 ; archive=${2:?} ; shift ; shift; args=$* ; break ;;
    -v) verbose=1 ;;
    -v=*) verbose=${1#-*=} ; info verbose=$verbose ;;
		*) usage "Unknown option:'$*'" ;;
	esac
	shift
done

if [[ -z "$action" ]] ;then
  usage "Nothing to do?"
fi

info "=== action=$action, archive=$archive, keyfile=$keyfile, args=$args"

function testme() {
  need_dir $TMPDIR
  cd $TMPDIR
  if [[ ! -e "$keyfile" ]] ;then
    ssh-keygen -t rsa -f $keyfile -q -N ""
    info "# Generated openssl rsa keyfile=$keyfile"
  fi
  need_file $keyfile
  date > date.txt
  info "# bash $0 -v=$verbose -k $keyfile -a $archive date.txt"
          bash $0 -v=$verbose -k $keyfile -a $archive date.txt
  need_file $archive
  info "# bash $0 -v=$verbose -k $keyfile -x $archive date.txt -d out"
          bash $0 -v=$verbose -k $keyfile -x $archive date.txt -d out
  need_file out/date.txt
  diff   $PWD/date.txt $PWD/out/date.txt ; error=$?
  if [ $error -eq 0 ] ; then
    warn "test passed"
  else
    warn "test failed"
  fi
}

case $action in
  -t) testme ; exit ;;
  -o) warn otp=$(cat $otpfile | openssl pkeyutl -decrypt -inkey $keyfile) ; exit ;;
	-a)
    # generate otp (one time password)
    otp=$(openssl rand -hex 32|dos2unix)
    # Save encrypted otp = ssl_enc(keyfile,otp) in the archive, -si from stdin.
		echo $otp | openssl pkeyutl -encrypt -inkey $keyfile -out $otpfile
    # cat otpfile | $zipper a $archive -si$otpfile
    need_file $otpfile
    info "# Generated otp=$otp "
    info "# Encryped opt with $keyfile to otpfile=$otpfile"
    # save otpfile unencrypted
    warn "# zip $archive"
    $zipper          $archive $otpfile
    $zipper -u -P "$otp" $archive $args
    need_file $archive
		info "# Archived $archive encrypted with otp in otpfile=$otpfile"
    info "# otp=$otp"
    # Extract otp from archive using ssl keyfile, -so to stdout.
    if [[ -n "$verbose" ]] ;then
      $unzipper -lv $archive | perl -lne 'print if m/^---/.../^---/'
    fi
    otp2=`$unzipper -p $archive "*$otpfile_base" | openssl pkeyutl -decrypt -inkey $keyfile`
    if [[ "$otp2" != "$otp" ]] ;then
      die "# opt extraction error otp=$otp!=$otp2 in $archive in $otpfile"
    else
      info "# opt extracted correctly"
    fi
    ;;
	-l) # list archive
    warn "$zipper -lv $archive"
    $unzipper -vl $archive $args | perl -lne 'print if m/^---/.../^---/'
    ;;
	-x)
    # Extract otp from archive using ssl keyfile, -so to stdout.
    otp=`$unzipper -p $archive "*$otpfile_base" | openssl pkeyutl -decrypt -inkey $keyfile`
    if [[ -z "$otp" ]] ;then
      die "No otp=$otp in $archive in $otpfile"
    fi
    # use otp to extract archive.
    warn "# $unzipper           $archive $args -x */$otpfile_base"
		        $unzipper -P "$otp" $archive $args -x */$otpfile_base
		info "# Decrypted $archive with"
		info "# otp=$otp"
		;;
esac

