// Programa   : DPLIBCOM_MENSUAL
// Fecha/Hora : 19/07/2022 00:39:13
// Propósito  : Mostrar resumen de fecha
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oLibCom,oBtnBrw,cWhereLib)
  LOCAL cWhere:="",cCodigo,uValue
  LOCAL cTitle:=" Compras Mensuales ",aTitle:=NIL,cFind:=NIL,cFilter:=NIL,cSgdoVal:=NIL,cOrderBy:=NIL

  cWhereLib:="DOC_CODSUC"+GetWhere("=",oDp:cSucursal)

  cWhere   := " INNER JOIN dpdiario ON DIA_FECHA=DOC_FCHDEC  "+;
              " INNER JOIN dptipdocpro ON DOC_TIPDOC=TDC_TIPO AND TDC_LIBCOM=1 "+;
              " WHERE "+cWhereLib+" AND DOC_TIPTRA"+GetWhere("=","D")+" AND DOC_ACT=1"

  cOrderBy  :="  GROUP BY DIA_ANO,DIA_MES  ORDER BY CONCAT(DIA_ANO,DIA_MES) DESC "
  aTitle    :={"Año","Mes","Desde","Hasta","Cant.;Reg"}

  oDp:aPicture   :={NIL,NIL,NIL,NIL,"9999"}
  oDp:aSize      :={50 ,50 ,80 ,80 ,40}
  oDp:lFullHeight:=.T.

  cCodigo:=EJECUTAR("REPBDLIST","DPDOCPRO","DIA_ANO,DIA_MES,MIN(DIA_FECHA) AS DESDE,MAX(DIA_FECHA) AS HASTA,COUNT(*) AS CUANTOS",.F.,cWhere,cTitle,aTitle,cFind,cFilter,cSgdoVal,cOrderBy,oBtnBrw)

  IF !Empty(cCodigo)

     oDp:dFchIniDoc:=CTOD("01/"+CTOO(oDp:aLine[2],"C")+"/"+CTOO(oDp:aLine[1],"C"))
     oDp:dFchFinDoc:=FCHFINMES(oDp:dFchIniDoc)

  ENDIF

RETURN .T.
// EOF

