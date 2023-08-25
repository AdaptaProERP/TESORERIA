// Programa   : DPDOCCXPCREARPLA
// Fecha/Hora : 02/08/2020 13:53:19
// Propósito  : Crear Plantilla para Planficación de Pagos
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cWhere,cCodSuc,nPeriodo,dFecha,dFchDec,cTitle,cCodigo,cNumPla,cNumReg,cTipDoc,oFrmMain)
   LOCAL aData,aFechas,cFileMem:="USER\BRDOCPROVCTA.MEM",V_nPeriodo:=4,cCodPar,cWhereP
   LOCAL V_dFecha:=CTOD(""),V_dFchDec:=CTOD(""),lResp
   LOCAL cServer:=oDp:cRunServer
   LOCAL lConectar:=.F.,cSql,nCol,cZonaNL,I,nPorIva,cRefere:="",cWhereR,cNumOrg
   LOCAL cNumero  :=SPACE(20)
   LOCAL cNumfis  :=SPACE(20)
   LOCAL cCodRet  :=SPACE(03)
// LOCAL cTipDoc  :=SPACE(03)
   LOCAL cCodMon  :=SPACE(03)
   LOCAL nMontoDiv:=0 // Monto planificación

   DEFAULT  dFecha   :=oDp:dFecha,;
            dFchDec  :=oDp:dFecha


   oDp:cRunServer:=NIL

   // ? cWhere,cCodSuc,nPeriodo,dFecha,dFchDec,cTitle,cCodigo,"cWhere,cCodSuc,nPeriodo,dFecha,dFchDec,cTitle,cCodigo"

   IF Type("oDOCCXPCREAR")="O" .AND. oDOCCXPCREAR:oWnd:hWnd>0
      RETURN EJECUTAR("BRRUNNEW",oDOCCXPCREAR,GetScript())
   ENDIF

   DEFAULT cCodigo:=SQLGET("DPPROVEEDORPROGCTA","PPC_CODIGO,PPC_NUMERO"),;
           cNumPla:=DPSQLROW(2)

   DEFAULT cWhere:="PPC_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
                   "PPC_NUMERO"+GetWhere("=",cNumPla)

   cWhere:="PPC_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
           "PPC_NUMERO"+GetWhere("=",cNumPla)


   IF Empty(cTipDoc)

     cRefere:=SQLGET("DPPROVEEDORPROGCTA","PPC_REFERE,PPC_TIPDOC",cWhere)
     cTipDoc:=DPSQLROW(2)

   ENDIF


   IF cTipDoc="NOM"

      IF Empty(oDp:cTipoNom)
         EJECUTAR("NMRESTDATA")
      ENDIF

      lResp:=EJECUTAR("PLAFIN_RUNNOM",cCodSuc,cCodigo,cNumPla,cNumReg,cTipDoc)

      IF lResp
         RETURN .F.
      ENDIF

   ENDIF

   IF Empty(cTipDoc)
      MensajeErr("Planificación Requiere Por Cuentas, Caso del Calendario Fiscal")
      RETURN .T.
   ENDIF

   EJECUTAR("DPPRIVCOMLEE",cTipDoc,.F.) // Lee los Privilegios del Usuario

   cWhereR:="PGC_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
            "PGC_NUMERO"+GetWhere("=",cNumPla)

   cCodRet:=SQLGET("DPPROVEEDORPROG","PGC_CODRET,PGC_NUMDOC,PGC_CODMON,PGC_REFERE",cWhereR)
   cNumOrg:=DPSQLROW(2) // Documento Original
   cCodMon:=DPSQLROW(3)
   cCodMon:=IIF(Empty(cCodMon),oDp:cMonedaExt,cCodMon)
   cRefere:=DPSQLROW(4,cRefere)

// ? cNumPla,cNumReg,"cNumPla,cNumReg"

   cWhereP:="PLP_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
            "PLP_NUMERO"+GetWhere("=",cNumPla)+" AND "+;
            "PLP_NUMREG"+GetWhere("=",cNumReg)+" AND "+;
            "PLP_TIPTRA"+GetWhere("=","D") 


   nMontoDiv:=SQLGET("DPDOCPROPROG","PLP_MTODIV,PLP_REFERE",cWhereP)
   cRefere:=DPSQLROW(2,cRefere)

   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
     ENDIF

   ENDIF

   cTitle:="Crear Documentos de CxP Desde Plantillas " +IF(Empty(cTitle),"",cTitle)

   oDp:oFrm:=NIL

   IF FILE(cFileMem) .AND. nPeriodo=NIL
      RESTORE FROM (cFileMem) ADDI
      nPeriodo:=V_nPeriodo
   ENDIF

   DEFAULT cCodSuc :=oDp:cSucursal,;
           nPeriodo:=4,;
           dFecha  :=CTOD(""),;
           dFchDec  :=CTOD("")

//   EJECUTAR("DPCAMPOSADD","DPPROVEEDORPROGCTA","PPC_CTAMOD","C",06,0,"Cuenta Modelo")
//   SQLUPDATE("DPPROVEEDORPROGCTA","PPC_CTAMOD",oDp:cCtaMod,"PPC_CTAMOD IS NULL")

   IF Empty(aData)

    cSql:= " SELECT     "+;
           " CIC_CUENTA,"+;
           " CTA_DESCRI ,"+;
           " PPC_MTODIV ,"+;
           " PPC_MONTO  ,"+;
           " PPC_TIPIVA ,"+;
           " 0 AS PORIVA,0 AS TOTAL,0 AS LOGICO "+;
           " FROM DPPROVEEDORPROGCTA"+;
           " LEFT JOIN DPPROVEEDORPROG_CTA ON PPC_CODIGO=CIC_CODIGO AND PPC_REFERE=CIC_COD2  AND CIC_CTAMOD"+GetWhere("=",oDp:cCtaMod)+;
           " LEFT JOIN DPCTA               ON PPC_CTAMOD=CTA_CODMOD AND CIC_CUENTA=CTA_CODIGO"+;
           " WHERE "+cWhere+;
           " GROUP BY PPC_CODCTA"+;
           " ORDER BY PPC_CODCTA"

     aData  :=ASQL(cSql)

     IF LEN(aData)>0 .AND. Empty(aData[1,3])
        aData[1,3]:=nMontoDiv
     ENDIF

   ENDIF

