// Programa   : DPDOCCXPCHD
// Fecha/Hora : 12/03/2009 18:43:16
// Propósito  : Buscar Cheques Devueltos
// Creado Por : Juan Navas
// Llamado por: DPDOCCXP
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cWhere)
   LOCAL cNumChq,aDataM:={}
   LOCAL oBrwM,oDlgM,oFontBrw,oCol,oFontB,oBtnM,oBrush
   LOCAL nTop:=180,nLeft:=1,nWidth:=735+35,nHeight:=362,I
   LOCAL nClrPane1:=16774636
   LOCAL lSelect:=.F.,nBtnAlto:=25,lResp:=.F.

   LOCAL cNumChq:=SPACE(10),cSql,aData:={}

   DEFAULT cWhere:="MOB_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND "+;
                   "MOB_TIPO  "+GetWhere("=","CHQ"        )+" AND "+;
                   "MOB_ORIGEN"+GetWhere("=","PAG")

   cSql:=" SELECT  PAG_NUMERO,MOB_CODBCO,BAN_NOMBRE,MOB_CUENTA,MOB_DOCUME,MOB_FECHA,MOB_MONTO "+;
         " FROM DPCTABANCOMOV "+;
         " INNER JOIN DPBANCOS   ON MOB_CODBCO=BAN_CODIGO"+;
         " INNER JOIN DPCBTEPAGO ON MOB_CODSUC=PAG_CODSUC AND MOB_DOCASO=PAG_NUMERO "+;
         " WHERE "+cWhere

   aDataM:=ASQL(cSql,.T.)

   IF Empty(aDataM)
      MensajeErr("No hay Datos en Movimiento de Bancos")
      RETURN ""
   ENDIF
   
   DEFINE FONT oFontBrw NAME "MS Sans Serif" SIZE 0, -12 BOLD
   DEFINE FONT oFontB   NAME "MS Sans Serif" SIZE 0, -10 BOLD

   DEFINE BRUSH oBrush;
                FILE "BITMAPS\dpchequespagados.bmp"

   DEFINE DIALOG oDlgM TITLE "Bancos";
          STYLE nOr( WS_POPUP, WS_VISIBLE );
          BRUSH oBrush

   oDlgM:lHelpIcon:=.F.

   oBrwM:=TXBrowse():New(oDlgM )
   oBrwM:SetArray( aDataM ,.T.)
   oBrwM:lHScroll  := .F.
   oBrwM:lVScroll  := .T.
   oBrwM:nFreeze   := 1
   oBrwM:oFont     := oFontBrw
   oBrwM:nDataLines:= 1
   oBrwM:nHeaderLines:= 2
   oBrwM:lFooter   := .F.
   oBrwM:lHeader   := .T.

   oCol:=oBrwM:aCols[1]
   oCol:cHeader:="Cbte"+CRLF+"Pago"
   oCol:nWidth :=70

   oCol:=oBrwM:aCols[2]
   oCol:cHeader:="Codigo"+CRLF+"Banco"
// oCol:bStrData:={||F8(aDataM[oBrwM:nArrayAt,2])}
   oCol:nWidth :=70

   oCol:=oBrwM:aCols[3]
   oCol:cHeader:="Nombre del Banco"
   oCol:nWidth :=160

   oCol:=oBrwM:aCols[4]
   oCol:cHeader:="Cuenta"+CRLF+"Bancaria"
   oCol:nWidth :=120

   oCol:=oBrwM:aCols[5]
   oCol:cHeader:="Número"+CRLF+"Cheque"
   oCol:nWidth :=100

   oCol:=oBrwM:aCols[6]
   oCol:cHeader:="Fecha"+CRLF+"Depósito"
   oCol:bStrData:={||F8(aDataM[oBrwM:nArrayAt,6])}
   oCol:nWidth :=76

   oCol:=oBrwM:aCols[7]
   oCol:cHeader :="Monto"
   oCol:nWidth  :=100
   oCol:bStrData:={||TRAN(aDataM[oBrwM:nArrayAt,7],"99,999,999,999.99")}
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT

// oCol:=oBrwM:aCols[8]
// oCol:cHeader :="Monto"
// oCol:nWidth  :=105
// oBrwM:DelCol(8)
// oBrwM:DelCol(8)

   oBrwM:bClrStd      := {||{CLR_BLUE, iif( oBrwM:nArrayAt%2=0,16770764,16774636 ) } }
   oBrwM:bClrHeader   := {||{CLR_YELLOW,16764315}}
   oBrwM:bLDblClick   := {||SelCheque()}
   oBrwM:bKeyDown     := {|nKey| oBrwM:nLastKey:=nKey,;
                                IIF( nKey=13,SelCheque(),NIL) }

    oBrwM:CreateFromCode()

   @ 06, 200+(1+(3*nBtnAlto));
             SBUTTON oBtnM PIXEL;
             SIZE nBtnAlto,nBtnAlto FONT oFontB;
             NOBORDER;
             FILE "BITMAPS\BOTONUP.BMP";
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION oBrwM:GoUp()

    oBtnM:cToolTip:="Subir"

   @ 06, 200+(1+(4*nBtnAlto));
             SBUTTON oBtnM PIXEL;
             SIZE nBtnAlto,nBtnAlto FONT oFontB;
             NOBORDER;
             FILE "BITMAPS\BOTONDOWN.BMP";
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION oBrwM:GoDown()

   oBtnM:cToolTip:="Bajar"

   @ 06, 200+(1+(5*nBtnAlto));
             SBUTTON oBtnM PIXEL;
             SIZE nBtnAlto,nBtnAlto FONT oFontB;
             FILE "BITMAPS\XFIND.BMP";
             NOBORDER;
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION EJECUTAR("BRWSETFIND",oBrwM)

   oBtnM:cToolTip:="Buscar"

   @ 06, 200+(1+(6*nBtnAlto));
              SBUTTON oBtnM PIXEL;
              SIZE nBtnAlto,nBtnAlto FONT oFontB;
              FILE "BITMAPS\XSALIR.BMP";
              NOBORDER;
              COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
              ACTION oDlgM:End()

   oBtnM:cToolTip:="Salir"


   ACTIVATE DIALOG oDlgM ON INIT (oDlgM:Move(nTop,nLeft,nWidth,nHeight,.T.),;
                                  oBrwM:Move(20+(nBtnAlto*2),10,nWidth-20,nHeight-084,.T.),;
                                  oBrwM:SetColor(NIL,nClrPane1),oBrwM:GoBottom(.T.))
 

RETURN lResp

FUNCTION SELCHEQUE()
  LOCAL aLine:=aDataM[oBrwM:nArrayAt]

  IF TYPE("oDlg")="O"

     oCheque:VarPut(aLine[3+2],.T.)
     oMonto:VarPut(aLine[7],.T.)

     oBanco:VarPut(aLine[2],.T.)
     oBcoNombre:Refresh(.T.)

     oCuenta:VarPut(aLine[4],.T.)
     oCuenta:Refresh(.T.)

  ENDIF

  oDlgM:End()

RETURN .T.
// EOF


