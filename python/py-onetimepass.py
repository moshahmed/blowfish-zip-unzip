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
    otp = onetimepass.get_totp(seed)
    otp = "%06d" % otp # Leading zeroes in h cannot be ignored?
    return otp, name
  except:
    return None, None

def demo_pyotp():
    # Demo1
    seed = 'MFRGGZDFMZTWQ2LK'
    token = onetimepass.get_totp(seed)
    print(f'| onetimepass: {token}')
    # Demo2
    pattern='aws1'
    line = pattern+':'+seed
    otp, name = get_pyotp(line,pattern)
    print(f'| onetimepass for {name}:{otp}')

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print(PY_ONETIMEPASS_USAGE)
    demo_pyotp()
    sys.exit()

  pattern = sys.argv[1]
  for line in sys.stdin:
    otp, name = get_pyotp(line,pattern)
    # print(f'DEBUG: otp={otp}, pattern={pattern}, name={name}, line={line.rstrip()}')
    if otp:
      print(f'{otp} {name}')
