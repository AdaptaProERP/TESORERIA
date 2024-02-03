// Programa   : BRLIBCOMEDIT
// Fecha/Hora : 18/11/2022 22:43:00
// Propósito  : "Libro de Compras editable"
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,dFchDec,lView,cCodCaj,cCodBco,cNumRei,cCodCli,cId,cCenCos,aTipDoc,lCondom,lCtaEgr,lVenta)
   LOCAL aData,aFechas,cFileMem:="USER\BRLIBCOMEDIT.MEM",V_nPeriodo:=1,cCodPar,dFchPag:=CTOD("")
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer
   LOCAL lConectar:=.F.,aFields:={}
   LOCAL aIva   :={} // ATABLE("SELECT TIP_CODIGO FROM DPIVATIP WHERE TIP_ACTIVO=1 AND TIP_COMPRA=1")
   LOCAL aCodCta:={}
   
   // cuenta de Egreso para condominios

   oDp:cRunServer:=NIL

   IF Type("oLIBCOMEDIT")="O" .AND. oLIBCOMEDIT:oWnd:hWnd>0
      RETURN EJECUTAR("BRRUNNEW",oLIBCOMEDIT,GetScript())
   ENDIF

   DEFAULT lVenta:=.F.

   aIva:=ATABLE("SELECT TIP_CODIGO FROM DPIVATIP WHERE TIP_ACTIVO=1 AND "+IF(lVenta,"TIP_VENTA","TIP_COMPRA"),"=1")


   DEFAULT oDp:lCondominio:=.F.,;
           cNumRei:=""


   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
     ENDIF

   ENDIF

   IF Empty(cNumRei)

     IF lVenta
       cTitle :="Registro de Documentos de Ventas [Editable]" +IF(Empty(cTitle),"",cTitle)
       lCondom:=.F.
       // lCtaEgr:=.F. // las ventas tambien puede ser cta egreso
     ELSE
       cTitle :="Registro Compras para Proveedores Ocasionales en el Libro de Compras [Editable]" +IF(Empty(cTitle),"",cTitle)
     ENDIF

   ENDIF

   oDp:oFrm:=NIL

   IF FILE(cFileMem) .AND. nPeriodo=NIL
      RESTORE FROM (cFileMem) ADDI
      nPeriodo:=V_nPeriodo
   ENDIF

   DEFAULT cCodSuc :=oDp:cSucursal,;
           nPeriodo:=4,;
           dDesde  :=CTOD(""),;
           dHasta  :=CTOD(""),;
           lView   :=.F.   

   DEFAULT lCtaEgr:=.F.,;
           lCondom:=.T.

   // Condominio 
   IF lCondom .AND. !lVenta

      IF !oDp:IsDef("lCndCtaEgr")
         EJECUTAR("CNDCONFIGLOAD")
      ENDIF

      lCtaEgr:=oDp:lCndCtaEgr // Cuentas de Egreso

      cTitle:="Registro de Compras y Gastos " 

   ENDIF

   DEFAULT dFchDec :=FCHFINMES(oDp:dFecha)

   DEFAULT cWhere:="LBC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                   "LBC_FCHDEC"+GetWhere("=",dFchDec)

   dFchPag:=SQLGET("DPDOCPROPROG","PLP_FECHA","PLP_TIPDOC"+GetWhere("=","F30")+" AND PLP_FCHDEC"+GetWhere("=",dFchDec))

   // Obtiene el Código del Parámetro

   IF !Empty(cWhere)

      cCodPar:=ATAIL(_VECTOR(cWhere,"="))

      IF TYPE(cCodPar)="C"
        cCodPar:=SUBS(cCodPar,2,LEN(cCodPar))
        cCodPar:=LEFT(cCodPar,LEN(cCodPar)-1)
      ENDIF

   ENDIF

   IF .T. .AND. (!nPeriodo=11 .AND. (Empty(dDesde) .OR. Empty(dhasta)))

       aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)
       dDesde :=aFechas[1]
       dHasta :=aFechas[2]

   ENDIF

   IF nPeriodo=10
      dDesde :=V_dDesde
      dHasta :=V_dHasta
   ELSE
      aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)
      dDesde :=aFechas[1]
      dHasta :=aFechas[2]
   ENDIF

   oDp:nValCam :=EJECUTAR("DPGETVALCAM",oDp:cMonedaExt,oDp:dFecha) // nValCam

   aData  :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere),NIL,cServer,NIL,lCondom,lCtaEgr,lVenta)
   aFields:=ACLONE(oDp:aFields)

   IF Empty(aTipDoc) .AND. lCondom .AND. !lVenta
     aTipDoc:=ATABLE("SELECT TDC_TIPO FROM DPTIPDOCPRO WHERE TDC_GASCND=1 AND TDC_ACTIVO=1")
   ENDIF

   IF Empty(aTipDoc) .AND. !lVenta
     aTipDoc:={"FAC","DEB","CRE","OPA","NRC","GAS"}
   ENDIF

   IF Empty(aTipDoc) .AND. lVenta
     aTipDoc:={"FAV","FAM","DEB","CRE"}
   ENDIF

   IF lVenta
 
      // Cliente Vacio
      IF !ISSQLFIND("DPCLIENTES","CLI_RIF"+GetWhere("=",SPACE(10)))

         EJECUTAR("CREATERECORD","DPCLIENTES",{"CLI_CODIGO","CLI_RIF"           ,"CLI_NOMBRE","CLI_RETIVA"          ,"CLI_ESTADO"},;
                                              {SPACE(10)   ,SPACE(10)           ,SPACE(10)   ,0                     ,"Activo"    },;
                                               NIL,.T.,"CLI_RIF"+GetWhere("=",SPACE(10)))
      ENDIF

      aCodCta:=ASQL([ SELECT TDC_TIPO,CIC_CUENTA,CTA_DESCRI,TDC_CXC,TDC_CLRGRA,TDC_DESCRI,"" AS TDC_NUMDOC,TDC_LIBVTA ]+;
                    [ FROM DPTIPDOCCLI ]+;
                    [ LEFT JOIN DPTIPDOCCLI_CTA ON CIC_CTAMOD]+GetWhere("=",oDp:cCtaMod)+[ AND CIC_CODIGO=TDC_TIPO ]+;
                    [ LEFT JOIN DPCTA           ON CIC_CTAMOD=CTA_CODMOD AND CIC_CUENTA=CTA_CODIGO ]+;
                    [ WHERE ]+GetWhereOr("TDC_TIPO",aTipDoc))

      AEVAL(aCodCta,{|a,n,nCxC| nCxC:=0,;
                                nCxC:=IF(a[4]="D",+1,nCxC),;
                                nCxC:=IF(a[4]="C",-1,nCxC),;
                                aCodCta[n,4]:=nCxC        ,;
                                aCodCta[n,7]:=EJECUTAR("DPDOCCLIGETNUM",a[1])})
   ELSE

      IF !ISSQLFIND("DPPROVEEDOR","PRO_RIF"+GetWhere("=",SPACE(10)))

         EJECUTAR("CREATERECORD","DPPROVEEDOR",{"PRO_CODIGO","PRO_RIF"           ,"PRO_NOMBRE","PRO_RETIVA"          ,"PRO_ESTADO"},;
                                               {SPACE(10)   ,SPACE(10)           ,SPACE(10)   ,0                     ,"Activo"    },;
                                               NIL,.T.,"PRO_RIF"+GetWhere("=",SPACE(10)))
      ENDIF

      aCodCta:=ASQL([ SELECT TDC_TIPO,CIC_CUENTA,CTA_DESCRI,TDC_CXP,TDC_CLRGRA,TDC_DESCRI,"" AS TDC_NUMDOC,TDC_LIBCOM ]+;
                    [ FROM DPTIPDOCPRO ]+;
                    [ LEFT JOIN DPTIPDOCPRO_CTA ON CIC_CTAMOD]+GetWhere("=",oDp:cCtaMod)+[ AND CIC_CODIGO=TDC_TIPO ]+;
                    [ LEFT JOIN DPCTA           ON CIC_CTAMOD=CTA_CODMOD AND CIC_CUENTA=CTA_CODIGO ]+;
                    [ WHERE ]+GetWhereOr("TDC_TIPO",aTipDoc))

      AEVAL(aCodCta,{|a,n,nCxP| nCxP:=0,;
                                nCxP:=IF(a[4]="D",+1,nCxP),;
                                nCxP:=IF(a[4]="C",-1,nCxP),;
                                aCodCta[n,4]:=nCxP        ,;
                                aCodCta[n,7]:=EJECUTAR("DPDOCPROGETNUM",a[1])})



   ENDIF

   AEVAL(aCodCta,{|a,n| aCodCta[n,1]:=ALLTRIM(a[1]) })

   IF Empty(aData)
      MensajeErr("no hay "+cTitle,"Información no Encontrada")
      RETURN .F.
   ENDIF

   ViewData(aData,cTitle,oDp:cWhere,cNumRei)

   oDp:oFrm:=oLIBCOMEDIT

RETURN .T.