// Agregamos una Linea segun la cuenta contable
//   IF Empty(aData)
//      ? "AGREGAR DATA"
//   ENDIF
// ? LEN(aData)


   cZonaNL:=SQLGET("DPPROVEEDOR","PRO_ZONANL","PRO_CODIGO"+GetWhere("=",cCodigo))
   cZonaNL:=IF(Empty(cZonaNL),"N",cZonaNL)

   nCol :=IIF(cZonaNL="N",3,5)

   FOR I=1 TO LEN(aData)

     nPorIva:=EJECUTAR("IVACAL",aData[I,4+1],nCol,oDp:dFecha) 

     IF Empty(aData[I,1])
        aData[I,1]:=oDp:cCtaIndef
        aData[I,2]:=oDp:cCtaIndef
     ENDIF

     aData[I,5+1]:=nPorIva

   NEXT I

// ViewArray(aData)
   ViewData(aData,cTitle,oDp:cWhere)

   oDp:oFrm:=oDOCCXPCREAR

RETURN .T.


FUNCTION ViewData(aData,cTitle,cWhere_)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

   DpMdi(cTitle,"oDOCCXPCREAR","DPDOCCXPCREARPLA.EDT")

   oDOCCXPCREAR:Windows(0,0,aCoors[3]-160,MIN(900,aCoors[4]-10),.T.) // Maximizado

   EJECUTAR("DPDOCPROPAR" ,oDOCCXPCREAR,cTipDoc)

   oDOCCXPCREAR:cCodSuc  :=cCodSuc
   oDOCCXPCREAR:lMsgBar  :=.F.
   oDOCCXPCREAR:cPeriodo :=aPeriodos[nPeriodo]
   oDOCCXPCREAR:cCodSuc  :=cCodSuc
   oDOCCXPCREAR:nPeriodo :=nPeriodo
   oDOCCXPCREAR:cNombre  :=""
   oDOCCXPCREAR:dFecha   :=dFecha
   oDOCCXPCREAR:cServer  :=cServer
   oDOCCXPCREAR:dFchDec   :=dFchDec
   oDOCCXPCREAR:cWhere   :=cWhere
   oDOCCXPCREAR:cWhere_  :=cWhere_
   oDOCCXPCREAR:cWhereQry:=""
   oDOCCXPCREAR:cSql     :=oDp:cSql
   oDOCCXPCREAR:oWhere   :=TWHERE():New(oDOCCXPCREAR)
   oDOCCXPCREAR:cCodPar  :=cCodPar // Código del Parámetro
   oDOCCXPCREAR:lWhen    :=.T.
   oDOCCXPCREAR:cTextTit :="" // Texto del Titulo Heredado
   oDOCCXPCREAR:oDb      :=oDp:oDb
   oDOCCXPCREAR:cBrwCod  :="DOCPROVCTA"
   oDOCCXPCREAR:lTmdi    :=.T.
   oDOCCXPCREAR:aHead    :={}
   oDOCCXPCREAR:cCodigo  :=cCodigo
   oDOCCXPCREAR:cCodRet  :=cCodRet
   oDOCCXPCREAR:cTipDoc  :=cTipDoc
   oDOCCXPCREAR:cRefere  :=cRefere
   oDOCCXPCREAR:cNumPla  :=cNumPla
   oDOCCXPCREAR:cNumero  :=cNumero
   oDOCCXPCREAR:cNumfis  :=cNumFis
   oDOCCXPCREAR:cNumReg  :=cNumReg // Número de Registro de Planificacion
   oDOCCXPCREAR:oFrmMain :=oFrmMain
   
   oDOCCXPCREAR:nValCam  :=1
   oDOCCXPCREAR:nDesc    :=0
   oDOCCXPCREAR:nTotal   :=0
   oDOCCXPCREAR:nPlazo   :=0
   oDOCCXPCREAR:cNumOrg   :=cNumOrg
   oDOCCXPCREAR:nOption   :=1

   oDOCCXPCREAR:dFecha   :=dFecha
   oDOCCXPCREAR:dFchDec  :=dFchDec
   oDOCCXPCREAR:cPeriodo :=oDp:aPeriodos[3]
   oDOCCXPCREAR:aPeriodos:=oDp:aPeriodos	

   oDOCCXPCREAR:lPar_Moneda:=.T.
   oDOCCXPCREAR:DOC_HORA   :=DPHORA()
   oDOCCXPCREAR:DOC_CODMON :=cCodMon
   oDOCCXPCREAR:DOC_VALCAM :=EJECUTAR("DPGETVALCAM",Left(oDOCCXPCREAR:DOC_CODMON,3),oDOCCXPCREAR:dFecha,oDOCCXPCREAR:DOC_HORA)

   oDOCCXPCREAR:lWhen    :=.T.
   oDOCCXPCREAR:lBarDef  :=.T. // Modo Diseño

   oDOCCXPCREAR:lValNum  :=.F.

   // Guarda los parámetros del Browse cuando cierra la ventana
   oDOCCXPCREAR:bValid   :={|| EJECUTAR("BRWSAVEPAR",oDOCCXPCREAR)}

   oDOCCXPCREAR:lBtnMenuBrw :=.F.
   oDOCCXPCREAR:lBtnSave    :=.F.
   oDOCCXPCREAR:lBtnCrystal :=.F.
   oDOCCXPCREAR:lBtnRefresh :=.F.
   oDOCCXPCREAR:lBtnHtml    :=.T.
   oDOCCXPCREAR:lBtnExcel   :=.T.
   oDOCCXPCREAR:lBtnPreview :=.T.
   oDOCCXPCREAR:lBtnQuery   :=.F.
   oDOCCXPCREAR:lBtnOptions :=.T.
   oDOCCXPCREAR:lBtnPageDown:=.T.
   oDOCCXPCREAR:lBtnPageUp  :=.T.
   oDOCCXPCREAR:lBtnFilters :=.T.
   oDOCCXPCREAR:lBtnFind    :=.T.

   oDOCCXPCREAR:nClrPane1:=oDp:nClrPane1
   oDOCCXPCREAR:nClrPane2:=oDp:nClrPane2

   oDOCCXPCREAR:nClrText :=0
   oDOCCXPCREAR:nClrText1:=9192960
   oDOCCXPCREAR:nClrText2:=0
   oDOCCXPCREAR:nClrText3:=0

   oDOCCXPCREAR:oBrw:=TXBrowse():New( IF(oDOCCXPCREAR:lTmdi,oDOCCXPCREAR:oWnd,oDOCCXPCREAR:oDlg ))
   oDOCCXPCREAR:oBrw:SetArray( aData, .F. )
   oDOCCXPCREAR:oBrw:SetFont(oFont)

   oDOCCXPCREAR:oBrw:lFooter     := .T.
   oDOCCXPCREAR:oBrw:lHScroll    := .T.
   oDOCCXPCREAR:oBrw:nHeaderLines:= 2
   oDOCCXPCREAR:oBrw:nDataLines  := 1
   oDOCCXPCREAR:oBrw:nFooterLines:= 1

   oDOCCXPCREAR:aData            :=ACLONE(aData)

   AEVAL(oDOCCXPCREAR:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})
  

  // Campo: CCD_CODCTA
  oCol:=oDOCCXPCREAR:oBrw:aCols[1]
  oCol:cHeader      :='Cuenta'+CRLF+'Contable'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oDOCCXPCREAR:oBrw:aArrayData ) } 
  oCol:nWidth       := 160

  // Campo: CTA_DESCRI
  oCol:=oDOCCXPCREAR:oBrw:aCols[2]
  oCol:cHeader      :='Descripción'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oDOCCXPCREAR:oBrw:aArrayData ) } 
  oCol:nWidth       := 320

 // Campo: MONTO
  oCol:=oDOCCXPCREAR:oBrw:aCols[3]
  oCol:cHeader      :='Monto'+CRLF+"Divisa"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oDOCCXPCREAR:oBrw:aArrayData ) } 
  oCol:nWidth       := 130
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,3],;
                              oCol  := oDOCCXPCREAR:oBrw:aCols[3],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[3],oCol:cEditPicture)
  oCol:nEditType    :=1
  oCol:cPicture     :='999,999,999.99'
  oCol:bOnPostEdit  :={|oCol,uValue,nLastKey,nCol|oDOCCXPCREAR:PUTMTODIV(uValue)}


  // Campo: MONTO
  oCol:=oDOCCXPCREAR:oBrw:aCols[4]
  oCol:cHeader      :='Monto'+CRLF+oDp:cMoneda
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oDOCCXPCREAR:oBrw:aArrayData ) } 
  oCol:nWidth       := 130
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,4],;
                              oCol  := oDOCCXPCREAR:oBrw:aCols[4],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[4],oCol:cEditPicture)
  oCol:nEditType    :=1
  oCol:cPicture     :='999,999,999.99'
  oCol:bOnPostEdit  :={|oCol,uValue,nLastKey,nCol|oDOCCXPCREAR:PUTVALOR(uValue)}



  // Campo: IVA
  oCol:=oDOCCXPCREAR:oBrw:aCols[5]
  oCol:cHeader      :="IVA"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oDOCCXPCREAR:oBrw:aArrayData ) } 
  oCol:nWidth       := 70


  // Campo: CUANTOS
  oCol:=oDOCCXPCREAR:oBrw:aCols[6]
  oCol:cHeader      :='%'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oDOCCXPCREAR:oBrw:aArrayData ) } 
  oCol:nWidth       := 40
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,6],;
                              oCol  := oDOCCXPCREAR:oBrw:aCols[6],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[6],oCol:cEditPicture)

  // Campo: TOTAL
  oCol:=oDOCCXPCREAR:oBrw:aCols[7]
  oCol:cHeader      :='Monto'+CRLF+"Total"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oDOCCXPCREAR:oBrw:aArrayData ) } 
  oCol:nWidth       := 130
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,7],;
                              oCol  := oDOCCXPCREAR:oBrw:aCols[7],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[7],oCol:cEditPicture)




  oCol:=oDOCCXPCREAR:oBrw:aCols[8]
  oCol:cHeader      := "Reg."
  oCol:nWidth       := 40
  oCol:AddBmpFile("BITMAPS\checkverde.bmp")
  oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
  oCol:bBmpData    := { ||oBrw:=oDOCCXPCREAR:oBrw,IIF(oBrw:aArrayData[oBrw:nArrayAt,8],1,2) }
  oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
  oCol:bStrData    :={||""}



   oDOCCXPCREAR:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))

   oDOCCXPCREAR:oBrw:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oDOCCXPCREAR:oBrw,;
                                                 aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                                                 nClrText:=oDOCCXPCREAR:nClrText,;
                                                 nClrText:=IF(aLine[8],oDOCCXPCREAR:nClrText1,nClrText),;
                                                 nClrText:=IF(.F.,oDOCCXPCREAR:nClrText2,nClrText),;
                                                 {nClrText,iif( oBrw:nArrayAt%2=0, oDOCCXPCREAR:nClrPane1, oDOCCXPCREAR:nClrPane2 ) } }

