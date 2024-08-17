// Programa   : DPRECIBODIV_DOCCLI
// Fecha/Hora : 01/03/2023 00:01:41
// Propósito  : Lectura Datos de Clientes
// Creado Por : Juan Navas
// Llamado por: DPRECIBODOV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodigo,aTipDoc,cWhereNot,lAnticipo,lPagoC,oBrwD,cDb,cNumRec)
   LOCAL aData,cSql,cWhere,oDb:=NIL,cSql2,aData2:={},cSql3,aData3:={}
   LOCAL nAt,nRowSel,aTotal,I

   DEFAULT cWhereNot:="",;
           lAnticipo:=.F.,;
           lPagoC   :=.F.

   IF lAnticipo
     cWhereNot:=[ AND (1=0) ]
   ENDIF

   IF cDb<>NIL
     oDb:=OpenOdbc(cDb)
   ENDIF
/*
   18/08/2024
   IF !EJECUTAR("DBISTABLE",cDb,"VIEW_DOCCLIDESORG",.F.)
      EJECUTAR("ADDFIELDS_2301",NIL,.T.)
   ENDIF
*/
   // Requieren nombre de la moneda
   // 18/08/2024 SQLUPDATE("DPBANCOTIP","TDB_CODMON",oDp:cMoneda,"TDB_CODMON"+GetWhere("=","")+" OR TDB_CODMON IS NULL")

   IF lPagoC

     cSql:=[ SELECT      ]+;
           [ DOC_TIPDOC, ]+;
           [ IF(CCG_NOMBRE IS NULL,CLI_NOMBRE,CCG_NOMBRE) AS CLI_NOMBRE, ]+;
           [ DOC_NUMERO, ]+;
           [ DOR_FECHA,  ]+;
           [ CXD_NETO,   ]+;
           [ DOR_VALCAM, ]+;
           [ CXD_CXCDIV, ]+;
           [ 0 AS PAGDIV,]+;
           [ 0 AS PAGMTO,]+;
           [ 0 AS DIFCAM,]+;
           [ 0 AS LOGICO,]+;
           [ TDC_CXC    ,]+;
           [ DOC_CODMON ,]+;
           [ DOC_CODIGO ,TDC_REVALO ]+;
           [ FROM DPDOCCLI  ]+;
           [ LEFT  JOIN DPTABMON          ON DOC_CODMON=MON_CODIGO   ]+;
           [ INNER JOIN DPTIPDOCCLI       ON DOC_TIPDOC=TDC_TIPO     ]+;
           [ INNER JOIN VIEW_DOCCLICXCDIV ON DOC_CODSUC=CXD_CODSUC AND DOC_TIPDOC=CXD_TIPDOC AND DOC_NUMERO=CXD_NUMERO AND CXD_CXCDIV<>0 ]+;
           [ LEFT  JOIN VIEW_DOCCLIDESORG ON DOC_CODSUC=DOR_CODSUC AND DOC_TIPDOC=DOR_TIPORG AND DOC_NUMERO=DOR_DOCORG ]+;
           [ LEFT  JOIN DPCLIENTES        ON DOC_CODIGO=CLI_CODIGO ]+;
           [ LEFT   JOIN DPCLIENTESCERO ON CCG_CODSUC=DOC_CODSUC AND CCG_TIPDOC=DOC_TIPDOC AND CCG_NUMDOC=DOC_NUMERO ]+;
           [ WHERE (]+GetWhereOr("DOC_TIPDOC",aTipDoc)+[ AND DOC_TIPTRA]+GetWhere("=","D")+[ AND DOC_ACT=1 )  ]+;
           [ GROUP BY DOC_TIPDOC,DOC_NUMERO ]+;
           [ ORDER BY DOR_FECHA ]


