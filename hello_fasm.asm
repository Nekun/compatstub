format PE GUI 4.0 on 'stub_type0.exe'
entry start

section '.data' data readable writable
	str_caption db 'Windows hello',0
	str_message db 'Windows is good',0
	
section '.text' code readable executable
start:
	push 0
	push str_caption
	push str_message
	push 0
	call [MessageBoxA]

	push 0
	call [ExitProcess]

section '.idata' import data readable writeable

; Import directory table
	dd 0,0,0,rva kernel32_name,rva kernel32_itable ; KERNEL32.DLL
	dd 0,0,0,rva user32_name,rva user32_itable ; USER32.DLL
	dd 0,0,0,0,0

; Import lookup tables
kernel32_itable:
	ExitProcess dd rva _ExitProcess
	dd 0
user32_itable:
	MessageBoxA dd rva _MessageBoxA
	dd 0

; Hint/Name table
	; kernel32.dll
	_ExitProcess dw 0
		db 'ExitProcess',0
	; user32.dll
	_MessageBoxA dw 0
		db 'MessageBoxA',0

; DLL name strings
	kernel32_name db 'kernel32.dll',0
	user32_name db 'user32.dll',0

; vi: syntax=fasm
