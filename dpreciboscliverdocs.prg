// Programa   : DPRECIBOSCLIVERDOCS
// Fecha/Hora : 24/05/2019 05:04:16
// Propósito  : Visualizar Documentos
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oCliRec,lSave)
  LOCAL cSql,aData,oDb,I,oTable

  IF oCliRec=NIL  
     RETURN .F.
  ENDIF
/*
  cSql:=[ SELECT  ]+CRLF+;
        [ TDC_DESCRI, ]+CRLF+;
        [ DOC_NUMERO, ]+CRLF+;
        [ ORG_FECHA,  ]+CRLF+;
        [ IF(DOC_CXC=+1,0,DOC_NETO) AS DEBE, ]+CRLF+;
        [ IF(DOC_CXC=-1,0,DOC_NETO) AS HABER,]+CRLF+;
        [ ORG_VALCAM,]+CRLF+;
        [ DOC_NETO/DOC_VALCAM AS DOC_MTODIV,]+CRLF+;
        [ DOC_MTOCOM,]+CRLF+;
        [ DOC_NETO-ORG_MTOIVA AS NUEVE,]+CRLF+;
        [ IF(RTI_CODSUC IS NULL,0,1) AS RTI, ]+CRLF+;
        [ IF(RET_CODSUC IS NULL,0,1) AS ISLR,]+CRLF+;
        [ IF(RMU_CODSUC IS NULL,0,1) AS RMU  ]+CRLF+;
        [ FROM dpdoccli ]+CRLF+;
        [ INNER JOIN dptipdoccli     ON DOC_TIPDOC=TDC_TIPO ]+CRLF+;
        [ INNER JOIN view_docclidoc  ON DOC_CODSUC=ORG_CODSUC AND DOC_TIPDOC=ORG_TIPDOC AND DOC_NUMERO=ORG_NUMERO ]+CRLF+;
        [ LEFT  JOIN view_doccliislr ON DOC_CODSUC=RET_CODSUC AND DOC_TIPDOC=RET_TIPDOC AND DOC_NUMERO=RET_NUMERO ]+CRLF+;
        [ LEFT  JOIN view_DOCCLIRTI  ON DOC_CODSUC=RTI_CODSUC AND DOC_TIPDOC=RTI_TIPDOC AND DOC_NUMERO=RTI_NUMERO ]+CRLF+;
        [ LEFT  JOIN view_DOCCLIRMU  ON DOC_CODSUC=RMU_CODSUC AND DOC_TIPDOC=RMU_TIPDOC AND DOC_NUMERO=RMU_NUMDOC ]+CRLF+;
        [ WHERE DOC_CODSUC ]+GetWhere("=",oCliRec:REC_CODSUC)+[ AND DOC_RECNUM]+GetWhere("=",oCliRec:REC_NUMERO)+;
        [ AND DOC_ACT=1 AND (DOC_TIPTRA='P' OR (DOC_DOCORG='R' AND DOC_TIPTRA='P'))]+CRLF+;
        [ ORDER BY DOC_FECHA ]
*/
  // 19/10/2022 incluido anticipo creado desde recibo de ingreso
  cSql:=[ SELECT  ]+CRLF+;
        [ TDC_DESCRI, ]+CRLF+;
        [ DOC_NUMERO, ]+CRLF+;
        [ ORG_FECHA,  ]+CRLF+;
        [ IF(DOC_CXC=+1,0,DOC_NETO) AS DEBE, ]+CRLF+;
        [ IF(DOC_CXC=-1,0,DOC_NETO) AS HABER,]+CRLF+;
        [ ORG_VALCAM,]+CRLF+;
        [ DOC_NETO/DOC_VALCAM AS DOC_MTODIV,]+CRLF+;
        [ DOC_MTOCOM,]+CRLF+;
        [ DOC_NETO-ORG_MTOIVA AS NUEVE,]+CRLF+;
        [ IF(RTI_CODSUC IS NULL,0,1) AS RTI, ]+CRLF+;
        [ IF(RET_CODSUC IS NULL,0,1) AS ISLR,]+CRLF+;
        [ IF(RMU_CODSUC IS NULL,0,1) AS RMU  ]+CRLF+;
        [ FROM dpdoccli ]+CRLF+;
        [ INNER JOIN dptipdoccli     ON DOC_TIPDOC=TDC_TIPO ]+CRLF+;
        [ LEFT  JOIN view_docclidoc  ON DOC_CODSUC=ORG_CODSUC AND DOC_TIPDOC=ORG_TIPDOC AND DOC_NUMERO=ORG_NUMERO ]+CRLF+;
        [ LEFT  JOIN view_doccliislr ON DOC_CODSUC=RET_CODSUC AND DOC_TIPDOC=RET_TIPDOC AND DOC_NUMERO=RET_NUMERO ]+CRLF+;
        [ LEFT  JOIN view_DOCCLIRTI  ON DOC_CODSUC=RTI_CODSUC AND DOC_TIPDOC=RTI_TIPDOC AND DOC_NUMERO=RTI_NUMERO ]+CRLF+;
        [ LEFT  JOIN view_DOCCLIRMU  ON DOC_CODSUC=RMU_CODSUC AND DOC_TIPDOC=RMU_TIPDOC AND DOC_NUMERO=RMU_NUMDOC ]+CRLF+;
        [ WHERE DOC_CODSUC ]+GetWhere("=",oCliRec:REC_CODSUC)+[ AND DOC_RECNUM]+GetWhere("=",oCliRec:REC_NUMERO)+;
        [ AND DOC_ACT=1 AND (DOC_TIPTRA='P' OR (DOC_DOCORG='R' AND DOC_TIPTRA='P' OR DOC_TIPDOC='ANT'))]+CRLF+;
        [ ORDER BY DOC_FECHA ]