FUNCTION ViewData(aData,cTitle,cWhere_,cNumRei)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

   DpMdi(cTitle,"oLIBCOMEDIT","BRLIBCOMEDITX.EDT")

   oLIBCOMEDIT:Windows(0,0,aCoors[3]-160,MIN(4318,aCoors[4]-10),.T.) // Maximizado

   oLIBCOMEDIT:cCodSuc    :=cCodSuc
   oLIBCOMEDIT:lMsgBar    :=.F.
   oLIBCOMEDIT:cPeriodo   :=aPeriodos[nPeriodo]
   oLIBCOMEDIT:cCodSuc    :=cCodSuc
   oLIBCOMEDIT:nPeriodo   :=nPeriodo
   oLIBCOMEDIT:cNombre    :=""
   oLIBCOMEDIT:dDesde     :=dDesde
   oLIBCOMEDIT:cServer    :=cServer
   oLIBCOMEDIT:dHasta     :=dHasta
   oLIBCOMEDIT:cWhere     :=cWhere
   oLIBCOMEDIT:cWhere_    :=cWhere_
   oLIBCOMEDIT:cWhereQry  :=""
   oLIBCOMEDIT:cSql       :=oDp:cSql
   oLIBCOMEDIT:oWhere     :=TWHERE():New(oLIBCOMEDIT)
   oLIBCOMEDIT:cCodPar    :=cCodPar // Código del Parámetro
   oLIBCOMEDIT:lWhen      :=.T.
   oLIBCOMEDIT:cTextTit   :="" // Texto del Titulo Heredado
   oLIBCOMEDIT:oDb        :=oDp:oDb
   oLIBCOMEDIT:cBrwCod    :="LIBCOMEDIT"
   oLIBCOMEDIT:lTmdi      :=.T.
   oLIBCOMEDIT:aHead      :={}
   oLIBCOMEDIT:lBarDef    :=.T. // Activar Modo Diseño.
   oLIBCOMEDIT:dFchDec    :=dFchDec
   oLIBCOMEDIT:dFchPag    :=dFchPag
   oLIBCOMEDIT:aFields    :=ACLONE(aFields)
   oLIBCOMEDIT:lSave      :=.F.
   oLIBCOMEDIT:aTipDoc    :=ACLONE(aTipDoc)
   oLIBCOMEDIT:aIva       :=ACLONE(aIva)
   oLIBCOMEDIT:cCodSuc    :=oDp:cSucursal
   oLIBCOMEDIT:cCodCaj    :=cCodCaj
   oLIBCOMEDIT:cCodBco    :=cCodBco
   oLIBCOMEDIT:cNumRei    :=cNumRei
   oLIBCOMEDIT:lReintegro :=!Empty(cNumRei)
   oLIBCOMEDIT:cCodCli    :=cCodCli   // Cliente en el caso de condominio
   oLIBCOMEDIT:cCodPro    :=SPACE(10) // Código del proveedor
   oLIBCOMEDIT:cNomPro    :=SPACE(10) // Nombre del Proveedor
   oLIBCOMEDIT:cCenCos    :=cCenCos
   oLIBCOMEDIT:nCxP       :=0 
   oLIBCOMEDIT:oFrmRefresh:=NIL
   oLIBCOMEDIT:lCondom    :=lCondom  // Condominios, debe incluir la planificacion realizada
   oLIBCOMEDIT:lCtaEgr    :=lCtaEgr
   oLIBCOMEDIT:lVenta     :=lVenta
   oLIBCOMEDIT:cWherePro  :=" (1=1) "
   oLIBCOMEDIT:cTable     :=IF(!lVenta,"DPLIBCOMPRASDET","DPLIBVENTASDET")
   oLIBCOMEDIT:aCodCta    :=ACLONE(aCodCta)
   oLIBCOMEDIT:cTipo      :=IF(oLIBCOMEDIT:lCondom,"Prestador de Servicios","Ocasional")

   IF !oLIBCOMEDIT:lVenta
     oLIBCOMEDIT:cWherePro  :=" NOT (LEFT(PRO_RIF,1)"+GetWhere("=","G")+" OR LEFT(PRO_RIF,1)"+GetWhere("=","T")+")"
   ENDIF


   // Condominios Cliente y Propiedad. 
   oLIBCOMEDIT:cCodCli:=cCodCli
   oLIBCOMEDIT:cId    :=cId // DPCLIENTESCLI=ITEM

   oLIBCOMEDIT:cItemChange:=""
   oLIBCOMEDIT:LBC_FCHDEC :=dFchDec

   // Guarda los parámetros del Browse cuando cierra la ventana
   oLIBCOMEDIT:bValid   :={|| EJECUTAR("BRWSAVEPAR",oLIBCOMEDIT)}

   oLIBCOMEDIT:lBtnRun     :=.F.
   oLIBCOMEDIT:lBtnMenuBrw :=.F.
   oLIBCOMEDIT:lBtnSave    :=.F.
   oLIBCOMEDIT:lBtnCrystal :=.F.
   oLIBCOMEDIT:lBtnRefresh :=.F.
   oLIBCOMEDIT:lBtnHtml    :=.T.
   oLIBCOMEDIT:lBtnExcel   :=.T.
   oLIBCOMEDIT:lBtnPreview :=.T.
   oLIBCOMEDIT:lBtnQuery   :=.F.
   oLIBCOMEDIT:lBtnOptions :=.T.
   oLIBCOMEDIT:lBtnPageDown:=.T.
   oLIBCOMEDIT:lBtnPageUp  :=.T.
   oLIBCOMEDIT:lBtnFilters :=.T.
   oLIBCOMEDIT:lBtnFind    :=.T.
   oLIBCOMEDIT:lBtnColor   :=.T.

   oLIBCOMEDIT:nClrPane1:=16775408
   oLIBCOMEDIT:nClrPane2:=16771797

   oLIBCOMEDIT:nClrText :=0
   oLIBCOMEDIT:nClrText1:=4227072
   oLIBCOMEDIT:nClrText2:=0
   oLIBCOMEDIT:nClrText3:=0

   oLIBCOMEDIT:oBrw:=TXBrowse():New( IF(oLIBCOMEDIT:lTmdi,oLIBCOMEDIT:oWnd,oLIBCOMEDIT:oDlg ))
   oLIBCOMEDIT:oBrw:SetArray( aData, .F. )
   oLIBCOMEDIT:oBrw:SetFont(oFont)

   oLIBCOMEDIT:oBrw:lFooter     := .T.
   oLIBCOMEDIT:oBrw:lHScroll    := .T.
   oLIBCOMEDIT:oBrw:nHeaderLines:= 3
   oLIBCOMEDIT:oBrw:nDataLines  := 1
   oLIBCOMEDIT:oBrw:nFooterLines:= 1
   oLIBCOMEDIT:oBrw:nFreeze     :=4+1

   oLIBCOMEDIT:aData            :=ACLONE(aData)

   AEVAL(oLIBCOMEDIT:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   // Crear nombre de las Columnas
   AEVAL(oDp:aFields,{|a,n| oLIBCOMEDIT:SET("COL_"+a[1],n)})

   IF Empty(aData[1,1])
      aData[1,oLIBCOMEDIT:COL_LBC_NUMPAR]:=STRZERO(1,5)
      aData[1,oLIBCOMEDIT:COL_LBC_ITEM]  :=STRZERO(1,5)
   ENDIF

   IF oLIBCOMEDIT:lCtaEgr
      oLIBCOMEDIT:COL_LBC_CODCTA:=oLIBCOMEDIT:COL_LBC_CTAEGR
   ENDIF

   IF !oLIBCOMEDIT:lVenta
      oLIBCOMEDIT:COL_LBC_CXC:=oLIBCOMEDIT:COL_LBC_CXP
   ENDIF

   AEVAL(aData,{|a,n|aData[n,oLIBCOMEDIT:COL_LBC_COMORG]:=ALLTRIM(SAYOPTIONS(oLIBCOMEDIT:cTable,"LBC_COMORG",a[oLIBCOMEDIT:COL_LBC_COMORG]))})


   // Campo: LBC_TIPDOC
   oCol:=oLIBCOMEDIT:oBrw:aCols[1]
   oCol:cHeader       :='Tipo'+CRLF+'Doc.'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
   oCol:nWidth        := 40
   oCol:nEditType     :=IIF( lView, 0, 1)
   oCol:bOnPostEdit   :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTTIPDOC(oCol,uValue,1,nKey)}
   oCol:aEditListTxt  :=oLIBCOMEDIT:aTipDoc
   oCol:aEditListBound:=oLIBCOMEDIT:aTipDoc
   oCol:nEditType     :=EDIT_LISTBOX

   oCol:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oLIBCOMEDIT:oBrw,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                                                 nClrText:=aLine[oLIBCOMEDIT:COL_TDC_CLRGRA],;
                                                 {nClrText,iif( oBrw:nArrayAt%2=0, oLIBCOMEDIT:nClrPane1, oLIBCOMEDIT:nClrPane2 ) } }



   // Campo: LBC_DIA
   oCol:=oLIBCOMEDIT:oBrw:aCols[2]
   oCol:cHeader       :='Día'
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
   oCol:nWidth        := 40
   oCol:nEditType     :=IIF( lView, 0, 1)
   oCol:bOnPostEdit   :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTDIA(oCol,uValue,2,nKey)}
   oCol:cEditPicture  :='99'
   oCol:bStrData      :={|nDia,oCol|nDia:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,2],;
                                    oCol:= oLIBCOMEDIT:oBrw:aCols[2],;
                                    FDP(nDia,oCol:cEditPicture)}

   // Campo: LBC_FECHA
   oCol:=oLIBCOMEDIT:oBrw:aCols[3]
   oCol:cHeader      :='Fecha'+CRLF+'Emisión'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
   oCol:nWidth       := 72
   oCol:nEditType    :=IIF( lView, 0, 1)
   oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFECHA(oCol,uValue,3,nKey)}
   oCol:nEditType    :=EDIT_GET_BUTTON
   oCol:bEditBlock   :={||EJECUTAR("BRWEDITCALENDARIO",oLIBCOMEDIT:oBrw)}

  // Campo: LBC_RIF
  oCol:=oLIBCOMEDIT:oBrw:aCols[4]
  oCol:cHeader      :='RIF'+CRLF+IF(lVenta,"Cliente","Proveedor")
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 100
  oCol:nEditType    :=IIF( lView, 0, EDIT_GET_BUTTON)
  oCol:bEditBlock   :={||oLIBCOMEDIT:EDITRIF(4,.F.)}
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALRIF(oCol,uValue,4,nKey)}
  oCol:lButton      :=.F.


  // Campo: PRO_NOMBRE
  oCol:=oLIBCOMEDIT:oBrw:aCols[5]
  oCol:cHeader      :='Nombre o Razon Social'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 220
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALRIFNOMBRE(oCol,uValue,5,nKey)}

  IF lVenta

    oCol:bStrData     :={|cData,oCol|cData:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_CLI_NOMBRE],;
                                     oCol := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_CLI_NOMBRE],;
                                     cData}
  ELSE

    oCol:bStrData     :={|cData,oCol|cData:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_PRO_NOMBRE],;
                                     oCol:= oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_PRO_NOMBRE],;
                                     cData}
  ENDIF

  IF !oLIBCOMEDIT:lCtaEgr

   // Campo: LBC_CODCTA
   oCol:=oLIBCOMEDIT:oBrw:aCols[6]
   oCol:cHeader      :='Cuenta'+CRLF+'Contable'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
   oCol:nWidth       := 100
   oCol:nEditType    :=IIF( lView, 0, EDIT_GET_BUTTON)
   oCol:bEditBlock   :={||oLIBCOMEDIT:EDITCTA(5,.F.)}
   oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALCTA(oCol,uValue,6,nKey)}
   oCol:lButton      :=.F.

   // Campo: CTA_DESCRI
   oCol:=oLIBCOMEDIT:oBrw:aCols[7]
   oCol:cHeader      :='Nombre'+CRLF+'Cuenta'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
   oCol:nWidth       := 180

  ELSE

   // Campo: LBC_CTAEGR
   oCol:=oLIBCOMEDIT:oBrw:aCols[6]
   oCol:cHeader      :='Cuenta'+CRLF+'Egreso'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
   oCol:nWidth       := 100
   oCol:nEditType    :=IIF( lView, 0, EDIT_GET_BUTTON)
   oCol:bEditBlock   :={||oLIBCOMEDIT:EDITCTA(5,.F.)}
   oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALCTA(oCol,uValue,6,nKey)}
   oCol:lButton      :=.F.

   oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALCTAEGR(oCol,uValue,6,nKey)}

   // Campo: CTA_DESCRI
   oCol:=oLIBCOMEDIT:oBrw:aCols[7]
   oCol:cHeader      :='Descripción'+CRLF+'De la Cuenta'
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
   oCol:nWidth       := 200
   oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALNOMBREEGR(oCol,uValue,7,nKey,NIL,.T.)}


  ENDIF

  // Campo: LBC_DESCRI
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_DESCRI]
  oCol:cHeader      :='Descripción'+CRLF+"del Asiento"
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 220
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_DESCRI,nKey,NIL,.T.)}

  // Campo: LBC_NUMFAC
  oCol:=oLIBCOMEDIT:oBrw:aCols[9]
  oCol:cHeader      :='Número'+CRLF+'Doc'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALNUMFAC(oCol,uValue,9,nKey)}

  // Campo: LBC_NUMFIS
  oCol:=oLIBCOMEDIT:oBrw:aCols[10]
  oCol:cHeader      :='Número'+CRLF+'Fiscal'
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,10,nKey,NIL,.T.)}

  // Campo: LBC_FACAFE
  oCol:=oLIBCOMEDIT:oBrw:aCols[11]
  oCol:cHeader      :='Factura'+CRLF+'Afectada'
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 120
  oCol:nEditType    :=0 // Solo Activa si es DEBITO O CREDITO IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,11,nKey)}

  // Campo: LBC_MTOBAS
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOBAS]
  oCol:cHeader      :='Monto'+CRLF+'sin IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 120
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData     :={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTOBAS],;
                                    oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOBAS],;
                                    FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[oLIBCOMEDIT:COL_LBC_MTOBAS],oCol:cEditPicture)
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALLBCMTOBAS(oCol,uValue,oLIBCOMEDIT:COL_LBC_MTOBAS,nKey)}


  // Campo: LBC_TIPIVA
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_TIPIVA]
  oCol:cHeader       :='IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth        := 72
  oCol:nEditType     :=IIF( lView, 0, 1)
  oCol:bOnPostEdit   :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTTIPIVA(oCol,uValue,oLIBCOMEDIT:COL_LBC_TIPIVA,nKey)}
  oCol:aEditListTxt  :=oLIBCOMEDIT:aIva
  oCol:aEditListBound:=oLIBCOMEDIT:aIva
  oCol:nEditType     :=EDIT_LISTBOX

  // Campo: LBC_PORIVA
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_PORIVA]
  oCol:cHeader      :='%'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_PORIVA,nKey)}
  oCol:cEditPicture :='99.99'
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 

  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_PORIVA],;
                               oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_PORIVA],;
                               FDP(nMonto,oCol:cEditPicture)}

