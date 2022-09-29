echo "== Encrypt string using ssh PUBKEYFILE, decrypt using ssh PRVKEYFILE" 
PRVKEYFILE=age-test2.pem
PUBKEYFILE=$PRVKEYFILE.pub

rm -f $PRVKEYFILE $PUBKEYFILE

echo "== Generating PRVKEYFILE PASSPHRASE and PUBKEYFILE"
read -s -p "ssh PRVKEYFILE PASSPHRASE (5char or more, or blank):" PASSPHRASE 

echo "== "
echo "ssh-keygen -P "$PASSPHRASE" -t rsa -b 4096 -mRFC4716 -f $PRVKEYFILE -q"
ssh-keygen -P "$PASSPHRASE" -t rsa -b 4096 -mRFC4716 -f $PRVKEYFILE -q

echo "== "
echo "== Encrypt date with PUBKEYFILE"
echo "== Decrypt with PRVKEYFILE (needs PASSPHRASE)"

date |
  age-enc -e -a -R $PUBKEYFILE |
  age-enc -d    -i $PRVKEYFILE -

rm -fv $PRVKEYFILE $PUBKEYFILE
