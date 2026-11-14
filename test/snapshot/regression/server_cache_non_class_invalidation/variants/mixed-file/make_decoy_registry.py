"""Writes a HookName.hx that makes byte offsets and character offsets disagree.

Usage: make_decoy_registry.py NOTE HOOK OUTPUT

The file holds, in this order: a comment line of `é` characters, a comment
that looks like the start of the class, a `@:phxHookNames` registry with one
entry HOOK, and the class `HookNameNotes` whose `note()` returns NOTE.

A Haxe position counts characters. Each `é` is one character and two bytes.
The number of `é` characters is chosen so that the class position, read as
byte offsets, starts at the comment that looks like the class and ends at a
`}` inside the class. A compiler that cuts bytes at character offsets then
removes the registry from its comparison, and a change of HOOK is not seen.
"""
import sys

note, hook, output = sys.argv[1], sys.argv[2], sys.argv[3]
decoy = "/*class HookNameNotes {*/\n"
registry = '@:phxHookNames\nenum abstract HookName(String) from String to String {\n\tvar %s = "%s";\n}\n' % (hook, hook)
shift = len((decoy + registry).encode()) - 2
head = "// " + "é" * shift + "\n"
body = 'class HookNameNotes {\n\tpublic static function note():String {\n\t\treturn "%s";\n\t}' % note
body += " " * (shift - 1) + "}\n"
with open(output, "wb") as target:
    target.write(("package;\n" + head + decoy + registry + body).encode())
