;----------------------------------------------------------------------
;			cc65 includes
;----------------------------------------------------------------------
.include "telestrat.inc"
.include "fcntl.inc"

;----------------------------------------------------------------------
;			Orix SDK includes
;----------------------------------------------------------------------
.include "SDK.mac"
.include "SDK.inc"
.include "types.mac"

;----------------------------------------------------------------------
;				Imports
;----------------------------------------------------------------------
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
	spar := spar1
.import sopt1
	sopt := sopt1

.importzp cbp
.importzp opt

;----------------------------------------------------------------------
;				Exports
;----------------------------------------------------------------------
.export _main
.export _argc
.export _argv

;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------
	VERSION = $20231020
	.define PROGNAME "hexdump"

	twil_register := $0342
	twil_bank     := $0343

;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.include "include/hexdump.inc"

;----------------------------------------------------------------------
;			Segments vides
;----------------------------------------------------------------------
.pushseg
	.segment "STARTUP"
	.segment "INIT"
	.segment "ONCE"
.popseg

;----------------------------------------------------------------------
;				Programme
;----------------------------------------------------------------------
.segment "CODE"

;----------------------------------------------------------------------
;
; Entrée:
;	AY: Adresse de chargement? (A=LSB)
;	X : $ff
; Sortie:
;	-
;
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc _main
		; --------------------------------------------------------------------
		;		Placer toute cette partie dans "STARTUP"
		; Calcule la taille du tableau char *ARGV[]
		; --------------------------------------------------------------------
		lda	#((MAX_ARGS*2)+1)
		sta	userzp+2
		lda	#$00
		sta	userzp+3

		; --------------------------------------------------------------------
		;			Calcule la longueur de BUFEDT
		; --------------------------------------------------------------------
		strlen	BUFEDT
		iny				; Longueur de BUFEDT +1 pour le \0 final
		tya

		; --------------------------------------------------------------------
		;		Alloue un tampon pour BUFEDT+ARGV
		; --------------------------------------------------------------------
		ldy	#$00
		clc
		adc	#((MAX_ARGS*2)+1)
		bcc	setuzp
		iny
	setuzp:
		sta	userzp+4
		sty	userzp+5

		malloc	(userzp+4)

		sta	_argv			; Sauvegarde le pointeur malloc
		sty	_argv+1

		; --------------------------------------------------------------------
		;		Copie de BUFEDT dans le tampon (après char *ARGV[])
		; --------------------------------------------------------------------
		clc				; Sauvegarde le pointeur vers la copie de BUFEDT
		adc	userzp+2
		sta	userzp+2
		sta	cbp
		tya
		adc	userzp+3
		sta	userzp+3
		sta	cbp+1

		strcpy	(userzp+2), BUFEDT		; Copie BUFEDT dans le tampon


		; --------------------------------------------------------------------
		; Saute le nom du programme dans la ligne de commande
		; --------------------------------------------------------------------
		ldy	#$00
	loopPrg:
		lda	(cbp),y
		beq	get_param_B

		cmp	#' '
		beq	get_param_B

		iny
		bne	loopPrg

		; --------------------------------------------------------------------
		; Calcule l'adresse du premier paramètre dans la ligne de commande
		; --------------------------------------------------------------------
	get_param_B:
		clc
		tya
		adc	cbp
		tay
		lda	#$00
		adc	cbp+1

		; --------------------------------------------------------------------
		; Traitemment paramètre -b <bankid>
		; --------------------------------------------------------------------
		jsr	sopt
		.asciiz	"BVH"
		bcs	errOpt

		cpx	#$40
		beq	cmnd_version

		cpx	#$20
		beq	cmnd_help

		cpx	#$80
		bne	dumpFile

		; --------------------------------------------------------------------
		; Traitemment paramètre [, <offset>]
		; On veut une valeur décimale, clear, pas de '+'
		; --------------------------------------------------------------------
		ldx	#%10000000
		jsr	spar
		.byte	bankid, offset, 0

		; --------------------------------------------------------------------
		; Flag des variables saisies: b7-> bankid, b6-> offset
		; Seule bankid est obligatoire
		; --------------------------------------------------------------------
		cpx	#%10000000
		bcc	errBankid

		; --------------------------------------------------------------------
		; Offset maximal: 16Ko ($4000-1)
		; --------------------------------------------------------------------
		lda	offset+1
		cmp	#$40
		bcs	errOffset

		; --------------------------------------------------------------------
		; 0 < bankid < 65
		; --------------------------------------------------------------------
		lda	bankid+1
		bne	errBankid

		lda	bankid
		; [ Autorise cas spécial banque 0
		beq	dumpBank
		; ]
		; [ sinon
		; beq	errBankid
		; ]

		cmp	#64+1
		bcs	errBankid

		; --------------------------------------------------------------------
		; Calcule le numéro de la banque dans le set
		; --------------------------------------------------------------------
		; Avec table:
		; and	#$07
		; tax
		; lda	bankTbl,x
		; sta	bankid+1

		; Sans table:
		and	#$03
		bne	set_bank

		lda	#$04

	set_bank:
		sta	bankid+1

		; L'offset 0 de la table setTbl correspond à la banque 1
		dec	bankid

		jmp	dumpBank

		; --------------------------------------------------------------------
		;
		; --------------------------------------------------------------------
	errBankid:
		print	error_bankid
		crlf
		rts

	errOffset:
		print	error_offset
		crlf
		rts

	errOpt:
		print	error_opt
		crlf
		rts

	cmnd_version:
		print	version_msg
		crlf
		rts

	cmnd_help:
		jmp	DisplayHelp

	dumpBank:
		; dec	bankid
		lda	#<bank_msg
		sta	fname
		lda	#>bank_msg
		sta	fname+1
		jmp	open

		; --------------------------------------------------------------------
		; Synatxe: hexdump <filename>
		;
		; Initialise la structure ARGV
		; --------------------------------------------------------------------

	dumpFile:
		init_argv	(_argv), (userzp+2)


		; --------------------------------------------------------------------
		; Récupère le nom du fichier
		; --------------------------------------------------------------------

		ldx	_argc
		bne	get_args

		print	version_msg
		print	error_missing_arg
		crlf
		rts

	get_args:
		; Alloue un tampon de 256 octets pour la lecture du fichier
	;	malloc #0100
	;	sta BufferPtr
	;	sty BufferPtr+1

		; TODO: Récupérer les paramètres en fonction de ARGC

		; Nom du fichier à ouvrir
		ldx	#$01
		; A: LSB
		; Y: MSB
		get_argv

		bcs	ok
		jmp	errArgv

	ok:
	.if 1
		sta	fname
		sty	fname+1

		; Adresse à 0 pour les fichiers
		lda	#$00
		sta	address
		sta	address+1

	.else
		; Récupère un éventuel paramètre
		; /!\ AY inversé par rapport à get_argv
		; A: MSB
		; Y: LSB
		sty	address
		tay
		lda	address
		; valeur hexa, '+', clear de la variable
		ldx	#$40
		jsr	spar
		.byte	address,$00

		jsr	PrintRegs
		; X: bit des variables trouvées (ici address <=> b7)
		cpx	#$00
		bne	@getfname

		; Remet AY dans l'ordre
		sty	fname
		sta	fname+1
		jmp	open

	@getfname:
		ldx	#$02
		get_argv
		bcs	*+5
		jmp	errArgv
		sta	fname
		sty	fname+1
	.endif

	open:
		jsr	openSrc
		bne	bufferLoad

		jmp	errFopen

	bufferLoad:
		jsr	bufferFill
		bcc	dump

		jmp	errFread

	dump:
		sec
		lda	PTR_READ_DEST
		sbc	#<BufferPtr
		sta	len
	;	beq *+4
	;	inc len

	;	jsr PrintRegs
		crlf
	;	lda PTR_READ_DEST+1
	;	jsr PrintHexByte
	;	lda PTR_READ_DEST
	;	jsr PrintHexByte


	disp_addr:
		; Affiche l'adresse de la ligne
		jsr	printAddress

		ldy	#$00
		ldx	#$01
	loop:
	;	lda (BufferPtr),y
		;tya
		;and #%00000111
		;tax
		lda	#'.'
		sta	charline,x
		lda	BufferPtr,y
		cmp	#' '
		bcc	suite

		cmp	#'z'+1
		bcs	suite

		sta	charline,x

	suite:
		print	#' ', SAVE
		jsr	PrintHexByte

		inx
		cpx	#$09
		bne	next

		print	charline, SAVE

		jsr	StopOrCont
		bcs	end

		clc
		lda	address
		adc	#$08
		sta	address
		bne	skip
		inc	address+1
	skip:

		; Si on a affiché tout le buffer, on le rempli
		iny
		cpy	len
		beq	refill

		; Sinon, il faut afficher l'adresse de la ligne suivante
		; et reboucler
		jsr	printAddress
		ldx	#$01
		bne	loop

	next:
		; Affiche la ligne suivante si il en reste dans le buffer
		iny
		cpy	len
		bne	loop

