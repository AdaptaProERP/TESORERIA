// Programa   : LIBCOMVALRIF
// Fecha/Hora : 14/02/2024 09:17:56
// Propósito  : Validar RIF
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oCol,uValue,nCol,nKey)
  LOCAL oTable,cCtaOld:="",cDescri,cWhere,lOk:=.F.,cCodRet:=""
  LOCAL oRif,cCtaEgr,cCodCta:="",cNomCta:="",nPorIva,cTipIva,nPorRti,cCodigo,cRif,cCodCli,cNombre:=""
  LOCAL aLine     :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]
  LOCAL cRifAnt   :=aLine[nCol]
  LOCAL cWhere    :=oLIBCOMEDIT:LIBWHERE()
  LOCAL nColPorRti:=0 // oLIBCOMEDIT:LBCGETCOLPOS("LBC_PORRTI")
  LOCAL nColTipIva:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_TIPIVA")
  LOCAL nColDescri:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_DESCRI")
  LOCAL nColCtaEgr:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_CTAEGR")
  LOCAL nColCodCta:=0
  LOCAL cTipDoc   :=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_TIPDOC")
  LOCAL oColConIsr:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_CONISR]

  IF oLIBCOMEDIT:COL_LBC_PORRTI>0
     nColPorRti:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_PORRTI")
  ENDIF
 
  DEFAULT nKey:=0

  DEFAULT oCol:lButton:=.F.

  IF oCol:lButton=.T.
     oCol:lButton:=.F.
     RETURN .T.
  ENDIF

  IF !Empty(cRifAnt) .AND. cRifAnt<>uValue

   // Cambia el Codigo del Cliente/Provedor
   IF oLIBCOMEDIT:lVenta
      SQLUPDATE("DPCLIENTES" ,{"CLI_RIF","CLI_CODIGO"},{uValue,uValue},"CLI_RIF"+GetWhere("=",cRifAnt))
   ELSE
      SQLUPDATE("DPPROVEEDOR",{"PRO_RIF","PRO_CODIGO"},{uValue,uValue},"PRO_RIF"+GetWhere("=",cRifAnt))
   ENDIF

  ENDIF

  IF !oLIBCOMEDIT:lVenta .AND. !ISSQLFIND("DPPROVEEDOR","PRO_RIF"+GetWhere("=",uValue))

    cRif:=EJECUTAR("FINDCODENAME","DPPROVEEDOR","PRO_RIF","PRO_NOMBRE",oCol,NIL,uValue)

    IF !Empty(cRif)
       uValue:=cRif
    ENDIF
    
  ENDIF

  IF oLIBCOMEDIT:lVenta .AND. !ISSQLFIND("DPCLIENTES","CLI_RIF"+GetWhere("=",uValue))

    cRif:=EJECUTAR("FINDCODENAME","DPCLIENTES","CLI_RIF","CLI_NOMBRE",oCol,NIL,uValue)

    IF !Empty(cRif)
       uValue:=cRif
    ENDIF

  ENDIF

  IF !oLIBCOMEDIT:lVenta
    cNombre:=SQLGET("DPPROVEEDOR","PRO_NOMBRE,PRO_RETIVA,PRO_CODIGO","PRO_RIF"+GetWhere("=",uValue))
    nPorIva:=DPSQLROW(2)
  ELSE
    cNombre:=SQLGET("DPCLIENTES","CLI_NOMBRE,CLI_RETIVA,CLI_CODIGO","CLI_RIF"+GetWhere("=",uValue))
    nPorIva:=DPSQLROW(2)
  ENDIF

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol+1]:=cNombre
  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue

  IF !oLIBCOMEDIT:lVenta .AND. !ISSQLFIND("DPPROVEEDOR","PRO_RIF"+GetWhere("=",uValue))

    oDp:aRif:={}

    IF LEN(uValue)>=10 .AND. oDp:lAutRif
      lOk:=EJECUTAR("VALRIFSENIAT",uValue,!ISDIGIT(uValue),ISDIGIT(uValue)) 
    ENDIF

    IF lOk .AND. LEN(oDp:aRif)>1 .AND. !("NO ENCON"$oDp:aRif[1] .OR. "NO EXIS"$UPPER(oDp:aRif[1]))

       cCodigo:=uValue

       oLIBCOMEDIT:CREATEPROVEEDOR(uValue,oDp:aRif[1] ,VAL(oDp:aRif[2]))

   ELSE

      // 31/01/2024 NO debe llamar LBX debe permitir agregar cliente EVAL(oCol:bEditBlock)  

      IF Empty(cRifAnt) .AND. Empty(cNombre)
         oCol:oBrw:nColSel:=oLIBCOMEDIT:COL_LBC_RIF+1
         RETURN .T.
      ENDIF

    ENDIF

  ENDIF

  IF oLIBCOMEDIT:lVenta .AND. !ISSQLFIND("DPCLIENTES","CLI_RIF"+GetWhere("=",uValue))

    oDp:aRif:={}

    IF LEN(uValue)>=10 .AND. oDp:lAutRif
      lOk:=EJECUTAR("VALRIFSENIAT",uValue,!ISDIGIT(uValue),ISDIGIT(uValue)) 
    ENDIF

    IF lOk .AND. LEN(oDp:aRif)>1 .AND. !("NO ENCON"$oDp:aRif[1] .OR. "NO EXIS"$UPPER(oDp:aRif[1]))

       cCodigo:=uValue

       oLIBCOMEDIT:CREATECLIENTE(uValue,oDp:aRif[1],VAL(oDp:aRif[2]))

   ELSE

      // 31/01/2024 NO debe llamar LBX debe permitir agregar cliente EVAL(oCol:bEditBlock)  
      // EVAL(oCol:bEditBlock)  

      IF Empty(cRifAnt) .AND. Empty(cNombre)
         oCol:oBrw:nColSel:=oLIBCOMEDIT:COL_LBC_RIF+1
         RETURN .T.
      ENDIF

    ENDIF

 ENDIF
 
 IF !oLIBCOMEDIT:lCtaEgr 
    cCodCta:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_CODCTA")
 ELSE
    cCtaEgr:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_CTAEGR")
 ENDIF
 
 IF Empty(cCodCta) .AND. !oLIBCOMEDIT:lCtaEgr 

   cCodCta:=SQLGET(oLIBCOMEDIT:cTable,"LBC_CODCTA,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                                      "LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CODCTA"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")

   IF Empty(cCodCta)
      cCodCta:=SQLGET(oLIBCOMEDIT:cTable,"LBC_CODCTA,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CODCTA"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")
   ENDIF

   IF Empty(cCodCta)
      oLIBCOMEDIT:PUTCTATIPDOC()
   ENDIF

   nColCodCta:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_CODCTA")
   cCodCta   :=SQLGET(oLIBCOMEDIT:cTable,"LBC_CODCTA,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CODCTA"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")
   cTipIva   :=DPSQLROW(2)
   nPorRti   :=DPSQLROW(3)
   cDescri   :=PADR(DPSQLROW(4),140)

   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_COMORG)

   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColCodCta]:=cCodCta
   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColTipIva]:=cTipIva

   IF nColPorRti>0
      oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColPorRti]:=nPorRti
   ENDIF

   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColDescri]:=cDescri

   cNomCta:=SQLGET("DPCTA","CTA_DESCRI","CTA_CODMOD"+GetWhere("=",oDp:cCtaMod)+" AND CTA_CODIGO"+GetWhere("=",cCodCta))

   IF !Empty(cCodCta)
     SQLUPDATE(oLIBCOMEDIT:cTable,"LBC_CODCTA",cCodCta,cWhere)
   ENDIF

 ENDIF

 IF Empty(cCtaEgr) .AND. oLIBCOMEDIT:lCtaEgr 

   cCtaEgr:=SQLGET(oLIBCOMEDIT:cTable,"LBC_CTAEGR,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                                      "LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CTAEGR"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")

   IF Empty(cCtaEgr)
      cCtaEgr:=SQLGET(oLIBCOMEDIT:cTable,"LBC_CTAEGR,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CTAEGR"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")
   ENDIF

   cTipIva:=DPSQLROW(2)
   nPorRti:=DPSQLROW(3)
   cDescri:=PADR(DPSQLROW(4),140)

   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColCtaEgr]:=cCtaEgr
   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColTipIva]:=cTipIva

   IF nColPorRti>0
     oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColPorRti]:=nPorRti
   ENDIF

   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColDescri]:=cDescri

   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_CTAEGR)

   cNomCta:=SQLGET("DPCTAEGRESO","CEG_DESCRI","CEG_CODIGO"+GetWhere("=",cCtaEgr))

   IF !Empty(cCodCta)
     SQLUPDATE(oLIBCOMEDIT:cTable,"LBC_CTAEGR",cCtaEgr,cWhere)
   ENDIF

  ENDIF
	
  IF !oLIBCOMEDIT:lVenta

