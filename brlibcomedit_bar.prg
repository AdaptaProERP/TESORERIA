// Programa   : BRLIBCOMEDIT_BAR
// Fecha/Hora : 18/11/2022 22:43:00
// Propósito  : "Libro de Compras editable"
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

FUNCTION MAIN(oLIBCOMEDIT)
   LOCAL oCursor,oBar,oBtn,oFont,oFontB,oCol,lSay:=.F.
   LOCAL oDlg:=NIL // IF(oLIBCOMEDIT:lTmdi,oLIBCOMEDIT:oWnd,oLIBCOMEDIT:oDlg)
   LOCAL nLin:=2,nCol:=0,nAt
   LOCAL nWidth:=0 // oLIBCOMEDIT:oBrw:nWidth()
   LOCAL nAdd  :=55+4

   IF oLIBCOMEDIT=NIL
      RETURN .F.
   ENDIF

   oDlg  :=IF(oLIBCOMEDIT:lTmdi,oLIBCOMEDIT:oWnd,oLIBCOMEDIT:oDlg)
   nWidth:=oLIBCOMEDIT:oBrw:nWidth()

   oLIBCOMEDIT:oBrw:GoBottom(.T.)
   oLIBCOMEDIT:oBrw:Refresh(.T.)

   DEFINE CURSOR oCursor HAND

   IF !oDp:lBtnText 
     DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   ELSE 
     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth,oDp:nBarnHeight+6+40 OF oDlg 3D CURSOR oCursor 
   ENDIF 

   DEFINE FONT oFont   NAME "Tahoma"   SIZE 0, -10 BOLD
   DEFINE FONT oFontB  NAME "Tahoma"   SIZE 0, -10 BOLD

   oLIBCOMEDIT:oFontBtn   :=oFont    
   oLIBCOMEDIT:nClrPaneBar:=oDp:nGris
   oLIBCOMEDIT:oBrw:oLbx  :=oLIBCOMEDIT

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSAVE.BMP";
          TOP PROMPT "Grabar"; 
          ACTION oLIBCOMEDIT:LIBCOMSAVE()

   oBtn:cToolTip:="Guardar en Documentos del Proveedor"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XNEW.BMP";
          TOP PROMPT "Incluir"; 
          ACTION oLIBCOMEDIT:LIBADDITEM()

   oBtn:cToolTip:="Insertar nuevo Item en el mismo documento"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CONTABILIZAR.BMP";
          TOP PROMPT "Contab"; 
          ACTION oLIBCOMEDIT:CONTABILIZAR()

   oBtn:cToolTip:="Contabilizar Documentos"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FORM.BMP";
          TOP PROMPT "Doc."; 
          ACTION oLIBCOMEDIT:CREARDOC(.T.)

   oBtn:cToolTip:="Crear Documento"

   oLIBCOMEDIT:oBtnForm:=oBtn

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\MENU.BMP";
          TOP PROMPT "Menú"; 
          ACTION oLIBCOMEDIT:CREARDOC(.F.)

   oBtn:cToolTip:="Menú del Documento"

   oLIBCOMEDIT:oBtnMenu:=oBtn

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\seniat.BMP";
          TOP PROMPT "Seniat"; 
          ACTION oLIBCOMEDIT:VALRIFSENIAT2()

   oBtn:cToolTip:="Obtener datos del SENIAT"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XDELETE.BMP";
          TOP PROMPT "Eliminar"; 
          ACTION oLIBCOMEDIT:DELASIENTOS()

   oBtn:cToolTip:="Activar/Inactivar Registro"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ZOOM.BMP";
          TOP PROMPT "Zoom"; 
          ACTION IF(oLIBCOMEDIT:oWnd:IsZoomed(),oLIBCOMEDIT:oWnd:Restore(),oLIBCOMEDIT:oWnd:Maximize())

   oBtn:cToolTip:="Maximizar"


/*
   IF Empty(oLIBCOMEDIT:cServer) .AND. !Empty(SQLGET("DPBRWLNK","EBR_CODIGO","EBR_CODIGO"+GetWhere("=","LIBCOMEDIT")))
*/

   IF ISSQLFIND("DPBRWLNKCONCAT","BRC_CODIGO"+GetWhere("=","LIBCOMEDIT"))

       DEFINE BUTTON oBtn;
       OF oBar;
       NOBORDER;
       FONT oFont;
       FILENAME "BITMAPS\XBROWSE.BMP";
       ACTION EJECUTAR("BRWRUNBRWLINK",oLIBCOMEDIT:oBrw,"LIBCOMEDIT",oLIBCOMEDIT:cSql,oLIBCOMEDIT:nPeriodo,oLIBCOMEDIT:dDesde,oLIBCOMEDIT:dHasta,oLIBCOMEDIT)

       oBtn:cToolTip:="Ejecutar Browse Vinculado(s)"
       oLIBCOMEDIT:oBtnRun:=oBtn



       oLIBCOMEDIT:oBrw:bLDblClick:={||EVAL(oLIBCOMEDIT:oBtnRun:bAction) }


   ENDIF




