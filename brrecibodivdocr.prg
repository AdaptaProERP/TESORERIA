// Programa   : BRRECIBODIVDOCR
// Fecha/Hora : 28/09/2022 10:18:55
// Propósito  : "Documentos Generador por Recibos de Ingreso"
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,cRecibo,cRecibo2)
   LOCAL aData,aFechas,cFileMem:="USER\BRRECIBODIVDOCR.MEM",V_nPeriodo:=1,cCodPar,cCodCli
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer
   LOCAL lConectar:=.F.

   oDp:cRunServer:=NIL

   IF Type("oRECIBODIVDOCR")="O" .AND. oRECIBODIVDOCR:oWnd:hWnd>0
      RETURN EJECUTAR("BRRUNNEW",oRECIBODIVDOCR,GetScript())
   ENDIF

   IF Empty(cRecibo2)
      cRecibo2:=cRecibo
   ENDIF

   DEFAULT cCodSuc :=oDp:cSucursal,;
           cRecibo :=SQLGETMAX("DPRECIBOSCLI","REC_NUMERO","REC_CODSUC"+GetWhere("=",cCodSuc)),;
           cRecibo2:=cRecibo,;
           cWhere  :="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                     GetWhereOr("DOC_RECNUM",{cRecibo,cRecibo2})+" AND "+;
                     "DOC_DOCORG"+GetWhere("=","R"    )
                    
   cCodCli:=SQLGET("DPRECIBOSCLI","REC_CODIGO","REC_CODSUC"+GetWhere("=",cCodSuc)+" AND REC_NUMERO"+GetWhere("=",cRecibo))

   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
             ENDIF

   ENDIF


   cTitle:="Documentos Generador por Recibos de Ingreso" +IF(Empty(cTitle),"",cTitle)

   oDp:oFrm:=NIL

   IF FILE(cFileMem) .AND. nPeriodo=NIL
      RESTORE FROM (cFileMem) ADDI
      nPeriodo:=V_nPeriodo
   ENDIF

   DEFAULT cCodSuc :=oDp:cSucursal,;
           nPeriodo:=4,;
           dDesde  :=CTOD(""),;
           dHasta  :=CTOD("")


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

   IF .F.

      IF nPeriodo=10
        dDesde :=V_dDesde
        dHasta :=V_dHasta
      ELSE
        aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)
        dDesde :=aFechas[1]
        dHasta :=aFechas[2]
      ENDIF

     aData :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere),NIL,cServer,NIL)


   ELSEIF (.T.)

     aData :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere),NIL,cServer,NIL)

   ENDIF

   IF Empty(aData)
      MensajeErr("no hay "+cTitle,"Información no Encontrada")
      RETURN .F.
   ENDIF

   ViewData(aData,cTitle,oDp:cWhere)

   oDp:oFrm:=oRECIBODIVDOCR

RETURN .T.


FUNCTION ViewData(aData,cTitle,cWhere_)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

   DpMdi(cTitle,"oRECIBODIVDOCR","BRRECIBODIVDOCR.EDT")
// oRECIBODIVDOCR:CreateWindow(0,0,100,550)
   oRECIBODIVDOCR:Windows(0,0,aCoors[3]-160,MIN(1724,aCoors[4]-10),.T.) // Maximizado

   oRECIBODIVDOCR:cCodSuc  :=cCodSuc
   oRECIBODIVDOCR:cRecibo  :=cRecibo
   oRECIBODIVDOCR:cRecibo2 :=cRecibo2

   oRECIBODIVDOCR:cCodCli  :=cCodCli
   oRECIBODIVDOCR:cNombre  :=SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",cCodCli))
   oRECIBODIVDOCR:lMsgBar  :=.F.
   oRECIBODIVDOCR:cPeriodo :=aPeriodos[nPeriodo]
   oRECIBODIVDOCR:cCodSuc  :=cCodSuc
   oRECIBODIVDOCR:nPeriodo :=nPeriodo
