// Programa   : DPCBTEPAGOX
// Fecha/Hora : 24/11/2005 17:45:20
// Propósito  : Comprobantes de Pago
// Creado Por : Juan Navas
// Llamado por: DPMENU
// Aplicación : Ventas 
// Tabla      : DPCBTEPAGO Version X (Evaluacion)

#INCLUDE "DPXBASE.CH"
#INCLUDE "SAYREF.CH"

PROCE MAIN(lAuto,cTipPag,cCodSuc,cCodPro,cRecord,lView,cCenCos,cCodMon,nValCam)
  LOCAL cTitle:="",cScope:="PAG_CODSUC"+GetWhere("=",oDp:cSucursal)
  LOCAL oSayRef,oFontB,oBrw,oCol,oFontGrid,oFont,oFontOtr,oData,cForm,nAt
  LOCAL aTipPag:=GETOPTIONS("DPCBTEPAGO","PAG_TIPPAG",.F.),aTipCaj:={},aCaja:={}
  LOCAL aCajas :=ASQL("SELECT CAJ_CODIGO,CAJ_NOMBRE FROM DPCAJA WHERE CAJ_EGRESO=1 AND CAJ_ACTIVO=1 ")
  LOCAL aFormas:={} // Formas de Pago
  LOCAL aDocs  :={} // Documentos
  LOCAL aData:={},aPorIva:={},aIva:={},nTotal:=0
  LOCAL oBrw,oCol
  LOCAL oFont,oFontB,oBtn
  LOCAL lConcil,dDec

  IF COUNT("DPCAJAINST","ICJ_ACTIVO=1 AND ICJ_EGRESO=1")=0
     MsgMemo("Por favor Activar Instrumentos de Caja"+CRLF+"Necesarios para realizar Cbte de Pago","Activar Registros")
     DPLBX("DPCAJAINST.LBX")
     RETURN .T.
  ENDIF

  IF COUNT("DPBANCOTIP","TDB_ACTIVO=1 AND TDB_PAGOS=1")=0
      MsgMemo("Por favor Activar Instrumentos Bancarios"+CRLF+"Necesarios para realizar Cbte de Pagos","Activar Registros")
      DPLBX("DPBANCOTIP.LBX")
      RETURN .T.
  ENDIF

  IF Type("oProPagX")="O" .AND. oProPagX:oWnd:hWnd>0
     RETURN EJECUTAR("BRRUNNEW",oProPagX,GetScript())
  ENDIF

// ? lAuto,cTipPag,cCodSuc,cCodPro,cRecord,lView,cCenCos,cCodMon,nValCam,"lAuto,cTipPag,cCodSuc,cCodPro,cRecord,lView,cCenCos,cCodMon,nValCam"

  DEFAULT cTipPag:="P",lAuto:=.F.,lView:=.F.

  DEFAULT nValCam:=1

  cScope:=cScope + IIF( Empty(cRecord) ,  "" , " AND "+cRecord )

  IF !Empty(cCenCos)
    cScope:=cScope + IIF( Empty(cRecord) ,  "" , " AND PAG_CENCOS"+GetWhere("=",cCenCos))
  ELSE
    cCenCos:=oDp:cCenCos
  ENDIF

  aIva  :=ASQL("SELECT TIP_CODIGO FROM DPIVATIP WHERE TIP_ACTIVO=1 AND TIP_COMPRA=1")

  IF Empty(aIva)
     aIva:={}
     AADD(aIva,{"GN"})
  ENDIF


  AEVAL(aIva,{|a,n,nIva| nIva:=EJECUTAR("IVACAL",a[1],2,oDp:dFecha),;
                        AADD(aPorIva , nIva) ,;
                        aIva[n]:=a[1]+":"+ TRAN(nIva ,"99.99") })


  AADD(aDocs,{"","",CTOD(""),0,0})


  // Si no Encuentra Otros Pagos debe Removerlo del ComboBox
  IF oDp:nVersion>=5 .AND. Empty(SQLGET("DPTIPDOCPRO","TDC_TIPO","TDC_TIPO"+GetWhere("=","OPA")))
     nAt:=ASCAN(aTipPag,{|a,n| LEFT(ALLTRIM(UPPER(a)),1)="O" })
     IIF(nAt>0, ARREDUCE(aTipPag,nAt), NIL)
  ENDIF

  // Si no Encuentra Anticipo debe Removerlo del ComboBox
  IF oDp:nVersion>=5 .AND. Empty(SQLGET("DPTIPDOCPRO","TDC_TIPO","TDC_TIPO"+GetWhere("=","ANT")))
     nAt:=ASCAN(aTipPag,{|a,n| LEFT(ALLTRIM(UPPER(a)),1)="A" })
     IIF(nAt>0, ARREDUCE(aTipPag,nAt), NIL)
  ENDIF

  aTipPag:=ASORT(aTipPag)

  LOADFORMAS(.F.,.F.)

  DEFINE FONT oFont      NAME "Tahoma" SIZE 0, -14 BOLD
  DEFINE FONT oFontGrid  NAME "Tahoma" SIZE 0, -14
  DEFINE FONT oFontOtr   NAME "Tahoma" SIZE 0, -14

  AEVAL(aCajas,{|a,n|AADD(aTipCaj,a[1]),AADD(aCaja,a[2])})

  cTitle:=GetFromVar("{oDp:DPCBTEPAGO}")

  DOCENC(cTitle,"oProPagX","DPCBTEPAGO.EDT")

  oData  :=DATASET("SUC_CBTPAG"+oDp:cSucursal,"ALL")

  oProPagX:cNumero  :=oData:Get("Numero",STRZERO(1,8))

  IF ISALLDIGIT(oProPagX:cNumero)
      oProPagX:cNumero:=STRZERO(VAL(oProPagX:cNumero),8)
  ENDIF

  oProPagX:lSucursal :=oData:Get("lSucursal",.F.)
  oProPagX:lContab   :=oData:Get("lPagContab"  ,.T.)
  oProPagX:lContSel  :=oData:Get("lPagContSel" ,.T.)
  oProPagX:lEditar   :=oData:Get("lPagNumero"  ,.F.)
  oProPagX:lFecha    :=oData:Get("lPagFecha"   ,.F.)
  oProPagX:cView     :="VIEW"
  oProPagx:dDec      := dDec
  oProPagx:cCodMon   :=cCodMon
  oProPagx:nValCam   :=nValCam
  oProPagx:cSucCli   :=""
  oProPagX:aDocOrgCli:={}

  IF lView
    oProPagX:lInc:=.F.
    oProPagX:lMod:=.F.
    oProPagX:lEli:=.F.
  ENDIF

  oData:End(.F.)

  oProPagX:SetScope(cScope)
  oProPagX:SetTable("DPCBTEPAGO","PAG_NUMERO")
// oProPagX:oTable:Browse()

  oProPagX:cWhereRecord:=cScope

//  IF !Empty(cRecord)
//     cCodPro:=oProPagX:PAG_CODIGO
//  ENDIF

  oProPagX:cTipDoc    :=oProPagX:PAG_TIPDOC
  oProPagX:cPrimary   :="PAG_CODSUC,PAG_NUMERO"
  oProPagX:cCodProDoc :=cCodPro
  oProPagX:aTipPag    :=aTipPag
  oProPagX:aTipCaj    :=aTipCaj
  oProPagX:cTipPag    :=cTipPag
  oProPagX:aCajas     :=ACLONE(aCajas)
  oProPagX:aDataPag   :={} // Copia de los Pagos
  oProPagX:aRti       :={}
  oProPagX:aRvi       :={}
  oProPagX:aIslr      :={}
  oProPagX:aDocOrg    :={}
  oProPagX:aDocRev    :={}
  oProPagX:aFormas    :={}
  oProPagX:lBrwEdit   :=.F.
  oProPagX:lBrwDEdit  :=.F.
  oProPagX:cCodCli    :=""    // Cliente Actual
  oProPagX:aDocs      :=aDocs // Documentos
  oProPagX:lDocs      :=.F.   // No Edita Documentos
  oProPagX:cMemo      :=""    // Campo Memo
  oProPagX:PAGTIPDOC  :=""
  oProPagX:PAGNUMDOC  :=""
  oProPagX:lValDoc    :=.T.
  oProPagX:PAG_MTODIF :=0
  oProPagX:PAG_MTORMU :=0 // Retención 1x1000
  oProPagX:oFrmDoc    :=NIL
  oProPagX:cPostSave  :="POSTGRABAR"
  oProPagX:cPreSave   :="PREGRABAR"
  oProPagX:cPreDelete :="PREDELETE"
  oProPagX:cPostDelete:="POSTDELETE" 
  oProPagX:cList      :="DPCBTEPAGO.BRW"
  oProPagX:cFileBrw   :=oProPagX:cList
  oProPagX:lRev       :=.F.
  oProPagX:lAuto      :=lAuto
  oProPagX:lDelCheque :=.F. // Elimina Transacciones Financieras de Bancos
  oProPagX:aCajNum    :={}  // Numero de Registros de Caja
  oProPagX:cPrimary   :="PAG_NUMERO"
  oProPagX:cCenCos    :=cCenCos
  oProPagX:cRecord    :=cRecord
  oProPagX:oBrwDC     :=NIL
  oProPagX:lCliente   :=.F.
  oProPagX:aDocOrgCli :={}


  oProPagX:PAG_PAGOS  :=0 // Monto de los Pagos
  oProPagX:PAG_DEBE   :=0 // Débito
  oProPagX:PAG_HABER  :=0 // Haber


  oProPagX:PAG_DEBE   :=0 // Débito de Clientes
  oProPagX:PAG_HABER  :=0 // Haber  de Clientes

  oProPagX:nOtrosPag  :=0 // Otros Pagos
  oProPagX:PAG_ACT    :=1 // Situación
  oProPagX:PAG_MEMO   :="" // Campo Memo
  oProPagX:PAG_MONTO  :=0  // Monto
  oProPagX:aCajaDat   :={} // Data de Caja 
  oProPagX:aBcoDat    :={} // Data de Banco
  oProPagX:lPar_Moneda:=.F.   // En Otra Moneda
  oProPagX:nSavePago  :=0     // Columna no Válida 

  oProPagX:cList      :=NIL

  AADD(oProPagX:aDocOrg,{1,2,3,4,5,6,7,8,.F.,10})

  oProPagX:SetMemo("PAG_NUMMEM","Descripción Amplia")

  IF DPVERSION()>4
    oProPagX:SetAdjuntos("PAG_FILMAI") // Vinculo con DPFILEEMP
  ENDIF

  IF !oProPagX:lEditar
    oProPagX:SetIncremental("PAG_NUMERO","PAG_CODSUC"+GetWhere("=",oDp:cSucursal),oProPagX:cNumero)
  ENDIF

  oProPagX:AddBtn("MENU.bmp","Menú de Opciones"   ,;
                            "(oProPagX:nOption=0)",;
                            " oProPagX:PRINTER()"  ,"CLI")

  IF oDp:nVersion>=4.1

     oProPagX:AddBtnEdit("proveedores.bmp",oDp:xDPPROVEEDOR,;
                            "(oProPagX:nOption<>0)",;
                              " oProPagX:LISTPROVEE()"  ,"CLI")

  ENDIF

  IF oDp:nVersion>5
     oProPagX:AddBtnEdit("RETIVA.BMP","Validar RIF","(oProPagX:nOption=1 .OR. oProPagX:nOption=3 )","oProPagX:VALRIF()","OTHER")
  ENDIF

  oProPagX:nBtnWidth:=42
  oProPagX:cBtnList :="xbrowse2.bmp"
  oProPagX:BtnSetMnu("BROWSE","Detallado por Otros Pagos"      ,"BRWOTROSPAGOS")  // Agregar Menú en Barra de Botones
  oProPagX:BtnSetMnu("BROWSE","Detallado por Cuenta Bancaria"  ,"BRWOTROSPAGOS")  // Agregar Menú en Barra de Botones
  oProPagX:BtnSetMnu("BROWSE","Agrupado por Cuentas Contable"  ,"BRWXCTA")        // Por Cuenta Contable
  oProPagX:BtnSetMnu("BROWSE","Agrupado Por Proveedor"          ,"BRWXPROV")       // Por Cuenta Contable
  oProPagX:BtnSetMnu("BROWSE","Agrupado por Cuenta Bancaria"    ,"BRWXCTABCO")     // Por Cuenta Contable
  oProPagX:BtnSetMnu("BROWSE","Anticipos"                       ,"BRWANTICIPO")    // Anticipos
  oProPagX:BtnSetMnu("BROWSE","Otros Pagos"                     ,"BRWOTROS")       // Otros Pagos
  oProPagX:BtnSetMnu("BROWSE","Servicios ["+oDp:xDPCTAEGRESO+"]","BRWSERVICIOS")   // Pagos Vinculados Otros Pagos
  oProPagX:BtnSetMnu("BROWSE","Con Diferencia de Pago "         ,"BRWPAGDIF")      // Pagos Vinculados Otros Pagos

  oProPagX:NewPago(.F.)

  oProPagX:lFind:=.T.
  //oProPagX:Windows(0,0,445+100+60,780+100+190)
  oProPagX:Windows(0,0,700-50,1020)


  @ 2.6,1 SAYREF oSayRef PROMPT oDp:xDPPROVEEDOR;
          SIZE 42,18;
          FONT oFontB;
          RIGHT;
          COLORS CLR_HBLUE,oDp:nGris


  oProPagX:oSayProveedor:=oSayRef

  oSayRef:bAction:={||oProPagX:CONPROVEEDOR()}

  @ 2.6,30 SAYREF oSayRef PROMPT GetFromVar("{oDp:xDPCAJA}")+":" ;
          SIZE 42,18;
          FONT oFontB;
          RIGHT;
          COLORS CLR_HBLUE,oDp:nGris

  oSayRef:bAction:={||oProPagX:ViewCaja()}

  @ 1.6,1 SAY "Tipo:"   SIZE NIL,09 RIGHT
  @ 2.6,1 SAY "Número:" SIZE NIL,09 RIGHT
  @ 3.6,1 SAY "Fecha:"  SIZE NIL,09 RIGHT

  @ 1, 1 GROUP oProPagX:oGroup TO 11.4,6 PROMPT ""

  @ 1.5,1 COMBOBOX oProPagX:oPAG_TIPPAG VAR oProPagX:PAG_TIPPAG ITEMS aTipPag;
                    SIZE 120,40 ON CHANGE oProPagX:CHANGETIP();
                    WHEN (oProPagX:nOption=1 .AND. (AccessField("DPCBTEPAGO","PAG_TIPPAG",oProPagX:nOption);
                                           .AND. oProPagX:PAG_MONTO+oProPagX:nOtrosPag=0 .AND. LEN(oProPagX:oPAG_TIPPAG:aItems)>1))

  COMBOINI(oProPagX:oPAG_TIPPAG)

  @ 5.0,10 BMPGET oProPagX:oPAG_CODIGO VAR oProPagX:PAG_CODIGO;
                  VALID EJECUTAR("DPCEROPROV",oProPagX:PAG_CODIGO,oProPagX:oPAG_CODIGO);
                        .AND. oProPagX:VALCODPRO();
                  NAME "BITMAPS\FIND.BMP"; 
                  ACTION oProPagX:LBXPROVEEDORES(); 
                  WHEN (AccessField("DPCBTEPAGO","PAG_CODIGO",oProPagX:nOption);
                      .AND. oProPagX:nOption=1 );
                 SIZE 64,10


  oProPagX:oPAG_CODIGO:cToolTip:="Código "+oDp:xDPPROVEEDOR

/*
  @ 1.5,20 COMBOBOX oProPagX:oPAG_CODCAJ VAR oProPagX:PAG_CODCAJ ITEMS aCaja;
           SIZE 120,40 ON CHANGE oProPagX:CHANGECAJ();
           WHEN (AccessField("DPCBTEPAGO","PAG_CODCAJ",oProPagX:nOption);
                .AND. oProPagX:nOption!=0 .AND. LEN(oProPagX:aCajas)>1)


  oProPagX:oPAG_CODCAJ:cToolTip:="Código "+oDp:xDPCAJA


  COMBOINI(oProPagX:oPAG_CODCAJ)
*/


  @ 5.0,10 BMPGET oProPagX:oPAG_CODCAJ VAR oProPagX:PAG_CODCAJ;
                  VALID oProPagX:VALCODCAJ();
                  NAME "BITMAPS\FIND.BMP"; 
                  ACTION oProPagX:LBXCAJA();
                  WHEN (AccessField("DPCBTEPAGO","PAG_CODCAJ",oProPagX:nOption);
                      .AND. oProPagX:nOption=1 );
                  SIZE 45,10

