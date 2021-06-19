GAUTH_USAGE = '''
What: Convert seed into gauth otp, called from vim, otp to clipboard

Usage:
> pip3 install pyotp
> echo "aws1 : x x" | python gauth-pyotp.py aws1

Test pyotp without this script:
> python -c "import pyotp,sys; print(pyotp.TOTP(sys.argv[1]).now()) " xx
  123456
> echo "aws1:x x" |
  python -c "import pyotp,re,sys;
    seed=sys.stdin.readline(); seed=re.sub('.*:','',seed); seed=re.sub(r'\W+','',seed);
    print(pyotp.TOTP(seed).now())" |
  gclip
  :: 123456 -- Paste from clipboard
'''

import re,sys
import pyotp
import subprocess

def otp2clipboard(otp):
  subprocess.run(['gclip'], input=otp, encoding='ascii')

def seed2otp(seed,domain):
  seed = re.sub(r'[^A-Za-z2-7]+','',seed)      # x-x => xx, base32
  # convert seed to otp
  otp = pyotp.TOTP(seed).now()       # x-x => 123456
  # Print otp
  sys.stderr.write("%6s -- %s\n" %(otp,domain))
  otp2clipboard(otp)
  return otp

def line2seed(line,pattern):
  # Get seed from line
  if pattern and not pattern.search(line):
    return
  if ':' in line:
    domain,seed = line.rsplit(':',1) # aws1:x-x => [aws1, xx]
  else:
    domain,seed = 'none',line        # x-x => [none, x-x]
  otp = seed2otp(seed,domain)
  return otp

if __name__ == '__main__':
  # line = sys.stdin.readline()
  if len(sys.argv) > 1 :
    pat_domain = sys.argv[1]
  else:
    pat_domain = '.'
  if pat_domain == '-h':
    print(GAUTH_USAGE)
    sys.exit()
  for line in sys.stdin:
    pattern = re.compile(pat_domain)
    line2seed(line,pattern)