IF oLIBCOMEDIT:lBtnRun

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            MENU EJECUTAR("BRBTNMENU",{"Opcion 1",;
                                       "Opcion 2",;
                                       "Opcion 3"},;
                                       "oLIBCOMEDIT");
            FILENAME "BITMAPS\RUN.BMP";
            ACTION oLIBCOMEDIT:BTNRUN()

      oBtn:cToolTip:="Opciones de Ejecucion"

ENDIF

IF oLIBCOMEDIT:lBtnColor

     oLIBCOMEDIT:oBtnColor:=NIL

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            TOP PROMPT "Colorear"; 
            FILENAME "BITMAPS\COLORS.BMP";
            MENU EJECUTAR("BRBTNMENUCOLOR",oLIBCOMEDIT:oBrw,oLIBCOMEDIT,oLIBCOMEDIT:oBtnColor,{||EJECUTAR("BRWCAMPOSOPC",oLIBCOMEDIT,.T.)});
            ACTION EJECUTAR("BRWSELCOLORFIELD",oLIBCOMEDIT,.T.)

    oBtn:cToolTip:="Personalizar Colores en los Campos"

    oLIBCOMEDIT:oBtnColor:=oBtn

ENDIF




IF oLIBCOMEDIT:lBtnMenuBrw

 DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\BRWMENU.BMP",NIL,"BITMAPS\BRWMENUG.BMP";
          ACTION (EJECUTAR("BRWBUILDHEAD",oLIBCOMEDIT),;
                  EJECUTAR("DPBRWMENURUN",oLIBCOMEDIT,oLIBCOMEDIT:oBrw,oLIBCOMEDIT:cBrwCod,oLIBCOMEDIT:cTitle,oLIBCOMEDIT:aHead));
          WHEN !Empty(oLIBCOMEDIT:oBrw:aArrayData[1,1])

   oBtn:cToolTip:="Menú de Opciones"

ENDIF


IF oLIBCOMEDIT:lBtnFind

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
          TOP PROMPT "Buscar"; 
          ACTION EJECUTAR("BRWSETFIND",oLIBCOMEDIT:oBrw)

   oBtn:cToolTip:="Buscar"
ENDIF

IF oLIBCOMEDIT:lBtnFilters

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          TOP PROMPT "Filtra"; 
          MENU EJECUTAR("BRBTNMENUFILTER",oLIBCOMEDIT:oBrw,oLIBCOMEDIT);
          ACTION EJECUTAR("BRWSETFILTER",oLIBCOMEDIT:oBrw)

   oBtn:cToolTip:="Filtrar Registros"
ENDIF