//                  ACTION  (oDpLbx:=DpLbx("DPCAJA.LBX",NIL,"CAJ_ACTIVO=1",NIL,NIL,NIL,NIL,NIL,NIL,oProPagX:oPAG_CODCAJ),;
//                           oDpLbx:GetValue("CAJ_CODIGO",oProPagX:oPAG_CODCAJ));




  oProPagX:oPAG_CODCAJ:cToolTip:="Código "+oDp:xDPCAJA


  @ 6.0,1 BMPGET oProPagX:oPAG_NUMERO VAR oProPagX:PAG_NUMERO;
                 VALID CERO(oProPagX:PAG_NUMERO,NIL,.T.) .AND. oProPagX:VALNUMERO();
                 WHEN (AccessField("DPDOCPRO","PAG_NUMERO",oProPagX:nOption);
                      .AND. oProPagX:nOption!=0 .AND. oProPagX:lEditar);
                 SIZE 40,10


  oProPagX:oPAG_NUMERO:cToolTip:="Número del Comprobante"


  @ 12,10 BMPGET oProPagX:oPAG_FECHA  VAR oProPagX:PAG_FECHA  PICTURE "99/99/9999";
           NAME "BITMAPS\Calendar.bmp";
           ACTION LbxDate(oProPagX:oPAG_FECHA ,oProPagX:PAG_FECHA);
           VALID (oProPagX:VALFECHA() .AND. EJECUTAR("DPVALFECHA",oProPagX:PAG_FECHA,.T.,.T.,oProPagX:oPAG_FECHA) .AND. ;
                  oProPagX:PROVALCAM());
           WHEN (AccessField("DPDOCMOV","PAG_FECHA",oProPagX:nOption);
                .AND. oProPagX:nOption!=0);
           SIZE 55,10


  oProPagX:oPAG_FECHA:cToolTip:="Fecha de Emisión"


  // Campo : PAG_CODMON
  // Uso   : Moneda                                  
  //
  @ 1.6, 06.0 COMBOBOX oProPagX:oPAG_CODMON VAR oProPagX:PAG_CODMON ITEMS oDp:aMonedas;
                       VALID oProPagX:PROVALCAM(!Eval(oProPagX:oPAG_VALCAM:bWhen));
                       ON CHANGE oProPagX:PROVALCAM();
                       WHEN (oProPagX:lPar_Moneda .AND. AccessField("DPCBTEPAGO","PAG_CODMON",oProPagX:nOption);
                            .AND. oProPagX:nOption!=0 .AND. LEN(oProPagX:PAG_CODMON:aItems)>1) SIZE 100,NIL

  ComboIni(oProPagX:oPAG_CODMON)

  @ 2,10 GET oProPagX:oPAG_VALCAM  VAR oProPagX:PAG_VALCAM;
              PICTURE oDp:cPictValCam;
              VALID oProPagX:PAGVALCAM();
              WHEN LEFT(oProPagX:PAG_TIPPAG,1)='A' .AND.;
                   (oProPagX:lPar_Moneda .AND. (!oDp:cMoneda==LEFT(oProPagX:PAG_CODMON,LEN(oDp:cMoneda))) .AND. ;
                    AccessField("DPCBTEPAGO","PAG_VALCAM",oProPagX:nOption);
                    .AND. oProPagX:nOption!=0);
              SIZE 41,10 RIGHT

  oProPagX:oPAG_VALCAM:cToolTip:="Valor Cambiario" 

  @ 2,17 SAY oProPagX:oProNombre;
         PROMPT EJECUTAR("PAGPRONOMBRE",oProPagX);
         SIZE 140,09

  @ 2.6,40 SAY "Moneda:" SIZE NIL,12 RIGHT
  @ 3.6,40 SAY "Valor:"  SIZE NIL,12 RIGHT

  @ 2,17 SAY oProPagX:oCajNombre;
         PROMPT SQLGET("DPCAJA","CAJ_NOMBRE","CAJ_CODIGO"+GetWhere("=",oProPagX:PAG_CODCAJ));
         SIZE 140,09

  @ 10, 0 FOLDER oProPagX:oFolder ITEMS "Forma de Pago","Documentos","Otros Pagos","Datos Adicionales","Comentarios","Documento de Clientes";
          OF oProPagX:oDlg SIZE 952,248

  SETFOLDER( 1)
  
  oBrw:=TXBrowse():New( oProPagX:oFolder:aDialogs[1]  )

  oBrw:SetArray( oProPagX:aFormas ,.F.)
  oBrw:lHScroll       :=.F.
  oBrw:lFooter        :=.T.
  oBrw:lVScroll       :=.T.
  oBrw:l3D            :=.F.
  oBrw:lRecordSelector:=.F.
  oBrw:oFont          :=oFontGrid
  oBrw:lDownAuto      :=.F.

  oProPagX:oBrw        :=oBrw

  oCol:=oBrw:aCols[1]
  oCol:cHeader      := "Forma"
  oCol:nWidth       := 190
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTFORMA(oCol,uValue)}

  oCol:=oBrw:aCols[2]
  oCol:cHeader      := "Banco"
  oCol:nWidth       := 190
  oCol:bClrHeader   := {|oBrw|oBrw:=oProPagX:oBrw,{CLR_BLUE,12582911}}
  oCol:bOnPostEdit  := {|oCol,uValue|oProPagX:PUTBANCO(oCol,uValue)}

  oCol:=oBrw:aCols[3]
  oCol:cHeader      := "Cuenta"
  oCol:nWidth       := 190+20
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTCUENTA(oCol,uValue)}
  oCol:nEditType    :=1

  oCol:=oBrw:aCols[4]
  oCol:cHeader      := "Número"
  oCol:nWidth       := 130
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTNUMPAG(oCol,uValue)}

  oCol:=oBrw:aCols[5]
  oCol:cHeader      := "Fecha"
  oCol:nWidth       := 100
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTFECHA(oCol,uValue)}
  oCol:cFooter      :="Emitido"

  oCol:=oBrw:aCols[6]
  oCol:cHeader      := "Monto"
  oCol:nWidth       := 140
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:cEditPicture :="99,999,999,999.99"
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrw,TRAN(oBrw:aArrayData[oBrw:nArrayAt,6],"99,999,999,999,999.99")}
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:nEditType    :=1
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTMONTO(oCol,uValue)}
  oCol:cFooter      :="0.00"

  oBrw:DelCol(7)

 
  AEVAL(oBrw:aCols,{|oCol,n|oCol:bClrHeader   := {|oBrw|oBrw:=oProPagX:oBrw,{CLR_GREEN,12582911}},;
                            oCol:oFooterFont  :=oFont,;
                            oCol:oHeaderFont  :=oFont})

  oBrw:bClrFooter:= {|oBrw|oBrw:=oProPagX:oBrw,{CLR_GREEN,8580861}}
  oBrw:bClrStd   := {|oBrw|oBrw:=oProPagX:oBrw,{IIF(!oProPagX:lBrwEdit,CLR_GRAY,CLR_BLACK), iif( oBrw:nArrayAt%2=0,14612478,13104638 ) } }

  oBrw:bChange   := {||oProPagX:ASIGNAFORMA()}

  oBrw:CreateFromCode()
  oBrw:bWhen:={|| !( Empty(oProPagX:PAG_CODIGO) )}

  SETFOLDER(2)

  oBrw:=TXBrowse():New( oProPagX:oFolder:aDialogs[2] )

  oBrw:SetArray(ACLONE(oProPagX:aDocs), .F.)
  oBrw:lHScroll       :=.F.
  oBrw:lFooter        :=.T.
  oBrw:lVScroll       :=.T.
  oBrw:l3D            :=.F.
  oBrw:lRecordSelector:=.F.
  oBrw:oFont          :=oFontGrid
  oBrw:lDownAuto      :=.T.

  oProPagX:oBrwD       :=oBrw

  oCol:=oBrw:aCols[1]
  oCol:cHeader      := "Documento"
  oCol:nWidth       := 220+20+10     // 168

  oCol:=oBrw:aCols[2]
  oCol:cHeader      := "Número"
  oCol:nWidth       := 110+80+10

  oCol:=oBrw:aCols[3]
  oCol:cHeader      := "Fecha"
  oCol:nWidth       := 110
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwD, DTOC(oBrw:aArrayData[oBrw:nArrayAt,3])}

  oCol:=oBrw:aCols[4]
  oCol:cHeader      := "Debe"
  oCol:nWidth       := 200
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:cEditPicture :="99,999,999,999.99"
   oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTDEBCRE(oCol,uValue,4)}
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwD, IIF(oBrw:aArrayData[oBrw:nArrayAt,4]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,4],"9,999,999,999,999.99"))}
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:cFooter      :="0.00"
  oCol:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwD,{IIF(!oProPagX:aDocOrg[oBrw:nArrayAt,9],CLR_GRAY,CLR_HBLUE), iif( oBrw:nArrayAt%2=0,14612478,13104638 ) } }
  oCol:bClrFooter   := {||{CLR_HBLUE,8580861}}

  oCol:=oBrw:aCols[5]
  oCol:cHeader      := "Haber"
  oCol:nWidth       := 200
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:cEditPicture :="99,999,999,999.99"
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwD, IIF(oBrw:aArrayData[oBrw:nArrayAt,5]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,5],"9,999,999,999,999.99"))}
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTDEBCRE(oCol,uValue,5)}
  oCol:cFooter      :="0.00"
  oCol:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwD,{IIF(!oProPagX:aDocOrg[oBrw:nArrayAt,9],CLR_GRAY,CLR_HRED), iif( oBrw:nArrayAt%2=0,14612478,13104638 ) } }
  oCol:bClrFooter   := {||{CLR_HRED,8580861}}

  oBrw:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwD,{IIF(!oProPagX:aDocOrg[oBrw:nArrayAt,9],CLR_GRAY,CLR_BLACK), iif( oBrw:nArrayAt%2=0,14612478,13104638 ) } }

// ojo 18/06/2015  oBrw:bKeyChar     := {|nKey|oProPagX:PUTDEBCRE(nKey)}


//oBrw:bKeyDown     := {|nKey|IIF(nKey=13,oProPagX:RunKeyD(nKey),NIL)}
//  oBrw:bKeyDown     := {|nKey|oProPagX:RunKeyD(nKey)}
// 18/06/2015 oBrw:bKeyChar     := {|oBrw|oBrw:=oProPagX:oBrwD,EVAL(oBrw:bLDblClick)}
  oBrw:bLDblClick   := {|oBrw|oProPagX:DblClick() }
  oBrw:bChange      := {|oBrw|oProPagX:BrwChange()}
  oBrw:bClrFooter   := {||{CLR_GREEN,8580861}}
//oBrw:bKeyDown     := {|| MsgAlert(LSTR(nkey))}

//oBrw:bKeyDown     := {|nKey|IIF(nKey=13,oProPagX:RunKeyD(nKey),NIL)}

  AEVAL(oBrw:aCols,{|oCol,n|oCol:bClrHeader   := {|oBrw|oBrw:=oProPagX:oBrwD,{CLR_GREEN,12582911}},;
                            oCol:oFooterFont  :=oFont,;
                            oCol:oHeaderFont  :=oFont})

  oBrw:CreateFromCode()

  SETFOLDER(3) 

//  EJECUTAR("DPCBTEP_OBRW",oProPagX)

  aData:={}

   AADD(aData,{SPACE(20),oDp:cCenCos,SPACE(12),SPACE(40),0,0})

   oProPagX:aIva   :=ACLONE(aIva)
   oProPagX:aPorIva:=ACLONE(aPorIva)

   oProPagX:oBrwO:=TXBrowse():New( oProPagX:oFolder:aDialogs[3]  )

   oProPagX:oBrwO:SetArray( aData, .F. )

   oProPagX:oBrwO:oFont       :=oFontGrid 
   oProPagX:oBrwO:lFooter     := .T.
   oProPagX:oBrwO:lHScroll    := .F.
   oProPagX:oBrwO:nHeaderLines:= 1
   oProPagX:lAcction          :=.F.

   AEVAL(oProPagX:oBrwO:aCols,{|oCol|oCol:oHeaderFont:=oFontB})

   oCol:=oProPagX:oBrwO:aCols[1]   
   oCol:cHeader      :="Cuenta de Egreso"
   oCol:nWidth       :=170
   oCol:nEditType    :=EDIT_GET_BUTTON
   oCol:bOnPostEdit  :={|o, uValue| oProPagX:VALCTAEGRE(uValue) }
   oCol:bEditBlock   :={||EJECUTAR("DPCBTEP_OCTAEGR",NIL,NIL,oProPagX)}

   oCol:=oProPagX:oBrwO:aCols[2]   
   oCol:cHeader      :="Costo"
   oCol:nWidth       :=080+30
   oCol:nEditType    :=EDIT_GET_BUTTON
   oCol:bEditBlock   :={||oProPagX:EDITCENCOS()}
   oCol:bOnPostEdit  :={|o, uValue| oProPagX:VALCENCOS(uValue,NIL,oProPagX ) }

   oCol:=oProPagX:oBrwO:aCols[3]  
   oCol:cHeader      :="Referencia"
   oCol:nWidth       :=120
   oCol:nEditType    := EDIT_GET
   oCol:bOnPostEdit  :={|o, uValue| oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,3]:=uValue,;
                                    oProPagX:oBrwO:SelectCol(IF(Empty(uValue),3,4)) }

   oCol:=oProPagX:oBrwO:aCols[4]  
   oCol:cHeader      :="Descripción"
   oCol:nWidth       :=300+8
   oCol:nEditType    := EDIT_GET
   oCol:bOnPostEdit  :={|o, uValue| oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,4]:=uValue,;
                                    oProPagX:oBrwO:SelectCol(IF(Empty(uValue),4,5)) }

   oCol:=oProPagX:oBrwO:aCols[5]   
   oCol:cHeader      :="Monto"
   oCol:nWidth       :=170-30
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,5],;
                                TRAN(nMonto,"999,999,999,999.99")}

   oCol:cEditPicture :="999,999,999,999.99"
   oCol:nEditType    := EDIT_GET
   oCol:bOnPostEdit  :={|o, uValue| oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,5]:=uValue,;
                                    oProPagX:CALTOTAL(),;
                                    oProPagX:oBrwO:SelectCol(IF(Empty(uValue),5,6)) }

   oCol:cFooter      :=TRAN(0,"999,999,999,999.99")


   oCol:=oProPagX:oBrwO:aCols[6]   
   oCol:cHeader      :="% IVA"
   oCol:nWidth       :=55
   oCol:nDataStrAlign:= AL_RIGHT
   oCol:nHeadStrAlign:= AL_RIGHT
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:bStrData     :={|nMonto|nMonto:=oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,6],;
                                TRAN(nMonto,"99.99")}

   oCol:nEditType      := EDIT_LISTBOX
   oCol:aEditListTxt   := ACLONE(aIva)
   oCol:aEditListBound := ACLONE(aPorIva)
   oCol:bOnPostEdit    := {|o, v| oProPagX:VALIVA(v), oProPagX:CALTOTAL()}

   oProPagX:oBrwO:bClrStd   := {|oBrw,nClrText,aData|oBrw:=oProPagX:oBrwO,aData:=oBrw:aArrayData[oBrw:nArrayAt],;
                                nClrText:=0,;
                                nClrText:=IIF(Empty(aTail(oBrw:aArrayData)[1]),CLR_HGRAY,nClrText),;
                                nClrText:=IIF(aData[5]>0,CLR_HBLUE,nClrText),;
                                nClrText:=IIF(aData[5]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, 9690879, 14217982 ) } }

   oProPagX:oBrwO:bClrHeader:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oProPagX:oBrwO:bClrFooter:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


   oProPagX:oBrwO:CreateFromCode()

  SETFOLDER(4)

  oProPagX:oScroll:=oProPagX:SCROLLGET("DPCBTEPAGO","DPCBTEPAGO.SCG","")

 
  IF oProPagX:IsDef("oScroll")
    oProPagX:oScroll:SetEdit(.F.)
  ENDIF

  oProPagX:oScroll:SetColSize(220,260,240)

  oProPagX:oScroll:SetColorHead(CLR_BLACK ,6220027,oFont) 

  oProPagX:oScroll:SetColor(14612478,CLR_GREEN,1,13104638,oFontB) 
  oProPagX:oScroll:SetColor(14612478,0,2,13104638,oFont) 
  oProPagX:oScroll:SetColor(14612478,0,3,13104638,oFontB)

  SETFOLDER(5)

  @ 0,0 GET oProPagX:oMemo VAR oProPagX:PAG_MEMO MULTILINE SIZE 235,44;
            WHEN (AccessField("DPCBTEPAGO","PAG_NUMMEM",oProPagX:nOption);
                 .AND. oProPagX:nOption!=0);


  /*
  // Documentos de Clientes
  */

  SETFOLDER(6)
  oProPagX:DPDOCCLI()

  SETFOLDER(0)

  @ 2.6,40 SAY "Total Documentos:" SIZE NIL,09 RIGHT

  @ 2.6,40 SAY oProPagX:oPAG_MONTO PROMPT TRAN(oProPagX:PAG_MONTO,"999,999,999,999.99");
           SIZE NIL,09 RIGHT

  @ 1.6,30 SAY "Total Pagado:" SIZE NIL,09 RIGHT
  @ 2.6,30 SAY oProPagX:oPAG_PAGOS PROMPT TRAN(oProPagX:PAG_PAGOS,"999,999,999,999.99");
           SIZE NIL,09 RIGHT

  @ 2,1 SAY oProPagX:oEstado PROMPT SayOptions("DPCBTEPAGO","PAG_ESTADO",oProPagX:PAG_ESTADO,.T.);
                             UPDATE

//IIF(oProPagX:PAG_ACT=1,"Activo","Anulado") UPDATE

  @ 1.6,30 SAY "Diferencia:" SIZE NIL,09 RIGHT
  @ 2.6,30 SAY oProPagX:oPAG_MTODIF PROMPT TRAN(oProPagX:PAG_MTODIF,"999,999,999,999.99");
           SIZE NIL,09 RIGHT

  @ 1.6,30 SAY "Estado:" SIZE NIL,09 RIGHT

  @09, 33  SBUTTON oProPagX:oBtnISLR ;
	      SIZE 45, 20 FONT oFont;
           FILE "BITMAPS\RETISLR.BMP","BITMAPS\RETISLR.BMP","BITMAPS\RETISLRG.BMP" NOBORDER;
           LEFT PROMPT "Retención ISLR";
           COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 3 };
           ACTION (oProPagX:ISLR());
           WHEN oProPagX:oFolder:nOption=2 .AND. oProPagX:nOption<>0;
           UPDATE

  oProPagX:oBtnISLR:cToolTip:="Crear Retención ISLR"
  oProPagX:oBtnISLR:cMsg    :=oProPagX:oBtnISLR:cToolTip

  oProPagX:oFolder:bChange:={||oProPagX:oBtnISLR:ForWhen()}

  //No apareceran documentos relacionados con retenciones de IVA si la empresa no 
  //esta configurada como contribuyente especial
  IF LEFT(oDp:cTipCon,1)="E"
  
  @12, 33  SBUTTON oProPagX:oBtnRTI ;
           SIZE 45, 22 FONT oFont;
           FILE "BITMAPS\retiva.bmp","BITMAPS\retivag.bmp","BITMAPS\retivag.bmp" NOBORDER;
           LEFT PROMPT "Retención IVA";
	           COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 3 };
           ACTION (oProPagX:RTI());
           WHEN oProPagX:oFolder:nOption=2 .AND. oProPagX:nOption<>0;

  oProPagX:oBtnRTI:cToolTip:="Crear Retención de IVA"
  oProPagX:oBtnRTI:cMsg    :=oProPagX:oBtnRTI:cToolTip
  oProPagX:oBtnRTI:lCancel :=.T.

  oProPagX:oFolder:bChange:={||oProPagX:oBtnRTI:ForWhen()}
 

  ENDIF


  @12, 33  SBUTTON oProPagX:oBtnDoc ;
           SIZE 45, 22 FONT oFont;
           FILE "BITMAPS\documentocxp.bmp","BITMAPS\documentocxp.bmp","BITMAPS\documentocxpg.bmp" NOBORDER;
           LEFT PROMPT "Documentos";
	           COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 3 };
           ACTION (oProPagX:DOCUMENTOS());
           WHEN oProPagX:nOption<>0 .AND. Empty(oProPagX:cCodProDoc)

           // oProPagX:oFolder:nOption=2 .AND. oProPagX:nOption<>0
  oProPagX:oBtnDoc:cToolTip:="Documentos Cuentas por Cobrar"
  oProPagX:oBtnDoc:cMsg    :=oProPagX:oBtnDoc:cToolTip
  oProPagX:oBtnDoc:lCancel :=.T.

  
  //No podra applicar retenciones multiples de IVA si la empresa no esta configurada 
  //como contribuyente especial y tildada que aplique Retenciones Multiples 
 
  IF .t. .OR. LEFT(oDp:cTipCon,1)="E" .AND. oDp:lRetIvaMul=.T.

  @12, 43  SBUTTON oProPagX:oBtnMulI ;
           SIZE 45, 22 FONT oFont;
           FILE "BITMAPS\retivag.bmp","BITMAPS\retivag.bmp","BITMAPS\retivag.bmp" NOBORDER;
           LEFT PROMPT "Multi Ret/I.V.A";
	           COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 3 };
           ACTION (oProPagX:MULRTI());
           WHEN oProPagX:oFolder:nOption=2 .AND. oProPagX:nOption<>0  ;
                .AND. oDp:nVersion>=4.1

  oProPagX:oBtnMulI:cToolTip:="Crear Retención de IVA Multiple"
  oProPagX:oBtnMulI:cMsg    :=oProPagX:oBtnMulI:cToolTip
  oProPagX:oBtnMulI:lCancel :=.T.

  ENDIF

  @12, 43  SBUTTON oProPagX:oBtnRefresh ;
           SIZE 45, 22 FONT oFont;
           FILE "BITMAPS\REFRESH.bmp","BITMAPS\REFRESH.bmp","BITMAPS\REFRESHG.bmp" NOBORDER;
           LEFT PROMPT "Refrescar";
	           COLORS CLR_BLACK, { CLR_WHITE, oDp:nGris2, 3 };
           ACTION (oProPagX:PAGREFRESCAR());
           WHEN oProPagX:oFolder:nOption=2 .AND. oProPagX:nOption<>0  ;
                .AND. oDp:nVersion>=4.1

  oProPagX:oBtnRefresh:cToolTip:="Crear Retención de IVA Multiple"
  oProPagX:oBtnRefresh:cMsg    :=oProPagX:oBtnRefresh:cToolTip
  oProPagX:oBtnRefresh:lCancel :=.T.

/*
 @14, 43  SBUTTON oProPagX:oBtnView ;
           SIZE 45, 22 FONT oFont;
           FILE "BITMAPS\VIEW.bmp","BITMAPS\VIEW.bmp","BITMAPS\VIEWG.bmp" NOBORDER;
           LEFT PROMPT "Consultar";
	           COLORS CLR_BLACK, { CLR_WHITE, 4509179, 1 };
           ACTION (oProPagX:DOCCONSULTAR());
           WHEN !Empty(oProPagX:oBrwD:aArrayData[oProPagX:oBrwD:nArrayAt,1]) .AND. ISRELEASE("18.12")

  oProPagX:oBtnISLR:cToolTip:="Consultar Documento"
  oProPagX:oBtnISLR:cMsg    :=oBtn:cToolTip
  oProPagX:oBtnISLR:lCancel :=.T.
*/

  oProPagX:oFocusFind:=oProPagX:oPAG_NUMERO
  oProPagX:Activate({||oProPagX:INICIOCBT()})

  oProPagX:nWidth_FOLDER :=oProPagX:oFolder:nWidth()
  oProPagX:nHeight_FOLDER:=oProPagX:oFolder:nHeight()

  oDp:oCbtPago:=oProPagX

IF .T.

  EJECUTAR("FRMMOVEDOWN",oProPagX:oFolder,oProPagX,{oProPagX:oBrw,oProPagX:oBrwD,oProPagX:oBrwO,oProPagX:oScroll:oBrw,oProPagX:oMemo,oProPagX:oBrwDC})

