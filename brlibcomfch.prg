// Programa   : BRLIBCOMFCH
// Fecha/Hora : 19/11/2022 08:14:30
// Propósito  : "Registro de Libros de Compra"
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,cCenCos,cCodCaj,lVenta)
   LOCAL aData,aFechas,cFileMem:="USER\BRLIBCOMFCH.MEM",V_nPeriodo:=1,cCodPar
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer
   LOCAL lConectar:=.F.

   oDp:cRunServer:=NIL

   IF Type("oLIBCOMFCH")="O" .AND. oLIBCOMFCH:oWnd:hWnd>0
      RETURN EJECUTAR("BRRUNNEW",oLIBCOMFCH,GetScript())
   ENDIF

   DEFAULT lVenta:=.T.

   IF COUNT("DPDOCPROPROG","PLP_FCHDEC"+GetWhere("=",CTOD("")))>0
      EJECUTAR("DPLIBCOMSETFECHA")
   ENDIF

   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
      ENDIF

   ENDIF

   EJECUTAR("CREARCALFIS")

   IF lVenta
      cTitle:="Registro de Ventas "
   ELSE
      cTitle:="Registro Compras para Proveedores Ocasionales en el Libro de Compras Editable" +IF(Empty(cTitle),"",cTitle)
   ENDIF

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

/*
   IF .T. .AND. (!nPeriodo=11 .AND. (Empty(dDesde) .OR. Empty(dhasta)))

       aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)
       dDesde :=aFechas[1]
       dHasta :=aFechas[2]

   ENDIF
*/	
   IF .T.

      IF nPeriodo=oDp:nIndicada
        dDesde :=V_dDesde
        dHasta :=V_dHasta
      ELSE

        aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo,dDesde,dDesde,dHasta)
        dDesde :=aFechas[1]
        dHasta :=aFechas[2]
      ENDIF

     aData :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere,NIL,cCodSuc,cCenCos),NIL,cServer,NIL,cCodSuc,cCenCos,cCodCaj,lVenta)

/*
     IF Empty(aData[1,1])     // .AND. YEAR(dDesde)=2024 .AND. .F.
        SysRefresh(.T.)
        aData :=LEERDATA(HACERWHERE(dDesde,dHasta,cWhere,NIL,cCodSuc,cCenCos),NIL,cServer,NIL,cCodSuc,cCenCos,cCodCaj)
     ENDIF
*/
   ENDIF

   IF Empty(aData)
      MensajeErr("no hay "+cTitle+CRLF+"Valide la Sucursal Activa"+cCodSuc,"Información no Encontrada ")
      RETURN .F.
   ENDIF

   ViewData(aData,cTitle,oDp:cWhere)

   oDp:oFrm:=oLIBCOMFCH

RETURN .T.


FUNCTION ViewData(aData,cTitle,cWhere_)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB
   LOCAL aPeriodos:=ACLONE(oDp:aPeriodos)
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD


   DpMdi(cTitle,"oLIBCOMFCH","BRLIBCOMFCH.EDT")
