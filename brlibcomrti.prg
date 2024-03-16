// Programa   : BRLIBCOMRTI
// Fecha/Hora : 08/02/2017 00:15:05
// Propósito  : "Retenciones de IVA del Libro de Compras"
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia 
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle)
   LOCAL aData,aFechas,cFileMem:="USER\BRLIBCOMRTI.MEM",V_nPeriodo:=4,cCodPar
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer
   LOCAL lConectar:=.F.

   oDp:cRunServer:=NIL

   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
     ENDIF

   ENDIF 


   cTitle:="Retenciones de IVA del Libro de Compras" +IF(Empty(cTitle),"",cTitle)

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

   IF .T. .AND. (!nPeriodo=10 .AND. (Empty(dDesde) .OR. Empty(dhasta)))

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

     aData :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere),NIL,cServer)


   ELSEIF (.T.)

     aData :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere),NIL,cServer)

   ENDIF

   IF Empty(aData)
      MensajeErr("no hay "+cTitle,"Información no Encontrada")
      RETURN .F.
   ENDIF

   ViewData(aData,cTitle,oDp:cWhere)

   oDp:oFrm:=oLIBCOMRTI
            
RETURN .T. 


FUNCTION ViewData(aData,cTitle,cWhere_)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

   DpMdi(cTitle,"oLIBCOMRTI","BRLIBCOMRTI.EDT")
   oLIBCOMRTI:CreateWindow(0,0,100,550)


   oLIBCOMRTI:cCodSuc  :=cCodSuc
   oLIBCOMRTI:lMsgBar  :=.F.
   oLIBCOMRTI:cPeriodo :=aPeriodos[nPeriodo]
   oLIBCOMRTI:cCodSuc  :=cCodSuc
   oLIBCOMRTI:nPeriodo :=nPeriodo
   oLIBCOMRTI:cNombre  :=""
   oLIBCOMRTI:dDesde   :=dDesde
   oLIBCOMRTI:cServer  :=cServer
   oLIBCOMRTI:dHasta   :=dHasta
   oLIBCOMRTI:cWhere   :=cWhere
   oLIBCOMRTI:cWhere_  :=cWhere_
   oLIBCOMRTI:cWhereQry:=""
   oLIBCOMRTI:cSql     :=oDp:cSql
   oLIBCOMRTI:oWhere   :=TWHERE():New(oLIBCOMRTI)
   oLIBCOMRTI:cCodPar  :=cCodPar // Código del Parámetro
   oLIBCOMRTI:lWhen    :=.T.
   oLIBCOMRTI:cTextTit :="" // Texto del Titulo Heredado
    oLIBCOMRTI:oDb     :=oDp:oDb
   oLIBCOMRTI:cBrwCod  :="LIBCOMRTI"
   oLIBCOMRTI:lTmdi    :=.T.



   oLIBCOMRTI:oBrw:=TXBrowse():New( IF(oLIBCOMRTI:lTmdi,oLIBCOMRTI:oWnd,oLIBCOMRTI:oDlg ))
   oLIBCOMRTI:oBrw:SetArray( aData, .F. )
   oLIBCOMRTI:oBrw:SetFont(oFont)

   oLIBCOMRTI:oBrw:lFooter     := .T.
   oLIBCOMRTI:oBrw:lHScroll    := .F.
   oLIBCOMRTI:oBrw:nHeaderLines:= 2
   oLIBCOMRTI:oBrw:nDataLines  := 1
   oLIBCOMRTI:oBrw:nFooterLines:= 1




   oLIBCOMRTI:aData            :=ACLONE(aData)
  oLIBCOMRTI:nClrText :=0
  oLIBCOMRTI:nClrPane1:=16776699
  oLIBCOMRTI:nClrPane2:=16771797

   AEVAL(oLIBCOMRTI:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   

  oCol:=oLIBCOMRTI:oBrw:aCols[1]
  oCol:cHeader      :='Número'+CRLF+'Transacción'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 64

  oCol:=oLIBCOMRTI:oBrw:aCols[2]
  oCol:cHeader      :='Número'+CRLF+'Documento'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  oCol:=oLIBCOMRTI:oBrw:aCols[3]
  oCol:cHeader      :='Nombre Proveedor'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 400

  oCol:=oLIBCOMRTI:oBrw:aCols[4]
  oCol:cHeader      :='Fecha'+CRLF+'Reg/Ret.'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 70

  oCol:=oLIBCOMRTI:oBrw:aCols[5]
  oCol:cHeader      :='Fecha'+CRLF+'Reg/Decl.'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 70

  oCol:=oLIBCOMRTI:oBrw:aCols[6]
  oCol:cHeader      :='Fecha'+CRLF+'Reg/Doc.'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 70

  oCol:=oLIBCOMRTI:oBrw:aCols[7]
  oCol:cHeader      :='Fecha'+CRLF+'Dec/Doc'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 70

  oCol:=oLIBCOMRTI:oBrw:aCols[8]
  oCol:cHeader      :='Tip.'+CRLF+'Doc.'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 24

  oCol:=oLIBCOMRTI:oBrw:aCols[9]
  oCol:cHeader      :='Proveedor'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  oCol:=oLIBCOMRTI:oBrw:aCols[10]
  oCol:cHeader      :='Número'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 80

  oCol:=oLIBCOMRTI:oBrw:aCols[11]
  oCol:cHeader      :='Base'+CRLF+'Imponible'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 110
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:bStrData:={|nMonto|nMonto:= oLIBCOMRTI:oBrw:aArrayData[oLIBCOMRTI:oBrw:nArrayAt,11],FDP(nMonto,'999,999,999,999.99')}
   oCol:cFooter      :=FDP(aTotal[11],'999,999,999,999.99')


  oCol:=oLIBCOMRTI:oBrw:aCols[12]
  oCol:cHeader      :='Monto'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 100
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:bStrData:={|nMonto|nMonto:= oLIBCOMRTI:oBrw:aArrayData[oLIBCOMRTI:oBrw:nArrayAt,12],FDP(nMonto,'999,999,999,999.99')}
   oCol:cFooter      :=FDP(aTotal[12],'999,999,999,999.99')


  oCol:=oLIBCOMRTI:oBrw:aCols[13]
  oCol:cHeader      :='% Ret'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 48
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:bStrData:={|nMonto|nMonto:= oLIBCOMRTI:oBrw:aArrayData[oLIBCOMRTI:oBrw:nArrayAt,13],FDP(nMonto,'999,999,999.99')}
   oCol:cFooter      :=FDP(aTotal[13],'999,999,999.99')


  oCol:=oLIBCOMRTI:oBrw:aCols[14]
  oCol:cHeader      :='Monto'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 100
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:bStrData:={|nMonto|nMonto:= oLIBCOMRTI:oBrw:aArrayData[oLIBCOMRTI:oBrw:nArrayAt,14],FDP(nMonto,'999,999,999,999.99')}
   oCol:cFooter      :=FDP(aTotal[14],'999,999,999,999.99')


  oCol:=oLIBCOMRTI:oBrw:aCols[15]
  oCol:cHeader      :='Reg'+CRLF+'Libro'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMRTI:oBrw:aArrayData ) } 
  oCol:nWidth       := 40

   oLIBCOMRTI:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))

   oLIBCOMRTI:oBrw:bClrStd               := {|oBrw,nClrText,aData|oBrw:=oLIBCOMRTI:oBrw,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                           oLIBCOMRTI:nClrText,;
                                          {nClrText,iif( oBrw:nArrayAt%2=0, oLIBCOMRTI:nClrPane1, oLIBCOMRTI:nClrPane2 ) } }

   oLIBCOMRTI:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oLIBCOMRTI:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


   oLIBCOMRTI:oBrw:bLDblClick:={|oBrw|oLIBCOMRTI:RUNCLICK() }

   oLIBCOMRTI:oBrw:bChange:={||oLIBCOMRTI:BRWCHANGE()}
   oLIBCOMRTI:oBrw:CreateFromCode()
    oLIBCOMRTI:bValid   :={|| EJECUTAR("BRWSAVEPAR",oLIBCOMRTI)}
    oLIBCOMRTI:BRWRESTOREPAR()


   oLIBCOMRTI:oWnd:oClient := oLIBCOMRTI:oBrw


   oLIBCOMRTI:Activate({||oLIBCOMRTI:ViewDatBar()})


RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg:=IF(oLIBCOMRTI:lTmdi,oLIBCOMRTI:oWnd,oLIBCOMRTI:oDlg)
   LOCAL nLin:=0
   LOCAL nWidth:=oLIBCOMRTI:oBrw:nWidth()

   oLIBCOMRTI:oBrw:GoBottom(.T.)
   oLIBCOMRTI:oBrw:Refresh(.T.)

   IF !File("FORMS\BRLIBCOMRTI.EDT")
     oLIBCOMRTI:oBrw:Move(44,0,850+50,460)
   ENDIF

   DEFINE CURSOR oCursor HAND
   IF !oDp:lBtnText 
     DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   ELSE 
     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth,oDp:nBarnHeight+6 OF oDlg 3D CURSOR oCursor 
   ENDIF 

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -11 BOLD


 // Emanager no Incluye consulta de Vinculos


   IF .T. .AND. Empty(oLIBCOMRTI:cServer)

   oLIBCOMRTI:oFontBtn   :=oFont    
   oLIBCOMRTI:nClrPaneBar:=oDp:nGris
   oLIBCOMRTI:oBrw:oLbx  :=oLIBCOMRTI

  DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\VIEW.BMP";
            TOP PROMPT "Consulta"; 
           ACTION  EJECUTAR("BRWRUNLINK",oLIBCOMRTI:oBrw,oLIBCOMRTI:cSql)

     oBtn:cToolTip:="Consultar Vinculos"

   ENDIF



  
