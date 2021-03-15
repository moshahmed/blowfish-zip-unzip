PY_ONETIMEPASS_USAGE='''
Usage:
| Setup: install python3 and pip install onetimepass
| from   https://github.com/tadeck/onetimepass
|$ echo 'aws1/2021-03-12:JBSW-Y3DP-EHPK-3PXP' | python py-onetimepass.py aws1 -
|  332556 aws1
|$ python -c "import onetimepass;print('%06d'%onetimepass.get_totp('MFRGGZDFMZTWQ2LK'))"
|  332556
'''

import onetimepass
import sys, re

def get_pyotp(line, pattern=''):
  # from py_otp.py
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
    otp = onetimepass.get_totp(line)
    otp = "%06d" % otp # Leading zeroes in h cannot be ignored?
  except:
    return
  return otp

def demo_pyotp():
    # Demo1
    seed = 'MFRGGZDFMZTWQ2LK'
    token = onetimepass.get_totp(seed)
    print(f'| onetimepass: {token}')
    # Demo2
    pattern='aws1'
    line = pattern+':'+seed
    otp = get_pyotp(line,pattern)
    print(f'| onetimepass for {pattern}:{otp}')

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print(PY_ONETIMEPASS_USAGE)
    demo_pyotp()
    sys.exit()

  pattern = sys.argv[1]
  for line in sys.stdin:
    otp = get_pyotp(line,pattern)
    # print("DEBUG: %s %s %s" % (otp,pattern,line))
    if otp:
      print(f'{otp} {pattern}')