// oLIBCOMFCH:CreateWindow(0,0,100,550)
   oLIBCOMFCH:Windows(0,0,aCoors[3]-160,MIN(6850,aCoors[4]-10),.T.) // Maximizado

   oLIBCOMFCH:cCodSuc  :=cCodSuc
   oLIBCOMFCH:lMsgBar  :=.F.
   oLIBCOMFCH:cPeriodo :=aPeriodos[nPeriodo]
   oLIBCOMFCH:cCodSuc  :=cCodSuc
   oLIBCOMFCH:nPeriodo :=nPeriodo
   oLIBCOMFCH:cNombre  :=""
   oLIBCOMFCH:dDesde   :=dDesde
   oLIBCOMFCH:cServer  :=cServer
   oLIBCOMFCH:dHasta   :=dHasta
   oLIBCOMFCH:cWhere   :=cWhere
   oLIBCOMFCH:cWhere_  :=cWhere_
   oLIBCOMFCH:cWhereQry:=""
   oLIBCOMFCH:cSql     :=oDp:cSql
   oLIBCOMFCH:oWhere   :=TWHERE():New(oLIBCOMFCH)
   oLIBCOMFCH:cCodPar  :=cCodPar // Código del Parámetro
   oLIBCOMFCH:lWhen    :=.T.
   oLIBCOMFCH:cTextTit :="" // Texto del Titulo Heredado
   oLIBCOMFCH:oDb      :=oDp:oDb
   oLIBCOMFCH:cBrwCod  :="LIBCOMFCH"
   oLIBCOMFCH:lTmdi    :=.T.
   oLIBCOMFCH:aHead    :={}
   oLIBCOMFCH:lBarDef  :=.T.     // Activar Modo Diseño.
   oLIBCOMFCH:cCodSuc  :=cCodSuc // Sucursal
   oLIBCOMFCH:cCenCos  :=cCenCos // Centro de Costos
   oLIBCOMFCH:cCodCaj  :=cCodCaj
   oLIBCOMFCH:lVenta   :=lVenta 


   // Guarda los parámetros del Browse cuando cierra la ventana
   oLIBCOMFCH:bValid   :={|| EJECUTAR("BRWSAVEPAR",oLIBCOMFCH)}

   oLIBCOMFCH:lBtnRun     :=.F.
   oLIBCOMFCH:lBtnMenuBrw :=.F.
   oLIBCOMFCH:lBtnSave    :=.F.
   oLIBCOMFCH:lBtnCrystal :=.F.
   oLIBCOMFCH:lBtnRefresh :=.F.
   oLIBCOMFCH:lBtnHtml    :=.T.
   oLIBCOMFCH:lBtnExcel   :=.T.
   oLIBCOMFCH:lBtnPreview :=.T.
   oLIBCOMFCH:lBtnQuery   :=.F.
   oLIBCOMFCH:lBtnOptions :=.T.
   oLIBCOMFCH:lBtnPageDown:=.T.
   oLIBCOMFCH:lBtnPageUp  :=.T.
   oLIBCOMFCH:lBtnFilters :=.T.
   oLIBCOMFCH:lBtnFind    :=.T.
   oLIBCOMFCH:lBtnColor   :=.T.

   oLIBCOMFCH:nClrPane1:=16775408
   oLIBCOMFCH:nClrPane2:=16771797

   oLIBCOMFCH:nClrText :=0
   oLIBCOMFCH:nClrText1:=13526784
   oLIBCOMFCH:nClrText2:=0
   oLIBCOMFCH:nClrText3:=0


   oLIBCOMFCH:oBrw:=TXBrowse():New( IF(oLIBCOMFCH:lTmdi,oLIBCOMFCH:oWnd,oLIBCOMFCH:oDlg ))
   oLIBCOMFCH:oBrw:SetArray( aData, .F. )
   oLIBCOMFCH:oBrw:SetFont(oFont)

   oLIBCOMFCH:oBrw:lFooter     := .T.
   oLIBCOMFCH:oBrw:lHScroll    := .F.
   oLIBCOMFCH:oBrw:nHeaderLines:= 2
   oLIBCOMFCH:oBrw:nDataLines  := 1
   oLIBCOMFCH:oBrw:nFooterLines:= 1

   oLIBCOMFCH:aData            :=ACLONE(aData)

   AEVAL(oLIBCOMFCH:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   
  // Campo: PLP_CODSUC
  oCol:=oLIBCOMFCH:oBrw:aCols[1]
  oCol:cHeader      :='Sucursal'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMFCH:oBrw:aArrayData ) } 
  oCol:nWidth       := 48

  // Campo: PLP_FCHDEC
  oCol:=oLIBCOMFCH:oBrw:aCols[2]
  oCol:cHeader      :='Fecha'+CRLF+'Declaración'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMFCH:oBrw:aArrayData ) } 
  oCol:nWidth       := 70

  // Campo: PLP_FECHA
  oCol:=oLIBCOMFCH:oBrw:aCols[3]
  oCol:cHeader      :='Fecha'+CRLF+'Pago'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMFCH:oBrw:aArrayData ) } 
  oCol:nWidth       := 70

  // Campo: LBC_MTOBAS
  oCol:=oLIBCOMFCH:oBrw:aCols[4]
  oCol:cHeader      :='Base'+CRLF+'Imponible'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMFCH:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMFCH:oBrw:aArrayData[oLIBCOMFCH:oBrw:nArrayAt,4],;
                              oCol  := oLIBCOMFCH:oBrw:aCols[4],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[4],oCol:cEditPicture)


  // Campo: LBC_MTOIVA
  oCol:=oLIBCOMFCH:oBrw:aCols[5]
  oCol:cHeader      :='Monto'+CRLF+'IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMFCH:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMFCH:oBrw:aArrayData[oLIBCOMFCH:oBrw:nArrayAt,5],;
                              oCol  := oLIBCOMFCH:oBrw:aCols[5],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[5],oCol:cEditPicture)


  // Campo: LBC_MTONET
  oCol:=oLIBCOMFCH:oBrw:aCols[6]
  oCol:cHeader      :=IF(lVenta,"Venta",'Compra')+CRLF+'con IVA'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMFCH:oBrw:aArrayData ) } 
  oCol:nWidth       := 136
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999,999,999,999.99'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMFCH:oBrw:aArrayData[oLIBCOMFCH:oBrw:nArrayAt,6],;
                              oCol  := oLIBCOMFCH:oBrw:aCols[6],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[6],oCol:cEditPicture)


  // Campo: CUANTOS
  oCol:=oLIBCOMFCH:oBrw:aCols[7]
  oCol:cHeader      :='Cant.'+CRLF+'Reg.'
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oLIBCOMFCH:oBrw:aArrayData ) } 
  oCol:nWidth       := 144
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :='9,999,999'
  oCol:bStrData:={|nMonto,oCol|nMonto:= oLIBCOMFCH:oBrw:aArrayData[oLIBCOMFCH:oBrw:nArrayAt,7],;
                              oCol   := oLIBCOMFCH:oBrw:aCols[7],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[7],oCol:cEditPicture)


   oLIBCOMFCH:oBrw:aCols[1]:cFooter:=" #"+LSTR(LEN(aData))

   oLIBCOMFCH:oBrw:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oLIBCOMFCH:oBrw,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                                                 nClrText:=oLIBCOMFCH:nClrText,;
                                                 nClrText:=IF(aLine[7]>0,oLIBCOMFCH:nClrText1,nClrText),;
                                                 nClrText:=IF(.F.,oLIBCOMFCH:nClrText2,nClrText),;
                                                 {nClrText,iif( oBrw:nArrayAt%2=0, oLIBCOMFCH:nClrPane1, oLIBCOMFCH:nClrPane2 ) } }

