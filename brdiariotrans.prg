// Programa   : BRDIARIOTRANS
// Fecha/Hora : 08/07/2022 01:01:23
// Propósito  : Resumen de Transacciones
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle)
   LOCAL aData,aFechas,cFileMem:="USER\BRTICKETPOS.MEM",V_nPeriodo:=1,cCodPar
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer
   LOCAL lConectar:=.F.

   oDp:cRunServer:=NIL

   IF Type("oBRDIARIO")="O" .AND. oBRDIARIO:oWnd:hWnd>0
      RETURN EJECUTAR("BRRUNNEW",oBRDIARIO,GetScript())
   ENDIF


   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
     ENDIF

   ENDIF

   cTitle:="Resumen de Transacciones" +IF(Empty(cTitle),"",cTitle)

   oDp:oFrm:=NIL

   IF FILE(cFileMem) .AND. nPeriodo=NIL
      RESTORE FROM (cFileMem) ADDI
      nPeriodo:=V_nPeriodo
   ENDIF

   DEFAULT cCodSuc :=oDp:cSucursal,;
           nPeriodo:=1,;
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

   aData :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere),NIL,cServer,NIL,cCodSuc,dDesde,dHasta)

   IF Empty(aData)
      MensajeErr("no hay "+cTitle,"Información no Encontrada")
      RETURN .F.
   ENDIF

   ViewData(aData,cTitle,oDp:cWhere)

   oDp:oFrm:=oBRDIARIO

RETURN .T.


FUNCTION ViewData(aData,cTitle,cWhere_)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

   DpMdi(cTitle,"oBRDIARIO","BRDIARIOTRANS.EDT")
   oBRDIARIO:Windows(0,0,aCoors[3]-160,MIN(526,aCoors[4]-10),.T.) // Maximizado

   oBRDIARIO:cCodSuc  :=cCodSuc
   oBRDIARIO:lMsgBar  :=.F.
   oBRDIARIO:cPeriodo :=aPeriodos[nPeriodo]
   oBRDIARIO:cCodSuc  :=cCodSuc
   oBRDIARIO:nPeriodo :=nPeriodo
   oBRDIARIO:cNombre  :=""
   oBRDIARIO:dDesde   :=dDesde
   oBRDIARIO:cServer  :=cServer
   oBRDIARIO:dHasta   :=dHasta
   oBRDIARIO:cWhere   :=cWhere
   oBRDIARIO:cWhere_  :=cWhere_
   oBRDIARIO:cWhereQry:=""
   oBRDIARIO:cSql     :=oDp:cSql
   oBRDIARIO:oWhere   :=TWHERE():New(oBRDIARIO)
   oBRDIARIO:cCodPar  :=cCodPar // Código del Parámetro
   oBRDIARIO:lWhen    :=.T.
   oBRDIARIO:cTextTit :="" // Texto del Titulo Heredado
   oBRDIARIO:oDb      :=oDp:oDb
   oBRDIARIO:cBrwCod  :=""
   oBRDIARIO:lTmdi    :=.T.
   oBRDIARIO:aHead    :={}
   oBRDIARIO:lBarDef  :=.T. // Activar Modo Diseño.

   // Guarda los parámetros del Browse cuando cierra la ventana
   oBRDIARIO:bValid   :={|| EJECUTAR("BRWSAVEPAR",oBRDIARIO)}

   oBRDIARIO:lBtnRun     :=.F.
   oBRDIARIO:lBtnMenuBrw :=.F.
   oBRDIARIO:lBtnSave    :=.F.
   oBRDIARIO:lBtnCrystal :=.F.
   oBRDIARIO:lBtnRefresh :=.T.
   oBRDIARIO:lBtnHtml    :=.T.
   oBRDIARIO:lBtnExcel   :=.T.
   oBRDIARIO:lBtnPreview :=.T.
   oBRDIARIO:lBtnQuery   :=.F.
   oBRDIARIO:lBtnOptions :=.T.
   oBRDIARIO:lBtnPageDown:=.T.
   oBRDIARIO:lBtnPageUp  :=.T.
   oBRDIARIO:lBtnFilters :=.T.
   oBRDIARIO:lBtnFind    :=.T.

   oBRDIARIO:nClrPane1:=16775408
   oBRDIARIO:nClrPane2:=16771797

   oBRDIARIO:nClrText :=12870144
   oBRDIARIO:nClrText1:=255
   oBRDIARIO:nClrText2:=0
   oBRDIARIO:nClrText3:=1863424

   oBRDIARIO:oBrw:=TXBrowse():New( IF(oBRDIARIO:lTmdi,oBRDIARIO:oWnd,oBRDIARIO:oDlg ))
   oBRDIARIO:oBrw:SetArray( aData, .F. )
   oBRDIARIO:oBrw:SetFont(oFont)

   oBRDIARIO:oBrw:lFooter     := .T.
   oBRDIARIO:oBrw:lHScroll    := .T.
   oBRDIARIO:oBrw:nHeaderLines:= 2
   oBRDIARIO:oBrw:nDataLines  := 1
   oBRDIARIO:oBrw:nFooterLines:= 1

   oBRDIARIO:aData            :=ACLONE(aData)

   AEVAL(oBRDIARIO:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   
 // Campo: DOC_TIPDOC
  oCol:=oBRDIARIO:oBrw:aCols[1]
  oCol:cHeader      :='Tipo'+CRLF+"Trans."
//oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBRDIARIO:oBrw:aArrayData ) } 
  oCol:nWidth       := 50

  // Campo: DOC_NUMERO
  oCol:=oBRDIARIO:oBrw:aCols[2]
  oCol:cHeader      :='Descripción'
//oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBRDIARIO:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  // Campo: Monto
  oCol:=oBRDIARIO:oBrw:aCols[3]
  oCol:cHeader      :="Monto"+CRLF+"Divisa"
//oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBRDIARIO:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oBRDIARIO:oBrw:aArrayData[oBRDIARIO:oBrw:nArrayAt,3],;
                              oCol   := oBRDIARIO:oBrw:aCols[3],;
                              IF(nMonto=0,"",FDP(nMonto,oCol:cEditPicture))}

