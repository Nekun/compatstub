# Defaults to build C example with MSVC in windows command prompt
# Replace to appropriate commands for building in *nix environment

# Should be compatible with GNU make and NMAKE

FASM=fasm
CC=cl
LD=link
DEL=del

all: stub_type0.exe stub_type1.exe
examples: hello_fasm.exe hello_link32.exe

stub_type0.exe: stub_type0.asm compatstub.asm
	$(FASM) stub_type0.asm $@

stub_type1.exe: stub_type1.asm compatstub.asm
	$(FASM) stub_type1.asm $@

hello_fasm.exe: hello_fasm.asm stub_type0.exe
	$(FASM) hello_fasm.asm $@

hello_link32.exe: hello_link32.obj stub_type1.exe
	$(LD) $(LDFLAGS) /stub:stub_type1.exe /out:$@ hello_link32.obj
hello_link32.obj: hello_link32.c
	$(CC) $(CFLAGS) /c /Fo$@ hello_link32.c

clean:
	$(DEL) *.obj *.exe

.PHONY: all examples clean