/*
   IF Empty(oLIBCOMRTI:cServer) .AND. !Empty(SQLGET("DPBRWLNK","EBR_CODIGO","EBR_CODIGO"+GetWhere("=","LIBCOMRTI")))
*/

   IF ISSQLFIND("DPBRWLNKCONCAT","BRC_CODIGO"+GetWhere("=","LIBCOMRTI"))

       DEFINE BUTTON oBtn;
       OF oBar;
       NOBORDER;
       FONT oFont;
       FILENAME "BITMAPS\XBROWSE.BMP";
         TOP PROMPT "Detalles"; 
              ACTION  EJECUTAR("BRWRUNBRWLINK",oLIBCOMRTI:oBrw,"LIBCOMRTI",oLIBCOMRTI:cSql,oLIBCOMRTI:nPeriodo,oLIBCOMRTI:dDesde,oLIBCOMRTI:dHasta,oLIBCOMRTI)

       oBtn:cToolTip:="Ejecutar Browse Vinculado(s)"
       oLIBCOMRTI:oBtnRun:=oBtn



       oLIBCOMRTI:oBrw:bLDblClick:={||EVAL(oLIBCOMRTI:oBtnRun:bAction) }


   ENDIF



   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
            TOP PROMPT "Buscar"; 
              ACTION  EJECUTAR("BRWSETFIND",oLIBCOMRTI:oBrw)

   oBtn:cToolTip:="Buscar"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
            TOP PROMPT "Filtrar"; 
              ACTION  EJECUTAR("BRWSETFILTER",oLIBCOMRTI:oBrw)

   oBtn:cToolTip:="Filtrar Registros"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
            TOP PROMPT "Opciones"; 
              ACTION  EJECUTAR("BRWSETOPTIONS",oLIBCOMRTI:oBrw);
          WHEN LEN(oLIBCOMRTI:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"



IF nWidth>300

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\REFRESH.BMP";
            TOP PROMPT "Refrescar"; 
              ACTION  oLIBCOMRTI:BRWREFRESCAR()

   oBtn:cToolTip:="Refrescar"

ENDIF


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.BMP";
            TOP PROMPT "Crystal"; 
              ACTION  EJECUTAR("BRWTODBF",oLIBCOMRTI)

   oBtn:cToolTip:="Visualizar Mediante Crystal Report"


IF nWidth>400

 
     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
              TOP PROMPT "Excel"; 
              ACTION  (EJECUTAR("BRWTOEXCEL",oLIBCOMRTI:oBrw,oLIBCOMRTI:cTitle,oLIBCOMRTI:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oLIBCOMRTI:oBtnXls:=oBtn

ENDIF

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          TOP PROMPT "Html"; 
          ACTION  (EJECUTAR("BRWTOHTML",oLIBCOMRTI:oBrw))

   oBtn:cToolTip:="Generar Archivo html"

   oLIBCOMRTI:oBtnHtml:=oBtn

IF nWidth>300

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
            TOP PROMPT "Preview"; 
              ACTION  (EJECUTAR("BRWPREVIEW",oLIBCOMRTI:oBrw))

   oBtn:cToolTip:="Previsualización"

   oLIBCOMRTI:oBtnPreview:=oBtn

ENDIF

   IF ISSQLGET("DPREPORTES","REP_CODIGO","BRLIBCOMRTI")

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XPRINT.BMP";
              TOP PROMPT "Imprimir"; 
              ACTION  oLIBCOMRTI:IMPRIMIR()

      oBtn:cToolTip:="Imprimir"

     oLIBCOMRTI:oBtnPrint:=oBtn

   ENDIF

IF nWidth>700


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oLIBCOMRTI:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF




   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
            TOP PROMPT "Primero"; 
              ACTION  (oLIBCOMRTI:oBrw:GoTop(),oLIBCOMRTI:oBrw:Setfocus())

IF nWidth>800 .OR. nWidth=0

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xSIG.BMP";
            TOP PROMPT "Avance"; 
              ACTION  (oLIBCOMRTI:oBrw:PageDown(),oLIBCOMRTI:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xANT.BMP";
            TOP PROMPT "Anterior"; 
              ACTION  (oLIBCOMRTI:oBrw:PageUp(),oLIBCOMRTI:oBrw:Setfocus())

ENDIF


  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
            TOP PROMPT "Ultimo"; 
              ACTION  (oLIBCOMRTI:oBrw:GoBottom(),oLIBCOMRTI:oBrw:Setfocus())



   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
            TOP PROMPT "Cerrar"; 
              ACTION  oLIBCOMRTI:Close()

  oLIBCOMRTI:oBrw:SetColor(0,oLIBCOMRTI:nClrPane1)

  EVAL(oLIBCOMRTI:oBrw:bChange)
 
  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oLIBCOMRTI:oBar:=oBar

    nLin:=490

  // Controles se Inician luego del Ultimo Boton
  nLin:=32
  AEVAL(oBar:aControls,{|o,n|nLin:=nLin+o:nWidth() })

  //
  // Campo : Periodo
  //

  @ 10, nLin COMBOBOX oLIBCOMRTI:oPeriodo  VAR oLIBCOMRTI:cPeriodo ITEMS aPeriodos;
                SIZE 100,NIL;
                PIXEL;
                OF oBar;
                FONT oFont;
                ON CHANGE oLIBCOMRTI:LEEFECHAS();
                WHEN oLIBCOMRTI:lWhen 


  ComboIni(oLIBCOMRTI:oPeriodo )

  @ 10, nLin+103 BUTTON oLIBCOMRTI:oBtn PROMPT " < " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oLIBCOMRTI:oPeriodo:nAt,oLIBCOMRTI:oDesde,oLIBCOMRTI:oHasta,-1),;
                         EVAL(oLIBCOMRTI:oBtn:bAction));
                WHEN oLIBCOMRTI:lWhen 


  @ 10, nLin+130 BUTTON oLIBCOMRTI:oBtn PROMPT " > " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oLIBCOMRTI:oPeriodo:nAt,oLIBCOMRTI:oDesde,oLIBCOMRTI:oHasta,+1),;
                         EVAL(oLIBCOMRTI:oBtn:bAction));
                WHEN oLIBCOMRTI:lWhen 


  @ 10, nLin+170 BMPGET oLIBCOMRTI:oDesde  VAR oLIBCOMRTI:dDesde;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oLIBCOMRTI:oDesde ,oLIBCOMRTI:dDesde);
                SIZE 76,24;
                OF   oBar;
                WHEN oLIBCOMRTI:oPeriodo:nAt=LEN(oLIBCOMRTI:oPeriodo:aItems) .AND. oLIBCOMRTI:lWhen ;
                FONT oFont

   oLIBCOMRTI:oDesde:cToolTip:="F6: Calendario"

  @ 10, nLin+252 BMPGET oLIBCOMRTI:oHasta  VAR oLIBCOMRTI:dHasta;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oLIBCOMRTI:oHasta,oLIBCOMRTI:dHasta);
                SIZE 80,23;
                WHEN oLIBCOMRTI:oPeriodo:nAt=LEN(oLIBCOMRTI:oPeriodo:aItems) .AND. oLIBCOMRTI:lWhen ;
                OF oBar;
                FONT oFont

   oLIBCOMRTI:oHasta:cToolTip:="F6: Calendario"

   @ 10, nLin+335 BUTTON oLIBCOMRTI:oBtn PROMPT " > " SIZE 27,24;
               FONT oFont;
               OF oBar;
               PIXEL;
               WHEN oLIBCOMRTI:oPeriodo:nAt=LEN(oLIBCOMRTI:oPeriodo:aItems);
               ACTION oLIBCOMRTI:HACERWHERE(oLIBCOMRTI:dDesde,oLIBCOMRTI:dHasta,oLIBCOMRTI:cWhere,.T.);
               WHEN oLIBCOMRTI:lWhen

  AEVAL(oBar:aControls,{|o|o:ForWhen(.T.)})




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
  LOCAL oRep,cWhere

  oRep:=REPORTE("BRLIBCOMRTI",cWhere)
  oRep:cSql  :=oLIBCOMRTI:cSql
  oRep:cTitle:=oLIBCOMRTI:cTitle

