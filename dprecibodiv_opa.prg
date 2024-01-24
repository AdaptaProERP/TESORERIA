// Programa   : DPRECIBODIV_OPA
// Fecha/Hora : 04/03/2023 00:45:14
// Propósito  : OTros Pagos y Otros Ingresos
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv,oFontBrw)
  LOCAL aData:={},oCol
  LOCAL aIva :={},aPorIva:={},oFontB,oFontGrid 

  IF oRecDiv=NIL
     RETURN NIL
  ENDIF

  aIva  :=ASQL("SELECT TIP_CODIGO FROM DPIVATIP WHERE TIP_ACTIVO=1 AND "+IF(oRecDiv:lCliente,"TIP_VENTA=1","TIP_COMPRA=1"))

  IF Empty(aIva)
     aIva:={}
     AADD(aIva,{"GN"})
  ENDIF

  AEVAL(aIva,{|a,n,nIva| nIva:=EJECUTAR("IVACAL",a[1],2,oDp:dFecha),;
                         AADD(aPorIva , nIva) ,;
                         aIva[n]:=a[1]+":"+ TRAN(nIva ,"99.99") })

  DEFINE FONT oFontGrid  NAME "Tahoma" SIZE 0, -14
  DEFINE FONT oFontB     NAME "Tahoma" SIZE 0, -12 BOLD

  AADD(aData,{SPACE(20),oDp:cCenCos,SPACE(12),SPACE(40),0,0,0,0,0})

  oRecDiv:aIva   :=ACLONE(aIva)
  oRecDiv:aPorIva:=ACLONE(aPorIva)

  oRecDiv:oBrwD:=TXBrowse():New( IF(oRecDiv:lTmdi,oRecDiv:oWnd,oRecDiv:oDlg ))

  oRecDiv:oBrwD:SetArray( aData, .F. )


  oRecDiv:oBrwD:oFont       :=oFontGrid 
  oRecDiv:oBrwD:lFooter     := .T.
  oRecDiv:oBrwD:lHScroll    := .F.
  oRecDiv:oBrwD:nHeaderLines:= 2
  oRecDiv:lAcction          :=.F.

  AEVAL(oRecDiv:oBrwD:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

  oCol:=oRecDiv:oBrwD:aCols[1]   
  oCol:cHeader      :="Cuenta de Egreso"
  oCol:oFrm         :=oRecDiv
  oCol:nWidth       :=170-40
  oCol:nEditType    :=EDIT_GET_BUTTON
  oCol:bOnPostEdit  :={|oCol, uValue| oRecDiv:VALCTAEGRE(uValue,NIL,oRecDiv) }
  oCol:bEditBlock   :={|oCol| EJECUTAR("DPRECIBODIV_CTAEGR",NIL,NIL,oRecDiv)}

  oCol:=oRecDiv:oBrwD:aCols[2]   
  oCol:cHeader      :="Centro"+CRLF+"Costo"
  oCol:nWidth       :=080+10
  oCol:nEditType    :=EDIT_GET_BUTTON
  oCol:bEditBlock   :={||oRecDiv:EDITCENCOS()}
  oCol:bOnPostEdit  :={|o, uValue| oRecDiv:VALCENCOSOPA(uValue,NIL,oRecDiv ) }

  oCol:=oRecDiv:oBrwD:aCols[3]  
  oCol:cHeader      :="Referencia"
  oCol:nWidth       :=120-30
  oCol:nEditType    := EDIT_GET
  oCol:bOnPostEdit  :={|o, uValue| oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,3]:=uValue,;
                                    oRecDiv:oBrwD:SelectCol(IF(Empty(uValue),3,4)) }

  oCol:=oRecDiv:oBrwD:aCols[4]  
  oCol:cHeader      :="Descripción"
  oCol:nWidth       :=300-40
  oCol:nEditType    := EDIT_GET
  oCol:bOnPostEdit  :={|o, uValue| oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,4]:=uValue,;
                                   oRecDiv:oBrwD:SelectCol(IF(Empty(uValue),4,5)) }

   oCol:=oRecDiv:oBrwD:aCols[5]   
   oCol:cHeader      :="Base"+CRLF+"Imponible"
   oCol:nWidth       :=170-50
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5],;
                                TRAN(nMonto,"999,999,999,999.99")}

   oCol:cEditPicture :="999,999,999,999.99"
   oCol:nEditType    := EDIT_GET
   oCol:bOnPostEdit  :={|o, uValue| oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5]:=uValue,;
                                    oRecDiv:CALTOTAL(),;
                                    oRecDiv:oBrwD:SelectCol(IF(Empty(uValue),5,6)) }

   oCol:cFooter      :=TRAN(0,"999,999,999,999.99")


   oCol:=oRecDiv:oBrwD:aCols[6]   
   oCol:cHeader      :="% IVA"
   oCol:nWidth       :=55
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,6],;
                                TRAN(nMonto,"99.99")}

   oCol:nEditType      := EDIT_LISTBOX
   oCol:aEditListTxt   := ACLONE(aIva)
   oCol:aEditListBound := ACLONE(aPorIva)
   oCol:bOnPostEdit    := {|o, v| oRecDiv:VALIVA(v), oRecDiv:CALTOTAL()}


   oCol:=oRecDiv:oBrwD:aCols[7]   
   oCol:cHeader      :="Monto"+CRLF+"IVA"
   oCol:nWidth       :=170-50
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7],;
                                TRAN(nMonto,"999,999,999,999.99")}
   oCol:cFooter      :=TRAN(0,"999,999,999,999.99")


   oCol:=oRecDiv:oBrwD:aCols[8]   
   oCol:cHeader      :="Monto"+CRLF+"Neto"
   oCol:nWidth       :=170-50
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,8],;
                                TRAN(nMonto,"999,999,999,999.99")}
   oCol:cFooter      :=TRAN(0,"999,999,999,999.99")


   oCol:=oRecDiv:oBrwD:aCols[9]   
   oCol:cHeader      :="Monto"+CRLF+"Divisa"
   oCol:nWidth       :=170-50
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,9],;
                                TRAN(nMonto,"999,999,999,999.99")}
   oCol:cFooter      :=TRAN(0,"999,999,999,999.99")
   oCol:nEditType    := EDIT_GET
   oCol:cEditPicture :="999,999,999,999.99"
   oCol:bOnPostEdit  :={|o, uValue| oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,9]:=uValue,;
                                    EJECUTAR("DPRECIBODIVOPADIV",oRecDiv)}
   oCol:cFooter      :=TRAN(0,"999,999,999,999.99")


   oRecDiv:oBrwD:bClrStd   := {|oBrw,nClrText,aData|oBrw:=oRecDiv:oBrwD,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                nClrText:=0,;
                                nClrText:=IIF(Empty(aTail(oBrw:aArrayData)[1]),5197647,nClrText),;
                                nClrText:=IIF(aData[5]>0,CLR_HBLUE,nClrText),;
                                nClrText:=IIF(aData[5]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

   oRecDiv:oBrwD:bClrHeader:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oRecDiv:oBrwD:bClrFooter:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


   oRecDiv:oBrwO:=oRecDiv:oBrwD

   oRecDiv:oBrwD:CreateFromCode()

RETURN NIL
// EOF
