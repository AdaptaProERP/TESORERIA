// Programa   : LIBCOMGETNUMRTI
// Fecha/Hora : 14/02/2024 08:01:57
// Propósito  : Generar Número de Retención de RETENCION DE IVA
// Creado Por : Juan Navas
// Llamado por: 
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oLIBCOMEDIT)
   LOCAL cWhere    :="LBC_CODSUC"+GetWhere("=",oLIBCOMEDIT:cCodSuc),nKey:=0
   LOCAL oColNumRti:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_NUMRTI]
   LOCAL nColNumRti:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_NUMRTI")
   LOCAL cNumero   :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_NUMRTI]

   // Condominio, la retencion es para todos 
   IF oLIBCOMEDIT:lCondom
      cWhere:=""
   ENDIF

   IF Empty(cNumero)
     cNumero:=SQLINCREMENTAL("DPLIBCOMPRASDET","LBC_NUMRTI",cWhere,NIL,oLIBCOMEDIT:cNumRti,oLIBCOMEDIT:lZeroRti,oLIBCOMEDIT:nLenRti)
     oLIBCOMEDIT:PUTFIELDVALUE(oColNumRti,cNumero,oLIBCOMEDIT:COL_LBC_NUMRti,nKey)
   ENDIF

RETURN .T.
// EOF
