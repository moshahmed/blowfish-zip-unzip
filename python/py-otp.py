PY_OTP_USAGE = '''
What: generate token from seed
USAGE: echo NAME:SEED | python py-otp.py PATTERN -
Date:  2021-03-12 moshahmed/at/gmail
Setup:
  Install python3 and pip install pyotp cryptography
  See https://pyotp.readthedocs.io/en/latest/
Test pyotp with xx and demo.txt:
  $ echo xx |python -c "import pyotp,re,sys;seed=sys.stdin.readline();seed=re.sub(r'\W+','',seed);print(pyotp.TOTP(seed).now())"
    158726
  $ echo '
    aws1:JBSW-Y3DP-EHPK-3PXP
    aws2:ZZXW6-33PN5X-W6MZX
    QR-Code:otpauth://totp/aws3?secret=JBSWY3DPEHPK3PXP&issuer=self
  ' > demo.txt
Example usage:
  $ echo 'my/aws1/comment:JBSWY3DPEHPK3PXP' | python py-otp.py aws1
    332556 aws1
Use with gpg
  $ gpg -o  demo.gpg -qc demo.txt
  $ gpg -qd demo.gpg | python py-otp.py aws1
    pass:fkey
    332556 aws1
Use with ccrypt:
  $ wget http://ccrypt.sourceforge.net/download/1.11/ccrypt-1.11.tar.gz
  $ tar -xvf ccrypt-1.11.tar.gz ; cd ccrypt-1.11 ; ./configure ; make ; make install
  $ ccrypt -eK fkey demo.txt  # writes encrypted demo.txt.cpt
  $ ccrypt -c       demo.txt.cpt | python py-otp.py aws1
    pass:fkey
    332556 aws1
  OR
  $ ccrypt -ck fkey demo.txt.cpt | perl -lne 'print if s/aws1.*://' |
    python -c "import pyotp,re,sys;print(pyotp.TOTP(re.sub(r'\W+','',sys.stdin.readline())).now())" |
    gclip # Now paste from clipboard
  OR
  $ vim demo.txt.cpt
    pass:fkey
    : '<,'> w ! python 'import pyotp,sys; print(pyotp.TOTP(sys.stdin.readline()).now())'
Use from vim
  $ echo ': command MoshGauthOtp : . w ! python py-otp.py' >> ~/.vimrc
  $ vim -x demo.txt
    pass:fkey
      :/aws1
      <CURSOR_ON_LINE> aws1:JBSW-Y3DP-EHPK-3PXP
      : MoshGauthOtp
      OR
      : . w ! python py-otp.py aws1
      OR <visual-select SEED>
      : '<,'> w ! python py-otp.py aws1
        | 332556 aws1
      :q
  $
'''

import pyotp
import sys, re

def get_pyotp(line, pattern=''):
  # Input line is NAME:SEED and PATTERN =~ LINE
  if pattern and not re.search(pattern,line):
    return None, None
  qrcode = re.search(r'totp/(\w+).*secret=(\w+)',line)
  if qrcode:
    name = qrcode.group(1)
    seed = qrcode.group(2)
  elif re.match(r'^.+:.+$',line):
    name, seed = line.rsplit(':', 1)
  else:
    name, seed = '', line

  seed = re.sub(r'\W+', '', seed)
  if not seed:
    return None, None
  try:
    otp = pyotp.TOTP(seed).now()
    return otp, name
  except:
    return None, None

def demo_pyotp():
  line ="aws1/demo:JBSW-Y3DP-EHPK-3PXP"
  pattern = 'demo'
  otp, name = get_pyotp(line, pattern)
  print("Example:")
  print(f"  $ echo '{line}' | python py-otp.py {pattern}")
  print(f"    | otp={otp} {name}")

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print(PY_OTP_USAGE)
    demo_pyotp()
    sys.exit()

  pattern = sys.argv[1]
  for line in sys.stdin:
    otp, name = get_pyotp(line,pattern)
    # print(f'DEBUG: otp={otp}, pattern={pattern}, name={name}, line={line.rstrip()}')
    if otp:
      print(f'{otp} {name}')