// Campo: Monto
  oCol:=oBRDIARIO:oBrw:aCols[4]
  oCol:cHeader      :="Cant."+CRLF+"Trans."
//oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBRDIARIO:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oBRDIARIO:oBrw:aArrayData[oBRDIARIO:oBrw:nArrayAt,4],;
                              oCol   := oBRDIARIO:oBrw:aCols[4],;
                              IF(nMonto=0,"",FDP(nMonto,oCol:cEditPicture))}

  oCol:=oBRDIARIO:oBrw:aCols[5]
  oCol:cHeader      :="%"+CRLF+"Prop."
//oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBRDIARIO:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='999,999.999'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oBRDIARIO:oBrw:aArrayData[oBRDIARIO:oBrw:nArrayAt,5],;
                              oCol   := oBRDIARIO:oBrw:aCols[5],;
                              IF(nMonto=0,"",FDP(nMonto,oCol:cEditPicture))}



  oCol:=oBRDIARIO:oBrw:aCols[6]
  oCol:cHeader      :='Origen'
//oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oBRDIARIO:oBrw:aArrayData ) } 
  oCol:nWidth       := 80


  oBRDIARIO:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))

//  nClrText:=IF(aLine[12]<0,oBRDIARIO:nClrText1,nClrText),;


  oBRDIARIO:oBrw:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oBRDIARIO:oBrw,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                                                    nClrText:=oBRDIARIO:nClrText,;
                                                    nClrText:=IF(Empty(aLine[1]) .AND.  "TOTAL"$aLine[2],oBRDIARIO:nClrText2,nClrText),;
                                                    nClrText:=IF(Empty(aLine[1]) .AND. !"TOTAL"$aLine[2],oBRDIARIO:nClrText3,nClrText),;
                                                    nClrText:=IF(aLine[3]<0,oBRDIARIO:nClrText1,nClrText),;
                                                    {nClrText,iif( oBrw:nArrayAt%2=0, oBRDIARIO:nClrPane1, oBRDIARIO:nClrPane2 ) } }


   oBRDIARIO:oBrw:bClrHeader          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oBRDIARIO:oBrw:bClrFooter          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oBRDIARIO:oBrw:bLDblClick:={|oBrw|oBRDIARIO:RUNCLICK() }

   oBRDIARIO:oBrw:bChange:={||oBRDIARIO:BRWCHANGE()}
   oBRDIARIO:oBrw:CreateFromCode()

   oBRDIARIO:oWnd:oClient := oBRDIARIO:oBrw

   oBRDIARIO:Activate({||oBRDIARIO:ViewDatBar()})

   oBRDIARIO:BRWRESTOREPAR()

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg:=IF(oBRDIARIO:lTmdi,oBRDIARIO:oWnd,oBRDIARIO:oDlg)
   LOCAL nLin:=2,nCol:=0
   LOCAL nWidth:=oBRDIARIO:oBrw:nWidth()

   oBRDIARIO:oBrw:GoBottom(.T.)
   oBRDIARIO:oBrw:Refresh(.T.)

