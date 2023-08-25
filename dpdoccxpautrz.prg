// Programa   : DPDOCCXPAUTRZ
// Fecha/Hora : 18/04/2012 08:12:09
// Propósito  : Resumen de Documentos por Cliente
// Creado Por : Juan Navas
// Llamado por: DPMENU
// Aplicación : Gerencia 
// Tabla      : DPTIPDOCPRO

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,dFecha,lData,lMsg)
   LOCAL cSql
   LOCAL aData,cTitle

   DEFAULT cCodSuc:=oDp:cSucursal,;
           dFecha :=oDp:dFecha   ,;
           lData  :=.F.          ,;
           lMsg   :=.T.

   cTitle:="Nómina de Cuentas por Pagar por "+oDp:xDPPROVEEDOR+" Con Autorizaciones de Pago"

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

//   DPEDIT():New(cTitle,"DPDOCCXPAUTRZ.EDT","oCxoAtrz",.T.)

   DpMdi(cTitle,"oCxoAtrz","DPDOCCXPAUTRZ.EDT")
   oCxoAtrz:Windows(0,0,aCoors[3]-160,MIN(584+200,aCoors[4]-10),.T.) // Maximizado


   oCxoAtrz:cCodSuc :=oDp:cSucursal
   oCxoAtrz:lMsgBar :=.F.
   oCxoAtrz:cCodSuc :=cCodSuc
   oCxoAtrz:cTipDoc :=cTipDoc
   oCxoAtrz:dFecha  :=oDp:dFecha
   oCxoAtrz:cNombre :="Hasta el "+DTOC(oDp:dFecha)

   oCxoAtrz:dDesde  :=dDesde
   oCxoAtrz:dHasta  :=dHasta

   oCxoAtrz:oBrw:=TXBrowse():New( oCxoAtrz:oDlg )
   oCxoAtrz:oBrw:SetArray( aData, .T. )
   oCxoAtrz:oBrw:SetFont(oFont)

   oCxoAtrz:oBrw:lFooter     := .T.
   oCxoAtrz:oBrw:lHScroll    := .F.
   oCxoAtrz:oBrw:nHeaderLines:= 2
   oCxoAtrz:oBrw:lFooter     :=.T.

   oCxoAtrz:aData            :=ACLONE(aData)
  oCxoAtrz:nClrText :=0
  oCxoAtrz:nClrPane1:=oDp:nClrPane1
  oCxoAtrz:nClrPane2:=oDp:nClrPane2

   AEVAL(oCxoAtrz:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   oCol:=oCxoAtrz:oBrw:aCols[1]   
   oCol:cHeader      :="Código"+CRLF+oDp:xDPCLIENTES
   oCol:nWidth       :=080

   oCol:=oCxoAtrz:oBrw:aCols[2]
   oCol:cHeader      :="Nombre del "+CRLF+oDp:xDPCLIENTES
   oCol:nWidth       :=260

   oCol:=oCxoAtrz:oBrw:aCols[3]   
   oCol:cHeader      :="Deuda"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,3],;
                                TRAN(nMonto,"999,999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[3],"999,999,999,999,999.99")

   oCol:=oCxoAtrz:oBrw:aCols[4]   
   oCol:cHeader      :="I.V.A por Pagar"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,4],;
                                TRAN(nMonto,"999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[4],"999,999,999,999,999.99")


   oCol:=oCxoAtrz:oBrw:aCols[5]   
   oCol:cHeader      :="Vencido"
   oCol:nWidth       :=130
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,5],;
                                TRAN(nMonto,"999,999,999,999,999.99")}
   oCol:cFooter      :=TRAN( aTotal[5],"999,999,999,999,999.99")


   oCxoAtrz:oBrw:bClrStd               := {|oBrw,nClrText,aData|oBrw:=oCxoAtrz:oBrw,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                           oCxoAtrz:nClrText,;
                                          {nClrText,iif( oBrw:nArrayAt%2=0, oCxoAtrz:nClrPane1, oCxoAtrz:nClrPane2 ) } }


   oCxoAtrz:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oCxoAtrz:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


   oCxoAtrz:oBrw:bLDblClick:={|oBrw|oCxoAtrz:oRep:=oCxoAtrz:VERPROVEEDOR() }

   oCxoAtrz:oBrw:CreateFromCode()
   oCxoAtrz:bValid   :={|| EJECUTAR("BRWSAVEPAR",oCxoAtrz)}
   oCxoAtrz:BRWRESTOREPAR()

   oCxoAtrz:oWnd:oClient := oCxoAtrz:oBrw


   oCxoAtrz:Activate({||oCxoAtrz:ViewDatBar(oCxoAtrz)})

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar(oCxoAtrz)
   LOCAL oCursor,oBar,oBtn,oFont,oCol,nDif
   LOCAL nWidth :=0 // Ancho Calculado seg£n Columnas
   LOCAL nHeight:=0 // Alto
   LOCAL nLines :=0 // Lineas
   LOCAL oDlg:=oCxoAtrz:oDlg

   oCxoAtrz:oBrw:GoBottom(.T.)

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   DEFINE FONT oFont  NAME "Arial"   SIZE 0, -12 BOLD

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\edocuenta.BMP",NIL,"BITMAPS\VIEWG.BMP";
          ACTION (oCxoAtrz:cCodigo:=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,1],;
                  EJECUTAR("DPDOCPROVIEW",oCxoAtrz:cCodigo));
          WHEN !Empty(oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,3])


   oBtn:cToolTip:="Consultar Estado de Cuenta"
   oCxoAtrz:oBtnCxc:=oBtn

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\VENCIMIENTOS.BMP",NIL,"BITMAPS\VIEWG.BMP";
          ACTION (oCxoAtrz:cCodigo:=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,1],;
                  EJECUTAR("PROVIEWVEN",oCxoAtrz:cCodigo));
          WHEN !Empty(oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,5])

   oCxoAtrz:oBtnVen:=oBtn

   oBtn:cToolTip:="Vencimientos del "+oDp:xDPCLIENTES

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\DOCCXP.BMP",NIL,"BITMAPS\VIEWG.BMP";
          ACTION (oCxoAtrz:cCodigo:=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,1],;
                  EJECUTAR("DPDOCPROPENDTE",oCxoAtrz:cCodigo));
          WHEN !Empty(oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,5])

   oBtn:cToolTip:="Documentos Pendientes "

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\proveedores.bmp",NIL,"BITMAPS\proveedores.bmp";
          ACTION oCxoAtrz:oRep:=oCxoAtrz:VERPROVEEDOR();
          WHEN !Empty(oCxoAtrz:oBrw:aArrayData[1,1])
             
   oBtn:cToolTip:="Consultar Ficha del "+oDp:xDPPROVEEDOR

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CALENDAR.BMP";
          ACTION LbxDate(oCxoAtrz:oFecha,oCxoAtrz:dFecha);
          WHEN !Empty(oCxoAtrz:oBrw:aArrayData[1,1])