;		fread	BufferPtr, #$0100, 1, fp
;		; C=0 -> Erreur
;		jsr	checkEof
	refill:
		jsr	bufferFill
		bcs	@endloop

		sec
		lda	PTR_READ_DEST
		sbc	#<BufferPtr
		sta	len
		clc
	;	bcc	loop-4
		bcc	disp_addr

	@endloop:
		lda	len
		and	#$07
		beq	end

		pha
		tay
		iny

		lda	#' '
	loopchar:
		sta	charline,y
		iny
		cpy	#$09
		bne	loopchar

		; Calcule 2*len+ (len-1)
		; Nombre de caractères déjà affichés sur la ligne
		pla
		tay
		dey
		dey
		sty	len
		asl
		clc
		adc	len

		tay
	empty_loop:
		iny
		lda	emptyline,y
		beq	aff_dummp

		cputc
		bne	empty_loop

	aff_dummp:
		print	charline

	end:
		lda	opt
		bne	exit

		fclose(fp)
	;	mfree (BufferPtr)
	exit:
		mfree	(_argv)

		crlf
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	Z: 0-> OK, 1-> Erreur
;
; Variables:
;	Modifiées:
;		fp
;		address
;	Utilisées:
;		fname
;		opt
;		offset
; Sous-routines:
;	fopen
;----------------------------------------------------------------------
.proc openSrc
		lda	opt
		bne	memory

		fopen	(fname), O_RDONLY
		sta	fp
		stx	fp+1

		eor	fp+1
		rts

	memory:
		lda	offset
		sta	address

		clc
		lda	offset+1
		adc	#$c0
		sta	offset+1
		sta	address+1

		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;