//   oRECIBODIVDOCR:cNombre  :=""
   oRECIBODIVDOCR:dDesde   :=dDesde
   oRECIBODIVDOCR:cServer  :=cServer
   oRECIBODIVDOCR:dHasta   :=dHasta
   oRECIBODIVDOCR:cWhere   :=cWhere
   oRECIBODIVDOCR:cWhere_  :=cWhere_
   oRECIBODIVDOCR:cWhereQry:=""
   oRECIBODIVDOCR:cSql     :=oDp:cSql
   oRECIBODIVDOCR:oWhere   :=TWHERE():New(oRECIBODIVDOCR)
   oRECIBODIVDOCR:cCodPar  :=cCodPar // Código del Parámetro
   oRECIBODIVDOCR:lWhen    :=.T.
   oRECIBODIVDOCR:cTextTit :="" // Texto del Titulo Heredado
   oRECIBODIVDOCR:oDb      :=oDp:oDb
   oRECIBODIVDOCR:cBrwCod  :="RECIBODIVDOCR"
   oRECIBODIVDOCR:lTmdi    :=.T.
   oRECIBODIVDOCR:aHead    :={}
   oRECIBODIVDOCR:lBarDef  :=.T. // Activar Modo Diseño.

   // Guarda los parámetros del Browse cuando cierra la ventana
   oRECIBODIVDOCR:bValid   :={|| EJECUTAR("BRWSAVEPAR",oRECIBODIVDOCR)}

   oRECIBODIVDOCR:lBtnRun     :=.F.
   oRECIBODIVDOCR:lBtnMenuBrw :=.F.
   oRECIBODIVDOCR:lBtnSave    :=.F.
   oRECIBODIVDOCR:lBtnCrystal :=.F.
   oRECIBODIVDOCR:lBtnRefresh :=.F.
   oRECIBODIVDOCR:lBtnHtml    :=.T.
   oRECIBODIVDOCR:lBtnExcel   :=.T.
   oRECIBODIVDOCR:lBtnPreview :=.T.
   oRECIBODIVDOCR:lBtnQuery   :=.F.
   oRECIBODIVDOCR:lBtnOptions :=.T.
   oRECIBODIVDOCR:lBtnPageDown:=.T.
   oRECIBODIVDOCR:lBtnPageUp  :=.T.
   oRECIBODIVDOCR:lBtnFilters :=.T.
   oRECIBODIVDOCR:lBtnFind    :=.T.
   oRECIBODIVDOCR:lBtnColor   :=.T.

   oRECIBODIVDOCR:nClrPane1:=16775408
   oRECIBODIVDOCR:nClrPane2:=16771797

   oRECIBODIVDOCR:nClrText :=0
   oRECIBODIVDOCR:nClrText1:=0
   oRECIBODIVDOCR:nClrText2:=0
   oRECIBODIVDOCR:nClrText3:=0




   oRECIBODIVDOCR:oBrw:=TXBrowse():New( IF(oRECIBODIVDOCR:lTmdi,oRECIBODIVDOCR:oWnd,oRECIBODIVDOCR:oDlg ))
   oRECIBODIVDOCR:oBrw:SetArray( aData, .F. )
   oRECIBODIVDOCR:oBrw:SetFont(oFont)

   oRECIBODIVDOCR:oBrw:lFooter     := .T.
   oRECIBODIVDOCR:oBrw:lHScroll    := .T.
   oRECIBODIVDOCR:oBrw:nHeaderLines:= 2
   oRECIBODIVDOCR:oBrw:nDataLines  := 1
   oRECIBODIVDOCR:oBrw:nFooterLines:= 1




   oRECIBODIVDOCR:aData            :=ACLONE(aData)

   AEVAL(oRECIBODIVDOCR:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   

  // Campo: DOC_TIPDOC
  oCol:=oRECIBODIVDOCR:oBrw:aCols[1]
  oCol:cHeader      :='Tipo'+CRLF+'Doc.'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 32
  oCol:bClrStd     := {|nClrText,uValue|uValue:=oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,1],;
                     nClrText:=COLOR_OPTIONS("DPDOCPRO            ","DOC_TIPDOC",uValue),;
                     {nClrText,iif( oRECIBODIVDOCR:oBrw:nArrayAt%2=0, oRECIBODIVDOCR:nClrPane1, oRECIBODIVDOCR:nClrPane2 ) } } 

  // Campo: TDC_DESCRI
  oCol:=oRECIBODIVDOCR:oBrw:aCols[2]
  oCol:cHeader      :='Descripción Documento'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 72
  oCol:bClrStd      := {|nClrText,uValue|uValue:=oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,2],;
                     nClrText:=COLOR_OPTIONS("DPTIPDOCPRO         ","TDC_DESCRI",uValue),;
                     {nClrText,iif( oRECIBODIVDOCR:oBrw:nArrayAt%2=0, oRECIBODIVDOCR:nClrPane1, oRECIBODIVDOCR:nClrPane2 ) } } 

  // Campo: DOC_NUMERO
  oCol:=oRECIBODIVDOCR:oBrw:aCols[3]
  oCol:cHeader      :='Número'+CRLF+'Doc.'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  // Campo: DOC_SERFIS
  oCol:=oRECIBODIVDOCR:oBrw:aCols[4]
  oCol:cHeader      :='Serie'+CRLF+'Fiscal'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 20

  // Campo: DOC_NUMFIS
  oCol:=oRECIBODIVDOCR:oBrw:aCols[5]
  oCol:cHeader      :='Número'+CRLF+'Fiscal'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  // Campo: DOC_GIRNUM
  oCol:=oRECIBODIVDOCR:oBrw:aCols[6]
  oCol:cHeader      :='Código'+CRLF+'Motivo'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 64

  // Campo: MDC_DESCRI
  oCol:=oRECIBODIVDOCR:oBrw:aCols[7]
  oCol:cHeader      :='Descripción'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 260

  // Campo: DOC_BASNET
  oCol:=oRECIBODIVDOCR:oBrw:aCols[8]
  oCol:cHeader      :='Monto'+CRLF+'Neto'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,8],;
                              oCol  := oRECIBODIVDOCR:oBrw:aCols[8],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[8],oCol:cEditPicture)


  // Campo: DOC_MTOIVA
  oCol:=oRECIBODIVDOCR:oBrw:aCols[9]
  oCol:cHeader      :='Monto'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,9],;
                              oCol  := oRECIBODIVDOCR:oBrw:aCols[9],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[9],oCol:cEditPicture)


  // Campo: DOC_NETO
  oCol:=oRECIBODIVDOCR:oBrw:aCols[10]
  oCol:cHeader      :='Monto'+CRLF+'Neto'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,10],;
                              oCol  := oRECIBODIVDOCR:oBrw:aCols[10],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[10],oCol:cEditPicture)


  // Campo: DOC_IMPRES
  oCol:=oRECIBODIVDOCR:oBrw:aCols[11]
  oCol:cHeader      :='Impreso'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 50
  // Campo: DOC_IMPRES
 oCol:AddBmpFile("BITMAPS\checkverde.bmp") 
 oCol:AddBmpFile("BITMAPS\checkrojo.bmp") 
 oCol:bBmpData    := { |oBrw|oBrw:=oRECIBODIVDOCR:oBrw,IIF(oBrw:aArrayData[oBrw:nArrayAt,11],1,2) }
 oCol:nDataStyle  := oCol:DefStyle( AL_RIGHT, .F.) 
 oCol:bStrData    :={||""}
 oCol:bLDClickData:={||oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,11]:=!oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,11],oRECIBODIVDOCR:oBrw:DrawLine(.T.)} 
 oCol:bStrData    :={||""}
 oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 