ENDIF

  IF !Empty(oProPagX:cCodProDoc) 

      oProPagX:nOption :=1
      oProPagX:lAutoInc:=.T.
      oProPagX:LoadData(1)
      oProPagX:oPAG_CODIGO:VarPut(oProPagX:cCodProDoc)
      oProPagX:oPAG_CODIGO:KeyBoard(13)

  ENDIF

  oProPagX:BRWPSETSIZE()

RETURN oProPagX

FUNCTION INICIOCBT()

   oProPagX:aBrwFocus:=EJECUTAR("FRMGETBRW",oProPagX)

   oProPagX:bLostFocus:={||oProPagX:CBTLOSTFOCUS()}
   oProPagX:bGotFocus :={||oProPagX:CBTGOTFOCUS()}

   // ViewArray(oProPagX:aBrwFocus), Se muestra 4 browse

   oProPagX:aPagType:={} // Tipos de Edición Pagos
   oProPagX:aDocType:={} // Tipos de Edición Documentos

   oProPagX:oBrw:SetColor(NIL,14612478)
   oProPagX:oBrwD:SetColor(NIL,14612478)
   oProPagX:oBrwO:SetColor(NIL,14612478)
// oProPagX:oScroll:oBrw:SetColor(CLR_GREEN,14612478)


   oProPagX:oBrwD:bKeyDown     := {|nKey|oProPagX:RunKeyD(nKey)}

   // 15/06/2021 Generar incidencia cuando se llama desde compras

   IF !Empty(oProPagX:cCodProDoc) .AND. .F. 

      oProPagX:nOption :=1
      oProPagX:lAutoInc:=.T.
      oProPagX:LoadData(1)
      oProPagX:oPAG_CODIGO:VarPut(oProPagX:cCodProDoc)
      oProPagX:oPAG_CODIGO:KeyBoard(13)

   ENDIF

   IF !Empty(oProPagX:cRecord) .AND. oProPagX:nRecCount>0
      oProPagX:LoadData(0)
   ENDIF
 
 
RETURN .T.

/*
// Anular Comprobantes
*/
FUNCTION PREDELETE()
  LOCAL cResp:="",lResp:=.t.,aData,aDocs:={}
  LOCAL cWhere
		
  cWhere:="MOB_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+ " AND "+;
          "MOB_DOCASO"+GetWhere("=",oProPagX:PAG_NUMERO)+ " AND "+;
          "MOB_ORIGEN"+GetWhere("=",'PAG'  )+ " AND "+;
          "MOB_ACT"+GetWhere("=",1         )  

  // Para no anular si el movimiento esta conciliado 
  oProPagx:dDec:=SQLGET("DPCTABANCOMOV","MOB_FCHCON",cWhere)

  IF oProPagX:nOption<>3 .AND. oProPagX:dDec<>CTOD("")

     MensajeErr("No es Posible Anular Comprobante "+oProPagx:PAG_NUMERO, "Esta CONCILIADO")
 
     RETURN .F.

  ENDIF


  IF !EJECUTAR("DPCBTEPAGANUL",oProPagX)
     oProPagX:MensajeErr(cResp,"Comprobante de Pago no puede ser Anulado")
     RETURN .F.
  ENDIF
  
  IF !MensajeNS("Desea Anular","Comprobante de Pago "+oProPagX:PAG_NUMERO)
     RETURN .F.
  ENDIF

  EJECUTAR("DPCBTEPAGDELETE",oProPagX)
  oProPagX:PAG_ESTADO:="N" 

  oProPagX:LOAD()

RETURN .F.

FUNCTION POSTDELETE()


RETURN .F.

FUNCTION VALCODCLI()

  IF Empty(oProPagX:PAG_CODIGO) .OR. !ISSQLFIND("DPCLIENTES","CLI_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO))
     DPFOCUS(oProPagX:oPAG_CODIGO)
     oProPagX:oPAG_CODIGO:KeyBoard(VK_F6)
     RETURN .T.
  ENDIF

RETURN .T.

FUNCTION VALCODPRO()
  LOCAL cCodMon

  IF oProPagX:lCliente

     oProPagX:VALCODCLI()

  ELSE

    IF Empty(oProPagX:PAG_CODIGO) .OR. !ISSQLFIND("DPPROVEEDOR","PRO_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO))

//!(SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO))==oProPagX:PAG_CODIGO)
      DPFOCUS(oProPagX:oPAG_CODIGO)
      oProPagX:oPAG_CODIGO:KeyBoard(VK_F6)
      RETURN .T.
    ENDIF

  ENDIF

  oProPagX:oProNombre:Refresh(.T.)
  oProPagX:lBrwEdit:=Eval(oProPagX:oBrw:bWhen)
  oProPagX:oBrw:ForWhen()

  // Cuando se hace anticipo, documento y luego anticipo genera error.

  IF Left(oProPagX:PAG_TIPPAG,1)="A"

      oProPagX:oFolder:SetOption(1)
      oProPagX:oBrwD:Enable()
      RETURN .T.

  ELSE

      oProPagX:oFolder:SetOption(2)

  ENDIF

  oProPagX:oBrwD:bKeyDown:= {|nKey|oProPagX:RunKeyD(nKey)}

  oProPagX:oBrwD:Enable()

  oProPagX:lPar_Moneda:=UPPE(SQLGET("DPPROVEEDOR","PRO_ENOTRA,PRO_CODMON","PRO_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO)))="S"
  cCodMon:=DPSQLROW(2,oDp:cMoneda)

  IF !Empty(cCodMon)
    oProPagX:oPAG_CODMON:VarPut(cCodMon)
    oProPagX:oPAG_CODMON:bWhen:={||.T.}
    ComboIni(oProPagX:oPAG_CODMON)
  ELSE
    oProPagX:oPAG_CODMON:bWhen:={||oProPagX:lPar_Moneda}
  ENDIF


//?  oProPagX:oPAG_CODMON:ClassName(),oProPagX:PAG_CODMON,"oProPagX:oPAG_CODMON"
// oProPagX:oPAG_CODMON:ForWhen(.T.)
//? oProPagX:lPar_Moneda

  IF !(oProPagX:cCodCli==oProPagX:PAG_CODIGO) .OR. (oProPagX:PAG_DEBE=0 .AND. oProPagX:PAG_HABER=0)

     // Debe Obtener los Documentos por Cobrar
     IF Left(oProPagX:PAG_TIPPAG,1)="P" .AND. !oProPagX:LoadDoc()

        oProPagX:oPAG_CODIGO:MsgErr(oDp:xDPPROVEEDOR+" no tiene Documentos por Pagar")
        RETURN .F.
/* 
        IF MensajeSN(oDp:xDPPROVEEDOR+" no tiene Documentos por Cobrar","Desea realizar un Anticipo")
           oProPagX:oPAG_TIPPAG:VarPut(oProPagX:oPAG_TIPPAG:aItems[1],.t.)
           RETURN .T.
        ENDIF
*/
     ENDIF

  ENDIF

  oProPagX:oFolder:aEnable[1]:=.T.
  oProPagX:oFolder:Refresh(.F.)

  oProPagX:cCodCli:=oProPagX:PAG_CODIGO

  IF EVAL(oProPagX:oPAG_CODCAJ:bWhen)
     DPFOCUS(oProPagX:oPAG_CODCAJ)
  ENDIF

  oProPagX:oFolder:aEnable[1]:=.T.

  EVAL(oProPagX:oPAG_CODIGO:bLostFocus)
  oProPagX:oPAG_CODIGO:SetColor(0,CLR_WHITE)
  oProPagX:oPAG_CODIGO:oJump:=oProPagX:oPAG_FECHA

  oProPagX:aDocOrgCli:={}

  IF oProPagX:lCliente
    EJECUTAR("DPCBTEPAGOCLILOADDOC",oProPagX,.F.)
    oProPagX:oFolder:SetOption(6)
  ENDIF

RETURN .T.

FUNCTION PROVALCAM(lDoc)
   
   DEFAULT lDoc:=.F.

   IF lDoc

     IF LEFT(oProPagX:PAG_TIPPAG,1)="A"
       oProPagX:oFolder:SetOption( 1 )
       oProPagX:oFolder:Refresh(.F.)
       DpFocus(oProPagX:oBrw)
     ELSE
       oProPagX:oFolder:SetOption( 2 )
       oProPagX:oFolder:Refresh(.F.)
       DpFocus(oProPagX:oBrwD)
     ENDIF

   ENDIF

   oProPagX:RECSETVALCAM()

RETURN .T.

FUNCTION VALNUMERO()

   IF !oProPagX:ValUnique(oProPagX:PAG_NUMERO,NIL,.F.)
      MensajeErr("Recibo "+oProPagX:PAG_NUMERO,"ya Existe")
      RETURN .F.
   ENDIF

RETURN .T.

FUNCTION VALFECHA()
RETURN .T.

// Tipo de Pago
FUNCTION CHANGETIP()
   LOCAL aLine

   IF LEFT(oProPagX:PAG_TIPPAG,1)$"AOR" // No tiene Documentos

      oProPagX:aDocOrg    :={}
      aLine:=oProPagX:oBrwD:aArrayData[1]

      AEVAL(aLine,{|a,n|aLine[n]:=CTOEMPY(a)})
   
      oProPagX:oBrwD:aArrayData:={ACLONE(aLine)}
      oProPagX:oBrwD:nArrayAt:=1
      oProPagX:oBrwD:nRowSel:=1
      oProPagX:oBrwD:Refresh(.T.)

      oProPagX:lDocs:=.F.
      oProPagX:oFolder:aEnable[2]:=oProPagX:lDocs
      oProPagX:oFolder:aEnable[3]:=IIF(LEFT(oProPagX:PAG_TIPPAG,1)$"AR",.F.,.T.)
      oProPagX:oFolder:Refresh(.F.)

      // No tiene Documentos

      IF LEFT(oProPagX:PAG_TIPPAG,1)$"R" .OR. LEFT(oProPagX:PAG_TIPPAG,1)$"F"
        EJECUTAR("DPCBTEPAGOREQ",oProPagX)
      ELSE
        oProPagX:oFolder:SetOption(IF(LEFT(oProPagX:PAG_TIPPAG,1)="A",1,3))
      ENDIF

      RETURN .T.

   ELSE

      oProPagX:lDocs             :=(LEN(oProPagX:aDocs)>1)
      oProPagX:oFolder:aEnable[2]:=oProPagX:lDocs
      oProPagX:oFolder:aEnable[3]:=.T.
      oProPagX:oFolder:Refresh(.F.)

   ENDIF

   oProPagX:lVentas:=(LEFT(oProPagX:PAG_TIPPAG,1)="D")

   IF oProPagX:cTipPag<>LEFT(oProPagX:PAG_TIPPAG,1) .OR. LEFT(oProPagX:PAG_TIPPAG,1)="D"

      oProPagX:LOADFORMAS(oProPagX:lVentas,.T.)
      oProPagX:aForPag:={}
      oProPagX:ASIGNAFORMA()

   ENDIF

   oProPagX:cTipPag:=LEFT(oProPagX:PAG_TIPPAG,1)
   oProPagX:oFolder:aEnable[3]:=.T.

   IF oProPagX:cTipPag$"DA"
     oProPagX:oFolder:aEnable[3]:=.F.
   ENDIF

   oProPagX:oFolder:Refresh(.F.)

RETURN .T.

FUNCTION CHANGECAJ()
RETURN .T.

FUNCTION NewPago(lRefresh)
  LOCAL aLine:={}

  aLine:={"","","","",CTOD(""),0,.T.}
  
  IF ValType(oProPagX:oBrw)="O"

    aLine:=ACLONE(ATAIL(oProPagX:oBrw:aArrayData)) // [oProPagX:oBrw:aArrayAt,1]
    AEVAL(aLine,{|a,n|aLine[n]:=CTOEMPTY(a)})

    aLine[6]:=0
    AADD(oProPagX:oBrw:aArrayData,aLine)
    oProPagX:oBrw:nColSel:=1
    oProPagX:oBrw:GoBottom()
    oProPagX:nRowSel:=oProPagX:oBrw:nRowSel

  ELSE

    AADD(oProPagX:aFormas,aLine)
    oProPagX:nRowSel:=1

  ENDIF
RETURN .T.

// Carga Documento
FUNCTION LOAD()
  LOCAL nAt   :=0,oCol,aData:={},oTable,cTipo,nMonto:=0,cSql,cResp:="",uValue,aLine:={}
  LOCAL dFecha,cWhere,cCodCaj  

  oProPagX:oCajNombre:Refresh(.T.)

  dFecha:=IIF(oProPagX:nOption=1 , oDp:dFecha ,oProPagX:PAG_FECHA )

  IF !oProPagX:nOption=0 .AND. !EJECUTAR("DPVALFECHA",dFecha , .T. , .T. ) 
     oProPagX:Cancel()
     RETURN .F.
  ENDIF

  cWhere:="MOB_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+ " AND "+;
          "MOB_DOCASO"+GetWhere("=",oProPagX:PAG_NUMERO)+ " AND "+;
          "MOB_ORIGEN"+GetWhere("=",'PAG'  )+ " AND "+;
          "MOB_ACT"+GetWhere("=",1         )  

  // Para no anular si el movimiento esta conciliado H.C
  //oProPagx:dDec:= SQLGET("DPCTABANCOMOV","MOB_FCHCON","MOB_DOCASO"+GetWhere("=",oProPagx:PAG_NUMERO))
  
  oProPagx:dDec:=SQLGET("DPCTABANCOMOV","MOB_FCHCON",cWhere)

  IF oProPagX:nOption=3 .AND. oProPagX:dDec<>CTOD("")
	//? "No es Posible Modificar comprobante "+oProPagx:PAG_NUMERO+", esta conciliado"
     MensajeErr("No es Posible Modificar Comprobante "+oProPagx:PAG_NUMERO, "Esta CONCILIADO")
     oProPagX:nOption:=0
  ENDIF


  IF oProPagX:nOption=3 .AND. !EJECUTAR("DPCBTEPAGANUL",oProPagX)
     oProPagX:MensajeErr(cResp,"Comprobante no puede ser Modificado")
     RETURN .F.
  ENDIF

  oProPagX:aBcoDat   :={}
  oProPagX:aCajaDat  :={}
  oProPagX:PAG_MTORMU:=0
  oProPagX:PAG_MTODIF:=0

  oProPagX:oFolder:aEnable[2]:=.T.
  oProPagX:cCodCli :=""
  oProPagX:lBrwEdit:=(oProPagX:nOption>0)

  oProPagX:oBrw:Gotop(.T.)
  oProPagX:oBrw:Refresh(.f.)
//oProPagX:oScroll:oBrw:Refresh(.F.)

  oProPagX:lVentas:=(LEFT(oProPagX:PAG_TIPPAG,1)="A")

  IF oProPagX:cTipPag<>LEFT(oProPagX:PAG_TIPPAG,1)="A"
     oProPagX:LOADFORMAS(oProPagX:lVentas,.T.)
  ENDIF

  oProPagX:cTipPag:=LEFT(oProPagX:PAG_TIPPAG,1)

  IF oProPagX:nOption=0
    AEVAL(oProPagX:oBrw:aCols,{|oCol,n|oCol:nEditType:=0})
  ENDIF

  oProPagX:PAGTIPPAG  :=oProPagX:PAG_TIPDOC
  oProPagX:PAGNUMDOC  :=oProPagX:PAG_NUMDOC
  oProPagX:cPAG_CODCAJ:=oProPagX:PAG_CODCAJ

  IF oProPagX:nOption=1

    IF !EJECUTAR("DPVALFECHA")
       RETURN .F.
    ENDIF
    
    oProPagX:PAG_CODSUC:=oDp:cSucursal 
    oProPagX:PAG_ESTADO:="A"
    oProPagX:PAG_CENCOS:=oDp:cCenCos

    oProPagX:AUTONUM()

    aLine:=ACLONE(oProPagX:oBrwD:aArrayData[1])

    AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(aLine[n])})
   
    oProPagX:oBrwD:aArrayData:={ACLONE(aLine)}
    oProPagX:oBrwD:nArrayAt:=1
    oProPagX:oBrwD:nRowSel:=1
    oProPagX:oBrwD:Gotop(.T.)
    oProPagX:oBrwD:Refresh(.T.)

    oProPagX:nOtrosPag:=0

    AADD(aData,{"","","",SPACE(14),CTOD(""),0,.F.})

    oProPagX:oBrw:aArrayData:=ACLONE(aData)
    oProPagX:oBrw:nArrayAt:=1
    oProPagX:oBrw:aCols[6]:cFooter:="0.00"
    oProPagX:oMemo:VarPut("",.T.)
    oProPagX:PAG_NUMMEM:=0
    oProPagX:PAGTIPPAG :=""
    oProPagX:PAGNUMDOC :=""
    oProPagX:PAG_MTODIF:=0
    oProPagX:PAG_NUMRMU:=""
    oProPagX:oBrw:Gotop(.T.)
    oProPagX:oBrw:Refresh(.T.)

    oProPagX:oFolder:aEnable[2]:=.F.
    oProPagX:oFolder:SetOption( 1 )
    oProPagX:oFolder:Refresh(.F.)

    aData:=ACLONE(oProPagX:oBrwO:aArrayData[1])
    AEVAL(aData,{|a,n| aData[n]:=CTOEMPTY(a) })
    oProPagX:oBrwO:aArrayData:=ACLONE(aData)
    oProPagX:oBrwO:nArrayAt:=1
    oProPagX:oBrwO:Gotop(.F.)

    DPFOCUS(oProPagX:oPAG_TIPPAG)

    oProPagX:SET("PAG_FECHA" ,DPFECHA()) 
    //oProPagX:SET("PAG_FECHA" ,IIF(oDp:lFechaNew,oDp:dFecha,DATE()))
    //oProPagX:SET("PAG_HORA"  ,TIME()       )
    oProPagX:SET("PAG_ACT"   ,1            )
    oProPagX:SET("PAG_TIPDOC",""           )
    oProPagX:SET("PAG_NUMDOC",""           )
    oProPagX:SET("PAG_CODSUC",oDp:cSucursal)
    oProPagX:SET("PAG_CENCOS",oProPagX:cCenCos)

    IF !Empty(oProPagX:cCodCli)
       oProPagX:SET("PAG_CODIGO",oProPagX:cCodCli)
    ENDIF

    oProPagX:PAG_CODSUC:=oDp:cSucursal
    oProPagX:PAG_TIPPAG:=oProPagX:cTipPag

    COMBOINI(oProPagX:oPAG_TIPPAG)

/*
//  JN 22/02/2016
    nAt:=ASCAN(oProPagX:aCajas,{|a,n|a[1]=oDp:cCaja})
    nAt:=MAX(nAt,1)
    oProPagX:PAG_CODCAJ:=oProPagX:aCajas[nAt,2]

    COMBOINI(oProPagX:oPAG_CODCAJ)
*/
    oProPagX:PAG_CODCAJ:=oDp:cCaja // Código de Caja

    // Busca si caja por Defecto tiene Permiso y Atributos
    cCodCaj:=SQLGET("DPCAJA","CAJ_CODIGO","CAJ_CODIGO"+GetWhere("=",oProPagX:PAG_CODCAJ)+" AND CAJ_ACTIVO=1 AND CAJ_EGRESO=1")

    IF Empty(cCodCaj)
      // Busca si caja por Defecto tiene Permiso y Atributos
      cCodCaj :=SQLGET("DPCAJA","CAJ_CODIGO","CAJ_ACTIVO=1 AND CAJ_EGRESO=1 ORDER BY CAJ_CODIGO")
    ENDIF

    oProPagX:oPAG_CODCAJ:VarPut(cCodCaj,.T.)

    oProPagX:oPAG_NUMERO:Refresh(.T.)

    oProPagX:PAG_CODMON:=oDp:cMoneda
    COMBOINI(oProPagX:oPAG_CODMON)

    oProPagX:oPAG_TIPPAG:VarPut("P",.T.)
    oProPagX:PAG_MONTO:=0
    oProPagX:oPAG_MONTO:Refresh(.T.)
    oProPagX:CALTOTAL()

    oProPagX:oBrw:Refresh(.T.)
    oProPagX:oBrwO:Refresh(.T.)
    oProPagX:oBrwD:Refresh(.T.)

    oProPagX:oCajNombre:Refresh(.T.)

  ELSE

    IF oProPagX:nOption<>0 .AND. !EJECUTAR("DPVALFECHA",oProPagX:PAG_FECHA)
       RETURN .F.
    ENDIF

    IF !Empty( oProPagX:PAG_NUMMEM )
       oProPagX:oMemo:VarPut(ALLTRIM(SQLGET("DPMEMO","MEM_MEMO","MEM_NUMERO"+GetWhere("=",oProPagX:PAG_NUMMEM))),.T.)
    ENDIF

    oProPagX:oPAG_TIPPAG:VarPut(oProPagX:PAG_TIPPAG,.t.)

    // Debe Recupar los Datos BANCOS
    oTable:=OpenTable(" SELECT MOB_TIPO,MOB_CUENTA,MOB_FECHA,MOB_CODBCO,MOB_DOCUME,MOB_MONTO,"+;
                      " BAN_NOMBRE,MOB_NUMTRA FROM DPCTABANCOMOV "+;
                      " INNER JOIN DPBANCOS ON DPBANCOS.BAN_CODIGO = MOB_CODBCO "+;
                      " WHERE MOB_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+;
                      " AND MOB_DOCASO"+GetWhere("=",oProPagX:PAG_NUMERO)+;
                      " AND MOB_ORIGEN"+GetWhere("=","PAG")+;
                      " AND MOB_ACT=1",.T.)

//    ? CLPCOPY(oTable:cSql)

    oProPagX:aBcoDat:=ACLONE(oTable:aDataFill)

    WHILE !oTable:Eof()

      cTipo:=oTable:MOB_TIPO
      nAt  :=ASCAN(oDp:aFormas,{|a,n|a[6]=cTipo})
      cTipo:=IIF(nAt>0,oDp:aFormas[nAt,1],cTipo)

      AADD(aData,{cTipo,oTable:BAN_NOMBRE,oTable:MOB_CUENTA,oTable:MOB_DOCUME,oTable:MOB_FECHA,;
                  oTable:MOB_MONTO,.F.})

      oTable:DbSkip()

    ENDDO

    oTable:End()

    // Lee Caja

    oTable:=OpenTable(" SELECT CAJ_TIPO,CAJ_BCODIR,CAJ_FECHA,CAJ_NUMERO,CAJ_MONTO,CAJ_NUMTRA "+;
                      " FROM DPCAJAMOV "+;
                      " WHERE CAJ_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+;
                      "   AND CAJ_DOCASO"+GetWhere("=",oProPagX:PAG_NUMERO)+;
                      "   AND CAJ_ORIGEN"+GetWhere("=","PAG")+;
                      IIF(LEFT(oProPagX:PAG_TIPPAG,1)="R" .OR. LEFT(oProPagX:PAG_TIPPAG,1)="F"," AND CAJ_TIPO<>'EFE' ","")+;
                      " AND CAJ_ACT=1",.T.)

    oProPagX:aCajaDat:=ACLONE(oTable:aDataFill)

    WHILE !oTable:Eof()

      cTipo:=oTable:CAJ_TIPO
      nAt  :=ASCAN(oDp:aFormas,{|a,n|a[6]=cTipo})
      cTipo:=IIF(nAt>0,oDp:aFormas[nAt,1],cTipo)

      AADD(aData,{cTipo,oTable:CAJ_BCODIR,"",oTable:CAJ_NUMERO,oTable:CAJ_FECHA,oTable:CAJ_MONTO,.T.})

      oTable:DbSkip()

    ENDDO

    oTable:End()

    AEVAL(aData,{|a,n|nMonto:=nMonto+a[6]})
    oProPagX:oBrw:aCols[6]:cFooter:=TRAN(nMonto,"999,999,999,999.99")
    oProPagX:oBrw:aArrayData:=ACLONE(aData)

    // TECNODATOS
    IF oProPagX:PAG_ACT=0   
       // ANULADO
       aLine:=ACLONE(oProPagX:oBrwD:aArrayData[1])
       AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(aLine[n])})
       oProPagX:oBrwD:aArrayData:={ACLONE(aLine)} 
    ENDIF

    oProPagX:oBrw:Refresh(.T.)

    oProPagX:LOADDOC()

    EJECUTAR("DPCBTEP_OLOAD", oProPagX)

  ENDIF

  IF oProPagX:nOption=1 .OR. oProPagX:nOption=3

    oProPagX:aForPag:={}
    AEVAL(oDp:aFormas,{|a,n|AADD(oProPagX:aForPag,a[1])})

    uValue:=oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,1]

    oProPagX:ASIGNAFORMA()

    oProPagX:Prepare()

    EJECUTAR("DPCBTEP_OINI",oProPagX)


    IF oProPagX:nOption=1

       uValue:=oProPagX:aForPag[1]

       IF oDp:aFormas[1,4] // Directorio Bancario
         oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2]:=oDp:aBancoDir[1,1]
       ENDIF

    ENDIF

    oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,1]:=uValue

    oCol:nEditType:=EDIT_LISTBOX

  ENDIF

  oProPagX:PUTMONTO(NIL,0,.F.)
  oProPagX:oPAG_MTODIF:Refresh(.T.)
  oProPagX:oEstado:Refresh(.T.)
  oProPagX:oProNombre:Refresh(.T.)

  oProPagX:aDataPag:=ACLONE(aData)

  IF oProPagX:nOption=3
    IF  Empty(aData)
      aData:={}
      AADD(aData,{oDp:aCajaInst[1,2],"","","",CTOD(""),0,.F.})
      oProPagX:oBrw:aArrayData:=ACLONE(aData)
      oProPagX:oBrw:nArrayAt  :=1
      oProPagX:oBrw:Refresh(.T.)
    ELSE
      oProPagX:NewPago(.T.)
    ENDIF
  
  ENDIF

  oProPagX:oFolder:aEnable[1]:=.T.
  oProPagX:oFolder:aEnable[2]:=(LEFT(oProPagX:PAG_TIPPAG,1)="P")
  oProPagX:oFolder:aEnable[3]:=(LEFT(oProPagX:PAG_TIPPAG,1)="O")
  oProPagX:oFolder:Refresh(.F.)

