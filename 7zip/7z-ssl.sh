#/usr/bin/sh
# What: 7zip file or 7unzip archive
# GPL(C) moshahmed/at/gmail
# Refs:
#   linux: yum install p7zip .. and use 7za
#   https://wiki.openssl.org/index.php/Command_Line_Utilities

function die() { 1>&2 echo -e "$*" ; exit ;}
function warn() { 1>&2 echo -e "$*"        ;}
function info() { if [[ -n "$verbose" ]]; then 1>&2 echo -e "$*" ;fi ;}
function need_exe(){ [[ -x "$(command -v $1)" ]] || die "Need_exe $1" ;}
function need_file(){ test -f "$1" || die "need_file $*" ;}
function need_dir(){  test -d "$1" || die "need_dir $*"  ;}
function need_val(){  test -n "$1" || die "need_val $2"  ;}

CMD=${0##*\\} ; CMD=${CMD##*/} ; CMD=${CMD%.*}
SCRIPT=$(realpath -s "$0")

DRY=
verbose=

if [[ "$OS" =~ "Windows" ]] ;then
  packer=7z
else
  packer=7za
fi

kfile=
otpfile=$TMP/otpfile.txt

zargs="-snl -snh"
USAGE="
Usage: $CMD [Options] [$packer single file or dir | file.7z to unpack]
Options:
  -h -0 -v -test -debug .. help, dry, verbose, test, debug
  -kfile=sshkey  .. pub/prv to enc/dec PASS_7Z into otpfile
    where:
      PASS_7Z: one time password generated by: openssl rand -hex 32
      otpfile: PASS_7Z encrypted with ssh pubkey.
      pack:    otpfile=enc(otp=PASS_7Z, sshkey.pem.pub)
      unpack:  otp=PASS_7Z=dec(otpfile, sshkey.pem with PASSPHRASE)
Remaining options to $packer
  -pPASS_7Z  => -pPASS_7Z -mhe
  -etc    =>  send etc as args to $packer
  Defaults: $zargs (keep links as links)
Examples:
     > cd \$TMP
     > touch x.txt y.txt z.txt
Eg1. > $CMD x.txt    => Pack into x.7z
     > $CMD x.7z     => Unpack    x.txt
Eg2. > $CMD dir      => Pack into dir.7z
     > $CMD dir.7z   => Unpack into dir/..
Eg3. Pack x.txt y.txt z.txt into x.7z with 7zip password=Yoyo
     > $CMD -0 -pYoyo x.txt y.txt z.txt
Test > $CMD -v -kfile=id_rsa.pem -test
    1. Pack   y.txt z.txt otpfile=enc(otp,kfile.pub) into y.7z
    2. Unpack y.7z with otp=dec(otpfile,kfile.pem with passphrase)
"


function realpath2(){
  somepath=${1:-.}
  if [[ "$OS" =~ "Windows" ]] ;then
    somepath=$(realpath $somepath)
  else
    somepath=$(cygpath -mad $somepath)
  fi
  echo "$somepath"
}

function test_7z_ssl(){
  testdir=$TMP/test1
  mkdir -p $testdir
  cd $testdir || die "Missing $testdir" ;

  if [[ "$OS" =~ Windows* ]] ; then
    PWD2=$(cygpath -wam .)
  else
    PWD2=$PWD
  fi
  echo PWD=$PWD2

  if [[ ! -f "$kfile" ]] ;then
    if [[ -z "$kfile" ]] ;then
      kfile=7z_ssl-id_rsa.pem
      if [[ -f "$kfile" ]] ;then
        rm -fv $kfile $kfile.pub
      fi
    fi
    PASSPHRASE=abcde
    echo "# == Need PASSPHRASE (5 char or more, or blank) to generate $kfile"
    read -s -p "PASSPHRASE:" PASSPHRASE  ; echo ""
    if [[ -n "$PASSPHRASE" ]] ;then
      PASSPHRASE="-P $PASSPHRASE"
      echo "# == Generating $kfile with PASSPHRASE=$PASSPHRASE"
    else
      echo "# == Generating $kfile with blank PASSPHRASE=$PASSPHRASE"
    fi
    ssh-keygen -m PEM -t rsa -b 2048 -C test_7z_ssl $PASSPHRASE -q -f $kfile
    [[ $? != 0 ]] && die "ssh-keygen failed"
    ssh-keygen -f $kfile $PASSPHRASE -e -m PKCS8 > $kfile.pub
    [[ $? != 0 ]] && die "ssh-keygen failed"
  fi

  [[ -f "$kfile" ]] || die "Need kfile=$kfile"
  file $kfile*
  echo "# Check passphrase of kfile=$kfile, showing pubkey"
  ssh-keygen -y -f $kfile || die "Cannot open $kfile"

  rm -rf date-1 date-1.7z date-[123].txt
  for i in 1 2 3 ;do date > date-$i.txt ;done

  echo "# Pack otpfile and date*.txt into date-1.7z"
  bash $SCRIPT -v -kfile=$kfile.pub date*.txt
  rm -rf date-1 date-[123].txt
  echo "# Listing date-1.7z"
  7z l date-1.7z | grep -P "(archive|[.]txt)"

  echo "# Unpack date-1.7z with dec(otpfile with kfile)"
  bash $SCRIPT -kfile=$kfile date-1.7z

  if [[ "$debug" ]]; then
    pwd ; ls -al . date-1
  else
    rm -rfv date-1 date-1.7z date-[123].txt
  fi
  exit
}

# Process options
for arg in $@ ;do
  case $arg in
    -v)       verbose=1 ; shift;;
    -debug)   set -x; debug=1 ; shift;;
    -0)       DRY="echo Dry:"  ; shift;;
    -[h?])    die "$USAGE"  ; shift ;;
    -kfile=*)   kfile=${1#-kfile=} ; shift
                kfile=$(echo $kfile)
                # kfile=$(realpath2 "$kfile")
                ;;
    -test)    shift; test_7z_ssl ;;
    -p*)      zargs+=" -mhe $arg"; PASS_7Z=${arg#-p} ; shift ;;
    -*)       zargs+=" $arg"; shift ;;
  esac
