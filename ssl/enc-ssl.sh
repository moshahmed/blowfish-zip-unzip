# What: How to sign, verify signature, encrypt, decrypt using openssl and ssh keys:
# Date 2021-04-15 Thu 19:36


# Needs ssh keys:
SSH_PAS_PHR=demokeys.pas
SSH_PRV_KEY=demokeys.pem # id_rsa
SSH_PUB_KEY=demokeys.pub # id_rsa.pub
SSH_PKS_KEY=demokeys.pub.pkcs8

# ln -s ~/.ssh/id_rsa     $SSH_PRV_KEY
# ln -s ~/.ssh/id_rsa.pub $SSH_PUB_KEY

echo Generating PASSPHRASE in $SSH_PAS_PHR
# PASSPHRASE=$(shuf -zer -n20  {A..Z} {a..z} {0..9})
# PASSPHRASE=$(apn -n 1)
# PASSPHRASE=$(openssl rand -hex 8)
PASSPHRASE=P-$(openssl rand -base64 8| tr -dc 'a-zA-Z0-9'| cut -c1-8)

LANG=C LC_ALL=C PASSPHRASE_LEN=${#PASSPHRASE}
if [[ "$PASSPHRASE_LEN" -lt 5 ]] ;then
  echo "Need len(PASSPHRASE) >= 5"
  exit
fi 
echo -n $PASSPHRASE > $SSH_PAS_PHR

echo Generate private key $SSH_PRV_KEY must be PEM RSA key, with pass:$PASSPHRASE
openssl genrsa -out $SSH_PRV_KEY -aes128 -passout pass:$PASSPHRASE 2048
# ssh-keygen -m PEM -t rsa -b 2048 -C "mosh@example.com" -P $PASSPHRASE -f $SSH_PRV_KEY

echo Extract pub pkcs8 key $SSH_PKS_KEY from private key
ssh-keygen -e -f $SSH_PRV_KEY -m PKCS8 -P $PASSPHRASE > $SSH_PKS_KEY

FILE_TXT=test.txt
FILE_ENC=test.enc
FILE_DEC=test.dec
FILE_SIG=test.sign

date > $FILE_TXT

# Encrypt with public key and decrypt with private key:
echo Encrypting $FILE_TXT to $FILE_ENC
openssl pkeyutl -encrypt -pubin -inkey $SSH_PKS_KEY -in $FILE_TXT -out $FILE_ENC

echo Decrypting $FILE_ENC to $FILE_DEC
openssl pkeyutl -decrypt -inkey $SSH_PRV_KEY -in $FILE_ENC -out $FILE_DEC -passin pass:$PASSPHRASE

echo diff $FILE_DEC $FILE_TXT
diff $FILE_DEC $FILE_TXT

# Sign file with private key
echo Sign $FILE_TXT
openssl pkeyutl -sign -inkey $SSH_PRV_KEY -in $FILE_TXT -out $FILE_SIG -passin pass:$PASSPHRASE

# Check sig with pks public key:
echo Verify sign $FILE_SIG
openssl pkeyutl -verify -pubin -inkey $SSH_PKS_KEY -in $FILE_TXT -sigfile $FILE_SIG

