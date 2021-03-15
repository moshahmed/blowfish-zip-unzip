PY_GAUTH_USAGE = '''
Usage: echo NAME:SEED | python py-gauth.py NAME .. prints time based otp for NAME
What: Generate totp
From: https://stackoverflow.com/questions/8529265/google-authenticator-implementation-in-python
'''

import hmac, base64, struct, hashlib, time
import sys, re

def get_hotp_token(seed, intervals_no=1):
    # generates one-time token, invalidates after single use,
    seed = re.sub(r'\W+', '', seed)
    if not seed:
      return
    key = base64.b32decode(seed, True)
    msg = struct.pack(">Q", intervals_no)
    h = hmac.new(key, msg, hashlib.sha1).digest()
    o = h[19] & 15
    h = (struct.unpack(">I", h[o:o+4])[0] & 0x7fffffff) % 1000000
    h = "%06d" % h # Leading zeroes in h cannot be ignored?
    return h

def get_totp_token(seed):
    # generates token based on time (changed in 30-second intervals).
    return get_hotp_token(seed, intervals_no=int(time.time())//30)

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
    otp = get_totp_token(line)
    return otp
  except:
    return

def demo_totp():
    # Demo1
    seed = 'MZXW.633P N5XW-6MZX'
    print('# Demo of 10 single use tokens for seed=%s' % seed)
    for i in range(1, 10):
      token = get_hotp_token(seed, intervals_no=i)
      print( "| %8s | %12d |" % (token, i))
    # Demo2
    print('# Demo of time based token for seed=%s' % seed)
    now = int(time.time())//30;
    token = get_totp_token(seed)
    print( "| %8s | %12d |" % (token,now))

if __name__ == '__main__':
  if len(sys.argv) < 2:
    print(PY_GAUTH_USAGE)
    demo_totp()
    sys.exit()

  pattern = sys.argv[1]
  for line in sys.stdin:
    otp = get_pyotp(line,pattern)
    # print("DEBUG: %s %s %s" % (otp,pattern,line))
    if otp:
      print(f'{otp} {pattern}')
