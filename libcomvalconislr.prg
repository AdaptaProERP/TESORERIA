// Programa   : LIBCOMVALCONISLR        
// Fecha/Hora : 14/02/2024 07:17:13
// Propósito  : Validar Concepto ISLR
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oCol,uValue,nCol,nKey,oLIBCOMEDIT)
  LOCAL cSql,oTable
  LOCAL oColPorIsr:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_PORISR]
  LOCAL nColPorIsr:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_PORISR")
  LOCAL lFound    :=.F.,cMemo:=""

  oLIBCOMEDIT:SETTIPPER()

  cSql:=" SELECT TBR_PORCEN FROM DPCONRETISLR "+;
        " INNER JOIN DPTARIFASRET ON CTR_CODIGO=TBR_CODCON "+;
        " WHERE CTR_CODIGO "+GetWhere("=",uValue)+;
        "  AND  TBR_TIPPER "+GetWhere("=",oLIBCOMEDIT:cTipPer)+;
        "  AND  TBR_RESIDE" +GetWhere("=",oLIBCOMEDIT:cReside)+;
        " GROUP BY CTR_CODIGO "

  // ? cSql,"cSql"

  oTable:=OpenTable(cSql,.T.)

  IF oTable:RecCount()>0
     lFound:=.T.
     // ? oTable:TBR_PORCEN,"oTable:TBR_PORCEN",nColPorIsr
     oLIBCOMEDIT:PUTFIELDVALUE(oColPorIsr,oTable:TBR_PORCEN,nColPorIsr,nKey)
     oLIBCOMEDIT:VALPORISR(oColPorIsr,oTable:TBR_PORCEN,nColPorIsr,nKey)
  ENDIF

  oTable:End(.T.)

  oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_CONISR,nKey)

  IF !lFound

    cMemo:="Concepto de Retención: Código="+uValue+CRLF+;
           "Tipo de Persona= "+oLIBCOMEDIT:cTipPer+CRLF+;
           "Residente= "+oLIBCOMEDIT:cReside

    EJECUTAR("XSCGMSGERR",oLIBCOMEDIT:oBrw,cMemo,"Registro no Existe")

  ENDIF

RETURN lFound
// EOF
