#
# traplist.i
#
# List of A-line traps
#

	.macro	_SysError ;.word 0xa9c9 ;.endm
	.macro	_InitGraf ;.word 0xa86e ;.endm
	.macro	_OpenPort ;.word 0xa86f ;.endm
	.macro	_FillRect ;.word 0xa8a5 ;.endm
	.macro	_SetAppBase ;.word 0xa057 ;.endm
	.macro	_NewPtr_Sys_Clear ;.word 0xa71e ;.endm
	.macro	_BlockMove ;.word 0xa02e ;.endm
	.macro	_SetTrapAddress_NewOS ;.word 0xa247 ;.endm
	.macro	_GetTrapAddress_NewOS ;.word 0xa346 ;.endm
	.macro	_InitResources ;.word 0xa995 ;.endm
	.macro	_InitFonts ;.word 0xa8fe ;.endm
	.macro	_MoveTo ;.word 0xa893 ;.endm
	.macro	_DrawString ;.word 0xa884 ;.endm
	.macro	_Read ;.word 0xa002 ;.endm
	.macro	_FrameRect ;.word 0xa8a1 ;.endm
	.macro	_ScrollRect ;.word 0xa8ef ;.endm
	.macro	_NewRgn ;.word 0xa8d8 ;.endm
	.macro	_DrawChar ;.word 0xa883 ;.endm

#
# EOF
#
