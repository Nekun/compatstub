--- ABSOLUTELY COMPATIBLE DOS STUB ---
This is a PE DOS stub program intended to be
compatible with very ancient MS[PC]-DOS 1.00-1.25, 
where is MZ EXE format was not stabilized.

This is free and unencumbered software released
into the public domain.

Most of stubs uses functions from DOS 2.0+ API
(such as int21h/4Ch for exit to DOS), but main
problem that is DOS 1.x EXE loader expects MZ
header to be aligned with "page" (512b chunks)
boundary and small EXEs without relocations
doesn't loads completely or loads to wrong offset.

We try to assemble manually two variants of
the stub EXE: the first one (type0) contains old 
32-byte header and PE linker should align it properly 
in resulting file after adding additional fields 
in MZ header (offset to PE and some reserved stuff).
The second variant (type1) is already contains "new"
64-byte header, so PE linker should just insert
them in PE and overwrite offset to PE field.

--- BUILDING ---
You need only FASM assembler to build stubs. Run
"fasm stub_type{0,1}.asm stub_type{0,1}.exe" or
issue default target in the provided Makefile.
Makefile should be compatible with GNU make and
NMAKE, but for *nixes you may need to adjust some
variables.

--- LINKING ---
I observed only two linkers which allows to change the
default stub: FASM formatter and Microsoft link.exe

FASM: use stub_type0, pass "on" operator in format directive:
format PE GUI 4.0 on 'stub_type0.exe'

LINK.EXE: use stub_type1, pass /stub:stub_type1.exe to
linker options

GNU LD: no option for replacing default stub in COFF module

LLVM LLD: lld-link has similiar with link.exe /stub option, but 
it has no effect at the moment