done

[[ "$#" -ge 1 ]] || die "$USAGE"
[[ -e $1   ]] || die "Not a file or dir $1"
[[ -x "$(command -v $packer)" ]] || die "Need $packer"

packer="${DRY} $packer $zargs"

file=$1
shift
case $file in
  *.7z) # unpack
    archive=$file
    [[ -f $archive ]] || die "Missing archive $archive"
    output=${archive%.7z}
    echo "Unpack $archive to $output"
    if [[ -n "$kfile" ]] ;then
      # Extract otpfile from archive to stdout, and decrypt PASS_7Z from otpfile with kfile
      [[ -f "$kfile" ]] || die "Need kfile=$kfile"
      otpfile_base=$(basename $otpfile)
      PASS_7Z=$($packer x -so $archive $otpfile_base | base64 -d | openssl pkeyutl -decrypt -inkey $kfile )
      [[ -z "$PASS_7Z" ]] && die "Cannot get PASS_7Z from otpfile=$otpfile, kfile=$kfile, archive=$archive"
      # use 7z -pPASS_7Z to decrypt remaining archive
      packer="$packer -p$PASS_7Z"
    else
      die "Need -kfile kfile"
    fi
    # if archive has multiple files save in a dir
    count=$($packer l $archive| perl -lne 'print $1 if m/(\d+)\s+files/')
    if [[ $count -gt 1 ]] ;then
      [[ -e $output ]] && die "output dir '$output' already exists"
      $packer x -o$output $archive | grep -P "(Creating|Files|Archive)"
    else
      [[ -e $output ]] && die "output file '$output' already exists"
      $packer x $archive | grep -P "(Creating|Files|Archive)"
    fi
    ;;
  *) # pack
    archive=${file%.*}.7z
    # archive=${file}.7z
    [[ -e $archive ]] && die "archive $archive already exists"
    if [[ -n "$kfile" ]] ;then
      [[ -f "$kfile" ]] || die "Need kfile=$kfile"
      if [[ -z "$PASS_7Z" ]] ;then
        PASS_7Z=$(openssl rand -hex 32) # Generate random PASS_7Z, 32 bytes in hex, 256bits
      fi
      # otpfile=encrypt PASS_7Z with kfile
      echo "$PASS_7Z" | openssl pkeyutl -encrypt -pubin -inkey $kfile | base64 > $otpfile
      [[ -s $otpfile ]] || die "Invalid otpfile=$otpfile"
      info "# PASS_7Z=$PASS_7Z"
      info "# otpfile=$otpfile\n otpfile=[\n$(cat $otpfile)\n]" 
      # save otpfile to archive without password
      $packer a $archive $otpfile | grep -P "(Creating|Files|Archive)"
      rm -fv $otpfile
      # For remaining files, 7z encrypt with PASS_7Z into archive
      packer="$packer -p$PASS_7Z"
    else
      die "Need -kfile kfile.pub"
    fi
    if [[ -z "$DRY" ]] ;then
      $packer a $archive $file $* | grep Creating
    else
      $packer a $archive $file $* | grep -P "(Creating|Files|Archive)"
    fi
    ;;
esac