/*
  // Refrescar Caja
  nAt:=ASCAN(oProPagX:aCajas , {|a,n| oProPagX:PAG_CODCAJ=a[1] })

  IF nAt>0
     oProPagX:oPAG_CODCAJ:Select(nAt)
  ENDIF
*/

  oProPagX:CALTOTAL()

RETURN .T.

FUNCTION ASIGNAFORMA()
    LOCAL oCol:=oProPagX:oBrw:aCols[1],nAt:=0

    IF oProPagX:nOption=0
       oCol:nEditType:=0
       RETURN .F.
    ENDIF

    IF EMPTY(oProPagX:aForPag)
       AEVAL(oDp:aFormas,{|a,n|AADD(oProPagX:aForPag,a[1])})
    ENDIF

    oCol:aEditListTxt  :=ACLONE(oProPagX:aForPag)
    oCol:aEditListBound:=ACLONE(oProPagX:aForPag)

    nAt:=ASCAN(oProPagX:oBrw:aArrayData,{|a,n|"EFECTIVO"==ALLTRIM(UPPE(a[1]))})

    IF oProPagX:oBrw:nArrayAt<>nAt .AND. nAt>0 .AND. (nAt:=ASCAN(oCol:aEditListTxt,{|a,n|UPPE(ALLTRIM(a))="EFECTIVO"}),nAt>0)

      oCol:aEditListTxt  :=ARREDUCE(oCol:aEditListTxt  ,nAt)
      oCol:aEditListBound:=ARREDUCE(oCol:aEditListBound,nAt)

    ENDIF

    nAt:=ASCAN(oCol:aEditListTxt,oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,1])

    IF oProPagX:nOption<>0 .AND. nAt=0
       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,1]:=oCol:aEditListTxt[1]
       oProPagX:oBrw:Drawline(.f.)
    ENDIF

    oCol:nEditType:=EDIT_LISTBOX

RETURN .T.

// Lee las Formas de Pago
FUNCTION LOADFORMAS(lVentas,lIni,cCajWhere)

  LOCAL I,oTable,cVenta:=""

  DEFAULT lVentas:=.T.,lIni:=.T.,;
          cCajWhere:=""

  // 27/10/2016

  IF lIni .OR. LEFT(oProPagX:PAG_TIPPAG,1)="R" // Requerimiento de Efectivo solo usa Bancos

    oDp:aCajaInst:={}
    oDp:aBancoTip:={}
    oDp:aFormas  :={}

  ENDIF

  IF Empty(oDp:aCajaInst) 
    oDp:aCajaInst:=ASQL("SELECT ICJ_CODIGO,ICJ_NOMBRE,ICJ_DIRBCO,ICJ_MONEDA,ICJ_CODMON,ICJ_BMP,ICJ_REQNUM FROM DPCAJAINST "+;
                      "WHERE "+"ICJ_EGRESO=1 AND ICJ_ACTIVO=1"+" "+cCajWhere)

    IF Empty(oDp:aCajaInst) .AND. .F.		
       MsgMemo("No hay Registro Activos ni definidos en Tabla "+oDp:xDPCAJAINST)
       RETURN .T.
    ENDIF
  ENDIF  

 IF Empty(oDp:aBancoTip) .AND. COUNT("DPCTABANCO","(BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" OR BCO_FILSUC=0) AND BCO_ACTIVA=1")>0
    
    oDp:aBancoTip:=ASQL("SELECT TDB_CODIGO,TDB_NOMBRE,TDB_BMP FROM DPBANCOTIP "+;
                        "WHERE "+"TDB_PAGOS=1"+" "+cCajWhere)

  ENDIF

  oDp:aFormas:={}

  
  FOR I=1 TO LEN(oDp:aCajaInst) 
    AADD(oDp:aFormas,{oDp:aCajaInst[I,2],ALLTRIM(oDp:aCajaInst[I,6]),.T.,oDp:aCajaInst[I,3],oDp:aCajaInst[I,7],oDp:aCajaInst[I,1],;
                      oDp:aCajaInst[I,4]})
  NEXT I

  // JN 27/10/2010
  IF LEFT(oProPagX:PAG_TIPPAG,1)="R" // Requerimiento de Efectivo solo usa Bancos
    oDp:aFormas:={}
  ENDIF

  FOR I=1 TO LEN(oDp:aBancoTip)
    AADD(oDp:aFormas,{oDp:aBancoTip[I,2],ALLTRIM(oDp:aBancoTip[I,3]),.F.,.F.,.T.,oDp:aBancoTip[I,1],.F.})
  NEXT I

  FOR I=1 TO LEN(oDp:aFormas)
    oDp:aFormas[I,2]:=IIF(Empty(oDp:aFormas[I,2]),"BITMAPS\xCheckOff.bmp",ALLTRIM(oDp:aFormas[i,2]))
  NEXT I

  IF Empty(oDp:aBancoDir) 

    oDp:aListMsg:={}

    oTable:=OpenTable("SELECT BAN_NOMBRE,BAN_TELEF1,BAN_TELEF2,BAN_TELEF3,BAN_TELEF4,BAN_WEB  FROM DPBANCODIR ",.T.)
    oTable:Gotop()
    oTable:DbEval({||oTable:Replace("BAN_TELEF1",ALLTRIM(oTable:BAN_TELEF1)+;
                     ALLTRIM(oTable:BAN_TELEF2)+" "+;
                     ALLTRIM(oTable:BAN_TELEF3)+" "+;
                     ALLTRIM(oTable:BAN_TELEF4)+" "+;
                     ALLTRIM(oTabla:BAN_WEB))})

    oDp:aBancoDir:=ACLONE(oTable:aDataFill)

    oTable:End()

    AEVAL(oDp:aBancoDir,{|a,n|AADD(oDp:aListMsg,a[2])})

  ENDIF

  IF Empty(oDp:aCuentaBco) .OR. .T. 

    oDp:aCuentaBco:={}
    oTable:=OpenTable("SELECT DPBANCOS.BAN_CODIGO,DPCTABANCO.BCO_CTABAN,DPBANCOS.BAN_NOMBRE FROM DPCTABANCO "+;
                      "INNER JOIN DPBANCOS ON DPBANCOS.BAN_CODIGO = DPCTABANCO.BCO_CODIGO "+;
                      "WHERE (BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" OR BCO_FILSUC=0) AND BCO_ACTIVA=1 ",.T.)
// ? CLPCOPY(oDp:cSql)

    WHILE !oTable:Eof()
       AADD(oDp:aCuentaBco,{oTable:BAN_NOMBRE,oTable:BCO_CTABAN,oTable:BAN_CODIGO})
       oTable:DbSkip()
    ENDDO
    oTable:End()

  ENDIF
RETURN .T.

FUNCTION BRWPSETSIZE()
   LOCAL oDlg:=oProPagX:oBrw:oWnd

   AEVAL(oProPagX:oFolder:aDialogs,{|oDlg,n| oDlg:Move(25,0,oProPagX:nWidth_FOLDER,oProPagX:nHeight_FOLDER-25,.T.)})
   oProPagX:oBrw:Move(0,0,oDlg:nWidth()-10,oDlg:nHeight()-30,.T.)

RETURN .T.

FUNCTION PUTFORMA(oCol,uValue)
   LOCAL nAt,oCol,aBancos:={},oBrw:=oProPagX:oBrw,cTipo
    
   oProPagX:BRWPSETSIZE()

   oProPagX:nSavePago:=0
   oProPagX:aBancos:={}

   nAt:=ASCAN(oDp:aFormas,{|a,n|a[1]==uValue})

   oProPagX:lCaja  :=oDp:aFormas[nAt,3] // Indicador de Caja
   oProPagX:lDirBco:=oDp:aFormas[nAt,4] // Directorio Bancario
   cTipo           :=oDp:aFormas[nAt,6] // Tipo de Intrumento

   IF oProPagX:lCaja // Debe Buscar Directorio Bancario
   ENDIF

    oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,1]:=uValue

    oCol:=oProPagX:oBrw:aCols[2]

    IF oProPagX:lDirBco // Requiere Directorio Bancario

       AEVAL(oDp:aBancoDir,{|a,n|AADD(oProPagX:aBancos,a[1])})
       oCol:aEditListTxt   :=oProPagX:aBancos
       oCol:aEditListBound :=oProPagX:aBancos
       oCol:nEditType      :=EDIT_LISTBOX
       oProPagX:oBrw:nColSel:=2

       IF Empty(oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2])
          oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2]:=oProPagX:aBancos[1]
       ENDIF

       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=""

    ENDIF

    IF !oProPagX:lDirBco .AND. oProPagX:lCaja  // no hay Bancos

       oProPagX:oBrw:aCols[2]:nEditType:=0
       oProPagX:oBrw:aCols[3]:nEditType:=0
       oProPagX:oBrw:aCols[4]:nEditType:=0
       oProPagX:oBrw:aCols[5]:nEditType:=0

       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2]:=""
       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=""
       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4]:=SPACE(10)
       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,5]:=oProPagX:PAG_FECHA
       oProPagX:oBrw:nColSel:=6

    ENDIF

    IF !oProPagX:lCaja // Bancos

      aBancos:=ASQL(" SELECT DPBANCOS.BAN_NOMBRE,DPCTABANCO.BCO_CTABAN FROM DPCTABANCO "+;
                    " INNER JOIN DPBANCOS ON DPBANCOS.BAN_CODIGO = DPCTABANCO.BCO_CODIGO"+;
                    " WHERE (BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" OR BCO_FILSUC=0) AND BCO_ACTIVA=1 ")

      nAt:=ASCAN(aBancos,{|a,n|oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2]=a[1]})

      IF EMPTY(oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2]) .OR. nAt=0
         oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2]:=aBancos[1,1]
         oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=aBancos[1,2]
         oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,5]:=oProPagX:PAG_FECHA
      ENDIF

      aBancos:=ASQL(" SELECT DPBANCOS.BAN_NOMBRE FROM DPCTABANCO "+;
                    " INNER JOIN DPBANCOS ON DPBANCOS.BAN_CODIGO = DPCTABANCO.BCO_CODIGO "+;
                    " WHERE (DPCTABANCO.BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" OR BCO_FILSUC=0) "+;
                    " GROUP BY DPBANCOS.BAN_NOMBRE")

      //  ViewArray(aBancos)
      // ? CLPCOPY(oDp:cSql)
      oProPagX:aBancos:={}
      AEVAL(aBancos,{|a,n|AADD(oProPagX:aBancos,a[1])})

      // ViewArray(oProPagX:aBancos)


      oCol:aEditListTxt   :=ACLONE(oProPagX:aBancos)
      oCol:aEditListBound :=ACLONE(oProPagX:aBancos)
      oCol:nEditType      :=EDIT_LISTBOX

      EVAL(oProPagX:oBrw:aCols[2]:bOnPostEdit, oProPagX:oBrw:aCols[3],oProPagX:aBancos[1])

      oProPagX:oBrw:nColSel:=2

   ELSE

      // Operaciones de Caja

      IF SQLGET("DPCAJAINST","ICJ_REQNUM","ICJ_CODIGO"+GetWhere("=",cTipo)) .AND. !oProPagX:LEE_VIEWCXC(cTipo)
         oProPagX:oBrw:nColSel:=1
         RETURN .F.
      ENDIF

/*
      // Si el Tipo de Instrumento no Tiene Numero no puede Seguir
      IF Empty(oProPagX:aCajNum)
        EJECUTAR("XSCGMSGERR",oProPagX:oBrw,cTipo+" no posee Registros en Caja")
      ENDIF
*/      

   ENDIF

   IF Empty(oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,5])
      oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,5]:=oProPagX:PAG_FECHA
   ENDIF

   oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,7]:=oProPagX:lCaja // Indica si es Caja
   oBrw:aCols[6]:nEditType:=1

   IF Empty(oBrw:aArrayData[oBrw:nArrayAt,6])
       oBrw:aArrayData[oBrw:nArrayAt,6]:=MAX(oProPagX:PAG_MTODIF*-1,0)
   ENDIF

RETURN .T.

FUNCTION PUTBANCO(oCol,uValue)
  LOCAL aBancos,aCuentas:={},oCol,nAt,cCuenta

  oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2]:=uValue

  IF oProPagX:lCaja
     oProPagX:oBrw:nColSel:=4
     oProPagX:oBrw:aCols[4]:nEditType:=1

     IF Empty(oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4])
        oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4]:=SPACE(10)
     ENDIF

     oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=""
     oProPagX:oBrw:aCols[3]:nEditType:=0
  ELSE

     // Selecciona las Cuentas Bancarias
     // oProPagX:oBrw:nColSel:=3
     // oProPagX:oBrw:aCols[4]:nEditType:=1
     oCol:=oProPagX:oBrw:aCols[3]

     aBancos:=ASQL("SELECT DPCTABANCO.BCO_CTABAN FROM DPCTABANCO INNER JOIN DPBANCOS ON DPBANCOS.BAN_CODIGO = DPCTABANCO.BCO_CODIGO "+;
                   " WHERE DPBANCOS.BAN_NOMBRE"+GetWhere("=",oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2])+;
                   " AND (BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" OR BCO_FILSUC=0) AND BCO_ACTIVA=1 ")

     AEVAL(aBancos,{|a,n|AADD(aCuentas,a[1])})

     oCol:aEditListTxt   :=aCuentas
     oCol:aEditListBound :=aCuentas
     oCol:nEditType      :=EDIT_LISTBOX
     oProPagX:oBrw:nColSel:=3
     nAt                 :=ASCAN(aCuentas,cCuenta)

     oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4]:=SPACE(14)

     IF EMPTY(oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]) .OR. nAt=0
        nAt:=1
        oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=aCuentas[nAt]
     ENDIF

  ENDIF

RETURN .T.

/* Para asignar control chequeras
FUNCTION PUTCUENTA(oCol,uValue)
  LOCAL aCheques:={},aCuentas:={},nAt:=0

  //oProPagX:GetCheque()
  // Version 5 Estandar
  oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=uValue

  aCuentas:=ASQL("SELECT CHE_NUMERO FROM DPBCOCHEQUES INNER JOIN DPBANCOS ON  BAN_CODIGO = CHE_CODBCO "+;
                 " WHERE  BAN_NOMBRE"+GetWhere("=",oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,2])+;
                 " AND CHE_NUMCTA"+GetWhere("=",oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3])+" AND CHE_ACT=1 AND CHE_ESTADO='A'")


  //oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=uValue
  oProPagX:oBrw:nColSel:=4
  oProPagX:oBrw:aCols[4]:nEditType:=1


  oCol:=oProPagX:oBrw:aCols[4]
  IF !Empty(aCuentas)
    AADD(aCheques,SPACE(04))
    AEVAL(aCuentas,{|a,n|AADD(aCheques,a[1])})

    oCol:aEditListTxt   :=aCheques
    oCol:aEditListBound :=aCheques
    oCol:nEditType      :=EDIT_LISTBOX
    oProPag:oBrw:nColSel:=4
    nAt                 :=ASCAN(aCheques,aCheques)

  ENDIF

RETURN .T.
*/