// oCol:cFooter      :=FDP(aTotal[oLIBCOMEDIT:COL_LBC_PORIVA	],oCol:cEditPicture)


  // Campo: LBC_MTOIVA
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOIVA]
  oCol:cHeader      :='Monto'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_MTOIVA,nKey)}
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData     :={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTOIVA],;
                                    oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOIVA],;
                                    FDP(nMonto,oCol:cEditPicture)}

  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cFooter      :=FDP(aTotal[oLIBCOMEDIT:COL_LBC_MTOIVA],oCol:cEditPicture)

 // Campo: LBC_MTONET
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTONET]
  oCol:cHeader      :='Monto'+CRLF+'Neto'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:nEditType    :=IIF( lView, 0, 1)
//oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_MTONET,nKey)}
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:CALBASEIMP(oCol,uValue,oLIBCOMEDIT:COL_LBC_MTONET,nKey)}

  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:cFooter      :=FDP(aTotal[oLIBCOMEDIT:COL_LBC_MTONET],oCol:cEditPicture)

  oCol:bStrData     :={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTONET],;
                                    oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTONET],;
                                    FDP(nMonto,oCol:cEditPicture)}

  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 

 // Campo: LBC_PORRTI
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_PORRTI]
  oCol:cHeader      :="%"+CRLF+"RET"+CRLF+"IVA"+CRLF+"IVA"
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 40
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALPORRTI(oCol,uValue,oLIBCOMEDIT:COL_LBC_PORRTI,nKey)}
  oCol:cEditPicture :='9,999,999,999,999,999.99'

  // Campo: LBC_MTORTI
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTORTI]
  oCol:cHeader      :='Monto'+CRLF+'Retención'+CRLF+"IVA"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTORTI],;
                              oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTORTI],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[oLIBCOMEDIT:COL_LBC_MTORTI],oCol:cEditPicture)
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_MTORTI,nKey)}


  // Campo: LBC_NUMRTI
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_NUMRTI]
  oCol:cHeader      :='Número'+CRLF+'Retención'+CRLF+"IVA"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_NUMRTI,nKey)}

  // Campo: LBC_CONISR
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_CONISR]
  oCol:cHeader      :='Con-'+CRLF+'cepto'+CRLF+"ISLR"
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_CONISR,nKey)}

 // Campo: LBC_PORISR
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_PORISR]
  oCol:cHeader      :="%"+CRLF+"RET"+CRLF+"ISR"
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 40
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:VALPORISR(oCol,uValue,oLIBCOMEDIT:COL_LBC_PORISR,nKey)}
  oCol:cEditPicture :='9,999,999,999,999,999.99'

  // Campo: LBC_MTOISR
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOISR]
  oCol:cHeader      :='Monto'+CRLF+'Retención'+CRLF+"ISR"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTOISR],;
                              oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOISR],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[oLIBCOMEDIT:COL_LBC_MTOISR],oCol:cEditPicture)
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_MTOISR,nKey)}

  // Campo: LBC_COMORG
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_COMORG]
  oCol:cHeader      :='Nacional'+CRLF+IF(oLIBCOMEDIT:lVenta,"Exportación",'Importado')
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 32
  oCol:bClrStd      := {|nClrText,uValue|uValue:=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_COMORG],;
                           nClrText:=COLOR_OPTIONS(oLIBCOMEDIT:cTable,"LBC_COMORG",uValue),;
                         {nClrText,iif( oLIBCOMEDIT:oBrw:nArrayAt%2=0, oLIBCOMEDIT:nClrPane1, oLIBCOMEDIT:nClrPane2 ) } } 
  oCol:aEditListTxt  :={"Nacional","Importada"}
  oCol:aEditListBound:={"Nacional","Importada"}
  oCol:nEditType     :=EDIT_LISTBOX
  oCol:bOnPostEdit   :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_COMORG,nKey,1)}


  // Campo: LBC_USOCON
  IF Empty(oLIBCOMEDIT:cCodCaj)

    oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_USOCON]
    oCol:cHeader       :='Contra-'+CRLF+'Partida'
    oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
    oCol:nWidth        := 80
    oCol:nEditType     :=IIF( lView, 0, 1)
    oCol:aEditListTxt  :={"Cuentas x Pagar","Caja","Caja Divisa","Banco","Banco Divisa"}
    oCol:aEditListBound:=oCol:aEditListTxt
    oCol:bOnPostEdit   :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_USOCON,nKey)}
    oCol:nEditType     :=EDIT_LISTBOX

  ELSE

    oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_USOCON]
    oCol:cHeader       :="Pago"
    oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
    oCol:nWidth        := 80
    oCol:nEditType     :=IIF( lView, 0, 1)
    oCol:aEditListTxt  :={"Caja","Banco","CXP"}
    oCol:aEditListBound:=oCol:aEditListTxt
    oCol:bOnPostEdit   :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_USOCON,nKey)}
    oCol:nEditType     :=EDIT_LISTBOX

 
  ENDIF

  // Campo: LBC_VALCAM Valor Cambiario
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_VALCAM]
  oCol:cHeader      :='Monto'+CRLF+'Valor'+CRLF+"Cambiario"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :=oDp:cPictValCam
  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_VALCAM],;
                              oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_VALCAM],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[oLIBCOMEDIT:COL_LBC_VALCAM],oCol:cEditPicture)
  oCol:nEditType    :=IIF( lView, 0, 1)
  oCol:bOnPostEdit  :={|oCol,uValue,nKey|oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_VALCAM,nKey)}

  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_REGDOC]
  oCol:cHeader      := "Regis-"+CRLF+"trado"
  oCol:nWidth       := 40
  oCol:AddBmpFile("BITMAPS\checkverde.bmp")
  oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
  oCol:bBmpData    := { |oBrw|oBrw:=oLIBCOMEDIT:oBrw,IIF(oBrw:aArrayData[oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_REGDOC],1,2) }
  oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
  oCol:bStrData    :={||""}
//oCol:bLDClickData:={||oLIBCOMEDIT:DELASIENTOS()}

  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_ACTIVO]
  oCol:cHeader      := "Reg."+CRLF+"Activo"
  oCol:nWidth       := 40
  oCol:AddBmpFile("BITMAPS\checkverde.bmp")
  oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
  oCol:bBmpData    := { |oBrw|oBrw:=oLIBCOMEDIT:oBrw,IIF(oBrw:aArrayData[oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_ACTIVO],1,2) }
  oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
  oCol:bStrData    :={||""}
  oCol:bLDClickData:={||oLIBCOMEDIT:DELASIENTOS()}

  // Campo: LBC_NUMPAR
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_NUMPAR]
  oCol:cHeader      :='Núm.'+CRLF+'Par-'+CRLF+"tida"
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80


  // Campo: LBC_ITEM
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_ITEM]
  oCol:cHeader      :='Núm.'+CRLF+'Item'
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  // Campo: LBC_REGPLA
  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_REGPLA]
  oCol:cHeader      :='Reg.'+CRLF+'Planif.'
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  // Campo: LBC_REGPLA
  IF !oLIBCOMEDIT:lVenta
    oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_CXP]
    oCol:cHeader      :="CxP"
    oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
    oCol:nWidth       := 80
    oCol:cEditPicture :='999'
    oCol:bStrData     :={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CXP],;
                                      oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_CXP],;
                                      FDP(nMonto,oCol:cEditPicture)}


  ELSE
    oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_CXC]
    oCol:cHeader      :="CxC"
    oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
    oCol:nWidth       := 80
  ENDIF

  oCol:=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_TDC_CLRGRA]
  oCol:cHeader      :="Color"+CRLF+"Texto"
  oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oLIBCOMEDIT:oBrw:aArrayData ) } 
  oCol:nWidth       := 80
  oCol:cEditPicture :='99999999999'
  oCol:bStrData     :={|nMonto,oCol|nMonto:= oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_TDC_CLRGRA],;
                                    oCol  := oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_TDC_CLRGRA],;
                                    FDP(nMonto,oCol:cEditPicture)}

  oLIBCOMEDIT:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))

  oLIBCOMEDIT:oBrw:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oLIBCOMEDIT:oBrw,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                                                 nClrText:=oLIBCOMEDIT:nClrText,;
                                                 nClrText:=IF(aLine[oLIBCOMEDIT:COL_LBC_ITEM]<>STRZERO(1,5),oLIBCOMEDIT:nClrText1,nClrText),;
                                                 nClrText:=IF(.F.,oLIBCOMEDIT:nClrText2,nClrText),;
                                                 {nClrText,iif( oBrw:nArrayAt%2=0, oLIBCOMEDIT:nClrPane1, oLIBCOMEDIT:nClrPane2 ) } }

  oLIBCOMEDIT:oBrw:bClrHeader          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
  oLIBCOMEDIT:oBrw:bClrFooter          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

  oLIBCOMEDIT:oBrw:bLDblClick:={|oBrw|oLIBCOMEDIT:RUNCLICK() }

  oLIBCOMEDIT:oBrw:bChange:={||oLIBCOMEDIT:BRWCHANGE()}

  AEVAL(oLIBCOMEDIT:oBrw:aCols,{|oCol,n| oCol:cHeader:=oCol:cHeader+CRLF+LSTR(n)})
  oLIBCOMEDIT:oBrw:CreateFromCode()
  oLIBCOMEDIT:oWnd:oClient := oLIBCOMEDIT:oBrw

  // Copiar Edición de ColumnasColumnas

  oLIBCOMEDIT:aEditType:={}

  oLIBCOMEDIT:aFieldItemF:={"LBC_CODCTA","LBC_DESCRI","LBC_MTOBAS","LBC_TIPIVA","LBC_PORIVA","LBC_MTOIVA","LBC_MTONET"}

  // Posición de los campos que seran Editados en ITEM ADICIONAL
  oLIBCOMEDIT:aFieldItemP:={}
  AEVAL(oLIBCOMEDIT:aFieldItemF,{|a,n| AADD(oLIBCOMEDIT:aFieldItemP,oLIBCOMEDIT:LBCGETCOLPOS(a))})

  AEVAL(oLIBCOMEDIT:oBrw:aCols,{|oCol,n| AADD(oLIBCOMEDIT:aEditType,oCol:nEditType)})


  oLIBCOMEDIT:Activate({||oLIBCOMEDIT:ViewDatBar()})

  oLIBCOMEDIT:BRWRESTOREPAR()

  oLIBCOMEDIT:SETEDITTYPE(.T.)

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION VIEWDATBAR()
RETURN EJECUTAR("BRLIBCOMEDIT_BAR",oLIBCOMEDIT)

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()


RETURN .T.


/*
// Imprimir
*/
FUNCTION IMPRIMIR()
  LOCAL oRep,cWhere

  oRep:=REPORTE("BRLIBCOMEDIT",cWhere)
  oRep:cSql  :=oLIBCOMEDIT:cSql
  oRep:cTitle:=oLIBCOMEDIT:cTitle

RETURN .T.

FUNCTION LEEFECHAS()
  LOCAL nPeriodo:=oLIBCOMEDIT:oPeriodo:nAt,cWhere

  oLIBCOMEDIT:nPeriodo:=nPeriodo


  IF oLIBCOMEDIT:oPeriodo:nAt=LEN(oLIBCOMEDIT:oPeriodo:aItems)

     oLIBCOMEDIT:oDesde:ForWhen(.T.)
     oLIBCOMEDIT:oHasta:ForWhen(.T.)
     oLIBCOMEDIT:oBtn  :ForWhen(.T.)

     DPFOCUS(oLIBCOMEDIT:oDesde)

  ELSE

     oLIBCOMEDIT:aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)

     oLIBCOMEDIT:oDesde:VarPut(oLIBCOMEDIT:aFechas[1] , .T. )
     oLIBCOMEDIT:oHasta:VarPut(oLIBCOMEDIT:aFechas[2] , .T. )

     oLIBCOMEDIT:dDesde:=oLIBCOMEDIT:aFechas[1]
     oLIBCOMEDIT:dHasta:=oLIBCOMEDIT:aFechas[2]

     cWhere:=oLIBCOMEDIT:HACERWHERE(oLIBCOMEDIT:dDesde,oLIBCOMEDIT:dHasta,oLIBCOMEDIT:cWhere,.T.)

     oLIBCOMEDIT:LEERDATA(cWhere,oLIBCOMEDIT:oBrw,oLIBCOMEDIT:cServer,oLIBCOMEDIT)

  ENDIF

  oLIBCOMEDIT:SAVEPERIODO()

