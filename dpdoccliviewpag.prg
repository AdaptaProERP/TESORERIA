// Programa   : DPDOCCLIVIEWPAG
// Fecha/Hora : 16/02/2004 16:39:12
// Propósito  : Consultar los Pagos de una Factura
// Creado Por : Juan Navas
// Llamado por: DPDOCCLI
// Aplicación : Ventas
// Tabla      : DPDOCCLI

#INCLUDE "INCLUDE\DPXBASE.CH"
#INCLUDE "SAYREF.CH"


PROCE MAIN(cCodSuc,cTipDoc,cCodigo,cNumero,cMemo)
  LOCAL oBrw,oFontBrw,oFontB,oCol,nTotal:=0,oSayRef,oBtn
  LOCAL cWhere,aData,cSql,oTable,cNombre,dFecha,dFchVen,nNeto
  LOCAL cTitle:="Pagos de ",nMonto:=0,nMtoDiv:=0,cCodMon

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cTipDoc:="FAV",;
          cNumero:=SQLGET("DPDOCCLI","DOC_NUMERO","DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","P")+" ORDER BY DOC_NUMERO DESC LIMIT 1" ),;
          cCodigo:=SQLGET("DPDOCCLI","DOC_CODIGO","DOC_NUMERO"+GetWhere("=",cNumero))

  cTitle:=cTitle+ALLTRIM(MySQLGET("DPTIPDOCCLI","TDC_DESCRI","TDC_TIPO"+GetWhere("=",cTipDoc)))+;
          " "+cNumero

  nNeto :=SQLGET("DPDOCCLI","DOC_NETO,DOC_NETO/DOC_VALCAM AS DOC_MTODIV,DOC_CODMON","DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                                       "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                                       "DOC_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
                                       "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
                                       "DOC_TIPTRA"+GetWhere("=","D"    )+" AND "+;
                                       "DOC_ACT   =1")

  nMtoDiv:=DPSQLROW(2,0)
  cCodMon:=DPSQLROW(3,0)
  nMonto :=nNeto


// ? CLPCOPY(oDp:cSql)


  oTable:=OpenTable([ SELECT DOC_RECNUM,DOC_FECHA,DOC_HORA,REC_CODCOB,VEN_NOMBRE,DOC_NETO,DOC_MTOCOM,DOC_NETO+DOC_MTOCOM AS MTOPAGO,0 AS RATA, 0 AS SALDO,DOC_VALCAM,(DOC_NETO+DOC_MTOCOM)/DOC_VALCAM AS DOC_MTODIV ]+;
                    [ FROM DPDOCCLI ]+;
                    [ INNER JOIN DPRECIBOSCLI ON DOC_RECNUM=REC_NUMERO AND DOC_CODSUC=REC_CODSUC ]+;
                    [ LEFT JOIN DPVENDEDOR ON REC_CODCOB=VEN_CODIGO ]+;
                    [ WHERE DOC_CODSUC]+GetWhere("=",cCodSuc)+;
                    [  AND DOC_TIPDOC ]+GetWhere("=",cTipDoc)+;
                    [  AND DOC_CODIGO ]+GetWhere("=",cCodigo)+;
                    [  AND DOC_NUMERO ]+GetWhere("=",cNumero)+;
                    [  AND DOC_TIPTRA ]+GetWhere("=","P"    )+;
                    [  AND DOC_ACT   =1] +;
                    [  ORDER BY DOC_FECHA,DOC_HORA ],.T.)

 
  oTable:Replace("RATA" ,0)
  oTable:Replace("SALDO",0)

  WHILE !oTable:Eof()
    nNeto:=nNeto-(oTable:DOC_NETO+0)
    oTable:Replace("SALDO",nNeto)
    oTable:Replace("RATA" ,RATA(oTable:DOC_NETO,nMonto))
    oTable:DbSkip()
  ENDDO

//oTable:Browse()
  aData:=ACLONE(oTable:aDataFill)

  IF Empty(aData)
     MensajeErr("Información no Fué Encontrada")
     RETURN .F.
  ENDIF


  ViewData(aData,cCodigo,cTitle)
              
RETURN .T.

