// Programa   : DPRECIBODIV_CAJBCO
// Fecha/Hora : 01/03/2023 06:10:40
// Propósito  : Lectura de Instrumentos de Caja/Bancos
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

/*
// Lectura del Estado de Cuenta Bancario
*/
FUNCTION TIPCAJBCO(oRecDiv,cRif,nValCam,oBrw,nColIsMon,lCliente)
  LOCAL aData,cSql,aData1
  LOCAL oDb   :=OpenOdbc(oDp:cDsnData)
  LOCAL dFecha:=oDp:dFecha

  IF ValType(oBrw)="O"
     dFecha:=oRecDiv:dFecha
  ENDIF

  nColIsMon:=13

  oDp:cMonedaNombre:=SQLGET("DPTABMON","MON_DESCRI","MON_CODIGO"+GetWhere("=",oDp:cMoneda))

  // DEFAULT cRif:=oRecDiv:cRif

  cSql:=[ SELECT MON_DESCRI,HMN_VALOR,0 AS TRES,0 AS CUATRO,0 AS CINCO,0 AS LOGICO,MON_CODIGO,"CAJ" AS TIPDOC,ICJ_CODIGO,ICJ_NOMBRE,ICJ_PORITF,0 AS MTOIGTF,ICJ_MONEDA,]+;
        [ SPACE(10) AS MARCAFIN,]+CRLF+;
        [ SPACE(10) AS BANCO ,]+CRLF+;
        [ SPACE(20) AS CUENTA,]+CRLF+;
        [ SPACE(10) AS REFER,0 AS LOGICO  ]+CRLF+;
        [ FROM DPTABMON ]+;
        [ INNER JOIN DPCAJAINST          ON MON_CODIGO=ICJ_CODMON AND ICJ_ACTIVO=1 AND ]+IF(lCliente,[ICJ_INGRES=1 ],[ICJ_EGRESO=1 ])+;
        [ LEFT  JOIN VIEW_NMHISMONMAXFCH ON MON_CODIGO=MAX_CODIGO ]+;
        [ LEFT  JOIN DPHISMON            ON MON_CODIGO=HMN_CODIGO AND HMN_FECHA]+GetWhere("=",dFecha)+;
        [ LEFT  JOIN VIEW_TABMONXCLI     ON MON_CODIGO=CLI_CODMON ]+;
        [ WHERE MON_ACTIVO=1 AND ]+IF(lCliente,[MON_RECING=1 ],[MON_CBTPAG=1 ])+;
        [ GROUP BY ICJ_CODIGO ]+;
        [ ORDER BY HMN_VALOR DESC ]

//     [ LEFT  JOIN DPHISMON            ON MON_CODIGO=HMN_CODIGO AND MAX_FECHA=HMN_FECHA AND MAX_HORA=HMN_HORA ]+;
// ? CLPCOPY(cSql)

  aData:=ASQL(cSql)

  AEVAL(aData,{|a,n| aData[n,2]:=IF(a[2]=0 .OR. a[2]=1,EJECUTAR("DPGETVALCAM",a[7],dFecha),a[2])})

  cSql:=[ SELECT           ]+;
        [ MON_DESCRI     , ]+CRLF+;
        [ 1 AS DOS       , ]+CRLF+;
        [ 0 AS TRES      , ]+CRLF+;
        [ 0 AS CUATRO    , ]+CRLF+;
        [ 0 AS CINCO     , ]+CRLF+;
        [ 0 AS LOGICO    , ]+CRLF+;
        [ TDB_CODMON AS MONEDA, ]+CRLF+;
        [ "BCO" AS NUEVE , ]+CRLF+;
        [ TDB_CODIGO     , ]+CRLF+;
        [ TDB_NOMBRE    , ]+CRLF+;
        [ 0 AS IGTF     , ]+CRLF+;
        [ 0 AS TIGTF    , ]+CRLF+;
        [ 0 AS MONEDA   , ]+CRLF+;
        [ SPACE(10) AS MARCAFIN,]+CRLF+;
        [ SPACE(10) AS BANCO ,]+CRLF+;
        [ SPACE(20) AS CUENTA,]+CRLF+;
        [ SPACE(10) AS REFER ,0 AS LOGICO ]+CRLF+;
        [ FROM DPBANCOTIP  ]+CRLF+;
        [ LEFT JOIN DPTABMON ON MON_CODIGO=TDB_CODMON ]+CRLF+;
        [ WHERE TDB_ACTIVO=1 AND ]+IF(lCliente,[TDB_INGRES=1 ],[TDB_PAGOS=1 ])+CRLF+;
        [ ORDER BY TDB_NOMBRE ]
 
  aData1:=ASQL(cSql)

/*
  AEVAL(aData1,{|a,n| aData1[n,01  ]:=oDp:cMonedaNombre,;
                      aData1[n,07  ]:=oDp:cMoneda,;
                      aData1[n,06  ]:=.F.,;
                      aData1[n,nColIsMon]:=.F.})
*/

  AEVAL(aData1,{|a,n| aData1[n,02       ]:=IF(a[2]=0 .OR. a[2]=1,EJECUTAR("DPGETVALCAM",a[7],dFecha),a[2]),;
                      aData1[n,06       ]:=.F.,;
                      aData1[n,nColIsMon]:=.F.})

  AEVAL(aData1,{|a,n| AADD(aData,a)})

//  ViewArray(aData)

  IF ValType(oBrw)="O"
     oBrw:aArrayData:=ACLONE(aData)
     oBrw:Refresh(.T.)
  ENDIF

RETURN aData