//   oLIBCOMFCH:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
//   oLIBCOMFCH:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oLIBCOMFCH:oBrw:bClrHeader          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oLIBCOMFCH:oBrw:bClrFooter          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oLIBCOMFCH:oBrw:bLDblClick:={|oBrw|oLIBCOMFCH:RUNCLICK() }

   oLIBCOMFCH:oBrw:bChange:={||oLIBCOMFCH:BRWCHANGE()}
   oLIBCOMFCH:oBrw:CreateFromCode()

   oLIBCOMFCH:oWnd:oClient := oLIBCOMFCH:oBrw

   oLIBCOMFCH:Activate({||oLIBCOMFCH:ViewDatBar()})

   oLIBCOMFCH:BRWRESTOREPAR()

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg:=IF(oLIBCOMFCH:lTmdi,oLIBCOMFCH:oWnd,oLIBCOMFCH:oDlg)
   LOCAL nLin:=2,nCol:=0
   LOCAL nWidth:=oLIBCOMFCH:oBrw:nWidth()
   
   oLIBCOMFCH:oBrw:GoBottom(.T.)
   oLIBCOMFCH:oBrw:Refresh(.T.)

//   IF !File("FORMS\BRLIBCOMFCH.EDT")
//     oLIBCOMFCH:oBrw:Move(44,0,6850+50,460)
//   ENDIF

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52-15,60-15+40+00 OF oDlg 3D CURSOR oCursor
   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -10 BOLD


 // Emanager no Incluye consulta de Vinculos


   IF .F. .AND. Empty(oLIBCOMFCH:cServer)

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\VIEW.BMP";
            ACTION EJECUTAR("BRWRUNLINK",oLIBCOMFCH:oBrw,oLIBCOMFCH:cSql)

     oBtn:cToolTip:="Consultar Vinculos"


   ENDIF

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\RUN.BMP";
          ACTION oLIBCOMFCH:EDITLIBCOM()

   oBtn:cToolTip:="Editar Documentos Libro de "+IF(oLIBCOMFCH:lVenta,"Ventas","Compras")

   IF !oLIBCOMFCH:lVenta

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\LIBRODECOMPRA.BMP";
            ACTION oLIBCOMFCH:DPLIBCOM()
   ELSE

   ENDIF

   oBtn:cToolTip:="Generar Libro de Compra"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CONTABILIZAR.BMP";
          ACTION oLIBCOMFCH:RUNCONTAB()

   oBtn:cToolTip:="Contabilizar"

/*
   IF Empty(oLIBCOMFCH:cServer) .AND. !Empty(SQLGET("DPBRWLNK","EBR_CODIGO","EBR_CODIGO"+GetWhere("=","LIBCOMFCH")))
*/

   IF ISSQLFIND("DPBRWLNKCONCAT","BRC_CODIGO"+GetWhere("=","LIBCOMFCH"))

       DEFINE BUTTON oBtn;
       OF oBar;
       NOBORDER;
       FONT oFont;
       FILENAME "BITMAPS\XBROWSE.BMP";
       ACTION EJECUTAR("BRWRUNBRWLINK",oLIBCOMFCH:oBrw,"LIBCOMFCH",oLIBCOMFCH:cSql,oLIBCOMFCH:nPeriodo,oLIBCOMFCH:dDesde,oLIBCOMFCH:dHasta,oLIBCOMFCH)

       oBtn:cToolTip:="Ejecutar Browse Vinculado(s)"
       oLIBCOMFCH:oBtnRun:=oBtn

       oLIBCOMFCH:oBrw:bLDblClick:={||EVAL(oLIBCOMFCH:oBtnRun:bAction) }

   ENDIF


IF oLIBCOMFCH:lBtnRun

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            MENU EJECUTAR("BRBTNMENU",{"Opcion 1",;
                                       "Opcion 2",;
                                       "Opcion 3"},;
                                       "oLIBCOMFCH");
            FILENAME "BITMAPS\RUN.BMP";
            ACTION oLIBCOMFCH:BTNRUN()

      oBtn:cToolTip:="Opciones de Ejecucion"