// IF !File("FORMS\BRTICKETPOS.EDT")
//     oBRDIARIO:oBrw:Move(44,0,526+50,460)
// ENDIF

   DEFINE CURSOR oCursor HAND
   IF !oDp:lBtnText 
     DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   ELSE 
     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth,oDp:nBarnHeight+6 OF oDlg 3D CURSOR oCursor 
   ENDIF 

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -10 BOLD


IF oBRDIARIO:lBtnRun

     oBRDIARIO:oFontBtn   :=oFont    
   oBRDIARIO:nClrPaneBar:=oDp:nGris
   oBRDIARIO:oBrw:oLbx  :=oBRDIARIO

 DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            MENU EJECUTAR("BRBTNMENU",{"Opcion 1",;
                                       "Opcion 2",;
                                       "Opcion 3"},;
                                       "oBRDIARIO");
            FILENAME "BITMAPS\RUN.BMP";
              TOP PROMPT "Ejecutar"; 
              ACTION  oBRDIARIO:BTNRUN()

      oBtn:cToolTip:="Opciones de Ejecucion"

ENDIF

/*
IF oBRDIARIO:lBtnSave

      DEFINE BITMAP OF OUTLOOK oBRWMENURUN:oOut ;
             BITMAP "BITMAPS\XSAVE.BMP";
             PROMPT "Guardar Consulta";
               TOP PROMPT "Grabar"; 
              ACTION  EJECUTAR("DPBRWSAVE",oBRDIARIO:oBrw,oBRDIARIO:oFrm)
ENDIF
*/
IF oBRDIARIO:lBtnMenuBrw

 DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\BRWMENU.BMP",NIL,"BITMAPS\BRWMENUG.BMP";
            TOP PROMPT "Menú"; 
              ACTION  (EJECUTAR("BRWBUILDHEAD",oBRDIARIO),;
                  EJECUTAR("DPBRWMENURUN",oBRDIARIO,oBRDIARIO:oBrw,oBRDIARIO:cBrwCod,oBRDIARIO:cTitle,oBRDIARIO:aHead));
          WHEN !Empty(oBRDIARIO:oBrw:aArrayData[1,1])

   oBtn:cToolTip:="Menú de Opciones"

ENDIF


IF oBRDIARIO:lBtnFind

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
            TOP PROMPT "Buscar"; 
              ACTION  EJECUTAR("BRWSETFIND",oBRDIARIO:oBrw)

   oBtn:cToolTip:="Buscar"
ENDIF

IF oBRDIARIO:lBtnFilters

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          MENU EJECUTAR("BRBTNMENUFILTER",oBRDIARIO:oBrw,oBRDIARIO);
            TOP PROMPT "Filtrar"; 
              ACTION  EJECUTAR("BRWSETFILTER",oBRDIARIO:oBrw)

   oBtn:cToolTip:="Filtrar Registros"
ENDIF

