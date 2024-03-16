// Programa   : DPLIBCOM_QUINCENAL
// Fecha/Hora : 19/07/2022 00:39:13
// Propósito  : Mostrar resumen de fecha
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oLibCom,oBtnBrw,cWhereLib)
  LOCAL cWhere:="",cCodigo,uValue
  LOCAL cTitle:=" Compras Quincenales ",aTitle:=NIL,cFind:=NIL,cFilter:=NIL,cSgdoVal:=NIL,cOrderBy:=NIL

  cWhereLib:="DOC_CODSUC"+GetWhere("=",oDp:cSucursal)

  cWhere   := " INNER JOIN dpdiario ON DIA_FECHA=DOC_FCHDEC  "+;
              " INNER JOIN dptipdocpro ON DOC_TIPDOC=TDC_TIPO AND TDC_LIBCOM=1 "+;
              " WHERE "+cWhereLib+" AND DOC_TIPTRA"+GetWhere("=","D")+" AND DOC_ACT=1"

  cOrderBy  :="  GROUP BY DIA_ANO,DIA_MES,DIA_QUINCE  ORDER BY CONCAT(DIA_ANO,DIA_MES,DIA_QUINCE) DESC "
  aTitle    :={"Año","Mes","Quince","Desde","Hasta","Cant.;Reg"}

  oDp:aPicture   :={NIL,NIL,NIL,NIL,NIL,"9999"}
  oDp:aSize      :={50 ,50 ,50 ,80 ,80 ,40}
  oDp:lFullHeight:=.T.

  cCodigo:=EJECUTAR("REPBDLIST","DPDOCPRO","DIA_ANO,DIA_MES,DIA_QUINCE,MIN(DIA_FECHA) AS DESDE,MAX(DIA_FECHA) AS HASTA,COUNT(*) AS CUANTOS",.F.,cWhere,cTitle,aTitle,cFind,cFilter,cSgdoVal,cOrderBy,oBtnBrw)

  IF !Empty(cCodigo)

     IF DAY(oDp:aLine[4])<=15
        oDp:dFchIniDoc:=FCHINIMES(oDp:aLine[4])
        oDp:dFchFinDoc:=oDp:dFchIniDoc+14
     ELSE
       oDp:dFchIniDoc:=CTOD("15/"+SUBS(DTOC(oDp:aLine[4]),3,10))
       oDp:dFchFinDoc:=FCHFINMES(oDp:dFchIniDoc)
     ENDIF

  ENDIF

RETURN .T.