//   oDOCCXPCREAR:oBrw:bClrHeader            := {|| {0,14671839 }}
//   oDOCCXPCREAR:oBrw:bClrFooter            := {|| {0,14671839 }}

   oDOCCXPCREAR:oBrw:bClrHeader          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oDOCCXPCREAR:oBrw:bClrFooter          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oDOCCXPCREAR:oBrw:bLDblClick:={|oBrw|oDOCCXPCREAR:RUNCLICK() }

   oDOCCXPCREAR:oBrw:bChange:={||oDOCCXPCREAR:BRWCHANGE()}
   oDOCCXPCREAR:oBrw:CreateFromCode()

   oDOCCXPCREAR:oWnd:oClient := oDOCCXPCREAR:oBrw

   oDOCCXPCREAR:Activate({||oDOCCXPCREAR:ViewDatBar()})

   BMPGETBTN(oDOCCXPCREAR:oBar)

   oDOCCXPCREAR:BRWRESTOREPAR()

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg:=IF(oDOCCXPCREAR:lTmdi,oDOCCXPCREAR:oWnd,oDOCCXPCREAR:oDlg)
   LOCAL nLin:=0
   LOCAL nWidth:=oDOCCXPCREAR:oBrw:nWidth()

   oDOCCXPCREAR:oBrw:GoBottom(.T.)
   oDOCCXPCREAR:oBrw:Refresh(.T.)

   IF !File("FORMS\BRDOCPROVCTA.EDT")
     oDOCCXPCREAR:oBrw:Move(44,0,700+50,460)
   ENDIF

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52-15,200 OF oDlg 3D CURSOR oCursor

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -10 BOLD
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -11 BOLD


 // Emanager no Incluye consulta de Vinculos


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSAVE.BMP",NIL,"BITMAPS\XSAVEG.BMP";
          ACTION oDOCCXPCREAR:GUARDARDOC();
          WHEN oDOCCXPCREAR:lValNum .AND. oDOCCXPCREAR:nTotal>0 UPDATE

   oBtn:cToolTip:="Guardar Documento"

   oDOCCXPCREAR:oBtnSave:=oBtn

   IF !Empty(oDOCCXPCREAR:cCodigo)

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XBROWSE.BMP";
            ACTION oDOCCXPCREAR:VERDETALLES()

    oBtn:cToolTip:="Ver Detalles"

   ENDIF

   IF !Empty(oDOCCXPCREAR:cNumOrg)

      DEFINE BUTTON oBtn;
             OF oBar;
             NOBORDER;
             FONT oFont;
             FILENAME "BITMAPS\FORM.BMP";
             ACTION EJECUTAR("VERDOCPRO",oDOCCXPCREAR:cCodSuc,oDOCCXPCREAR:cTipDoc,oDOCCXPCREAR:cCodigo,oDOCCXPCREAR:cNumOrg)

      oBtn:cToolTip:="Ver Documento de Origen "+oDOCCXPCREAR:cTipDoc+"-"+oDOCCXPCREAR:cNumOrg

   ENDIF

   DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\CONTABILIDAD.BMP";
            ACTION oDOCCXPCREAR:VERPROVEEDORES()

   oBtn:cToolTip:="Ver Proveedores Asociada con la Cuenta Focalizada "

   DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\PROVEEDORES.BMP";
            ACTION EJECUTAR("DPPROVEEDOR",0,oDOCCXPCREAR:cCodigo)

   oBtn:cToolTip:="Ver Formulario del Proveedor "