RETURN .T.


FUNCTION HACERWHERE(dDesde,dHasta,cWhere_,lRun)
   LOCAL cWhere:=""

   DEFAULT lRun:=.F.

   // Campo fecha no puede estar en la nueva clausula
   IF ""$cWhere
     RETURN ""
   ENDIF

   IF !Empty(dDesde)
       
   ELSE
     IF !Empty(dHasta)
       
     ENDIF
   ENDIF


   IF !Empty(cWhere_)
      cWhere:=cWhere + IIF( Empty(cWhere),""," AND ") +cWhere_
   ENDIF

   IF lRun

     IF !Empty(oLIBCOMEDIT:cWhereQry)
       cWhere:=cWhere + oLIBCOMEDIT:cWhereQry
     ENDIF

     oLIBCOMEDIT:LEERDATA(cWhere,oLIBCOMEDIT:oBrw,oLIBCOMEDIT:cServer,oLIBCOMEDIT)

   ENDIF


RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer,oLIBEDIT,lCondom,lCtaEgr,lVenta)
   LOCAL aData:={},aTotal:={},oCol,cSql,aLines:={},oTable
   LOCAL oDb,nLenLin
   LOCAL nAt,nRowSel,cJoinCta,cJoinCli,cCtaNombre,cSqlPla,aDataPla:={},aLine:={},nAt,aNew:={}
   LOCAL cJoinTip:=" INNER JOIN DPTIPDOCPRO ON LBC_TIPDOC=TDC_TIPO" 

   DEFAULT cWhere:=""

   IF !Empty(cServer)

     IF !EJECUTAR("DPSERVERDBOPEN",cServer)
        RETURN .F.
     ENDIF

     oDb:=oDp:oDb

   ENDIF

   IF ValType(oLIBEDIT)="O"
      lCondom:=oLIBEDIT:lCondom
      lCtaEgr:=oLIBEDIT:lCtaEgr
      lVenta :=oLIBEDIT:lVenta
   ENDIF

   cWhere:=IIF(Empty(cWhere),"",ALLTRIM(cWhere))

   IF !Empty(cWhere) .AND. LEFT(cWhere,5)="WHERE"
      cWhere:=SUBS(cWhere,6,LEN(cWhere))
   ENDIF

   cJoinCta  :="LEFT  JOIN DPCTA        ON LBC_CODMOD=CTA_CODMOD AND LBC_CODCTA=CTA_CODIGO"
   cCtaNombre:="LBC_CODCTA,CTA_DESCRI,"

   IF lCtaEgr
      cJoinCta  :="LEFT  JOIN DPCTAEGRESO   ON LBC_CTAEGR=CEG_CODIGO"
      cCtaNombre:="LBC_CTAEGR,CEG_DESCRI,"
   ENDIF

   cSql:= " SELECT "+;
          " LBC_TIPDOC,"+;
          " DAY(LBC_FECHA) AS LBC_DIA,"+;
          " LBC_FECHA ,"+;
          " LBC_RIF   ,"+;
          " PRO_NOMBRE,"+;
          cCtaNombre+;
          " LBC_DESCRI,"+;
          " LBC_NUMFAC,"+;
          " LBC_NUMFIS,"+;
          " LBC_FACAFE,"+;
          " LBC_MTOBAS,"+;
          " LBC_TIPIVA,"+;
          " LBC_PORIVA,"+;
          " LBC_MTOIVA,"+;
          " LBC_MTONET,"+;
          " LBC_PORRTI,"+;
          " LBC_MTORTI,"+;
          " LBC_NUMRTI,"+;
          " LBC_CONISR,"+;
          " LBC_PORISR,"+;
          " LBC_MTOISR,"+;
          " LBC_VALCAM,"+;
          " LBC_USOCON,"+;
          " LBC_COMORG,"+;
          " IF(DOC_CODIGO IS NULL,0,1) AS LBC_REGDOC, "+;
          " LBC_ACTIVO,"+;
          " LBC_NUMPAR,"+;
          " LBC_ITEM,  "+;
          " LBC_REGPLA,"+;
          " LBC_CXP   ,"+;
          " TDC_CLRGRA "+;
          " FROM DPLIBCOMPRASDET "+;
          " LEFT  JOIN DPDOCPRO     ON LBC_CODSUC=DOC_CODSUC AND LBC_TIPDOC=DOC_TIPDOC AND LBC_CODIGO=DOC_CODIGO AND LBC_NUMFAC=DOC_NUMERO AND DOC_TIPTRA"+GetWhere("=","D")+;
          " INNER JOIN DPPROVEEDOR  ON LBC_RIF=PRO_RIF"+;
          " "+cJoinCta+;
          " "+cJoinTip+;
          " ORDER BY CONCAT(LBC_NUMPAR,LBC_ITEM) "+;
          ""

   IF lVenta
     cSql:=STRTRAN(cSql,"LBC_CXP","LBC_CXC")
     cSql:=STRTRAN(cSql,"DPLIBCOMPRASDET","DPLIBVENTASDET")
     cSql:=STRTRAN(cSql,"DPDOCPRO"       ,"DPDOCCLI")
     cSql:=STRTRAN(cSql,"DPPROVEEDOR"    ,"DPCLIENTES")
     cSql:=STRTRAN(cSql,"PRO_RIF"        ,"CLI_RIF")
     cSql:=STRTRAN(cSql,"PRO_NOMBRE"     ,"CLI_NOMBRE")
     cSql:=STRTRAN(cSql,"DPTIPDOCPRO"    ,"DPTIPDOCCLI")

   ENDIF

   IF !Empty(cWhere)
      cSql:=EJECUTAR("SQLINSERTWHERE",cSql,cWhere)
   ENDIF

   cSql:=EJECUTAR("WHERE_VAR",cSql)

   oDp:lExcluye:=.T.

   DPWRITE("TEMP\BRLIBCOMEDIT.SQL",cSql)

   oTable     :=OpenTable(cSql,.T.)
   aData      :=ACLONE(oTable:aDataFill)
   oDp:aFields:=ACLONE(oTable:aFields)

   oDp:cWhere:=cWhere

   IF EMPTY(aData)
      aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
   ENDIF

   // 28/01/2024 
   // ? lCtaEgr,lCondom,"lCtaEgr,lCondom"

   IF lCtaEgr .AND. lCondom

     // Debemos excluir las planificaciones (proveedor y referencia) 
     aLine  :=ACLONE(aData[1])
     cWhere :="" // Excluimos los que ya fueron Actualizados
     AEVAL(aData,{|a,n| IF(!Empty(a[29]),AADD(aNew,a),NIL)})

     AEVAL(aNew,{|a,n| aNew[n]:="(PRO_CODIGO"+GetWhere("=",a[3])+" AND PGC_NUMERO"+GetWhere("=",a[29])+")"})
     AEVAL(aNew,{|a,n| cWhere :=cWhere + IF(!Empty(cWhere)," OR ","")+a })

     cSqlPla:=[ SELECT PRO_CODIGO,PRO_NOMBRE,PRO_TIPO  ,PGC_REFERE,PGC_CTAEGR,CEG_DESCRI,  PGC_IVA,]+CRLF+;
              [        PGC_DESCRI,PGC_TIPDOC,PGC_MTODIV,PGC_TIPDES,PGC_NUMERO,TDC_CXP,TDC_CLRGRA ]+CRLF+; 
              [ FROM  DPPROVEEDOR ]+CRLF+;
              [ INNER JOIN DPPROVEEDORPROG   ON PGC_CODIGO=PRO_CODIGO ]+;
              [ LEFT  JOIN DPTIPDOCPRO       ON PGC_TIPDOC=TDC_TIPO   ]+;  
              [ LEFT  JOIN DPCTAEGRESO       ON PGC_CTAEGR=CEG_CODIGO ]+;
              [ WHERE LEFT(PRO_SITUAC,1)='A' AND ]+;
              [          (PRO_TIPO='Prestador de Servicios' OR PRO_TIPO='Servicios Públicos') ]+;
              IF(!Empty(cWhere)," AND NOT "+cWhere,"")+;
              [ GROUP BY PRO_CODIGO,PRO_NOMBRE,PRO_TIPO ]+;
              [ ORDER BY PGC_ITEM DESC ]

      oTable:=OpenTable(cSqlPla,.T.)

// oTable:Browse()

      WHILE !oTable:Eof()

          aLine[01]:=oTable:PGC_TIPDOC
          aLine[03]:=IF(Empty(aLine[03]),oDp:dFecha,FCHINIMES(aLine[03]))
          aLine[02]:=DAY(aLine[03])
          aLine[04]:=oTable:PRO_CODIGO
          aLine[05]:=oTable:PRO_NOMBRE
          aLine[06]:=oTable:PGC_CTAEGR
          aLine[07]:=oTable:CEG_DESCRI
          aLine[08]:=oTable:PGC_DESCRI
          aLine[09]:=CTOEMPTY(aLine[08])
          aLine[10]:=CTOEMPTY(aLine[09])
          aLine[11]:=CTOEMPTY(aLine[10])
          aLine[12]:=ROUND(oTable:PGC_MTODIV*oDp:nValCam,2)
          aLine[13]:=oTable:PGC_IVA
          aLine[14]:=0
          aLine[15]:=0
          aLine[16]:=0
          aLine[17]:=0
          aLine[18]:=0
          aLine[19]:=CTOEMPTY(aLine[19])
          aLine[20]:=CTOEMPTY(aLine[20])
          aLine[21]:=CTOEMPTY(aLine[21])
          aLine[22]:=CTOEMPTY(aLine[22])
          aLine[23]:=oDp:nValCam

          aLine[25]:="Nacional"
          aLine[26]:=0
          aLine[27]:=.F.
          aLine[28]:=STRZERO(LEN(aData)+1,5)
          aLine[29]:=STRZERO(1,5)
          aLine[30]:=oTable:PGC_NUMERO
          aLine[31]:=0
          aLine[31]:=IF(oTable:TDC_CXP="D",+1,aLine[31])
          aLine[31]:=IF(oTable:TDC_CXP="C",-1,aLine[31])
          aLine[32]:=oTable:TDC_CLRGRA

          AADD(aData,ACLONE(aLine))
          oTable:DbSkip()

      ENDDO

  
      oTable:End(.T.)

   ENDIF

   AEVAL(aData,{|a,n| aData[n,24+2]:=(a[24+2]=1)})
// nLenLin:=LEN(aData[1])
// IF Empty(aData[1,nLenLin])
//    aData[1,nLenLin]:=STRZERO(1,5)
// ENDIF


   IF ValType(oBrw)="O"

      oLIBCOMEDIT:cSql   :=cSql
      oLIBCOMEDIT:cWhere_:=cWhere

      aTotal:=ATOTALES(aData)

      oBrw:aArrayData:=ACLONE(aData)
      // oBrw:nArrayAt  :=1
      // oBrw:nRowSel   :=1

      // JN 15/03/2020 Sustituido por BRWCALTOTALES
      EJECUTAR("BRWCALTOTALES",oBrw,.F.)

      nAt    :=oBrw:nArrayAt
      nRowSel:=oBrw:nRowSel

      oBrw:Refresh(.F.)
      oBrw:nArrayAt  :=MIN(nAt,LEN(aData))
      oBrw:nRowSel   :=MIN(nRowSel,oBrw:nRowSel)
      AEVAL(oLIBCOMEDIT:oBar:aControls,{|o,n| o:ForWhen(.T.)})

      oLIBCOMEDIT:SAVEPERIODO()

   ENDIF

RETURN aData