// Original

FUNCTION PUTCUENTA(oCol,uValue)

  oProPagX:GetCheque()

  oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,3]:=uValue
  oProPagX:oBrw:nColSel:=4
  oProPagX:oBrw:aCols[4]:nEditType:=1

RETURN .T.

// Asigna el Numero del Pago
FUNCTION PUTNUMPAG(oCol,uValue)
  LOCAL lFound:=.F.
  LOCAL aLine:=oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt],nAt,cNumero,cCbtPago
  LOCAL cTipDoc:=aLine[1],cBanco,cCuenta,cCodSuc:=oDp:cSucursal,cNumChq

  IF EMPTY(uValue)
     RETURN .F.
  ENDIF

  oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4]:=uValue
  oProPagX:oBrw:nColSel:=5
  oProPagX:oBrw:aCols[5]:nEditType:=1

  IF aLine[7]
     RETURN .F.
  ENDIF

  nAt    :=ASCAN(oDp:aFormas,{|a,n|a[1]==cTipDoc})
  cTipDoc:=oDp:aFormas[nAt,6]
  cBanco :=aLine[2]
  cBanco :=MYSQLGET("DPBANCOS","BAN_CODIGO","BAN_NOMBRE"+GetWhere("=",cBanco))
  cCuenta:=aLine[3]

  cNumero:=MYSQLGET("DPCTABANCOMOV","MOB_DOCUME,MOB_DOCASO,MOB_ORIGEN","MOB_TIPO  "+GetWhere("=",cTipDoc)+" AND "+;
                                                 "MOB_CODBCO"+GetWhere("=",cBanco )+" AND "+;
                                                 "MOB_CUENTA"+GetWhere("=",cCuenta)+" AND "+;
                                                 "MOB_DOCUME"+GetWhere("=",uValue ))

  cCbtPago:=IIF(Empty(oDp:aRow) , "" , oDp:aRow[2] )
  oProPagX:nSavePago:=0

  IF ALLTRIM(cNumero)=ALLTRIM(uValue) 
     
     IF oProPagX:nOption=1 .OR. (oProPagX:nOption<>1 .AND. cCbtPago<>oProPagX:PAG_NUMERO)
        oProPagX:nSavePago:=4   
        MensajeErr("Transacción Bancaria "+ALLTRIM(uValue)+" ya Existe")
        oProPagX:oBrw:nColSel:=4
        RETURN .F.
     ENDIF
  ENDIF
RETURN .T.

// Asigna el Numero del Pago
FUNCTION PUTFECHA(oCol,uValue)

  oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,5]:=uValue
  oProPagX:oBrw:nColSel:=6

RETURN .T.

FUNCTION PUTMONTO(oCol,uValue,lSave)
   LOCAL nMonto:=0,nAt:=0

   DEFAULT lSave:=.T.

   IF !oProPagX:lValDoc 
      RETURN .F.
   ENDIF

   IF Empty(uValue) .AND. lSave .AND. oProPagX:oBrw:nArrayAt=LEN(oProPagX:oBrw:aArrayData)
      RETURN .F.
   ENDIF

   IF oProPagX:nSavePago>0  
      oProPagX:oBrw:nColSel:=oProPagX:nSavePago
      RETURN .F.
   ENDIF

   IF lSave

      MensajeErr(cTipDoc,cNumDoc)

      oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,6]:=uValue // Monto del Pago

   ELSE

   ENDIF

   oProPagX:CALTOTAL()

   oProPagX:oBrw:aCols[6]:cFooter:=TRAN(oProPagX:PAG_PAGOS,"99,999,999,999.99")

   IF oProPagX:oBrw:nArrayAt=LEN(oProPagX:oBrw:aArrayData) .AND. lSave
     oProPagX:NewPago(.T.)
   ENDIF

RETURN .T.

FUNCTION VALFECHA()
RETURN .T.

// Carga de Documentos Pendientes
FUNCTION LOADDOC(lSave)
  LOCAL oTable,cSql,I,aDoc:={},cWhere:="",nAt:=0,aLine,nValCam:=0 // Fecha y hora
  LOCAL nPagado:=0,aCopy:=ACLONE(oProPagX:oBrwD:aArrayData)
  LOCAL aCopyOrg:=ACLONE(oProPagX:aDocOrg),cHora:=DPHORA(),cConcat:=""
  LOCAL cTipFac:="",cNumFac:="" // Numero de Factura vinculada con Retencion de IVA

  DEFAULT lSave:=.T.

  oProPagX:lDocs   := .F. // No Edita Documentos
  cHora           := IIF( !lSave , DPHORA() , oProPagX:PAG_HORA )

  IF !oProPagX:lValDoc 
     RETURN .T.
  ENDIF

  oProPagX:lRev    :=MYSQLGET("DPPROVEEDOR","PRO_ENOTRA","PRO_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO))="S"

  IF LEFT(oProPagX:PAG_TIPPAG,1)="A" .OR. LEFT(oProPagX:PAG_TIPPAG,1)="O"

     // Anticipo no hay Documentos
     oProPagX:aDocs:={} 
     oProPagX:oFolder:aEnable[2]:=oProPagX:lDocs
     oProPagX:oFolder:ForWhen()
     aLine:=ACLONE(oProPagX:oBrwD:aArrayData[1])
     AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(aLine[n])})
     oProPagX:oBrwD:nArrayAt:=1
     oProPagX:oBrwD:aArrayData:={ACLONE(aLine)}
     oProPagX:oBrwD:GoTop(.T.)

     RETURN .T.

  ENDIF
  
  IF oProPagX:nOption=0 
     cWhere:=" DOC_PAGNUM"+GetWhere("=",oProPagX:PAG_NUMERO)+" AND (DOC_TIPTRA='P' OR (DOC_DOCORG='P' AND DOC_TIPTRA='P'))"
  ELSE

     EJECUTAR("DPCBTEPAGOLDO",oProPagX)
/*
     cWhere:="( NOT (DOC_PAGNUM"+GetWhere("=",oProPagX:PAG_NUMERO)+" AND "+;
             "       DOC_TIPTRA='P' )) AND DOC_TIPDOC<>'RMUX' AND DOC_DOCORG<>'P' AND "+;
             "(DOC_FECHA"+GetWhere("<=",oProPagX:PAG_FECHA )+" OR "+;
             "(DOC_FECHA"+GetWhere("=" ,oProPagX:PAG_FECHA )+"))"
*/
     // JN 18/10/2016

     cConcat:=EJECUTAR("SQLCONCAT",oProPagX:PAG_FECHA,cHora)

     cWhere :="( NOT (DOC_PAGNUM"+GetWhere("=",oProPagX:PAG_NUMERO)+" AND "+;
              "       DOC_TIPTRA='P' )) AND DOC_TIPDOC<>'RMUX' AND DOC_DOCORG<>'P' AND "+;
              "CONCAT(DOC_FECHA,DOC_HORA)"
  ENDIF

  IF oProPagX:nOption=1

     oProPagX:PAG_HORA:=DPHORA()

/*
     cWhere:="DOC_TIPDOC"+GetWhere("<>","RMUX"           )+" AND "+;
             "(DOC_FECHA"+GetWhere("<",oProPagX:PAG_FECHA)+" OR "+;
             "(DOC_FECHA"+GetWhere("=",oProPagX:PAG_FECHA)+"))"
*/
     // JN 18/10/2016
     cConcat:=EJECUTAR("SQLCONCAT",oProPagX:PAG_FECHA,cHora)
     cWhere:="DOC_TIPDOC"+GetWhere("<>","RMUX"           )

// Requiere Indicar la fecha y hora
// +" AND "+;
//             "CONCAT(DOC_FECHA,DOC_HORA)"

  ENDIF

  CursorWait()

  cSql :=" SELECT DOC_CODIGO,DOC_CODSUC,DOC_CXP,TDC_DESCRI,DOC_TIPDOC,DOC_NUMERO,SUM(DOC_NETO*DOC_CXP) AS DOC_NETO FROM DPDOCPRO "+;
         "  INNER JOIN DPTIPDOCPRO ON DOC_TIPDOC=TDC_TIPO "+;
         "  WHERE DOC_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC) +;
         "    AND DOC_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO) +;
         "    AND DOC_ACT=1 AND DOC_CXP<>0 "+;
         "    AND "+cWhere +;
         " GROUP BY DOC_CODIGO,DOC_CODSUC,TDC_DESCRI,DOC_TIPDOC,DOC_NUMERO "+;
         " HAVING ROUND(DOC_NETO,2)<>0 "+;  
         " ORDER BY CONCAT(DOC_FECHA,DOC_HORA) "

  oTable:=OpenTable(cSql,.T.)

  DPWRITE("TEMP\DPCBTEPAGO_LOAD.SQL",cSql)

  IF oTable:RecCount()=0

     oTable:End()
     oProPagX:aDocs:={} 
     oProPagX:oFolder:aEnable[2]:=oProPagX:lDocs
     oProPagX:oFolder:ForWhen()

     oTable:aDataFill:=EJECUTAR("SQLARRAYEMPTY",cSql)