/*
   IF Empty(oDOCCXPCREAR:cServer) .AND. !Empty(SQLGET("DPBRWLNK","EBR_CODIGO","EBR_CODIGO"+GetWhere("=","DOCPROVCTA")))
*/

   IF ISSQLFIND("DPBRWLNKCONCAT","BRC_CODIGO"+GetWhere("=","DOCPROVCTA"))

       DEFINE BUTTON oBtn;
       OF oBar;
       NOBORDER;
       FONT oFont;
       FILENAME "BITMAPS\XBROWSE.BMP";
       ACTION EJECUTAR("BRWRUNBRWLINK",oDOCCXPCREAR:oBrw,"DOCPROVCTA",oDOCCXPCREAR:cSql,oDOCCXPCREAR:nPeriodo,oDOCCXPCREAR:dFecha,oDOCCXPCREAR:dFchDec,oDOCCXPCREAR)

       oBtn:cToolTip:="Ejecutar Browse Vinculado(s)"
       oDOCCXPCREAR:oBtnRun:=oBtn



       oDOCCXPCREAR:oBrw:bLDblClick:={||EVAL(oDOCCXPCREAR:oBtnRun:bAction) }


   ENDIF



IF oDOCCXPCREAR:lBtnSave

      DEFINE BITMAP OF OUTLOOK oBRWMENURUN:oOut ;
             BITMAP "BITMAPS\XSAVE.BMP";
             PROMPT "Guardar Consulta";
             ACTION EJECUTAR("DPBRWSAVE",oDOCCXPCREAR:oBrw,oDOCCXPCREAR:oFrm)
ENDIF

IF oDOCCXPCREAR:lBtnMenuBrw

 DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\BRWMENU.BMP",NIL,"BITMAPS\BRWMENUG.BMP";
          ACTION (EJECUTAR("BRWBUILDHEAD",oDOCCXPCREAR),;
                  EJECUTAR("DPBRWMENURUN",oDOCCXPCREAR,oDOCCXPCREAR:oBrw,oDOCCXPCREAR:cBrwCod,oDOCCXPCREAR:cTitle,oDOCCXPCREAR:aHead));
          WHEN !Empty(oDOCCXPCREAR:oBrw:aArrayData[1,1])

   oBtn:cToolTip:="Menú de Opciones"

ENDIF


IF oDOCCXPCREAR:lBtnFind

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
          ACTION EJECUTAR("BRWSETFIND",oDOCCXPCREAR:oBrw)

   oBtn:cToolTip:="Buscar"
ENDIF

IF oDOCCXPCREAR:lBtnFilters

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          MENU EJECUTAR("BRBTNMENUFILTER",oDOCCXPCREAR:oBrw,oDOCCXPCREAR);
          ACTION EJECUTAR("BRWSETFILTER",oDOCCXPCREAR:oBrw)

   oBtn:cToolTip:="Filtrar Registros"
ENDIF