// oCol:bLClickHeader:={||oDp:lSel:=!oRECIBODIVDOCR:oBrw:aArrayData[1,9],; 
// AEVAL(oRECIBODIVDOCR:oBrw:aArrayData,{|a,n| oRECIBODIVDOCR:oBrw:aArrayData[n,11]:=oDp:lSel}),oRECIBODIVDOCR:oBrw:Refresh(.T.)} 

// Campo: DOC_RECNUM
  oCol:=oRECIBODIVDOCR:oBrw:aCols[12]
  oCol:cHeader      :='Recibo'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 60


  oCol:=oRECIBODIVDOCR:oBrw:aCols[13]
  oCol:cHeader      :='Fecha'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 60

  oCol:=oRECIBODIVDOCR:oBrw:aCols[14]
  oCol:cHeader      :='Factura'+CRLF+"Afectada"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRECIBODIVDOCR:oBrw:aArrayData ) } 
  oCol:nWidth       := 60





   oRECIBODIVDOCR:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))

   oRECIBODIVDOCR:oBrw:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oRECIBODIVDOCR:oBrw,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                                                 nClrText:=oRECIBODIVDOCR:nClrText,;
                                                 nClrText:=IF(.F.,oRECIBODIVDOCR:nClrText1,nClrText),;
                                                 nClrText:=IF(.F.,oRECIBODIVDOCR:nClrText2,nClrText),;
                                                 {nClrText,iif( oBrw:nArrayAt%2=0, oRECIBODIVDOCR:nClrPane1, oRECIBODIVDOCR:nClrPane2 ) } }

//   oRECIBODIVDOCR:oBrw:bClrHeader            := {|| {0,14671839 }}
//   oRECIBODIVDOCR:oBrw:bClrFooter            := {|| {0,14671839 }}

   oRECIBODIVDOCR:oBrw:bClrHeader          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oRECIBODIVDOCR:oBrw:bClrFooter          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oRECIBODIVDOCR:oBrw:bLDblClick:={|oBrw|oRECIBODIVDOCR:RUNCLICK() }

   oRECIBODIVDOCR:oBrw:bChange:={||oRECIBODIVDOCR:BRWCHANGE()}
   oRECIBODIVDOCR:oBrw:CreateFromCode()


   oRECIBODIVDOCR:oWnd:oClient := oRECIBODIVDOCR:oBrw



   oRECIBODIVDOCR:Activate({||oRECIBODIVDOCR:ViewDatBar()})

   oRECIBODIVDOCR:BRWRESTOREPAR()

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
  LOCAL oCursor,oBar,oBtn,oFont,oCol
  LOCAL oDlg:=IF(oRECIBODIVDOCR:lTmdi,oRECIBODIVDOCR:oWnd,oRECIBODIVDOCR:oDlg)
  LOCAL nLin:=2,nCol:=0
  LOCAL nWidth:=oRECIBODIVDOCR:oBrw:nWidth()

  oRECIBODIVDOCR:oBrw:GoBottom(.T.)
  oRECIBODIVDOCR:oBrw:Refresh(.T.)

