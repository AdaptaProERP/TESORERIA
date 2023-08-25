// Programa   : BRDPDOCCXPRES
// Fecha/Hora : 01/05/2006 08:12:09
// Propósito  : Resumen de Documentos por Proveedor
// Creado Por : Juan Navas
// Llamado por: DPMENU
// Aplicación : Gerencia 
// Tabla      : DPTIPDOCPRO

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,dFecha,lData,lMsg)
   LOCAL cSql
   LOCAL aData,cTitle

   IF Type("oCxPRes")="O" .AND. oCxPRes:oWnd:hWnd>0
      RETURN EJECUTAR("BRRUNNEW",oCxPRes,GetScript())
   ENDIF

   DEFAULT cCodSuc:=oDp:cSucursal,;
           dFecha :=oDp:dFecha   ,;
           lData  :=.F.          ,;
           lMsg   :=.T.

   cTitle:="Resumen de Cuentas por Pagar por "+oDp:xDPPROVEEDOR

   aData :=LEERDOCPRO(NIL,NIL,cCodSuc,dFecha)

   IF lData
     RETURN aData
   ENDIF

   IF Empty(aData) 

      IF lMsg
        MensajeErr("no hay "+cTitle,"Información no Encontrada")
      ENDIF

      RETURN .F.

   ENDIF

   ViewData(aData,cTitle)
            
RETURN .T.

FUNCTION ViewData(aData,cTitle)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL I,nMonto:=0
   LOCAL cSql,oTable
   LOCAL oFont,oFontB
   LOCAL nDebe:=0,nHaber:=0
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