IF oDOCCXPCREAR:lBtnOptions

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
          ACTION EJECUTAR("BRWSETOPTIONS",oDOCCXPCREAR:oBrw);
          WHEN LEN(oDOCCXPCREAR:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

ENDIF

IF oDOCCXPCREAR:lBtnRefresh

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\REFRESH.BMP";
          ACTION oDOCCXPCREAR:BRWREFRESCAR()

   oBtn:cToolTip:="Refrescar"

ENDIF

IF oDOCCXPCREAR:lBtnCrystal

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.BMP";
          ACTION EJECUTAR("BRWTODBF",oDOCCXPCREAR)

   oBtn:cToolTip:="Visualizar Mediante Crystal Report"

ENDIF

IF oDOCCXPCREAR:lBtnExcel


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
            ACTION (EJECUTAR("BRWTOEXCEL",oDOCCXPCREAR:oBrw,oDOCCXPCREAR:cTitle,oDOCCXPCREAR:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oDOCCXPCREAR:oBtnXls:=oBtn

ENDIF

IF oDOCCXPCREAR:lBtnHtml

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          ACTION (oDOCCXPCREAR:HTMLHEAD(),EJECUTAR("BRWTOHTML",oDOCCXPCREAR:oBrw,NIL,oDOCCXPCREAR:cTitle,oDOCCXPCREAR:aHead))

   oBtn:cToolTip:="Generar Archivo html"

   oDOCCXPCREAR:oBtnHtml:=oBtn

ENDIF


IF oDOCCXPCREAR:lBtnPreview

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
          ACTION (EJECUTAR("BRWPREVIEW",oDOCCXPCREAR:oBrw))

   oBtn:cToolTip:="Previsualización"

   oDOCCXPCREAR:oBtnPreview:=oBtn

ENDIF

   IF ISSQLGET("DPREPORTES","REP_CODIGO","BRDOCPROVCTA")

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XPRINT.BMP";
            ACTION oDOCCXPCREAR:IMPRIMIR()

      oBtn:cToolTip:="Imprimir"

     oDOCCXPCREAR:oBtnPrint:=oBtn

   ENDIF

IF oDOCCXPCREAR:lBtnQuery


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oDOCCXPCREAR:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF




   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          ACTION (oDOCCXPCREAR:oBrw:GoTop(),oDOCCXPCREAR:oBrw:Setfocus())

IF nWidth>800 .OR. nWidth=0

   IF oDOCCXPCREAR:lBtnPageDown

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\xSIG.BMP";
            ACTION (oDOCCXPCREAR:oBrw:PageDown(),oDOCCXPCREAR:oBrw:Setfocus())
  ENDIF

  IF  oDOCCXPCREAR:lBtnPageUp

    DEFINE BUTTON oBtn;
           OF oBar;
           NOBORDER;
           FONT oFont;
           FILENAME "BITMAPS\xANT.BMP";
           ACTION (oDOCCXPCREAR:oBrw:PageUp(),oDOCCXPCREAR:oBrw:Setfocus())
  ENDIF

ENDIF


  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
          ACTION (oDOCCXPCREAR:oBrw:GoBottom(),oDOCCXPCREAR:oBrw:Setfocus())


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION oDOCCXPCREAR:Close()

  oDOCCXPCREAR:oBrw:SetColor(0,oDOCCXPCREAR:nClrPane1)

  EVAL(oDOCCXPCREAR:oBrw:bChange)

  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oDOCCXPCREAR:oBar:=oBar

  nLin:=32
  AEVAL(oBar:aControls,{|o,n|nLin:=nLin+o:nWidth() })


  oDOCCXPCREAR:SETBTNBAR(45,45,oBar)

  oDOCCXPCREAR:lBarDef:=.T.

  DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

  nLin:=15

  @ 50,nLin SAY " "+oDOCCXPCREAR:cCodigo OF oBar PIXEL SIZE 90,20 COLOR CLR_WHITE,16744448 BORDER FONT oFontB

  @ 50,nLin+100 SAY " "+SQLGET("DPPROVEEDOR","PRO_NOMBRE","PRO_CODIGO"+GetWhere("=",oDOCCXPCREAR:cCodigo));
            OF oBar PIXEL SIZE 390,20 COLOR CLR_WHITE,16744448 BORDER

  @ 130,nLin SAY oDOCCXPCREAR:cRefere OF oBar PIXEL SIZE 200,20 FONT oFontB BORDER

  @ 130,nLin SAY oDOCCXPCREAR:cTipDoc+" "+SQLGET("DPTIPDOCPRO","TDC_DESCRI","TDC_TIPO"+GetWhere("=",oDOCCXPCREAR:cTipDoc));
                 OF oBar PIXEL SIZE 200,20 FONT oFontB BORDER

  @ 130,nLin SAY oDOCCXPCREAR:oSayCodRet;
                 PROMPT "CODRET"+SQLGET("DPCONRETISLR","CTR_DESCRI","CTR_CODIGO"+GetWhere("=",oDOCCXPCREAR:cCodRet));
                 OF oBar PIXEL BORDER

  @ 110,nLin+100 SAY "Emisión "         OF oBar PIXEL RIGHT FONT oFontB
  @ 115,nLin+100 SAY "Declaración "     OF oBar PIXEL RIGHT FONT oFontB
  @ 120,nLin+100 SAY "    Referencia "  OF oBar PIXEL RIGHT FONT oFontB
  @ 125,nLin+100 SAY "  Cód.Ret ISLR "  OF oBar PIXEL RIGHT FONT oFontB
  @ 130,nLin+100 SAY "Tipo Documento "  OF oBar PIXEL RIGHT FONT oFontB
  @ 130,nLin+100 SAY "#Planificación "  OF oBar PIXEL RIGHT FONT oFontB


  @ 130,nLin SAY oDOCCXPCREAR:oSayNumPla;
                 PROMPT oDOCCXPCREAR:cNumReg;
                 OF oBar PIXEL BORDER

  @ 130,nLin+100 SAY "# Documento "  OF oBar PIXEL RIGHT FONT oFontB
  @ 130,nLin+100 SAY "# Fiscal "     OF oBar PIXEL RIGHT FONT oFontB


  @ 130,nLin+560 SAY "Divisa "  OF oBar PIXEL RIGHT FONT oFontB 
  @ 150,nLin+560 SAY "Valor "   OF oBar PIXEL RIGHT FONT oFontB


  @ 130,nLin GET oDOCCXPCREAR:oNumero;
             VAR oDOCCXPCREAR:cNumero OF oBar;
             VALID oDOCCXPCREAR:VALNUMERO();
             PIXEL SIZE 200,20 FONT oFontB

  oDOCCXPCREAR:oNumero:bLostFocus:={|| EVAL(oDOCCXPCREAR:oNumero:bValid) }
        
  @ 150,nLin GET oDOCCXPCREAR:oNumFis;
             VAR oDOCCXPCREAR:cNumFis  OF oBar;
             VALID oDOCCXPCREAR:VALNUMFIS();
             PIXEL SIZE 200,20 FONT oFontB


  @ 100+35, nLin+160-30 BMPGET oDOCCXPCREAR:oFecha  VAR oDOCCXPCREAR:dFecha;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oDOCCXPCREAR:oFecha ,oDOCCXPCREAR:dFecha);
                SIZE 76,24;
                OF   oBar;
                WHEN oDOCCXPCREAR:lWhen ;
                FONT oFont

  oDOCCXPCREAR:oFecha:cToolTip:="F6: Calendario"



  @ 100+60, nLin+252-30 BMPGET oDOCCXPCREAR:oFchDec  VAR oDOCCXPCREAR:dFchDec;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oDOCCXPCREAR:oFchDec,oDOCCXPCREAR:dFchDec);
                SIZE 76,24;
                WHEN oDOCCXPCREAR:lWhen ;
                OF oBar;
                FONT oFont

  oDOCCXPCREAR:oFchDec:cToolTip:="F6: Calendario"

  //
  // Campo : DOC_CODMON
  // Uso   : Moneda                                  
  //
  @ 10, 40 COMBOBOX oDOCCXPCREAR:oDOC_CODMON VAR oDOCCXPCREAR:DOC_CODMON ITEMS oDp:aMonedas;
                       VALID oDOCCXPCREAR:PROVALCAM(.t.);
                       ON CHANGE oDOCCXPCREAR:PROVALCAM();
                       WHEN (oDOCCXPCREAR:lPar_Moneda .AND. AccessField("DPDOCPRO","DOC_CODMON",oDOCCXPCREAR:nOption);
                             .AND. oDOCCXPCREAR:nOption!=0 .AND. LEN(oDp:aMonedas)>1) SIZE 100,200 FONT oFontB

  ComboIni(oDOCCXPCREAR:oDOC_CODMON)

  @ 13,40 GET oDOCCXPCREAR:oDOC_VALCAM  VAR oDOCCXPCREAR:DOC_VALCAM;
              PICTURE oDp:cPictValCam;
              WHEN (oDOCCXPCREAR:lPar_Moneda .AND. (!oDp:cMoneda==LEFT(oDOCCXPCREAR:DOC_CODMON,LEN(oDp:cMoneda))) .AND. ;
                    AccessField("DPDOCPRO","DOC_VALCAM",oDOCCXPCREAR:nOption);
                    .AND. oDOCCXPCREAR:nOption!=0);
              SIZE 80	,20 RIGHT FONT oFontB


 //  BMPGETBTN(oBar,oFontB,20)

  DPFOCUS(oDOCCXPCREAR:oNumero)


RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()
  LOCAL aLine:=oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt]


  IF oDOCCXPCREAR:oBrw:nColSel=8     
    oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,8]:=!oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,8]		
    oDOCCXPCREAR:oBrw:Drawline(.T.)
  ENDIF



