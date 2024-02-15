// Programa   : LIBCOMEDITCONISLR
// Fecha/Hora : 14/02/2024 07:23:41
// Propósito  :
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

/*
// Editar Codigo de RetencióN
*/

#INCLUDE "DPXBASE.CH"

PROCE MAIN(nCol,lSave,oLIBCOMEDIT)
  LOCAL oBrw      :=oLIBCOMEDIT:oBrw,oLbx
  LOCAL nAt       :=oBrw:nArrayAt,nClrText:=0
  LOCAL aLine     :=oBrw:aArrayData[oBrw:nArrayAt]
  LOCAL cCodRet   :=oBrw:aArrayData[oBrw:nArrayAt,nCol]
  LOCAL cWhere    :=""
  LOCAL cRif      :=aLine[oLIBCOMEDIT:COL_LBC_RIF] 
  LOCAL cCodRet_  :=cCodRet

  IF Empty(cRif)
      EJECUTAR("XSCGMSGERR",oBrw,"Requiere RIF ","Campo Requerido")
      RETURN NIL
   ENDIF

   oLIBCOMEDIT:SETTIPPER()
   cCodRet:=EJECUTAR("DPCONRETSEL",cCodRet,oLIBCOMEDIT:cTipPer,oLIBCOMEDIT:cReside,oBrw)

   cCodRet:=IF(ValType(cCodRet)="L",cCodRet_,cCodRet)
   oLIBCOMEDIT:lAcction  :=.T.
   oBrw:nArrayAt:=nAt

   SysRefresh(.t.)

RETURN cCodRet