ENDIF

IF oLIBCOMFCH:lBtnColor

     oLIBCOMFCH:oBtnColor:=NIL

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\COLORS.BMP";
            MENU EJECUTAR("BRBTNMENUCOLOR",oLIBCOMFCH:oBrw,oLIBCOMFCH,oLIBCOMFCH:oBtnColor,{||EJECUTAR("BRWCAMPOSOPC",oLIBCOMFCH,.T.)});
            ACTION EJECUTAR("BRWSELCOLORFIELD",oLIBCOMFCH,.T.)

    oBtn:cToolTip:="Personalizar Colores en los Campos"

    oLIBCOMFCH:oBtnColor:=oBtn

ENDIF



IF oLIBCOMFCH:lBtnSave

      DEFINE BITMAP OF OUTLOOK oBRWMENURUN:oOut ;
             BITMAP "BITMAPS\XSAVE.BMP";
             PROMPT "Guardar Consulta";
             ACTION EJECUTAR("DPBRWSAVE",oLIBCOMFCH:oBrw,oLIBCOMFCH:oFrm)
ENDIF

IF oLIBCOMFCH:lBtnMenuBrw

 DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\BRWMENU.BMP",NIL,"BITMAPS\BRWMENUG.BMP";
          ACTION (EJECUTAR("BRWBUILDHEAD",oLIBCOMFCH),;
                  EJECUTAR("DPBRWMENURUN",oLIBCOMFCH,oLIBCOMFCH:oBrw,oLIBCOMFCH:cBrwCod,oLIBCOMFCH:cTitle,oLIBCOMFCH:aHead));
          WHEN !Empty(oLIBCOMFCH:oBrw:aArrayData[1,1])

   oBtn:cToolTip:="Menú de Opciones"

ENDIF


IF oLIBCOMFCH:lBtnFind

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
          ACTION EJECUTAR("BRWSETFIND",oLIBCOMFCH:oBrw)

   oBtn:cToolTip:="Buscar"
ENDIF

IF oLIBCOMFCH:lBtnFilters

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          MENU EJECUTAR("BRBTNMENUFILTER",oLIBCOMFCH:oBrw,oLIBCOMFCH);
          ACTION EJECUTAR("BRWSETFILTER",oLIBCOMFCH:oBrw)

   oBtn:cToolTip:="Filtrar Registros"
ENDIF