RETURN .T.


/*
// Imprimir
*/
FUNCTION IMPRIMIR()
  LOCAL oRep,cWhere

  oRep:=REPORTE("BRDOCPROVCTA",cWhere)
  oRep:cSql  :=oDOCCXPCREAR:cSql
  oRep:cTitle:=oDOCCXPCREAR:cTitle

RETURN .T.

FUNCTION LEEFECHAS()
RETURN .T.


FUNCTION HACERWHERE(dFecha,dFchDec,cWhere_,lRun)
RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer)
RETURN aData


FUNCTION SAVEPERIODO()
RETURN .T.

/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oDOCCXPCREAR)
RETURN .T.

/*
// Ejecución Cambio de Linea
*/
FUNCTION BRWCHANGE()
RETURN NIL

/*
// Refrescar Browse
*/
FUNCTION BRWREFRESCAR()
RETURN NIL


FUNCTION BTNMENU(nOption,cOption)

   IF nOption=1
   ENDIF

RETURN .T.

FUNCTION HTMLHEAD()
   oDOCCXPCREAR:aHead:=EJECUTAR("HTMLHEAD",oDOCCXPCREAR)
RETURN

// Restaurar Parametros
FUNCTION BRWRESTOREPAR()
  EJECUTAR("BRWRESTOREPAR",oDOCCXPCREAR)
RETURN .T.


FUNCTION VERPROVEEDORES()
  LOCAL aLine  :=oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt]
  LOCAL cCuenta:=aLine[1]
  LOCAL cWhere :="CCD_CODCTA"+GetWhere("=",cCuenta)

RETURN EJECUTAR("BRDPDOCPROCTAP",cWhere,NIL,11,CTOD(""),CTOD(""),NIL,cCuenta)


FUNCTION VERDETALLES()
  LOCAL aLine  :=oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt]
  LOCAL cCuenta:=aLine[1]
  LOCAL cWhere :="DOC_CODIGO"+GetWhere("=",oDOCCXPCREAR:cCodigo)+" AND "+;
                 "CCD_CODCTA"+GetWhere("=",cCuenta)

 
RETURN EJECUTAR("BRDPDOCPROCTAD",cWhere,NIL,11,CTOD(""),CTOD(""),NIL,cCuenta)

FUNCTION LEEFECHAS()
RETURN .T.

FUNCTION PUTMTODIV(uValue,nCol)
  LOCAL aLine  :=oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt]
  LOCAL nMtoBs :=ROUND(uValue*oDOCCXPCREAR:DOC_VALCAM,2)

  oDOCCXPCREAR:nValCam:=oDOCCXPCREAR:DOC_VALCAM

  DEFAULT nCol:=3 

// ? uValue,nMtoBs,"uValue,nMtoBs",oDOCCXPCREAR:DOC_VALCAM,"oDOCCXPCREAR:nValCam"
   
  oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,nCol]  :=uValue
  oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,nCol+1]:=nMtoBs

  oDOCCXPCREAR:PUTVALOR(nMtoBs,nCol+1)

//  oDOCCXPCREAR:oBrw:Drawline(.T.)

/*
  oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,6+1]:=uValue+PORCEN(uValue,aLine[5+1])

  oDOCCXPCREAR:oBrw:Drawline(.T.)
  oDOCCXPCREAR:oBrw:KeyBoard(VK_DOWN)
*/
//  oDOCCXPCREAR:CALTOTAL()

  // EJECUTAR("BRWCALTOTALES",oDOCCXPCREAR:oBrw,.F.)

RETURN NIL


FUNCTION PUTVALOR(uValue,nCol)
  LOCAL aLine:=oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt]

  DEFAULT nCol:=3
   
  oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,nCol]:=uValue
  oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,7+1   ]:=.T.

  oDOCCXPCREAR:oBrw:aArrayData[oDOCCXPCREAR:oBrw:nArrayAt,6+1]:=uValue+PORCEN(uValue,aLine[5+1])

  oDOCCXPCREAR:oBrw:Drawline(.T.)
  oDOCCXPCREAR:oBrw:KeyBoard(VK_DOWN)

  oDOCCXPCREAR:CALTOTAL()

  // EJECUTAR("BRWCALTOTALES",oDOCCXPCREAR:oBrw,.F.)

RETURN NIL

FUNCTION CALTOTAL()
  LOCAL aTotal:=ACLONE(oDOCCXPCREAR:oBrw:aArrayData)
  
  ADEPURA(aTotal,{|a,n| !a[7+1]})

  aTotal:=ATOTALES(aTotal)

  oDOCCXPCREAR:nTotal:=aTotal[6+1]

  oDOCCXPCREAR:oBtnSave:ForWhen(.T.)

RETURN EJECUTAR("BRWCALTOTALES",oDOCCXPCREAR:oBrw,.F.,aTotal)

FUNCTION VALTIPDOC()
RETURN .T.

FUNCTION GUARDARDOC()
  LOCAL aData:=ACLONE(oDOCCXPCREAR:oBrw:aArrayData)
  LOCAL aTodos:=ACLONE(oDOCCXPCREAR:oBrw:aArrayData)
  LOCAL oProvPrg,cWhere,cNumPla,cIva,aTotal,oTable,I
  LOCAL cTipDoc:=oDOCCXPCREAR:cTipDoc+" "+ALLTRIM(SQLGET("DPTIPDOCPRO","TDC_DESCRI","TDC_TIPO"+GetWhere("=",oDOCCXPCREAR:cTipDoc)))

  aData:=ADEPURA(aData,{|a,n| !a[7]})

  IF Empty(aData)
     oDOCCXPCREAR:oBtnSave:MsgErr("Necesario Seleccionar Cuenta","Validación de Cuentas")
     DPFOCUS(oDOCCXPCREAR:oBrw)
     RETURN .F.
  ENDIF

  IF Empty(oDOCCXPCREAR:cNumero)
    oDOCCXPCREAR:oRefere:MsgErr("Necesario Indicar Referencia","Validación")
    RETURN .F.
  ENDIF

  oDOCCXPCREAR:oBrw:aArrayData:=ACLONE(aData)
  oDOCCXPCREAR:oBrw:nArrayAt:=1
  oDOCCXPCREAR:oBrw:nRowSel :=1
  oDOCCXPCREAR:oBrw:GoTop()

  EJECUTAR("BRWCALTOTALES",oDOCCXPCREAR:oBrw)

  oDOCCXPCREAR:oBrw:Refresh(.F.)


  IF !MsgNoYes("Desea Registrar #"+oDOCCXPCREAR:cNumero,cTipDoc)

     oDOCCXPCREAR:oBrw:aArrayData:=ACLONE(aTodos)
     oDOCCXPCREAR:oBrw:nArrayAt:=1
     oDOCCXPCREAR:oBrw:nRowSel :=1
     oDOCCXPCREAR:oBrw:GoTop()
     oDOCCXPCREAR:oBrw:Refresh(.F.)

     EJECUTAR("BRWCALTOTALES",oDOCCXPCREAR:oBrw)

     RETURN .T.

  ENDIF

  cIva  :=aData[1,6]
  aTotal:=ATOTALES(aData)

  CursorWait()
  oDOCCXPCREAR:CREA_DOC()