IF oBRDIARIO:lBtnOptions

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
            TOP PROMPT "Opciones"; 
              ACTION  EJECUTAR("BRWSETOPTIONS",oBRDIARIO:oBrw);
          WHEN LEN(oBRDIARIO:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

ENDIF

IF oBRDIARIO:lBtnRefresh

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\REFRESH.BMP";
            TOP PROMPT "Refrescar"; 
              ACTION  oBRDIARIO:BRWREFRESCAR()

   oBtn:cToolTip:="Refrescar"

ENDIF

IF oBRDIARIO:lBtnCrystal

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.BMP";
            TOP PROMPT "Crystal"; 
              ACTION  EJECUTAR("BRWTODBF",oBRDIARIO)

   oBtn:cToolTip:="Visualizar Mediante Crystal Report"

ENDIF

IF oBRDIARIO:lBtnExcel


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
              TOP PROMPT "Excel"; 
              ACTION  (EJECUTAR("BRWTOEXCEL",oBRDIARIO:oBrw,oBRDIARIO:cTitle,oBRDIARIO:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oBRDIARIO:oBtnXls:=oBtn

ENDIF

IF oBRDIARIO:lBtnHtml

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
            TOP PROMPT "Html"; 
              ACTION  (oBRDIARIO:HTMLHEAD(),EJECUTAR("BRWTOHTML",oBRDIARIO:oBrw,NIL,oBRDIARIO:cTitle,oBRDIARIO:aHead))

   oBtn:cToolTip:="Generar Archivo html"

   oBRDIARIO:oBtnHtml:=oBtn

ENDIF


IF oBRDIARIO:lBtnPreview

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
            TOP PROMPT "Preview"; 
              ACTION  (EJECUTAR("BRWPREVIEW",oBRDIARIO:oBrw))

   oBtn:cToolTip:="Previsualización"

   oBRDIARIO:oBtnPreview:=oBtn

ENDIF

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XPRINT.BMP";
            TOP PROMPT "Imprimir"; 
              ACTION  oBRDIARIO:IMPRIMIR()

   oBtn:cToolTip:="Imprimir ticket no Impreso"
   oBRDIARIO:oBtnPrint:=oBtn


IF oBRDIARIO:lBtnQuery


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oBRDIARIO:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF




   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
            TOP PROMPT "Primero"; 
              ACTION  (oBRDIARIO:oBrw:GoTop(),oBRDIARIO:oBrw:Setfocus())

IF nWidth>800 .OR. nWidth=0

   IF oBRDIARIO:lBtnPageDown

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\xSIG.BMP";
              TOP PROMPT "Avance"; 
              ACTION  (oBRDIARIO:oBrw:PageDown(),oBRDIARIO:oBrw:Setfocus())
  ENDIF

  IF  oBRDIARIO:lBtnPageUp

    DEFINE BUTTON oBtn;
           OF oBar;
           NOBORDER;
           FONT oFont;
           FILENAME "BITMAPS\xANT.BMP";
             TOP PROMPT "Anterior"; 
              ACTION  (oBRDIARIO:oBrw:PageUp(),oBRDIARIO:oBrw:Setfocus())
  ENDIF

ENDIF

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
            TOP PROMPT "Ultimo"; 
              ACTION  (oBRDIARIO:oBrw:GoBottom(),oBRDIARIO:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
            TOP PROMPT "Cerrar"; 
              ACTION  oBRDIARIO:Close()

  oBRDIARIO:oBrw:SetColor(0,oBRDIARIO:nClrPane1)

  oBRDIARIO:SETBTNBAR(40+10,40+10,oBar)


  EVAL(oBRDIARIO:oBrw:bChange)

  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oBRDIARIO:oBar:=oBar

  oBar:SetSize(NIL,90,.T.)

  //nLin:=<NLIN> // 08

  // Controles se Inician luego del Ultimo Boton
  nCol:=32
  AEVAL(oBar:aControls,{|o,n|nCol:=nCol+o:nWidth() })

  nCol:=32
  nLin:=45+14
  //
  // Campo : Periodo
  //

  @ nLin, nCol COMBOBOX oBRDIARIO:oPeriodo  VAR oBRDIARIO:cPeriodo ITEMS aPeriodos;
                SIZE 100,200;
                PIXEL;
                OF oBar;
                FONT oFont;
                ON CHANGE oBRDIARIO:LEEFECHAS();
                WHEN oBRDIARIO:lWhen


  ComboIni(oBRDIARIO:oPeriodo )

  @ nLin, nCol+103 BUTTON oBRDIARIO:oBtn PROMPT " < " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oBRDIARIO:oPeriodo:nAt,oBRDIARIO:oDesde,oBRDIARIO:oHasta,-1),;
                         EVAL(oBRDIARIO:oBtn:bAction));
                WHEN oBRDIARIO:lWhen


  @ nLin, nCol+130 BUTTON oBRDIARIO:oBtn PROMPT " > " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oBRDIARIO:oPeriodo:nAt,oBRDIARIO:oDesde,oBRDIARIO:oHasta,+1),;
                         EVAL(oBRDIARIO:oBtn:bAction));
                WHEN oBRDIARIO:lWhen


  @ nLin, nCol+160 BMPGET oBRDIARIO:oDesde  VAR oBRDIARIO:dDesde;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oBRDIARIO:oDesde ,oBRDIARIO:dDesde);
                SIZE 76-2,24;
                OF   oBar;
                WHEN oBRDIARIO:oPeriodo:nAt=LEN(oBRDIARIO:oPeriodo:aItems) .AND. oBRDIARIO:lWhen ;
                FONT oFont

   oBRDIARIO:oDesde:cToolTip:="F6: Calendario"

  @ nLin, nCol+252 BMPGET oBRDIARIO:oHasta  VAR oBRDIARIO:dHasta;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oBRDIARIO:oHasta,oBRDIARIO:dHasta);
                SIZE 76-2,24;
                WHEN oBRDIARIO:oPeriodo:nAt=LEN(oBRDIARIO:oPeriodo:aItems) .AND. oBRDIARIO:lWhen ;
                OF oBar;
                FONT oFont

   oBRDIARIO:oHasta:cToolTip:="F6: Calendario"

   @ nLin, nCol+345 BUTTON oBRDIARIO:oBtn PROMPT " > " SIZE 27,24;
               FONT oFont;
               OF oBar;
               PIXEL;
               WHEN oBRDIARIO:oPeriodo:nAt=LEN(oBRDIARIO:oPeriodo:aItems);
               ACTION oBRDIARIO:HACERWHERE(oBRDIARIO:dDesde,oBRDIARIO:dHasta,oBRDIARIO:cWhere,.T.);
               WHEN oBRDIARIO:lWhen

  BMPGETBTN(oBar,oFont,13)

  AEVAL(oBar:aControls,{|o|o:ForWhen(.T.)})



RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()
  LOCAL aLine:=oBRDIARIO:oBrw:aArrayData[oBRDIARIO:oBrw:nArrayAt]
  LOCAL cWhere:=NIL,cTitle,cTipDoc:=aLine[1]

  IF aLine[6]==[VTA]
     EJECUTAR("BRDPDOCCLICXC",cWhere,oBRDIARIO:cCodSuc,oBRDIARIO:nPeriodo,oBRDIARIO:dDesde,oBRDIARIO:dHasta,cTitle,cTipDoc)
  ENDIF

RETURN .T.


/*
// Imprimir
*/
FUNCTION IMPRIMIR()
   LOCAL aLine:=oBRDIARIO:oBrw:aArrayData[oBRDIARIO:oBrw:nArrayAt]
   LOCAL cCodSuc:=oBRDIARIO:cCodSuc,cTipDoc:=aLine[1],cNumero:=aLine[2],cSerFis:=aLine[10]

   IF Empty(cTipDoc)
      RETURN .F.
   ENDIF

   IF aLine[9] 
//.AND. !oDp:lImpFisModVal

      IF !MsgNoYes("Documento "+cTipDoc+"-"+cNumero+CRLF+"Documento ya está Impreso","Desea Re-Imprimirlo")
         RETURN .F.
      ENDIF

   ELSE

     IF !MsgNoYes("Desea Imprimir Documento "+cTipDoc+" "+cNumero)
        RETURN .F.
     ENDIF

   ENDIF

// ? oDp:lImpFisModVal,"oDp:lImpFisModVal"

   CursorWait()

   EJECUTAR("DPDOCCLI_PRINT",cCodSuc,cTipDoc,cNumero,cSerFis)

   // MODO VALIDACION, DISPONIBLE PARA IMPRIMIR
   IF oDp:lImpFisModVal

     SQLUPDATE("DPDOCCLI","DOC_IMPRES",.F.,"DOC_CODSUC"+GetWhere("=",cCodSuc )+" AND "+;
                                           "DOC_TIPDOC"+GetWhere("=",cTipDoc )+" AND "+;
                                           "DOC_NUMERO"+GetWhere("=",cNumero )+" AND "+;
                                           "DOC_TIPTRA"+GetWhere("=","D"     ))
   ENDIF

   oBRDIARIO:BRWREFRESCAR()

RETURN .T.