FUNCTION ViewData(aData,cCodCli,cTitle)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData),cNombre:="ASADFA"
   LOCAL I
   LOCAL cSql,oTable
   LOCAL oFont,oFontB
   LOCAL nDebe:=0,nHaber:=0
   LOCAL aCoors:=GetCoors( GetDesktopWindow() )

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 
   DEFINE FONT oFontB NAME "Tahoma"   SIZE 0, -12 BOLD

   cNombre:=MYSQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",cCodCli))

// oPagView:=DPEDIT():New(cTitle,"DPDOCCLIVIEWPAG.EDT","oPagView",.T.)

   DpMdi(cTitle,"oPagView","DPDOCCLIVIEWPAG.EDT")
   oPagView:Windows(0,0,aCoors[3]-160,MIN(aCoors[4]-10,900),.T.) // Maximizado

   oPagView:cCodCli :=cCodCli
   oPagView:cNombre :=cNombre
   oPagView:cNumero :=cNumero
   oPagView:cTipDoc :=cTipDoc
   oPagView:cCodSuc :=cCodSuc
   oPagView:lMsgBar :=.F.
   oPagView:nNeto   :=nMonto
   oPagView:nMtoDiv :=nMtoDiv
   oPagView:cCodMon :=cCodMon

   oPagView:nClrPane1:=16772055
   oPagView:nClrPane2:=16774636

   oPagView:oBrw:=TXBrowse():New( oPagView:oWnd )
   oPagView:oBrw:SetArray( aData, .F. )
   oPagView:oBrw:SetFont(oFont)
   oPagView:oBrw:lFooter     := .T.
   oPagView:oBrw:lHScroll    := .F.
   oPagView:oBrw:nHeaderLines:= 3
   oPagView:oBrw:lFooter     :=.T.

   oPagView:cCodCli  :=cCodCli
   oPagView:cNombre  :=cNombre
   oPagView:aData    :=ACLONE(aData)

   AEVAL(oPagView:oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   oCol:=oPagView:oBrw:aCols[1]   
   oCol:cHeader      :="Recibo"
   oCol:nWidth       :=065

   oCol:=oPagView:oBrw:aCols[2]
   oCol:cHeader      :="Fecha"
   oCol:nWidth       :=70

   oCol:=oPagView:oBrw:aCols[3]
   oCol:cHeader      :="Hora"
   oCol:nWidth       :=60

   oCol:=oPagView:oBrw:aCols[4]
   oCol:cHeader      :="Cod"+CRLF+"Cob"
   oCol:nWidth       :=60

   oCol:=oPagView:oBrw:aCols[5]
   oCol:cHeader      :="Cobrador"
   oCol:nWidth       :=170

   oCol:=oPagView:oBrw:aCols[6]  
   oCol:cHeader      :="Monto"+CRLF+"Pago"
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:nWidth       :=100
   oCol:bStrData     :={|nMonto|nMonto:=oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt,6],;
                                TRAN(nMonto,"99,999,999,999.99")}

   oCol:cFooter      :=TRAN(aTotal[6],"99,999,999,999.99")

   oCol:=oPagView:oBrw:aCols[7]  
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cHeader      :="Diferencial"+CRLF+"Cambiario"
   oCol:nWidth       :=100
   oCol:cEditPicture :='999,999,999,999,999.99'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt,7],;
                         oCol  := oPagView:oBrw:aCols[7],;
                         FDP(nMonto,oCol:cEditPicture)}