FUNCTION SAVEPERIODO()
  LOCAL cFileMem:="USER\BRLIBCOMEDIT.MEM",V_nPeriodo:=oLIBCOMEDIT:nPeriodo
  LOCAL V_dDesde:=oLIBCOMEDIT:dDesde
  LOCAL V_dHasta:=oLIBCOMEDIT:dHasta

  SAVE TO (cFileMem) ALL LIKE "V_*"

RETURN .T.

/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oLIBCOMEDIT)
RETURN .T.

/*
// Ejecución Cambio de Linea
*/
FUNCTION BRWCHANGE()
  LOCAL cItem:=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_ITEM]

  oLIBCOMEDIT:lSave:=.F.
  oLIBCOMEDIT:LIBREFRESHFIELD() // Refresca los Campos

  IF Empty(oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_TIPDOC])
    oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_TIPDOC]:=IF(oLIBCOMEDIT:lVenta,"FAV","FAC")
    oLIBCOMEDIT:PUTCTATIPDOC()
  ENDIF

  IF Empty(oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_TIPIVA])
    oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_TIPIVA]:="GN"
  ENDIF

  IF Empty(oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_COMORG])
    oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_COMORG]:="Nacional"
  ENDIF

  AEVAL(oLIBCOMEDIT:oBrw:aCols,{|oCol,n|oCol:lButton:=.F.})

  IF oLIBCOMEDIT:cItemChange<>cItem
    oLIBCOMEDIT:SETEDITTYPE(cItem=STRZERO(1,5))
  ENDIF

  oLIBCOMEDIT:cItemChange:=cItem

RETURN NIL

/*
// Refrescar Browse
*/
FUNCTION BRWREFRESCAR()
    LOCAL cWhere


    IF Type("oLIBCOMEDIT")="O" .AND. oLIBCOMEDIT:oWnd:hWnd>0

      cWhere:=" "+IIF(!Empty(oLIBCOMEDIT:cWhere_),oLIBCOMEDIT:cWhere_,oLIBCOMEDIT:cWhere)
      cWhere:=STRTRAN(cWhere," WHERE ","")

      oLIBCOMEDIT:LEERDATA(oLIBCOMEDIT:cWhere_,oLIBCOMEDIT:oBrw,oLIBCOMEDIT:cServer)
      oLIBCOMEDIT:oWnd:Show()
      oLIBCOMEDIT:oWnd:Restore()

    ENDIF

RETURN NIL

FUNCTION BTNRUN()
    ? "PERSONALIZA FUNCTION DE BTNRUN"
RETURN .T.

FUNCTION BTNMENU(nOption,cOption)

   ? nOption,cOption,"PESONALIZA LAS SUB-OPCIONES"

   IF nOption=1
   ENDIF

   IF nOption=2
   ENDIF

   IF nOption=3
   ENDIF

RETURN .T.

FUNCTION HTMLHEAD()

   oLIBCOMEDIT:aHead:=EJECUTAR("HTMLHEAD",oLIBCOMEDIT)

// Ejemplo para Agregar mas Parámetros
//   AADD(oDOCPROISLR:aHead,{"Consulta",oDOCPROISLR:oWnd:cTitle})

RETURN

// Restaurar Parametros
FUNCTION BRWRESTOREPAR()
  EJECUTAR("BRWRESTOREPAR",oLIBCOMEDIT)
RETURN .T.

FUNCTION EDITCTA(nCol,lSave)
   LOCAL oBrw  :=oLIBCOMEDIT:oBrw,oLbx
   LOCAL nAt   :=oBrw:nArrayAt
   LOCAL uValue:=oBrw:aArrayData[oBrw:nArrayAt,nCol]

   IF !oLIBCOMEDIT:lCtaEgr

     IF oDp:lCondominio
       oLbx:=DPLBX("CNDDPCTA.LBX","Cuentas con Planificación, Periodo "+DTOC(oDp:dFchInicio)+"-"+DTOC(oDp:dFchCierre))
       oLbx:=DPLBX("CNDDPCTA.LBX","Cuentas con Planificación, Periodo "+DTOC(oDp:dFchInicio)+"-"+DTOC(oDp:dFchCierre))
     ELSE
       oLbx:=DpLbx("DPCTAUTILIZACION.LBX",NIL,"CTA_CODMOD"+GetWhere("=",oDp:cCtaMod))
     ENDIF

     oLbx:GetValue("CTA_CODIGO",oBrw:aCols[nCol],,,uValue)

   ELSE

     oLbx:=DpLbx("DPCTAEGRESO.LBX")
     oLbx:GetValue("CEG_CODIGO",oBrw:aCols[nCol],,,uValue)

   ENDIF

   oLIBCOMEDIT:lAcction  :=.T.
   oBrw:nArrayAt:=nAt

   SysRefresh(.t.)

RETURN uValue

FUNCTION VALCTA(oCol,uValue,nCol,nKey)
 LOCAL cTipDoc,oTable,cWhere:="",cCtaOld:="",cDescri,aLine:={},cWhere
 LOCAL cDescri:=aLine[oLIBCOMEDIT:COL_CTA_DESCRI],cCodCta

 DEFAULT nKey:=0

 DEFAULT oCol:lButton:=.F.

 IF oCol:lButton=.T.
// oCol:oBrw:nColSel:=nCol+2
   oCol:lButton:=.F.
   RETURN .T.
 ENDIF

 IF !oLIBCOMEDIT:lCtaEgr

   cCodCta:=EJECUTAR("FINDCODENAME","DPCTA","CTA_CODIGO","CTA_DESCRI",oCol,NIL,uValue)
   uValue :=IF(Empty(cCodCta),uValue,cCodCta)

   IF !SQLGET("DPCTA","CTA_CODIGO,CTA_DESCRI","CTA_CODIGO"+GetWhere("=",uValue))==uValue
     MensajeErr("Cuenta Contable no Existe")
     EVAL(oCol:bEditBlock)  
     RETURN .F.
   ENDIF

   cDescri:=oDp:aRow[2]

   IF !EJECUTAR("ISCTADET",uValue,.T.)
      EVAL(oCol:bEditBlock)  
      RETURN .F.
   ENDIF

 ELSE

   cCodCta:=EJECUTAR("FINDCODENAME","DPCTAEGRESO","CEG_CODIGO","CEG_DESCRI",oCol,NIL,uValue)
   uValue :=IF(Empty(cCodCta),uValue,cCodCta)

 ENDIF

 oLIBCOMEDIT:lAcction:=.F.

 IF !oLIBCOMEDIT:lCtaEgr
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CODCTA]:=uValue
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_CTA_DESCRI]:=cDescri
    oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_CODCTA)

 ELSE
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CTAEGR]:=uValue
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_CEG_DESCRI]:=cDescri
    oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_CTAEGR)

 ENDIF

 oCol:oBrw:nColSel:=oLIBCOMEDIT:COL_LBC_DESCRI
// nCol+2 OJO
 oCol:oBrw:DrawLine(.T.)

RETURN .T.

FUNCTION EDITRIF(nCol,lSave)
   LOCAL oBrw  :=oLIBCOMEDIT:oBrw,oLbx
   LOCAL nAt   :=oBrw:nArrayAt
   LOCAL aLine :=oBrw:aArrayData[oBrw:nArrayAt]
   LOCAL uValue:=oBrw:aArrayData[oBrw:nArrayAt,nCol]
   LOCAL cWhere:=""

   IF !Empty(aLine[nCol])

      IF !oLIBCOMEDIT:lVenta

        cWhere:="PRO_RIF"+GetWhere(" LIKE ","%"+ALLTRIM(aLine[nCol])+"%")
         
        // no hay RIF con estos datos y proceso a Incluirlo
        IF COUNT("DPPROVEEDOR",cWhere)=0
          oBrw:nColSel:=oLIBCOMEDIT:LBCGETCOLPOS("PRO_NOMBRE")
          RETURN .T.
        ENDIF

      ELSE

        cWhere:="CLI_RIF"+GetWhere(" LIKE ","%"+ALLTRIM(aLine[nCol])+"%")
         
        // no hay RIF con estos datos y proceso a Incluirlo
        IF COUNT("DPCLIENTES",cWhere)=0
          oBrw:nColSel:=oLIBCOMEDIT:LBCGETCOLPOS("CLI_NOMBRE")
          RETURN .T.
        ENDIF

      ENDIF

   ENDIF

   IF !oLIBCOMEDIT:lVenta .AND. COUNT("DPPROVEEDOR")=0
      oLIBCOMEDIT:VALRIFSENIAT()
      RETURN .F.
   ENDIF

   IF !oLIBCOMEDIT:lVenta
     oLbx:=DpLbx("DPPROVEEDOR_RIF.LBX",NIL,oLIBCOMEDIT:cWherePro+IF(Empty(cWhere),""," AND "+cWhere))
     oLbx:GetValue("PRO_RIF",oBrw:aCols[nCol],,,uValue)
   ELSE
     oLbx:=DpLbx("DPCLIENTES_RIF.LBX",NIL,oLIBCOMEDIT:cWherePro+IF(Empty(cWhere),""," AND "+cWhere))
     oLbx:GetValue("CLI_RIF",oBrw:aCols[nCol],,,uValue)
   ENDIF

   oLIBCOMEDIT:lAcction  :=.T.
   oBrw:nArrayAt:=nAt

   SysRefresh(.t.)

RETURN uValue

/*
// Validar RIF DEL SENIAT
*/
FUNCTION VALRIFSENIAT2()
  LOCAL uValue :=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_RIF")
  LOCAL oCol   :=oLIBCOMEDIT:LBCGETCOLBRW("LBC_RIF")
  LOCAL nCol   :=oLIBCOMEDIT:LBCGETCOLPOS("LBC_RIF")
  LOCAL lOk ,nKey:=NIL
  LOCAL oDb    :=OpenOdbc(oDp:cDsnData),cSql

  oDp:aRif:={}
  lOk:=EJECUTAR("VALRIFSENIAT",uValue,!ISDIGIT(uValue),ISDIGIT(uValue)) 

  IF lOk

    IF LEN(oDp:aRif)>1 .AND. !("NO ENCON"$oDp:aRif[1] .OR. "NO EXIS"$UPPER(oDp:aRif[1]))

      cSql:=" SET FOREIGN_KEY_CHECKS = 0"
      oDb:Execute(cSql)

      IF oLIBCOMEDIT:lVenta
        oLIBCOMEDIT:CREATECLIENTE(uValue,oDp:aRif[1],VAL(oDp:aRif[2]))
      ELSE
        oLIBCOMEDIT:CREATEPROVEEDOR(uValue,oDp:aRif[1],VAL(oDp:aRif[2]))
      ENDIF

      cSql:=" SET FOREIGN_KEY_CHECKS = 1"
      oDb:Execute(cSql)

    ENDIF

    oLIBCOMEDIT:VALRIF(oCol,uValue,nCol,nKey)

  ENDIF

RETURN .T.

