// Programa   : DPRECIBODIV_DOCPRO
// Fecha/Hora : 01/03/2023 00:01:41
// Propósito  : Lectura Datos de Clientes
// Creado Por : Juan Navas
// Llamado por: DPRECIBODOV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodigo,aTipDoc,cWhereNot,lAnticipo,lPagoC,oBrwD,cDb)
   LOCAL aData,cSql,cWhere
   LOCAL nAt,nRowSel,aTotal

   DEFAULT cWhereNot:="",;
           cDb:=oDp:cDsnData

   IF lAnticipo
     cWhereNot:=[ AND (1=0) ]
   ENDIF

   IF cDb<>NIL
     oDb:=OpenOdbc(cDb)
   ENDIF

   IF !EJECUTAR("DBISTABLE",cDb,"VIEW_DOCPRODESORG",.F.)
      EJECUTAR("ADDFIELDS_2301",NIL,.T.)
   ENDIF

   EJECUTAR("DPDOCPRORTISETVALCAM","DOC_CODIGO"+GetWhere("=",cCodigo))

   IF lPagoC

     cSql:=[ SELECT      ]+;
           [ DOC_TIPDOC, ]+;
           [ IF(CCG_NOMBRE IS NULL,PRO_NOMBRE,CCG_NOMBRE) AS PRO_NOMBRE, ]+;
           [ DOC_NUMERO, ]+;
           [ DOR_FECHA,  ]+;
           [ CXD_NETO,   ]+;
           [ DOR_VALCAM, ]+;
           [ CXD_CXPDIV, ]+;
           [ 0 AS PAGDIV,]+;
           [ 0 AS PAGMTO,]+;
           [ 0 AS DIFCAM,]+;
           [ 0 AS LOGICO,]+;
           [ TDC_CXP    ,]+;
           [ DOC_CODMON ,]+;
           [ DOC_CODIGO ,TDC_REVALO ]+;
           [ FROM DPDOCPRO  ]+;
           [ LEFT  JOIN DPTABMON          ON DOC_CODMON=MON_CODIGO   ]+;
           [ INNER JOIN DPTIPDOCPRO       ON DOC_TIPDOC=TDC_TIPO     ]+;
           [ INNER JOIN VIEW_DOCPROCXPDIV ON DOC_CODSUC=CXD_CODSUC AND DOC_TIPDOC=CXD_TIPDOC AND DOC_NUMERO=CXD_NUMERO AND CXD_CXPDIV<>0 ]+;
           [ LEFT  JOIN VIEW_DOCPRODESORG ON DOC_CODSUC=DOR_CODSUC AND DOC_TIPDOC=DOR_TIPORG AND DOC_CODIGO=DOR_CODIGO AND DOC_NUMERO=DOR_DOCORG ]+;
           [ INNER JOIN DPPROVEEDOR       ON DOC_CODIGO=PRO_CODIGO ]+;
           [ LEFT   JOIN DPPROVEEDORCERO  ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_CODIGO=DOC_CODIGO AND CCG_NUMDOC=DOC_NUMERO ]+;
           [ WHERE (]+GetWhereOr("DOC_TIPDOC",aTipDoc)+[ AND DOC_TIPTRA]+GetWhere("=","D")+[ AND DOC_ACT=1 )  ]+cWhereNot+;
           [ GROUP BY DOC_TIPDOC,DOC_CODIGO,DOC_NUMERO ]+;
           [ ORDER BY DOR_FECHA ]

   ELSE
   
      cSql:=[ SELECT      ]+;
            [ DOC_TIPDOC, ]+;
            [ TDC_DESCRI, ]+;
            [ DOC_NUMERO, ]+;
            [ DOR_FECHA,  ]+;
            [ CXD_NETO,   ]+;
            [ DOR_VALCAM, ]+;
            [ CXD_CXPDIV, ]+;
            [ 0 AS PAGDIV,]+;
            [ 0 AS PAGMTO,]+;
            [ 0 AS DIFCAM,]+;
            [ 0 AS LOGICO,]+;
            [ TDC_CXP    ,]+;
            [ DOC_CODMON ,]+;
            [ DOC_FACAFE ,]+;
            [ TDC_REVALO  ]+;
            [ FROM DPDOCPRO  ]+;
            [ LEFT  JOIN DPTABMON          ON DOC_CODMON=MON_CODIGO   ]+;
            [ INNER JOIN DPTIPDOCPRO       ON DOC_TIPDOC=TDC_TIPO         ]+;
            [ INNER JOIN VIEW_DOCPROCXPDIV ON DOC_CODSUC=CXD_CODSUC AND DOC_TIPDOC=CXD_TIPDOC AND DOC_NUMERO=CXD_NUMERO AND CXD_CXPDIV<>0 ]+;
            [ LEFT  JOIN VIEW_DOCPRODESORG ON DOC_CODSUC=DOR_CODSUC AND DOC_TIPDOC=DOR_TIPORG AND DOC_NUMERO=DOR_DOCORG ]+;
            [ WHERE (DOC_CODIGO]+GetWhere("=",cCodigo)+[ AND DOC_TIPTRA]+GetWhere("=","D")+[ AND DOC_ACT=1 )  ]+cWhereNot+;
            [ GROUP BY DOC_TIPDOC,DOC_NUMERO ]+;
            [ ORDER BY DOR_FECHA ]
  ENDIF

  aData:=ASQL(cSql)

  DPWRITE("TEMP\RECIBOSCLIDOCPRO.SQL",oDp:cSql)

// ? CLPCOPY(oDp:cSql)

  AEVAL(aData,{|a,n|aData[n,12] :=SAYOPTIONS("DPTIPDOCPRO","TDC_CXP",a[12])})

  IF EMPTY(aData)
    aData:=EJECUTAR("SQLARRAYEMPTY",cSql)
  ENDIF

  // Crea el Registro de Anticipo
  IF lAnticipo
     aData[1,1]:="ANT"
     aData[1,2]:=" CREAR "+SQLGET("DPTIPDOCPRO","TDC_DESCRI","TDC_TIPO"+GetWhere("=","ANT"))
  ENDIF

  IF ValType(oBrwD)="O"

     oBrwD:aArrayData:=ACLONE(aData)

     aTotal:=ATOTALES(aData)

     oBrwD:aArrayData:=ACLONE(aData)
     EJECUTAR("BRWCALTOTALES",oBrwD,.F.)

     nAt    :=oBrwD:nArrayAt
     nRowSel:=oBrwD:nRowSel

     oBrwD:Refresh(.F.)
     oBrwD:nArrayAt  :=MIN(nAt,LEN(aData))
     oBrwD:nRowSel   :=MIN(nRowSel,oBrwD:nRowSel)

  ENDIF

RETURN aData
// EOF