; Variables:
;	Modifiées:
;		BufferPtr
;		offset
;		twil_register
;		twil_bank
;		VIA2::PRA
;		PTR_READ_DEST
;
;	Utilisées:
;		fp
;		opt
;		bankid
;		setTbl
;		bankTbl
;		address
; Sous-routines:
;	checkEof
;	fread
;----------------------------------------------------------------------
.proc bufferFill
		lda	opt
		bne	memory

		fread	BufferPtr, #$0100, 1, fp
		; C=0 -> Erreur
		jmp	checkEof

	memory:
		lda	offset+1
		bne	switch
		sec
		rts

	switch:
		; Banque active
		sei
		lda	VIA2::PRA
		pha
		lda	twil_register
		pha
		lda	twil_bank
		pha

		; Change la banque active
		lda	bankid+1
;		lda	bankTbl,x
		sta	VIA2::PRA
		; Cas spécial banque 0
		beq	load

		ldx	bankid
		lda	setTbl,x
		sta	twil_bank

		; Test banque ROM/RAM
		;
		; En principe la banque active à l'exécution du programme
		; était une banque de ROM donc on ne bascule que si bankid
		; est une banque de RAM.
		;
		; Sinon il faut ajouter une bascule pour les banques de ROM
		;	lda	twil_register
		;	ora	#$20
		;	sta	twil_register
		cpx	#$20
		bcs	load

		; ROM, on force b5 à 0
		lda	twil_register
		and	#$df
		sta	twil_register

	load:
		; Rempli le tampon
		ldy	#$00

	loop:
		lda	(offset),y
		sta	BufferPtr,y
		iny
		bne	loop

		; Restaure la banque
		pla
		sta	twil_bank
		pla
		sta	twil_register
		pla
		sta	VIA2::PRA
		cli

		ldy	offset+1
		iny
		sty	offset+1
		bne	cont

		; On est arrivé à la fin de la banque
		; Cas particulier si l'offset est un nombre entier de pages
		; de 256 octets ($xx00)
		lda	address
		beq	cont

		; sinon cas général
		sec
		lda	#$00
		sbc	address
		adc	#<BufferPtr
		sta	PTR_READ_DEST
		clc
		rts


	cont:
		lda	#<BufferPtr
		sta	PTR_READ_DEST

		clc
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	C: 1-> CTRL+C
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		-
; Sous-routines:
;	XRD0
;----------------------------------------------------------------------
.proc StopOrCont
		.byte	$00, XRD0
		cmp	#$03
		beq	stop

		cmp	#' '
		bne	cont

	loop:
		.byte	$00, XRD0
		beq	loop

		cmp	#$03
		beq	stop

	cont:
		clc
		.byte	$24

	stop:
		sec
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;
; Sortie:
;	C: 1-> PTR_READ_DEST <= BufferPtr
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		BufferPtr
;		PTR_READ_DEST
; Sous-routines:
;	-
;----------------------------------------------------------------------
.proc checkEof
		lda	#<BufferPtr
		cmp	PTR_READ_DEST
		lda	#>BufferPtr
		sbc	PTR_READ_DEST+1
		rts
.endproc

;----------------------------------------------------------------------
;
; Entrée:
;	-
; Sortie:
;	-
; Variables:
;	Modifiées:
;		-
;	Utilisées:
;		address
; Sous-routines:
;	PrintHexByte
;----------------------------------------------------------------------
.proc printAddress
		print	#' '
		lda	address+1
		jsr	PrintHexByte

		lda	address
		jsr	PrintHexByte

		print	#':'
		rts
.endproc

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
;		error_argv
; Sous-routines:
;	print
;----------------------------------------------------------------------
.proc errArgv
		print	error_argv
		rts
.endproc

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
;		fname
;		error_fopen
; Sous-routines:
;	print
;	crlf
;----------------------------------------------------------------------
.proc errFopen
		crlf
		print	error_fopen

	::errEnd:
		print	(fname)
		crlf
		crlf
		rts
.endproc

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
;		error_fread
; Sous-routines:
;	errEnd
;	print
;	crlf
;----------------------------------------------------------------------
.proc errFread
		crlf
		print	error_fread
		jmp	errEnd
.endproc

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
;		helpmsg
; Sous-routines:
;	print
;----------------------------------------------------------------------
.proc DisplayHelp
		print	helpmsg
		; Dépile le pointeur sur la ligne de commande
		;pla
		;pla
		rts
.endproc

