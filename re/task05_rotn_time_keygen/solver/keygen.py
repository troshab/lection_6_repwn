#!/usr/bin/env python3
import sys, time, string

def rot(txt, n):
    out = []
    for ch in txt:
        if 'a' <= ch <= 'z':
            out.append(chr(ord('a') + (ord(ch)-ord('a') + n)%26))
        elif 'A' <= ch <= 'Z':
            out.append(chr(ord('A') + (ord(ch)-ord('A') + n)%26))
        else:
            out.append(ch)
    return ''.join(out)

def main():
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <name>")
        sys.exit(1)
    name = sys.argv[1]
    n = int(time.time()) % 20
    serial = rot(name, n)
    print(serial)

if __name__ == "__main__":
    main()