//  IF !File("FORMS\BRRECIBODIVDOCR.EDT")
//    oRECIBODIVDOCR:oBrw:Move(44,0,1724+50,460)
//  ENDIF

  DEFINE CURSOR oCursor HAND

  IF !oDp:lBtnText 
     DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   ELSE 
     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth,oDp:nBarnHeight+6+20 OF oDlg 3D CURSOR oCursor 
   ENDIF 

  DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -10 BOLD

 // Emanager no Incluye consulta de Vinculos

  oRECIBODIVDOCR:oFontBtn   :=oFont    
   oRECIBODIVDOCR:nClrPaneBar:=oDp:nGris
   oRECIBODIVDOCR:oBrw:oLbx  :=oRECIBODIVDOCR

 DEFINE BUTTON oBtn;
         OF oBar;
         NOBORDER;
         FONT oFont;
         TOP PROMPT "Formulario"; 
         FILENAME "BITMAPS\FORM.BMP";
         ACTION oRECIBODIVDOCR:VERDOCCLI()

  oBtn:cToolTip:="Formulario del Documento"


  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XEDIT.BMP",NIL,"BITMAPS\XEDITG.BMP";
          TOP PROMPT "Editar"; 
          ACTION  oRECIBODIVDOCR:DOCCLIMOD();
          WHEN ISTABMOD("DPDOCCLI") 

   oBtn:cToolTip:="Modificar Números y Fechas"




  DEFINE BUTTON oBtn;
         OF oBar;
         NOBORDER;
         FONT oFont;
         FILENAME "BITMAPS\VIEW.BMP";
         TOP PROMPT "Consulta"; 
         ACTION  oRECIBODIVDOCR:VERMENUCON()

  oBtn:cToolTip:="Consultar Documento"

  DEFINE BUTTON oBtn;
         OF oBar;
         NOBORDER;
         FONT oFont;
         FILENAME "BITMAPS\XPRINT.BMP";
           TOP PROMPT "Imprimir"; 
              ACTION  oRECIBODIVDOCR:IMPRIMIR()

  oBtn:cToolTip:="Imprimir Documento"


/*
   IF Empty(oRECIBODIVDOCR:cServer) .AND. !Empty(SQLGET("DPBRWLNK","EBR_CODIGO","EBR_CODIGO"+GetWhere("=","RECIBODIVDOCR")))
*/

   IF ISSQLFIND("DPBRWLNKCONCAT","BRC_CODIGO"+GetWhere("=","RECIBODIVDOCR"))

       DEFINE BUTTON oBtn;
       OF oBar;
       NOBORDER;
       FONT oFont;
       FILENAME "BITMAPS\XBROWSE.BMP";
         TOP PROMPT "Detalles"; 
              ACTION  EJECUTAR("BRWRUNBRWLINK",oRECIBODIVDOCR:oBrw,"RECIBODIVDOCR",oRECIBODIVDOCR:cSql,oRECIBODIVDOCR:nPeriodo,oRECIBODIVDOCR:dDesde,oRECIBODIVDOCR:dHasta,oRECIBODIVDOCR)

       oBtn:cToolTip:="Ejecutar Browse Vinculado(s)"
       oRECIBODIVDOCR:oBtnRun:=oBtn



       oRECIBODIVDOCR:oBrw:bLDblClick:={||EVAL(oRECIBODIVDOCR:oBtnRun:bAction) }


   ENDIF




IF oRECIBODIVDOCR:lBtnRun

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            MENU EJECUTAR("BRBTNMENU",{"Opcion 1",;
                                       "Opcion 2",;
                                       "Opcion 3"},;
                                       "oRECIBODIVDOCR");
            FILENAME "BITMAPS\RUN.BMP";
            ACTION oRECIBODIVDOCR:BTNRUN()

      oBtn:cToolTip:="Opciones de Ejecucion"

ENDIF

