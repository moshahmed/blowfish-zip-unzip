# https://stackoverflow.com/questions/8529265/google-authenticator-implementation-in-python
# get_hotp_token() generates one-time token (that should invalidate after single use),
# get_totp_token() generates token based on time (changed in 30-second intervals),

import hmac, base64, struct, hashlib, time, re,sys
import gnupg

USAGE = '''
# What: print topt for domain from seed in gpgotp.gpg file.
Usage: python gpgotp.py domain gauth.gpg passwd
Example:
  echo aws1:ZZZZZ 33PN5XW 6MZX  >  gpgotp.txt
  echo aws2:MZXW6 33PN5XW 6MZX >>  gpgotp.txt
  gpg -o gpgotp.gpg --passphrase xyz --batch --yes -qc gpgotp.txt
  gpg               --passphrase xyz --batch --yes -qd gpgotp.gpg | grep aws1
    pass:xyz
  rm gpgotp.txt
  python gpgotp.py aws1 gpgotp.gpg keybboard
    pass:xyz
    |   716402 |  aws1 | 0 |
'''

def get_hotp_token(secret, intervals_no):
    key = base64.b32decode(secret, True)
    msg = struct.pack(">Q", intervals_no)
    h = hmac.new(key, msg, hashlib.sha1).digest()
    o = h[19] & 15
    h = (struct.unpack(">I", h[o:o+4])[0] & 0x7fffffff) % 1000000
    return h

def get_totp_token(secret):
    return get_hotp_token(secret, intervals_no=int(time.time())//30)

def print_totp(title,secret,whence=1):
    secret = secret.strip().replace(' ','')
    for i in range(0, whence):
        token = get_hotp_token(secret, intervals_no=i)
        print( "| %8s |  %s | %i | " % (token, title, i))

def get_seeds(domain='aws',infile='gpgotp.gpg',passwd='fkey'):
    gpg = gnupg.GPG()
    ifp = open(infile, 'rb')
    dd = gpg.decrypt_file(ifp, passphrase=passwd)
    if not dd.ok:
      print('cannot decrypt file=%s' % infile)
      sys.exit()
    lst = str(dd)
    lst = lst.splitlines()
    lst = filter(lambda aline: domain in aline, lst)
    # regex = re.compile(rf'.*{domain}.*:.+')
    # lst = filter(regex.search,lst)
    return lst

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

if __name__ == '__main__':
    # Process args
    if len(sys.argv) <= 3:
        print(USAGE)
        sys.exit()
    domain = sys.argv[1]
    infile = sys.argv[2]
    passwd = get_pass(sys.argv[3])

    # Process domain seeds in infile.
    lst = get_seeds(domain,infile,passwd)
    for line in lst:
        ab = re.search(rf'^(.*):(.+)', line)
        if not ab:
            continue
        title, secret = ab.group(1), ab.group(2)
        print_totp(title,secret)