RETURN .T.

FUNCTION VALCODRET()

   IF !ISSQLFIND("DPCONRETISLR","CTR_CODIGO"+GetWhere("=",oDOCPRODEFPLA:cCodRet))
     oDOCPRODEFPLA:oCodRet:KeyBoard(VK_F6)
     RETURN .F.
   ENDIF

   oDOCPRODEFPLA:oSayCodRet:Refresh(.T.)

RETURN .T.

FUNCTION VALNUMERO()

  IF Empty(oDOCCXPCREAR:cNumero)
      oDOCCXPCREAR:lValNum:=.F.
  ENDIF

  IF Empty(oDOCCXPCREAR:cNumFis)
     oDOCCXPCREAR:oNumFis:VarPut(oDOCCXPCREAR:cNumero,.T.)
  ENDIF

  oDOCCXPCREAR:lValNum:=.T.

  oDOCCXPCREAR:oBtnSave:ForWhen(.T.)

RETURN .T.

FUNCTION VALNUMFIS()

   ? "valida numero fiscal"


RETURN .T.

FUNCTION CREA_DOC()
    LOCAL cCodSuc:=oDOCCXPCREAR:cCodSuc
    LOCAL cCodPro:=oDOCCXPCREAR:cCodigo
    LOCAL cTipDoc:=oDOCCXPCREAR:cTipDoc
    LOCAL cNumReg:=oDOCCXPCREAR:cNumReg
    LOCAL nMonto :=oDOCCXPCREAR:nTotal
    LOCAL dFecha :=oDOCCXPCREAR:dFecha
    LOCAL dFchDec:=oDOCCXPCREAR:dFchDec
    LOCAL nPlazo :=oDOCCXPCREAR:nPlazo
    LOCAL oDoc_Pro,oData
    LOCAL oItem,cRefere,cCtaEgr,cCodCta
    LOCAL nLen,lZero
    LOCAL cWhere,oTable
    LOCAL cNumero:=oDOCCXPCREAR:cNumero
    LOCAL cNumFis:=oDOCCXPCREAR:cNumFis
    LOCAL dFecha
    LOCAL lAppend:=.T.,aLine:={}
    LOCAL aData  :=ACLONE(oDOCCXPCREAR:oBrw:aArrayData)
    LOCAL oTipDocPro

// ? oDOCCXPCREAR:cNumPla,oDOCCXPCREAR:cNumero,oDOCCXPCREAR:cNumfis,oDOCCXPCREAR:cNumReg,"oDOCCXPCREAR:cNumPla,oDOCCXPCREAR:cNumero,oDOCCXPCREAR:cNumfis,oDOCCXPCREAR:cNumReg"
	
    DEFAULT cCodSuc:=oDp:cSucursal,;
            cCodPro:=EJECUTAR("GETCODSENIAT"),;
            cTipDoc:="PRT",;
            cNumReg:="0000001393",;
            dFecha :=DPFECHA(),;
            nPlazo :=0

   aData:=ADEPURA(aData,{|a,n| !a[7+1]})

   cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
           "DOC_CODIGO"+GetWhere("=",cCodPro)+" AND "+;
           "DOC_PPLREG"+getWhere("=",cNumReg)+" AND "+;
           "DOC_TIPTRA='D'"

   cNumero:=SQLGET("DPDOCPRO","DOC_NUMERO",cWhere)

   IF !Empty(cNumero)

     lAppend:=.F.
     cWhere :=" WHERE "+;
              "DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
              "DOC_CODIGO"+GetWhere("=",cCodPro)+" AND "+;
              "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
              "DOC_TIPTRA='D'"
   ELSE

     lAppend:=.T.
     cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
             "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
             "DOC_CODIGO"+GetWhere("=",cCodPro)+" AND "+;
             "DOC_TIPTRA='D'"

   
     oTipDocPro:=OpenTable("SELECT * FROM DPTIPDOCPRO WHERE TDC_TIPO"+GetWhere("=",cTipDoc),.T.)
     oTipDocPro:End()

     IF  !oTipDocPro:TDC_NUMEDT

       cNumero:=SQLINCREMENTAL("DPDOCPRO","DOC_NUMERO",cWhere)
       nLen   :=SQLGET("DPTIPDOCPRO","TDC_LEN" ,"TDC_TIPO"+GetWhere("=",cTipDoc))
       lZero  :=SQLGET("DPTIPDOCPRO","TDC_ZERO","TDC_TIPO"+GetWhere("=",cTipDoc))
       IF nLen>1 .AND. lZero
         cNumero:=STRZERO(VAL(cNumero),nLen)
       ENDIF

      ELSE

        cNumero:=oDOCCXPCREAR:cNumero

      ENDIF

     cWhere:=""
 
   ENDIF

   oDoc_Pro:=OpenTable("SELECT * FROM DPDOCPRO "+cWhere , !lAppend )
   oDoc_Pro:EXECUTE(" SET FOREIGN_KEY_CHECKS = 0")

   IF oDoc_Pro:RecCount()=0
     cWhere:=""
     oDoc_Pro:AppendBlank()
   ENDIF

   oDoc_Pro:Replace("DOC_CODSUC" , cCodSuc)
   oDoc_Pro:Replace("DOC_TIPDOC" , cTipDoc)
   oDoc_Pro:Replace("DOC_CODIGO" , cCodPro)
   oDoc_Pro:Replace("DOC_NUMERO" , cNumero)
   oDoc_Pro:Replace("DOC_TIPTRA" , "D")
   oDoc_Pro:Replace("DOC_CODMON" , oDOCCXPCREAR:DOC_CODMON)
   oDoc_Pro:Replace("DOC_ACT"    , 1)
   oDoc_Pro:Replace("DOC_CXP"    , 1)
   oDoc_Pro:Replace("DOC_NETO"   , nMonto)
   oDoc_Pro:Replace("DOC_ESTADO" , IF(nMonto=0,"PA","AC"))
   oDoc_Pro:Replace("DOC_DOCORG" , "D")
   oDoc_Pro:Replace("DOC_ORIGEN" , "N")
   oDoc_Pro:Replace("DOC_USUARI" , oDp:cUsuario)
   oDoc_Pro:Replace("DOC_VALCAM" , oDOCCXPCREAR:DOC_VALCAM)
   oDoc_Pro:Replace("DOC_PLAZO"  , nPlazo)
   oDoc_Pro:Replace("DOC_FCHVEN" , dFecha+nPlazo)
   oDoc_Pro:Replace("DOC_FCHDEC" , oDOCCXPCREAR:dFecha)
   oDoc_Pro:Replace("DOC_FECHA"  , dFchDec)
   oDoc_Pro:Replace("DOC_PPLREG" , oDOCCXPCREAR:cNumReg) // cNumReg) // Planificacion de Documentos del Proveedor
   oDoc_Pro:Replace("DOC_NUMFIS" , oDOCCXPCREAR:cNumfis) // Número Fiscal

   AEVAL(oDoc_Pro:aFields,{|a,n| AADD(aLine,oDoc_Pro:FieldGet(n))})
   oDoc_Pro:Commit(cWhere)

