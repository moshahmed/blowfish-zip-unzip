#!/usr/bin/bash
# What: gpg-glob.sh for windows

function die() { 1>&2 echo "$*" ; exit ;}
function warn() { 1>&2 echo "$*" ;}
function info() { if [[ -n "$VERBOSE" ]]; then 1>&2 echo $* ;fi ;}
function need_file(){ test -f "$1" || die "need_file $1" ;} 
function need_dir(){ test -d "$1" || die "need_dir $1" ;} 
 
CMD=${0##*\\} 
ACTION=c
USERID=x
GPG=gpg
GPG_DRY="echo dry gpg"
GPASS=
: ${TMP:=/tmp}
TMP=${TMP/\/cygdrive\/c\//c:/}  # /cygdrive/c/tmp => c:/tmp
OUTDIR=$TMP
OUTEXT=
VERBOSE=0
OVERWRITE=0

function print_usage() {
  2>&1 echo "\
What: gpg-glob encrypts multiple-files
Usage: $CMD OPTIONS INFILES =action=> OUTDIR/INFILES.OUTEXT
  -a=[c|d]     default -a=$ACTION
  -o=OUTDIR    default -o=$OUTDIR
  -e=OUTEXT    default -e=$OUTEXT
  -p=password  default -p=$GPASS
  -v           default verbose=$VERBOSE
  -w           default overwrite=$OVERWRITE
  -gpg=path    default=$GPG
  -0           dryrun, GPG_DRY=$GPG_DRY
  -debug       to debug this bash script

Example:
  $CMD -a=c -w -p=x -o=$TMP      *.txt
  $CMD -a=d -w -p=x -o=c:/temp $TMP/*.gpg

$*
"
  exit
}

function get_pass() {
  if [[ -z "$GPASS" ]] ;then
    read -s -p "password=" GPASS
    echo ""
  else
    return
  fi
  if [[ -z "$GPASS" ]] ;then
    print_usage "Need password"
  fi
  info "hash(password)=$(echo $GPASS | sha256sum | perl -lane 'print $F[0]')"
  warn "hash(password)=$(echo $GPASS | sha256sum | perl -lane 'print substr($F[0],0,3)')"
}

for i in $* ;do # PROCESS OPTIONS
  case $i in
  -*)
    case $i in
      -0)  GPG=$GPG_DRY ;;
      -v)  VERBOSE=1 ;;
      -a=c) ACTION=c
        ;;
      -a=d) ACTION=d
        ;;
      -w)  OVERWRITE=1 ;;
      -debug) set -x ;;
      -gpg=*) GPG=${1#-gpg=} ;;
      -e=*) OUTEXT=${1#-e=} ;;
      -o=*) OUTDIR=${1#-o=} ;;
      -p=*) GPASS=${1#-p=} ;;
      -[h?]) print_usage ;;
      *) print_usage "Unknown option $i" ;;
    esac
    shift ;;
  *) break ;;
  esac
done
 
if [[ $# == 0 ]] ;then
  print_usage No files to process?
fi

if [[ -z "$OUTEXT" ]] ;then
  case $ACTION in
    c) OUTEXT=.gpg ;;
    d) OUTEXT=.txt ;;
  esac
fi

for INFILE in $* ;do
  OUTFILE=${OUTDIR}/$(basename ${INFILE%.*}$OUTEXT)
  warn "$ACTION: $INFILE => $OUTFILE"
  if [[ -d $INFILE ]] ;then
    print_usage "use tar -cvf $INFILE | gpg -c -o $OUTFILE"
  fi
  if [[ -e $OUTFILE && $OVERWRITE -eq 0 ]] ;then
    print_usage "Use -w to overwrite $OUTFILE" 
  fi
  if [[ "$INFILE" == "$OUTFILE" ]] ;then
    print_usage "Same OUTFILE==INFILE=$INFILE"
  fi
  get_pass
  case $ACTION in
  c) echo "$GPASS" |
    $GPG --passphrase-fd 0 --batch --yes -c -q --output "$OUTFILE" "$INFILE"
    ;;
  d) echo "$GPASS" |
    $GPG --passphrase-fd 0 --batch --yes -d -q --output "$OUTFILE" "$INFILE"
    ;; 
  *) print_usage "ACTION $ACTION not supported" ;;
  esac
done