IF oLIBCOMFCH:lBtnOptions

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
          ACTION EJECUTAR("BRWSETOPTIONS",oLIBCOMFCH:oBrw);
          WHEN LEN(oLIBCOMFCH:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

ENDIF

IF oLIBCOMFCH:lBtnRefresh

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\REFRESH.BMP";
          ACTION oLIBCOMFCH:BRWREFRESCAR()

   oBtn:cToolTip:="Refrescar"

ENDIF

IF oLIBCOMFCH:lBtnCrystal

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.BMP";
          ACTION EJECUTAR("BRWTODBF",oLIBCOMFCH)

   oBtn:cToolTip:="Visualizar Mediante Crystal Report"

ENDIF

IF oLIBCOMFCH:lBtnExcel


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
            ACTION (EJECUTAR("BRWTOEXCEL",oLIBCOMFCH:oBrw,oLIBCOMFCH:cTitle,oLIBCOMFCH:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oLIBCOMFCH:oBtnXls:=oBtn

ENDIF

IF oLIBCOMFCH:lBtnHtml

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          ACTION (oLIBCOMFCH:HTMLHEAD(),EJECUTAR("BRWTOHTML",oLIBCOMFCH:oBrw,NIL,oLIBCOMFCH:cTitle,oLIBCOMFCH:aHead))

   oBtn:cToolTip:="Generar Archivo html"

   oLIBCOMFCH:oBtnHtml:=oBtn

ENDIF


IF oLIBCOMFCH:lBtnPreview

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
          ACTION (EJECUTAR("BRWPREVIEW",oLIBCOMFCH:oBrw))

   oBtn:cToolTip:="Previsualización"

   oLIBCOMFCH:oBtnPreview:=oBtn

ENDIF

   IF ISSQLGET("DPREPORTES","REP_CODIGO","BRLIBCOMFCH")

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XPRINT.BMP";
            ACTION oLIBCOMFCH:IMPRIMIR()

      oBtn:cToolTip:="Imprimir"

     oLIBCOMFCH:oBtnPrint:=oBtn

   ENDIF

IF oLIBCOMFCH:lBtnQuery


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oLIBCOMFCH:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          ACTION (oLIBCOMFCH:oBrw:GoTop(),oLIBCOMFCH:oBrw:Setfocus())

IF nWidth>800 .OR. nWidth=0

   IF oLIBCOMFCH:lBtnPageDown

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\xSIG.BMP";
            ACTION (oLIBCOMFCH:oBrw:PageDown(),oLIBCOMFCH:oBrw:Setfocus())
  ENDIF

  IF  oLIBCOMFCH:lBtnPageUp

    DEFINE BUTTON oBtn;
           OF oBar;
           NOBORDER;
           FONT oFont;
           FILENAME "BITMAPS\xANT.BMP";
           ACTION (oLIBCOMFCH:oBrw:PageUp(),oLIBCOMFCH:oBrw:Setfocus())
  ENDIF

ENDIF

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
          ACTION (oLIBCOMFCH:oBrw:GoBottom(),oLIBCOMFCH:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION oLIBCOMFCH:Close()

  oLIBCOMFCH:oBrw:SetColor(0,oLIBCOMFCH:nClrPane1)

  oLIBCOMFCH:SETBTNBAR(40,40,oBar)

  EVAL(oLIBCOMFCH:oBrw:bChange)

  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oLIBCOMFCH:oBar:=oBar

  // nCol:=6490
  // nLin:=<NLIN> // 08
  // Controles se Inician luego del Ultimo Boton

  nCol:=10
  nLin:=50

  // AEVAL(oBar:aControls,{|o,n|nCol:=nCol+o:nWidth() })

  //
  // Campo : Periodo
  //

  @ nLin, nCol COMBOBOX oLIBCOMFCH:oPeriodo  VAR oLIBCOMFCH:cPeriodo ITEMS aPeriodos;
                SIZE 100,200;
                PIXEL;
                OF oBar;
                FONT oFont;
                ON CHANGE oLIBCOMFCH:LEEFECHAS();
                WHEN oLIBCOMFCH:lWhen


  ComboIni(oLIBCOMFCH:oPeriodo )

  @ nLin, nCol+103 BUTTON oLIBCOMFCH:oBtn PROMPT " < " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oLIBCOMFCH:oPeriodo:nAt,oLIBCOMFCH:oDesde,oLIBCOMFCH:oHasta,-1),;
                         EVAL(oLIBCOMFCH:oBtn:bAction));
                WHEN oLIBCOMFCH:lWhen


  @ nLin, nCol+130 BUTTON oLIBCOMFCH:oBtn PROMPT " > " SIZE 27,24;
                 FONT oFont;
                 PIXEL;
                 OF oBar;
                 ACTION (EJECUTAR("PERIODOMAS",oLIBCOMFCH:oPeriodo:nAt,oLIBCOMFCH:oDesde,oLIBCOMFCH:oHasta,+1),;
                         EVAL(oLIBCOMFCH:oBtn:bAction));
                WHEN oLIBCOMFCH:lWhen


  @ nLin, nCol+160 BMPGET oLIBCOMFCH:oDesde  VAR oLIBCOMFCH:dDesde;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oLIBCOMFCH:oDesde ,oLIBCOMFCH:dDesde);
                SIZE 76-2,24;
                OF   oBar;
                WHEN oLIBCOMFCH:oPeriodo:nAt=LEN(oLIBCOMFCH:oPeriodo:aItems) .AND. oLIBCOMFCH:lWhen ;
                FONT oFont

   oLIBCOMFCH:oDesde:cToolTip:="F6: Calendario"

  @ nLin, nCol+252 BMPGET oLIBCOMFCH:oHasta  VAR oLIBCOMFCH:dHasta;
                PICTURE "99/99/9999";
                PIXEL;
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oLIBCOMFCH:oHasta,oLIBCOMFCH:dHasta);
                SIZE 76-2,24;
                WHEN oLIBCOMFCH:oPeriodo:nAt=LEN(oLIBCOMFCH:oPeriodo:aItems) .AND. oLIBCOMFCH:lWhen ;
                OF oBar;
                FONT oFont

   oLIBCOMFCH:oHasta:cToolTip:="F6: Calendario"

   @ nLin, nCol+345 BUTTON oLIBCOMFCH:oBtn PROMPT " > " SIZE 27,24;
               FONT oFont;
               OF oBar;
               PIXEL;
               WHEN oLIBCOMFCH:oPeriodo:nAt=LEN(oLIBCOMFCH:oPeriodo:aItems);
               ACTION oLIBCOMFCH:HACERWHERE(oLIBCOMFCH:dDesde,oLIBCOMFCH:dHasta,oLIBCOMFCH:cWhere,.T.,oLIBCOMFCH:cCodSuc,oLIBCOMFCH:cCenCos,oLIBCOMFCH:cCodCaj);
               WHEN oLIBCOMFCH:lWhen

  BMPGETBTN(oBar,oFont,13)

  nCol:=10
  AEVAL(oBar:aControls,{|o|o:ForWhen(.T.)})
 
  DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 BOLD

  IF !Empty(oLIBCOMFCH:cCodCaj)
  
    oBar:SetSize(200,oBar:nHeight()+20,.T.)

    @ nLin+27,nCol+001 SAY " Caja " OF oBar;
                       BORDER SIZE 074,20;
                       COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont SIZE 80,20 PIXEL RIGHT

    @ nLin+27,nCol+076 SAY " "+oLIBCOMFCH:cCodCaj+" " OF oBar;
                       BORDER SIZE 070,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    @ nLin+27,nCol+148 SAY " "+SQLGET("DPCAJA","CAJ_NOMBRE","CAJ_CODIGO"+GetWhere("=",oLIBCOMFCH:cCodCaj))+" " OF oBar;
                       BORDER SIZE 320,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

  ENDIF

  IF !Empty(oLIBCOMFCH:cCenCos)
  
    oBar:SetSize(200,oBar:nHeight()+20,.T.)

    @ nLin+27,nCol+001 SAY " C.Costo " OF oBar;
                       BORDER SIZE 074,20;
                       COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont SIZE 80,20 PIXEL RIGHT

    @ nLin+27,nCol+076 SAY " "+oLIBCOMFCH:cCenCos+" " OF oBar;
                       BORDER SIZE 070,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    @ nLin+27,nCol+148 SAY " "+SQLGET("DPCENCOS","CEN_DESCRI","CEN_CODIGO"+GetWhere("=",oLIBCOMFCH:cCenCos))+" " OF oBar;
                       BORDER SIZE 320,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

  ENDIF



RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()

  oLIBCOMFCH:EDITLIBCOM()

RETURN .T.


/*
// Imprimir
*/
FUNCTION IMPRIMIR()
  LOCAL oRep,cWhere

  oRep:=REPORTE("BRLIBCOMFCH",cWhere)
  oRep:cSql  :=oLIBCOMFCH:cSql
  oRep:cTitle:=oLIBCOMFCH:cTitle

RETURN .T.

FUNCTION LEEFECHAS()
  LOCAL nPeriodo:=oLIBCOMFCH:oPeriodo:nAt,cWhere

  oLIBCOMFCH:nPeriodo:=nPeriodo


  IF oLIBCOMFCH:oPeriodo:nAt=LEN(oLIBCOMFCH:oPeriodo:aItems)

     oLIBCOMFCH:oDesde:ForWhen(.T.)
     oLIBCOMFCH:oHasta:ForWhen(.T.)
     oLIBCOMFCH:oBtn  :ForWhen(.T.)

     DPFOCUS(oLIBCOMFCH:oDesde)

  ELSE

     oLIBCOMFCH:aFechas:=EJECUTAR("DPDIARIOGET",nPeriodo)

     oLIBCOMFCH:oDesde:VarPut(oLIBCOMFCH:aFechas[1] , .T. )
     oLIBCOMFCH:oHasta:VarPut(oLIBCOMFCH:aFechas[2] , .T. )

     oLIBCOMFCH:dDesde:=oLIBCOMFCH:aFechas[1]
     oLIBCOMFCH:dHasta:=oLIBCOMFCH:aFechas[2]

     cWhere:=oLIBCOMFCH:HACERWHERE(oLIBCOMFCH:dDesde,oLIBCOMFCH:dHasta,oLIBCOMFCH:cWhere,.T.,oLIBCOMFCH:cCodSuc,oLIBCOMFCH:cCenCos,oLIBCOMFCH:cCodCaj)

     oLIBCOMFCH:LEERDATA(cWhere,oLIBCOMFCH:oBrw,oLIBCOMFCH:cServer,oLIBCOMFCH)

  ENDIF

  oLIBCOMFCH:SAVEPERIODO()

RETURN .T.


FUNCTION HACERWHERE(dDesde,dHasta,cWhere_,lRun,cCodSuc,cCenCos,cCodCaj)
   LOCAL cWhere:=""

   DEFAULT lRun:=.F.

   EJECUTAR("CREARCALFIS",dDesde,dHasta,.F.,.F.)

   // Campo fecha no puede estar en la nueva clausula
   IF "DPDOCPROPROG.PLP_FCHDEC"$cWhere
      RETURN ""
   ENDIF

   IF !Empty(dDesde)
       cWhere:=GetWhereAnd('DPDOCPROPROG.PLP_FCHDEC',dDesde,dHasta)
   ELSE
     IF !Empty(dHasta)
       cWhere:=GetWhereAnd('DPDOCPROPROG.PLP_FCHDEC',dDesde,dHasta)
     ENDIF
   ENDIF


   IF !Empty(cWhere_)
      cWhere:=cWhere + IIF( Empty(cWhere),""," AND ") +cWhere_
   ENDIF

   IF lRun

     IF !Empty(oLIBCOMFCH:cWhereQry)
       cWhere:=cWhere + oLIBCOMFCH:cWhereQry
     ENDIF

     oLIBCOMFCH:LEERDATA(cWhere,oLIBCOMFCH:oBrw,oLIBCOMFCH:cServer,oLIBCOMFCH)

   ENDIF


RETURN cWhere