//  [ WHERE DOC_RECNUM ]+GetWhere("=",oCliRec:REC_CODSUC)+[ AND REC_NUMERO]+GetWhere("=",oCliRec:REC_NUMERO)+[ AND DOC_ACT=1 AND (DOC_TIPTRA='P' OR (DOC_DOCORG='R' AND DOC_TIPTRA='P'))]+CRLF+;

  aData:=ASQL(cSql)

// ? CLPCOPY(cSql)

  DPWRITE("TEMP\DPRECIBOSCLIVERDOCS.SQL",oDp:cSql)

  IF Empty(aData)
    aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
  ENDIF

  // 12/01/2024, si la vista esta vacia, solicita su generación y nuevamente lectura del query
  IF !Empty(aData) .AND. Empty(aData[1,3])
    EJECUTAR("SETVISTAS",NIL,"docclidoc",NIL,.T.,NIL,NIL)
    aData:=ASQL(cSql)
  ENDIF

  AEVAL(aData,{|a,n| aData[n,10]:=CTOO(a[10],"L"),;
                     aData[n,11]:=CTOO(a[11],"L"),;
                     aData[n,12]:=CTOO(a[12],"L")})


  oCliRecX:aDocOrg:={}

  FOR I=1 TO LEN(aData)
     AADD(oCliRecX:aDocOrg,{1,2,3,4,5,6,7,8,.T.,10})
  NEXT 

// ViewArray(aData)
// ViewArray(aData)

  oCliRec:oBrwD:aArrayData:=ACLONE(aData)

  oCliRec:oBrwD:Gotop(.T.)
  oCliRec:oBrwD:nArrayAt:=1
  oCliRec:oBrwD:nRowSel :=1
  oCliRec:oBrwD:Refresh(.T.)

  oCliRec:oBrwD:bChange   :={||NIL} // QUITAR 24/12/2021
  oCliRec:oBrwD:bKeyDown  :={||NIL}
  oCliRec:oBrwD:bLDblClick:={||NIL}

//  oBrw:bChange      := {|oBrw|oCliRecX:BrwChange()}


  cWhere:=[ WHERE DOC_CODSUC ]+GetWhere("=",oCliRec:REC_CODSUC)+[ AND DOC_RECNUM]+GetWhere("=",oCliRec:REC_NUMERO)+;
          [ AND DOC_ACT=1 AND (DOC_TIPTRA='P' OR (DOC_DOCORG='R' AND DOC_TIPTRA='P'))]

// ? oDp:cWhere

  cSql :=" SELECT DOC_CODIGO,DOC_CODSUC,DOC_CXC,TDC_DESCRI,DOC_TIPDOC,DOC_NUMERO,(DOC_NETO*DOC_CXC) AS DOC_NETO,8 AS OCHO,1 AS LOGICO,10 AS DIEZ FROM DPDOCCLI "+;
         " LEFT JOIN dptipdoccli     ON DOC_TIPDOC=TDC_TIPO "+;
         oDp:cWhere

//       cWhere
//? CLPCOPY(cSql)

  DPWRITE("TEMP\DPRECIBOSDOCORG.SQL",cSql)

  oTable:=OpenTable(cSql,.t.)
//  oTable:Browse()
  oCliRec:aDocOrg:=ACLONE(oTable:aDataFill)

  IF Empty(oCliRec:aDocOrg)
     AADD(oCliRecX:aDocOrg,{1,2,3,4,5,6,7,8,.T.,10})
  ENDIF

//ViewArray(oCliRec:aDocOrg)

  oTable:End()

  EJECUTAR("BRWCALTOTALES",oCliRec:oBrwD)

RETURN .T.
// EOF