FUNCTION VALRIF(oCol,uValue,nCol,nKey)
  LOCAL oTable,cCtaOld:="",cDescri,cWhere,lOk:=.F.
  LOCAL oRif,cCtaEgr,cCodCta:="",cNomCta:="",nPorIva,cTipIva,nPorRti,cCodigo,cRif,cCodCli,cNombre:=""
  LOCAL aLine     :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]
  LOCAL cRifAnt   :=aLine[nCol]
  LOCAL cWhere    :=oLIBCOMEDIT:LIBWHERE()
  LOCAL nColPorRti:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_PORRTI")
  LOCAL nColTipIva:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_TIPIVA")
  LOCAL nColDescri:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_DESCRI")
  LOCAL nColCtaEgr:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_CTAEGR")
  LOCAL nColCodCta:=0
  LOCAL cTipDoc   :=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_TIPDOC")
 
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

   cCodCta:=SQLGET(oLIBCOMEDIT:cTable,"LBC_CTACOD,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                                      "LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CTACOD"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")

   IF Empty(cCodCta)
      cCodCta:=SQLGET(oLIBCOMEDIT:cTable,"LBC_CTACOD,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CTACOD"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")
   ENDIF

   nColCodCta:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_CODCTA")
   cCodCta   :=SQLGET(oLIBCOMEDIT:cTable,"LBC_CODCTA,LBC_TIPIVA,LBC_PORRTI,LBC_DESCRI","LBC_RIF"+GetWhere("=",uValue)+" AND LBC_CODCTA"+GetWhere("<>","")+" ORDER BY LBC_FECHA DESC LIMIT 1 ")
   cTipIva   :=DPSQLROW(2)
   nPorRti   :=DPSQLROW(3)
   cDescri   :=PADR(DPSQLROW(4),140)

   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_COMORG)

   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColCodCta]:=cCodCta
   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColTipIva]:=cTipIva
   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColPorRti]:=nPorRti
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
   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColPorRti]:=nPorRti
   oLIBCOMEDIT:oBrw:aArrayData[oCol:oBrw:nArrayAt,nColDescri]:=cDescri

   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_CTAEGR)

   cNomCta:=SQLGET("DPCTAEGRESO","CEG_DESCRI","CEG_CODIGO"+GetWhere("=",cCtaEgr))

   IF !Empty(cCodCta)
     SQLUPDATE(oLIBCOMEDIT:cTable,"LBC_CTAEGR",cCtaEgr,cWhere)
   ENDIF

  ENDIF

	
  IF !oLIBCOMEDIT:lVenta
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

  oCol:oBrw:DrawLine(.T.)

RETURN .T.

/*
// Crear la cuenta de Egreso, validar antes de grabar el registro
*/
FUNCTION CREATECTAEGRESO(cCodigo,cDescri)
   LOCAL aLine     :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]

   DEFAULT cCodigo:=aLine[oLIBCOMEDIT:COL_LBC_CTAEGR],;
           cDescri:=aLine[oLIBCOMEDIT:COL_EGR_DESCRI]

   EJECUTAR("CREATERECORD","DPCTAEGRESO",{"CEG_CODIGO","CEG_DESCRI" ,"CEG_CUENTA"   ,"CEG_ACTIVO","CEG_EGRES","CEG_CODCLA"},;
                                         {cCodigo     ,cDescri      ,oDp:cCtaIndef  ,.T.         ,.T.        ,oDp:cCtaIndef},;
                                           NIL,.T.,"CEG_CODIGO"+GetWhere("=",cCodigo))
RETURN .T.
/*
// Crear el codigo del Proveedor
*/
FUNCTION CREATEPROVEEDOR(cRif,cNombre,nRetIva)

   DEFAULT nRetIva:=0

   EJECUTAR("CREATERECORD","DPPROVEEDOR",{"PRO_CODIGO","PRO_RIF" ,"PRO_NOMBRE","PRO_RETIVA","PRO_ESTADO","PRO_TIPO" },;
                                         {cRif        ,cRif      ,cNombre     ,nRetIva     ,"Activo"    ,oLIBCOMEDIT:cTipo},;
            NIL,.T.,"PRO_RIF"+GetWhere("=",cRif))

RETURN .T.

/*
// Crear el codigo del Proveedor
*/
FUNCTION CREATECLIENTE(cRif,cNombre,nRetIva)

   DEFAULT nRetIva:=0

   EJECUTAR("CREATERECORD","DPCLIENTES",{"CLI_CODIGO","CLI_RIF" ,"CLI_NOMBRE","CLI_RETIVA","PRO_ACTIVO" },;
                                        {cRif        ,cRif      ,cNombre     ,nRetIva     ,"Activo"     },;
            NIL,.T.,"CLI_RIF"+GetWhere("=",cRif))

RETURN .T.


/*
// Validar Número de Factura
*/
FUNCTION VALNUMFAC(oCol,uValue,nCol,nKey)
  LOCAL cWhere :=oLIBCOMEDIT:LIBWHERE()
  LOCAL aLine  :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]
  LOCAL nLen   :=LEN(aLine)
  LOCAL cWhere :="LBC_CODSUC"+GetWhere("=",oLIBCOMEDIT:cCodSuc)+" AND LBC_FCHDEC"+GetWhere("=",oLIBCOMEDIT:dFchDec)+" AND LBC_ITEM"+GetWhere("<>",aLine[nLen])
  LOCAL dFchFin:=SQLGET(oLIBCOMEDIT:cTable,"LBC_FCHDEC,LBC_ITEM",cWhere+" AND LBC_NUMFAC"+GetWhere("=",uValue)+" AND LBC_RIF"+GetWhere("=",oLIBCOMEDIT:LBC_RIF))
  LOCAL cItem  :=DPSQLROW(2),nAt

  // oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,nCol,nKey)
  nAt:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_NUMFIS")

  IF nAt>0
    oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nAt]:=uValue
    oCol:oBrw:nColSel:=nAt
  ENDIF

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol]:=uValue

  oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,nCol,nKey)

RETURN .T.

FUNCTION PUTDESCRI(oCol,uValue,nCol)

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue
  oCol:oBrw:DrawLine(.T.)
  oLIBCOMEDIT:LIBSAVEFIELD(nCol)

  oCol:oBrw:nColSel:=nCol+1

RETURN .T.

FUNCTION PUTFECHA(oCol,uValue,nCol)

  oLIBCOMEDIT:LBC_VALCAM:=EJECUTAR("DPGETVALCAM",oDp:cMonedaExt,uValue)

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_VALCAM ]:=oLIBCOMEDIT:LBC_VALCAM

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue
  oCol:oBrw:DrawLine(.T.)
  oLIBCOMEDIT:LIBSAVEFIELD(nCol)

  oCol:oBrw:nColSel:=nCol+1


RETURN .T.

/*
// Seleccionar tipo de Documento
*/
FUNCTION PUTTIPDOC(oCol,uValue,nCol)
  
  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue
  oCol:oBrw:DrawLine(.T.)
  oLIBCOMEDIT:LIBSAVEFIELD(nCol)

  IF uValue="FAC" .OR. uValue="FAV" .OR. uValue="FAM"
    oCol:oBrw:aCols[oLIBCOMEDIT:COL_LBC_FACAFE]:nEditType:=0
  ELSE
    oCol:oBrw:aCols[oLIBCOMEDIT:COL_LBC_FACAFE]:nEditType:=1
  ENDIF

  IF oLIBCOMEDIT:lVenta

     oLIBCOMEDIT:nCxP:=EJECUTAR("DPTIPCXC",uValue)
     oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CXC]:=oLIBCOMEDIT:nCxP
     oLIBCOMEDIT:PUTCTATIPDOC()
     oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_CXC)

  ELSE

     oLIBCOMEDIT:nCxP:=EJECUTAR("DPTIPCXP",uValue)
     oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CXP]:=oLIBCOMEDIT:nCxP
     oLIBCOMEDIT:PUTCTATIPDOC()

  ENDIF

  oCol:oBrw:nColSel:=nCol+1

RETURN .T.

/*
// Busca la Columna 
*/
FUNCTION LBCGETCOLVALUE(cField)
   LOCAL nAt   :=ASCAN(oLIBCOMEDIT:aFields,{|a,n|a[1]==cField})
   LOCAL aLine :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]
   LOCAL uValue:=IF(nAt>0,aLine[nAt],NIL)

RETURN uValue

/*
// Busca Posición de la Columna 
*/
FUNCTION LBCGETCOLPOS(cField)
   LOCAL nAt   :=ASCAN(oLIBCOMEDIT:aFields,{|a,n|a[1]==cField})
RETURN nAt

/*
// Busca Posición de la Columna 
*/
FUNCTION LBCGETCOLBRW(cField)
   LOCAL nAt   :=ASCAN(oLIBCOMEDIT:aFields,{|a,n|a[1]==cField})
RETURN IF(nAt>0,oLIBCOMEDIT:oBrw:aCols[nAt],NIL)


/*
// GUARDAR VALOR EN EL CAMPO
*/
FUNCTION PUTFIELDVALUE(oCol,uValue,nCol,nKey,nLen,lNext,lTotal)
   LOCAL cField,aLine,aTotal:={},nTotal:=0
   LOCAL cWhere:=oLIBCOMEDIT:LIBWHERE()

   DEFAULT nCol  :=oCol:nPos,;
           lNext :=.F.,;
           lTotal:=!Empty(oCol:cFooter)

   cField:=oLIBCOMEDIT:aFields[nCol,1]
   oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue
   aLine :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]

   IF nLen<>NIL .AND. ValType(uValue)="C"   
      uValue:=LEFT(uValue,nLen)
   ENDIF

   // si no existe , debe crearlo
   IF !ISSQLFIND(oLIBCOMEDIT:cTable,cWhere)
      oLIBCOMEDIT:LIBCOMGRABAR()
   ENDIF

   SQLUPDATE(oLIBCOMEDIT:cTable,cField,uValue,cWhere)

   // cada columna representa un campo y asigna el valor dinámico en el formulario
   oLIBCOMEDIT:LIBREFRESHFIELD()

   IF lTotal
      AEVAL(oCol:oBrw:aArrayData,{|a,n| nTotal:=nTotal+a[nCol]})
      oCol:cFooter      :=FDP(nTotal,oCol:cEditPicture)
      oCol:RefreshFooter()
   ENDIF

   IF lNext
      oLIBCOMEDIT:oBrw:nColSel:=nCol+1
   ENDIF

RETURN .T.

FUNCTION LIBREFRESHFIELD(nAt)
  LOCAL aLine

  DEFAULT nAt:=oLIBCOMEDIT:oBrw:nArrayAt

  aLine :=oLIBCOMEDIT:oBrw:aArrayData[nAt]

  AEVAL(oLIBCOMEDIT:aFields,{|a,n| oLIBCOMEDIT:SET(a[1],aLine[n])})

RETURN .T.

FUNCTION LIBSAVEFIELD(nCol)
  LOCAL cWhere:=oLIBCOMEDIT:LIBWHERE()
  LOCAL cField:=oLIBCOMEDIT:aFields[nCol,1]
  LOCAL uValue:=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,nCol]
  LOCAL cCodigo

  // Debe guardar el registro en todo momento, por ahora
  IF !oLIBCOMEDIT:lSave .AND. COUNT(oLIBCOMEDIT:cTable,cWhere)=0
    oLIBCOMEDIT:LIBCOMGRABAR()
  ENDIF

  IF "LBC_RIF"=cField 

     IF !oLIBCOMEDIT:lVenta
       cCodigo:=SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_RIF"+GetWhere("=",cCodigo))
     ELSE
       cCodigo:=SQLGET("DPCLIENTES","CLI_CODIGO","CLI_RIF"+GetWhere("=",cCodigo))
     ENDIF

     SQLUPDATE(oLIBCOMEDIT:cTable,"LBC_CODIGO",cCodigo,cWhere)

  ENDIF

  SQLUPDATE(oLIBCOMEDIT:cTable,cField,uValue,cWhere)

  // Caso de Gastos de condominio, asociado con un cliente
  IF !Empty(oLIBCOMEDIT:cCodCli)
    SQLUPDATE(oLIBCOMEDIT:cTable,{"LBC_CODCLI","LBC_ID"},{oLIBCOMEDIT:cCodCli,oLIBCOMEDIT:cId},cWhere)
    //oLIBCOMEDIT:cCodCli:=cCodCli
    //oLIBCOMEDIT:cId    :=cId // DPCLIENTESCLI=ITEM
  ENDIF

  IF !Empty(oLIBCOMEDIT:cCenCos)
    SQLUPDATE(oLIBCOMEDIT:cTable,"LBC_CENCOS",oLIBCOMEDIT:cCenCos,cWhere)
  ENDIF

  oLIBCOMEDIT:LIBREFRESHFIELD() // Refresca los Campos

RETURN .T.

FUNCTION LIBWHERE()
   LOCAL aLine   :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]
   LOCAL nColItem:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_ITEM")
   LOCAL nColNumP:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_NUMPAR")
   LOCAL cWhere  :="LBC_CODSUC"+GetWhere("=",oLIBCOMEDIT:cCodSuc)+" AND "+;
                   "LBC_FCHDEC"+GetWhere("=",oLIBCOMEDIT:dFchDec)+" AND "+;
                   "LBC_NUMPAR"+GetWhere("=",aLine[nColNumP]    )+" AND "+;
                   "LBC_ITEM"  +GetWhere("=",aLine[nColItem]    )
  
