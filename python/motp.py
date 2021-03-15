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
What: print otp for domain from seed in motp file.

  Encrypt a set of appkeys in a python file, to be decrypted only when needed with a masterpass.
  appkeys are decrypted from lkeys.py with masterpass at runtime only when needed.
  The file lkeys.py can contain both encrypted and plaintext appkeys.
  The file '-' is stdin and stdout.
  Masterpass can be a 'string' or '$env_var' (from env) or '-' (from keyboard)

  Fernet from stackoverflow
  GPL(C) moshahmed/at/gmail

Examples:

Encrypt single string 'hello' into 'xyzab':
  $ python motp.py -e hello masterpass
    xyzab

Decrypt single string 'xxxab' back to 'hello':
  $ python motp.py -d xxxab masterpass
    hello

Encrypt all appkeys in plaintext.py file with masterpass (from keyboard):
  $ cat plaintext.py
    appkey="hello"
  $ python motp.py -f plaintext.py lkeys.py -
    password:masterpass
  $ cat lkeys.py
    appkey="xxxab"

Encrypt plaintext.py with motp.py inside vim:
  $ vim plaintext.py
    :silent 1,$ !python motp.py --fileenc - - $fkey
      fkey:masterpass
    :w lkeys.py

Decrypt all keys in a lkeys.py file with masterpass (in env var):
  If the input is too short, it is assumed to be plain text, and returned as is.
  If the key cannot be decrypted, program throws an error.
  $ export mkey=masterpass
  $ cat lkeys.py
    appkey="xxxab"
  $ python motp.py -D lkeys.py - '$mkey'
    appkey="hello"

Sample usage as python library from app.py:
  $ cat plaintext.py
    appkey="hello"
  $ export mkey=masterpass
  $ python motp.py -f plaintext.py lkeys.py  '$mkey'
  $ cat lkeys.py
    appkey="xxxab"
  $ cat app.py
    import motp
    realkey = motp.decryptedkey('appkey', passwd='$mkey', infile='lkeys.py')
    # use realkey in api call
  $ python app.py
'''

g_args = None

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
  if not passwd or passwd == 'keyboard' or passwd == '-':
    passwd=getpass.getpass('passwd:')
  if not passwd:
    log.error('No passwd')
    sys.exit(1)
  return passwd

def summary_pass256(line, prefix=2):
  dig = sha256(line.encode('utf-8')).hexdigest()
  return dig[:prefix]

def encrypt_cred_file(infile, outfile, passwd, enc_or_dec='enc'):
  todays = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

  if infile == '-':
    ifp = sys.stdin
  else:
    ifp = open(infile)

  if outfile == '-':
    ofp = sys.stdout
  else:
    ofp = open(outfile, "w")

  passwd256 = summary_pass256(passwd)

  if outfile != '-':
    print(    '# %s file %s to %s on %s with hash(pass)=%s..'   % (enc_or_dec,infile,outfile,todays,passwd256))
  if g_args.verbose:
    ofp.write('# %s file %s to %s on %s with hash(pass)=%s..\n' % (enc_or_dec,infile,outfile,todays,passwd256))

  for line in ifp:
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

  if outfile != '-':
    ofp.close()

def decryptedkey(akey, passwd='$mkey', infile='lkeys.py'):
  # exported library function
  passwd = get_pass(passwd)

  if infile == '-':
    ifp = sys.stdin
  else:
    ifp = open(infile)

  for line in ifp:
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

def show_totp(adomain, passwd='$mkey', infile='lkeys.py'):
  passwd = get_pass(passwd)
  lineno,found=0,0

  if infile == '-':
    ifp = sys.stdin
  else:
    ifp = open(infile)

  for line in ifp:
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

def g_args_parse():
    parser = argparse.ArgumentParser(
      description='''# What: Protect strings in a python file with a master passwd''',
      epilog='')
    parser.add_argument('-e', '--strenc',  nargs=2, help='encrypt_str  TEXT PASSWD')
    parser.add_argument('-d', '--strdec',  nargs=2, help='decrypt_str  TEXT PASSWD')
    parser.add_argument('-g', '--keydec',  nargs=3, help='decrypt_file INFILE KEYNAME PASSWD')
    parser.add_argument('-D', '--filedec', nargs=3, help='decrypt_file INFILE OUTFILE PASSWD')
    parser.add_argument('-f', '--fileenc', nargs=3, help='encrypt_file INFILE OUTFILE PASSWD')
    parser.add_argument('-t', '--totp',    nargs=3, help= 'topt_domain INFILE ADOMAIN PASSWD')
    parser.add_argument('-u', '--usage',   help='show usage', action='store_true', default=False)
    parser.add_argument('-v', '--verbose', help='verbose',    action='store_true', default=False)
    parser.parse_args()
    global g_args
    g_args = parser.parse_args()

if __name__ == '__main__':
  g_args_parse()

  if g_args.verbose:
      log.basicConfig(format="%(levelname)s: %(message)s", level=log.DEBUG)
  else:
      log.basicConfig(format="%(levelname)s: %(message)s")

  if g_args.usage:
    print(MOLOCK_USAGE)
    sys.exit()

  if g_args.strenc:
    dtoken, passwd = g_args.strenc
    passwd = get_pass(passwd)
    etoken = encrypt_token(dtoken,passwd)
    print('# etoken(d=%s,p=%s)=\n"%s"' % (dtoken,passwd,etoken))

  elif g_args.strdec:
    etoken, passwd = g_args.strdec
    passwd = get_pass(passwd)
    dtoken = decrypt_token(etoken,passwd)
    print('# dtoken(e=%s,p=%s)=\n"%s"' % (etoken,passwd,dtoken))

  elif g_args.fileenc:
    infile, outfile, passwd = g_args.fileenc
    passwd = get_pass(passwd)
    try:
      encrypt_cred_file(infile,outfile,passwd,'enc')
    except:
      print('fileenc Error %s' % (infile))

  elif g_args.filedec:
    infile, outfile, passwd = g_args.filedec
    passwd = get_pass(passwd)
    try:
      encrypt_cred_file(infile,outfile,passwd,'dec')
    except:
      print('filedec Error %s' % (infile))

  elif g_args.keydec:
    infile, keyname, passwd = g_args.keydec
    result = decryptedkey(keyname,passwd,infile)
    print("# infile:%s keyname:%s passwd:%s result:%s" % (infile, keyname, passwd, result))

  elif g_args.totp:
    infile, adomain, passwd = g_args.totp
    show_totp(adomain,passwd,infile)

  else:
    print("Try --help")
