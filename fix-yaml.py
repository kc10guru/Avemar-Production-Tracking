import sys
f = 'docker-compose.yml'
data = open(f, 'rb').read()
clean = bytearray()
for b in data:
    if b == 0x1b or b == 0x7e:
        continue
    if b == 0x5b and len(clean) > 0 and clean[-1:] == b'\x1b':
        continue
    clean.append(b)
out = clean.decode('utf-8', errors='ignore')
if 'SMTP_PASS' in out:
    lines = out.split('\n')
    for i, line in enumerate(lines):
        if 'GOTRUE_SMTP_PASS' in line:
            lines[i] = '      GOTRUE_SMTP_PASS: itjqxkdcmxhcmjyn'
    out = '\n'.join(lines)
open(f, 'w').write(out)
print('docker-compose.yml cleaned')