//  ? CLPCOPY(cSql)
//           [ WHERE (]+GetWhereOr("DOC_TIPDOC",aTipDoc)+[ AND DOC_TIPTRA]+GetWhere("=","D")+[ AND DOC_ACT=1 )  ]+cWhereNot+;

   ELSE
   
      cSql:=[ SELECT      ]+;
            [ DOC_TIPDOC, ]+;
            [ TDC_DESCRI, ]+;
            [ DOC_NUMERO, ]+;
            [ DOR_FECHA,  ]+;
            [ CXD_NETO,   ]+;
            [ DOR_VALCAM, ]+;
            [ CXD_CXCDIV, ]+;
            [ 0 AS PAGDIV,]+;
            [ 0 AS PAGMTO,]+;
            [ 0 AS DIFCAM,]+;
            [ 0 AS LOGICO,]+;
            [ TDC_CXC    ,]+;
            [ DOC_CODMON ,]+;
            [ DOC_FACAFE ,]+;
            [ TDC_REVALO  ]+;
            [ FROM DPDOCCLI  ]+;
            [ LEFT  JOIN DPTABMON          ON DOC_CODMON=MON_CODIGO   ]+;
            [ INNER JOIN DPTIPDOCCLI       ON DOC_TIPDOC=TDC_TIPO  AND TDC_PAGOS=1   ]+;
            [ INNER JOIN VIEW_DOCCLICXCDIV ON DOC_CODSUC=CXD_CODSUC AND DOC_TIPDOC=CXD_TIPDOC AND DOC_NUMERO=CXD_NUMERO AND CXD_CXCDIV<>0 ]+;
            [ LEFT  JOIN VIEW_DOCCLIDESORG ON DOC_CODSUC=DOR_CODSUC AND DOC_TIPDOC=DOR_TIPORG AND DOC_NUMERO=DOR_DOCORG ]+;
            [ WHERE (DOC_CODIGO]+GetWhere("=",cCodigo)+[ AND DOC_TIPTRA]+GetWhere("=","D")+[ AND DOC_ACT=1 )  ]+cWhereNot+;
            [ GROUP BY DOC_TIPDOC,DOC_NUMERO ]+;
            [ ORDER BY DOR_FECHA ]


// ? "otros",cSql


  ENDIF

  aData:={}

  IF !lAnticipo

     aData:=ASQL(cSql,oDb)

     // CXC no revalorizables
     cSql2:=[ SELECT      ]+;
            [ DOC_TIPDOC, ]+;
            [ TDC_DESCRI, ]+;
            [ DOC_NUMERO, ]+;
            [ DOR_FECHA,  ]+;
            [ CXD_NETO,   ]+;
            [ DOR_VALCAM, ]+;
            [ CXD_CXCDIV, ]+;
            [ 0 AS PAGDIV,]+;
            [ 0 AS PAGMTO,]+;
            [ 0 AS DIFCAM,]+;
            [ 0 AS LOGICO,]+;
            [ TDC_CXC    ,]+;
            [ DOC_CODMON ,]+;
            [ DOC_FACAFE ,]+;
            [ 0 AS LOGICO  ]+;
            [ FROM DPDOCCLI  ]+;
            [ LEFT  JOIN DPTABMON          ON DOC_CODMON=MON_CODIGO   ]+;
            [ INNER JOIN DPTIPDOCCLI       ON DOC_TIPDOC=TDC_TIPO  AND TDC_PAGOS=1   ]+;
            [ INNER JOIN VIEW_DOCCLICXC    ON DOC_CODSUC=CXD_CODSUC AND DOC_TIPDOC=CXD_TIPDOC AND DOC_NUMERO=CXD_NUMERO AND CXD_NETO<>0 ]+;
            [ LEFT  JOIN VIEW_DOCCLIDESORG ON DOC_CODSUC=DOR_CODSUC AND DOC_TIPDOC=DOR_TIPORG AND DOC_NUMERO=DOR_DOCORG ]+;
            [ WHERE (DOC_CODIGO]+GetWhere("=",cCodigo)+[ AND DOC_TIPTRA]+GetWhere("=","D")+[ AND DOC_ACT=1 AND DOC_VALCAM=1)  ]+cWhereNot+;
            [ GROUP BY DOC_TIPDOC,DOC_NUMERO ]+;
            [ ORDER BY DOR_FECHA ]