// oCol:lAvg         :=.T.
   oCol:cFooter      :=TRAN(RATA(aTotal[7],nNeto),oCol:cEditPicture)


   oCol:=oPagView:oBrw:aCols[8]  
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cHeader      :="Pago"+CRLF+"Diferencia"+CRLF+"Cambiario"
   oCol:nWidth       :=100
   oCol:cEditPicture :='9,999,999,999,999.99'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt,8],;
                         oCol  := oPagView:oBrw:aCols[8],;
                         FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[8],oCol:cEditPicture)

   oCol:=oPagView:oBrw:aCols[9]  
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cHeader      :="%"+CRLF+"Prop."
   oCol:nWidth       :=100
   oCol:cEditPicture :='9,999,999,999.99'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt,9],;
                         oCol  := oPagView:oBrw:aCols[9],;
                         FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[9],oCol:cEditPicture)
   oCol:lAvg         :=.F.

   oCol:=oPagView:oBrw:aCols[9+1]  
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cHeader      :="Saldo"
   oCol:nWidth       :=100
   oCol:cEditPicture :='999,999,999,999,999.99'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt,9+1],;
                         oCol  := oPagView:oBrw:aCols[9+1],;
                         FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[9+1],oCol:cEditPicture)


   oCol:=oPagView:oBrw:aCols[10+1]  
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cHeader      :="Valor"+CRLF+"Divisa"
   oCol:nWidth       :=100
   oCol:cEditPicture :='99,999,999,999.99'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt,10+1],;
                         oCol  := oPagView:oBrw:aCols[10+1],;
                         FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[10+1],oCol:cEditPicture)

   oCol:=oPagView:oBrw:aCols[10+2]  
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:cHeader      :="Pago"+CRLF+"Calculado"+CRLF+"en Divisa"
   oCol:nWidth       :=100
   oCol:cEditPicture :='99,999,999,999.99'
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt,10+2],;
                         oCol  := oPagView:oBrw:aCols[10+1],;
                         FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[10+2],oCol:cEditPicture)





   oPagView:oBrw:bClrStd               := {|oBrw,nClrText,aData|oBrw:=oPagView:oBrw,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                           nClrText:=0,;
                                          {nClrText,iif( oBrw:nArrayAt%2=0, oPagView:nClrPane2, oPagView:nClrPane1) } }

   oPagView:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oPagView:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


 
   FOR I=1 TO LEN(oPagView:oBrw:aCols)
       oPagView:oBrw:aCols[I]:bLClickFooter:=oCol:bLClickFooter
   NEXT I

   oPagView:oBrw:CreateFromCode()
   oPagView:bValid   :={|| EJECUTAR("BRWSAVEPAR",oPagView)}
   

   oPagView:oWnd:oClient := oPagView:oBrw


   oPagView:oBrw:bLDblClick:={|oBrw|oPagView:RUNCLICK() }

   oPagView:Activate({||oPagView:ViewDatBar(oPagView)})

   EJECUTAR("BRWCALTOTALES",oPagView:oBrw)
   oPagView:BRWRESTOREPAR()

RETURN .T.

/*
// Barra de Botones
*/
FUNCTION ViewDatBar(oPagView)
   LOCAL oCursor,oBar,oBtn,oFont,oCol,nDif
   LOCAL nWidth :=0 // Ancho Calculado seg£n Columnas
   LOCAL nHeight:=0 // Alto
   LOCAL nLines :=0 // Lineas
   LOCAL oDlg:=oPagView:oDlg

   oPagView:oBrw:GoBottom(.T.)

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -10 BOLD

   DEFINE CURSOR oCursor HAND

   IF !oDp:lBtnText 
     DEFINE BUTTONBAR oBar SIZE 52,60 OF oDlg 3D CURSOR oCursor
   ELSE 
     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth,oDp:nBarnHeight+6 OF oDlg 3D CURSOR oCursor 
   ENDIF 


