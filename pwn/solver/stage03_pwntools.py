
from pwn import *
io = remote('127.0.0.1', 7103, timeout=5)
print(io.recvline().decode().strip())
io.sendline(b'GIMME FLAG')
print(io.recvline().decode().strip())