// Inactivado por TJ mientras revisamos la Incidencia que da al darle al boton
/*
   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XPRINT.BMP";
          ACTION (oCxoAtrz:oRep:=REPORTE("DPDOCCXPRES"),;
                  oCxoAtrz:oRep:SetCriterio(1,oCxoAtrz:cCodSuc),;
                  oCxoAtrz:oRep:SetCriterio(2,oCxoAtrz:dFecha))

   oBtn:cToolTip:="Imprimir"
*/

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\EXCEL.BMP";
          ACTION (EJECUTAR("BRWTOEXCEL",oCxoAtrz:oBrw,oCxoAtrz:cTitle,oCxoAtrz:cNombre))

   oBtn:cToolTip:="Exportar hacia Excel"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          ACTION (oCxoAtrz:oBrw:GoTop(),oCxoAtrz:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xSIG.BMP";
          ACTION (oCxoAtrz:oBrw:PageDown(),oCxoAtrz:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xANT.BMP";
          ACTION (oCxoAtrz:oBrw:PageUp(),oCxoAtrz:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
          ACTION (oCxoAtrz:oBrw:GoBottom(),oCxoAtrz:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION oCxoAtrz:Close()

  oCxoAtrz:oBrw:SetColor(0,oCxoAtrz:nClrPane1)

  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oCxoAtrz:oBrw:bChange:={||  oCxoAtrz:oBtnVen:ForWhen(.f.) }

  //
  // Campo : Periodo
  //

  @ 1.0, 082 GET oCxoAtrz:oFecha  VAR oCxoAtrz:dFecha;
               SIZE 80,22;
               COLOR CLR_BLACK,CLR_WHITE;
               VALID (oCxoAtrz:LEERDOCPRO(NIL,oCxoAtrz:oBrw,NIL,oCxoAtrz:dFecha),.T.);
               OF oBar;
               SPINNER;
               ON CHANGE EVAL(oCxoAtrz:oFecha:bValid);
               FONT oFont

  @ oCxoAtrz:oFecha:nTop,080 SAY "Fecha:" OF oBar BORDER SIZE 34,24

  @ 0.75, 126 BUTTON oCxoAtrz:oBtn PROMPT " > " SIZE 27,24-2;
              FONT oFont;
              OF oBar;
              ACTION EVAL(oCxoAtrz:oFecha:bValid)

   oCxoAtrz:oBar:=oBar

   oCxoAtrz:oBrw:aCols[3]:cOrder := "A"
   EVAL(oCxoAtrz:oBrw:aCols[3]:bLClickHeader,NIL,NIL,NIL,oCxoAtrz:oBrw:aCols[3])

RETURN .T.

/*
// Imprimir
*/
FUNCTION IMPRIMIR(cCodInv)
  LOCAL oRep

//  oRep:=REPORTE("INVCOSULT")
//  oRep:SetRango(1,oCxoAtrz:cCodInv,oCxoAtrz:cCodInv)

RETURN .T.

FUNCTION LEERDOCPRO(cWhere,oBrw,cCodSuc,dFecha)
   LOCAL aData:={},aTotal:={}
   LOCAL cSql,cCodSuc:=oDp:cSucursal

   DEFAULT cCodSuc:=oDp:cSucursal,;
           dFecha :=oDp:dFecha

   cSql  :=" SELECT DOC_CODIGO,PRO_NOMBRE, "+;
           " SUM(IF ((DOC_TIPTRA ='D' OR DOC_TIPTRA ='P') AND DOC_CXP=1,DOC_NETO,0)) - SUM(IF((DOC_TIPTRA ='P' OR DOC_TIPTRA ='D') AND DOC_CXP =-1,DOC_NETO,0)) AS DOC_NETO, " +;
           " SUM(IF ((DOC_TIPTRA ='D' OR DOC_TIPTRA ='P') AND DOC_CXP=1,DOC_MTOIVA,0)) - SUM(IF((DOC_TIPTRA ='P' OR DOC_TIPTRA ='D') AND DOC_CXP =-1,DOC_MTOIVA,0)) AS IVA, " +;
		 " (SUM(IF ((DOC_TIPTRA ='D' OR DOC_TIPTRA ='P') AND DOC_CXP=1,DOC_NETO,0)) - SUM(IF((DOC_TIPTRA ='P' OR DOC_TIPTRA ='D') AND DOC_CXP =-1,DOC_NETO,0)) * IF(DOC_FCHVEN"+GetWhere("<=",dFecha)+",1,0 )) AS VENCIDO " +;          
           " FROM DPDOCPRO "+;
           " INNER JOIN DPPROVEEDOR ON DOC_CODIGO=PRO_CODIGO "+;
           " WHERE DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_CXP<>0 AND DOC_ACT=1 "+;
           "   AND DOC_FECHA" +GetWhere("<=",dFecha )+;
           " GROUP BY DOC_CODIGO,PRO_NOMBRE "+;
           "  HAVING SUM(IF ((DOC_TIPTRA ='D' OR DOC_TIPTRA ='P') AND DOC_CXP=1,DOC_NETO,0)) - SUM(IF((DOC_TIPTRA ='P' OR DOC_TIPTRA ='D') AND DOC_CXP =-1,DOC_NETO,0)) <>0 "

   aData:=ASQL(cSql)

   IF EMPTY(aData)
      AADD(aData,{"","",0,0,0,0})
   ENDIF
 
   IF ValType(oBrw)="O"

      aTotal:=ATOTALES(aData)
  
      oBrw:aArrayData:=ACLONE(aData)
      oBrw:nArrayAt  :=1
      oBrw:nRowSel   :=1

      oBrw:aCols[3]:cFooter      :=TRAN( aTotal[3],"999,999,999,999,999.99")
      oBrw:aCols[4]:cFooter      :=TRAN( aTotal[4],"999,999,999,999,999.99")
      oBrw:aCols[5]:cFooter      :=TRAN( aTotal[5],"999,999,999,999,999.99")

      oCxoAtrz:oBrw:aCols[3]:cOrder:=IIF( oCxoAtrz:oBrw:aCols[3]:cOrder="A","D","A")

      EVAL(oCxoAtrz:oBrw:aCols[3]:bLClickHeader,NIL,NIL,NIL,oCxoAtrz:oBrw:aCols[3])

      oBrw:Refresh(.T.)

   ENDIF

RETURN aData

FUNCTION VERPROVEEDOR()
   LOCAL cCodigo :=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,1]

   EJECUTAR("DPPROVEEDORCON",NIL,cCodigo)

RETURN .T.

FUNCTION VERDOCUMENTO()
   LOCAL cCodigo :=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,3]
   LOCAL cNumero :=oCxoAtrz:oBrw:aArrayData[oCxoAtrz:oBrw:nArrayAt,1]

   EJECUTAR("DPDOCCLIFAVCON",NIL,oCxoAtrz:cCodSuc,oCxoAtrz:cTipDoc,cNumero,cCodigo)

RETURN .T.



 FUNCTION BRWRESTOREPAR()
 RETURN EJECUTAR("BRWRESTOREPAR",oCxoAtrz)
// EOF
