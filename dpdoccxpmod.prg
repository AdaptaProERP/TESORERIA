// Programa   : DPDOCCXPMOD
// Fecha/Hora : 10/03/2015 17:21:13
// Propósito  : Modelo de Documento de Cuenta por Pagar
// Creado Por : Juan Navas
// Llamado por: DPACTIVOS
// Aplicación : Ventas
// Tabla      : DPPROVEEDORCTA

#INCLUDE "DPXBASE.CH"
#INCLUDE "SAYREF.CH"

PROCE MAIN(cCodigo,cTipDoc,cTitle,lView)
  LOCAL cSql,aData,cTableD,I,nAt
  LOCAL oBrw,oCol,oFont,oFontG,oFontB,oSayRef,oTable,oBtn
  LOCAL cTable,cNombre

  DEFAULT cCodigo:=SQLGET("DPPROVEEDOR","PRO_CODIGO"),;
          cTitle :="Modelo de Documento de Cuentas por Pagar",;
          lView  :=.F.

  cNombre:=SQLGET("DPPROVEEDOR","PRO_NOMBRE","PRO_CODIGO"+GetWhere("=",cCodigo))
 
  
  cSql:=" SELECT CCD_CODCTA,CTA_DESCRI,CCD_TIPIVA,CCD_MONTO FROM DPDOCPROCTA "+;
        " INNER JOIN DPCTA ON CCD_CODCTA=CTA_CODIGO "+;
        " WHERE CCD_CODIGO"+GetWhere("=",cCodigo)

  aData:=ASQL(cSql)


  DEFINE FONT oFont  NAME "Arial"   SIZE 0, -12 
  DEFINE FONT oFontB NAME "Arial"   SIZE 0, -12 BOLD

  cTitle:=IF(lView,"Consultar","Asignar")+;
          "["+cTitle+"] "

  DPEDIT():New(cTitle,"DPDOCCXCPMOD.EDT","oEditCta",.T.)

  oEditCta:cCodigo   :=cCodigo
  oEditCta:aData     :=ACLONE(aData)
  oEditCta:cNombre   :=cNombre

  oEditCta:lAcction  :=.F.
  oEditCta:cCtaDoc   :=""
  oEditCta:cCtaCxP   :=""
  oEditCta:lView     :=lView  
  oEditCta:cTableD   :=cTableD

  oBrw:=TXBrowse():New( oEditCta:oDlg )

  oBrw:SetArray( aData, .F. )
  oBrw:lHScroll            := .F.
  oBrw:lFooter             := .F.
  oBrw:oFont               :=oFont
  oBrw:nHeaderLines        := 2

  AEVAL(oBrw:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

  oBrw:CreateFromCode()

/*
  oBrw:aCols[1]:cHeader:="Código"+CRLF+"Integración"
  oBrw:aCols[1]:nWidth :=80

  oBrw:aCols[2]:cHeader:="Referencia"
  oBrw:aCols[2]:nWidth :=140

  oBrw:aCols[3]:cHeader   :="Cuenta "
  oBrw:aCols[3]:nWidth    :=180
  oBrw:aCols[3]:nEditType :=IIF( lView, 0, EDIT_GET_BUTTON)
  oBrw:aCols[3]:bEditBlock:={||oEditCta:EditCta(3,.F.)}
  oBrw:aCols[3]:bOnPostEdit:={|oCol,uValue,nKey|oEditCta:ValCta(oCol,uValue,3,nKey)}
  oBrw:aCols[3]:lButton   :=.F.


  oBrw:aCols[4]:cHeader   :="Nombre de la Cuenta "
  oBrw:aCols[4]:nWidth    :=300

  oBrw:aCols[5]:cHeader   :="Fecha"
  oBrw:aCols[5]:nWidth    :=80

  oBrw:aCols[6]:cHeader   :="Hora"
  oBrw:aCols[6]:nWidth    :=80

  oBrw:aCols[7]:cHeader   :="Número"+CRLF+"Usuario"
  oBrw:aCols[7]:nWidth    :=70

  oBrw:aCols[8]:cHeader   :="Nombre"+CRLF+"Usuario"
  oBrw:aCols[8]:nWidth    :=120

*/

  oBrw:bClrHeader:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
  oBrw:bClrFooter:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


  oBrw:bClrStd   :={|oBrw,nMto,nClrText|oBrw:=oEditCta:oBrw,;
                               nClrText:=0,;
                              {nClrText, iif( oBrw:nArrayAt%2=0, 15790320, 16382457 ) } }

  oBrw:bChange:={||NIL}
  oBrw:SetFont(oFont)
  oEditCta:oBrw:=oBrw

  oEditCta:Activate({||oEditCta:BotBarra()})

  DpFocus(oBrw)

  STORE NIL TO oBrw,oDlg

RETURN NIL

FUNCTION EditCta(nCol,lSave)
   LOCAL oBrw  :=oEditCta:oBrw,oLbx
   LOCAL nAt   :=oBrw:nArrayAt
   LOCAL uValue:=oBrw:aArrayData[oBrw:nArrayAt,nCol]

   oLbx:=DpLbx("DPCTA.LBX")
   oLbx:GetValue("CTA_CODIGO",oBrw:aCols[nCol],,,uValue)
   oEditCta:lAcction  :=.T.
   oBrw:nArrayAt:=nAt

   SysRefresh(.t.)


RETURN uValue

FUNCTION ValCta(oCol,uValue,nCol,nKey)
 LOCAL cTipDoc,oTable,cWhere:="",cCtaOld:="",cDescri,aLine:={},cWhere

 DEFAULT nKey:=0

 DEFAULT oCol:lButton:=.F.

 IF oCol:lButton=.T.
    oCol:lButton:=.F.
    RETURN .T.
 ENDIF

 IF !SQLGET("DPCTA","CTA_CODIGO,CTA_DESCRI","CTA_CODIGO"+GetWhere("=",uValue))==uValue
    MensajeErr("Cuenta Contable no Existe")
    EVAL(oCol:bEditBlock)  
    RETURN .F.
 ENDIF

 cDescri:=oDp:aRow[2]

 IF !EJECUTAR("ISCTADET",uValue,.T.)
    EVAL(oCol:bEditBlock)  
    RETURN .F.
 ENDIF

 oEditCta:lAcction  :=.F.

 oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,3]:=uValue
 oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,4]:=cDescri
 oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,5]:=DPFECHA()
 oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,6]:=DPHORA()
 oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt,7]:=oDp:cUsuario

 aLine:=oCol:oBrw:aArrayData[oCol:oBrw:nArrayAt]

 cWhere:="CIC_CODIGO"+GetWhere("=",oEditCta:cCodigo)+" AND "+;
         "CIC_COD2"  +GetWhere("=",oEditCta:cCod2  )+" AND "+;
         "CIC_CODINT"+GetWhere("=",aLine[1])

 oTable:=OpenTable("SELECT * FROM "+oEditCta:cTableD+" WHERE "+cWhere,.T.)

 IF oTable:RecCount()=0
    oTable:Append()
 ELSE
    cWhere:=oTable:cWhere
 ENDIF

 oTable:cPrimary:="CIC_CTAMOD,CIC_CODIGO,CIC_COD2,CIC_CODINT"
 oTable:SetAuditar()
 oTable:Replace("CIC_COD2"  ,oEditCta:cCod2  )
 oTable:Replace("CIC_CODIGO",oEditCta:cCodigo)
 oTable:Replace("CIC_CODINT",aLine[1])
 oTable:Replace("CIC_CUENTA",aLine[3])
 oTable:Replace("CIC_FECHA" ,aLine[5])
 oTable:Replace("CIC_HORA"  ,aLine[6])
 oTable:Replace("CIC_USUARI",aLine[7])
 otable:Replace("CIC_CTAMOD",oDp:cCtaMod)
 oTable:Commit(cWhere)
 oTable:End()

 SysRefresh(.t.)

 oCol:oBrw:DrawLine(.T.)

