;----------------------------------------------------------------------
;			cc65 includes
;----------------------------------------------------------------------
.include "telestrat.inc"
.include "fcntl.inc"

;----------------------------------------------------------------------
;			Orix Kernel includes
;----------------------------------------------------------------------
.include "kernel/src/include/kernel.inc"
.include "kernel/src/include/memory.inc"
.include "kernel/src/include/process.inc"
;.include "kernel/src/orix.inc"


;----------------------------------------------------------------------
;			Orix Shell includes
;----------------------------------------------------------------------
.include "shell/src/include/bash.inc"
.include "shell/src/include/orix.inc"


;----------------------------------------------------------------------
;			Orix SDK includes
;----------------------------------------------------------------------
.include "macros/SDK.mac"
.include "include/SDK.inc"

; .reloc nécessaire parce que le dernier segment de orix.inc est .bss et qu'il
; y a des .org xxxx dans les fichiers .inc...
.reloc

;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------
;.reloc
;From orix
.import _init_argv
.import _get_argv
.import _strcpy
.import _strlen

; From debug
.import PrintHexByte
.import PrintRegs

; From sopt
.import spar1
.import sopt1

.zeropage
.import cbp

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export _main
.export _argc
.export _argv

;----------------------------------------------------------------------
;				ORIXHDR
;----------------------------------------------------------------------
; MODULE __MAIN_START__, __MAIN_LAST__, _main

;----------------------------------------------------------------------
;			Segments vides
;----------------------------------------------------------------------
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.zeropage
;BufferPtr := userzp+6
.if 0
	fp        := userzp+12
	fname     := fp+2
	address   := fname+2
	len       := address+2
	;BufferPtr := len +1
.else
	fp: .res 2
	fname: .res 2
	address: .res 2
	;BufferPtr: .res 2
	len: .res 1
.endif

;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
.segment "CODE"
spar := spar1
sopt := sopt1


_main:

	; --------------------------------------------------------------------
	;		Placer toute cette partie dans "STARTUP"
	; Calcule la taille du tableau char *ARGV[]
	; --------------------------------------------------------------------
	lda #((MAX_ARGS*2)+1)
	sta userzp+2
	lda #$00
	sta userzp+3

	; --------------------------------------------------------------------
	;			Calcule la longueur de BUFEDT
	; --------------------------------------------------------------------
	strlen BUFEDT
	iny				; Longueur de BUFEDT +1 pour le \0 final
	tya

	; --------------------------------------------------------------------
	;		Alloue un tampon pour BUFEDT+ARGV
	; --------------------------------------------------------------------
	ldy #$00
	clc
	adc #((MAX_ARGS*2)+1)
	bcc *+3
	iny
	sta userzp+4
	sty userzp+5

	malloc (userzp+4)

	sta _argv			; Sauvegarde le pointeur malloc
	sty _argv+1

	; --------------------------------------------------------------------
	;		Copie de BUFEDT dans le tampon(après char *ARGV[])
	; --------------------------------------------------------------------
	clc				; Sauvegarde le pointeur vers la copie de BUFEDT
	adc userzp+2
	sta userzp+2
	tya
	adc userzp+3
	sta userzp+3

	strcpy (userzp+2), BUFEDT		; Copie BUFEDT dans le tampon

	; --------------------------------------------------------------------
	;		Initialise la structure ARGV
	; --------------------------------------------------------------------
	init_argv (_argv), (userzp+2)


	; ====================================================================
	;			Programme de test
	; ====================================================================

	ldx _argc
	bne *+5
	jmp DisplayHelp


	; Alloue un tampon de 256 octets pour la lecture du fichier
;	malloc #0100
;	sta BufferPtr
;	sty BufferPtr+1

	; TODO: Récupérer les paramètres en fonction de ARGC

	; Nom du fichier à ouvrir
	ldx #$01
	; A: LSB
	; Y: MSB
	get_argv

	bcs *+5
	jmp errArgv

.if 1
	sta fname
	sty fname+1

.else
	; Récupère un éventuel paramètre
	; /!\ AY inversé par rapport à get_argv
	; A: MSB
	; Y: LSB
	sty address
	tay
	lda address
	ldx #$40
	jsr spar
	.byte address,$00
	jsr PrintRegs
	; X: bit des variables trouvées (ici address <=> b7)
	cpx #$00
	bne @getfname
	; Remet AY dans l'ordre
	sty fname
	sta fname+1
	jmp @open

@getfname:
	ldx #$02
	get_argv
	bcs *+5
	jmp errArgv
	sta fname
	sty fname+1
.endif

@open:
	fopen (fname), O_RDONLY
	sta fp
	sty fp+1

	ora fp+1
	bne *+5
	jmp errFopen

	fread BufferPtr, #$0100, 1, fp
	; C=1 -> Erreur
	jsr checkEof