/*
29/05/2024
     cSql2:=[ SELECT     ]+;
            [ DOC_TIPDOC,]+;
            [ TDC_DESCRI,]+;
            [ DOC_NUMERO,]+;
            [ DOC_FECHA, ]+;
            [ (DOC_NETO*DOC_CXC) AS DOC_NETO, ]+;
            [ DOC_VALCAM, ]+;
            [ (DOC_NETO*DOC_CXC) AS CXD_CXCDIV,]+;
            [ 0 AS PAGDIV,]+;
            [ 0 AS PAGMTO,]+;
            [ 0 AS DIFCAM,]+;
            [ 0 AS LOGICO,]+;
            [ TDC_CXC,    ]+;
            [ DOC_CODMON, ]+;
            [ DOC_FACAFE, ]+;
            [ TDC_REVALO,]+;
            [ (SELECT SUM((DOC_NETO+DOC_MTOCOM)*DOC_CXC*-1) AS PAGADO FROM dpdoccli AS T2 ]+;
            [ WHERE T1.DOC_CODSUC=T2.DOC_CODSUC AND DOC_TIPDOC=T2.DOC_TIPDOC AND T1.DOC_NUMERO=T2.DOC_NUMERO AND DOC_TIPTRA="P" AND DOC_ACT=1 ) AS DOC_MTOPAG ]+;
            [ FROM dpdoccli AS t1 ]+;
            [ INNER JOIN dptipdoccli ON TDC_TIPO=DOC_TIPDOC ]+;
            [ WHERE (DOC_CODIGO]+GetWhere("=",cCodigo)+[ AND DOC_TIPTRA]+GetWhere("=","D")+[ AND DOC_ACT=1 )  ]+cWhereNot+;
            [ AND  (DOC_VALCAM=0 OR DOC_VALCAM=1) ]+;
            [ HAVING (DOC_NETO<>0 AND DOC_MTOPAG IS NULL) ]
*/

// 14/08/2024
//     aData2:=ASQL(cSql2)
//     AEVAL(aData2,{|a,n| aData2[n]:=ASIZE(aData2[n],15)}) 
//     AEVAL(aData2,{|a,n| AADD(aData,a)}) // 24/02/2024 Duplicaba el registro


   

  ENDIF

  IF EMPTY(aData)
    aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
  ELSE
     DPWRITE("TEMP\RECIBOSCLIDOCCLI.SQL",oDp:cSql)
  ENDIF

  // Ahora debe Incluir los Pagos del Recibo de Ingreso

  IF !Empty(cNumRec)

     cSql3:=[ SELECT DOC_TIPDOC,TDC_DESCRI,DOC_NUMERO,DOR_FECHA,DOR_NETO,DOR_VALCAM,DOC_MTODIV,  ]+;
            [ DOC_MTODIV AS PAGDIV, DOC_NETO AS PAGMTO, 0 AS DIFCAM, 1 AS LOGICO, TDC_CXC,DOC_CODMON,DOC_FACAFE,TDC_REVALO ]+CRLF+;
            [ FROM DPDOCCLI ]+;
            [ LEFT  JOIN DPTABMON          ON DOC_CODMON=MON_CODIGO ]+;
            [ INNER JOIN DPTIPDOCCLI       ON DOC_TIPDOC=TDC_TIPO  ]+;
            [ INNER JOIN VIEW_DOCCLIDESORG ON DOC_CODSUC=DOR_CODSUC AND DOC_TIPDOC=DOR_TIPORG AND DOC_NUMERO=DOR_DOCORG  ]+;
            [ WHERE (DOC_CODIGO]+GetWhere("=",cCodigo)+[ AND DOC_TIPTRA='P' AND DOC_ACT=1 AND DOC_RECNUM]+GetWhere("=",cNumRec)+[)]+;   
            [ GROUP BY DOC_TIPDOC,DOC_NUMERO ]+; 
            [ ORDER BY DOR_FECHA ]

     aData3:=ASQL(cSql3,oDb)

     FOR I=1 TO LEN(aData3)

         nAt:=ASCAN(aData,{|a,n| a[1]=aData3[I,1] .AND. a[3]=aData3[I,3]})

         IF nAt=0
            AADD(aData,aData3[I])
         ELSE
            aData[nAt,8]:=aData3[I,8]
            aData[nAt,9]:=aData3[I,9]
//          ? nAt,"PAGO PARCIAL, DEBE CLONARLE EL PAGO, EL DOCUMENTO ESTA PENDIENTE"
         ENDIF

     NEXT I

     // ViewArray(aData3)


  ENDIF

// ? CLPCOPY(cSql)

  AEVAL(aData,{|a,n|aData[n,11]:=(a[9]>0),;
                    aData[n,12]:=SAYOPTIONS("DPTIPDOCCLI","TDC_CXC",a[12])})

  // ViewArray(aData)
  // Crea el Registro de Anticipo

  IF lAnticipo
     aData[1,1]:="ANT"
     aData[1,2]:=" CREAR "+SQLGET("DPTIPDOCCLI","TDC_DESCRI","TDC_TIPO"+GetWhere("=","ANT"))
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