IF oRECIBODIVDOCR:lBtnColor

     oRECIBODIVDOCR:oBtnColor:=NIL

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            TOP PROMPT "Colores"; 
            FILENAME "BITMAPS\COLORS.BMP";
            MENU EJECUTAR("BRBTNMENUCOLOR",oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR,oRECIBODIVDOCR:oBtnColor,{||EJECUTAR("BRWCAMPOSOPC",oRECIBODIVDOCR,.T.)});
            ACTION EJECUTAR("BRWSELCOLORFIELD",oRECIBODIVDOCR,.T.)

    oBtn:cToolTip:="Personalizar Colores en los Campos"

    oRECIBODIVDOCR:oBtnColor:=oBtn

ENDIF



IF oRECIBODIVDOCR:lBtnSave
/*
      DEFINE BITMAP OF OUTLOOK oBRWMENURUN:oOut ;
             BITMAP "BITMAPS\XSAVE.BMP";
             PROMPT "Guardar Consulta";
               TOP PROMPT "Grabar"; 
              ACTION  EJECUTAR("DPBRWSAVE",oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR:oFrm)
*/
ENDIF

IF oRECIBODIVDOCR:lBtnMenuBrw

 DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\BRWMENU.BMP",NIL,"BITMAPS\BRWMENUG.BMP";
            TOP PROMPT "Menú"; 
              ACTION  (EJECUTAR("BRWBUILDHEAD",oRECIBODIVDOCR),;
                  EJECUTAR("DPBRWMENURUN",oRECIBODIVDOCR,oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR:cBrwCod,oRECIBODIVDOCR:cTitle,oRECIBODIVDOCR:aHead));
          WHEN !Empty(oRECIBODIVDOCR:oBrw:aArrayData[1,1])

   oBtn:cToolTip:="Menú de Opciones"

ENDIF


IF oRECIBODIVDOCR:lBtnFind

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
            TOP PROMPT "Buscar"; 
              ACTION  EJECUTAR("BRWSETFIND",oRECIBODIVDOCR:oBrw)

   oBtn:cToolTip:="Buscar"
ENDIF

IF oRECIBODIVDOCR:lBtnFilters

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          MENU EJECUTAR("BRBTNMENUFILTER",oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR);
            TOP PROMPT "Filtrar"; 
              ACTION  EJECUTAR("BRWSETFILTER",oRECIBODIVDOCR:oBrw)

   oBtn:cToolTip:="Filtrar Registros"
ENDIF

