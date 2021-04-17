# What: How to sign, verify signature, encrypt, decrypt using openssl and ssh keys:
# Date 2021-04-15 Thu 19:36

# PASSPHRASE=$(shuf -zer -n20  {A..Z} {a..z} {0..9})
# PASSPHRASE=$(apn -n 1)
# PASSPHRASE=$(openssl rand -base64 12)
PASSPHRASE=$(openssl rand -hex 12)

# Needs ssh keys:
SSH_PRV_KEY=demokeys.pem # id_rsa
SSH_PUB_KEY=demokeys.pub # id_rsa.pub
SSH_PKS_KEY=demokeys.pub.pkcs8

# ln -s ~/.ssh/id_rsa     $SSH_PRV_KEY
# ln -s ~/.ssh/id_rsa.pub $SSH_PUB_KEY

echo Generate private key, must be PEM RSA key.
openssl genrsa -out $SSH_PRV_KEY -aes128 -passout pass:$PASSPHRASE 2048
# ssh-keygen -m PEM -t rsa -b 2048 -C "your_email@example.com" -P $PASSPHRASE -f $SSH_PRV_KEY
ssh-keygen -e -f $SSH_PRV_KEY -m PKCS8 -P $PASSPHRASE > $SSH_PKS_KEY

# Sign file with private key and later check signature with public key:
# Encrypt with public key and descrypt with private key:

FILE_TXT=test.txt 
FILE_ENC=test.enc
FILE_DEC=test.dec
FILE_SIG=test.sign

date > $FILE_TXT

echo encrypting $FILE_TXT to $FILE_ENC
openssl pkeyutl -encrypt -pubin -inkey $SSH_PKS_KEY -in $FILE_TXT -out $FILE_ENC

echo decrypting $FILE_ENC to $FILE_DEC
openssl pkeyutl -decrypt -inkey $SSH_PRV_KEY -in $FILE_ENC -out $FILE_DEC -passin pass:$PASSPHRASE

echo diff $FILE_DEC $FILE_TXT
diff $FILE_DEC $FILE_TXT

echo sign $FILE_TXT
openssl pkeyutl -sign -inkey $SSH_PRV_KEY -in $FILE_TXT -out $FILE_SIG -passin pass:$PASSPHRASE

echo verify sign $FILE_SIG
openssl pkeyutl -verify -pubin -inkey $SSH_PKS_KEY -in $FILE_TXT -sigfile $FILE_SIG

