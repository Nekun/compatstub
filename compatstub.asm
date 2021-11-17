; --- ABSOLUTELY COMPATIBLE DOS STUB ---
; This is a PE DOS stub program intended to be
; compatible with very ancient MS[PC]-DOS 1.00-1.25, 
; where is MZ EXE format was not stabilized.
;
; Most of stubs uses functions from DOS 2.0+ API
; (such as int21h/4Ch for exit to DOS), but main
; problem that is DOS 1.x EXE loader expects MZ
; header to be aligned with "page" (512b chunks)
; boundary and small EXEs without relocations
; doesn't loads completely or loads to wrong offset.
;
; We try to assemble manually such EXE that is
; PE linker aligns properly in resulting file
; after adding additional fields in MZ header
; (offset to PE and some reserved stuff)
; So, stub itself is not compatible with DOS 1.x,
; however it's valid EXE for DOS 2.0+ which is
; commonly known as "real", forward-compatible 
; DOS environment. But after linking to PE, all
; offsets and pointers should be adjusted to reach
; compatibility even with its unstable predecessor,
; without directories, boot signatures, installable
; drivers, environment variables, very rudimentary
; batch scripting even without GOTO,IF,FOR and so on.

use16
org 0

; Size of loadable image
loadsz = 512    

; Size of expected MZ header (incl. relocs) after being merged to PE
trgheadsz = 512 

; Size of standard MZ header in PE (incl. "new" post-dos fields)
peheadsz = 64   

; Number of relocation entries to reach target header size
; after merging to PE
relcnt = (trgheadsz-peheadsz) / 4

; Number of paragraphs in header (incl. relocs)
headsz_p = (startrel+relcnt*4) / 16

; Number of 512b pages in file
pagenum = (loadsz+startrel+relcnt*4) / 512

; Size of the last page or zero if it has a maximum size
pagerem = (loadsz+startrel+relcnt*4) mod 512

; Fixup for accomplish ceil-dividing
if pagerem > 0
    pagenum = pagenum + 1
end if

; -- MZ HEADER --
e_magic     db "MZ"     ; MZ signature
e_cblp      dw pagerem  ; Size of the last page or zero if it 
                        ; | has maximal size. 
                        ; | In DOS 1.x this field is ignored
e_cp        dw pagenum  ; Number of 512b pages in file
                        ; | In DOS 1.x all pages must be 512b
e_crlc      dw relcnt   ; Number of dword relocation entries
e_cparhdr   dw headsz_p ; Size of header in 16b chunks
                        ; | In DOS 1.x header must be aligned
                        ; | at page boundary (512b)
e_minalloc  dw 0        ; Required uninitialized data region
                        ; | in 16b chunks above load module
                        ; | In DOS 1.x this field is ignored
e_maxalloc  dw 0        ; Maximal uninitialized data region
                        ; | in 16b chunks above load module
                        ; | In DOS 1.x this field has other
                        ; | meaning: FFFFh to load module 
                        ; | at highest possible segment, otherwise
                        ; | load module at caller (command.com)
                        ; | segment
e_ss        dw 0        ; Initial relative stack segment, 
                        ; | set to single first one
e_sp        dw stk      ; Initial stack pointer
                        ; | we don't use stack directly, but intcalls
                        ; | on x86 uses them to save environment, so
                        ; | leave a room on top of our allocated segment
e_csum      dw 0        ; Checksum of whole file, if you know any
                        ; | system which check it, please tell me
e_ip        dw run      ; Entry point
e_cs        dw 0        ; Relative code segment, set to
                        ; | single first one
e_lfarlc    dw startrel ; Offset to the first relocation entry

; Some linkers (like FASM) automatically adjusts standard 2-paragraph MZ header
; and appending additional fields, but some others (like MS LINK) expects
; these fields already exists and just writes PE pointer to lfanew offset.
; We support assemling executables for both cases.
if ~ defined headertype
display "headertype must be defined",0x0d,0x0a
err
else if headertype=0
_align      dw 0,0,0    ; Fill in remaining space in paragraph to
                        ; | ensure PE linker to align MZ stuff properly
else if headertype=1
e_ovno      dw 0
e_sym_tab   dd 0
e_flags     dw 1        ; EKNOWEAS flag just to make some linkers happy
e_res       dw 0
e_oemid     dw 0
e_oeminfo   dw 0
e_res2      dw 10 dup(0)
e_lfanew    dd 0
else
display "You should define headertype to 0 or 1",0x0d,0x0a
err
end if

startrel = $            ; End of header fields, start of relocation table
; -- END OF MZ HEADER --
; -- RELOCATION TABLE

; We don't really need relocation, just fill up
; with dummy entries pointed to the same offset
; to make PE linker not truncating our header

times relcnt dw 0,dummyrel
; -- END OF RELOCATION TABLE --

; -- LOAD MODULE --
org 0
    msg db 'DOS in xxxx? Are you kidding?$'
    y_pos = msg+10
run:
    ; Patch segment address in far jump instruction
    ; with initial DS contains PSP and set current DS to CS
    mov [cs:fixup],ds
    mov ax,cs
    mov ds,ax
    
    ; Get current date, returns year in CX
    mov ah,0x2A
    int 0x21
    
    ; Translate year to string
    mov ax,cx       ; Dividend is a returned year
    mov cx,10       ; Divide by 10
    mov bx,y_pos    ; Position of year in displayed string
divloop:
    xor dx,dx       ; Clear high word of dividend
    div cx          ; DX = next year digit
    add dl,0x30     ; Convert it to ASCII
    mov [bx],dl     ; Move to the current offset in string
    dec bx          ; Decrement string offset
    test ax,ax      ; Was it last digit?
    jnz divloop     ; If not, continue to divide AX

    ; Display string with a current year
    mov ah,0x9
    mov dx,msg
    int 0x21

    ; Jump to int 20h instruction located in base of the PSP
    ; This is the most compatible (PC-DOS 1.0+) method
    ; to terminate the program
    db 0xEA         ; far jump instruction
    dw 0            ; offset operand
    fixup dw 0      ; segment operand
    
dummyrel:
    ; Dummy relocation point
    dw 0

    ; We need to waste space filling with zeroes to page
    ; boundary only to make PE linker happy and avoid patching
    ; MZ fields in PE binary manually
    times loadsz-($-$$) db 0
    
    ; Here should be enough guaranteed allocated zeroes 
    ; for pushing registers at INT
    stk = $
; -- END OF LOAD MODULE --