IF oRECIBODIVDOCR:lBtnOptions

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
            TOP PROMPT "Opciones"; 
              ACTION  EJECUTAR("BRWSETOPTIONS",oRECIBODIVDOCR:oBrw);
          WHEN LEN(oRECIBODIVDOCR:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

ENDIF

IF oRECIBODIVDOCR:lBtnRefresh

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\REFRESH.BMP";
            TOP PROMPT "Refrescar"; 
              ACTION  oRECIBODIVDOCR:BRWREFRESCAR()

   oBtn:cToolTip:="Refrescar"

ENDIF

IF oRECIBODIVDOCR:lBtnCrystal

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.BMP";
            TOP PROMPT "Crystal"; 
              ACTION  EJECUTAR("BRWTODBF",oRECIBODIVDOCR)

   oBtn:cToolTip:="Visualizar Mediante Crystal Report"

ENDIF

IF oRECIBODIVDOCR:lBtnExcel


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
              TOP PROMPT "Excel"; 
              ACTION  (EJECUTAR("BRWTOEXCEL",oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR:cTitle,oRECIBODIVDOCR:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oRECIBODIVDOCR:oBtnXls:=oBtn

ENDIF

IF oRECIBODIVDOCR:lBtnHtml

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
            TOP PROMPT "Html"; 
              ACTION  (oRECIBODIVDOCR:HTMLHEAD(),EJECUTAR("BRWTOHTML",oRECIBODIVDOCR:oBrw,NIL,oRECIBODIVDOCR:cTitle,oRECIBODIVDOCR:aHead))

   oBtn:cToolTip:="Generar Archivo html"

   oRECIBODIVDOCR:oBtnHtml:=oBtn

ENDIF


IF oRECIBODIVDOCR:lBtnPreview

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
            TOP PROMPT "Preview"; 
              ACTION  (EJECUTAR("BRWPREVIEW",oRECIBODIVDOCR:oBrw))

   oBtn:cToolTip:="Previsualización"

   oRECIBODIVDOCR:oBtnPreview:=oBtn

ENDIF

   IF ISSQLGET("DPREPORTES","REP_CODIGO","BRRECIBODIVDOCR")

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XPRINT.BMP";
            ACTION oRECIBODIVDOCR:IMPRIMIR()

      oBtn:cToolTip:="Imprimir"

     oRECIBODIVDOCR:oBtnPrint:=oBtn

   ENDIF

IF oRECIBODIVDOCR:lBtnQuery


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oRECIBODIVDOCR:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF




   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
            TOP PROMPT "Primero"; 
              ACTION  (oRECIBODIVDOCR:oBrw:GoTop(),oRECIBODIVDOCR:oBrw:Setfocus())

IF nWidth>800 .OR. nWidth=0

   IF oRECIBODIVDOCR:lBtnPageDown

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\xSIG.BMP";
              TOP PROMPT "Avance"; 
              ACTION  (oRECIBODIVDOCR:oBrw:PageDown(),oRECIBODIVDOCR:oBrw:Setfocus())
  ENDIF

  IF  oRECIBODIVDOCR:lBtnPageUp

    DEFINE BUTTON oBtn;
           OF oBar;
           NOBORDER;
           FONT oFont;
           FILENAME "BITMAPS\xANT.BMP";
             TOP PROMPT "Anterior"; 
              ACTION  (oRECIBODIVDOCR:oBrw:PageUp(),oRECIBODIVDOCR:oBrw:Setfocus())
  ENDIF

ENDIF

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
            TOP PROMPT "Ultimo"; 
              ACTION  (oRECIBODIVDOCR:oBrw:GoBottom(),oRECIBODIVDOCR:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
            TOP PROMPT "Cerrar"; 
              ACTION  oRECIBODIVDOCR:Close()

  oRECIBODIVDOCR:oBrw:SetColor(0,oRECIBODIVDOCR:nClrPane1)

  oRECIBODIVDOCR:SETBTNBAR(40+20,40+20,oBar)


  EVAL(oRECIBODIVDOCR:oBrw:bChange)

  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oRECIBODIVDOCR:oBar:=oBar

  oBar:SetSize(NIL,75+22+20,.T.)

  DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 BOLD

  @ 46+20,085     SAY " "+oRECIBODIVDOCR:cCodCli  OF oBar SIZE 090,20 BORDER PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont
  @ 46+20,115+065 SAY " "+oRECIBODIVDOCR:cNombre  OF oBar SIZE 300,20 BORDER PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont

  @ 46+20,015 SAY " Código "                      OF oBar SIZE 068,20 BORDER PIXEL COLOR oDp:nClrLabelText ,oDp:nClrLabelPane FONT oFont RIGHT
  @ 68+20,015 SAY " Recibo "                      OF oBar SIZE 068,20 BORDER PIXEL COLOR oDp:nClrLabelText ,oDp:nClrLabelPane FONT oFont RIGHT

  @ 68+20,085 SAY " "+oRECIBODIVDOCR:cRecibo  OF oBar SIZE 090,20 BORDER PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow    FONT oFont

RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()


RETURN .T.


/*
// Imprimir
*/
FUNCTION IMPRIMIR()
  LOCAL aLine  :=oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt]
  LOCAL cNumero:=aLine[03]
  LOCAL cTipDoc:=ALLTRIM(aLine[01])
  LOCAL oRep   :=REPORTE(IF("IGT"$cTipDoc3,"DOCCXCIGTF","DOCCXC"))
  LOCAL cWhere :="DOC_CODSUC"+GetWhere("=",oRECIBODIVDOCR:cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_NUMERO"+GetWhere("=",cNumero)+" AND DOC_TIPTRA"+GetWhere("=","D")
  LOCAL bBlq   :=[SQLUPDATE("DPDOCCLI","DOC_IMPRES",.T.,"]+cWhere+[")]


  oRep:SetRango(1,cNumero,cNumero)
  oRep:SetRango(2,oRECIBODIVDOCR:cCodCli,oRECIBODIVDOCR:cCodCli)
  oRep:SetCriterio(2,cTipDoc)

  oRep:aCargo:=cTipDoc
  oDp:oGenRep:aCargo:=cTipDoc

  oDp:oGenRep:bPostRun:=BLOQUECOD(bBlq)

RETURN .T.

FUNCTION LEEFECHAS()
  LOCAL nPeriodo:=oRECIBODIVDOCR:oPeriodo:nAt,cWhere

  oRECIBODIVDOCR:nPeriodo:=nPeriodo


  IF oRECIBODIVDOCR:oPeriodo:nAt=LEN(oRECIBODIVDOCR:oPeriodo:aItems)

     oRECIBODIVDOCR:oDesde:ForWhen(.T.)
     oRECIBODIVDOCR:oHasta:ForWhen(.T.)
     oRECIBODIVDOCR:oBtn  :ForWhen(.T.)

     DPFOCUS(oRECIBODIVDOCR:oDesde)

  ELSE

     oRECIBODIVDOCR:aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)

     oRECIBODIVDOCR:oDesde:VarPut(oRECIBODIVDOCR:aFechas[1] , .T. )
     oRECIBODIVDOCR:oHasta:VarPut(oRECIBODIVDOCR:aFechas[2] , .T. )

     oRECIBODIVDOCR:dDesde:=oRECIBODIVDOCR:aFechas[1]
     oRECIBODIVDOCR:dHasta:=oRECIBODIVDOCR:aFechas[2]

     cWhere:=oRECIBODIVDOCR:HACERWHERE(oRECIBODIVDOCR:dDesde,oRECIBODIVDOCR:dHasta,oRECIBODIVDOCR:cWhere,.T.)

     oRECIBODIVDOCR:LEERDATA(cWhere,oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR:cServer,oRECIBODIVDOCR)

  ENDIF

  oRECIBODIVDOCR:SAVEPERIODO()

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

     IF !Empty(oRECIBODIVDOCR:cWhereQry)
       cWhere:=cWhere + oRECIBODIVDOCR:cWhereQry
     ENDIF

     oRECIBODIVDOCR:LEERDATA(cWhere,oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR:cServer,oRECIBODIVDOCR)

   ENDIF


RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer,oRECIBODIVDOCR)
   LOCAL aData:={},aTotal:={},oCol,cSql,aLines:={}
   LOCAL oDb
   LOCAL nAt,nRowSel

   DEFAULT cWhere:=""

   IF !Empty(cServer)

     IF !EJECUTAR("DPSERVERDBOPEN",cServer)
        RETURN .F.
     ENDIF

     oDb:=oDp:oDb

   ENDIF

   cWhere:=IIF(Empty(cWhere),"",ALLTRIM(cWhere))

   IF !Empty(cWhere) .AND. LEFT(cWhere,5)="WHERE"
      cWhere:=SUBS(cWhere,6,LEN(cWhere))
   ENDIF

   cSql:=" SELECT  "+;
          "  DOC_TIPDOC, "+;
          "  TDC_DESCRI, "+;
          "  DOC_NUMERO, "+;
          "  DOC_SERFIS, "+;
          "  DOC_NUMFIS, "+;
          "  DOC_GIRNUM, "+;
          "  MDC_DESCRI, "+;
          "  DOC_BASNET, "+;
          "  DOC_MTOIVA, "+;
          "  DOC_NETO, "+;
          "  DOC_IMPRES,DOC_RECNUM,DOC_FECHA,DOC_FACAFE  "+;
          "  FROM DPDOCCLI  "+;
          "  LEFT JOIN DPTIPDOCCLIMOT ON DOC_GIRNUM=MDC_CODIGO	     "+;
          "  LEFT JOIN DPTIPDOCCLI    ON DOC_TIPDOC=TDC_TIPO "+;
          "  WHERE DOC_DOCORG"+GetWhere("=","R")+" AND DOC_TIPTRA"+GetWhere("=","D")+;
          " "

/*
   IF Empty(cWhere)
     cSql:=STRTRAN(cSql,"<WHERE>","")
   ELSE
     cSql:=STRTRAN(cSql,"<WHERE>"," WHERE "+cWhere)
   ENDIF
*/
   IF !Empty(cWhere)
      cSql:=EJECUTAR("SQLINSERTWHERE",cSql,cWhere)
   ENDIF

   cSql:=EJECUTAR("WHERE_VAR",cSql)


   oDp:lExcluye:=.T.

   DPWRITE("TEMP\BRRECIBODIVDOCR.SQL",cSql)


   aData:=ASQL(cSql,oDb)

// ? CLPCOPY(oDp:cSql)

   oDp:cWhere:=cWhere


   IF EMPTY(aData)
      aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
//    AADD(aData,{'','','','','','','',0,0,0,0})
   ENDIF

        AEVAL(aData,{|a,n|aData[n,1]:=SAYOPTIONS("DPDOCPRO","DOC_TIPDOC",a[1]),;
          aData[n,2]:=SAYOPTIONS("DPTIPDOCPRO","TDC_DESCRI",a[2])})

   IF ValType(oBrw)="O"

      oRECIBODIVDOCR:cSql   :=cSql
      oRECIBODIVDOCR:cWhere_:=cWhere

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
      AEVAL(oRECIBODIVDOCR:oBar:aControls,{|o,n| o:ForWhen(.T.)})

      oRECIBODIVDOCR:SAVEPERIODO()

   ENDIF

RETURN aData


FUNCTION SAVEPERIODO()
  LOCAL cFileMem:="USER\BRRECIBODIVDOCR.MEM",V_nPeriodo:=oRECIBODIVDOCR:nPeriodo
  LOCAL V_dDesde:=oRECIBODIVDOCR:dDesde
  LOCAL V_dHasta:=oRECIBODIVDOCR:dHasta

  SAVE TO (cFileMem) ALL LIKE "V_*"

RETURN .T.

/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oRECIBODIVDOCR)
RETURN .T.

/*
// Ejecución Cambio de Linea
*/
FUNCTION BRWCHANGE()

  AEVAL(oRECIBODIVDOCR:oBrw:aCols,{|o,n|o:nEditType:=0})
  oRECIBODIVDOCR:oBrw:CancelEdit()

RETURN NIL

/*
// Refrescar Browse
*/
FUNCTION BRWREFRESCAR()
    LOCAL cWhere


    IF Type("oRECIBODIVDOCR")="O" .AND. oRECIBODIVDOCR:oWnd:hWnd>0

      cWhere:=" "+IIF(!Empty(oRECIBODIVDOCR:cWhere_),oRECIBODIVDOCR:cWhere_,oRECIBODIVDOCR:cWhere)
      cWhere:=STRTRAN(cWhere," WHERE ","")

      oRECIBODIVDOCR:LEERDATA(oRECIBODIVDOCR:cWhere_,oRECIBODIVDOCR:oBrw,oRECIBODIVDOCR:cServer)
      oRECIBODIVDOCR:oWnd:Show()
      oRECIBODIVDOCR:oWnd:Restore()

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

   oRECIBODIVDOCR:aHead:=EJECUTAR("HTMLHEAD",oRECIBODIVDOCR)

// Ejemplo para Agregar mas Parámetros
//   AADD(oDOCPROISLR:aHead,{"Consulta",oDOCPROISLR:oWnd:cTitle})

RETURN

// Restaurar Parametros
FUNCTION BRWRESTOREPAR()
  EJECUTAR("BRWRESTOREPAR",oRECIBODIVDOCR)
RETURN .T.

FUNCTION VERDOCCLI()
   LOCAL aLine  :=oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt]
   LOCAL cNumero:=aLine[03]
   LOCAL cTipDoc:=aLine[01]
   LOCAL cCodigo:=oRECIBODIVDOCR:cCodCli
   LOCAL cTipTra:="D"

