// Programa   : CNDAPTTOLIBCOM
// Fecha/Hora : 05/02/2024 15:39:29
// Propósito  : Generar los Apartados automaticamente
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cCenCos,dDesde,dHasta,dFchDec,cWhere,nValCam,lQuery)
  LOCAL cSql,oTable,oNew,nCxP,nMtoBas,nMtoExe:=0,cNumPar,cNumero

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cCenCos:=oDp:cCenCos  ,;
          dFchDec:=FCHINIMES(oDp:dFecha),;
          dDesde :=FCHINIMES(oDp:dFecha),;
          dHasta :=FCHFINMES(oDp:dFecha),;
          cWhere :=[ LEFT(PRO_SITUAC,1)='A' AND  (PRO_TIPO='Prestador de Servicios' OR PRO_TIPO='Servicios Públicos')  ],;
          lQuery :=.F.

  DEFAULT nValCam:=EJECUTAR("DPGETVALCAM",oDp:cMonedaExt)

  nValCam:=IF(nValCam=0,1,nValCam)

  SQLUPDATE("DPPROVEEDORPROG","PGC_CENCOS",cCenCos,"PGC_CENCOS IS NULL OR PGC_CENCOS"+GetWhere("=",""))

  cSql:=[ SELECT PRO_CODIGO,PRO_NOMBRE,PRO_TIPO  ,PGC_REFERE,PGC_CTAEGR,CEG_DESCRI,  PGC_IVA, ]+CRLF+;
        [ PGC_DESCRI,PGC_TIPDOC,PGC_MTODIV,PGC_TIPDES,PGC_NUMERO,TDC_CXP,TDC_CLRGRA ]+CRLF+;
        [ FROM  DPPROVEEDOR ]+CRLF+;
        [ INNER JOIN DPPROVEEDORPROG   ON PGC_CODSUC]+GetWhere("=",cCodSuc)+[ AND PGC_CENCOS]+GetWhere("=",cCenCos)+[ AND PGC_CODIGO=PRO_CODIGO ]+CRLF+;
        [ INNER JOIN DPTIPDOCPRO       ON PGC_TIPDOC=TDC_TIPO AND TDC_GASCND=1 AND TDC_AUTONU=1 AND TDC_ACTIVO=1 ]+CRLF+;
        [ LEFT  JOIN DPCTAEGRESO       ON PGC_CTAEGR=CEG_CODIGO ]+CRLF+;
        [ LEFT  JOIN DPLIBCOMPRASDET   ON PGC_CODSUC=LBC_CODSUC AND PGC_TIPDOC=LBC_TIPDOC AND PGC_CENCOS=LBC_CENCOS ]+;
        [ AND PGC_CODIGO=LBC_CODIGO ]+CRLF+;      
        [ AND PGC_NUMERO=LBC_REGPLA ]+CRLF+; 
        [ AND ]+GetWhereAnd("LBC_FECHA",dDesde,dHasta)+CRLF+[ AND LBC_FECHA IS NULL ]+CRLF+;
        [ WHERE ]+cWhere+;
        [ GROUP BY PRO_CODIGO,PRO_NOMBRE,PRO_TIPO  ORDER BY PGC_ITEM DESC ]


  IF lQuery
     RETURN cSql
  ENDIF

  oTable:=OpenTable(cSql,.T.)
  oTable:Browse()

  IF oTable:RecCount()=0
     oTable:End()
     RETURN .F.
  ENDIF

  oNew:=OpenTable("SELECT * FROM DPLIBCOMPRASDET",.F.)

  oTable:Browse()

  WHILE !oTable:Eof()

    cWhere :="LBC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
             "LBC_CENCOS"+GetWhere("=",cCenCos)+" AND "+;
             "LBC_FCHDEC"+GetWhere("=",dFchDec)

    nMtoBas:=ROUND(PGC_MTODIV,nValCam)

    nCxP:=0
    nCxP:=IF(oTable:TDC_CXP="D",1,nCxP)
    nCxP:=IF(oTable:TDC_CXP="C",1,nCxP)

    cNumPar:=SQLINCREMETAL("DPLIBCOMPRASDET","LBC_NUMPAR",cWhere,NIL,NIL,.T.,5)
// ,cNumero


    oNew:AppendBlank()
    oNew:Replace("LBC_CODSUC",cCodSuc)
    oNew:Replace("LBC_FCHDEC",dFchDec)
    oNew:Replace("LBC_CENCOS",cCenCos)
    oNew:Replace("LBC_CODIGO",oTable:PRO_CODIGO)
    oNew:Replace("LBC_REGPLA",oTable:PGC_NUMERO)
    oNew:Replace("LBC_CTAEGR",oTable:PGC_CTAEGR)
    oNew:Replace("LBC_TIPDOC",oTable:PGC_TIPDOC)
    oNew:Replace("LBC_REFERE",oTable:PGC_REFERE)
    oNew:Replace("LBC_TIPIVA",oTable:PGC_IVA)
    oNew:Replace("LBC_CXP"   ,nCxP   )
    oNew:Replace("LBC_MTOBAS",nMtoBas)
    oNew:Replace("LBC_VALCAM",nValCam)
    oNew:Replace("LBC_DESCRI",oTable:PGC_DESCRI)
    oNew:Commit("")

    oTable:DbSkip()

  ENDDO

  oNew:End(.T.)
  oTable:End(.T.)


? CLPCOPY(cSql)

