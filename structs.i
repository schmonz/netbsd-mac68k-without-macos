|
| structs.i
|
| Mac system data structures
|

|
| IO Parameter Blocks (ParamBlockRec)
|

qLink		=	0
qType		=	4
ioTrap		=	6
ioCmdAddr	=	8
ioCompletion	=	12
ioResult	=	16
ioNamePtr	=	18
ioVRefNum	=	22

| ioParam variant:

ioRefNum	=	24
ioVersNum	=	26
ioPermssn	=	27
ioMisc		=	28
ioBuffer	=	32
ioReqCount	=	36
ioActCount	=	40
ioPosMode	=	44
ioPosOffset	=	46

|
| GrafPorts (GrafPort)
|

device		=	0
portBits	=	2
portRect	=	16
visRgn		=	24
clipRgn		=	28
bkPat		=	32
fillPat		=	40
pnLoc		=	48
pnSize		=	52
pnMode		=	56
pnPat		=	58
pnVis		=	66
txFont		=	68
txFace		=	70
txMode		=	72
txSize		=	74
spExtra		=	76
fgColor		=	80
bkColor		=	84
colrBit		=	88
patStretch	=	90
picSave		=	92
rgnSave		=	96
polySave	=	100
grafProcs	=	104
sizeGrafPort	=	108

|
| Rectangles (Rect)
|

top	=	0
left	=	2
bottom	=	4
right	=	6
sizeRect=	8

|
| EOF
|