FUNCTION LEERDATA(cWhere,oBrw,cServer,oLIBCOMFCH,cCodSuc,cCenCos,cCodCaj,lVenta)
   LOCAL aData:={},aTotal:={},oCol,cSql,aLines:={}
   LOCAL oDb
   LOCAL nAt,nRowSel,cWhereJ:=""
   LOCAL cCxP:="*LBC_CXP"

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

   IF ValType(oLIBCOMFCH)="O"
      cCodSuc:=oLIBCOMFCH:cCodSuc
      cCenCos:=oLIBCOMFCH:cCenCos
      cCodCaj:=oLIBCOMFCH:cCodCaj
      lVenta :=oLIBCOMFCH:lVenta
   ENDIF

   IF !Empty(cCodSuc)
      cWhereJ:=" LBC_CODSUC"+GetWhere("=",cCodSuc)
   ENDIF

   IF !Empty(cCenCos)
      cWhereJ:=cWhereJ+IF(Empty(cWhereJ),""," AND ")+" LBC_CENCOS"+GetWhere("=",cCenCos)
   ENDIF

   IF !Empty(cCodCaj)
      cWhereJ:=cWhereJ+IF(Empty(cWhereJ),""," AND ")+" LBC_CODCAJ"+GetWhere("=",cCodCaj)
   ENDIF

   IF lVenta
     cCxP:="*LBC_CXC"
   ENDIF

   cSql:=" SELECT  "+;
          "   PLP_CODSUC, "+;
          "   PLP_FCHDEC, "+;  
          "   PLP_FECHA, "+;
          "   SUM(IF(LBC_MTOBAS IS NULL,0,LBC_MTOBAS"+cCxP+")) AS LBC_MTOBAS, "+;
          "   SUM(IF(LBC_MTOIVA IS NULL,0,LBC_MTOIVA"+cCxP+")) AS LBC_MTOIVA, "+;
          "   SUM(IF(LBC_MTONET IS NULL,0,LBC_MTONET"+cCxP+")) AS LBC_MTONET, "+;
          "   SUM(IF(LBC_CODSUC IS NULL,0,1)) AS CUANTOS "+;
          "   FROM VIEW_DPCALF30   "+;
          "   INNER JOIN DPDOCPROPROG     ON F30_FECHA=PLP_FECHA "+IF(Empty(cWhere),""," AND "+cWhere)+;
          "   INNER JOIN DPPROVEEDORPROG  ON "+;
          "       PLP_CODSUC=PGC_CODSUC AND "+;
          "       PLP_CODIGO=PGC_CODIGO AND "+;
          "       PLP_TIPDOC=PGC_TIPDOC AND "+;
          "       PLP_NUMERO=PGC_NUMERO AND "+;
          "       PLP_TIPTRA='D' "+;
          "   LEFT JOIN DPLIBCOMPRASDET   ON PLP_CODSUC=LBC_CODSUC AND LBC_FCHDEC=PLP_FCHDEC "+IF(Empty(cWhereJ),""," AND "+cWhereJ)+;
          "   WHERE 1=1 "+;
          "   GROUP BY PLP_CODSUC,PLP_FCHDEC,PLP_FECHA  ORDER BY PLP_FECHA"+;
          ""

  IF lVenta
     cSql:=STRTRAN(cSql,"DPLIBCOMPRASDET","DPLIBVENTASDET")
  ENDIF

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

   DPWRITE("TEMP\BRLIBCOMFCH.SQL",cSql)

   aData:=ASQL(cSql,oDb)

// ? CLPCOPY(oDp:cSql)

   oDp:cWhere:=cWhere


   IF EMPTY(aData)
      aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
//    AADD(aData,{'',CTOD(""),CTOD(""),0,0,0,0})
   ENDIF

   

   IF ValType(oBrw)="O"

      oLIBCOMFCH:cSql   :=cSql
      oLIBCOMFCH:cWhere_:=cWhere

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
      AEVAL(oLIBCOMFCH:oBar:aControls,{|o,n| o:ForWhen(.T.)})

      oLIBCOMFCH:SAVEPERIODO()

   ENDIF

RETURN aData


FUNCTION SAVEPERIODO()
  LOCAL cFileMem:="USER\BRLIBCOMFCH.MEM",V_nPeriodo:=oLIBCOMFCH:nPeriodo
  LOCAL V_dDesde:=oLIBCOMFCH:dDesde
  LOCAL V_dHasta:=oLIBCOMFCH:dHasta

  SAVE TO (cFileMem) ALL LIKE "V_*"

RETURN .T.

/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oLIBCOMFCH)
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


    IF Type("oLIBCOMFCH")="O" .AND. oLIBCOMFCH:oWnd:hWnd>0

      cWhere:=" "+IIF(!Empty(oLIBCOMFCH:cWhere_),oLIBCOMFCH:cWhere_,oLIBCOMFCH:cWhere)
      cWhere:=STRTRAN(cWhere," WHERE ","")

      oLIBCOMFCH:LEERDATA(oLIBCOMFCH:cWhere_,oLIBCOMFCH:oBrw,oLIBCOMFCH:cServer)
      oLIBCOMFCH:oWnd:Show()
      oLIBCOMFCH:oWnd:Restore()

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

   oLIBCOMFCH:aHead:=EJECUTAR("HTMLHEAD",oLIBCOMFCH)