// IF oDp:nVersion>=5

   oPagView:oFontBtn   :=oFont    
   oPagView:nClrPaneBar:=oDp:nGris
   oPagView:oBrw:oLbx  :=oPagView

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\RECIBIRDINERO.BMP";
          TOP PROMPT "Consultar";
          ACTION oPagView:RUNCLICK()

   oBtn:cToolTip:="Consultar Recibo"


  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XEDIT.BMP",NIL,"BITMAPS\XEDITG.BMP";
          TOP PROMPT "Modificar";
          ACTION oPagView:DOCCLIRUNEDIT(.T.)

   oBtn:cToolTip:="Modificar Recibo"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\MENU.BMP";
          TOP PROMPT "Menú";
          ACTION oPagView:DPRECIBOCLIMNU()

   oBtn:cToolTip:="Menú de Opciones"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XPRINT.BMP";
          TOP PROMPT "Imprimir"; 
              ACTION  (oDp:oRep:=REPORTE("DOCCLIPAG"),;
                  oDp:oRep:SetRango(1,oPagView:cCodCli,oPagView:cCodCli),;
                  oDp:oRep:SetRango(2,oPagView:cNumero,oPagView:cNumero),;
                  oDp:oRep:SetCriterio(1,oPagView:cCodSuc),;
                  oDp:oRep:SetCriterio(2,oPagView:cTipDoc))

   oBtn:cToolTip:="Listado de Pagos"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\EXCEL.BMP";
          TOP PROMPT "Excel"; 
          ACTION  (EJECUTAR("BRWTOEXCEL",oPagView:oBrw,oPagView:cTitle,oPagView:cNombre))

   oBtn:cToolTip:="Exportar hacia Excel"


  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          TOP PROMPT "Html"; 
          ACTION  (oPagView:HTMLHEAD(),EJECUTAR("BRWTOHTML",oPagView:oBrw,NIL,oPagView:cTitle,oPagView:aHead))

   oBtn:cToolTip:="Generar Archivo html"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          TOP PROMPT "Primero"; 
          ACTION  (oPagView:oBrw:GoTop(),oPagView:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xSIG.BMP";
          TOP PROMPT "Avance"; 
          ACTION  (oPagView:oBrw:PageDown(),oPagView:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xANT.BMP";
          TOP PROMPT "Anterior"; 
          ACTION  (oPagView:oBrw:PageUp(),oPagView:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
          TOP PROMPT "Ultimo"; 
          ACTION  (oPagView:oBrw:GoBottom(),oPagView:oBrw:Setfocus())

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          TOP PROMPT "Cerrar"; 
          ACTION  oPagView:Close()

  oPagView:oBrw:SetColor(0,oPagView:nClrPane2)

  oBar:SetColor(CLR_BLACK,oDp:nGris)
  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oBar:SetSize(NIL,115)

  @ 4.3+0.1,55-55+4 SAY " "+oPagView:cCodCli OF oBar BORDER SIZE 100,20 COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont
  @ 4.3+1.5,55-55+4 SAY " "+oPagView:cNombre OF oBar BORDER SIZE 345,20 COLOR oDp:nClrYellowText,oDp:nClrYellow FONT oFont

  @ 4.3+0.1,55-55+63 SAY "Neto "+oDp:cMoneda OF oBar BORDER SIZE 52,20 COLOR oDp:nClrLabelText,oDp:nClrLabelPane RIGHT FONT oFont
  @ 4.3+0.1,55-55+72 SAY TRAN(oPagView:nNeto,"999,999,999,999.99") OF oBar BORDER SIZE 125,18 COLOR oDp:nClrYellowText,oDp:nClrYellow RIGHT FONT oFont

  @ 4.3+1.5,55-55+63 SAY oPagView:cCodMon OF oBar BORDER SIZE 52,20 COLOR oDp:nClrYellowText,oDp:nClrYellow RIGHT FONT oFont
  @ 4.3+1.5,55-55+72 SAY TRAN(oPagView:nMtoDiv,"999,999,999,999.99") OF oBar BORDER SIZE 125,18 COLOR oDp:nClrYellowText,oDp:nClrYellow RIGHT FONT oFont

RETURN .T.

FUNCTION BRWRESTOREPAR()
RETURN EJECUTAR("BRWRESTOREPAR",oPagView)

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()
  LOCAL aLine:=oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt]

  EJECUTAR("DPRECIBOSCLI",.F.,NIL,oPagView:cCodSuc,NIL,"REC_NUMERO"+GetWhere("=",aLine[1]),.T.)


RETURN .T.


FUNCTION HTMLHEAD()

   oPagView:aHead:=EJECUTAR("HTMLHEAD",oPagView)

// Ejemplo para Agregar mas Parámetros
//   AADD(oDOCPROISLR:aHead,{"Consulta",oDOCPROISLR:oWnd:cTitle})

RETURN

FUNCTION DOCCLIRUNEDIT(lEdit)
   LOCAL aLine:=oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt]
   EJECUTAR("DPRECIBOSDIV_EDIT",oPagView:cCodSuc,aLine[1],lEdit)
RETURN .T.

FUNCTION DPRECIBOCLIMNU()
   LOCAL aLine:=oPagView:oBrw:aArrayData[oPagView:oBrw:nArrayAt]
RETURN EJECUTAR("DPRECIBOCLIMNU",oPagView:cCodSuc,aLine[1])
// EOF