//     RETURN .F.

  ENDIF

  oProPagX:lDocs:=(oTable:RecCount()>0) // No Edita Documentos
  oProPagX:oFolder:aEnable[2]:=oProPagX:lDocs

  oTable:Replace("DOC_FECHA" ,CTOD(""))
  oTable:Replace("DOC_PAGO"  ,.F.     ) // Indica si Pagó
  oTable:Replace("DOC_MTOORG",0       ) // Monto Original
  oTable:Replace("DOC_MTOPAG",0       ) // Monto Pagado
  oTable:Replace("DOC_MROREV",0       ) // Monto Revaluado

  oTable:Gotop()
  oProPagX:aDocs:={}

  WHILE !oTable:Eof() 

     // Buscamos Datos Complementarios
     nValCam:=0
     oTable:Replace("DOC_MTOORG",oTable:DOC_NETO)
     oTable:Replace("DOC_MONNAC",oTable:DOC_NETO)

     // Busca la retencion de IVA
     


  // H.C
  IF oTable:DOC_TIPDOC="ANT"
     oTable:Replace("DOC_FECHA",SQLGET("DPDOCPRO","DOC_FECHA,DOC_VALCAM,DOC_CODMON,DOC_FCHVEN","DOC_CODSUC"+GetWhere("=",oTable:DOC_CODSUC)+" AND "+;
                                                              "DOC_TIPDOC"+GetWhere("=",oTable:DOC_TIPDOC)+" AND "+;
                                                              "DOC_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                              "DOC_PAGNUM"+GetWhere("=",oTable:DOC_NUMERO)+" AND DOC_TIPTRA='D'"))
  ENDIF




     oTable:Replace("DOC_FECHA",SQLGET("DPDOCPRO","DOC_FECHA,DOC_VALCAM,DOC_CODMON","DOC_CODSUC"+GetWhere("=",oTable:DOC_CODSUC)+" AND "+;
                                                              "DOC_TIPDOC"+GetWhere("=",oTable:DOC_TIPDOC)+" AND "+;
                                                              "DOC_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                              "DOC_NUMERO"+GetWhere("=",oTable:DOC_NUMERO)+" AND DOC_TIPTRA='D'"))

     oTable:Replace("DOC_VALCAM",DPSQLROW(2,0))
     oTable:Replace("DOC_CODMON",DPSQLROW(3,CTOD("")))
     oTable:Replace("DOC_ENOTRA",DIV(oTable:DOC_NETO,oTable:DOC_VALCAM))
     oTable:Replace("DOC_CAMBIO",nValCam)

     IF oProPagX:lRev .AND. oProPagX:nOption<>0 .AND. oTable:DOC_VALCAM<>0

        nValCam:=EJECUTAR("DPGETVALCAM",oTable:DOC_CODMON,oProPagX:PAG_FECHA,cHora)

        oTable:DOC_NETO:=(DIV(oTable:DOC_NETO,oTable:DOC_VALCAM))*nValCam

        oTable:Replace("DOC_CAMBIO",nValCam)
        oTable:Replace("DOC_MTOORG",oTable:DOC_NETO)

     ENDIF

     IF oProPagX:nOption<>0

        nPagado:=MYSQLGET("DPDOCPRO","(DOC_NETO+DOC_OTROS)*DOC_CXP","DOC_CODSUC"+GetWhere("=",oTable:DOC_CODSUC)+" AND "+;
                                                        "DOC_TIPDOC"+GetWhere("=",oTable:DOC_TIPDOC)+" AND "+;
                                                        "DOC_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                        "DOC_NUMERO"+GetWhere("=",oTable:DOC_NUMERO)+" AND DOC_TIPTRA='P' AND "+;
                                                        "DOC_PAGNUM"+GetWhere("=",oProPagX:PAG_NUMERO))

        nPagado:=nPagado*-1

     ELSE

        nPagado:=oTable:DOC_NETO*-1

     ENDIF

     IF Empty(nPagado)
        nPagado:=oTable:DOC_NETO
     ELSE
        oTable:Replace("DOC_PAGO"  ,.T.     ) // Indica si Pagó
     ENDIF

     IF  oProPagX:nOption<>0 .OR. (oProPagX:nOption=0 .AND. oTable:DOC_PAGO)


      IF oTable:DOC_TIPDOC="RET"

         cTipFac:=SQLGET("DPDOCPROISLR","RXP_TIPDOC,RXP_NUMDOC","RXP_CODSUC"+GetWhere("=",oTable:DOC_CODSUC)+" AND "+;
                                                                "RXP_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                                "RXP_DOCNUM"+GetWhere("=",oTable:DOC_NUMERO))
         cNumFac:=DPSQLROW(2,"")

         oTable:TDC_DESCRI:=ALLTRIM(oTable:TDC_DESCRI)+" ["+cTipFac+":"+ALLTRIM(cNumFac)+"]"

      ENDIF

      IF oTable:DOC_TIPDOC="RTI"

         cTipFac:=SQLGET("DPDOCPRORTI","RTI_TIPDOC,RTI_NUMERO","RTI_CODSUC"+GetWhere("=",oTable:DOC_CODSUC)+" AND "+;
                                                               "RTI_DOCTIP"+GetWhere("=",oTable:DOC_TIPDOC)+" AND "+;
                                                               "RTI_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                               "RTI_DOCNUM"+GetWhere("=",oTable:DOC_NUMERO))
         cNumFac:=DPSQLROW(2,"")

         oTable:TDC_DESCRI:=ALLTRIM(oTable:TDC_DESCRI)+" ["+cTipFac+":"+ALLTRIM(cNumFac)+"]"

      ENDIF



      IF oProPagX:nOption=0

         AADD(oProPagX:aDocs,{oTable:TDC_DESCRI,oTable:DOC_NUMERO,oTable:DOC_FECHA,;
                             IIF(oTable:DOC_CXP=-1 ,nPagado   ,0),;
                             IIF(oTable:DOC_CXP=+1 ,nPagado*-1,0)})

      ELSE

        AADD(oProPagX:aDocs,{oTable:TDC_DESCRI,oTable:DOC_NUMERO,oTable:DOC_FECHA,;
                            IIF(oTable:DOC_CXP=+1 ,nPagado   ,0),;
                            IIF(oTable:DOC_CXP=-1 ,nPagado*-1,0)})


      ENDIF
     ENDIF

     oTable:DbSkip()

  ENDDO

  oProPagX:aDocOrg:=ACLONE(oTable:aDataFill)

  IF !lSave

     FOR I=1 TO LEN(aCopy)

       nAt:=ASCAN(oProPagX:aDocs,{|a,n|aCopy[I,1]=a[1] .AND. aCopy[I,2]=a[2]})

       IF nAt>0 

         IF aCopyOrg[I,9]
           oProPagX:aDocs[nAt,4]  :=IIF(aCopy[I,4]<>0 , MIN( aCopy[I,4] , oProPagX:aDocs[nAt,4] ) , oProPagX:aDocs[nAt,4] )
           oProPagX:aDocs[nAt,5]  :=IIF(aCopy[I,5]<>0 , MIN( aCopy[I,5] , oProPagX:aDocs[nAt,5] ) , oProPagX:aDocs[nAt,5] )
           oProPagX:aDocOrg[nAt,9]:=aCopyOrg[I,9]
         ENDIF

       ENDIF
     NEXT I
  ENDIF

// ViewArray(oProPagX:aDocs)

  oProPagX:oBrwD:aArrayData:=ACLONE(oProPagX:aDocs)

  oProPagX:oBrwD:nArrayAt:=1
  oProPagX:oBrwD:nRowSel:=1
  oProPagX:oBrwD:Refresh(.F.)
  oProPagX:oBrwD:GoTop(.T.)  

  oTable:End()

  EJECUTAR("DPCBTEPAGOCLILOADDOC",oProPagX,NIL)

  IF oProPagX:nOption=0
    oProPagX:CALTOTAL()
  ELSE
    oProPagX:PUTDEBCRE(NIL,0,4,.F.)
  ENDIF


RETURN .T.

FUNCTION PUTDEBCRE(oCol,uValue,nCol,lSave)
   LOCAL oBrw   :=oProPagX:oBrwD,nDebe:=0,nHaber:=0,I,nAt,nColRet,nMtoRet:=0,lRetIva
   LOCAL cTipDoc:=oProPagX:aDocOrg[oBrw:nArrayAt,5]
   LOCAL cNumDoc:=ALLTRIM(oProPagX:aDocOrg[oBrw:nArrayAt,6]) // JN 17/10/2016
   LOCAL cNumRti:="",lActivar:=.T. // Documento Asociado

   DEFAULT lSave:=.T.

   IF lSave

      lRetIva:=IIF(LEFT(oDp:cTipCon,1)="E",SQLGET("DPTIPDOCPRO","TDC_RETIVA","TDC_TIPO"+GetWhere("=",cTipDoc)),.F.)
 
      nAt:=oBrw:nArrayAt
     
      IF lRetIva

        cNumRti:=SQLGET("DPDOCPRORTI","RTI_DOCNUM","RTI_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+" AND "+;
                                                   "RTI_TIPDOC"+GetWhere("=",cTipDoc            )+" AND "+;
                                                   "RTI_NUMERO"+GetWhere("=",cNumDoc            ))
        IF Empty(cNumRti)
          oProPagX:RTI()
        ENDIF

      ENDIF

//? lSave,"lSave"

      oBrw:aCols[nCol]:oEditGet:End()
      oBrw:aCols[nCol]:oEditGet:=NIL

      // Para que no se ubique en el ultimo registro del grid al no poseer IVA el documento
      oBrw:nArrayAt:=nAt
      oBrw:DrawLine(.T.)
  
      // Validación de la Autorización del Pago
      IF !EJECUTAR("DPCBTPAGAUTRZ",oProPagX,oBrw,uValue)
         RETURN .F.
      ENDIF
      // Hasta Aqui Validacion de Pago Autorizado

      IF uValue>ABS(oProPagX:aDocOrg[oBrw:nArrayAt,10])
         MensajeErr("Pago no puede superar Saldo: "+;
                    ALLTRIM(TRAN(oProPagX:aDocOrg[oBrw:nArrayAt,10],"99,999,999,999.99"))+"del Documento")
         RETURN .F.
      ENDIF

      oProPagX:aDocOrg[oBrw:nArrayAt,9]   :=.T.
      oBrw:aArrayData[oBrw:nArrayAt,nCol]:=uValue
//    oBrw:lAutoDown:=.T.
      oBrw:nColSel:=4
//    oBrw:GoDown(.T.)

      IF uValue=0 // Recupera su Valor

        oProPagX:aDocOrg[oBrw:nArrayAt,9]  :=.F.
        oBrw:aArrayData[oBrw:nArrayAt,nCol]:= ABS(oProPagX:aDocOrg[oBrw:nArrayAt,10])
        lActivar:=.F.

      ENDIF

//      IF .T. 

        // Busca Documento Asociado
        nAt:=ASCAN(oProPagX:aRti,{|a,n|cTipDoc=a[1] .AND. cNumDoc=ALLTRIM(a[3]) })

        IF nAt>0 .AND. (ABS(uValue)=ABS(oProPagX:aDocOrg[oBrw:nArrayAt,10]) .OR. uValue=0) // Pago Total

           cTipDoc:="RTI"
           cNumDoc:=ALLTRIM(oProPagX:aRti[nAt,2])
           nAt    :=0
           nAt    :=ASCAN(oProPagX:aDocOrg,{|a,n|a[5]=cTipDoc .AND. ALLTRIM(a[6])=cNumDoc}) // JN 17/10/2016


           IF nAt>0
              oProPagX:aDocOrg[nAt,9]:=lActivar
           ENDIF

        ENDIF

        // Busca Documento Asociado  RET
        cTipDoc:=oProPagX:aDocOrg[oBrw:nArrayAt,5]
        cNumDoc:=ALLTRIM(oProPagX:aDocOrg[oBrw:nArrayAt,6]) // JN 17/10/2016
        nAt    :=ASCAN(oProPagX:aIslr,{|a,n|cTipDoc=a[1] .AND. cNumDoc=ALLTRIM(a[3]) })

        IF nAt>0 .AND. (ABS(uValue)=ABS(oProPagX:aDocOrg[oBrw:nArrayAt,10]).OR. Empty(uValue)) // Pago Total

           cTipDoc:="RET"
           cNumDoc:=ALLTRIM(oProPagX:aIslr[nAt,2]) // JN 17/10/2016
           nAt    :=0
           nAt    :=ASCAN(oProPagX:aDocOrg,{|a,n|a[5]=cTipDoc .AND. ALLTRIM(a[6])=cNumDoc})

           IF nAt>0
              oProPagX:aDocOrg[nAt,9]:=lActivar
           ENDIF

        ENDIF
       
      // Busca Documento Asociado  RVI
        cTipDoc:=oProPagX:aDocOrg[oBrw:nArrayAt,5]
        cNumDoc:=ALLTRIM(oProPagX:aDocOrg[oBrw:nArrayAt,6]) // JN 17/10/2016
        nAt    :=ASCAN(oProPagX:aRvi,{|a,n|cTipDoc=a[1] .AND. cNumDoc=ALLTRIM(a[3]) })

        IF nAt>0 .AND. (ABS(uValue)=ABS(oProPagX:aDocOrg[oBrw:nArrayAt,10]) .OR. Empty(uValue)) // Pago Total

           cTipDoc:="RVI"
           cNumDoc:=ALLTRIM(oProPagX:aRvi[nAt,2]) // JN 17/10/2016
           nAt    :=0
           nAt    :=ASCAN(oProPagX:aDocOrg,{|a,n|a[5]=cTipDoc .AND. ALLTRIM(a[6])=cNumDoc})

           IF nAt>0
              oProPagX:aDocOrg[nAt,9]:=lActivar
           ENDIF

        ENDIF

//      ENDIF

   ENDIF
 
   oProPagX:CALTOTAL()

   oProPagX:oPAG_TIPPAG:ForWhen(.F.)

   IF lSave

      IF oBrw:nArrayAt<LEN(oBrw:aArrayData) 
          oBrw:nColSel:=IIF(oBrw:aArrayData[oBrw:nArrayAt+1,5]=0,4,5)
      ENDIF

      oBrw:lAutoDown:=.T.

   ENDIF

RETURN .T.

FUNCTION CALTOTAL()
   LOCAL oBrw:=oProPagX:oBrwD,nDebe:=0,nHaber:=0,I,nMonto:=0,aTotales:={},nDec
   LOCAL nArrayAt:=oBrw:nArrayAt
   LOCAL nTotal :=0,nMtoIva:=0
   LOCAL sn:=0

   AEVAL( oProPagX:oBrw:aArrayData,{|a,n|nMonto:=nMonto+a[6]})

   oProPagX:oBrw:aCols[6]:cFooter:=TRAN(nMonto,"99,999,999,999.99")

   oProPagX:CALRMU()  // Calcula Retencion Municipal

   // Totalizar Otros Pagos
   AEVAL(oProPagX:oBrwO:aArrayData,{|a,n|nTotal:=nTotal + a[5] , nMtoIva:=nMtoIva+PORCEN(a[5],a[6]) })
   oProPagX:oBrwO:aCols[5]:cFooter:=TRAN(nTotal,"9,999,999,999.99")
   oProPagX:nOtrosPag:=nTotal+nMtoIva
   oProPagX:oBrwO:RefreshFooters() // 27/04/2016 Refresh(.F.)

   // Total Otros Pagos
   aTotales:=ATOTALES(oProPagX:oBrwO:aArrayData)
   oProPagX:oBrwO:aCols[5]:cFooter:=TRAN(aTotales[5] ,"999,999,999,999.99")
   oProPagX:oBrwO:RefreshFooters() // 27/04/2016 Refresh(.F.)

   oProPagX:PAG_PAGOS:=nMonto

   IF !Empty(oProPagX:aDocOrg) .AND. oProPagX:nOption<>0

     FOR I=1 TO LEN(oBrw:aArrayData)

       IF oProPagX:aDocOrg[I,9]
          nDebe :=nDebe +oBrw:aArrayData[I,4]
          nHaber:=nHaber+oBrw:aArrayData[I,5]
       ENDIF

     NEXT I

   ELSE

      // ver documento 
      FOR I=1 TO LEN(oBrw:aArrayData)
        nDebe :=nDebe +oBrw:aArrayData[I,4]
        nHaber:=nHaber+oBrw:aArrayData[I,5]
     NEXT I

   ENDIF

   nHaber:=nHaber+oProPagX:PAG_MTORMU

   /*
   // Suma Documentos del Cliente
   */

   oBrw:=oProPagX:oBrwDC

   IF !Empty(oProPagX:aDocOrgCli) 

     FOR I=1 TO LEN(oBrw:aArrayData)

       IF oProPagX:aDocOrgCli[I,9]
          nDebe :=nDebe +oBrw:aArrayData[I,5]
          nHaber:=nHaber+oBrw:aArrayData[I,4]
       ENDIF

     NEXT I

   ENDIF

   oBrw:aCols[4]:cFooter:=TRAN(nDebe ,"999,999,999,999.99")
   oBrw:aCols[5]:cFooter:=TRAN(nHaber,"999,999,999,999.99")
   oBrw:RefreshFooters()

   oProPagX:PAG_MONTO :=(nDebe-nHaber)*IIF(LEFT(oProPagX:PAG_TIPPAG,1)="D",-1,1)

   oProPagX:PAG_DEBE  :=nDebe  // Débito
   oProPagX:PAG_HABER :=nHaber // Haber
   oProPagX:PAG_MONTO :=(oProPagX:PAG_DEBE-oProPagX:PAG_HABER) + oProPagX:nOtrosPag



  // oProPagX:PAG_PAGOS:=INT(oProPagX:PAG_PAGOS*100)/100 
  // oProPagX:PAG_MONTO:=INT(oProPagX:PAG_MONTO*100)/100

   oProPagX:PAG_PAGOS:=VAL(TRAN(oProPagX:PAG_PAGOS,"99999999999.99"))
   oProPagX:PAG_MONTO:=VAL(TRAN(oProPagX:PAG_MONTO,"99999999999.99"))
   
   oProPagX:PAG_MTODIF:=oProPagX:PAG_PAGOS-oProPagX:PAG_MONTO    // (II) 

   oProPagX:oPAG_MONTO:Refresh(.T.)
   oProPagX:oPAG_MTODIF:Refresh(.T.)
   oProPagX:oPAG_PAGOS:Refresh(.T.)

   oBrw:Refresh(.F.)
   oBrw:nArrayAt:=nArrayAt

RETURN .T.

// Seleccionar Documento
FUNCTION DblClick(nKey)
  LOCAL oBrw:=oProPagX:oBrwD,nCol:=4

  nKey := If(nKey == nil,0,nKey )


  IF oProPagX:nOption=0 .OR. oBrw:nColSel=1 .OR. oBrw:nColSel=2

      CursorWait()

      EJECUTAR("DPDOCPROFACCON",NIL,oProPagX:PAG_CODSUC,;
                                    oProPagX:aDocOrg[oBrw:nArrayAt,5],;
                                    oProPagX:aDocOrg[oBrw:nArrayAt,6],;
                                    oProPagX:PAG_CODIGO)

     RETURN NIL

  ENDIF

  IF oProPagX:aDocOrg[oBrw:nArrayAt,3]=-1 
     nCol:=5
  ENDIF

  oBrw:nColSel:=nCol
  oBrw:DrawLine(.T.)
  oBrw:aCols[nCol]:nEditType:=1

  IF nKey<>13
     oBrw:KeyBoard(13)
  ENDIF
RETURN .T.

FUNCTION BrwChange()

  oProPagX:oBrwD:aCols[4]:nEditType:=0
  oProPagX:oBrwD:aCols[5]:nEditType:=0
RETURN .T.

FUNCTION RunKeyD(nKey)
  LOCAL nCol:=oProPagX:oBrwD:nColSel

  IF ValType(oProPagX:oBrwD:aCols[nCol]:oEditGet)="O"
     RETURN .T.
  ENDIF

  IF nKey=13

      oProPagX:DblClick(nKey)

   ELSE

      IF ValType(oProPagX:oBrwD:aCols[nCol]:oEditGet)!="O"
        oProPagX:oBrwD:aCols[nCol]:nEditType:=1
        oProPagX:oBrwD:aCols[nCol]:nKey     :=nKey // Presinó la Misma tecla
        oProPagX:oBrwD:aCols[nCol]:Edit()
      ENDIF

   ENDIF

RETURN .T.

FUNCTION PREGRABAR()
  LOCAL nMonto:=oProPagX:PAG_PAGOS,lOk:=.T.,I,aControls:={},uValue
  LOCAL lSaldo:=SQLGET("DPCAJA","CAJ_VALDIS,CAJ_NOMBRE","CAJ_CODIGO"+GetWhere("=",oProPagX:PAG_CODCAJ))
  LOCAL cNombre:=DPSQLROW(2)
  LOCAL nSaldo:=0,nEfectivo:=0,aCaja:=ACLONE(oProPagX:oBrw:aArrayData)
  LOCAL oTable,cKey

  oProPagX:PAG_ESTADO:=IIF(oProPagX:PAG_ACT=1,"Activo","Nulo")

  IF !EVAL(oProPagX:oPAG_CODCAJ:bValid)
     RETURN .F.
  ENDIF

  oProPagX:PAG_CENCOS:=oDp:cCenCos

  ADEPURA(aCaja,{|a,n| !a[7] })

  IF lSaldo .AND. !Empty(aCaja)

     nSaldo:=SQLGET("VIEW_DPCAJASALDO","SLD_TOTAL","SLD_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND "+;
                                                   "SLD_CODCAJ"+GetWhere("=",oProPagX:PAG_CODCAJ))

     IF nSaldo<ATOTALES(aCaja)[6]

        oProPagX:oPAG_CODCAJ:MsgErr("Monto de Caja :"+ALLTRIM(TRAN(ATOTALES(aCaja)[6],"999,999,999.99"))+CRLF+;
                                    "Supera el Disponible :"+ALLTRIM(TRAN(nSaldo,"999,999,999.99")),cNombre)

        RETURN .F.

     ENDIF
   
  ENDIF

  // oProPagX:PAG_PAGOS-(oProPagX:PAG_MONTO+oProPagX:nOtrosPag),lOk:=.T.
  // Diferencia en el Pago 
  oProPagX:nMtoDif   :=oProPagX:PAG_MTODIF

  // oProPagX:PAG_CODCAJ:=oProPagX:aCajas[oProPagX:oPAG_CODCAJ:nAt,1] // JN 23/02/2016 

  AADD(aControls,oProPagX:oPAG_CODIGO)
  AADD(aControls,oProPagX:oPAG_FECHA )
  AADD(aControls,oProPagX:oPAG_NUMERO)

  FOR I=1 TO LEN(aControls)

     uValue:=aControls[I]:VarGet()

     IF Empty(uValue)
       aControls[I]:MsgErr(aControls[I]:cToolTip,"Valor no puede estar Vacio") // Muestra el Mensaje Tooltips
       RETURN .F.
     ENDIF

     IF EVAL(aControls[I]:bWhen) .AND. !Eval(aControls[I]:bValid)
        RETURN .F.
     ENDIF

  NEXT I


  // Validar Anticipos sin Datos en Caja
  IF LEFT(oProPagX:PAG_TIPPAG,1)$"A" .AND. oProPagX:PAG_PAGOS=0 
     MensajeErr("Es necesario el Monto del Anticipo")
     RETURN .F.
  ENDIF

  IF (oProPagX:PAG_DEBE=0 .AND. oProPagX:PAG_HABER=0) .AND. LEFT(oProPagX:PAG_TIPPAG,1)$"PD"

     IF oProPagX:PAG_PAGOS>0 .AND. LEFT(oProPagX:PAG_TIPPAG,1)="P" 
        oProPagX:oPAG_TIPPAG:SELECT(3)
        oProPagX:oPAG_TIPPAG:VarPut(oProPagX:oPAG_TIPPAG:aItems[3],.T.)
        oProPagX:MensajeErr("No existe Documentos Seleccionados"+CRLF+"Será Activada la Opción: Otros Pagos")
        oProPagX:oFolder:SetOption( 3 )
        DpFocus(oProPagX:oBrwD)
        RETURN .F.
     ENDIF

     oProPagX:MensajeErr("No existe Documentos Seleccionados")
     oProPagX:oFolder:SetOption( 2 )
     DpFocus(oProPagX:oBrwD)

     RETURN .F.

  ENDIF

  IF oProPagX:PAG_PAGOS=0 .AND. LEFT(oProPagX:PAG_TIPPAG,1)$"DP"

     // Documentos Posteados // JN 16/03/2006
     lOk:=.T.
     IF LEFT(oProPagX:PAG_TIPPAG,1)="P" .AND. oProPagX:PAG_DEBE=oProPagX:PAG_HABER
       lok:=.T.
     ENDIF

     IF !lOk
       oProPagX:MensajeErr("Debe Indicar la Forma de Pago")
       oProPagX:oFolder:SetOption( 1 )
       DpFocus(oProPagX:oBrw)
       RETURN .F.
     ENDIF

  ENDIF

  // Devolución debe ser CERO 14/02/2020

  IF (nMonto<>0 .AND. LEFT(oProPagX:PAG_TIPPAG,1)$"D") .AND. .F.

     oProPagX:MensajeErr("Devolución Requiere Monto Menor que Cero")
     oProPagX:oFolder:SetOption( 2 )
     DpFocus(oProPagX:oBrwD)

     RETURN .F.

  ENDIF

  oProPagX:nMontoRev:=0

  IF oProPagX:lRev
     oProPagX:nMontoRev:=EJECUTAR("DPCBTEPAGOREV",oProPagX) // Revaloriza
  ENDIF
 
 // IF nMonto<>0 .AND. !EJECUTAR("DPCBTEPRODIF",oProPagX,nMonto)
  IF oProPagX:nMtoDif<>0 .AND. !EJECUTAR("DPCBTEPRODIF",oProPagX,oProPagX:nMtoDif)
    RETURN .F.
  ENDIF

  // Monto Igual a Anticipo
  IF LEFT(oProPagX:PAG_TIPPAG,1)$"AOR"
    oProPagX:PAG_MONTO:=oProPagX:PAG_PAGOS
  ENDIF

  oProPagX:PAG_USUARI:=oDp:cUsuario

  IF oProPagX:nOption=1 .AND. !oProPagX:lEditar
     oProPagX:AUTONUM()
  ENDIF

//  IF oProPagX:nOption=1 .AND. oProPagX:lEditar .AND. ;
//     SQLGET("DPCBTEPAGO","PAG_NUMERO","PAG_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+" AND "+;
//                                        "PAG_NUMERO"+GetWhere("=",oProPagX:PAG_NUMERO))=oProPagX:PAG_NUMERO

  WHILE oProPagX:nOption=1 .AND.  ;
     !Empty(SQLGET("DPCBTEPAGO","PAG_NUMERO","PAG_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+" AND "+;
                                             "PAG_NUMERO"+GetWhere("=",oProPagX:PAG_NUMERO)))

     IF !oProPagX:lEditar 
       oProPagX:AUTONUM()
     ELSE
       MsgMemo("Comprobante de Pago "+oProPagX:PAG_NUMERO+" ya Existe")
       RETURN ..F.
     ENDIF

     SysRefresh(.T.)

  ENDDO

  oProPagX:cFieldAud  :="PAG_REGAUD" 

  IF oProPagX:nOption=3 .AND. !Empty(oProPagX:cFieldAud)

     cKey  :=oProPagX:GetWhere(oProPagX:cPrimary)
     oTable:=OpenTable("SELECT * FROM DPCBTEPAGO WHERE "+cKey,.T.)
     oTable:End()
     oProPagX:PAG_REGAUD:=EJECUTAR("DPAUDELIMOD",oProPagX,oProPagX:cPrimary,oTable,oProPagX:cPrimary,oProPagX:nOption,oProPagX:PAG_REGAUD)

  ENDIF
 



RETURN .T.

FUNCTION POSTGRABAR()

  // H.C
  SQLUPDATE("DPCBTEPAGO","PAG_USUAR2",oDp:cUsuario,"PAG_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+" AND "+;
                                                   "PAG_NUMERO"+GetWhere("=",oProPagX:PAG_NUMERO))

RETURN EJECUTAR("DPCBTEP_POSGRA",oProPagX)

// Grear RTI
FUNCTION RTI()
    LOCAL cCodSuc,cTipDoc,cCodigo,cNumDoc,nAt:=oProPagX:oBrwD:nArrayAt,cNomDoc
    LOCAL cTipRti:="RTI"


    IIF(oProPagX:oBrwD:aCols[4]:oEditGet=NIL,NIL,oProPagX:oBrwD:aCols[4]:oEditGet:End())
    IIF(oProPagX:oBrwD:aCols[5]:oEditGet=NIL,NIL,oProPagX:oBrwD:aCols[5]:oEditGet:End())

    oProPagX:oBrwD:aCols[4]:oEditGet:=NIL
    oProPagX:oBrwD:aCols[5]:oEditGet:=NIL
    oProPagX:oBrwD:DrawLine()

    cTipDoc:=oProPagX:aDocOrg[nAt,5]
    cNumDoc:=oProPagX:oBrwD:aArrayData[nAt,2]
    cNomDoc:=oProPagX:oBrwD:aArrayData[nAt,1]
    cCodigo:=oProPagX:aDocOrg[nAt,1]

    IF cTipDoc="RET"
       RETURN oCliRet:ISLR()
    ENDIF

//    SysRefresh(.T.)

    // si ya existe la Retencion solo debera Editarla

 
    IF EJECUTAR("DPDOCPRORTI" ,oProPagX:PAG_CODSUC,;
                               cTipDoc           ,;
                               oProPagX:PAG_CODIGO,;
                               cNumDoc           ,;
                               cNomDoc   )

        // Debe Refrescar el Formulario, cuando se crea la retencion

        oProPagX:ImportDoc()
        oProPagX:ASIGNARET(nAt)


    ENDIF

    oFrmRti:oPagos:=oProPagX // 18/04/2017 restaurar

RETURN .T.

FUNCTION ISLR()
    LOCAL cCodSuc,cTipDoc,cCodigo,cNumDoc,nAt:=oProPagX:oBrwD:nArrayAt,cNomDoc

    IIF(oProPagX:oBrwD:aCols[4]:oEditGet=NIL,NIL,oProPagX:oBrwD:aCols[4]:oEditGet:End())
    IIF(oProPagX:oBrwD:aCols[5]:oEditGet=NIL,NIL,oProPagX:oBrwD:aCols[5]:oEditGet:End())

    oProPagX:oBrwD:aCols[4]:oEditGet:=NIL
    oProPagX:oBrwD:aCols[5]:oEditGet:=NIL
    oProPagX:oBrwD:DrawLine()

    cTipDoc:=oProPagX:aDocOrg[nAt,5]
    cNumDoc:=oProPagX:oBrwD:aArrayData[nAt,2]
    cNomDoc:=oProPagX:oBrwD:aArrayData[nAt,1]
    cCodigo:=oProPagX:aDocOrg[nAt,1]

    IF cTipDoc="RTI"
       RETURN oCliRet:RTI()
    ENDIF

    EJECUTAR("DPDOCISLR",oProPagX:PAG_CODSUC,;
                         cTipDoc,;
                         cCodigo,;
                         cNumDoc,;
                         cNomDoc )
 
   oDpDocIslr:oPagos:=oProPagX
RETURN .T.


FUNCTION ImportDoc(cTipDoc,cNumero)
  LOCAL nAt:=oProPagX:oBrwD:nArrayAt,nRow:=oProPagX:oBrwD:nRowSel

  oProPagX:LOADDOC(.F.)

  oProPagX:oBrwD:nArrayAt:=MIN(nAt,LEN(oProPagX:oBrwD:aArrayData))
  oProPagX:oBrwD:nRowSel :=nRow

  oProPagX:oBrwD:Refresh(.F.)

RETURN .T.

FUNCTION RECSETVALCAM()

   oProPagX:PAG_VALCAM:=EJECUTAR("DPGETVALCAM",Left(oProPagX:PAG_CODMON,3),oProPagX:PAG_FECHA,oProPagX:PAG_HORA)

   oProPagX:oPAG_VALCAM:Refresh(.T.)
RETURN .T.

FUNCTION DOCUMENTOS()

    oProPagX:lValDoc:=.F.

    EJECUTAR("DPDOCCXP",NIL,oProPagX:PAG_CODIGO) 
    oProDoc:oPagos:=oProPagX
    oProPagX:lValDoc:=.T.

RETURN .T.

FUNCTION VIEWCAJA()
//EJECUTAR("DPCAJACON",oProPagX:aCajas[oProPagX:oPAG_CODCAJ:nAt,1],oProPagX:aCajas[oProPagX:oPAG_CODCAJ:nAt,2])
  EJECUTAR("DPCAJACON",oProPagX:PAG_CODCAJ,NIL)
RETURN .T.

FUNCTION PRINTER()
  EJECUTAR("DPCBTEPROMNU",oProPagX:PAG_CODSUC,oProPagX:PAG_NUMERO,oProPagX)
RETURN .T.

FUNCTION CONPROVEEDOR()

  CursorWait()
  EJECUTAR("DPPROVEEDORCON",NIL,oProPagX:PAG_CODIGO)

RETURN .T.

// Valida IVA
FUNCTION VALIVA(nIva)
   oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,6]:=nIva
   // oProPagX:SaveOtrPago()
   EJECUTAR("DPCBTEP_OSAVE",oProPagX)
RETURN .T.

FUNCTION VALCTAEGRE(uValue,lNext)

   DEFAULT lNext:=.T.

   IF oProPagX:lAcction 
      oProPagX:lAcction  :=.F.
      RETURN .F. // uValue
   ENDIF

   IF Empty(uValue) .OR. !SQLGET("DPCTAEGRESO","CEG_CODIGO","CEG_CODIGO"+GetWhere("=",uValue))==uValue
      oProPagX:lAcction  :=.T.
      oProPagX:EDITCTAEGRE()
      RETURN .F.
   ENDIF

   IF !lNext
      RETURN .T.
   ENDIF

   oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,1]:=uValue
   oProPagX:oBrwO:SelectCol(2)
   oProPagX:lAcction  :=.F.

RETURN uValue

// Editar Cuenta de Egreso
FUNCTION EDITCTAEGRE()

   LOCAL oBrw  :=oProPagX:oBrwO,oLbx
   LOCAL uValue:=oBrw:aArrayData[oBrw:nArrayAt,1]

   oLbx:=DpLbx("DPCTAEGRESO.LBX")
   oLbx:GetValue("CEG_CODIGO",oBrw:aCols[1],,,uValue)
   oProPagX:lAcction  :=.T.

   SysRefresh(.t.)

RETURN uValue

// Editar Cuenta de Egreso
FUNCTION EDITCENCOS()
   LOCAL oBrw  :=oProPagX:oBrwO,oLbx
   LOCAL uValue:=oBrw:aArrayData[oBrw:nArrayAt,2]

   oLbx:=DpLbx("DPCENCOSACT.LBX")
   oLbx:GetValue("CEN_CODIGO",oBrw:aCols[2],,,uValue)
   oProPagX:lAcction  :=.T.

   SysRefresh(.t.)

RETURN uValue

FUNCTION GetCheque()
  EJECUTAR("DPCBTPAGCHQ",oProPagX)
RETURN NIL

FUNCTION CANCELADO(cCodSuc,cTipDoc,cNumDoc,cCodigo)
   LOCAL nSaldo:=0,cWhere

   cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc           )+" AND "+;
           "DOC_NUMERO"+GetWhere("=",cNumDoc           )+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc           )+" AND "+;
           "DOC_CODIGO"+GetWhere("=",cCodigo           )+" AND "+;
           "DOC_ACT <> 0"

   nSaldo:=MYSQLGET("DPDOCPRO","SUM(DOC_NETO*DOC_CXP)",cWhere)

   nSaldo:=CTOO(nSaldo,"N")

   SQLUPDATE("DPDOCPRO","DOC_ESTADO",IIF(nSaldo=0,"PA","AC"),cWhere+ " AND DOC_TIPTRA='D'")

RETURN .T.

// Calcular Retención Municipal 1X100
FUNCTION CALRMU()
   LOCAL aNumDoc:={},I,aMonto:={},aTipDoc:={}


   IF oProPagX:nOption=0 .OR. LEFT(UPPE(oDp:cTipPer),1)<>"G"
      // Obtiene el Monto desde el Documento
      RETURN .T.
   ENDIF

   FOR I=1 TO LEN(oBrw:aArrayData)
      IF oProPagX:aDocOrg[I,9]
         AADD(aTipDoc,oProPagX:aDocOrg[I,5])
         AADD(aNumDoc,oProPagX:oBrwD:aArrayData[I,2])
         AADD(aMonto ,oProPagX:oBrwD:aArrayData[I,4]+oProPagX:oBrwD:aArrayData[I,5])
      ENDIF
   NEXT I

   oProPagX:PAG_MTORMU:=0

   IF LEN(aTipDoc)>0
     oProPagX:PAG_MTORMU:=EJECUTAR("CBTEPAGOCALRMU",oProPagX:PAG_CODSUC,oProPagX:PAG_CODIGO,aTipDoc,aNumDoc,aMonto)
   ENDIF

RETURN .T.

FUNCTION AUTONUM()
    LOCAL nLen:=8,lZero:=.T.,cMax:=oProPagX:cNumero

    //oProPagX:oPAG_NUMERO:VARPUT(SQLINCREMENTAL("DPCBTEPAGO","PAG_NUMERO","PAG_CODSUC"+GetWhere("=",oDp:cSucursal)),.T.)
     
    oProPagX:PAG_NUMERO :=SQLINCREMENTAL("DPCBTEPAGO","PAG_NUMERO","PAG_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC),NIL,cMax,lZero,nLen)
    oProPagX:PAG_NUMERO :=MAXCHAR(oProPagX:PAG_NUMERO,oProPagX:cNumero)    
    oProPagX:oPAG_NUMERO:VARPUT(oProPagX:PAG_NUMERO , .T.)

RETURN .T.
 
FUNCTION LBXPROVEEDORES()
   LOCAL oDpLbx

   oProPagX:lCliente:=.F.

   IF LEFT(oProPagX:PAG_TIPPAG,1)="D"

     oProPagX:lCliente:=.T.

     oProPagX:SET_CLI_PRO()

     oDpLbx:=DpLbx("DPCLIENTESCXC",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oProPagX:oPAG_CODIGO,NIL)
     oDpLbx:GetValue("CLI_CODIGO",oProPagX:oPAG_CODIGO)

     RETURN .T.
    
   ENDIF

   oProPagX:SET_CLI_PRO()

   IF LEFT(oProPagX:PAG_TIPPAG,1)="P"
     oDpLbx:=DpLbx("DPPROVEEDORCXP.LBX",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL,oProPagX:oPAG_CODIGO)
   ELSE
     oDpLbx:=DpLbx("DPPROVEEDOR.LBX",NIL,"PRO_SITUAC='A' OR PRO_SITUAC='C'",NIL,NIL,NIL,NIL,NIL,NIL,oProPagX:oPAG_CODIGO)
   ENDIF

   oDpLbx:GetValue("PRO_CODIGO",oProPagX:oPAG_CODIGO)

RETURN .T.


FUNCTION LBXCAJA()

   oDpLbx:=DpLbx("DPCAJA.LBX",NIL,"CAJ_ACTIVO=1",NIL,NIL,NIL,NIL,NIL,NIL,oProPagX:oPAG_CODCAJ),;
                oDpLbx:GetValue("CAJ_CODIGO",oProPagX:oPAG_CODCAJ)

RETURN .T.

// Revaloriza el Documento
FUNCTION PAGVALCAM()
RETURN .T.

FUNCTION CANCEL()
RETURN .T.

// Consulta del Documento
FUNCTION VIEW()
   EJECUTAR("DPCBTEPAGOVIEW",oProPagX:PAG_CODSUC,oProPagX:PAG_NUMERO,oProPagX)
RETURN .T.

FUNCTION VALCENCOS(uValue,lNext)
   DEFAULT lNext:=.T.

   IF oProPagX:lAcction 
      oProPagX:lAcction  :=.F.
      RETURN uValue
   ENDIF 

   IF Empty(uValue) .OR. !SQLGET("DPCENCOS","CEN_CODIGO","CEN_CODIGO"+GetWhere("=",uValue))==uValue
      oProPagX:lAcction  :=.T.
      oProPagX:EDITCENCOS()
      RETURN .F.
   ENDIF

   IF !lNext
      RETURN .T.
   ENDIF

   oProPagX:oBrwO:aArrayData[oProPagX:oBrwO:nArrayAt,2]:=uValue
   oProPagX:oBrwO:SelectCol(3)

RETURN uValue

FUNCTION MULRTI()
    LOCAL cCodSuc,cTipDoc,cCodigo,cNumDoc,nAt:=oProPagX:oBrwD:nArrayAt,cNomDoc,aNumDoc:={},I,nAt

    IIF(oProPagX:oBrwD:aCols[4]:oEditGet=NIL,NIL,oProPagX:oBrwD:aCols[4]:oEditGet:End())
    IIF(oProPagX:oBrwD:aCols[5]:oEditGet=NIL,NIL,oProPagX:oBrwD:aCols[5]:oEditGet:End())

    oProPagX:oBrwD:aCols[4]:oEditGet:=NIL
    oProPagX:oBrwD:aCols[5]:oEditGet:=NIL
    oProPagX:oBrwD:DrawLine()

    cTipDoc:=oProPagX:aDocOrg[nAt,5]
    cNumDoc:=oProPagX:oBrwD:aArrayData[nAt,2]
    cNomDoc:=oProPagX:oBrwD:aArrayData[nAt,1]
    cCodigo:=oProPagX:aDocOrg[nAt,1]

    IF cTipDoc="RET"
       RETURN oCliRet:ISLR()
    ENDIF

    oDp:aRti:={}
    EJECUTAR("RTIMULTIFAC",oProPagX:PAG_CODIGO,.T.,oProPagX)

    IF !Empty(oDp:aRti)

        oProPagX:ImportDoc()

        FOR I=1 TO LEN(oDp:aRti)
           nAt:=ASCAN(oProPagX:aDocOrg,{|a,n|a[5]=oDp:aRti[I,1] .AND. a[6]=oDp:aRti[I,2]})

           IF nAt>0
             oProPagX:aDocOrg[nAt,9]:=.T.
           ENDIF

        NEXT I

        oProPagX:ImportDoc()
        oProPagX:ASIGNARET(nAt)

/*
        // Asignar la Retencion 18/06/2015
        nCol  :=IIF(Empty(oProPagX:oBrwD:aArrayData[nAt,4]),5,4)
        oCol  :=oProPagX:oBrwD:aCols[nCol]
        uValue:=oProPagX:oBrwD:aArrayData[nAt,nCol]
        oProPagX:oBrwD:nArrayAt:=nAt

        oProPagX:PUTDEBCRE(oCol,uValue,nCol,lSave)
*/
        // oProPagX:oBrwD:Refresh(.T.)

    ENDIF
     
RETURN .T.

FUNCTION ASIGNARET(nAt,uValue)
  LOCAL oCol,nCol,uValue,lSave:=.T.
   
  // Asignar la Retencion 18/06/2015
  nCol  :=IIF(Empty(oProPagX:oBrwD:aArrayData[nAt,4]),5,4)
  oCol  :=oProPagX:oBrwD:aCols[nCol]

  DEFAULT uValue:=oProPagX:oBrwD:aArrayData[nAt,nCol]

  oProPagX:oBrwD:nArrayAt:=nAt

  oProPagX:PUTDEBCRE(oCol,uValue,nCol,lSave)

RETURN .T.

/*
// Listar Documentos por Fechas
*/
// Hugo Camesella 17-06-2014
FUNCTION LIST()
  LOCAL cWhere:="",dDesde,dHasta 
  LOCAL nAt:=ASCAN(oProPagX:aBtn,{|a,n| a[7]="BROWSE"}),oBtnBrw:=IF(nAt>0,oProPagX:aBtn[nAt,1],NIL)

  cWhere:="PAG_CODSUC"+GetWhere("=",oDp:cSucursal)

  dHasta:=SQLGETMAX("DPCBTEPAGO","PAG_FECHA",oProPagX:cScope)
  dDesde:=FCHINIMES(dHasta)


  IF EJECUTAR("CSRANGOFCH","DPCBTEPAGO",cWhere,"PAG_FECHA",dDesde,dHasta,oBtnBrw)

    cWhere:="PAG_CODSUC"+GetWhere("=",oDp:cSucursal)+;
            IIF(Empty(oDp:dFchIniDoc),""," AND "+GetWhereAnd("PAG_FECHA",oDp:dFchIniDoc,oDp:dFchFinDoc))

//? cWhere,oDp:dFchIniDoc
//            " AND (PAG_FECHA"+GetWhere(">=",oDp:dFchIniDoc)+;
//            " AND PAG_FECHA"+GetWhere("<=",oDp:dFchFinDoc)+")"
 
    oProPagX:ListBrw(cWhere,"DPCBTEPAGO.BRW")

  ENDIF

RETURN .T.


/*
// Listar Proveedores
*/
FUNCTION LISTPROVEE()
   LOCAL lResp,uValue:=SPACE(20),cWhere:="PRO_SITUAC"+GetWhere("=","A")

   lResp:=DPBRWPAG("DPPROVEE.BRW",NIL,@uValue,"PRO_CODIGO",.T.,cWhere)

   IF !Empty(uValue)
      oProPagX:oPAG_CODIGO:VarPut(uValue,.T.)
      EVAL(oProPagX:oPAG_CODIGO:bValid)
   ENDIF

RETURN NIL

/*
// Valida si el Documento Tiene Retención de IVA.
*/
FUNCTION VALRTI()
  LOCAL aLine:=oProPagX:oBrwD:aArrayData[oProPagX:oBrwD:nArrayAt]

ViewArray(aLine)

? "VALIDA SI TIENE RETENCION"

RETURN .T.

FUNCTION VALRIF()

  IF Empty(oProPagX:PAG_CODIGO) .OR. Empty(SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO)))
     MensajeErr("Es Necesario Indicar Código")
     RETURN .T.
  ENDIF

  EJECUTAR("BRPRONOVALRIF","PRO_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO),NIL,NIL,NIL,NIL,"Validar RIF "+oProPagX:PAG_CODIGO)

RETURN 

FUNCTION PAGREFRESCAR()

//  oProPagX:ImportDoc(cTipDoc,cNumero)
//  oProPagX:VALCODPRO()
    oProPagX:LOADDOC(.F.)

RETURN .T.

/*
// Validar Codigo de Caja
*/
FUNCTION VALCODCAJ()
  LOCAL cCodCaj:=SQLGET("DPCAJA","CAJ_CODIGO,CAJ_ACTIVO,CAJ_EGRESO,CAJ_ORGBCO","CAJ_CODIGO"+GetWhere("=",oProPagX:PAG_CODCAJ))
  LOCAL lActivo:=DPSQLROW(2)
  LOCAL lPagos :=DPSQLROW(3)
  LOCAL lOrgBco:=DPSQLROW(4)

  oProPagX:oCajNombre:Refresh(.T.)

  IF !lActivo
    oProPagX:oPAG_CODCAJ:MsgErr("Registro no "+oProPagX:PAG_CODCAJ+" Inactivo","Caja "+oProPagX:PAG_CODCAJ)
    RETURN .F.
  ENDIF

  IF LEFT(oProPagX:PAG_TIPPAG,1)="R" .OR. LEFT(oProPagX:PAG_TIPPAG,1)="F"

    IF !lOrgBco
      oProPagX:oPAG_CODCAJ:MsgErr("No está Autorizada para Realizar "+oProPagX:PAG_TIPPAG,"Caja "+oProPagX:PAG_CODCAJ)
      RETURN .F.
    ENDIF

  ELSE

    IF !lPagos
      oProPagX:oPAG_CODCAJ:MsgErr("No está Autorizada para Hacer Pagos","Caja "+oProPagX:PAG_CODCAJ)
      RETURN .F.
    ENDIF

  ENDIF

  IF LEFT(oProPagX:PAG_TIPPAG,1)="P" .AND. lOrgBco

     // Si tiene
     // oProPagX:oPAG_CODCAJ:MsgErr("Caja de Origen Bancario, Aplicará doble Tributación I.T.F "+CRLF+"Tipo : "+oProPagX:PAG_TIPPAG,"Caja "+oProPagX:PAG_CODCAJ)
     // RETURN .F.

  ENDIF

  IF Empty(oProPagX:PAG_CODCAJ) .OR. Empty(cCodCaj)
     DPFOCUS(oProPagX:oPAG_CODCAJ)
     oProPagX:oPAG_CODCAJ:KeyBoard(VK_F6)
     RETURN .T.
  ENDIF
 

RETURN .T.

/*
// Lectura
*/
FUNCTION LEE_VIEWCXC(cTipo,lPut)
   LOCAL cRif :=SQLGET("DPPROVEEDOR","PRO_RIF","PRO_CODIGO"+GetWhere("=",oProPagX:PAG_CODIGO))
   LOCAL cSql :="CAJ_CODSUC"+GetWhere("=",oProPagX:PAG_CODSUC)+" AND "+;
                "CAJ_CODCAJ"+GetWhere("=",oProPagX:PAG_CODCAJ)+" AND "+;
                "CAJ_RIF"   +GetWhere("=",cRif               )+" AND "+;
                "CAJ_TIPO"  +GetWhere("=",cTipo              )

   DEFAULT lPut:=.T.

   
   IF !Empty(oProPagX:aCajNum) .AND. lPut
  
     oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4]:=oProPagX:aCajNum[1,1] // IF(oProPagX:PAG_MONTO>0,MIN(oProPagX:aCajNum[1,1],oProPagX:PAG_MONTO),oProPagX:aCajNum[1,1])

   ELSE
  
     cSql:="SELECT CAJ_NUMERO,CAJ_MONTO FROM VIEW_CAJACXC_CXP WHERE "+cSql

     oProPagX:aCajNum:=ASQL(cSql)

     IF !Empty(oProPagX:aCajNum) .AND. lPut

       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4]:=oProPagX:aCajNum[1,1]
       oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,6]:=IF(oProPagX:PAG_MONTO>0,MIN(oProPagX:aCajNum[1,2],oProPagX:PAG_MONTO),oProPagX:aCajNum[1,2])

       oProPagX:oBrw:DrawLine(.T.)
       oProPagX:CALTOTAL()

     ELSE

       oProPagX:oBrw:nColSel:=1
       EJECUTAR("XSCGMSGERR",oProPagX:oBrw,cTipo+" no posee Registros en Caja")

       RETURN .F.

     ENDIF

   ENDIF

   IF !Empty(oProPagX:aCajNum)

     oProPagX:oBrw:aCols[4]:nEditType    :=EDIT_GET_BUTTON
     oProPagX:oBrw:aCols[4]:bOnPostEdit  :={|o, uValue| oProPagX:PUTNUMCAJA(uValue) }
     // Muestra lista de Pagos
     oProPagX:oBrw:aCols[4]:bEditBlock   :={||oProPagX:CAJANUMCXC()}

     oProPagX:oBrw:aCols[6]:nEditType    :=1
     oProPagX:oBrw:aCols[6]:bOnPostEdit  :={|o, uValue| oProPagX:PUTMTOCAJA(uValue) }

     // Muestra lista de Pagos

   ENDIF