//  ? CLPCOPY(oDp:cSql),cTipDoc,cWhere

   // Documento con Monto Cero con registro de pago
   IF nMonto=0
      // Debe Hacer el Pago del Documento
      oDoc_Pro:AppendBlank()
      AEVAL(aLine,{|a,n|oDoc_Pro:FieldPut(n,a)})
      oDoc_Pro:Replace("DOC_CXP"    , -1)
      oDoc_Pro:Replace("DOC_TIPTRA" , "P")
      oDoc_Pro:Commit("")
   ENDIF

   oDoc_Pro:End()


 // ? cNumReg,"cNumReg"

   SQLUPDATE("DPDOCPROPROG",{"PLP_NUMDOC"       ,"PLP_ESTADO"},;
                            {oDoc_Pro:DOC_NUMERO,"D"         },;
                            "PLP_CODSUC" + GetWhere("=" , cCodSuc)+" AND "+;
                            "PLP_TIPDOC" + GetWhere("=" , cTipDoc)+" AND "+;
                            "PLP_CODIGO" + GetWhere("=" , cCodPro)+" AND "+;
                            "PLP_NUMREG" + GetWhere("=" , cNumReg)+" AND "+;
                            "PLP_TIPTRA" + GetWhere("=" , "D"    ))

  // Crea Item
  cRefere:=SQLGET("DPPROVEEDORPROG","PGC_REFERE,PGC_CTAEGR",;
                                    "PGC_CODIGO"+GetWhere("=",cCodPro)+" AND "+;
                                    "PGC_TIPDOC"+GetWhere("=",cTipDoc))



  SQLDELETE("DPDOCPROCTA","CCD_CODSUC" + GetWhere("=" , cCodSuc)+" AND "+;
                          "CCD_TIPDOC" + GetWhere("=" , cTipDoc)+" AND "+;
                          "CCD_CODIGO" + GetWhere("=" , cCodPro)+" AND "+;
                          "CCD_NUMERO" + GetWhere("=" , cNumero))

  oItem:=OpenTable("SELECT * FROM DPDOCPROCTA",.F.)

  FOR I=1 TO LEN(aData)

    // cCtaEgr:=oDp:aRow[2]
    cCodCta:=aData[I,1]
    nMonto :=aData[I,4]
    cCtaEgr:=SQLGET("DPCTAEGRESO_CTA","CIC_CUENTA","CIC_CODIGO"+GetWhere("=",cCodCta))

    IF Empty(cCtaEgr)
       cCtaEgr:=oDp:cCtaIndef
    ENDIF

//    IF Empty(cCtaEgr)
//       cCtaEgr:=SQLGET("DPCTAEGRESO","CIC_CUENTA","CIC_CODIGO"+GetWhere("=",cCodCta))
//    ENDIF

    
    oItem:AppendBlank()
    oItem:Replace("CCD_CODSUC" , cCodSuc)
    oItem:Replace("CCD_TIPDOC" , cTipDoc)
    oItem:Replace("CCD_DESCRI" , aData[I,2])
    oItem:Replace("CCD_CODIGO" , cCodPro)
    oItem:Replace("CCD_NUMERO" , cNumero)
    oItem:Replace("CCD_TIPTRA" , "D"    )
    oItem:Replace("CCD_CODCTA" , cCodCta)
    oItem:Replace("CCD_CTAEGR" , cCtaEgr)
    oItem:Replace("CCD_ITEM"   , STRZERO(I,3))
    oItem:Replace("CCD_CENCOS" , oDp:cCenCos)
    oItem:Replace("CCD_ACT"    , 1      )
    oItem:Replace("CCD_REFERE" , cRefere)
    oItem:Replace("CCD_MTODIV" , aData[I,3+0])
    oItem:Replace("CCD_TIPIVA" , aData[I,4+1])
    oItem:Replace("CCD_PORIVA" , aData[I,5+1])
    oItem:Replace("CCD_MONTO"  , nMonto )
    oItem:Replace("CCD_CTAMOD" , oDp:cCtaMod)

    oItem:Commit()
 

  NEXT I

  oItem:End()

  oDoc_Pro:EXECUTE(" SET FOREIGN_KEY_CHECKS = 1")

// ? oDOCCXPCREAR:cCodSuc,oDOCCXPCREAR:cNumero,oDOCCXPCREAR:cCodigo,NIL,oDOCCXPCREAR:cTipDoc
  cRefere:=ALLTRIM(SQLGET("DPTIPDOCPRO","TDC_DESCRI","TDC_TIPO"+GetWhere("=",oDOCCXPCREAR:cTipDoc)))

  IF ValType(oDOCCXPCREAR:oFrmMain)="O"
     oDOCCXPCREAR:oFrmMain:BRWREFRESCAR()
  ENDIF

  EJECUTAR("DPDOCPROMNU",oDOCCXPCREAR:cCodSuc,cNumero,oDOCCXPCREAR:cCodigo,cRefere,oDOCCXPCREAR:cTipDoc)

  // ENDIF

RETURN .T.
/*
// Lee las tasas impositivas
*/
FUNCTION PROVALCAM(lFocus)

   DEFAULT lFocus:=.F.

   oDOCCXPCREAR:DOC_VALCAM:=EJECUTAR("DPGETVALCAM",Left(oDOCCXPCREAR:DOC_CODMON,3),oDOCCXPCREAR:dFecha,oDOCCXPCREAR:DOC_HORA)
   oDOCCXPCREAR:oDOC_VALCAM:Refresh(.T.)

RETURN .T.



// EOF

