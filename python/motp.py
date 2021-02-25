import os, sys, getpass, argparse, datetime, re
import logging as log
import secrets
import pyotp

from base64 import urlsafe_b64encode as b64e, urlsafe_b64decode as b64d
from cryptography.fernet import Fernet
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from hashlib import sha256

backend = default_backend()
iterations = 100_000

MOLOCK_USAGE = '''
What:
  Encrypt a set of appkeys in a python file, to be decrypted only when needed with a masterpass.
  appkeys are decrypted from lkeys.py with masterpass at runtime only when needed.
  masterpass can be a 'string', in an '$environment_variable' or to be read from 'keyboard'
  The file lkeys.py can contain both encrypted and plaintext appkeys.
  Here masterpass can be a 'string', in an '$environment_variable' or to be read from 'keyboard'
  From stackoverflow, additions GPL(C) moshahmed/at/gmail

Usage:

Encrypt single string 'hello' into 'xyzab':
  $ python molock.py -e hello masterpass

Decrypt single string 'xyzab' back into 'hello':
  $ python molock.py -d xxxab masterpass

Encrypt all appkeys in mykeys.py file with masterpass (read from the keyboard):
  $ cat mykeys.py
    appkey="hello"
  $ python molock.py -f mykeys.py   lkeys.py enc keyboard
    password:masterpass
  $ cat lkeys.py
    appkey="xxxab"

Decrypt all keys in a lkeys.py file with masterpass in env var:
If the key is too short, it is assumed to be plain text, and returned as is.
If the key cannot be decrypted, it throws an error and program stops.
  $ export mkey=masterpass
  $ python molock.py -f lkeys.py mykeys.py dec '$mkey'

Sample usage from python code:
  $ cat mykeys.py
    appkey="hello"
  $ export mkey=masterpass
  $ python molock.py -f mykeys.py lkeys.py  enc '$mkey'
  $ cat lkeys.py
    appkey="xxxab"
  $ cat app.py
    from molock import decryptedkey
    realkey = decryptedkey('appkey', passwd='$mkey', infile='lkeys.py')
    # make python api calls with realkey ...
  $ export mkey=masterpass
  $ python app.py
'''

def _derive_key(password: bytes, salt: bytes, iterations: int = iterations) -> bytes:
    """Derive a secret key from a given password and salt"""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(), length=32, salt=salt,
        iterations=iterations, backend=backend)
    return b64e(kdf.derive(password))

def encrypt_token(message: str, password: str, iterations: int = iterations) -> str:
    salt = secrets.token_bytes(16)
    key = _derive_key(password.encode(), salt, iterations)
    return b64e(
        b'%b%b%b' % (
            salt,
            iterations.to_bytes(4, 'big'),
            b64d(Fernet(key).encrypt(message.encode())),
        )
    ).decode()

def decrypt_token(token: bytes, password: str) -> str:
    decoded = b64d(token)
    salt, iter, token = decoded[:16], decoded[16:20], b64e(decoded[20:])
    iterations = int.from_bytes(iter, 'big')
    key = _derive_key(password.encode(), salt, iterations)
    return Fernet(key).decrypt(token).decode()

def get_pass(passwd):
  if passwd and passwd[0] == '$' and len(passwd)>1:
    envvar = passwd[1:]
    passwd = os.environ.get(envvar)
    if not passwd:
      log.error('No passwd in envvar $%s? set %s="passwd"' % (envvar,envvar))
  if not passwd or passwd == 'keyboard':
    passwd=getpass.getpass('passwd:')
  if not passwd:
    log.error('No passwd')
    sys.exit(1)
  return passwd

def summary2(line, prefix=2):
  dig = sha256(line.encode('utf-8')).hexdigest()
  return dig[:prefix]

def encrypt_cred_file(infile, outfile, passwd, enc_or_dec='enc'):
  todays = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
  ofp = open(outfile, "w")
  passwd256 = summary2(passwd)
  print(    '# %s file %s to %s on %s with hash(pass)=%s..'   % (enc_or_dec,infile,outfile,todays,passwd256))
  ofp.write('# %s file %s to %s on %s with hash(pass)=%s..\n' % (enc_or_dec,infile,outfile,todays,passwd256))
  for line in open(infile):
    line = line.strip().replace('\n','')

    # skip blank lines or comments
    if not line or re.match(rf'^\s*$',line):
      continue
    if re.match(rf'^\s*#',line):
      ofp.write(line+'\n')
      continue

    # Process lines matching, otherwise encrypt/decrypt whole line.
    #    =~ m/(    )(VAR  =")(VALUE)("                  )/
    #    = /(before)(varname)             (passin)(after)/
    #    => (before)(varname)encrypt_token(passin)(after)/
    pattern = re.compile(
      r'^(?P<before>[\s#]{0,2})'
      r'(?P<varname>\w+=")'
      r'(?P<passin>.+?)'
      r'(?P<after>"\s*)$'
    )
    ab = re.search( pattern, line)

    # Extract passin to process
    if ab:
      passin=ab.group('passin')
    else:
      passin=line

    # encrypt or decrypt passin
    if enc_or_dec == 'enc':
      passout = encrypt_token(passin,passwd)
    else:
      passout = decrypt_token(passin,passwd)

    # save passout to output file
    if ab:
      ofp.write('%s%s%s%s\n' % (ab.group('before'), ab.group('varname'),passout,ab.group('after')))
    else:
      ofp.write(passout+'\n')

  ofp.close()

