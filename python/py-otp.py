PY_OTP_USAGE = '''
What: generate token from seed
USAGE: echo NAME:SEED | python py-otp.py PATTERN -
Date:  2021-03-12 moshahmed/at/gmail
Setup:
  Install python3 and pip install pyotp cryptography
  See https://pyotp.readthedocs.io/en/latest/
Example usage:
  $ echo 'my/aws1/comment:JBSWY3DPEHPK3PXP' | python py-otp.py aws1
    332556 aws1
OR from bash and gpg
  echo '
    aws1:JBSW-Y3DP-EHPK-3PXP
    aws2:ZZXW6-33PN5X-W6MZX
    QR-Code:otpauth://totp/aws3?secret=JBSWY3DPEHPK3PXP&issuer=self
  ' > demo.txt
  $ gpg -o  demo.gpg -qc demo.txt
  $ gpg -qd demo.gpg | python py-otp.py aws1
    pass:fkey
    332556 aws1
OR from vim
  $ gvim -x demo.txt
      pass:fkey
      <CURSOR_ON_LINE> aws1:JBSW-Y3DP-EHPK-3PXP
      : command MoshGauthOtp : . w ! python py-otp.py ''
      : MoshGauthOtp
        : . w ! python py-otp.py aws1
          OR <visual-select SEED>
        : '<,'> w ! python py-otp.py aws1
          332556 aws1
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
