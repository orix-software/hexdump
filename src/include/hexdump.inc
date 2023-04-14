.ifndef HEXDUMP_INC
	.feature string_escapes

	;----------------------------------------------------------------------
	;				Variables
	;----------------------------------------------------------------------
	.pushseg
		.segment "ZEROPAGE"
			unsigned short fp
			unsigned short fname
			unsigned short address

			unsigned char len
			unsigned char userzp[6]

			unsigned short bankid
			unsigned short offset

		.segment "DATA"
			charline:
				.byte	"|........"
				.byte	$0a, $0d
				.byte	$00

			unsigned char twilregs[2]
			unsigned char BufferPtr[256]

			; Placer les variables suivantes dans la librairie
			unsigned char _argc
			unsigned short _argv

	.popseg

	;----------------------------------------------------------------------
	;				Tables
	;----------------------------------------------------------------------
	.pushseg
		.segment "RODATA"
			setTbl:
				; Utilisation de la table (0 <= bankid <= 63)
				;
				; ldx	bankid
				; lda	setTbl,x


				; Si offset 0 <=> bank 0
				; .byte	0

				; Rom
				.byte	0,0,0,0
				.byte	4,4,4,4
				.byte	1,1,1,1
				.byte	5,5,5,5
				.byte	2,2,2,2
				.byte	6,6,6,6
				.byte	3,3,3,3
				.byte	7,7,7,7

				; Remplacement de la table Rom par un calcul  (0 <= bankid <= 63)
				;
				;	Set		Bankid				int(Bankid / 4)		int(Bankid / 8)
				;
				;.byte	0,0,0,0		0 -> 3				0			0
				;.byte	4,4,4,4			4 -> 7				1			0
				;.byte	1,1,1,1		8 -> 11				2			1
				;.byte	5,5,5,5			12 -> 15			3			1
				;.byte	2,2,2,2		16 -> 19			4			2
				;.byte	6,6,6,6			20 -> 23			5			2
				;.byte	3,3,3,3		24 -> 27			6			3
				;.byte	7,7,7,7			28 -> 31			7			3
				;
				; (0 <= bankid <= 63)
				; s = int(bankid / 4)
				; si s est pair => s = s /2
				; sinon s = int(s/2)+4
				;
				;		; /4
				;		lsr
				;		lsr
				;
				;		lsr
				;		bcc	pair
				;	impair:
				;		; 1 -> 0 => 4	(+4)
				;		; 3 -> 1 => 5	(+4)
				;		; 5 -> 2 => 6	(+4)
				;		; 7 -> 3 => 7	(+4)
				;		adc	#$04
				;	pair:
				;		; 0 -> 0
				;		; 2 -> 1
				;		; 4 -> 2
				;		; 6 -> 3


				; Ram
				.byte	0,0,0,0
				.byte	1,1,1,1
				.byte	2,2,2,2
				.byte	3,3,3,3
				.byte	4,4,4,4
				.byte	5,5,5,5
				.byte	6,6,6,6
				.byte	7,7,7,7

				; Remplacement de la table Ram par un calcul (1 <= bankid <= 64)
				;
				; s = int((bankid - 33) / 4)
				;
				; sec
				; lda	bankid
				; sbc	#33
				; lsr
				; lsr


			bankTbl:
				; Utilisation de la table (1 <= bankid <= 64)
				;
				; lda	bankid
				; and	#$07
				; tax
				; lda	bankTbl,x
				;
				; .byte	4,1,2,3,4,1,2,3

				; Remplacement de la table par un calcul (1 <= bankid <= 64)
				;
				; b = (bankid mod 4)
				; si b=0 => b=4
				;
				;	lda	bankid
				;	and	#$03
				;	bne	@suite
				;	lda	#$04
				; @suite:



		.if 0
			bankTbl:
				; Utilisation de la table (0 <= bankid <= 63)
				;
				; ldx	bankid
				; lda	bankTbl,x

				; Si offset 0 <=> bank 0
				; .byte	0

				; Rom (0 <= bankid <= 63)
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4

				; Ram
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
				.byte	1,2,3,4
		.endif
	.popseg

	;----------------------------------------------------------------------
	;			Chaines de caractères
	;----------------------------------------------------------------------
	.pushseg
		.segment "RODATA"
			helpmsg:
				.byte "\r\n"
				.byte "\x1bC         Hexa dump utility\r\n\n"
				.byte " \x1bTSyntax:\x1bP\r\n"
				.byte "    hexdump\x1bA-h\r\n"
				.byte "    hexdump\x1bA-v\r\n"
				.byte "    hexdump\x1bA-b bankid\x1bB[,offset]\r\n"
				.byte "    hexdump\x1bAfilename\r\n"
				.byte "\r\n"
				.byte	$00

			version_msg:
				.asciiz .sprintf("%s version %x.%x - %x.%x\r\n", PROGNAME, (::VERSION & $ff0)>>4, (::VERSION & $0f), ::VERSION >> 16, (::VERSION & $f000)>>12)

			error_missing_arg:
				.asciiz "Filename missing"

			error_argv:
				.asciiz	"get_argv(1) error "

			error_fopen:
				.asciiz	"No such file or directory: "

			error_fread:
				.asciiz	"Read error: "

			error_offset:
				.asciiz "Error: offset out of range"

			error_bankid:
				.asciiz "Error: bankid out of range"

			error_opt:
				.asciiz "Error: unknown option"

			emptyline:
				.asciiz	"                       "

			bank_msg:
				.asciiz "Bank"

	.popseg

	; --------------------------------------------------------------
	;
	; --------------------------------------------------------------
	HEXDUMP_INC = 1

.endif
