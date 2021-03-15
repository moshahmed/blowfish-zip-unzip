PY_OTP_USAGE = '''
What: generate token from seed
USAGE: echo NAME:SEED | python py-otp.py PATTERN -
Date:  2021-03-12 moshahmed/at/gmail
Setup:
  Install python3 and pip install pyotp cryptography
  See https://pyotp.readthedocs.io/en/latest/
Example:
  $ echo 'my/aws1/comment:JBSWY3DPEHPK3PXP' | python py-otp.py aws1
    332556 aws1
OR
  echo '
    aws1:JBSW-Y3DP-EHPK-3PXP
    aws2:ZZXW6-33PN5X-W6MZX
  ' | gpg -o  demo.gpg -qc
  $ gpg -qd demo.gpg | python py-otp.py aws1
    pass:fkey
    332556 aws1
OR from inside vim
  > vi -x seeds.txt
      pass:fkey
      <CURSOR_ON_LINE> aws1/comment:JBSW-Y3DP-EHPK-3PXP
      : command MoshGauthOtp : . w ! python py-otp.py ''
      : MoshGauthOtp
      : . w ! python py-otp.py aws1
      OR <visual-select SEED>
      : '<,'> w ! python py-otp.py
      vi show otp 332556
'''

import pyotp
import sys, re

def get_pyotp(line, pattern=''):
  # Input line is NAME:SEED and PATTERN =~ LINE
  if pattern and not re.search(pattern,line):
    return
  qrcode = re.search(r'secret=(\w+)',line)
  if qrcode:
    line = qrcode.group(1)
  else:
    line = re.sub(r'^.*:', '', line)
  line = re.sub(r'\W+', '', line)
  if not line:
    return
  try:
    otp = pyotp.TOTP(line).now()
    return otp
  except:
    return

def demo_pyotp():
  line ="aws1/demo:JBSW-Y3DP-EHPK-3PXP"
  pattern = 'demo'
  otp = get_pyotp(line, pattern)
  print("Example:")
  print(f"  $ echo '{line}' | python py-otp.py {pattern}")
  print(f"    | otp={otp} {pattern}")

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print(PY_OTP_USAGE)
    demo_pyotp()
    sys.exit()

  pattern = sys.argv[1]
  for line in sys.stdin:
    otp = get_pyotp(line,pattern)
    # print("DEBUG: %s %s %s" % (otp,pattern,line))
    if otp:
      print("%s %s" % (otp,pattern))