RETURN cWhere


FUNCTION LIBCOMGRABAR(lAll)
   LOCAL aLine  :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]
   LOCAL cWhere :=oLIBCOMEDIT:LIBWHERE(),I,aFields:={},aValues:={}
   LOCAL nAt    :=oLIBCOMEDIT:oBrw:nArrayAt
   LOCAL nCxP   :=oLIBCOMEDIT:nCxP
   LOCAL cCodigo:=""
   LOCAL cRif   :=aLine[oLIBCOMEDIT:COL_LBC_RIF] 

   IF !Empty(cRif)

     IF !oLIBCOMEDIT:lVenta
       cCodigo:=SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_RIF"+GetWhere("=",cRif))
     ELSE
       cCodigo:=SQLGET("DPCLIENTES","CLI_CODIGO","CLI_RIF"+GetWhere("=",cRif))
     ENDIF

   ENDIF

   DEFAULT lAll:=.F.

   oLIBCOMEDIT:lSave:=.T.

   FOR I=1 TO LEN(oLIBCOMEDIT:aFields)
   
     IF LEFT(oLIBCOMEDIT:aFields[I,1],4)="LBC_" .AND. !LEFT(oLIBCOMEDIT:aFields[I,1],10)="LBC_REGDOC" .AND. !LEFT(oLIBCOMEDIT:aFields[I,1],07)="LBC_DIA"
        AADD(aFields,oLIBCOMEDIT:aFields[I,1])
        AADD(aValues,aLine[I])
     ENDIF

   NEXT I

   AADD(aFields,"LBC_CODMOD")
   AADD(aFields,"LBC_FCHDEC")
   AADD(aFields,"LBC_CODSUC")
   AADD(aFields,IF(oLIBCOMEDIT:lVenta,"LBC_CXC","LBC_CXP"))
   AADD(aFields,"LBC_REGPLA")
   AADD(aFields,"LBC_CODIGO")

   AADD(aValues,oDp:cCtaMod)
   AADD(aValues,oLIBCOMEDIT:dFchDec)
   AADD(aValues,oLIBCOMEDIT:cCodSuc)
   AADD(aValues,nCxP) 
   AADD(aValues,aLine[oLIBCOMEDIT:COL_LBC_REGPLA]) 
   AADD(aValues,aLine[oLIBCOMEDIT:COL_LBC_RIF   ]) // RIF=Código

   IF oLIBCOMEDIT:lCtaEgr .AND. !ISSQLFIND("DPCTAEGRESO","CEG_CODIGO"+GetWhere("=",aLine[oLIBCOMEDIT:COL_LBC_CTAEGR]))
      oLIBCOMEDIT:CREATECTAEGRESO(cCodigo,cDescri)
   ENDIF



   IF COUNT(oLIBCOMEDIT:cTable,cWhere)=0 .OR. lAll

     EJECUTAR("CREATERECORD",oLIBCOMEDIT:cTable,aFields,aValues,NIL,.T.,cWhere)

     IF !lAll
       oLIBCOMEDIT:LIBCOMADDLINE()
       oLIBCOMEDIT:oBrw:nArrayAt:=nAt
     ENDIF

   ENDIF

RETURN .T.

/*
// Agregar Linea
*/
FUNCTION LIBCOMADDLINE(lItem)
  LOCAL nColItem:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_ITEM")
  LOCAL nColNumP:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_NUMPAR")
  LOCAL cMaxNumP:=STRZERO(0,5)
  LOCAL cMaxItem:=""
  LOCAL aLine   :=ACLONE(oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt])
  LOCAL cItem   :=STRZERO(1,5)
  LOCAL nItems  :=0,nAt
  LOCAL cTipDoc :=aLine[1]

  DEFAULT lItem:=.F.

  IF !lItem

    // no suma el item
    AEVAL(oLIBCOMEDIT:oBrw:aArrayData,{|a,n| cMaxNumP:=IF(a[nColNumP]>cMaxNumP,a[nColNumP],cMaxNumP)})
    cMaxNumP:=STRZERO(VAL(cMaxNumP)+1,5)
  
  ELSE

    // Incrementa de Items en la misma partida
    cMaxNumP:=aLine[nColNumP]
    AEVAL(oLIBCOMEDIT:oBrw:aArrayData,{|a,n| nItems:=nItems+IF(a[nColNumP]=cMaxNumP,1,0)})
    cItem:=STRZERO(nItems+1,5)
    
  ENDIF

  AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(a)})

  aLine[1       ]:=cTipDoc
  aLine[nColItem]:=cItem
  aLine[nColNumP]:=cMaxNumP
  aLine[oLIBCOMEDIT:COL_LBC_ACTIVO]:=.T.

  IF !lItem
    AADD(oLIBCOMEDIT:oBrw:aArrayData,ACLONE(aLine))
  ELSE
    nAt:=oLIBCOMEDIT:oBrw:nArrayAt+1
    AINSERTAR(oLIBCOMEDIT:oBrw:aArrayData,nAt,ACLONE(aLine))
    oLIBCOMEDIT:oBrw:nArrayAt:=nAt
    oLIBCOMEDIT:oBrw:nRowSel:=oLIBCOMEDIT:oBrw:nRowSel+1
  ENDIF

  oLIBCOMEDIT:nCxP:=EJECUTAR("DPTIPCXP",aLine[1])

  oLIBCOMEDIT:oBrw:Refresh(.F.)

RETURN .T.

/*
// Ejecuta Guardar y Convertir en Documentos del Proveedor
*/
FUNCTION LIBCOMSAVE()

   EJECUTAR("DPLIBCOMTODPDOCPRO",oLIBCOMEDIT:cCodSuc,oLIBCOMEDIT:dFchDec)

   IF ValType(oLIBCOMEDIT:oFrmRefresh)="O"
      oLIBCOMEDIT:oFrmRefresh:BRWREFRESCAR()
   ENDIF

RETURN .T.

FUNCTION VALRIFNOMBRE(oCol,uValue,nCol)
  LOCAL cRif   :=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_RIF")
  LOCAL cNombre:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_NOMBRE")
  LOCAL aLine  :=ACLONE(oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt])
  LOCAL cCodigo:=uValue

  oLIBCOMEDIT:LIBREFRESHFIELD() // Refresca los Campos
  cCodigo:=uValue // Codigo del Proveedor

  IF !oLIBCOMEDIT:lVenta

    oLIBCOMEDIT:CREATEPROVEEDOR(cRif,uValue,oLIBCOMEDIT:LBC_PORRTI)

  ELSE

    oLIBCOMEDIT:CREATECLIENTE(cRif,uValue,oLIBCOMEDIT:LBC_PORRTI)

  ENDIF

  // Actualiza el Codigo del CLIENTE/RIF
  SQLUPDATE(oLIBCOMEDIT:cTable,{"LBC_RIF","LBC_CODIGO"},{cRif,cRif},oLIBCOMEDIT:LIBWHERE())

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue
  oCol:oBrw:DrawLine(.T.)

  IF Empty(aLine[nCol+1])
    oCol:oBrw:nColSel:=nCol+1
  ELSE
    oCol:oBrw:nColSel:=12 // oLIBCOMEDIT:COL_LBC_MTONET-1 // Directo hacia Monto Base
  ENDIF

RETURN .T.

FUNCTION PUTTIPIVA(oCol,cTipIva,nCol)
   LOCAL nPorIva   :=oLIBCOMEDIT:GETPORIVA(cTipIva)
   LOCAL nMonto    :=oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTOBAS]
   LOCAL nMtoIva   :=PORCEN(nMonto,nPorIva)
   LOCAL oColPorRti:=oLIBCOMEDIT:LBCGETCOLBRW("LBC_PORRTI")
   LOCAL nPorRti   :=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_PORRTI")

   oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_TIPIVA]:=cTipIva
   oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_PORIVA]:=nPorIva
   oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTOIVA]:=nMtoIva
   oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTONET]:=nMonto+nMtoIva

   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_TIPIVA)
   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_PORIVA)
   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_MTOIVA)
   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_MTONET)

   oLIBCOMEDIT:VALPORRTI(oColPorRti,nPorRti,oLIBCOMEDIT:COL_LBC_PORRTI,NIL)

RETURN .T.

/*
// Valida % RETENCION DE IVA
*/
FUNCTION VALPORRTI(oCol,uValue,oLIBCOMEDIT:COL_LBC_PORRTI,nKey)
   LOCAL nMtoIva:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_MTOIVA")
   LOCAL nMtoRti:=PORCEN(nMtoIva,uValue)
   LOCAL cRif   :=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_RIF")

   oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTORTI]:=nMtoRti

   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_MTORTI)
   oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_PORRTI,nKey)

   SQLUPDATE("DPPROVEEDOR","PRO_RETIVA",uValue,"PRO_RIF"+GetWhere("=",cRif))

RETURN .T.

/*
// Valida % RETENCION DE ISLR
*/
FUNCTION VALPORISR(oCol,uValue,oLIBCOMEDIT:COL_LBC_PORISR,nKey)
   LOCAL nMtoBas:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_MTOBAS")
   LOCAL nMtoIsr:=PORCEN(nMtoBas,uValue)

   oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_MTOISR]:=nMtoRti

   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_MTOISR)
   oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_PORISR,nKey)

RETURN .T.


FUNCTION GETPORIVA(cTipIva)
  LOCAL nPorIva:=0
  LOCAL nCol  :=IIF("N"="N",3,5)

  nPorIva:=EJECUTAR("IVACAL",cTipIva,nCol,oLIBCOMEDIT:dFchDec) 

RETURN nPorIva

/*
// Valida base imponible
*/

FUNCTION VALLBCMTOBAS(oCol,uValue,nCol,nKey)
  LOCAL cTipIva:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_TIPIVA"),nAt
  LOCAL cTipDoc:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_TIPDOC")
  LOCAL cNumDoc:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_NUMFAC")
  LOCAL nPorIva:=oLIBCOMEDIT:GETPORIVA(cTipIva)
  LOCAL oColIva:=oLIBCOMEDIT:LBCGETCOLBRW("LBC_TIPIVA")
  LOCAL oColPor:=oLIBCOMEDIT:LBCGETCOLBRW("LBC_PORIVA")
  LOCAL nColIva:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_TIPIVA")

  oLIBCOMEDIT:PUTFIELDVALUE(oCol,uValue,oLIBCOMEDIT:COL_LBC_MTOBAS,nKey)

  IF nPorIva>0
     oLIBCOMEDIT:PUTTIPIVA(oColIva,cTipIva,nColIva)
  ENDIF

  // En el caso de Gastos o documentos no fiscales, debe generar su número
  IF !oLIBCOMEDIT:lVenta .AND. Empty(cNumDoc) .AND. !ISSQLGET("DPTIPDOCPRO","TDC_LIBCOM","TDC_TIPO"+GetWhere("=",cTipDoc))
     // no es libro de compras, numero autoincremental
     cNumDoc:=SQLINCREMENTAL(oLIBCOMEDIT:cTable,"LBC_NUMFAC","LBC_TIPDOC"+GetWhere("=",cTipDoc),NIL,NIL,.T.,8)
     nAt:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_NUMFAC")
     oLIBCOMEDIT:PUTFIELDVALUE(oLIBCOMEDIT:oBrw:aCols[nAt],cNumDoc,nAt,nKey,NIL,.T.)
  ENDIF

  // AHORA DEBE AGREGAR NUEVA LINEA, si no tiene fechas vacias, agrega
  nAt:=ASCAN(oLIBCOMEDIT:oBrw:aArrayData,{|a,n| Empty(a[oLIBCOMEDIT:COL_LBC_FECHA])})
  IF nAt=0
    oLIBCOMEDIT:LIBCOMADDLINE()
  ENDIF

RETURN .T.