RETURN .T.

/*
// Consultar la Cuenta
*/

FUNCTION VERCUENTA()
RETURN .T.

FUNCTION QUITAR()
RETURN .T.

/*
// Barra de Botones
*/
FUNCTION BotBarra()
   LOCAL oCursor,oBar,oBtn,oFont

   oEditCta:oBrw:SetColor(0,15790320)
   oEditCta:oBrw:nColSel:=3

   DEFINE FONT oFont  NAME "Arial"   SIZE 0, -12 
   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oEditCta:oDlg 3D CURSOR oCursor

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILE "BITMAPS\CONTABILIDAD.BMP",NIL,"BITMAPS\CONTABILIDADG.BMP";
          WHEN !Empty(oEditCta:oBrw:aArrayData[oEditCta:oBrw:nArrayAt,3]);
          ACTION oEditCta:VERCUENTA()

   oBtn:lCancel :=.T.
   oBtn:cToolTip:="Consultar Cuenta Contable"
   oBtn:cMsg    :=oBtn:cToolTip


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          ACTION EJECUTAR("BRWSETFILTER",oEditCta:oBrw)

   oBtn:cToolTip:="Filtrar Registros"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\OPTIONSG.BMP";
          ACTION EJECUTAR("BRWSETOPTIONS",oEditCta::oBrw);
          WHEN LEN(oEditCta:oBrw:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          ACTION (EJECUTAR("BRWTOHTML",oEditCta:oBrw))

   oBtn:cToolTip:="Generar Archivo html"

   oEditCta:oBtnHtml:=oBtn


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILE "BITMAPS\XPRINT.BMP";
          ACTION oEditCta:IMPRIMIRCTAS()

   oBtn:lCancel :=.T.
   oBtn:cToolTip:="Imprimir Cuentas Contables"
   oBtn:cMsg    :=oBtn:cToolTip


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION  oEditCta:Close()

   oBtn:cToolTip:="Cerrar"

  @ 0.1,40 SAY " "+oEditCta:cCodigo OF oBar BORDER SIZE 395,18
  @ 1.4,40 SAY " "+oEditCta:cNombre OF oBar BORDER SIZE 395,18

  oBar:SetColor(CLR_BLACK,oDp:nGris)
  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  SysRefresh(.t.)

RETURN .T.

FUNCTION VERCUENTA()
  LOCAL cCodCta:=oEditCta:oBrw:aArrayData[oEditCta:oBrw:nArrayAt,3]

  EJECUTAR("DPCTACON",cCodCta)

RETURN NIL

FUNCTION IMPRIMIRCTAS()
  LOCAL oRep:=REPORTE(oEditCta:cTableD)

  IF ValType(oRep)="O"
     oRep:SetRango(1,oEditCta:cCodigo,oEditCta:cCodigo)
  ENDIF

RETURN NIL

// EOF