RETURN .T.

FUNCTION LEEFECHAS()
  LOCAL nPeriodo:=oLIBCOMRTI:oPeriodo:nAt,cWhere

  oLIBCOMRTI:nPeriodo:=nPeriodo


  IF oLIBCOMRTI:oPeriodo:nAt=LEN(oLIBCOMRTI:oPeriodo:aItems)

     oLIBCOMRTI:oDesde:ForWhen(.T.)
     oLIBCOMRTI:oHasta:ForWhen(.T.)
     oLIBCOMRTI:oBtn  :ForWhen(.T.)

     DPFOCUS(oLIBCOMRTI:oDesde)

  ELSE

     oLIBCOMRTI:aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)

     oLIBCOMRTI:oDesde:VarPut(oLIBCOMRTI:aFechas[1] , .T. )
     oLIBCOMRTI:oHasta:VarPut(oLIBCOMRTI:aFechas[2] , .T. )

     oLIBCOMRTI:dDesde:=oLIBCOMRTI:aFechas[1]
     oLIBCOMRTI:dHasta:=oLIBCOMRTI:aFechas[2]

     cWhere:=oLIBCOMRTI:HACERWHERE(oLIBCOMRTI:dDesde,oLIBCOMRTI:dHasta,oLIBCOMRTI:cWhere,.T.)

     oLIBCOMRTI:LEERDATA(cWhere,oLIBCOMRTI:oBrw,oLIBCOMRTI:cServer)

  ENDIF

  oLIBCOMRTI:SAVEPERIODO()