// Ejemplo para Agregar mas Parámetros
//   AADD(oDOCPROISLR:aHead,{"Consulta",oDOCPROISLR:oWnd:cTitle})

RETURN

// Restaurar Parametros
FUNCTION BRWRESTOREPAR()
  EJECUTAR("BRWRESTOREPAR",oLIBCOMFCH)
RETURN .T.

/*
// Editar Libro de Compras
*/
FUNCTION EDITLIBCOM()
  LOCAL aLine  :=oLIBCOMFCH:oBrw:aArrayData[oLIBCOMFCH:oBrw:nArrayAt]
  LOCAL dFchDec:=aLine[2]
  LOCAL cWhere :=NIL,cCodSuc:=oLIBCOMFCH:cCodSuc,nPeriodo:=NIL,dDesde:=NIL,dHasta:=NIL,cTitle:=" Fecha Declaración "+DTOC(dFchDec),lView:=.F.
  LOCAL aTipDoc:=NIL,lCondom:=.F.,lCtaEgr:=NIL

  IF !Empty(oLIBCOMFCH:cCodCaj)

      DEFAULT cWhere:=""

      cWhere:=cWhere+IF(Empty(cWhere),""," AND ")+" LBC_CODCAJ"+GetWhere("=",oLIBCOMFCH:cCodCaj)

  ENDIF

  IF !Empty(oLIBCOMFCH:cCenCos)

      DEFAULT cWhere:=""

      cWhere:=cWhere+IF(Empty(cWhere),""," AND ")+" LBC_CENCOS"+GetWhere("=",oLIBCOMFCH:cCenCos)

  ENDIF

RETURN EJECUTAR("BRLIBCOMEDIT",cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,dFchDec,lView,oLIBCOMFCH:cCodCaj,NIL,NIL,NIL,NIL,oLIBCOMFCH:cCenCos,aTipDoc,lCondom,lCtaEgr,oLIBCOMFCH:lVenta)


/*
// Generar Asientos Contables
*/
FUNCTION RUNCONTAB()
   LOCAL aLine  :=oLIBCOMFCH:oBrw:aArrayData[oLIBCOMFCH:oBrw:nArrayAt]
   LOCAL dFchDec:=aLine[2]
   LOCAL cWhere :="DOC_CXPTIP"+GetWhere("=","LBC"),cCodSuc:=oLIBCOMFCH:cCodSuc,nPeriodo:=oDp:nIndicada,dDesde:=dFchDec,dHasta:=dFchDec,cTitle:=NIL
   LOCAL aTipCxP:={"CAJ","BCO","CJE","BCE","LBC","CXP"}

   IF !MsgNoYes("Desea Generar Asientos Contables")
      RETURN .T.
   ENDIF
   
   cWhere:="DOC_CODSUC"+GetWhere("=",oLIBCOMFCH:cCodSuc)+" AND "+GetWhereOr("DOC_CXPTIP",aTipCxP)
 
   EJECUTAR("DPLIBCOMTODPDOCPRO",oLIBCOMFCH:cCodSuc,dFchDec)

   EJECUTAR("BRDOCPRORESXCNT",cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle)

RETURN .T.


FUNCION DPLIBCOM()
  LOCAL lConEsp:=nil,lPlanilla,oLiq,cCodSuc,dDesde,dHasta,cNumero,lFecha,lFrm,lSemana
  LOCAL oFrm
  LOCAL aLine  :=oLIBCOMFCH:oBrw:aArrayData[oLIBCOMFCH:oBrw:nArrayAt]
  LOCAL dFchDec:=aLine[2]
  LOCAL dFchPag:=aLine[3]
  LOCAL cNumero:=EJECUTAR("GETNUMPLAFISCAL",oLIBCOMFCH:cCodSuc,"F30",dFchPag)
  LOCAL aTipCxP:={"CAJ","BCO","CJE","BCE","LBC"}

  dHasta:=aLine[2]
  dDesde:=IF(DAY(dHasta)=15,FCHINIMES(dHasta),FCHINIMES(dHasta)+14)

// ? dFchDec,cNumero,dDesde,dHasta
  
  EJECUTAR("DPLIBCOM",lConEsp,lPlanilla,oLiq,cCodSuc,dDesde,dHasta,cNumero,lFecha,lFrm,lSemana)

  oLibCom:oDesde:VarPut(dDesde,.T.)
  oLibCom:oHasta:VarPut(dHasta,.T.)

  IF DAY(dFchDec)>15
     oLibCom:nRadio:=2
  ELSE
     oLibCom:nRadio:=1
  ENDIF

//  oLibCom:HACERQUINCENA()

RETURN NIL
// EOF