RETURN .T.
/*
C001=LBC_ACTIVO          ,'L',001,0,'','Registro Activo',0,''
 C002=LBC_BASIMP          ,'N',019,0,'','Base;Imponible',0,''
 C003=LBC_CBTNUM          ,'C',010,0,'','Cbte.;Contable',0,''
 C004=LBC_CENCOS          ,'C',008,0,'','Centro;Costos',0,''
 C005=LBC_CODBCO          ,'C',006,0,'','Código de Banco',0,''
 C006=LBC_CODCAJ          ,'C',006,0,'','Código de Caja',0,''
 C007=LBC_CODCLI          ,'C',010,0,'','Código del Cliente',0,''
 C008=LBC_CODCTA          ,'C',020,0,'','Cuenta;Contable',0,'&oDp:cCtaIndef'
 C009=LBC_CODIGO          ,'C',010,0,'','Código del Proveedor',0,'&oDp:cCliCero'
 C010=LBC_CODMOD          ,'C',006,0,'','Cta;Ejercicio',0,''
 C011=LBC_CODMON          ,'C',003,0,'','Divisa',0,'&oDp:cMoneda'
 C012=LBC_CODSUC          ,'C',006,0,'','Cód.;Suc.',0,'&oDp:cSucursal'
 C013=LBC_COMORG          ,'C',012,0,'','Nacional;Importado',0,''
 C014=LBC_CONISR          ,'C',003,0,'','Concepto;ISLR',0,''
 C015=LBC_CTABCO          ,'C',020,0,'','Cuenta Bancaria',0,''
 C016=LBC_CTAEGR          ,'C',020,0,'','Cuenta;Egreso',0,'&oDp:cCtaIndef'
 C017=LBC_CXP             ,'N',001,0,'','CxP',0,''
 C018=LBC_DESCRI          ,'C',140,0,'','Descripción',0,''
 C019=LBC_FACAFE          ,'C',020,0,'','Factura;Afectada',0,''
 C020=LBC_FCHDEC          ,'D',008,0,'','Fecha de Declaración',0,''
 C021=LBC_FCHREG          ,'D',008,0,'','Fecha;Registro',0,''
 C022=LBC_FCHRTI          ,'D',008,0,'','Fecha;Retención',0,''
 C023=LBC_FECHA           ,'D',008,0,'','Fecha Emisión',0,''
 C024=LBC_ID              ,'C',003,0,'','ID del Recurso del Cliente',0,''
 C025=LBC_INSTRU          ,'C',004,0,'','Instrument Caja/Banco',0,''
 C026=LBC_ITEM            ,'C',005,0,'','Item',0,''
 C027=LBC_IVA_GN          ,'N',019,0,'','IVA;General',0,''
 C028=LBC_IVA_RD          ,'N',019,0,'','IVA;Reducida',0,''
 C029=LBC_IVA_S1          ,'N',019,0,'','IVA;Suntuario',0,''
 C030=LBC_MTOBAS          ,'N',019,2,'','Base;Imponible',0,''
 C031=LBC_MTOEXE          ,'N',019,2,'','Monto;Exento',0,''
 C032=LBC_MTOEXO          ,'N',019,0,'','Monto;Exonerado',0,''
 C033=LBC_MTOISR          ,'N',019,0,'','Monto;RET/ISLR',0,''
 C034=LBC_MTOIVA          ,'N',019,2,'','Monto;IVA',0,''
 C035=LBC_MTONCF          ,'N',019,0,'','Sin Crédito;Fiscal',0,''
 C036=LBC_MTONET          ,'N',019,2,'','Compra;con IVA',0,''
 C037=LBC_MTONSJ          ,'N',019,0,'','No;Sujeto',0,''
 C038=LBC_MTORTI          ,'N',019,2,'','Monto;Retención',0,''
 C039=LBC_NOTCRE          ,'C',010,0,'','Nota de Crédito',0,''
 C040=LBC_NOTDEB          ,'C',010,0,'','Nota de Débito',0,''
 C041=LBC_NUMFAC          ,'C',020,0,'','Número;Control',0,''
 C042=LBC_NUMFIS          ,'C',020,0,'','Número;Fiscal',0,''
 C043=LBC_NUMPAR          ,'C',005,0,'','Número;Partida',0,''
 C044=LBC_NUMRTI          ,'C',010,0,'','Número;Retención',0,''
 C045=LBC_PLAIMP          ,'C',010,0,'','Planilla;Import.',0,''
 C046=LBC_PORISR          ,'N',002,0,'','%;ISLR',0,''
 C047=LBC_PORIVA          ,'N',005,2,'','%;IVA',0,''
 C048=LBC_PORRTI          ,'N',006,0,'','%Ret;IVA',0,''
 C049=LBC_REGPLA          ,'C',008,0,'','Reg.;Planf',0,''
 C050=LBC_RIF             ,'C',015,0,'','RIF',0,''
 C051=LBC_TIPDOC          ,'C',003,0,'','Tipo;Doc.',0,''
 C052=LBC_TIPIVA          ,'C',002,0,'','Tipo;IVA',0,''
 C053=LBC_TIPTRA          ,'C',006,0,'','Tipo;Transac.',0,''
 C054=LBC_USOCON          ,'C',020,0,'','Contrapartida',0,''
 C055=LBC_USUARI          ,'C',003,0,'','Usuario',0,''
 C056=LBC_VALCAM          ,'N',019,6,'','Valor;Divisa',0,''
[END_FIELDS]
*/

// EOF