IF oLIBCOMEDIT:lBtnOptions

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
          TOP PROMPT "Opciones"; 
          ACTION EJECUTAR("BRWSETOPTIONS",oLIBCOMEDIT:oBrw);
          WHEN LEN(oLIBCOMEDIT:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

ENDIF

IF oLIBCOMEDIT:lBtnRefresh

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\REFRESH.BMP";
          TOP PROMPT "Refrescar"; 
          ACTION oLIBCOMEDIT:BRWREFRESCAR()

   oBtn:cToolTip:="Refrescar"

ENDIF

IF oLIBCOMEDIT:lBtnCrystal

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.BMP";
          ACTION EJECUTAR("BRWTODBF",oLIBCOMEDIT)

   oBtn:cToolTip:="Visualizar Mediante Crystal Report"

ENDIF

IF oLIBCOMEDIT:lBtnExcel


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\EXCEL.BMP";
            TOP PROMPT "Excel"; 
            ACTION (EJECUTAR("BRWTOEXCEL",oLIBCOMEDIT:oBrw,oLIBCOMEDIT:cTitle,oLIBCOMEDIT:cNombre))

     oBtn:cToolTip:="Exportar hacia Excel"

     oLIBCOMEDIT:oBtnXls:=oBtn

ENDIF

IF oLIBCOMEDIT:lBtnHtml

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "HTML"; 
          FILENAME "BITMAPS\html.BMP";
          ACTION (oLIBCOMEDIT:HTMLHEAD(),EJECUTAR("BRWTOHTML",oLIBCOMEDIT:oBrw,NIL,oLIBCOMEDIT:cTitle,oLIBCOMEDIT:aHead))

   oBtn:cToolTip:="Generar Archivo html"

   oLIBCOMEDIT:oBtnHtml:=oBtn

ENDIF


IF oLIBCOMEDIT:lBtnPreview

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\PREVIEW.BMP";
          TOP PROMPT "Vista"; 
          ACTION (EJECUTAR("BRWPREVIEW",oLIBCOMEDIT:oBrw))

   oBtn:cToolTip:="Previsualización"

   oLIBCOMEDIT:oBtnPreview:=oBtn

ENDIF

   IF ISSQLGET("DPREPORTES","REP_CODIGO","BRLIBCOMEDIT")

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            TOP PROMPT "Imprimir"; 
            FILENAME "BITMAPS\XPRINT.BMP";
            ACTION oLIBCOMEDIT:IMPRIMIR()

      oBtn:cToolTip:="Imprimir"

     oLIBCOMEDIT:oBtnPrint:=oBtn

   ENDIF

IF oLIBCOMEDIT:lBtnQuery


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Query"; 
          FILENAME "BITMAPS\QUERY.BMP";
          ACTION oLIBCOMEDIT:BRWQUERY()

   oBtn:cToolTip:="Imprimir"

ENDIF




   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          TOP PROMPT "Primero"; 
          ACTION (oLIBCOMEDIT:oBrw:GoTop(),oLIBCOMEDIT:oBrw:Setfocus())

IF nWidth>800 .OR. nWidth=0

   IF oLIBCOMEDIT:lBtnPageDown

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\xSIG.BMP";
            ACTION (oLIBCOMEDIT:oBrw:PageDown(),oLIBCOMEDIT:oBrw:Setfocus())
  ENDIF

  IF  oLIBCOMEDIT:lBtnPageUp

    DEFINE BUTTON oBtn;
           OF oBar;
           NOBORDER;
           FONT oFont;
           FILENAME "BITMAPS\xANT.BMP";
           ACTION (oLIBCOMEDIT:oBrw:PageUp(),oLIBCOMEDIT:oBrw:Setfocus())
  ENDIF

ENDIF

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Ultimo"; 
          FILENAME "BITMAPS\xFIN.BMP";
          ACTION (oLIBCOMEDIT:oBrw:GoBottom(),oLIBCOMEDIT:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Salir"; 
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION oLIBCOMEDIT:Close()

  oLIBCOMEDIT:oBrw:SetColor(0,oLIBCOMEDIT:nClrPane1)

  nCol:=80
  oLIBCOMEDIT:SETBTNBAR(40,30,oBar)

  EVAL(oLIBCOMEDIT:oBrw:bChange)

  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris),nCol:=nCol+o:nWidth()})

  nCol:=-10	

  DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 BOLD

  @ 1.5+nAdd,nCol+32  SAY oSay PROMPT " Declarar " OF oBar;
               SIZE 70,20 COLOR oDp:nClrLabelText,oDp:nClrLabelPane PIXEL FONT oFont BORDER RIGHT

  @ 1.5+nAdd,nCol+102 SAY oSay PROMPT " "+DTOC(oLIBCOMEDIT:dFchDec) OF oBar;
               SIZE 90,20 COLOR oDp:nClrYellowText,oDp:nClrYellow PIXEL FONT oFont BORDER


  @ 22+nAdd,nCol+32  SAY oSay PROMPT " Pago " OF oBar;
               SIZE 70,20 COLOR oDp:nClrLabelText,oDp:nClrLabelPane PIXEL FONT oFont BORDER RIGHT

  @ 22+nAdd,nCol+102 SAY oSay PROMPT " "+DTOC(oLIBCOMEDIT:dFchPag) OF oBar;
               SIZE 90,20 COLOR oDp:nClrYellowText,oDp:nClrYellow PIXEL FONT oFont BORDER

  oLIBCOMEDIT:SETBTNBAR(52,60,oBar)


  IF !Empty(oLIBCOMEDIT:cCodCaj)
  
    nCol:=20
    nLin:=20+20

    oBar:SetSize(200,oBar:nHeight()+25,.T.)

    @ nLin+27,nCol+001 SAY " Caja " OF oBar;
                       BORDER SIZE 074,20;
                       COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont SIZE 80,20 PIXEL RIGHT

    @ nLin+27,nCol+076 SAY " "+oLIBCOMEDIT:cCodCaj+" " OF oBar;
                       BORDER SIZE 070,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    @ nLin+27,nCol+148 SAY " "+SQLGET("DPCAJA","CAJ_NOMBRE","CAJ_CODIGO"+GetWhere("=",oLIBCOMEDIT:cCodCaj))+" " OF oBar;
                       BORDER SIZE 320,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    lSay:=.T.

  ENDIF

  IF !Empty(oLIBCOMEDIT:cCodCli)
  
    nCol:=20
    nLin:=20+20

    oBar:SetSize(200,oBar:nHeight()+25,.T.)

    @ nLin+27,nCol+001 SAY " Cliente " OF oBar;
                       BORDER SIZE 074,20;
                       COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont SIZE 80,20 PIXEL RIGHT

    @ nLin+27,nCol+076+4 SAY " "+oLIBCOMEDIT:cCodCli+" " OF oBar;
                         BORDER SIZE 070+20,20;
                         COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    @ nLin+27,nCol+148+24 SAY " "+SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",oLIBCOMEDIT:cCodCli))+" " OF oBar;
                       BORDER SIZE 320,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    lSay:=.T.

  ENDIF


  IF !Empty(oLIBCOMEDIT:cCenCos)
  
    nCol:=20
    nLin:=20+20+35

    oBar:SetSize(200,oBar:nHeight()+25,.T.)

    @ nLin+27,nCol+001 SAY oDp:XDPCENCOS+" " OF oBar;
                       BORDER SIZE 074+80+6,20;
                       COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont SIZE 80,20 PIXEL RIGHT

    @ nLin+27,nCol+076+6+80 SAY " "+oLIBCOMEDIT:cCenCos+" " OF oBar;
                         BORDER SIZE 070+20,20;
                         COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    @ nLin+27,nCol+148+26+80 SAY " "+SQLGET("DPCENCOS","CEN_DESCRI","CEN_CODIGO"+GetWhere("=",oLIBCOMEDIT:cCenCos))+" " OF oBar;
                       BORDER SIZE 320,20;
                       COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL

    lSay:=.T.

  ENDIF


  IF !Empty(oLIBCOMEDIT:cNumRei)
  
    nCol:=20
    nLin:=20+20

    oBar:SetSize(200,oBar:nHeight()+25,.T.)

    @ nLin+27,nCol+001 SAY " Proveedor " OF oBar;
                       BORDER SIZE 074,20;
                       COLOR oDp:nClrLabelText,oDp:nClrLabelPane FONT oFont SIZE 80,20 PIXEL RIGHT

    @ nLin+27,nCol+078 BMPGET oLIBCOMEDIT:oCodPro VAR oLIBCOMEDIT:cCodPro;
                       VALID oLIBCOMEDIT:VALCODPRO();
                       NAME "BITMAPS\FIND.BMP";
                       ACTION (oDpLbx:=DpLbx("DPPROVEEDOR",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oLIBCOMEDIT:oCodPro), oDpLbx:GetValue("PRO_CODIGO",oLIBCOMEDIT:oCodPro)); 
                       SIZE 100,21 OF oLIBCOMEDIT:oBar FONT oFontB PIXEL

     @ oLIBCOMEDIT:oCodPro:nTop(),oLIBCOMEDIT:oCodPro:nRight()+20 SAY oLIBCOMEDIT:oNomPro;
                                        PROMPT SQLGET("DPPROVEEDOR","PRO_NOMBRE","PRO_CODIGO"+GetWhere("=",oLIBCOMEDIT:cCodPro)) OF oBar;
                                        SIZE 150+150,20 PIXEL FONT oFontB;
                                        COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 80,20 PIXEL BORDER

     oLIBCOMEDIT:oCodPro:bkeyDown:={|nkey| IIF(nKey=13, oLIBCOMEDIT:VALCODPRO(),NIL) }

     BMPGETBTN(oLIBCOMEDIT:oCodPro)

     lSay:=.T.

  ENDIF

  IF !lSay

//  DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -18 BOLD

    DEFINE FONT oFont NAME "Tahoma"   SIZE 0, -28 BOLD 

    nLin:=42
    nCol:=250
    
    IF oLIBCOMEDIT:lCondom

      @ nLin+27,nCol+001 SAY " Gastos del Condominio " OF oBar;
                         BORDER COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 280+140,34 PIXEL 

    ELSE

      @ nLin+27,nCol+001 SAY IF(oLIBCOMEDIT:lVenta," Libro de Ventas"," Libro de Compras") OF oBar;
                         BORDER COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont SIZE 280,34 PIXEL 

    ENDIF

  ENDIF

  oLIBCOMEDIT:oBar:=oBar

  nAt:=ASCAN(oLIBCOMEDIT:oBrw:aArrayData,{|a,n| Empty(a[oLIBCOMEDIT:COL_LBC_FECHA])})

  IF nAt=0
    oLIBCOMEDIT:LIBCOMADDLINE()
  ENDIF

// ENDIF

RETURN .T.