RETURN EJECUTAR("VERDOCCLI",oRECIBODIVDOCR:cCodSuc,cTipDoc,cCodigo,cNumero,cTipTra,"R")

FUNCTION VERMENUCON()
   LOCAL aLine  :=oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt]
   LOCAL cNumero:=aLine[03]
   LOCAL cTipDoc:=aLine[01]

RETURN EJECUTAR("DPDOCCLIFAVCON",NIL,oRECIBODIVDOCR:cCodSuc,cTipDoc,cNumero,oRECIBODIVDOCR:cCodCli)


FUNCTION DOCCLIMOD()
  LOCAL oCol

  oRECIBODIVDOCR:oBrw:nColSel:=5

  oCol:=oRECIBODIVDOCR:oBrw:aCols[5]
  oCol:nEditType    :=1
  oCol:bOnPostEdit  := {|oCol,uValue|oRECIBODIVDOCR:SAVENUMFIS(uValue)}

  oRECIBODIVDOCR:oBrw:DrawLine(.T.)
  oRECIBODIVDOCR:oBrw:aCols[oRECIBODIVDOCR:oBrw:nColSel]:Edit()

RETURN .T.

FUNCTION DOCCLIWHRE()
   LOCAL aLine:=oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt]
   LOCAL cWhere
  
   cWhere:="DOC_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",aLine[1]     )+" AND "+;
           "DOC_NUMERO"+GetWhere("=",aLine[3])