RETURN .T.


FUNCTION HACERWHERE(dDesde,dHasta,cWhere_,lRun)
   LOCAL cWhere:=""

   DEFAULT lRun:=.F.

   // Campo fecha no puede estar en la nueva clausula
   IF "DPDOCPRORTI.RTI_FCHDEC"$cWhere
     RETURN ""
   ENDIF

   IF !Empty(dDesde)
       cWhere:=GetWhereAnd('DPDOCPRORTI.RTI_FCHDEC',dDesde,dHasta)
   ELSE
     IF !Empty(dHasta)
       cWhere:=GetWhereAnd('DPDOCPRORTI.RTI_FCHDEC',dDesde,dHasta)
     ENDIF
   ENDIF


   IF !Empty(cWhere_)
      cWhere:=cWhere + IIF( Empty(cWhere),""," AND ") +cWhere_
   ENDIF

   IF lRun

     IF !Empty(oLIBCOMRTI:cWhereQry)
       cWhere:=cWhere + oLIBCOMRTI:cWhereQry
     ENDIF

     oLIBCOMRTI:LEERDATA(cWhere,oLIBCOMRTI:oBrw,oLIBCOMRTI:cServer)

   ENDIF


RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer)
   LOCAL aData:={},aTotal:={},oCol,cSql,aLines:={}
   LOCAL oDb

   DEFAULT cWhere:=""

   IF !Empty(cServer)

     IF !EJECUTAR("DPSERVERDBOPEN",cServer)
        RETURN .F.
     ENDIF

     oDb:=oDp:oDb

   ENDIF


   cSql:=" SELECT"+;
          " DPDOCPRORTI.RTI_NUMTRA,"+;
          " DPDOCPRORTI.RTI_NUMERO,"+;
          " PRO_NOMBRE,"+;
          " DPDOCPRORTI.RTI_FECHA,"+;
          " DPDOCPRORTI.RTI_FCHDEC,"+;
          " DOC_FECHA ,"+;
          " DOC_FCHDEC,"+;
          " DOC_TIPDOC,"+;
          " DOC_CODIGO,"+;
          " DOC_NUMERO,"+;
          " DOC_BASNET*DOC_CXP,"+;
          " DOC_MTOIVA*DOC_CXP,"+;
          " DPDOCPRORTI.RTI_PORCEN,"+;
          " RTI_MONTO*DOC_CXP,"+;
          " DOC_LIBCOM"+;
          "  "+;
          " FROM  DPDOCPRORTI "+;
          " INNER JOIN DPDOCPRO      ON  DPDOCPRORTI.RTI_CODSUC=DOC_CODSUC AND"+;
          "                              DPDOCPRORTI.RTI_TIPDOC=DOC_TIPDOC AND "+;
          " 								     DPDOCPRORTI.RTI_CODIGO=DOC_CODIGO AND"+;
          " 									  DPDOCPRORTI.RTI_NUMERO=DOC_NUMERO AND"+;
          " 									  DOC_TIPTRA='D' AND DOC_ACT=1"+;
          " INNER JOIN DPPROVEEDOR    ON DOC_CODIGO=PRO_CODIGO  "+;
          " INNER JOIN VIEW_DOCPRORTI ON DPDOCPRORTI.RTI_CODSUC=VIEW_DOCPRORTI.RTI_CODSUC AND"+;
          "                              DPDOCPRORTI.RTI_TIPDOC=VIEW_DOCPRORTI.RTI_TIPDOC AND                               "+;
          "                              DPDOCPRORTI.RTI_CODIGO=VIEW_DOCPRORTI.RTI_CODIGO AND"+;
          " 						  DPDOCPRORTI.RTI_NUMERO=VIEW_DOCPRORTI.RTI_NUMDOC AND "+;
          " 						   VIEW_DOCPRORTI.RTI_ACT   =1  "+;
          " WHERE "+cWhere+IIF(Empty(cWhere),""," AND ")+" VIEW_DOCPRORTI.RTI_CODSUC =&oDp:cSucursal"+;
          " "+;
          " "+;