def decryptedkey(akey, passwd='$mkey', infile='lkeys.py'):
  passwd = get_pass(passwd)
  for line in open(infile):
    if line[0] == '#':  # ignore comments
      continue
    ab = re.search(rf'^\s*{akey}="(.+)"', line)
    if ab:
      aval = ab.group(1)
      if len(aval) > 30:
        aval = decrypt_token(aval,passwd)
      else:
        log.info('akey %s value %s too small to decrypt?' % (akey, aval))
      return aval
  print('Cannot find akey=%s in file=%s' % (akey,infile))
  sys.exit(1)

def get_totp(adomain, passwd='$mkey', infile='lkeys.py'):
  passwd = get_pass(passwd)
  lineno,found=0,0
  for line in open(infile):
    lineno += 1
    line = line.strip().replace('\n','')

    # skip blank lines or comments
    if line == '' or re.match(rf'^\s*#',line):
      continue

    ab = re.search(rf'^(.*)="(.+)"', line)
    if ab:
      bval = ab.group(2)
    else:
      bval = line

    # decrypt bval
    try:
      bval_decrypted = decrypt_token(bval,passwd)
    except:
      log.info('Could not decrypt line %d="%s.."' % (lineno,bval[:10]))
      continue

    # split bval_decrypted into totp_name, totp_secret
    if not re.match(r'^.+:.+$',bval_decrypted):
      log.warn('No totp_name:totp_secret in %s on line %d' % (bval_decrypted,lineno))
      continue
    totp_name, totp_secret = bval_decrypted.rsplit(':', 1)


    # check totp_name matching adomain
    if not re.match(rf'^.*{adomain}.*$', totp_name):
      # log.info('skipping %s not matching %s on line %d' % (totp_name, adomain,lineno))
      continue

    # generate totp from totp_secret
    try:
      totp_secret = totp_secret.replace(' ','')
      totp = pyotp.TOTP(totp_secret)
      my_token = totp.now()
      print("pytop=%s  for %s" % (my_token,totp_name))
      found += 1
    except:
      log.warn('Bad seed:%s:%s.' % (totp_name, totp_secret))
      continue

  if found == 0:
    print('Cannot find adomain=%s in file=%s' % (adomain,infile))
    sys.exit(1)
  return

def get_args():
    parser = argparse.ArgumentParser(
      description='''# What: Protect strings in a python file with a master passwd''',
      epilog='')
    parser.add_argument('-d', '--dec', nargs=2, help='decrypts TEXT PASSWD')
    parser.add_argument('-e', '--enc', nargs=2, help='encrypts TEXT PASSWD')
    parser.add_argument('-f', '--fileenc', nargs=4, help='enc_or_dec INFILE OUTFILE ENC_OR_DEC PASSWD')
    parser.add_argument('-g', '--getdec', nargs=3, help= 'decrypts INFILE KEYNAME PASSWD')
    parser.add_argument('-t', '--totp', nargs=3, help= 'topt INFILE ADOMAIN PASSWD')
    parser.add_argument('-u', '--usage', help='show usage', action='store_true', default=False)
    parser.add_argument('-v', '--verbose', help='verbose', action='store_true', default=True)
    parser.parse_args()
    args = parser.parse_args()
    return args

if __name__ == '__main__':
  args = get_args()

  if args.verbose:
      log.basicConfig(format="%(levelname)s: %(message)s", level=log.DEBUG)
  else:
      log.basicConfig(format="%(levelname)s: %(message)s")

  if args.usage:
    print(MOLOCK_USAGE)
    sys.exit()

  if args.enc:
    dtoken, passwd = args.enc
    passwd = get_pass(passwd)
    etoken = encrypt_token(dtoken,passwd)
    print('# etoken(d=%s,p=%s)=\n"%s"' % (dtoken,passwd,etoken))

  elif args.dec:
    etoken, passwd = args.dec
    passwd = get_pass(passwd)
    dtoken = decrypt_token(etoken,passwd)
    print('# dtoken(e=%s,p=%s)=\n"%s"' % (etoken,passwd,dtoken))

  elif args.fileenc:
    infile, outfile, enc_or_dec, passwd = args.fileenc
    passwd = get_pass(passwd)
    try:
      encrypt_cred_file(infile,outfile,passwd,enc_or_dec)
    except:
      print('Error processing file %s' % (infile))

  elif args.getdec:
    infile, keyname, passwd = args.getdec
    result = decryptedkey(keyname,passwd,infile)
    print("# infile:%s keyname:%s passwd:%s result:%s" % (infile, keyname, passwd, result))

  elif args.totp:
    infile, adomain, passwd = args.totp
    get_totp(adomain,passwd,infile)

  else:
    print("Try --help")