RETURN cWhere


FUNCTION SAVENUMFIS(cNumero)
   LOCAL cWhere :=oRECIBODIVDOCR:DOCCLIWHRE()
   LOCAL aLine  :=oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt]
   LOCAL cNumOld:=aLine[3]

   LOCAL cWhereD:="DOC_CODSUC"+GetWhere("=",oDp:cSucursal         )+" AND "+;
                  "DOC_TIPDOC"+GetWhere("=",oRECIBODIVDOCR:cTipDoc)+" AND "+;
                  "DOC_NUMFIS"+GetWhere("=",cNumero)

   oRECIBODIVDOCR:cTipDoc:=aLine[1]
 
   IF ISSQLFIND("DPDOCCLI",cWhereD)
      EJECUTAR("XSCGMSGERR",oRECIBODIVDOCR:oBrw,"Documento Fiscal"+cNumero+" está Registrado")
      RETURN .F.
   ENDIF

   oRECIBODIVDOCR:oBrw:aArrayData[oRECIBODIVDOCR:oBrw:nArrayAt,5]:=cNumero
   oRECIBODIVDOCR:oBrw:DrawLine(.T.)

   MsgRun("Actualizando")
   CursorWait()

   SQLUPDATE("DPDOCCLI","DOC_NUMFIS",cNumero,cWhere)

   CursorArrow()


RETURN .T.



// EOF

