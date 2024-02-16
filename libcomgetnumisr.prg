// Programa   : LIBCOMGETNUMISR
// Fecha/Hora : 14/02/2024 08:01:57
// Propósito  : Generar Número de Retención de ISLR
// Creado Por : Juan Navas
// Llamado por: 
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oLIBCOMEDIT)
   LOCAL cWhere    :="LBC_CODSUC"+GetWhere("=",oLIBCOMEDIT:cCodSuc),nKey:=0
   LOCAL oColNumIsr:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_NUMISR]
   LOCAL nColNumIsr:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_NUMISR")
   LOCAL cNumero   :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_NUMISR]

   // Condominio, la retencion es para todos 
   IF oLIBCOMEDIT:lCondom
      cWhere:=""
   ENDIF

   IF Empty(cNumero)
     cNumero:=SQLINCREMENTAL("DPLIBCOMPRASDET","LBC_NUMISR",cWhere,NIL,oLIBCOMEDIT:cNumRet,oLIBCOMEDIT:lZeroRet,oLIBCOMEDIT:nLenRet)
     oLIBCOMEDIT:PUTFIELDVALUE(oColNumIsr,cNumero,oLIBCOMEDIT:COL_LBC_NUMISR,nKey)
   ENDIF

RETURN .T.
// EOF
