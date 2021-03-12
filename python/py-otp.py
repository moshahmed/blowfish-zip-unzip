# See https://pyotp.readthedocs.io/en/latest/

PY_OTP_USAGE = '''
USAGE: echo NAME:SEED | python py-otp.py PATTERN -
2021-03-12 moshahmed/at/gmail
Setup:
  Install python3 and pip install pyotp cryptography
Example:
  $ echo 'my/aws1/comment:JBSWY3DPEHPK3PXP' | python py-otp.py aws1 -
    332556 aws1
OR
  echo '
    aws1:JBSW-Y3DP-EHPK-3PXP
    aws2:ZZXW6-33PN5X-W6MZX
  ' | gpg -o  demo.gpg -qc
  $ gpg -qd demo.gpg | python py-otp.py aws1 -
    pass:fkey
    332556 aws1
'''

import pyotp, sys, re

def get_pyotp(line, pattern=''):
  # Input line is NAME:SEED and PATTERN =~ LINE
  if pattern and not re.search(pattern,line):
    return
  if not re.search(r'.+:.+',line):
    return
  line = re.sub(r'^.*:', '', line)
  line = re.sub(r'\W+', '', line)
  if not line:
    return
  otp = pyotp.TOTP(line).now()
  return otp

if __name__ == '__main__':

  if len(sys.argv) < 2:
    print(PY_OTP_USAGE)
    line ="aws1/demo:JBSW-Y3DP-EHPK-3PXP"
    print("Example: echo '%s' | python py-otp.py aws -" % line)
    print('Output: otp:%s' % (get_pyotp(line, 'demo')))
    sys.exit()

  pattern = sys.argv[1]
  for line in sys.stdin:
    otp = get_pyotp(line,pattern)
    # print("DEBUG: %s %s %s" % (otp,pattern,line))
    if otp:
      print("%s %s" % (otp,pattern))