FUNCTION LEEFECHAS()
  LOCAL nPeriodo:=oBRDIARIO:oPeriodo:nAt,cWhere

  oBRDIARIO:nPeriodo:=nPeriodo


  IF oBRDIARIO:oPeriodo:nAt=LEN(oBRDIARIO:oPeriodo:aItems)

     oBRDIARIO:oDesde:ForWhen(.T.)
     oBRDIARIO:oHasta:ForWhen(.T.)
     oBRDIARIO:oBtn  :ForWhen(.T.)

     DPFOCUS(oBRDIARIO:oDesde)

  ELSE

     oBRDIARIO:aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)

     oBRDIARIO:oDesde:VarPut(oBRDIARIO:aFechas[1] , .T. )
     oBRDIARIO:oHasta:VarPut(oBRDIARIO:aFechas[2] , .T. )

     oBRDIARIO:dDesde:=oBRDIARIO:aFechas[1]
     oBRDIARIO:dHasta:=oBRDIARIO:aFechas[2]

     cWhere:=oBRDIARIO:HACERWHERE(oBRDIARIO:dDesde,oBRDIARIO:dHasta,oBRDIARIO:cWhere,.T.)

     oBRDIARIO:LEERDATA(cWhere,oBRDIARIO:oBrw,oBRDIARIO:cServer,oBRDIARIO)

  ENDIF

  oBRDIARIO:SAVEPERIODO()

RETURN .T.


FUNCTION HACERWHERE(dDesde,dHasta,cWhere_,lRun)
   LOCAL cWhere:=""

   DEFAULT lRun:=.F.

   // Campo fecha no puede estar en la nueva clausula
   IF "DPDOCCLI.DOC_FECHA"$cWhere
     RETURN ""
   ENDIF

   IF !Empty(dDesde)
       cWhere:=GetWhereAnd('DPDOCCLI.DOC_FECHA',dDesde,dHasta)
   ELSE
     IF !Empty(dHasta)
       cWhere:=GetWhereAnd('DPDOCCLI.DOC_FECHA',dDesde,dHasta)
     ENDIF
   ENDIF


   IF !Empty(cWhere_)
      cWhere:=cWhere + IIF( Empty(cWhere),""," AND ") +cWhere_
   ENDIF

   IF lRun

     IF !Empty(oBRDIARIO:cWhereQry)
       cWhere:=cWhere + oBRDIARIO:cWhereQry
     ENDIF

     oBRDIARIO:LEERDATA(cWhere,oBRDIARIO:oBrw,oBRDIARIO:cServer,oBRDIARIO)

   ENDIF


RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer,oForm,cCodSuc,dDesde,dHasta)
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

   IF ValType(oForm)="O"
      cCodSuc:=oForm:cCodSuc
      dDesde :=oForm:dDesde
      dHasta :=oForm:dHasta
   ENDIF
  
   aData:=EJECUTAR("DIARIOTRANS",cCodSuc,dDesde,dHasta)

   oDp:cWhere:=cWhere

   IF ValType(oBrw)="O"

      oBRDIARIO:cSql   :=cSql
      oBRDIARIO:cWhere_:=cWhere

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

      AEVAL(oBRDIARIO:oBar:aControls,{|o,n| o:ForWhen(.T.)})

      oBRDIARIO:SAVEPERIODO()

   ENDIF

RETURN aData


FUNCTION SAVEPERIODO()
  LOCAL cFileMem:="USER\BRTICKETPOS.MEM",V_nPeriodo:=oBRDIARIO:nPeriodo
  LOCAL V_dDesde:=oBRDIARIO:dDesde
  LOCAL V_dHasta:=oBRDIARIO:dHasta

  SAVE TO (cFileMem) ALL LIKE "V_*"

RETURN .T.

/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oBRDIARIO)
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
    LOCAL cWhere


    IF Type("oBRDIARIO")="O" .AND. oBRDIARIO:oWnd:hWnd>0

      cWhere:=" "+IIF(!Empty(oBRDIARIO:cWhere_),oBRDIARIO:cWhere_,oBRDIARIO:cWhere)
      cWhere:=STRTRAN(cWhere," WHERE ","")

      oBRDIARIO:LEERDATA(oBRDIARIO:cWhere_,oBRDIARIO:oBrw,oBRDIARIO:cServer)
      oBRDIARIO:oWnd:Show()
      oBRDIARIO:oWnd:Restore()

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

   oBRDIARIO:aHead:=EJECUTAR("HTMLHEAD",oBRDIARIO)

// Ejemplo para Agregar mas Parámetros
//   AADD(oDOCPROISLR:aHead,{"Consulta",oDOCPROISLR:oWnd:cTitle})

RETURN

// Restaurar Parametros
FUNCTION BRWRESTOREPAR()
  EJECUTAR("BRWRESTOREPAR",oBRDIARIO)
RETURN .T.
// EOF