;	jsr PrintRegs
	bcc *+5
	jmp errFread

	sec
	lda PTR_READ_DEST
	sbc #<BufferPtr
	sta len
;	beq *+4
;	inc len

;	jsr PrintRegs
	BRK_KERNEL XCRLF
;	lda PTR_READ_DEST+1
;	jsr PrintHexByte
;	lda PTR_READ_DEST
;	jsr PrintHexByte

.if 1
	ldy #$00
	sty address
	sty address+1
.endif
	; Affiche l'adresse de la ligne
	jsr printAddress

	ldy #$00
	ldx #$01
loop:
;	lda (BufferPtr),y
	;tya
	;and #%00000111
	;tax
	lda #'.'
	sta charline,x
	lda BufferPtr,y
	cmp #' '
	bcc suite
	cmp #'z'+1
	bcs suite
	sta charline,x

suite:
	print #' '
	jsr PrintHexByte

	inx
	cpx #$09
	bne next
	print charline

	jsr StopOrCont
	bcs @end

	clc
	lda address
	adc #$08
	sta address
	bne *+4
	inc address+1
	jsr printAddress

	ldx #$01

next:
	iny
	cpy len
	bne loop

	fread BufferPtr, #$0100, 1, fp
	; C=0 -> Erreur
	jsr checkEof
	bcs @endloop
	sec
	lda PTR_READ_DEST
	sbc #<BufferPtr
	sta len
	clc
	bcc loop-4

@endloop:

	lda len
	and #$07
	beq @end
	pha
	tay
	iny
	lda #' '
@char:
	sta charline,y
	iny
	cpy #$09
	bne @char

	; Calcule 2*len+ (len-1)
	; Nombre de caractères déjà affichés sur la ligne
	pla
	tay
	dey
	dey
	sty len
	asl
	clc
	adc len
	tay

@empty_loop:
	iny
	lda emptyline,y
	beq @aff_dummp
	BRK_KERNEL XWR0
	bne @empty_loop

@aff_dummp:
	print charline

@end:
	fclose fp
;	mfree (BufferPtr)
	mfree (_argv)

	BRK_KERNEL XCRLF
	rts

;----------------------------------------------------------------------
; C=1: CTRL+C
; A mettre dans la librairie
;----------------------------------------------------------------------
StopOrCont:
	BRK_KERNEL XRD0
	cmp #$03
	beq @stop
	cmp #' '
	bne @cont

@loop:
	BRK_KERNEL XRD0
	beq @loop
	cmp #$03
	beq @stop

@cont:
	clc
	.byte $24

@stop:
	sec
	rts


;----------------------------------------------------------------------
;
; C:1 -> PTR_READ_DEST <= BufferPtr
;
;----------------------------------------------------------------------
checkEof:
	lda #<BufferPtr
	cmp PTR_READ_DEST
	lda #>BufferPtr
	sbc PTR_READ_DEST+1
	rts

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
printAddress:
	print #' '
	lda address+1
	jsr PrintHexByte
	lda address
	jsr PrintHexByte
	print #':'
	rts

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
errArgv:
	print error_argv, NOSAVE
	rts

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
errFopen:
	BRK_KERNEL XCRLF
	print error_fopen, NOSAVE
errEnd:
	print (fname), NOSAVE
	BRK_KERNEL XCRLF
	BRK_KERNEL XCRLF

	rts

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
errFread:
	BRK_KERNEL XCRLF
	print error_fread, NOSAVE
	clc
	bcc errEnd

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
DisplayHelp:
        print helpmsg, NOSAVE
        ; Dépile le pointeur sur la ligne de commande
        ;pla
        ;pla
        rts

;----------------------------------------------------------------------
;				DATAS
;----------------------------------------------------------------------
.segment "RODATA"
helpmsg:
    .byte $0a, $0d
    .byte   "Hexa dump utility", $0a, $0a, $0d
    .byte   "Syntax  : hexdump <filename>", $0a, $0a, $0d
    .byte $00

error_argv:
    .asciiz "get_argv(1) error "

error_fopen:
	.asciiz "Erreur d'ouverture du fichier: "

error_fread:
	.asciiz "Erreur de lecture du fichier: "

emptyline:
	.asciiz "                       "

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.segment "DATA"
charline:
	.byte "|........"
	.byte $0a, $0d
	.byte $00

;separator:
;	.asciiz ":"

BufferPtr:
	.res 256,0

;----------------------------------------------------------------------
;		Placer ces variables dans la librairie
;----------------------------------------------------------------------
.segment "DATA"
_argc:
	.res 1
_argv:
	.res 2