//   DPEDIT():New(cTitle,"DPDOCCXPRESUMEN.EDT","oCxPRes",.T.)

   DpMdi(cTitle,"oCxPRes","BRREIDET.EDT")
   oCxPRes:Windows(0,0,aCoors[3]-160,MIN(aCoors[4]-10,940),.T.) // Maximizado


   oCxPRes:cCodSuc :=oDp:cSucursal
   oCxPRes:lMsgBar :=.F.
   oCxPRes:cCodSuc :=cCodSuc
   oCxPRes:cTipDoc :=cTipDoc
   oCxPRes:dFecha  :=oDp:dFecha
   oCxPRes:cNombre :="Hasta el "+DTOC(oDp:dFecha)

   oCxPRes:dDesde  :=dDesde
   oCxPRes:dHasta  :=dHasta

   oCxPRes:oBrw:=TXBrowse():New( oCxPRes:oDlg )
   oCxPRes:oBrw:SetArray( aData, .T. )
   oCxPRes:oBrw:SetFont(oFont)

   oCxPRes:oBrw:lFooter     := .T.
   oCxPRes:oBrw:lHScroll    := .T.
   oCxPRes:oBrw:nHeaderLines:= 2
   oCxPRes:oBrw:lFooter     :=.T.

   oCxPRes:aData            :=ACLONE(aData)
   oCxPRes:nClrText :=0
   oCxPRes:nClrPane1:=oDp:nClrPane1
   oCxPRes:nClrPane2:=oDp:nClrPane2

   AEVAL(oCxPRes:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   oCol:=oCxPRes:oBrw:aCols[1]   
   oCol:cHeader      :="Código"+CRLF+oDp:xDPPROVEEDOR
   oCol:nWidth       :=080
   oCol:cFooter      :=LTRAN(LEN(aData))+" Reg."
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 


   oCol:=oCxPRes:oBrw:aCols[2]
   oCol:cHeader      :="Nombre del "+CRLF+oDp:xDPPROVEEDOR
   oCol:nWidth       :=260
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 


   oCol:=oCxPRes:oBrw:aCols[3]
   oCol:cHeader      :="Desde"
   oCol:nWidth       :=70
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 

   oCol:=oCxPRes:oBrw:aCols[4]
   oCol:cHeader      :="Hasta"
   oCol:nWidth       :=70
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 


   oCol:=oCxPRes:oBrw:aCols[5]   
   oCol:cHeader      :="Deuda"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,5],;
                                TRAN(nMonto,"999,999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[5],"999,999,999,999,999.99")
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 


   oCol:=oCxPRes:oBrw:aCols[6]   
   oCol:cHeader      :="I.V.A"+CRLF+"por Pagar"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,6],;
                                TRAN(nMonto,"999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[6],"999,999,999,999.99")
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 

   oCol:=oCxPRes:oBrw:aCols[7]   
   oCol:cHeader      :="Vencido"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,7],;
                                TRAN(nMonto,"999,999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[7],"999,999,999,999,999.99")
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 


   oCol:=oCxPRes:oBrw:aCols[8]   
   oCol:cHeader      :="Deuda"+CRLF+"en Divisa"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,8],;
                                TRAN(nMonto,"999,999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[8],"999,999,999,999,999,999.99")
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 

   oCol:=oCxPRes:oBrw:aCols[9]   
   oCol:cHeader      :="Vencido"+CRLF+"Divisa"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,9],;
                                TRAN(nMonto,"999,999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[9],"999,999,999,999,999.99")
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 


   oCol:=oCxPRes:oBrw:aCols[10]
   oCol:cHeader      :="Tipo"
   oCol:nWidth       :=70
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oCxPRes:oBrw:aArrayData ) } 


   oCxPRes:oBrw:bClrStd               := {|oBrw,nClrText,aData|oBrw:=oCxPRes:oBrw,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                           oCxPRes:nClrText,;
                                          {nClrText,iif( oBrw:nArrayAt%2=0, oCxPRes:nClrPane1, oCxPRes:nClrPane2 ) } }


   oCxPRes:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oCxPRes:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


   oCxPRes:oBrw:bLDblClick:={|oBrw|oCxPRes:oRep:=oCxPRes:VERPROVEEDOR() }

   oCxPRes:oBrw:CreateFromCode()
    oCxPRes:bValid   :={|| EJECUTAR("BRWSAVEPAR",oCxPRes)}
    oCxPRes:BRWRESTOREPAR()
   oCxPRes:oWnd:oClient := oCxPRes:oBrw

   oCxPRes:Activate({||oCxPRes:ViewDatBar(oCxPRes)})

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar(oCxPRes)
   LOCAL oCursor,oBar,oBtn,oFont,oCol,nDif
   LOCAL nWidth :=0 // Ancho Calculado seg£n Columnas
   LOCAL nHeight:=0 // Alto
   LOCAL nLines :=0 // Lineas
   LOCAL oDlg:=oCxPRes:oDlg

   oCxPRes:oBrw:GoBottom(.T.)

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 BOLD

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\edocuenta.BMP",NIL,"BITMAPS\VIEWG.BMP";
          ACTION oCxPRes:VEREDOCTA();
          WHEN !Empty(oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,3])


   oBtn:cToolTip:="Consultar Estado de Cuenta"
   oCxPRes:oBtnCxc:=oBtn

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\conciliacion.bmp",NIL,"BITMAPS\conciliaciong.bmp";
          ACTION (oCxPRes:cCodigo:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,1],;
                  EJECUTAR("DPDOCPROVIEW",oCxPRes:cCodigo));
          WHEN !Empty(oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,3])

   oBtn:cToolTip:="Autorizacion de Pagos"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\VENCIMIENTOS.BMP",NIL,"BITMAPS\VIEWG.BMP";
          ACTION (oCxPRes:cCodigo:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,1],;
                  EJECUTAR("PROVIEWVEN",oCxPRes:cCodigo));
          WHEN !Empty(oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,5])

   oCxPRes:oBtnVen:=oBtn

   oBtn:cToolTip:="Vencimientos del "+oDp:xDPPROVEEDOR

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\DOCCXP.BMP",NIL,"BITMAPS\VIEWG.BMP";
          ACTION (oCxPRes:cCodigo:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,1],;
                  EJECUTAR("DPDOCPROPENDTE",oCxPRes:cCodigo));
          WHEN !Empty(oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,5])

   oBtn:cToolTip:="Documentos Pendientes "

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\proveedores.bmp",NIL,"BITMAPS\proveedores.bmp";
          ACTION oCxPRes:VERPROVEEDOR();
          WHEN !Empty(oCxPRes:oBrw:aArrayData[1,1])
             
   oBtn:cToolTip:="Consultar Ficha del "+oDp:xDPPROVEEDOR


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          MENU EJECUTAR("BRBTNMENUFILTER",oCxPRes:oBrw,oCxPRes);
          ACTION EJECUTAR("BRWSETFILTER",oCxPRes:oBrw)

   oBtn:cToolTip:="Filtrar Registros"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
          ACTION EJECUTAR("BRWSETOPTIONS",oCxPRes:oBrw);
          WHEN LEN(oCxPRes:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CALENDAR.BMP";
          ACTION LbxDate(oCxPRes:oFecha,oCxPRes:dFecha);
          WHEN !Empty(oCxPRes:oBrw:aArrayData[1,1])


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          ACTION (oCxPRes:HTMLHEAD(),EJECUTAR("BRWTOHTML",oCxPRes:oBrw,NIL,oCxPRes:cTitle,oCxPRes:aHead))

   oBtn:cToolTip:="Generar Archivo html"

   oCxPRes:oBtnHtml:=oBtn



   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\EXCEL.BMP";
          ACTION (EJECUTAR("BRWTOEXCEL",oCxPRes:oBrw,oCxPRes:cTitle,oCxPRes:cNombre))

   oBtn:cToolTip:="Exportar hacia Excel"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XPRINT.BMP";
          ACTION (oCxPRes:oRep:=REPORTE("DPDOCCXPRES"),;
                  oCxPRes:oRep:SetCriterio(1,oCxPRes:cCodSuc),;
                  oCxPRes:oRep:SetCriterio(2,oCxPRes:dFecha))

   oBtn:cToolTip:="Imprimir"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          ACTION (oCxPRes:oBrw:GoTop(),oCxPRes:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xSIG.BMP";
          ACTION (oCxPRes:oBrw:PageDown(),oCxPRes:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xANT.BMP";
          ACTION (oCxPRes:oBrw:PageUp(),oCxPRes:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
          ACTION (oCxPRes:oBrw:GoBottom(),oCxPRes:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION oCxPRes:Close()

  oCxPRes:oBrw:SetColor(0,oCxPRes:nClrPane1)

  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oCxPRes:oBrw:bChange:={||  oCxPRes:oBtnVen:ForWhen(.f.) }

  //
  // Campo : Periodo
  //

  @ 1.0, 082 GET oCxPRes:oFecha  VAR oCxPRes:dFecha;
               SIZE 80,22;
               COLOR CLR_BLACK,CLR_WHITE;
               VALID (oCxPRes:LEERDOCPRO(NIL,oCxPRes:oBrw,NIL,oCxPRes:dFecha),.T.);
               OF oBar;
               SPINNER;
               ON CHANGE EVAL(oCxPRes:oFecha:bValid);
               FONT oFont

  @ oCxPRes:oFecha:nTop,080 SAY "Fecha:" OF oBar BORDER SIZE 34,24

  @ 0.75, 126 BUTTON oCxPRes:oBtn PROMPT " > " SIZE 27,24-2;
              FONT oFont;
              OF oBar;
              ACTION EVAL(oCxPRes:oFecha:bValid)

   oCxPRes:oBar:=oBar

   oCxPRes:oBrw:aCols[3]:cOrder := "A"
   EVAL(oCxPRes:oBrw:aCols[3]:bLClickHeader,NIL,NIL,NIL,oCxPRes:oBrw:aCols[3])

RETURN .T.

/*
// Imprimir
*/
FUNCTION IMPRIMIR(cCodInv)
  LOCAL oRep

//  oRep:=REPORTE("INVCOSULT")
//  oRep:SetRango(1,oCxPRes:cCodInv,oCxPRes:cCodInv)

RETURN .T.

FUNCTION LEERDOCPRO(cWhere,oBrw,cCodSuc,dFecha)
   LOCAL aData:={},aTotal:={}
   LOCAL cSql,cCodSuc:=oDp:cSucursal
   LOCAL nAt,nRowSel

   DEFAULT cCodSuc:=oDp:cSucursal,;
           dFecha :=oDp:dFecha

   cSql  :=" SELECT DOC_CODIGO,PRO_NOMBRE,MIN(DOC_FECHA),MAX(DOC_FECHA),SUM(DOC_CXP*DOC_NETO) AS DOC_NETO, "+;
           " SUM(DOC_MTOIVA*DOC_CXP) AS DOC_MTOIVA, "+;
           " SUM((DOC_NETO *DOC_CXP)   * IF(DOC_FCHVEN"+GetWhere("<=",dFecha)+",1,0)) AS VENCIDO, "+;
           " SUM(DOC_NETO  *DOC_CXP/DOC_VALCAM ) AS DEUDAUSD, "+;
           " SUM((DOC_NETO *DOC_CXP/DOC_VALCAM ) * IF(DOC_FCHVEN"+GetWhere("<=",dFecha)+",1,0)) AS VENCIDOUSD, "+;
           " PRO_TIPO "+;
           " FROM DPDOCPRO "+;
           " INNER JOIN DPPROVEEDOR ON DOC_CODIGO=PRO_CODIGO "+;
           " WHERE DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_CXP<>0 AND DOC_ACT=1 "+;
           "   AND DOC_FECHA" +GetWhere("<=",dFecha )+;
           " GROUP BY DOC_CODIGO,PRO_NOMBRE "+;
           " HAVING SUM(DOC_CXP*DOC_NETO)<>0 "

// ? CLPCOPY(cSql)

   aData:=ASQL(cSql)

   IF EMPTY(aData)
//      AADD(aData,{"","",0,0,0,0})
      aData:=EJECUTAR("SQLARRAYEMPTY",cSql,oDb)
   ENDIF

// ? "AQUI DEBE NO DEBE LLER"
// ? CLPCOPY(cSql)
 
   IF ValType(oBrw)="O"

      aTotal:=ATOTALES(aData)
  
      oBrw:aArrayData:=ACLONE(aData)

//    oBrw:nArrayAt  :=1
//    oBrw:nRowSel   :=1
/*
      oBrw:aCols[3]:cFooter      :=TRAN( aTotal[3+2],"999,999,999,999.99")
      oBrw:aCols[4]:cFooter      :=TRAN( aTotal[4+2],"999,999,999,999.99")
      oBrw:aCols[5]:cFooter      :=TRAN( aTotal[5+2],"999,999,999,999.99")
*/

      EJECUTAR("BRWCALTOTALES",oBrw,.F.)

      nAt    :=oBrw:nArrayAt
      nRowSel:=oBrw:nRowSel

      oBrw:Refresh(.F.)
      oBrw:nArrayAt  :=MIN(nAt,LEN(aData))
      oBrw:nRowSel   :=MIN(nRowSel,oBrw:nRowSel)

      oCxPRes:oBrw:aCols[3]:cOrder:=IIF( oCxPRes:oBrw:aCols[3]:cOrder="A","D","A")

      EVAL(oCxPRes:oBrw:aCols[3]:bLClickHeader,NIL,NIL,NIL,oCxPRes:oBrw:aCols[3])

      oBrw:Refresh(.T.)

   ENDIF

RETURN aData

FUNCTION VERPROVEEDOR()
   LOCAL cCodigo :=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,1]

   EJECUTAR("DPPROVEEDORCON",NIL,cCodigo)

RETURN .T.

FUNCTION VERDOCUMENTO()
   LOCAL cCodigo :=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,3]
   LOCAL cNumero :=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,1]

   EJECUTAR("DPDOCCLIFAVCON",NIL,oCxPRes:cCodSuc,oCxPRes:cTipDoc,cNumero,cCodigo)

RETURN .T.


FUNCTION VEREDOCTA()
   oCxPRes:cCodigo:=oCxPRes:oBrw:aArrayData[oCxPRes:oBrw:nArrayAt,1]
   EJECUTAR("DPDOCPROVIEW",oCxPRes:cCodigo)
RETURN NIL

FUNCTION HTMLHEAD()

   oCxPRes:aHead:=EJECUTAR("HTMLHEAD",oCxPRes)

RETURN



FUNCTION BRWRESTOREPAR()
RETURN EJECUTAR("BRWRESTOREPAR",oCxPRes)
// EOF
