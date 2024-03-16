// Programa   : BRLIBCOM_LBCNODEDU
// Fecha/Hora : 05/03/2024 21:51:39
// Propósito  : Libro de compras, asignar credito fisal
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oMdi,nCol)
  LOCAL lCreFis,oCol,nKey:=0

  IF oMdi=NIL
    RETURN .T.
  ENDIF

  // No Aplica 
  IF !oMdi:oBrw:aArrayData[oMdi:oBrw:nArrayAt,oLIBCOMEDIT:COL_TDC_LIBCOM]
     RETURN .T.
  ENDIF

  CursorWait()

  oCol:=oMdi:oBrw:aCols[oLIBCOMEDIT:COL_TDC_LIBCOM]

  oMdi:oBrw:aArrayData[oMdi:oBrw:nArrayAt,nCol]:=!oMdi:oBrw:aArrayData[oMdi:oBrw:nArrayAt,nCol]
  oMdi:PUTFIELDVALUE(oCol,oMdi:oBrw:aArrayData[oMdi:oBrw:nArrayAt,nCol],nCol,nKey)

  oMdi:oBrw:DrawLine(.T.)

  CursorArrow()

RETURN .T.
// EOF

