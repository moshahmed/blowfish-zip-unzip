# Author: GPL(C) moshahmed
import time, re,sys, gnupg

USAGE = '''
What: grep gpg files
Usage: python gpg-grep.py regex passwd *.gpg
Example:
  echo line1  >  tmp.txt
  echo line2 >>  tmp.txt
  gpg -o tmp.gpg --passphrase xyz --batch --yes -qc tmp.txt
  gpg            --passphrase xyz --batch --yes -qd tmp.gpg | grep line2
    passwd:xyz
    line2
  rm tmp.txt
  python gpg-grep.py line2 keyboard tmp.gpg
    passwd:xyz
    line2
'''

def gpg_grep(regex,infile,passwd):
    gpg = gnupg.GPG()
    ifp = open(infile, 'rb')
    dd = gpg.decrypt_file(ifp, passphrase=passwd)
    if not dd.ok:
      print('cannot decrypt file=%s' % infile)
      return
    lst = str(dd)
    lst = lst.splitlines()
    lst = filter(regex.search,lst)
    for line in lst:
      print(line)

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
    if len(sys.argv) <= 3:
        print(USAGE)
        sys.exit()
    regex = re.compile(sys.argv[1])
    passwd = sys.argv[2]
    for infile in sys.argv[3:]:
      gpg_grep(regex, infile, passwd)