""

   IF Empty(cWhere)
     cSql:=STRTRAN(cSql,"<WHERE>","")
   ELSE
     cSql:=STRTRAN(cSql,"<WHERE>"," WHERE "+cWhere)
   ENDIF

   cSql:=EJECUTAR("WHERE_VAR",cSql)

   oDp:lExcluye:=.F.

   aData:=ASQL(cSql,oDb)

   DPWRITE("TEMP\BRLIBCOMRTI.SQL",oDp:cSql)

   oDp:cWhere:=cWhere

   IF EMPTY(aData)
      aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
//    AADD(aData,{'','','',CTOD(""),CTOD(""),CTOD(""),CTOD(""),'','','',0,0,0,0,''})
   ENDIF

   IF ValType(oBrw)="O"

      oLIBCOMRTI:cSql   :=cSql
      oLIBCOMRTI:cWhere_:=cWhere

      aTotal:=ATOTALES(aData)

      oBrw:aArrayData:=ACLONE(aData)
      oBrw:nArrayAt  :=1
      oBrw:nRowSel   :=1

      
      oCol:=oLIBCOMRTI:oBrw:aCols[11]
         oCol:cFooter      :=FDP(aTotal[11],'999,999,999.99')
      oCol:=oLIBCOMRTI:oBrw:aCols[12]
         oCol:cFooter      :=FDP(aTotal[12],'999,999,999.99')
      oCol:=oLIBCOMRTI:oBrw:aCols[13]
         oCol:cFooter      :=FDP(aTotal[13],'999,999,999.99')
      oCol:=oLIBCOMRTI:oBrw:aCols[14]
         oCol:cFooter      :=FDP(aTotal[14],'999,999,999.99')

      oLIBCOMRTI:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))
   
      oBrw:Refresh(.T.)
      AEVAL(oLIBCOMRTI:oBar:aControls,{|o,n| o:ForWhen(.T.)})

      oLIBCOMRTI:SAVEPERIODO()

   ENDIF