RETURN .T.

/*
// Listas series de Caja
*/
FUNCTION CAJANUMCXC()
   LOCAL cTipo  :=oProPagX:GETTIPINST()
   LOCAL x      :=oProPagX:LEE_VIEWCXC(cTipo,.F.)
   LOCAL cNumero:=EJECUTAR("DPCBTEP_CAJACXC",oProPagX,oProPagX:aCajNum)

RETURN .T.

/*
// Coloca Monto de Caja/Banco
*/
FUNCTION PUTNUMCAJA(uValue)
   ? "AQUI PUTMONTOCAJA",uValue
RETURN .T.

/*
// Valida Monto del Documento con Número
*/
FUNCTION PUTMTOCAJA(uValue)
    LOCAL cNumero:=oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt,4]
    LOCAL cTipDoc:=oProPagX:GETTIPINST()
    LOCAL nAt:=ASCAN(oProPagX:aCajNum,{|a,n| cNumero=a[1]})

    IF nAt>0
//      ARREDUCE(oProPagX:aCajNum,nAt) // Remover de la Lista Numero de Caja
    ENDIF

    oProPagX:PUTMONTO(NIL,uValue,.T.)

RETURN .T.

/*
// Obtiene Tipo de Instrumento de Caja/Bancos
*/

FUNCTION GETTIPINST()
  LOCAL aLine  :=oProPagX:oBrw:aArrayData[oProPagX:oBrw:nArrayAt]
  LOCAL cTipDoc:=aLine[1],nAt

  IF aLine[7]
     nAt    :=ASCAN(oDp:aCajaInst,{|a,n|ALLTRIM(a[2])=ALLTRIM(aLine[1])})
     cTipDoc:=IF(nAt>0,oDp:aCajaInst[nAt,1],"")
     RETURN cTipDoc
  ENDIF

