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

| cntrlParam variant:

ioCRefNum	=	24
csCode		=	26
csParam		=	28

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
| Points (Point)
|

v		=	0
h		=	2
sizePoint	=	4

|
| Rectangles (Rect)
|

top	=	0
left	=	2
bottom	=	4
right	=	6
sizeRect=	8

|
| SCSI Instructions (SCSIInstr)
|

scOpcode	=	0
scParam1	=	2
scParam2	=	6
sizeSCSIInstr	=	10

| constants for SCSIInstr.scOpcode
scInc	=	1
scStop	=	7

|
| Partition Map Entries (???)
|

pmSig		=	0
pmSigPad	=	2
pmMapBlkCount	=	4
pmPyPartStart	=	8
pmPartBlkCnt	=	12
pmPartName	=	16
pmPartType	=	48
pmLgDataStart	=	80
pmDataCnt	=	84
| There's more, but I couldnt be bothered typing it in right now

|
| EOF
|