/*
    cCodRet:=SQLGET(oLIBCOMEDIT:cTable,"LBC_CONISR","LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CONISR"+GetWhere("<>","")+" ORDER BY LBC_NUMISR DESC LIMIT 1")
    oLIBCOMEDIT:PUTFIELDVALUE(oColConIsr,cCodRet,oLIBCOMEDIT:COL_LBC_CONISR,nKey)
*/

    cNombre:=SQLGET("DPPROVEEDOR","PRO_NOMBRE,PRO_RETIVA,PRO_CODIGO","PRO_RIF"+GetWhere("=",uValue))
    nPorIva:=DPSQLROW(2)

  ELSE

    cNombre:=SQLGET("DPCLIENTES","CLI_NOMBRE,CLI_RETIVA,CLI_CODIGO","CLI_RIF"+GetWhere("=",uValue))
    nPorIva:=DPSQLROW(2)

  ENDIF

  cCodigo    :=DPSQLROW(3)
  oLIBCOMEDIT:cRif    := oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol]
  oLIBCOMEDIT:lAcction:=.F.

  SQLUPDATE(oLIBCOMEDIT:cTable,"LBC_CODIGO",cCodCli,oLIBCOMEDIT:LIBWHERE())

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue
  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol+1]:=cNombre

  oLIBCOMEDIT:LIBSAVEFIELD(nCol)

  // Cuenta Contable
  IF !oLIBCOMEDIT:lCtaEgr
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CODCTA]:=cCodCta
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_CTA_DESCRI]:=cNomCta
  ELSE
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CTAEGR]:=cCtaEgr
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_CEG_DESCRI]:=cNomCta
  ENDIF

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_COMORG]:="Nacional"

  oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_COMORG)

  oLIBCOMEDIT:LIBCOMGRABAR(.T.) // guardar todo el registro

  // IF Empty(cDescri)
  //   oCol:oBrw:nColSel:=nCol+1
  // ENDIF

  IF !Empty(cCodCta)
    oCol:oBrw:nColSel:=oLIBCOMEDIT:COL_LBC_DESCRI
  ELSE
    oCol:oBrw:nColSel:=oLIBCOMEDIT:COL_LBC_CODCTA
  ENDIF

  // 08/03/2024 nombre del proveedor quedó vacio
  IF !oLIBCOMEDIT:lVenta .AND. Empty(aLine[oLIBCOMEDIT:COL_PRO_NOMBRE])
     oCol:oBrw:nColSel:=oLIBCOMEDIT:COL_PRO_NOMBRE
  ENDIF

  IF oLIBCOMEDIT:lVenta .AND. Empty(aLine[oLIBCOMEDIT:COL_CLI_NOMBRE])
     oCol:oBrw:nColSel:=oLIBCOMEDIT:COL_CLI_NOMBRE
  ENDIF

  oCol:oBrw:DrawLine(.T.)

RETURN .T.