RETURN cTipDoc

/*
// JN 8/11/2016
*/
FUNCTION CBTLOSTFOCUS()
  AEVAL(oProPagX:aBrwFocus,{|a,n| EJECUTAR("BRWLOSTFOCUS",a)})
RETURN .T.

FUNCTION CBTGOTFOCUS()

  AEVAL(oProPagX:aBrwFocus,{|a,n| EJECUTAR("BRWGOTFOCUS",a)})

  // Browse en Foco Activo
  IF oProPagX:oFolder:nOption=1 .AND. oProPagX:aBrwFocus[1]:nEditCol>0
     DPFOCUS(oProPagX:aBrwFocus[1])
  ENDIF

  // Browse en Foco Activo
  IF oProPagX:oFolder:nOption=2 .AND. oProPagX:aBrwFocus[2]:nEditCol>0
     DPFOCUS(oProPagX:aBrwFocus[2])
  ENDIF

RETURN .T.

FUNCTION BRWOTROSPAGOS(nOption,cOption)
  LOCAL cList:="DPCBTEPAGO_OPA.BRW"
  LOCAL cWhere:="",dDesde,dHasta
  LOCAL nAt:=ASCAN(oProPagX:aBtn,{|a,n| a[7]="BROWSE"}),oBtnBrw:=IF(nAt>0,oProPagX:aBtn[nAt,1],NIL)

  IF nOption=2
     cList:="DPCBTEPAGO_CTABCO.BRW"
  ENDIF

  cWhere:="PAG_CODSUC"+GetWhere("=",oDp:cSucursal)

  dHasta:=SQLGETMAX("DPCBTEPAGO","PAG_FECHA",cWhere)
  dDesde:=FCHINIMES(dHasta)

  IF !EJECUTAR("CSRANGOFCH","DPCBTEPAGO",cWhere,"PAG_FECHA",dDesde,dHasta,oBtnBrw)
      RETURN .T.
  ENDIF

  oProPagX:ListBrw(cWhere,cList)

RETURN .T.

/*
// Browse por Cuenta Contable
*/
FUNCTION BRWXCTA()
RETURN EJECUTAR("CBTEPAGO_BRWXCTA",oProPagX)

/*
// Browse por Cuenta Contable
*/
FUNCTION BRWXPROV()
  LOCAL cWhere:="",cCodigo
  LOCAL cTitle:=" Comprobantes de Pago Agrupados por Proveedor ",aTitle:=NIL,cFind:=NIL,cFilter:=NIL,cSgdoVal:=NIL,cOrderBy:=NIL
  LOCAL nAt:=ASCAN(oProPagX:aBtn,{|a,n| a[7]="BROWSE"}),oBtnBrw:=IF(nAt>0,oProPagX:aBtn[nAt,1],NIL)
  LOCAL cList:="DPCBTEPAGO_OPA.BRW"

  cList:="DPCBTEPAGO.BRW"

  cWhere  := " LEFT JOIN DPPROVEEDOR ON PAG_CODIGO=PRO_CODIGO WHERE 1=1 "
  cOrderBy:=" GROUP BY PAG_CODIGO ORDER BY PAG_CODIGO "
  aTitle  :={"Código;Nombre del Proveedor","Descripción","Desde","Hasta","Acumulado","Cant.;Reg"}

  oDp:aPicture   :={NIL,NIL,NIL,NIL,"999,999,999,999.99","9999"}
  oDp:aSize      :={120,300,60,60,120,40}
  oDp:lFullHeight:=.T.

  cCodigo:=EJECUTAR("REPBDLIST","DPCBTEPAGO","PAG_CODIGO,PRO_NOMBRE,MIN(PAG_FECHA) AS DESDE ,MAX(PAG_FECHA) AS HASTA,SUM(PAG_MONTO),COUNT(*)",.F.,cWhere,cTitle,aTitle,cFind,cFilter,cSgdoVal,cOrderBy,oBtnBrw)

  IF !Empty(cCodigo)

     cWhere:="PAG_CODIGO"+GetWhere("=",cCodigo)
     oDp:dFchIniDoc:=oDp:aLine[3]
     oDp:dFchFinDoc:=oDp:aLine[4] 

     oProPagX:ListBrw(cWhere,cList)

  ENDIF

RETURN .T.

/*
// Browse por Cuenta Bancaria
*/
FUNCTION BRWXCTABCO()
RETURN EJECUTAR("CBTEPAGO_BRWXCTABCO",oProPagX)


/*
// Anticipos
*/
FUNCTION BRWANTICIPO(cWhere,cTitle)
RETURN EJECUTAR("CBTEPAGO_BRWANTICIPO",cWhere,cTitle,oProPagX)

/*
// Otros Pagos
*/
FUNCTION BRWOTROS()
  LOCAL cWhere:="PAG_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND PAG_TIPPAG"+GetWhere("=","O")
  LOCAL cTitle:=" Otros Pagos "
RETURN oProPagX:BRWANTICIPO(cWhere,cTitle)

/*
// Consultar
*/
FUNCTION DOCCONSULTAR()
    LOCAL aLine  :=oProPagX:oBrwD:aArrayData[oProPagX:oBrwD:nArrayAt]
    LOCAL cTipDoc:=SQLGET("DPTIPDOCPRO","TDC_TIPO","TDC_DESCRI"+GetWhere("=",aLine[1]))
    LOCAL cNumero:=aLine[2]

    EJECUTAR("DPDOCPROFACCON",NIL,oDp:cSucursal,cTipDoc,cNumero,oProPagX:PAG_CODIGO)

RETURN .T.

/*
// Anticipos
*/
FUNCTION BRWSERVICIOS(cWhere,cTitle)
  LOCAL cList:="DPCBTEPAGO_OPA.BRW"
  LOCAL dDesde,dHasta,cTitle
  LOCAL nAt:=ASCAN(oProPagX:aBtn,{|a,n| a[7]="BROWSE"}),oBtnBrw:=IF(nAt>0,oProPagX:aBtn[nAt,1],NIL)

  IF Empty(cWhere) .OR. ValType(cWhere)="N"

    cWhere:="PAG_CODSUC"+GetWhere("=",oDp:cSucursal)

  ENDIF

//  IF "O"$RIGHT(cWhere,3)
     cTitle:=" Otros Pagos "
//  ENDIF

  dHasta:=SQLGETMAX("DPCBTEPAGO","PAG_FECHA",cWhere)
  dDesde:=FCHINIMES(dHasta)

  IF !EJECUTAR("CSRANGOFCH","DPCBTEPAGO",cWhere,"PAG_FECHA",dDesde,dHasta,oBtnBrw)
      RETURN .T.
  ENDIF

  IF Empty(cTitle)
     cTitle:=" Anticipos "
  ENDIF

  cTitle:=cTitle+" "+DTOC(dDesde)+"-"+DTOC(dHasta)

  oProPagX:ListBrw(cWhere,"DPCBTEPAGODOCPROCTA.BRW",cTitle)

RETURN .T.

FUNCTION BRWPAGDIF()
   LOCAL cWhere,cTitulo:=oDp:DPCBTEPAGO+" [Descuadres] "

   oProPagX:ListBrw(cWhere,"DPCBTEPAGODIF.BRW",cTitulo)

RETURN .T.

FUNCTION DPDOCCLI()
  LOCAL aDocsC:={}
  LOCAL oBrw,oCol

  AADD(aDocsC,{"","",CTOD(""),4,5,6,7,8,9,.F.,.F.,.F.})

  oProPagX:aDocOrgCli:={}

  oProPagX:nClrPaneCli1:=16772055
  oProPagX:nClrPaneCli2:=16766894

  AADD(oProPagX:aDocOrgCli,{1,2,3,4,5,6,7,8,.F.,10})

  IF oProPagX=NIL
     RETURN NIL
  ENDIF

  // Documentos

  oBrw:=TXBrowse():New(oProPagX:oFolder:aDialogs[6] )

  oBrw:SetArray( ACLONE(aDocsC) ,.F.)
  oBrw:lHScroll       :=.T.
  oBrw:lFooter        :=.T.
  oBrw:lVScroll       :=.T.
  oBrw:l3D            :=.F.
  oBrw:lRecordSelector:=.F.
  oBrw:oFont          :=oFontGrid
  oBrw:lDownAuto      :=.T.
  oBrw:nHeaderLines   := 2

  oProPagX:oBrwDC     :=oBrw

  oCol:=oBrw:aCols[1]
  oCol:cHeader      := "Documento"
  oCol:nWidth       := 200

  oCol:=oBrw:aCols[2]
  oCol:cHeader      := "Número"
  oCol:nWidth       := 110

  oCol:=oBrw:aCols[3]
  oCol:cHeader      := "Fecha"
  oCol:nWidth       := 110

  oCol:=oBrw:aCols[4]
  oCol:cHeader      := "Debe"
  oCol:nWidth       := 255-80
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:cEditPicture :="999,999,999,999.99"


  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwDC, IIF(oBrw:aArrayData[oBrw:nArrayAt,4]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,4],"999,999,999,999.99"))}
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTDEBCRE_CLI(oCol,uValue,4)}
  oCol:cFooter      :="0.00"
  oCol:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwDC,{IIF(!oProPagX:aDocOrgCli[oBrw:nArrayAt,9],CLR_GRAY,CLR_HBLUE), iif( oBrw:nArrayAt%2=0,oProPagX:nClrPaneCli1,oProPagX:nClrPaneCli2 ) } }
//  oCol:bClrFooter   := {||{CLR_HBLUE,8580861}}


  oCol:=oBrw:aCols[5]
  oCol:cHeader      := "Haber"
  oCol:nWidth       := 255-80
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:cEditPicture :="999,999,999,999.99"
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwDC, IIF(oBrw:aArrayData[oBrw:nArrayAt,5]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,5],"999,999,999,999.99"))}
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:bOnPostEdit  :={|oCol,uValue|oProPagX:PUTDEBCRE_CLI(oCol,uValue,5)}
  oCol:cFooter      :="0.00"
  oCol:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwDC,{IIF(!oProPagX:aDocOrgCli[oBrw:nArrayAt,9],CLR_GRAY,CLR_HRED), iif( oBrw:nArrayAt%2=0,oProPagX:nClrPaneCli1,oProPagX:nClrPaneCli2 ) } }
//oCol:bClrFooter   := {||{CLR_HRED,8580861}}

  oCol:=oBrw:aCols[6]
  oCol:cHeader      := "Valor"+CRLF+"Divisa"
  oCol:nWidth       :=120
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwDC, IIF(oBrw:aArrayData[oBrw:nArrayAt,6]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,6],"9,999,999,999.99"))}
  oCol:cFooter      :=""
//  oCol:bClrFooter   := {||{CLR_HRED,8580861}}

  oCol:=oBrw:aCols[7]
  oCol:cHeader      := "Monto en"+CRLF+"Divisa "+oDp:cMonedaExt
  oCol:nWidth       :=110
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwDC, IIF(oBrw:aArrayData[oBrw:nArrayAt,7]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,7],"9,999,999,999.99"))}
  oCol:cFooter      :=""
//  oCol:bClrFooter   := {||{CLR_HRED,8580861}}

  oCol:=oBrw:aCols[8]
  oCol:cHeader      := "Diferencial"+CRLF+"Cambiario"
  oCol:nWidth       :=140
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwDC, IIF(oBrw:aArrayData[oBrw:nArrayAt,7]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,8],"9,999,999,999.99"))}
  oCol:cFooter      :=""
  oCol:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwDC,{IF(oBrw:aArrayData[oBrw:nArrayAt,7]>0,CLR_HBLUE,CLR_HRED), iif( oBrw:nArrayAt%2=0,oProPagX:nClrPaneCli1,oProPagX:nClrPaneCli2 ) } }
//  oCol:bClrFooter   := {||{CLR_HRED,8580861}}

  oCol:=oBrw:aCols[9]
  oCol:cHeader      := "Monto"+CRLF+"Actualizado"
  oCol:nWidth       :=120
  oCol:nDataStrAlign:= AL_RIGHT
  oCol:nHeadStrAlign:=AL_RIGHT
  oCol:nDataStrAlign:=AL_RIGHT
  oCol:nFootStrAlign:=AL_RIGHT
  oCol:bStrData     :={|oBrw|oBrw:=oProPagX:oBrwDC, IIF(oBrw:aArrayData[oBrw:nArrayAt,7]=0,"",TRAN(oBrw:aArrayData[oBrw:nArrayAt,9],"9,999,999,999.99"))}
  oCol:cFooter      :=""
  oCol:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwDC,{IF(oBrw:aArrayData[oBrw:nArrayAt,7]>0,CLR_HBLUE,CLR_HRED), iif( oBrw:nArrayAt%2=0,oProPagX:nClrPaneCli1,oProPagX:nClrPaneCli2 ) } }
//  oCol:bClrFooter   := {||{CLR_HRED,8580861}}

  oCol:=oBrw:aCols[10]
  oCol:cHeader      :='Ret'+CRLF+"IVA"
  oCol:nWidth       := 50
  oCol:AddBmpFile("BITMAPS\ledverde.bmp") 
  oCol:AddBmpFile("BITMAPS\ledrojo.bmp") 
  oCol:bBmpData    := { |oBrw|oBrw:=oProPagX:oBrwDC,IIF(oBrw:aArrayData[oBrw:nArrayAt,10],1,2) }
  oCol:bStrData    :={||""}

  oCol:=oBrw:aCols[11]
  oCol:cHeader      :='Ret'+CRLF+"ISLR"
  oCol:nWidth       := 50
  oCol:AddBmpFile("BITMAPS\ledverde.bmp") 
  oCol:AddBmpFile("BITMAPS\ledrojo.bmp") 
  oCol:bBmpData    := { |oBrw|oBrw:=oProPagX:oBrwDC,IIF(oBrw:aArrayData[oBrw:nArrayAt,11],1,2) }
  oCol:bStrData    :={||""}

  oCol:=oBrw:aCols[12]
  oCol:cHeader      :='Ret'+CRLF+"Mun"
  oCol:nWidth       := 50
  oCol:AddBmpFile("BITMAPS\ledverde.bmp") 
  oCol:AddBmpFile("BITMAPS\ledrojo.bmp") 
  oCol:bBmpData    := { |oBrw|oBrw:=oProPagX:oBrwDC,IIF(oBrw:aArrayData[oBrw:nArrayAt,12],1,2) }
  oCol:bStrData    :={||""}

  oBrw:bClrStd      := {|oBrw|oBrw:=oProPagX:oBrwDC,{IIF(!oProPagX:aDocOrgCli[oBrw:nArrayAt,9],CLR_GRAY,CLR_BLACK), iif( oBrw:nArrayAt%2=0,oProPagX:nClrPaneCli1,oProPagX:nClrPaneCli2) } }

  oBrw:bKeyDown     := {|nKey|oProPagX:RunKeyD(nKey)}
  oBrw:bLDblClick   := {|oBrw|oProPagX:CLI_DblClick() }
  oBrw:bChange      := {|oBrw|oProPagX:CLI_BrwChange()}

//  oBrw:bClrFooter   := {||{CLR_GREEN,8580861}}

  oBrw:bClrHeader  := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
  oBrw:bClrFooter  := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

  AEVAL(oBrw:aCols,{|oCol,n|oCol:bClrHeader   := {|oBrw|oBrw:=oProPagX:oBrwDC,{oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}},;
                            oCol:oFooterFont  :=oFont,;
                            oCol:oHeaderFont  :=oFont})

  oBrw:CreateFromCode()

  oBrw:SetColor(NIL,16772055) // ,16766894

RETURN NIL

FUNCTION CLI_BrwChange()

  oProPagX:oBrwDC:aCols[4]:nEditType:=0
  oProPagX:oBrwDC:aCols[5]:nEditType:=0

RETURN .T.

/*
// Seleccionar Documento
*/
FUNCTION CLI_DblClick(nKey)
  LOCAL oBrw   :=oProPagX:oBrwDC,nCol:=4
  LOCAL aLine  :=oProPagX:aDocOrgCli[oBrw:nArrayAt]
  LOCAL cTipDoc:=aLine[5],cNumero:=aLine[6]

  DEFAULT nKey:=0

  IF oProPagX:nOption=0
      CursorWait()

      EJECUTAR("DPDOCCLIFAVCON",NIL,oProPagX:PAG_CODSUC,;
                                    cTipDoc,;
                                    cNumero,;
                                    oProPagX:PAG_CODIGO)

     RETURN NIL
  ENDIF


  // antes IF oCliRecX:aDocOrg[oBrw:nArrayAt,3]="C"
  IF oProPagX:aDocOrgCli[oBrw:nArrayAt,3]=-1
     nCol:=5
  ENDIF

  oBrw:nColSel:=nCol
  oBrw:DrawLine(.T.)
  oBrw:aCols[nCol]:nEditType:=1

  IF nKey<>13
     oBrw:KeyBoard(13)
  ENDIF
 

RETURN .T.


FUNCTION PUTDEBCRE_CLI(oCol,uValue,nCol,lSave)
   LOCAL oBrw:=oProPagX:oBrwDC,nDebe:=0,nHaber:=0,I

   DEFAULT lSave:=.T.

   IF lSave

      oBrw:aCols[nCol]:oEditGet:End()
      oBrw:aCols[nCol]:oEditGet:=NIL

/*
      IF uValue>ABS(oCliRecX:aDocOrg[oBrw:nArrayAt,10])
         MensajeErr("Pago no puede superar Saldo: "+;
                    ALLTRIM(TRAN(oCliRecX:aDocOrg[oBrw:nArrayAt,10],"999,999,999,999.99"))+"del Documento")
         RETURN .F.
      ENDIF
*/

      oProPagX:aDocOrgCli[oBrw:nArrayAt,9]:=.T.

      oBrw:aArrayData[oBrw:nArrayAt,nCol]:=uValue
      oBrw:lAutoDown:=.F.     // estaba .T. se cambio a .F. 2.0
      oBrw:nColSel:=4

      IF uValue=0 // Recupera su Valor
        oCbtePag:aDocOrgCli[oBrw:nArrayAt,9]:=.F.
        oBrw:aArrayData[oBrw:nArrayAt,nCol]:= ABS(oCbtePag:aDocOrgCli[oBrw:nArrayAt,10])
      ELSE

       // EJECUTAR("DPRECIBOSCLIASO",oCliRecX)

      ENDIF


   ENDIF

//ViewArray(oCbtePag:aDocOrgCli)

// oProPagX:CALMONTO()
   oProPagX:CALTOTAL()

   IF lSave

      IF oBrw:nArrayAt<LEN(oBrw:aArrayData) 
          oBrw:nColSel:=IIF(oBrw:aArrayData[oBrw:nArrayAt+1,5]=0,4,5)
      ENDIF

      oBrw:lAutoDown:=.T.

   ENDIF

RETURN .T.


/*
// Texto de Cliente/Proveedor
*/
FUNCTION SET_CLI_PRO()

  IF oProPagX:lCliente
     oProPagX:oSayProveedor:SetText(oDp:xDPCLIENTES)
  ELSE
     oProPagX:oSayProveedor:SetText(oDp:xDPPROVEEDOR)
  ENDIF

RETURN .T.
// EOF