RETURN aData


FUNCTION SAVEPERIODO()
  LOCAL cFileMem:="USER\BRLIBCOMRTI.MEM",V_nPeriodo:=oLIBCOMRTI:nPeriodo
  LOCAL V_dDesde:=oLIBCOMRTI:dDesde
  LOCAL V_dHasta:=oLIBCOMRTI:dHasta

  SAVE TO (cFileMem) ALL LIKE "V_*"

RETURN .T.

/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oLIBCOMRTI)
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


    IF Type("oLIBCOMRTI")="O" .AND. oLIBCOMRTI:oWnd:hWnd>0

      cWhere:=" "+IIF(!Empty("oLIBCOMRTI":cWhere_),"oLIBCOMRTI":cWhere_,"oLIBCOMRTI":cWhere)
      cWhere:=STRTRAN(cWhere," WHERE ","")


      oLIBCOMRTI:LEERDATA(oLIBCOMRTI:cWhere_,oLIBCOMRTI:oBrw,oLIBCOMRTI:cServer)
      oLIBCOMRTI:oWnd:Show()
      oLIBCOMRTI:oWnd:Maximize()

    ENDIF

RETURN NIL

/*
// Genera Correspondencia Masiva
*/




 FUNCTION BRWRESTOREPAR()
 RETURN EJECUTAR("BRWRESTOREPAR",oLIBCOMRTI)
// EOF