/*
// Activar o Inactivar Editar Columnas
*/
FUNCTION SETEDITTYPE(lOn)

  IF lOn
    // Activa la Edición de las columnas
    AEVAL(oLIBCOMEDIT:aEditType,{|nEditType,n| oLIBCOMEDIT:oBrw:aCols[n]:nEditType:=nEditType} )
  ELSE

    // Desactiva 
    AEVAL(oLIBCOMEDIT:aEditType,{|nEditType,n| oLIBCOMEDIT:oBrw:aCols[n]:nEditType:=0} )

    // Activa solo las columnas editables para agregar nuevas cuentas e Items
    // ViewArray(oLIBCOMEDIT:aFieldItemP)
    AEVAL(oLIBCOMEDIT:aFieldItemP,{|nAt,n,nEditType| nEditType:=oLIBCOMEDIT:aEditType[nAt],;
                                                     oLIBCOMEDIT:oBrw:aCols[nAt]:nEditType:=nEditType})

  ENDIF

RETURN .T.
/*
// Insertar Linea
*/
FUNCTION LIBADDITEM()

   oLIBCOMEDIT:LIBCOMADDLINE(.T.)
   oLIBCOMEDIT:SETEDITTYPE(.F.)

   oLIBCOMEDIT:oBrw:nColSel:=oLIBCOMEDIT:aFieldItemP[1]

RETURN .T.

/*
// CREAR DOCUMENTO 
*/
FUNCTION CREARDOC(lDoc)
   LOCAL cWhere,cCodigo

   DEFAULT lDoc:=.T.

   IF Empty(oLIBCOMEDIT:LBC_NUMFAC)
      oLIBCOMEDIT:oBtnForm:MsgErr("Requiere Número de Documento","Ver Documento, no es Posible")
      RETURN .F.
   ENDIF

   cWhere:="LBC_CODSUC"+GetWhere("=" ,oLIBCOMEDIT:cCodSuc   )+" AND "+;
           "LBC_NUMFAC"+GetWhere("=" ,oLIBCOMEDIT:LBC_NUMFAC)+" AND "+;
           "LBC_TIPDOC"+GetWhere("=" ,oLIBCOMEDIT:LBC_TIPDOC)+" AND "+;
           "LBC_RIF   "+GetWhere("=" ,oLIBCOMEDIT:LBC_RIF   )

   EJECUTAR("DPLIBCOMTODPDOCPRO",oLIBCOMEDIT:cCodSuc,oLIBCOMEDIT:dFchDec,cWhere)

   cCodigo:=SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_RIF"+GetWhere("=",oLIBCOMEDIT:LBC_RIF))

   IF lDoc
      EJECUTAR("VERDOCPRO",oLIBCOMEDIT:cCodSuc,oLIBCOMEDIT:LBC_TIPDOC,cCodigo,oLIBCOMEDIT:LBC_NUMFAC,"D")
   ELSE
      EJECUTAR("DPPRODOCMNU",oLIBCOMEDIT:cCodSuc,oLIBCOMEDIT:LBC_TIPDOC,oLIBCOMEDIT:LBC_NUMFAC,cCodigo)
   ENDIF   

RETURN .T.

/*
// Calcula la Base Imponible
*/

FUNCTION CALBASEIMP(oCol,nNeto,nCol,nKey)
   LOCAL nBaseImp:=0,nMtoIva:=0
   LOCAL cIVA    :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_TIPIVA]
   LOCAL oColIva :=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_TIPIVA]
   LOCAL x       :=oLIBCOMEDIT:PUTTIPIVA(oColIva,cIVA,oLIBCOMEDIT:COL_LBC_TIPIVA,nKey)
   LOCAL nIVA    :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_PORIVA]

   nBaseImp:=nNeto/(1+nIVA/100)
   nMtoIva :=PORCEN(nBaseImp,nIVA)

   oColIva :=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOBAS]
   oLIBCOMEDIT:PUTFIELDVALUE(oColIva,nBaseImp,oLIBCOMEDIT:COL_LBC_MTOBAS,nKey)

   oColIva :=oLIBCOMEDIT:oBrw:aCols[oLIBCOMEDIT:COL_LBC_MTOIVA]

   oLIBCOMEDIT:PUTFIELDVALUE(oColIva,nMtoIva,oLIBCOMEDIT:COL_LBC_MTOIVA,nKey,NIL,NIL,.T.)

   oColIva :=oLIBCOMEDIT:oBrw:aCols[nCol]
   oLIBCOMEDIT:PUTFIELDVALUE(oCol,nNeto,nCol,nKey)
  
RETURN nBaseImp

/*
// Inactiva Registro
*/
FUNCTION DELASIENTOS()
   LOCAL lActivo:=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_ACTIVO]

   oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_ACTIVO]:=!lActivo
   oLIBCOMEDIT:oBrw:DrawLine(.T.)
   oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_ACTIVO)

RETURN .T.

/*
// Contabilizar
*/
FUNCTION CONTABILIZAR()
  LOCAL cWhere,cTitle:=NIL
  LOCAL aTipCxP:={"CAJ","BCO","CJE","BCE","LBC"}

  cWhere:="DOC_CODSUC"+GetWhere("=",oLIBCOMEDIT:cCodSuc)+" AND DOC_FCHDEC"+GetWhere("=",oLIBCOMEDIT:dFchDec)

RETURN EJECUTAR("BRDOCPRORESXCNT",cWhere,oLIBCOMEDIT:cCodSuc,oDp:nIndicada,oLIBCOMEDIT:dFchDec,oLIBCOMEDIT:dFchDec,cTitle)

FUNCTION VALCODPRO()

  IF !ISSQLFIND("DPPROVEEDOR","PRO_CODIGO"+GetWhere("=",oLIBCOMEDIT:cCodPro))
    oLIBCOMEDIT:oCodPro:KeyBoard(VK_F6)
  ENDIF

  oLIBCOMEDIT:oNomPro:Refresh(.T.)

RETURN .T.

/*
// Validar Cuenta de Egreso
*/
FUNCTION VALCTAEGR(oCol,uValue,nCol,nKey)
  LOCAL cTipDoc,oTable,cWhere:="",cCtaOld:="",cDescri,aLine:={},cWhere,cCtaEgr:=""
  LOCAL nColPorRti:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_PORRTI")
  LOCAL nColTipIva:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_TIPIVA")
  LOCAL nColDescri:=oLIBCOMEDIT:LBCGETCOLPOS("LBC_DESCRI")

  DEFAULT nKey:=0

  DEFAULT oCol:lButton:=.F.

  IF oCol:lButton=.T.
    oCol:lButton:=.F.
    RETURN .T.
  ENDIF

  IF !ISSQLFIND("DPCTAEGRESO","CEG_CODIGO"+GetWhere("=",uValue))
    cCtaEgr:=EJECUTAR("FINDCODENAME","DPCTAEGRESO","CEG_CODIGO","CEG_DESCRI",oCol,NIL,uValue)
    uValue :=IF(Empty(cCtaEgr),uValue,cCtaEgr)
  ENDIF

  oCol:oBrw:aCols[nCol+1]:nEditType    :=0

  IF !ISSQLFIND("DPCTAEGRESO","CEG_CODIGO"+GetWhere("=",uValue))

    oCol:oBrw:aCols[nCol+1]:nEditType    :=1
    oCol:oBrw:nColSel:=nCol+1
 
  ENDIF

  cDescri:=SQLGET("DPCTAEGRESO","CEG_DESCRI","CEG_CODIGO"+GetWhere("=",uValue))

  oLIBCOMEDIT:lAcction:=.F.

  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol  ]:=uValue
  oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,nCol+1]:=cDescri
  oCol:oBrw:DrawLine(.T.)

  oLIBCOMEDIT:LIBSAVEFIELD(oLIBCOMEDIT:COL_LBC_CTAEGR)

RETURN .T.

/*
// Validar Nombre del Proveedor y lo guarda
*/
FUNCTION VALNOMBREEGR(oCol,uValue,nCol,nKey,NIL,lRefresh)
   LOCAL aLine  :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt]
   LOCAL cCodigo:=aLine[nCol-1]

   IF Empty(uValue)
      RETURN .F.
   ENDIF

   oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,nCol]:=uValue
   oLIBCOMEDIT:oBrw:DrawLine(.T.)
   oLIBCOMEDIT:oBrw:nColSel++

   oLIBCOMEDIT:CREATECTAEGRESO(cCodigo,uValue)

   // Debe actualizar el libro de compras
   oLIBCOMEDIT:LIBSAVEFIELD(nCol-1) // Asignar la Cuenta de Egreso

RETURN .T.
/*
// Asignar Cuenta Contable según tipo de Documento
*/
FUNCTION PUTCTATIPDOC()
   LOCAL cTipDoc:=oLIBCOMEDIT:LBCGETCOLVALUE("LBC_TIPDOC")
   LOCAL nAt    :=ASCAN(oLIBCOMEDIT:aCodCta,{|a,n|a[1]==cTipDoc}),cCodCta,cDescri
   LOCAL nField :=oLIBCOMEDIT:LBCGETCOLPOS(IF(oLIBCOMEDIT:lCtaEgr,"LBC_CTAEGR","LBC_CODCTA"))
   LOCAL nCxC   :=0,nColor:=0
   LOCAL cDescriV // Descripcion venta
   LOCAL cNumero:="",cWhere,nLen:=10,cNumFis:="",cNumFac:=""

   IF nAt>0 .AND. nField>0

      cCodCta :=oLIBCOMEDIT:aCodCta[nAt,2]
      cDescri :=oLIBCOMEDIT:aCodCta[nAt,3]
      nCxC    :=oLIBCOMEDIT:aCodCta[nAt,4]
      nColor  :=oLIBCOMEDIT:aCodCta[nAt,5]
      cDescriV:=oLIBCOMEDIT:aCodCta[nAt,6]

      cNumFac :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_NUMFAC]
      cNumFis :=oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_NUMFIS] 

      cWhere  :="LBC_CODSUC"+GetWhere("=",oLIBCOMEDIT:cCodSuc)+" AND "+;
                "LBC_TIPDOC"+GetWhere("=",cTipDoc            )

      cNumero :=oLIBCOMEDIT:aCodCta[nAt,7]
      cNumero :=SQLINCREMENTAL(oLIBCOMEDIT:cTable,"LBC_NUMFAC",cWhere+" AND LBC_NUMFAC"+GetWhere("<>",cNumFac),NIL,cNumero,.T.,nLen)
      cNumFis :=SQLINCREMENTAL(oLIBCOMEDIT:cTable,"LBC_NUMFIS",cWhere+" AND LBC_NUMFIS"+GetWhere("<>",cNumFis),NIL,cNumFis,.T.,nLen)

      oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,nField+0]:=cCodCta
      oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,nField+1]:=cDescri
      oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_DESCRI]:=cDescriV

      oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_CXC   ]:=nCxC
      oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_TDC_CLRGRA]:=nColor
      oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_NUMFAC]:=cNumero
      oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,oLIBCOMEDIT:COL_LBC_NUMFIS]:=cNumFis

      oLIBCOMEDIT:LIBCOMGRABAR(.T.) // Guarda toda la línea

   ENDIF


RETURN .T.

FUNCTION PUTDIA(oCol,uValue,nCol,nKey)
  LOCAL dFecha

  oLIBCOMEDIT:PUTCTATIPDOC()

  IF uValue>0 .AND. uValue<=31

    dFecha:=CTOD(LSTR(uValue)+"/"+LSTR(MONTH(oLIBCOMEDIT:dFchDec))+"/"+LSTR(YEAR(oLIBCOMEDIT:dFchDec)))

    IF ValType(dFecha)="D"
       oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,nCol  ]:=uValue
       oLIBCOMEDIT:oBrw:aArrayData[oLIBCOMEDIT:oBrw:nArrayAt,nCol+1]:=dFecha
       oLIBCOMEDIT:LIBSAVEFIELD(nCol+1)
       oLIBCOMEDIT:oBrw:nColSel:=nCol+2
       RETURN .T.
    ENDIF

  ENDIF

RETURN .F.

// EOF
