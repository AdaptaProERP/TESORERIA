// Programa   : DPDOCCXP 
// Fecha/Hora : 22/11/2004 23:10:42
// Propósito  : Documentos de Cuentas por Pagar
// Creado Por : Juan Navas
// Llamado por: Ventas y Cuentas por Cobrar
// Aplicación : VENTAS
// Tabla      : DPDOCPRO

#INCLUDE "DPXBASE.CH"
#INCLUDE "Constant.ch"
#INCLUDE "SAYREF.CH"

PROCE MAIN(cTipDoc,cCodPro,cTipDoc_,cNumDoc,aDataGrid,cTipPro,cCodSuc,cCenCos)
  LOCAL cTitle:="",cExcluye:="",cScope,cSql,cNomDoc:="",aIva:={},oSayRef,nContar:=0,bBlq:={||.T.}
  LOCAL nAt,I,cTip_Doc,lNinguno:=.f.
  LOCAL oFont,oFontG,oFontB,oCol,oFontGrid,oBrw,aDataIva,oGrp,cWhere:="",cLibro,oData
  LOCAL aTipDoc:={}
  LOCAL aDocs  :={}
  LOCAL aSerie :=ASQL("SELECT SFI_MODELO FROM DPSERIEFISCAL ORDER BY SFI_MODELO")
  LOCAL aTipIva:=ASQL("SELECT TIP_CODIGO,TIP_DESCRI,0 AS BASE,0 AS IVA,0 AS MTOIVA FROM DPIVATIP WHERE TIP_ACTIVO=1 AND TIP_COMPRA=1")
  LOCAL cDpIni :="DP\DPTIPDOCPRO.TXT"
  LOCAL cNumCbte:="",lContab:=.F.,lDefine:=.F.
  LOCAL cOrderBy:="DOC_FECHA,DOC_HORA,DOC_CODIGO,DOC_NUMERO,DOC_TIPTRA"
  LOCAL aCoors   :=GetCoors( GetDesktopWindow() )

  DEFAULT cCodSuc:=oDp:cSucursal

  cWhere:=" TDC_CXP<>'N' AND TDC_DOCEDI=1 AND TDC_ACTIVO=1 "

//  DEFAULT 
  oDp:GetnCltText:=0
  oDp:GetnClrPane:=CLR_WHITE

  IF !ValType(oDp:cCenCos)="C"
    oData:=DATASET("EMPRESA","USER")
    oDp:cCenCos    :=oData:Get("cCenCos"   ,STRZERO(1,8))
    oData:End()
  ENDIF

//ViewArray(aTipIva)


//  EJECUTAR("DPCAMPOSADD","DPDOCPRO"   ,"DOC_CREFIS","L",1 ,0,"Derecho a Crédito Fiscal")
//  EJECUTAR("DPCAMPOSADD","DPDOCPROCTA","CCD_CODPRO","C",10,0,"Código Proveedor REI/CPT"  ,"",NIL,.F.)
//  EJECUTAR("TIPDOCPROCPT") // Agregar Tipo de Documento CPT

  DEFAULT oDp:P_LCtaEgrCxP:=.T.,;
          cTipPro:=""

  DEFAULT oDp:aCoors:=GetCoors( GetDesktopWindow() )

  IF Empty(aTipIva)
     EJECUTAR("DPDATACREA",.T.)
     MensajeErr("Requiere Definir Alícuotas de IVA","Active Alícuotas de IVA")
     DPLBX("DPIVATIP.LBX")
     RETURN .F.
  ENDIF

  oDp:nClrDebe :=CLR_BLUE
  oDp:nClrHaber:=CLR_HRED


  IF !Empty(cTipPro)

    cSql:=" SELECT TDC_TIPO FROM DPTIPDOCPRO "+;
          " INNER JOIN DPTIPDOCPROXTIP ON TDC_TIPO=TXT_TIPDOC AND TXT_TIPPRO"+GetWhere("=",cTipPro)

    aDocs:=ASQL(cSql)
    AEVAL(aDocs,{|a,n| aDocs[n]:=a[1]})

    IF !Empty(aDocs)
       cWhere:=cWhere+" AND ("+GetWhereOr("TDC_TIPO",aDocs)+")"
    ENDIF

  ENDIF

  IIF( cTipDoc=NIL,lDefine:=.T.)
  //IIF( lDefine:=.T.)

  IF !FILE(cDpIni)
     dpwrite(cDpIni,cDpIni)
     SQLUPDATE("DPTIPDOCPRO","TDC_LITEM",1,"TDC_IVA=1")
  ENDIF

  IF !Empty(cTipDoc_)
    cWhere:="TDC_TIPO"+GetWhere("=",cTipDoc_)
  ENDIF


  aDocs:=ASQL("SELECT TDC_TIPO,TDC_DESCRI FROM DPTIPDOCPRO WHERE "+cWhere+" ORDER BY TDC_TIPO ")

  DEFAULT cTipDoc:="FAC",oDp:cPictDocOtros:=FIELDPICTURE("DPDOCPRO" ,"DOC_OTROS" ,.T.),;
          aDataGrid        :={}

  cTitle:="Documentos de Cuentas por Pagar "+IF(Empty(cTipPro),"","["+cTipPro+"]")

  AEVAL(aDocs  ,{|a,n|AADD(aTipDoc,a[1]),aDocs[n]:=a[2]})

  IF Empty(aDocs)
     MsgMemo("No hay Tipo de Documentos Activos")
     RETURN .F.
  ENDIF

  cTipDoc:=IIF(Empty(cTipDoc) .OR. ASCAN(aTipDoc,cTipDoc)=0 ,aTipDoc[1],cTipDoc)

  AEVAL(aSerie ,{|a,n|aSerie[n]:=a[1]})
  AEVAL(aTipIva,{|a,n|aTipIva[n,3]:=0,aTipIva[n,4]:=0,aTipIva[n,5]:=0})

  FOR I=1 TO LEN(aTipIva)
    aTipIva[I,4]:=EJECUTAR("IVACAL",aTipIva[I,1],2,oDp:dFecha)
  NEXT 

//ViewArray(aTipIva[I,4])

  IF !SQLGET("DPDOCPRO","DOC_TIPDOC","DOC_TIPDOC"+GetWhere("=",cTipDoc)+;
               " AND DOC_TIPTRA='D' AND DOC_DOCORG='D' ")==cTipDoc .AND. lDefine

     nContar :=1
     cTip_Doc:=""

     WHILE nContar<=LEN(aTipDoc) .AND. Empty(cTip_Doc)

       cTip_Doc:=MYSQLGET("DPDOCPRO","DOC_TIPDOC","DOC_CODSUC"+GetWhere("=",cCodSuc         )+" AND "+;
                                                  "DOC_TIPDOC"+GetWhere("=",aTipDoc[nContar])+" AND "+;
                                                  "DOC_TIPTRA='D' AND DOC_DOCORG='D'")

       nContar++

     ENDDO

     cTipDoc:=IIF(Empty(cTip_Doc),cTipDoc,cTip_Doc)

  ELSE

     cTip_Doc:=cTipDoc

  ENDIF

  lNinguno:=Empty(cTip_Doc)

  AADD(aIva,{"GN",0,0,0})

  nAt    :=MAX(ASCAN(aTipDoc,cTipDoc),1)
  cNomDoc:=aDocs[nAt]

  cScope:="DOC_CODSUC"+GetWhere("=",cCodSuc      )+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",cTipDoc      )+" AND "+;
          "DOC_TIPTRA='D' AND DOC_DOCORG='D'"

  // 30/04/2023
  IF !Empty(cCenCos)
    cWhere:="DOC_CENCOS"+GetWhere("=",cCenCos)
  ENDIF


  IF !Empty(cCodPro)

     cScope:=cScope+" AND DOC_CODIGO"+GetWhere("=",cCodPro)

     IF !Empty(cNumDoc)
         cScope:=cScope+" AND DOC_NUMERO"+GetWhere("=",cNumDoc)
     ENDIF

  ENDIF

  IF Empty(oDp:cModeVideo)
    DEFINE FONT oFont      NAME "Tahoma" SIZE 0, -11 BOLD
    DEFINE FONT oFontGrid  NAME "Tahoma" SIZE 0, -11
    DEFINE FONT oFontB     NAME "Tahoma"  SIZE 0, -12 BOLD
  ELSE
    DEFINE FONT oFont      NAME "Tahoma" SIZE 0, -14 BOLD
    DEFINE FONT oFontGrid  NAME "Tahoma" SIZE 0, -14
    DEFINE FONT oFontB     NAME "Tahoma" SIZE 0, -14 BOLD
  ENDIF

  EJECUTAR("DPPRIVCOMLEE",cTipDoc,.F.) // Lee los Privilegios del Usuario

  DOCENC(cTitle,"oDocCxP","DPDOCCXP.EDT")

  cLibro:=SQLGET("DPTIPDOCPRO","TDC_LIBCOM","TDC_TIPO"+GetWhere("=",cTipDoc))

  oDocCxP:lBar:=.T.
  oDocCxP:SetScope(cScope)
  oDocCxP:SetTable("DPDOCPRO","DOC_CODIGO,DOC_NUMERO",NIL, NIL, NIL,NIL,cOrderBy) 

  oDocCxP:cWhereRecord:=cScope
  oDocCxP:aDataGrid  :=ACLONE(aDataGrid)    // ag dp

  oDocCxP:cPrimary   :="DOC_CODSUC,DOC_TIPDOC,DOC_CODIGO,DOC_NUMERO"
  oDocCxP:cNomDoc    :=cNomDoc
  oDocCxP:aTipDoc    :=ACLONE(aTipDoc)
  oDocCxP:cTipDoc    :=cTipDoc
  oDocCxP:cCodSuc    :=cCodSuc
  oDocCxP:cTipDocAnt :=cTipDoc
  oDocCxP:xCodPro    :=cCodPro
  oDocCxP:aTipIva    :=ACLONE(aTipIva)  // DOC3
  oDocCxP:aIva       :=ACLONE(aIva)
  oDocCxP:nBase      :=0
  oDocCxP:nBruto     :=0
  oDocCxP:nMtoExo    :=0   // Exonerado 
  oDocCxP:nMtoDes    :=0   // Monto Descuento
  oDocCxP:nMtoRec    :=0   // Monto Recargo
  oDocCxP:nMtoBru    :=0   // Monto Bruto
  oDocCxP:nMtoIva    :=0   // Monto IVA
  oDocCxP:DOC_CODIGO_:=""  // Código
  oDocCxP:lDefine    :=lDefine
  oDocCxP:cProgram   :="DPDOCCXP"
  oDocCxP:cSkip      :="DPDOCCXPSKIP"
  oDocCxP:lPar_Zero  :=.T.
  oDocCxP:nPar_Len   :=10
  oDocCxp:cWherePro  :=IF(!Empty(cTipPro),"PRO_TIPO"+GetWhere("=",cTipPro)+" AND ","")+"LEFT(PRO_SITUAC,1)='A'"
  oDocCxp:cFileLbx   :=EJECUTAR("LBXTIPPROVEEDOR",cTipPro,.F.)
  oDocCxP:cWhereRec  :=""
  oDocCxP:cFileBrw   :="DPDOCPRO.BRW"

  oDocCxP:cCodSuc    :=cCodSuc
  oDocCxP:cCenCos    :=cCenCos

  oDocCxP:cMemo      :=""               // CampoMemo
  oDocCxP:lIva       :=.F.
  oDocCxP:lCta       :=.F.              // No tiene Cuentas Contables
  oDocCxP:lCtaEgr    :=oDp:P_LCtaEgrCxP // Utiliza Cuentas de Egreso
  oDocCxP:lFacAfe    :=.F.              // Editar Factura Afectada
  oDocCxP:lInv       :=.F.              // no tiene productos
  oDocCxP:cCancel    :="CANCEL"
  oDocCxP:oFrmDoc    :=NIL
  oDocCxP:oPagos     :=NIL
  oDocCxP:lPar_Moneda:=.F.
  oDocCxP:lValUnique :=.F.              // No Valida VALUNIQUE
  oDocCxP:cNumDoc    :=""               // Documento para Modificar
  oDocCxP:cCodigo    :=""               // Código del Proveedor
  oDocCxP:lNinguno   :=lNinguno
  oDocCxP:lNumFis    :=.F.              // Numero Fiscales
  oDocCxP:cTipPro    :=cTipPro 
  oDocCxP:dFchDec    :=FCHFINMES(oDp:dFecha) // Fecha Declaración Siempre debe ser Fin de Mes y debera ser validada
  oDocCxP:lStart     :=.T.
         
  oDocCxP:dFchDocAfe :=CTOD("") 

  // Cheque Devuelto
  oDocCxP:Chk_cCodBco:=SPACE(06)
  oDocCxP:Chk_cCuenta:=SPACE(20)
  oDocCxP:Chk_cCheque:=SPACE(20)

  oDocCxP:SetMemo("DOC_NUMMEM","Descripción Amplia")

  EJECUTAR("DPDOCPROPAR",oDocCxP,cTipDoc)


  IF DPVERSION()>4
    oDocCxP:SetAdjuntos("DOC_FILMAI") // Vinculo con DPFILEEMP
  ENDIF

  oDocCxP:AddBtn("MENU.bmp","Menú de Opciones","(oDocCxP:nOption=0)",;
                            "EJECUTAR('DPPRODOCMNU',oDocCxP:DOC_CODSUC,;
                             oDocCxP:DOC_TIPDOC,;
                             oDocCxP:DOC_NUMERO,;
                             oDocCxP:DOC_CODIGO,NIL,oDocCxP)","PRO")



  oDocCxP:AddBtnEdit("PROVEEDORES.bmp","Creación Rápida del Proveedor","(oDocCxP:nOption=1 .OR. oDocCxP:nOption=3 )",;
                              "EJECUTAR('DPCREAPROVEE',oDocCxP:oDOC_CODIGO,'Prestador de Servicios')","PRO")

  oDocCxP:nBtnWidth:=42
  oDocCxP:cBtnList :="xbrowse2.bmp"

  oDocCxP:BtnSetMnu("BROWSE","Tipo de Documento"     ,"BRWXTIP")  // Tipo Documento
  oDocCxP:BtnSetMnu("BROWSE","Agrupado por Proveedor","BRWXPRO")  // Por Proveedor
  oDocCxP:BtnSetMnu("BROWSE","Agrupado por "+oDp:DPCLACTAEGRE,"BRWXCTAE")  // Por Cuenta de Egreso
  oDocCxP:BtnSetMnu("BROWSE","Agrupado por "+oDp:DPCTA       ,"BRWXCTA")   // Por Cuenta Contable

/*
  oDocCli:BtnSetMnu("BROWSE","Pendientes de Pago"   ,"BRWXPAG")  // Por Pago
  oDocCli:BtnSetMnu("BROWSE","Pagadas"              ,"BRWPAGD")  // Pagadas
  oDocCli:BtnSetMnu("BROWSE","Registros Activo"     ,"BRWXPAG")  // Activos
  oDocCli:BtnSetMnu("BROWSE","Sin Anulados"         ,"BRWXNOA")  // No Anuladas
  oDocCli:BtnSetMnu("BROWSE","Anuladas"             ,"BRWANUL")  // Anuladas
  oDocCli:BtnSetMnu("BROWSE","Agrupado Por Vendedor","BRWXVEN")  // Por Vendedor
  oDocCli:BtnSetMnu("BROWSE","Agrupado Por Lote"    ,"BRWXLOT")  // Por Lotes
  oDocCli:BtnSetMnu("BROWSE","Agrupado Por Producto","BRWXINV")  // Por Lotes
  oDocCli:BtnSetMnu("BROWSE","Liberar Filtros"      ,"BRWXLIB")  // Liberar Filtro
*/

//EJECUTAR("DPDOCPROPAR",oDocCxP,cTipDoc)

  oDocCxP:cList  :=NIL
//  oDocCxP:Windows(0,0,600,1010)


  oDocCxP:lAutoSize  :=(aCoors[4]>1200)  // . AND. ISRELEASE("18.11")  // AutoAjuste 

  IF oDocCxP:lAutoSize 
    aCoors[4]:=MIN(aCoors[4],1920)
    oDocCxP:Windows(0,0,600-25	,aCoors[4]-20) 
  ELSE
    oDocCxP:Windows(0,0,600-25,1010)
  ENDIF


  @ 3.5,1 SAY oDocCxP:oSayRef PROMPT GetFromVar("{oDp:xDPPROVEEDOR}")+":" SIZE 42,12 RIGHT

  SayAction(oDocCxP:oSayRef,{||oDocCxP:CONPROVEEDOR()})

  @ 3,1 SAY "Tipo:" RIGHT SIZE 40,10

  @ 4.5,1 SAY "Número:" RIGHT SIZE 40,10

  @ 2,2 SAY "Emisión:" RIGHT SIZE 40,10

  @ 4,17 SAY oDocCxP:oProNombre PROMPT EJECUTAR("COMPRONOMBRE",oDoc) SIZE 140,09

  @ 2.5,1 COMBOBOX oDocCxP:oTipDoc VAR oDocCxP:cNomDoc ITEMS aDocs;
          SIZE 120,40 ON CHANGE oDocCxP:CHANGEDOC() VALID oDocCxP:CHANGEDOC();
          WHEN (((oDocCxP:nOption=1 .OR. oDocCxP:nOption=5 .OR. oDocCxP:DOC_NETO<>0);
                .OR. (oDocCxP:nOption=0 .OR. oDocCxP:lNinguno ) .AND. LEN(oDocCxP:aTipDoc)>1;
                .AND.oDocCxP:lDefine) .AND. oDocCxP:nOption<>3) .AND. LEN(oDocCxP:oTipDoc:aItems)>1 UPDATE

  ComboIni(oDocCxP:oTipDoc)

  @ 1.5,57 SAY oDocCxP:oEstado PROMPT EJECUTAR("DPDOCPROEDO",oDocCxP:DOC_CODSUC,oDocCxP:cTipDoc,oDocCxP:DOC_CODIGO,;
                                               oDocCxP:DOC_NUMERO,;
                                               NIL,oDocCxP:DOC_CXP,oDocCxP:DOC_NETO,oDocCxP)

// ACTION (oDpLbx:=oDpLbx:=DpLbx(oDocCxp:cFileLbx,NIL,oDocCxP:cWherePro,NIL,NIL,NIL,NIL,NIL,NIL,oDocCxP:oDOC_CODIGO),;
//         oDpLbx:GetValue("PRO_CODIGO",oDocCxP:oDOC_CODIGO)); 


  @ 5.0,10 BMPGET oDocCxP:oDOC_CODIGO VAR oDocCxP:DOC_CODIGO;
                  VALID EJECUTAR("DPCEROPROV",oDocCxP:DOC_CODIGO,oDocCxP:oDOC_CODIGO);
                  .AND. oDocCxP:VALCODPRO();
                  NAME "BITMAPS\FIND.BMP"; 
                  ACTION oDocCxP:LBXPROVEEDOR();
                  WHEN (AccessField("DPDOCPRO","DOC_CODIGO",oDocCxP:nOption);
                       .AND. (oDocCxP:nOption=1 .OR. oDocCxP:nOption=3) .AND. Empty(oDocCxP:xCodPro));
                  SIZE 58,10

//05/10/2016
//                       .AND. oDocCxP:nOption=1 .AND. Empty(oDocCxP:xCodPro));


  oDocCxP:oDOC_CODIGO:bKeyDown:={|nKey|oDocCxP:PosKeyDown(nKey)}

  oDocCxP:oDOC_CODIGO:cToolTip:="Código del Proveedor"


// VALID oDocCxP:VALNUMERO(.F.);

  @ 6.0,1 BMPGET oDocCxP:oDOC_NUMERO VAR oDocCxP:DOC_NUMERO;
                 VALID oDocCxP:lDOC_NUMERO;
                 WHEN (AccessField("DPDOCPRO","DOC_NUMERO",oDocCxP:nOption);
                      .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lPar_EditNum .AND. !Empty(oDocCxP:DOC_CODIGO));
                 SIZE 40,10 

  oDocCxP:oDOC_NUMERO:bLostFocus:={||oDocCxP:oDOC_NUMERO:SetColor(CLR_RED,CLR_WHITE),oDocCxP:VALNUMERO(.T.)}
  oDocCxP:oDOC_NUMERO:lCancel:=.T.

  oDocCxP:oDOC_NUMERO:cToolTip:="Número del Documento "

/*
// Control Fiscal
*/

  IF oDocCxP:cTipDoc="PPF"
    // oDocCxP:DOC_TIPDOC="PPF"


    @ 6.0,10 GET oDocCxP:oDOC_NUMFIS  VAR oDocCxP:DOC_NUMFIS;
             VALID oDocCxP:VALNUMFIS();
             WHEN (AccessField("DPDOCPRO","DOC_NUMFIS",oDocCxP:nOption);
                  .AND. oDocCxP:nOption!=0);
             SIZE 41,10

    oDocCxP:oDOC_NUMFIS:cToolTip:="#Referencia:"

  ELSE

    @ 6.0,10 GET oDocCxP:oDOC_NUMFIS  VAR oDocCxP:DOC_NUMFIS;
             VALID oDocCxP:VALNUMFIS();
             WHEN (oDocCxP:lPar_LibCom .AND. AccessField("DPDOCPRO","DOC_NUMFIS",oDocCxP:nOption);
                  .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lIva .AND. !Empty(oDocCxP:DOC_CODIGO));
             SIZE 41,10

    oDocCxP:oDOC_NUMFIS:cToolTip:="#Control Fiscal:"

  ENDIF


  @ 12,10 BMPGET oDocCxP:oDOC_FECHA  VAR oDocCxP:DOC_FECHA  PICTURE "99/99/9999";
          NAME "BITMAPS\Calendar.bmp";
          ACTION LbxDate(oDocCxP:oDOC_FECHA ,oDocCxP:DOC_FECHA);
          VALID oDocCxP:lDOC_FECHA;
          WHEN (AccessField("DPDOCMOV","DOC_FECHA",oDocCxP:nOption);
                .AND. oDocCxP:nOption!=0);
          SIZE 45,10


//VALID (oDocCxP:VALFECHA() .AND. EJECUTAR("DPVALFECHA",oDocCxP:DOC_FECHA,.T.,.T.,oDocCxP:oDOC_FECHA) .AND. ;
//       oDocCxP:PROVALCAM());

  oDocCxP:oDOC_FECHA:bLostFocus:={||oDocCxP:VALFECHA()}


// IF(Empty(oDocCxP:DOC_FECHA) .AND. oDocCxP:nOption=1 .OR. oDocCxP:nOption=3,(oDocCxP:oDOC_FECHA:VarPut(IF(oDocCxP:nOption=1,oDp:dFecha,oDocCxP:DOC_FECHA_),.T.),;
//                                                                 oDocCxP:oDOC_FECHA:MsgErr(oDocCxP:oDOC_FECHA:cToolTip,"No Puede estar Vacia")),;
//                                                                 NIL)}

  oDocCxP:oDOC_FECHA:cToolTip:="Fecha de Emisión"

  @ 02,10 BMPGET oDocCxP:oDOC_FCHDEC  VAR oDocCxP:DOC_FCHDEC  PICTURE "99/99/9999";
           NAME "BITMAPS\Calendar.bmp";
           ACTION LbxDate(oDocCxP:oDOC_FCHDEC ,oDocCxP:DOC_FCHDEC);
           VALID oDocCxP:lDOC_FCHDEC;
           WHEN (AccessField("DPDOCMOV","DOC_FCHDEC",oDocCxP:nOption);
                .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lPar_LIBCOM);
           SIZE 45,10

//  VALID (oDocCxP:VALFCHDEC(.F.) .AND. EJECUTAR("DPVALFECHA",oDocCxP:DOC_FCHDEC,.T.,.T.,oDocCxP:oDOC_FCHDEC));

  oDocCxP:oDOC_FECHA:cToolTip:="Fecha de Declaración"

  oDocCxP:oDOC_FCHDEC:bLostFocus:={|| oDocCxP:VALFCHDEC()}


//  oDocCxP:oDOC_FCHDEC:bLostFocus:={||IF(Empty(oDocCxP:DOC_FCHDEC) .AND. (oDocCxP:nOption=1 .OR. oDocCxP:nOption=3),(oDocCxP:oDOC_FCHDEC:VarPut(IF(oDocCxP:nOption=1,oDp:dFecha,oDocCxP:DOC_FCHDEC_),.T.),;
//                                                                   oDocCxP:oDOC_FCHDEC:MsgErr(oDocCxP:oDOC_FCHDEC:cToolTip,"No Puede estar Vacia")),;
//                                                                   NIL)}
  // ? oDocCxP:DOC_TIPDOC,"oDocCxP:DOC_TIPDOC"
  //  IF oDocCxP:DOC_TIPDOC="PPF"

  IF oDocCxP:cTipDoc="PPF"
    @ 6.0,1 SAY "#Referencia:" RIGHT SIZE NIL,10
  ELSE
    @ 6.0,1 SAY "#Control Fiscal:" RIGHT SIZE NIL,10
  ENDIF


  @ 3,1 CHECKBOX oDocCxP:oDOC_CREFIS VAR oDocCxP:DOC_CREFIS PROMPT ANSITOOEM("Sin Derecho a Crédito Fiscal");
           WHEN (oDocCxP:lPar_LibCom .AND. AccessField("DPDOCPRO","DOC_CREFIS",oDocCxP:nOption);
               .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lIva)


  @ 4,1 CHECKBOX oDocCxP:oDOC_NODEDU VAR oDocCxP:DOC_NODEDU PROMPT ANSITOOEM("Gastos no Deducibles");
        WHEN (oDocCxP:lPar_LibCom .AND. AccessField("DPDOCPRO","DOC_NODEDU",oDocCxP:nOption);
              .AND. oDocCxP:nOption!=0 );
        ON CHANGE oDocCxP:SETCTANODEDUCC()


  // CXP3
  @ 10,0 FOLDER oDocCxP:oFolder ITEMS GetFromVar(IIF(oDocCxP:lCtaEgr,"{oDp:xDPCTAEGRESO}","{oDp:xDPCTA}")),;
                "Básicos",;
                "Otros Valores",;
                "CxP de Terceros";
                OF oDocCxP:oDlg SIZE 390,61

  SETFOLDER(1)

  SETCUENTAS()

  SETFOLDER(2)

  @10,25 SAY oDocCxP:oTextDesc PROMPT "-%Descuento:" SIZE 42,12 RIGHT

  oDocCxP:oTextDesc:lWantClick:= .T.
  oDocCxP:oTextDesc:bLClicked:= {||oDocCxP:RUNDESC()}

  @ 1.0,0 SAY oDocCxP:oTabMon PROMPT GetFromVar("{oDp:xDPTABMON}")+":" SIZE 42,12 FONT oFontB RIGHT

  oDocCxP:oTabMon:lWantClick:= .T.
  oDocCxP:oTabMon:bLClicked :={||DpLbx("DPTABMON.LBX")}

  @ 11,15 SAY "Condición:" RIGHT

  @ 04,17 SAY PADR(" :. Montos",63)+".:"

  @ 06.5,1 SAY "Plazo en Días:" RIGHT SIZE 40,10

  @ 05.5,1 SAY "Vencimiento:" RIGHT SIZE NIL,10

  @ 05.5,1 SAY "Valor Cambiario:" RIGHT SIZE NIL,10



  @ 7.5,20 SAY "+%Recargo:" RIGHT SIZE NIL,10

  @ 7.3,20 SAY "+- Otros:" RIGHT SIZE NIL,10

  @ 7.5,20 SAY "Otros Impuestos:" RIGHT SIZE NIL,10

  @ 8.5,20 SAY "Exonerado:" RIGHT SIZE 40,10

  @ 9.5,20 SAY oDocCxP:oBase PROMPT TRAN(oDocCxP:nBase,"999,999,999,999.99") RIGHT SIZE 40,10 UPDATE

  @ 10.5,40 SAY oDocCxP:oMtoDes PROMPT TRAN(oDocCxP:nMtoDes,"999,999,999,999.99") RIGHT SIZE 40,10 UPDATE

  @ 10.5,40 SAY oDocCxP:oMtoRec PROMPT TRAN(oDocCxP:nMtoRec,"999,999,999,999.99") RIGHT SIZE 40,10 UPDATE

  @ 1,1 SAY "Factura Afectada:" RIGHT SIZE 40,10

  @ 12,26.5 GET oDocCxP:oDOC_PLAZO VAR oDocCxP:DOC_PLAZO PICT "99";
            VALID oDocCxP:CALFCHVEN() .AND. MensajeErr("Plazo no Permitido",NIL,{||oDocCxP:DOC_PLAZO>=0});
            WHEN (AccessField("DPDOCPRO","DOC_PLAZO",oDocCxP:nOption) .AND. oDocCxP:nOption!=0);
            SIZE 18,10 RIGHT

  @ 12,10 BMPGET oDocCxP:oDOC_FCHVEN  VAR oDocCxP:DOC_FCHVEN  PICTURE "99/99/9999";
          NAME "BITMAPS\Calendar.bmp" ACTION LbxDate(oDocCxP:oDOC_FCHVEN ,oDocCxP:DOC_FCHVEN);
          VALID (EJECUTAR("DPVALFECHA",oDocCxP:DOC_FCHVEN,.T.,.T.) .AND. oDocCxP:PROVALCAM());
          WHEN (AccessField("DPDOCPRO","DOC_FCHVEN",oDocCxP:nOption) .AND. oDocCxP:nOption!=0);
          SIZE 41,10

  @ 13,10 BMPGET oDocCxP:oDOC_CONDIC  VAR oDocCxP:DOC_CONDIC;
          VALID oDocCxP:PROVALCAM(!Eval(oDocCxP:oDOC_NUMFIS:bWhen));
          WHEN (AccessField("DPDOCPRO","DOC_CONDIC",oDocCxP:nOption) .AND. oDocCxP:nOption!=0);
          SIZE 41,10

  // oDocCxP:lPar_Moneda:=.T.
  // Campo : DOC_CODMON
  // Uso   : Moneda  ag cs  .AND. LEN(oDp:aMonedas)>1)                                

  @ 1.6,6 COMBOBOX oDocCxP:oDOC_CODMON VAR oDocCxP:DOC_CODMON ITEMS oDp:aMonedas;
          VALID oDocCxP:PROVALCAM(.T.) ON CHANGE oDocCxP:PROVALCAM();
          WHEN (oDocCxP:lPar_Moneda .AND. AccessField("DPDOCPRO","DOC_CODMON",oDocCxP:nOption);
               .AND. oDocCxP:nOption!=0 .AND. LEN(oDp:aMonedas)>1) SIZE 100,NIL

  ComboIni(oDocCxP:oDOC_CODMON)

  @ 10,10 GET oDocCxP:oDOC_VALCAM  VAR oDocCxP:DOC_VALCAM PICTURE oDp:cPictValCam;
              WHEN (oDocCxP:lPar_Moneda .AND. (!oDp:cMoneda==LEFT(oDocCxP:DOC_CODMON,LEN(oDp:cMoneda))) .AND. ;
                    AccessField("DPDOCPRO","DOC_VALCAM",oDocCxP:nOption) .AND. oDocCxP:nOption!=0);
              SIZE 41,10 RIGHT

  @ 5,10 BMPGET oDocCxP:oDOC_FACAFE VAR oDocCxP:DOC_FACAFE;
         VALID oDocCxP:VALFACAFE();
         NAME "BITMAPS\FIND.BMP" ACTION oDocCxP:LISTFACAFE();
         WHEN (oDocCxP:lFacAfe .AND. AccessField("DPDOCPRO","DOC_FACAFE",oDocCxP:nOption);
              .AND. oDocCxP:nOption!=0);
         SIZE 48,10

  @ 10,30 GET oDocCxP:oDOC_DCTO VAR oDocCxP:DOC_DCTO PICTURE "99.99" VALID oDocCxP:CALNETO();
              WHEN (AccessField("DPDOCPRO","DOC_DCTO",oDocCxP:nOption);
                    .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lIva);
              SIZE 41,10 RIGHT

  @ 10,30 GET oDocCxP:oDOC_RECARG VAR oDocCxP:DOC_RECARG PICTURE "99.99" VALID oDocCxP:CALNETO();
              WHEN (AccessField("DPDOCPRO","DOC_RECARG",oDocCxP:nOption );
                   .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lIva);
              SIZE 41,10 RIGHT

  @ 10,30 GET oDocCxP:oDOC_OTROS VAR oDocCxP:DOC_OTROS PICTURE oDp:cPictDocOtros VALID oDocCxP:CALNETO();
              WHEN (AccessField("DPDOCPRO","DOC_OTROS",oDocCxP:nOption );
                   .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lIva);
              SIZE 41,10 RIGHT

  @ 10,30 GET oDocCxP:oDOC_IMPOTR VAR oDocCxP:DOC_IMPOTR PICTURE oDp:cPictDocOtros;
              VALID oDocCxP:CALNETO(.T.);
              WHEN (AccessField("DPDOCPRO","DOC_IMPOTR",oDocCxP:nOption );
                   .AND. oDocCxP:nOption!=0 .AND. oDocCxP:lIva);
              SIZE 41,10 RIGHT

  oDocCxP:oFocus:=oDocCxP:oTipDoc

  @ 02,20 SAY "Base Imponible:" RIGHT SIZE 40,10

  @ 09,40 SAY oDocCxP:oMtoExo PROMPT TRAN(oDocCxP:nMtoExo,"999,999,999,999.99") RIGHT SIZE 40,10 UPDATE

  SETFOLDER(3)

  oDocCxP:oScroll:=oDocCxP:SCROLLGET("DPDOCPRO","DPPRODOC.SCG",cExcluye)

  IF oDocCxP:IsDef("oScroll")
     oDocCxP:oScroll:SetEdit(.F.)
  ENDIF

  oDocCxP:oScroll:SetColSize(IIF(Empty(oDp:cModeVideo),200,264),IIF(Empty(oDp:cModeVideo),250,300),282)

  oDocCxP:oScroll:SetColorHead(CLR_WHITE ,4566522,oFont) 

  oDocCxP:oScroll:SetColor(oDp:nClrPane1,CLR_GREEN,1,oDp:nClrPane2,oFontB) 
  oDocCxP:oScroll:SetColor(oDp:nClrPane1,0,2,oDp:nClrPane2,oFont) 
  oDocCxP:oScroll:SetColor(oDp:nClrPane1,0,3,oDp:nClrPane2,oFontB)

  @ 6,0 SAY " Comentarios "

  @ 5,0 GET oDocCxP:oMemo VAR oDocCxP:cMemo MULTILINE SIZE 100,60 WHEN (oDocCxP:nOption!=0)

  SETFOLDER( 0)

  @ 1,20    SAY "Estado:" RIGHT

  @ 1,40    SAY "Declaración:" RIGHT SIZE NIL,10

  @ 14.5,20 SAY oDocCxP:oMtoBru;
            PROMPT TRAN(oDocCxP:nMtoBru,"999,999,999,999.99");
            RIGHT SIZE 40,10

  @ 14.5,40 SAY oDocCxP:oMtoIva PROMPT TRAN(oDocCxP:DOC_MTOIVA,"999,999,999,999.99");
            RIGHT SIZE 40,10

  @ 14.5,10 GET oDocCxP:oNeto VAR oDocCxP:DOC_NETO;
            PICTURE "999,999,999,999.99" RIGHT SIZE 40,10;
            WHEN !oDocCxP:lIva .AND. (AccessField("DPDOCPRO","DOC_NETO",oDocCxP:nOption);
                 .AND. oDocCxP:nOption!=0)

  oDocCxP:oNeto:bKeyDown:={|nKey| IIF( nKey=13 .AND. oDocCxP:DOC_NETO>0, oDocCxP:PreSave(.T.),NIL)}

  @ 15,01 SAY "Bruto:" RIGHT
  @ 15,10 SAY oDocCxP:oIVATEXT PROMPT "IVA:"   RIGHT
  @ 15,11 SAY "Neto:"  RIGHT

  oDocCxP:cPreDelete :="PREDELETE"
  oDocCxP:cPostDelete:="POSTDELETE" 
  oDocCxP:oFocus     :=oDocCxP:oTipDoc

  oDocCxP:SETTERCEROS()

  oDocCxP:Activate({||oDocCxP:DOCINI()})

  oDp:nDif:=(oDp:aCoors[3]-180-oDocCxP:oWnd:nHeight())

  oDocCxP:lStart:=.F.

  IF oDp:nDif<>0 .AND. .F.

   
//   

/*
   oDocCxP:oNomCta 
   oDocCxP:oSayCta 
   oDocCxP:oSayCen 
   oDocCxP:oDpCenCos  
   oDocCxP:oDpCtaSay 
*/
   EJECUTAR("FRMMOVEDOWN",oDocCxP:oNeto,oDocCxP,{oDocCxP:oFolder,oDocCxP:aGrids[1]:oBrw})


   oDocCxP:oNeto:SetSize(oDocCxP:oNeto:nWidth(),24,.T.)
//   oDocCxP:oNomCta:Move(oDocCxP:oNomCta:nBottom()+oDp:nDif,oDocCxP:oNomCta:nLeft(),.T.)

  ENDIF

  oDocCxP:oGrid:=oDocCxP:aGrids[1]

  oDocCxP:oGrid:AdjustBtn(.T.)
/*
  oGrid:bClrText     := {|oBrw,nClrText,aLine|aLine:=oDocCxP:oGrid:oBrw:aArrayData[oDocCxP:oGrid:oBrw:nArrayAt],;
                                              nClrText:=IF(aLine[oDocCxP:nColMonto]>0,CLR_HBLUE,CLR_HRED),;
                                              nClrText}
*/


  oDocCxP:oGrid:=oDocCxP:aGrids[1]

  oDocCxP:CXPRESTBRW()

//? oDocCxP:aGrids[1]


  // oDp:oBtn:=oDocCxP:aGrids[1]:aBtn[1,1]
  oDp:aControls:={oDocCxP:oNomCta,oDocCxP:oSayCta,oDocCxP:oSayCen,oDocCxP:oDpCenCos,oDocCxP:oDpCtaSay}

//  oDocCxP:oDpCtaSay:Move(oDocCxP:oDpCtaSay:nTop()+oDp:nDif,NIL,.T.)
//  AEVAL(oDp:aControls,{|o,n|o:Move(o:nTop()+oDp:nDif,o:nLeft(),.T.)}) 

RETURN oDocCxP

// Cancelar
FUNCTION CANCEL()
  LOCAL nAt:=ASCAN(oDocCxP:aTipDoc,{|a,n|oDocCxP:cTipDocAnt=a})

// ? oDocCxP:cWhereRec,"oDocCxP:cWhereRec CANCEL "

  IF oDocCxP:nOption=1 .AND. oDocCxP:cTipDoc<>oDocCxP:cTipDocAnt .AND. nAt>0

     oDocCxP:oTipDoc:VarPut(oDocCxP:oTipDoc:aItems[nAt],.T.)
     oDocCxP:cTipDoc:=oDocCxP:cTipDocAnt

     oDocCxP:CHANGEDOC()
     oDocCxP:cTipDoc   :=oDocCxP:DOC_TIPDOC
     oDocCxP:cTipDocAnt:=oDocCxP:DOC_TIPDOC

     oDocCxP:cScope:="DOC_CODSUC"+GetWhere("=",oDocCxP:cCodSuc)+" AND "+;
                     "DOC_TIPDOC"+GetWhere("=",oDocCxP:cTipDoc)+" AND "+;
                     "DOC_TIPTRA"+GetWhere("=","D"            )+" AND "+;
                     "DOC_DOCORG='D' "

// ? oDocCxP:cTipDoc,oDocCxP:cTipDocAnt,"REGISTROS ANTERIORES"

  ENDIF

//  IF Empty(oDocCxP:DOC_NUMERO)
//     ? "ESTA VACIO EL NUMERO",oDocCxP:cWhereRec
//  ENDIF

RETURN EJECUTAR("DPDOCCLICANCEL",oDocCxP)


FUNCTION LOAD()
  LOCAL nAt,I,cMemo:="",cNombre:="",cTipDoc,cNumero

  oDocCxP:cNumDoc:=oDocCxP:DOC_NUMERO // Documento para Modificar
  oDocCxP:cCodigo:=oDocCxP:DOC_CODIGO // Código del Proveedor
  oDocCxP:dFecha :=oDocCxP:DOC_FECHA  // Fecha para Eliminar Asiento JN 21/04/2008
  oDocCxP:lCta   :=.F.
  oDocCxP:lInv   :=.F.
  oDocCxP:nMtoIva:=0
  oDocCxP:cPrimary:="DOC_NUMERO,DOC_CODIGO"     // para que valide pagos del proveedor   ag dp
  oDocCxP:cUltDoc :="" // Ultima Factura
  oDocCxP:lCancel:=.F.
  oDocCxP:lDOC_NUMERO:=.F.  // Validar Número      bLostFocus
  oDocCxP:lDOC_FECHA :=.F.  // Validar Fecha       bLostFocus
  oDocCxP:lDOC_FCHDEC:=.F.  // Validar Declaración bLostFocus

  IF !Empty(oDocCxP:DOC_NUMERO)
    oDocCxP:cWhereRec:=oDocCxP:GetWhere()
// ? oDocCxP:cWhereRec,"oDocCxP:cWhereRec"
  ENDIF

//  IF Empty(oDocCxP:DOC_NUMERO)
//     ? oDocCxp:lCancel,oDocCxP:cWhereRec,"oDocCxP:cWhereRec, ESTA VACIO"
//  ENDIF

  IF oDocCxP:nOption=3 .AND. !oDocCxP:ISALTER()
    RETURN .F.
  ENDIF

  IF oDocCxP:nOption=3 .AND. !EJECUTAR("DPVALFECHA",oDocCxP:DOC_FECHA,.T.,.T.)
    RETURN .F.
  ENDIF

  IF oDocCxP:nOption=1

     oDocCxP:DOC_DOCORG:="D" // Origen Documentos
     oDocCxP:DOC_DCTO  :=0
     oDocCxP:DOC_RECARG:=0
     oDocCxP:DOC_OTROS :=0
     oDocCxP:DOC_NETO  :=0
     oDocCxP:DOC_ESTADO :="AC"
     oDocCxP:DOC_PLAZO_ :=0
     oDocCxP:DOC_ACT    :=1 // Documento Activo
     oDocCxP:lInv       :=.F.
     oDocCxP:DOC_ANUFIS :=.F. 
//   oDocCxP:DOC_CODIGO :=SPACE(10) 

     oDocCxP:SET("DOC_FECHA" ,IIF(oDp:lFechaNew,oDp:dFecha,DATE()))

     oDocCxP:oDOC_FECHA:VarPut(oDocCxP:DOC_FECHA,.T.)
//   oDocCxP:oDOC_NUMPAG:VarPut(1,.T.)
     oDocCxP:DOC_TIPDOC:=oDocCxP:cTipDoc
     oDocCxP:DOC_CODSUC:=oDocCxP:cCodSuc
     oDocCxP:SET("DOC_CODMON",oDp:cMoneda,.T.)
     oDocCxP:SET("DOC_CENCOS",oDp:cCenCos,.T.)

     IF !Empty(oDocCxP:cCenCos)
       oDocCxP:SET("DOC_CENCOS",oDocCxP:cCenCos,.T.)
     ENDIF

     oDocCxP:SET("DOC_ORIGEN","N",.T.)
     oDocCxP:SET("DOC_HORA"  ,TIME()         )
     oDocCxP:SET("DOC_USUARI",oDp:cUsuario   )
     oDocCxP:oDOC_FCHDEC:VarPut(oDocCxP:dFchDec,.T.) // JN 18/10/2016 Fecha Declaracion debe ser fin de mes
    
     IF !Empty(oDocCxP:xCodPro)
        oDocCxP:oDOC_CODIGO:VarPut(oDocCxP:xCodPro,.T.)
        oDocCxP:oDOC_CODIGO:KeyBoard(13)
        EVAL(oDocCxP:oDOC_CODIGO:bValid)
     ELSE
         oDocCxP:SET("DOC_CODIGO",SPACE(10))
     ENDIF

     oDocCxP:nMtoExo    :=0   // Exonerado 
     oDocCxP:nMtoDes    :=0   // Monto Descuento
     oDocCxP:nMtoRec    :=0   // Monto Recargo
     oDocCxP:nMtoBru    :=0   // Monto Bruto
     oDocCxP:nMtoIva    :=0   // Monto IVA
     oDocCxP:oFolder:SetOption( IIF(oDocCxP:lPar_lItem, 1, 2) ) // Antes lIVA
     oDocCxP:oNeto:Refresh(.T.)
     oDocCxP:lSaved     :=.F.

     oDocCxP:VALFECHA()

     oDocCxP:GETTIPDOC(oDocCxP:DOC_USUARI)

 ELSE

 // oDocCxP:cTipDoc    :=oDocCxP:DOC_TIPDOC
   oDocCxP:oFolder:aEnable[4]:=(oDocCxP:DOC_TIPDOC="CPT") // CXP3
   oDocCxP:oFolder:Refresh(.T.)                           // CXP3

   oDocCxP:cMemo:=ALLTRIM(SQLGET("DPMEMO","MEM_MEMO","MEM_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMMEM)))
   oDocCxP:oMemo:VarPut(oDocCxP:cMemo,.t.)

   IF oDocCxP:nOption=3

      oDocCxP:lCta:=COUNT("DPDOCPROCTA","CCD_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                                        "CCD_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                                        "CCD_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                                        "CCD_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO))>0

      EVAL(oDocCxP:oDOC_NUMFIS:bValid)
      
   ENDIF

 ENDIF

 oDocCxP:ChkDocFis()
 oDocCxP:oProNombre:Refresh(.T.)

 oDocCxP:DOC_TIPO:=oDocCxP:aTipDoc[oDocCxP:oTipDoc:nAt]

 IF oDocCxP:nOption=0
   oDocCxP:oDOC_CODIGO:VarPut(oDocCxP:DOC_CODIGO , .T. )
 ELSE
   oDocCxP:CHANGEDOC()
   DPFOCUS(IIF(oDocCxP:nOption=3,oDocCxP:oDOC_CODIGO,oDocCxP:oTipDoc))
 ENDIF

 oDocCxP:CALNETO()
 oDocCxP:oTipDoc:ForWhen(.T.)
 oDocCxP:oEstado:Refresh(.T.)

 // AG CS  
 IF oDocCxP:nOption=3
   oDocCxP:VALCODPRO()
 ENDIF


RETURN .T.

FUNCTION CHANGEDOC()
  LOCAL cTipDoc:=oDocCxP:aTipDoc[oDocCxP:oTipDoc:nAt]
  LOCAL aDocs:={},cSql
  LOCAL cCodRif // Codigo de Institucion pre-establecida para el tipo documento, evitando error del usuario

  // AG20080402    pq
  IF EMPTY(oDocCxP:lPar_lItem)
     oDocCxP:lPar_lItem:=SQLGET("DPTIPDOCPRO","TDC_LITEM","TDC_TIPO"+GetWhere("=",cTipDoc))
  ENDIF

  IF oDocCxP:nOption=1 .AND. Empty(oDocCxP:DOC_CODIGO)

    cCodRif:=SQLGET("DPENTESPUB","ENT_RIF","ENT_TIPDOC"+GetWhere(" LIKE ","%"+cTipDoc+"%"))

    IF !Empty(cCodRif)
      cCodRif:=SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_RIF"+GetWhere("=",cCodRif))
      IF !Empty(cCodRif)
         oDocCxP:oDOC_CODIGO:VarPut(cCodRif,.T.)
         oDocCxP:oDOC_CODIGO:KeyBoard(13)
      ENDIF
    ENDIF

  ENDIF

 //?? cTipDoc,"cTipDoc"

  oDocCxP:lIva      :=SQLGET("DPTIPDOCPRO","TDC_IVA","TDC_TIPO"+GetWhere("=",cTipDoc))
  oDocCxP:DOC_TIPDOC:=cTipDoc

  IF cTipDoc="CPT"
    oDocCxP:lPar_lItem:=.F. // Debe Desactivar los Items
  ENDIF

  oDocCxP:oFolder:aEnable[1]:=oDocCxP:lPar_lItem // oDocCxP:lIva
  oDocCxP:oFolder:aEnable[4]:=(cTipDoc="CPT")


  oDocCxP:oFolder:Refresh(.F.)
  
  IF !oDocCxP:lPar_lItem // !oDocCxP:lIva
    oDocCxP:oFolder:SetOption(2)
  ELSE
    oDocCxP:oFolder:SetOption(1)
  ENDIF

  IF cTipDoc="CPT"
    oDocCxP:oFolder:SetOption(4)
  ENDIF

  IF !(cTipDoc==oDocCxP:cTipDoc)
// .OR. .T.
    oDocCxP:cTipDocAnt:=oDocCxP:cTipDoc
    oDocCxP:cTipDoc   :=cTipDoc

    EJECUTAR("DPDOCPROPAR" ,oDocCxP,oDocCxP:cTipDoc)

    oDocCxP:oDOC_NUMERO:ForWhen(.T.)

    IF oDocCxP:nOption=0 // Hace cambio de Scope
      oDocCxP:SETDOCSCOPE(.T.)
      oDocCxP:cTipDocAnt:=cTipDoc // 19/09/2016
    ENDIF
  ENDIF

//? oDocCxP:lPar_LibCom,"LIBRO DE COMPRAS"

  oDocCxP:DOC_TIPDOC:=cTipDoc
  oDocCxP:GETTIPDOC(cTipDoc) // JN 22/02/2016

  // Filtrar Proveedor por Tipo de Documento  //JN 19-09-2016
  cSql:=" SELECT TXT_TIPPRO FROM DPTIPDOCPROXTIP "+;
        " WHERE TXT_TIPDOC"+GetWhere("=",cTipDoc)+ " GROUP BY TXT_TIPPRO "

  AEVAL(ASQL(cSql),{|a,n| AADD(aDocs,a[1])})

  IF !Empty(aDocs)
     oDocCxP:cWherePro:="("+GetWhereOr("PRO_TIPO",aDocs)+")"  
     oDocCxP:cTipPro:=aDocs[1]
  ELSE
     oDocCxp:cWherePro  :="LEFT(PRO_SITUAC,1)='A'"
     oDocCxP:cTipPro    :=""
  ENDIF

  oDocCxp:cFileLbx   :=EJECUTAR("LBXTIPPROVEEDOR",oDocCxP:cTipPro,.F.)

  oDocCxP:lDOC_NUMERO:=!oDocCxP:lPar_EditNum
  oDocCXP:oDOC_NUMFIS:ForWhen(.T.)

RETURN .T.

/*
// Obtiene Longitud y Relleno de Zero
*/
FUNCTION GETTIPDOC(cTipDoc)

   oDocCxP:lPar_Zero:=SQLGET("DPTIPDOCPRO","TDC_ZERO,TDC_LEN","TDC_TIPO"+GetWhere("=",cTipDoc))
   oDocCxP:nPar_Len :=DPSQLROW(2)

RETURN .T.


// Asigna Scope
FUNCTION SETDOCSCOPE(lRefresh)
  LOCAL cWhere,nOption:=0

  DEFAULT lRefresh:=.T.

  cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:cCodSuc)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",oDocCxP:cTipDoc)+" AND "+;
          "DOC_TIPTRA"+GetWhere("=","D"            )+" AND "+;
          "DOC_DOCORG"+GetWhere("=","D"            )

  oDocCxP:DOC_TIPDOC:=oDocCxP:cTipDoc

  nOption:=IIF(MYCOUNT("DPDOCPRO",cWhere)=0,1,0)

  oDocCxP:SetScope(cWhere)

  oDocCxP:cWhereRecord:=cWhere

  IF lRefresh .OR. nOption=1
    oDocCxP:nOption:=nOption

    IF oDocCxP:nOption=0

      oDocCxP:Primero(.T.," WHERE DOC_CODSUC"+GetWhere("=",oDocCxP:cCodSuc)+" AND "+;
                                " DOC_TIPDOC"+GetWhere("=",oDocCxP:cTipDoc))

      // Contar Registros
      IF ISRELEASE("16.08")
        oDocCxP:RECCOUNT(.T.)
      ENDIF

    ELSE

      IF RELEASE("16.08")
        oDocCxP:RECCOUNT(.T.)
      ENDIF

    ENDIF

    oDocCxP:LoadData(nOption,NIL,.T.,cWhere)

    EJECUTAR("DPPRIVCOMLEE",oDocCxP:cTipDoc,.F.,oDocCxP) // Lee los Privilegios del Usuario

    EJECUTAR("DPDOCPROPAR" ,oDocCxP,oDocCxP:cTipDoc)

    oDocCxP:oDOC_NUMERO:Refresh(.T.)

  ENDIF

  oDocCxP:cScript:="DPDOCCXP"
  oDocCxP:aGrids[1]:SetScript("DPDOCCXP")    // CXP3
  oDocCxP:aGrids[2]:SetScript("DPDOCCXPCPT") // CXP3
  oGrid:cScript  :="DPDOCCXP"          // pq
  oDocCxP:cList  :="DPDOCPRO.BRW"

RETURN .T.

FUNCTION VALCODPRO()
  LOCAL lCreFis:=.F.
  LOCAL cWherePro,nCant,cCodigo

  cWherePro:="PRO_CODIGO LIKE "+GetWhere("","%"+ALLTRIM(oDocCxP:DOC_CODIGO)+"%")
  cWherePro:=cWherePro+" OR "+EJECUTAR("GETWHERELIKE","DPPROVEEDOR","PRO_NOMBRE",oDocCxP:DOC_CODIGO,"PRO_CODIGO")

  nCant  := COUNT("DPPROVEEDOR",cWherePro)
  cCodigo:=""

  IF nCant=1

    cCodigo:=SQLGET("DPPROVEEDOR","PRO_CODIGO",cWherePro)
    oDocCxP:oDOC_CODIGO:VarPut(cCodigo,.T.)
    oDocCxP:DOC_CODIGO:=cCodigo
    oDocCxP:oDOC_CODIGO:KeyBoard(13)

  ENDIF

  IF Empty(cCodigo) .AND. nCant>1

      cCodigo:=EJECUTAR("REPBDLIST","DPPROVEEDOR","PRO_CODIGO,PRO_NOMBRE,PRO_RIF",.F.,cWherePro,NIL,NIL,oDocCxP:DOC_CODIGO,NIL,NIL,"PRO_CODIGO",oDocCxP:oDOC_CODIGO)

      IF !Empty(cCodigo) .AND. ISSQLFIND("DPPROVEEDOR","PRO_CODIGO"+GetWhere("=",cCodigo))
         oDocCxP:oDOC_CODIGO:VarPut(cCodigo,.T.)
         oDocCxP:DOC_CODIGO:=cCodigo
      ENDIF

  ENDIF


  IF Empty(oDocCxP:DOC_CODIGO) .OR. !(SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO))==oDocCxP:DOC_CODIGO)
     DPFOCUS(oDocCxP:oDOC_CODIGO)
     EVAL(oDocCxP:oDOC_CODIGO:bAction)
     RETURN .T.
  ENDIF

  // 24/01/2020
  oDocCxP:oDOC_NUMERO:bLostFocus:={||oDocCxP:VALNUMERO(.T.)}


  EJECUTAR("DPDOCPROVALPRO",oDocCxP:oDOC_CODIGO,oDocCxP)

  oDocCxP:oProNombre:Refresh(.T.)

  // Documento sin derecho a Credito Fiscal
  lCreFis:=SQLGET("DPPROVEEDOR","PRO_CREFIS","PRO_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO))="N" // 24/11/2022

  oDocCxP:DOC_CREFIS:=lCreFis // lCreFis

  oDocCxP:oDOC_CREFIS:Refresh(.T.)

  oDocCxP:ChkDocFis()
  oDocCxP:oProNombre:Refresh(.T.)
  oDocCxP:oDOC_CODMON:ForWhen(.T.)
  oDocCxP:AUTONUM()

  // Cheque Devuelto
  IF oDocCxP:DOC_TIPDOC="CHD"
     EJECUTAR("PROCHKDEV",oDocCxP:DOC_CODIGO,oDocCxP)
  ENDIF

  IF oDocCxP:nOption=1
    oDocCxP:ASG_ULT_CTA()  // Busca la Ultima Cuenta del Proveedor
//    DPFOCUS(oDocCxP:oDOC_NUMERO)
  ENDIF
  
RETURN .T.

// Verifica si el Documento es Fiscal
FUNCTION ChkDocFis()
  LOCAL aCXP:={1,-1,0},nAt
  oDocCxP:lIva:=.F.
  oDocCxP:lPar_LIBCOM:=SQLGET("DPTIPDOCPRO","TDC_LIBCOM,TDC_IVA,TDC_CXP,TDC_LITEM","TDC_TIPO"+GetWhere("=",oDocCxP:cTipDoc))
  oDocCxP:lFacAfe   :=oDocCxP:cTipDoc$"CRE,DEB,CHD,DEV"

  IF !Empty(oDp:aRow)
    oDocCxP:lIva      :=oDp:aRow[2]
    oDocCxP:lPar_lItem:=oDp:aRow[4]
    oDocCxP:DOC_CXP:=IIF(oDp:aRow[3]="D", 1,oDocCxP:DOC_CXP)
    oDocCxP:DOC_CXP:=IIF(oDp:aRow[3]="H",-1,oDocCxP:DOC_CXP)
  ENDIF

RETURN .T.

FUNCTION CONPROVEEDOR()
  LOCAL lFound:=.F.

  lFound:=!Empty(oDocCxP:DOC_CODIGO) .AND. SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO))=oDocCxP:DOC_CODIGO

  IF lFound  
     EJECUTAR("DPPROVEEDORCON",NIL,oDocCxP:DOC_CODIGO)
  ENDIF

  IF !lFound .AND. oDocCxP:nOption<>0
     EVAL(oDocCxP:oDOC_CODIGO:bAction) // Lista los Clientes
  ENDIF

  SysRefresh(.T.)
RETURN .T.

// Lee las tasas impositivas
FUNCTION PROVALCAM(lFocus)
  DEFAULT lFocus:=.F.

  IF lFocus .AND. !EVAL(oDocCxP:oDOC_VALCAM:bWhen) .AND. !EVAL(oDocCxP:oDOC_FACAFE:bWhen) .AND. !oDocCxP:lPar_ReqFis
    oDocCxP:BrwSetFocus()
  ENDIF

  oDocCxP:DOC_VALCAM:=EJECUTAR("DPGETVALCAM",Left(oDocCxP:DOC_CODMON,3),oDocCxP:DOC_FECHA,oDocCxP:DOC_HORA)
  oDocCxP:oDOC_VALCAM:Refresh(.T.)

RETURN .T.

FUNCTION VALFECHA()
  LOCAL I
  LOCAL bLost:=oDocCxP:oDOC_FECHA:bLostFocus
  LOCAL cLibro:=SQLGET("DPTIPDOCPRO","TDC_LIBCOM","TDC_TIPO"+GetWhere("=",oDocCxP:DOC_TIPDOC))

  oDocCxP:lDOC_FECHA:=.F.
  oDocCxP:oDOC_FECHA:bLostFocus:=NIL

  IF cLibro=.F.
    oDocCxP:lNumFis:=.T.
  ELSE
    oDocCxP:lNumFis:=cLibro
  ENDIF

  IF !EJECUTAR("DPVALFECHA",oDocCxP:DOC_FECHA,.T.,.T.,oDocCxP:oDOC_FECHA) .AND. oDocCxP:PROVALCAM()
      oDocCxP:oDOC_FECHA:bLostFocus:=bLost
      RETURN .F.
  ENDIF

  oDocCxP:oDOC_FCHVEN:VarPut(EJECUTAR("CALFCHVEN",oDocCxP:DOC_FECHA,oDocCxP:DOC_PLAZO),.T.)

  IF (oDocCxP:nOption=1 .AND. Empty(oDocCxP:DOC_FCHDEC) .AND. (oDocCxP:lPar_LIBCOM .OR. oDocCxP:lPar_Contab=.T.)) .OR. !EVAL(oDocCxP:oDOC_FCHDEC:bWhen)   
    oDocCxP:oDOC_FCHDEC:VarPut(oDocCxP:DOC_FECHA,.T.)
  ENDIF

  oDocCxP:lDOC_FECHA:=.T.
  oDocCxP:oDOC_FECHA:ForWhen(.T.)
  oDocCxP:oDOC_FECHA:bLostFocus:=bLost

  oDocCxP:oDOC_FECHA:SetColor(oDp:GetnCltText,oDp:GetnClrPane)

RETURN .T.

FUNCTION PutBase(oCol,nValue)
  oDocCxP:PutIva(oCol,nIva)
  // oDocCxP:CalNeto()
RETURN uValue

FUNCTION PutIva(oCol,nIva)
RETURN nIva

FUNCTION RUNDESC()
  LOCAL nBruto:=0,nDesc
  nDesc :=EJECUTAR("DPDOCDESC",oDocCxP,nBruto,oDocCxP:DOC_DESCCO,!oDocCxP:nOption=0)
RETURN .T.

// Realizar Calculo del Valor Neto
FUNCTION CALNETO(lFocus,lUpDate)
  LOCAL lResp:=.T.
  LOCAL lRefresh:=.F.
  LOCAL oTable,cSql,aData,I,cWhere,nRecno:=oGrid:Recno(),aData

  DEFAULT lFocus :=.F., lUpdate:=.T.

  // ag  
  IF LEN(oDocCxP:aGrids)=0
     RETURN .T.
  ENDIF


  IF oDocCxP:DOC_TIPDOC="CPT"
     oDocCxP:DOC_NETO:=SQLGET("DPDOCPRO","SUM(DOC_NETO*DOC_CXP)","DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                                                                 "DOC_CXPTIP"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                                                                 "DOC_CXPCOD"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                                                                 "DOC_CXPDOC"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND DOC_TIPTRA='D'")
  ENDIF


  cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
          "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND "+;
          "DOC_TIPTRA='D'"

  oDocCxP:SAYCTA()

  //IF !oDocCxP:oFolder:aEnable[1] // Empty(oGrid:oBrw:aArrayData) at

 // antes IF (!oDocCxP:oFolder:aEnable[1]) .OR. (oDocCxP:DOC_TIPDOC="CHD")   //.OR. (oDocCxP:DOC_TIPDOC="CPT") // Empty(oGrid:oBrw:aArrayData)

  // ag cs
  IF (!oDocCxP:oFolder:aEnable[1]) .OR. (oDocCxP:DOC_TIPDOC="CPT") .OR. (oDocCxP:DOC_TIPDOC="CHD") 
    oDocCxP:nMtoBru:=oDocCxP:DOC_NETO

    oDocCxP:oMtoBru:Refresh(.T.)
    oDocCxP:oNeto:Refresh(.T.)
    oDocCxP:oMtoIva:Refresh(.T.) 
    RETURN .T.
  ENDIF

  EJECUTAR("DPDOCCLIIVA",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO,.F.,;
                         oDocCxP:DOC_DCTO  ,oDocCxP:DOC_RECARG,oDocCxP:DOC_OTROS,oDocCxP:DOC_IMPOTR,"C")

  oDocCxP:nMtoBru:=oDp:nBruto

  oDocCxP:oMtoBru:Refresh(.T.)

  oDocCxP:DOC_BASNET :=oDp:nBaseNet
  oDocCxP:DOC_MTOIVA :=oDp:nIVA 
  oDocCxP:DOC_NETO   :=oDp:nNeto 

  IF oDocCxP:nOption=0 .AND. Empty(oGrid:aData)
    oDocCxP:oNeto:Refresh(.T.)
    oDocCxP:oNeto:ForWhen()
    oDocCxP:oMtoIva:Refresh(.T.) // SetText(oDocCxP:nMtoIva,.T.)
    oDocCxP:oMtoBru:Refresh(.T.) // SetText(oDocCxP:nMtoBru,.T.)
    oDocCxP:oMtoExo:Refresh(.T.) // SetText(oDocCxP:nMtoBru,.T.)
    oDocCxP:oBase:Refresh(.T.)
    oDocCxP:oMtoDes:Refresh(.T.)
    oDocCxP:oMtoRec:Refresh(.T.)
    oDocCxP:oMtoBru:Refresh(.T.)
    oDocCxP:oMtoIva:Refresh(.T.)
 
    RETURN .T.
  ENDIF

  oDp:nIva       :=0
  oDp:nDesc      :=oDocCxP:DOC_DCTO  
  oDp:nRecarg    :=oDocCxP:DOC_RECARG
  oDp:nDocOtros  :=oDocCxP:DOC_OTROS
  oDp:nBruto     :=oDp:nBruto // Grid:GetTotal("CCD_MONTO")
  oDp:nNeto      :=0
  oDp:nBase      :=0
  oDocCxP:nMtoExo:=0 
  oDocCxP:nBase  :=0
  oDocCxP:lCta   :=oDp:nBruto>0

  oDocCxP:oMtoIva:Refresh(.T.) // SetText(oDocCxP:nMtoIva,.T.)
  oDocCxP:oMtoBru:Refresh(.T.) // SetText(oDocCxP:nMtoBru,.T.)
  oDocCxP:oMtoExo:Refresh(.T.) // SetText(oDocCxP:nMtoBru,.T.)

  oDocCxP:oNeto:VarPut(oDocCxP:DOC_NETO,.T.)
  oDocCxP:oNeto:ForWhen()
  
  oDocCxP:oBase:Refresh(.T.)
  oDocCxP:oMtoDes:Refresh(.T.)
  oDocCxP:oMtoRec:Refresh(.T.)
RETURN lResp

FUNCTION VALNUMERO(lLost)
  LOCAL lResp:=.F.,cNumDoc,oTable
  LOCAL cLibro:=SQLGET("DPTIPDOCPRO","TDC_LIBCOM","TDC_TIPO"+GetWhere("=",oDocCxP:DOC_TIPDOC))
  LOCAL cDescri,cNumGet:=""
  LOCAL cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)
  LOCAL bLost:=oDocCxP:oDOC_NUMERO:bLostFocus,nAt,oBtnCancel

  DEFAULT lLost:=.F.

  IF lLost .AND. Empty(oDocCxP:DOC_NUMERO)
      RETURN .T.
  ENDIF

  nAt       :=ASCAN(oDocCxP:aBtn,{|a,n| a[7]="CANCEL"})
  oBtnCancel:=oDocCxP:aBtn[nAt,1]
  oBtnCancel:lCancel:=.T.

  oDocCxP:oDOC_NUMERO:bLostFocus:=NIL
  oDocCxP:lDOC_NUMERO:=.F.

  IF cLibro=.F.
    oDocCxP:lNumFis:=.T.
  ELSE
    oDocCxP:lNumFis:=cLibro
  ENDIF
  
  IF EMPTY(oDocCxP:DOC_NUMERO)
    oDocCxP:oDOC_NUMERO:MsgErr("Indique Número del Documento")
    oDocCxP:oDOC_NUMERO:bLostFocus:=bLost
    RETURN .F.
  ENDIF

  lResp:=EJECUTAR("DPDOCPROVALNUM",oDocCxP)

// Rellena de Ceros hacia la Izquierda
// IF oDocCxP:lPar_Zero .AND. oDocCxP:nPar_Len>1 .AND. ISALLDIGIT(oDocCxP:DOC_NUMERO)
//    oDocCxP:DOC_NUMERO:=STRZERO(VAL(oDocCxP:DOC_NUMERO),oDocCxP:nPar_Len)
//    oDocCxP:oDOC_NUMERO:VarPut(oDocCxP:DOC_NUMERO,.T.)
// ENDIF
// 18022009 (Corrige error al modificar Numero de documentos) ag

   oDocCxP:cNumDoc:=oDocCxP:DOC_NUMERO

   IF oDocCxP:nOption=5 .OR. oDocCxP:nOption=0 
      oDocCxP:lDOC_NUMERO:=.T.
      oDocCxP:oDOC_NUMERO:bLostFocus:=bLost
      RETURN .T.
   ENDIF

   IF oDocCxP:nOption=5 .OR. (oDocCxP:nOption=3 .AND. oDocCxP:cNumDoc=oDocCxP:DOC_NUMERO .AND. oDocCxP:cCodigo=oDocCxP:DOC_CODIGO)
     oDocCxP:lDOC_NUMERO:=.T.
     oDocCxP:oDOC_NUMERO:bLostFocus:=bLost
     RETURN .T.
   ENDIF

   cNumGet:=ALLTRIM(SQLGET("DPDOCPRO","DOC_NUMERO",cWhere))
   cNumDoc:=ALLTRIM(oDocCxP:DOC_NUMERO) // Introducidor por Teclado

   lResp:=!(cNumDoc==cNumGet)

// ? lResp,"AQUI"

   // Valida Numero de Documentos  Caso 1
   IF lResp  .AND. oDocCxP:lPar_Zero

     cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
             "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
             "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
             "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)

     cNumGet:=ALLTRIM(SQLGET("DPDOCPRO","DOC_NUMERO",cWhere))

     lResp  :=!(cNumDoc==cNumGet)

   ENDIF


  //Valida Numero de Documentos  Caso 2
  IF lResp  .AND. !oDocCxP:lPar_Zero

     cNumDoc:=SIN_CEROS(cNumDoc)

     cWhere :="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
              "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
              "DOC_NUMERO"+GetWhere(" LIKE ","%"+SIN_CEROS(cNumDoc)+"")

     cNumGet:=SQLGET("DPDOCPRO","DOC_NUMERO",cWhere)

     lResp  :=!(SIN_CEROS(cNumGet)==cNumDoc) 

  ENDIF


  IF !lResp 

     oDocCxP:oDOC_NUMERO:bLostFocus:=NIL

     cDescri:=ALLTRIM(SQLGET("DPTIPDOCPRO","TDC_DESCRI","TDC_TIPO"+GetWhere("=",oDocCxP:DOC_TIPDOC)))
     oDocCxP:oDOC_NUMERO:MsgErr("Documento "+ALLTRIM(oDocCxP:DOC_NUMERO)+CRLF+" Está Registrado con Número "+cNumGet,cDescri)
     oDocCxP:lDOC_NUMERO:=.F.

     SysRefresh(.T.)
     CursorWait()

     DpFocus(oDocCxP:oDOC_NUMERO)
    
     oDocCxP:oDOC_NUMERO:bLostFocus:=bLost
     oDocCxP:oDOC_NUMERO:bValid    :={||oDocCxP:VALIDNUMERO()}
     oDocCxP:oDOC_NUMERO:bLostFocus:=NIL

 
     RETURN .F.

  ELSE

    IF oDocCxP:nOption=3
      oDocCxP:UpdateNumDoc()   // ojo
    ELSE
      oDocCxP:cNumDoc:=oDocCxP:DOC_NUMERO
      oDocCxP:cCodigo:=oDocCxP:DOC_CODIGO
    ENDIF

  ENDIF

  // ERP
  IF !Empty(oDocCxP:aDataGrid)
    EJECUTAR("DPDOCCXPPUTCTA",oDocCxP)
  ENDIF

  // JN 29/02/2016
  IF lResp .AND. oDocCxP:nOption=1 .AND. Empty(oDocCxP:DOC_NUMFIS)
     oDocCxP:oDOC_NUMFIS:VarPut(oDocCxP:DOC_NUMERO,.T.)
  ENDIF

  oDocCxP:lDOC_NUMERO:=lResp

  IF lResp
     oDocCxP:oDOC_NUMERO:SetColor(oDp:GetnCltText,oDp:GetnClrPane) 
  ENDIF

RETURN lResp

FUNCTION VALIDNUMERO()
  LOCAL lResp

//oDocCxP:oDOC_NUMERO:bLostFocus:={||oDocCxP:oDOC_NUMERO:SetColor(CLR_RED,CLR_WHITE),oDocCxP:VALNUMERO(.T.)}

  lResp:=oDocCxP:VALNUMERO(.T.)

RETURN lResp

// Calcula Fecha
FUNCTION CALFCHVEN()
  LOCAL dFecha:=EJECUTAR("CALFCHVEN",oDocCxP:DOC_FECHA,oDocCxP:DOC_PLAZO)

  oDocCxP:oDOC_FCHVEN:VarPut(dFecha,.T.)
RETURN .T.

FUNCTION VALNUMFIS()
 LOCAL cLibro:=SQLGET("DPTIPDOCPRO","TDC_LIBCOM","TDC_TIPO"+GetWhere("=",oDocCxP:DOC_TIPDOC))

 oDocCxP:lNumFis:= .T.

 IF cLibro=.T. .AND. Empty(oDocCxP:DOC_NUMFIS)
     oDocCxP:lNumFis:= .F.
     oDocCxP:oDOC_NUMFIS:MsgErr("Es Necesari Introducir Número de Serie Fiscal")
     oDocCxP:oDOC_NUMFIS:VarPut(oDocCxP:DOC_NUMERO,.T.)
  ENDIF

// numero fiscal no puede tener zeros izquierda

/*
  IF oDocCxP:lPar_Zero .AND. oDocCxP:nPar_Len>1 .AND. ISALLDIGIT(oDocCxP:DOC_NUMFIS)
     oDocCxP:DOC_NUMFIS:=STRZERO(VAL(oDocCxP:DOC_NUMFIS),oDocCxP:nPar_Len)
     oDocCxP:oDOC_NUMFIS:VarPut(oDocCxP:DOC_NUMFIS,.T.)
  ENDIF
  oDocCxP:PROVALCAM(.T.)
*/

  oDocCxP:RunWhen()

  DPFOCUS(oDocCxP:oDOC_FECHA)

RETURN oDocCxP:lNumFis

FUNCTION VALFACAFE()
  LOCAL cNumero:=ALLTRIM(oDocCxP:DOC_FACAFE),nLen:=SQLGET("DPTIPDOCPRO","TDC_LEN,TDC_ZERO","TDC_TIPO"+GetWhere("=","FAC"))
  LOCAL lZero  :=DPSQLROW(2,.F.)

  IF lZero .AND. nLen<>LEN(ALLTRIM(oDocCxP:DOC_FACAFE)) .AND. ALLDIGIT(uValue)
     oDocCxP:DOC_FACAFE :=STRZERO(VAL(oDocCxP:DOC_FACAFE),nLen)
     oDocCxP:oDOC_FACAFE:VarPut(oDocCxP:DOC_FACAFE,.T.)
  ENDIF

  IF !oDocCxP:lPar_LIBCOM
	oDocCxP:BrwSetFocus()
  ENDIF

  cNumero:=SQLGET("DPDOCPRO","DOC_NUMERO,DOC_ACT,DOC_FECHA",;
                  "DOC_CODSUC"+GetWhere("=",oDocCxP:cCodSuc   )+" AND "+;
                  "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                  "DOC_TIPDOC='FAC' AND "+;
                  "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_FACAFE))

  IF !(cNumero==oDocCxP:DOC_FACAFE)
     oDocCxP:oDOC_FACAFE:MsgErr("Factura "+oDocCxP:DOC_FACAFE+" no Encontrada")
     oDocCxP:LISTFACAFE()
     RETURN .F.
  ENDIF

  IF !Empty(cNumero) .AND. !Empty(oDp:aRow) .AND. oDp:aRow[2]=0
    MensajeErr("Factura "+cNumero+" no está Activo")
    RETURN .F.
  ENDIF

  oDocCxP:dFchDocAfe:=oDp:aRow[3]

RETURN .T.

FUNCTION LISTFACAFE()
  LOCAL cNumero:=SPACE(10)

  cNumero:=EJECUTAR("REPBDLIST","DPDOCPRO","DOC_NUMERO,DOC_FECHA,DOC_NETO",.F.,;
           "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+;
           " AND DOC_TIPTRA='D' AND DOC_ACT=1 "+;
           " AND DOC_TIPDOC='FAC' AND DOC_CODSUC"+GetWhere("=",oDocCxP:cCodSuc	),;
           "Seleccionar Factura de Compra",NIL,NIL,NIL,NIL,"DOC_NUMERO",oDocCxP:oDOC_FACAFE)

  IF !Empty(cNumero)
    oDocCxP:DOC_FACAFE:=cNumero
    oDocCxP:oDOC_FACAFE:VarPut(cNumero,.T.)
    oDocCxP:oDOC_FACAFE:SetFocus()
    oDocCxP:oDOC_FACAFE:KeyBoard(13)
  ENDIF

RETURN .T.

FUNCTION PREGRABAR()
  LOCAL cDebCre:=SQLGET("DPTIPDOCPRO","TDC_CXP"   ,"TDC_TIPO"+GetWhere("=",oDocCxP:DOC_TIPDOC))
  LOCAL lLibro :=SQLGET("DPTIPDOCPRO","TDC_LIBCOM","TDC_TIPO"+GetWhere("=",oDocCxP:DOC_TIPDOC))
  LOCAL cTipDoc:=SQLGET("DPTIPDOCPRO","TDC_TIPO"  ,"TDC_TIPO"+GetWhere("=",oDocCxP:DOC_TIPDOC))
  LOCAL aNoVacio:={oDocCxP:oDOC_FECHA,oDocCxP:oDOC_CODIGO},I,uValue

  IF oDocCxP:lPar_LibCom 
     AADD(aNoVacio,oDocCxP:oDOC_NUMFIS)
     AADD(aNoVacio,oDocCxP:oDOC_FCHDEC)
  ENDIF


  FOR I=1 TO LEN(aNoVacio)

    aNoVacio[I]:bWhen:=IF(aNoVacio[I]:bWhen=NIL,{||.T.},aNoVacio[I]:bWhen)

    uValue:=aNoVacio[I]:VarGet() .AND. !EVAL(aNoVacio[I]:bWhen)

    IF Empty(uValue)
      aNoVacio[I]:MsgErr(aNoVacio[I]:cToolTip,"Valor no puede estar Vacio") // Muestra el Mensaje Tooltips
      RETURN .F.
    ENDIF

  NEXT I

  oDocCxP:AUTONUM()
  oDocCxP:CALNETO()

  oDocCxP:DOC_TIPTRA='D'
  oDocCxP:DOC_CXP    :=IIF(cDebCre="D",1,-1)
  oDocCxP:DOC_ACT    :=1
  oDocCxP:cNumDoc    :=oDocCxP:DOC_NUMERO
  oDocCxP:nMtoIva    :=oDocCxP:DOC_MTOIVA

  IF oDocCxP:nOption=1 .AND. ValType(oDocCxP:oPagos)="O" .AND. oDocCxP:oPagos:oWnd:hWnd>0
    oDocCxP:DOC_FECHA:=oDocCxP:oPagos:PAG_FECHA
    oDocCxP:DOC_HORA :=oDocCxP:oPagos:PAG_HORA
  ENDIF

  IIF( EMPTY( oDocCxP:DOC_VALCAM ) , oDocCxP:PROVALCAM(.F.) , NIL )

  oDocCxP:cPrimary   :="DOC_CODSUC,DOC_TIPDOC,DOC_CODIGO,DOC_NUMERO"


  // Valida numero para que se le coloquen los ceros a la izquierda
  IF !oDocCxP:lSaved

    IF !EVAL(oDocCxP:oDOC_NUMERO:bValid)
      DPFOCUS(oDocCxP:oDOC_NUMERO)
      RETURN .F.
    ENDIF

  ENDIF

  IF lLibro=.T. .AND. Empty(oDocCxP:DOC_NUMFIS)
     oDocCxP:oDOC_NUMFIS:MsgErr("Es Necesario Colocar Numero Fiscal")
     RETURN .F.
  ENDIF

  IF oDocCxP:DOC_NETO=0 .AND. oDocCxP:lSaved
     oDocCxP:oDOC_NUMERO:MsgErr("Documento requiere Valor")
     RETURN .F.
  ENDIF

  IF !Empty(oDocCxP:cCenCos)
      oDocCxP:SET("DOC_CENCOS",oDocCxP:cCenCos,.T.)
  ENDIF
  
RETURN .T.

// Graba los Impuestos
FUNCTION POSTGRABAR()
  LOCAL oTable,cWhere,I,aData,lAutoIslr:=.T.,lHayRet:=.T.,cWhere,lRti:=.F.,lIslr:=.F.,nMtoBas:=0

  // Impuestos Directos
  oDocCxP:lNinguno:=.F.
  oDocCxP:DOC_NUMMEM:=DPMEMOSAVE(oDocCxP:DOC_NUMMEM,oDocCxP:cMemo,"")

  // JN 21/04/08
  IF oDocCxP:nOption=3

     // Si se Pìerde la Integridad Modificar la DPDOCPROCTA
     cWhere:="CCD_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC_)+" AND "+;
             "CCD_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC_)+" AND "+;
             "CCD_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO_)+" AND "+;
             "CCD_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO_)

     SQLUPDATE("DPDOCPROCTA",{"CCD_NUMERO"      ,"CCD_CODIGO"      },;
                             {oDocCxP:DOC_NUMERO,oDocCxP:DOC_CODIGO},cWhere)



     // Si se Pìerde la Integridad Modificar la DPDOCPRORTI
     cWhere:="RTI_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC_)+" AND "+;
             "RTI_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC_)+" AND "+;
             "RTI_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO_)+" AND "+;
             "RTI_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO_)

     SQLUPDATE("DPDOCPRORTI",{"RTI_NUMERO"      ,"RTI_CODIGO"      },;
                             {oDocCxP:DOC_NUMERO,oDocCxP:DOC_CODIGO},cWhere)

     lRti:=COUNT("DPDOCPRORTI",cWhere)>0


     // Si se Pìerde la Integridad Modificar la DPDOCPROISLR
     cWhere:="RXP_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC_)+" AND "+;
             "RXP_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC_)+" AND "+;
             "RXP_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO_)+" AND "+;
             "RXP_NUMDOC"+GetWhere("=",oDocCxP:DOC_NUMERO_)

     SQLUPDATE("DPDOCPROISLR",{"RXP_NUMDOC"      ,"RXP_CODIGO"      },;
                              {oDocCxP:DOC_NUMERO,oDocCxP:DOC_CODIGO},cWhere)

     nMtoBas:=SQLGET("DPDOCPROISLR","RXP_MTOBAS",cWhere)

     IF nMtoBas>0 .AND. nMtoBas<>oDocCxP:DOC_BASNET
        MsgMemo("Monto Base "+ALLTRIM(TRAN(nMtoBas,"999,999,999.99"))+" de la Retención de ISRL,"+CRLF+"Difiere del Monto de la Base Imponible del Documento "+ALLTRIM(TRAN(oDocCxP:DOC_BASNET,"999,999,999.99")))
     ENDIF

     lIslr:=COUNT("DPDOCPROISLR",cWhere)>0

     IF oDocCxP:DOC_TIPDOC<>"CPT" .OR. lRti

        EJECUTAR("DPDOCCLIIVA",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO,.T.,;
                               oDocCxP:DOC_DCTO  ,oDocCxP:DOC_RECARG,oDocCxP:DOC_OTROS,oDocCxP:DOC_IMPOTR,"C")
     ENDIF

     // Si hay Asientos Diferidos los Elimina
     IF  !Empty(oDocCxP:DOC_CBTNUM) 

        SQLDELETE("DPASIENTOS","MOC_NUMCBT"+GetWhere("=",oDocCxP:DOC_CBTNUM)+" AND "+;
                               "MOC_FECHA "+GetWhere("=",oDocCxP:dFecha    )+" AND "+;
                               "MOC_TIPO  "+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                               "MOC_DOCUME"+GetWhere("=",oDocCxP:cNumDoc   )+" AND "+;
                               "MOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                               "MOC_TIPTRA"+GetWhere("=","D"               )+" AND "+;
                               "MOC_ACTUAL"+GetWhere("=","N"               )+" AND "+;
                               "MOC_ORIGEN"+GetWhere("=","COM"))
    
     ENDIF

  ENDIF

  // Debe evaluar, si el tipo de documento, acepta retenciones  ag dp
  // Este Valor se Genera en el PROCESO AUTOMATICO: RETISLRAUTOMATICA   
  DEFAULT oDp:lRetISLR:=.F.

  oDocCxP:oFrmIslr:=oDp:lRetISLR

  IF !oDp:lRetISLR .OR. lIslr

    lAutoIslr:=Alltrim(SQLGET("DPDATASET","DAT_VALUE","DAT_NAME='RETLAPLAUTO' AND DAT_MODE"+GetWhere("=",oDp:cUsuario)))="T"

  ENDIF
//?? lAutoIslr,"lAutoIslr"
  // Cheques Devueltos
  IF oDocCxP:DOC_TIPDOC="CHD" 
    EJECUTAR("DPDOCPROCHDDEV",oDocCxP)
  ENDIF

  // 06/10/2022
  IF oDocCxP:DOC_TIPDOC="FAC" .AND. oDocCxP:nOption=1 .AND. oDp:lRTIFCHVEN
     // Fecha de declaración estará vacia y no se puede contabilizar

     cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
             "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
             "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
             "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND DOC_TIPTRA"+GetWhere("=","D")

     oDocCxP:DOC_FCHDEC:=CTOD("")
     SQLUPDATE("DPDOCPRO","DOC_FCHDEC",oDocCxP:DOC_FCHDEC,cWhere)

   ENDIF

  // Retencion de ISLR Automático

  IF ((oDocCxP:nOption=3 .OR. oDocCxP:nOption=1) .AND. oDp:lRetIslr_A) .OR. lIslr

    lHayRet:=COUNT("DPDOCPRO","INNER JOIN DPDOCPROCTA ON DOC_CODSUC=CCD_CODSUC AND DOC_TIPDOC=CCD_TIPDOC AND DOC_NUMERO=CCD_NUMERO "+;
                              "INNER JOIN DPCTA ON CCD_CODCTA=CTA_CODIGO "+;
                              "WHERE DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+;
                              "  AND DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+;
                              "  AND DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+;
                              "  AND DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+;
                              "  AND CTA_CODCON"+GetWhere("<>",""))>0

    IF lHayRet .OR. lIslr

      EJECUTAR("DPDOCISLR",oDocCxP:DOC_CODSUC,;
                           oDocCxP:DOC_TIPDOC,;
                           oDocCxP:DOC_CODIGO,;
                           oDocCxP:DOC_NUMERO,;
                           NIL , "C" , 0 , oDp:lRetIslr_A)


     IF oDocCxP:nOption=3 .AND. lIslr
       oDoc:LoadData(3)
       oGrid:Open() 
       oGrid:BtnSave()
       oGrid:Open()   
     ENDIF

    ENDIF

  ENDIF
  // fin ag dp

//  EJECUTAR("DPPROCESOSRUN","DPDOCPROPOSGRA",oDocCxP)

  IF (oDocCxP:lPar_ConAut .AND. oDocCxP:DOC_NETO<>0 ) .OR. (oDocCxP:nOption=3 .AND. !Empty(oDocCxP:DOC_CBTNUM))
    
    // 06/10/2022
    IF !Empty(oDocCxP:DOC_FCHDEC)

        MsgRun("Contabilizando Documento "+oDoc:DOC_NUMERO ,"Por favor Espere",{||;
                EJECUTAR("DPDOCCONTAB", NIL,oDocCxP:DOC_CODSUC,;
                                        oDocCxP:DOC_TIPDOC,;
                                        oDocCxP:DOC_CODIGO,;
                                        oDocCxP:DOC_NUMERO,.F.,.F.) })
    ENDIF

  ENDIF

  SQLUPDATE("DPDOCPRO",{"DOC_NUMMEM","DOC_BASNET"},{oDocCxP:DOC_NUMMEM,oDocCxP:DOC_BASNET},;
                        "DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                        "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                        "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                        "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND "+;
                        "DOC_TIPTRA='D'"                            )

  IF oDocCxP:nOption=3

      // 27/09/2012
      cWhere:="RTI_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC_)+" AND "+;
              "RTI_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC_)+" AND "+;
              "RTI_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO_)+" AND "+;
              "RTI_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO_)

      SQLUPDATE("DPDOCPRORTI","RTI_NUMERO",oDocCxP:DOC_NUMERO,cWhere)

      cWhere:="RXP_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC_)+" AND "+;
              "RXP_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC_)+" AND "+;
              "RXP_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO_)+" AND "+;
              "RXP_NUMDOC"+GetWhere("=",oDocCxP:DOC_NUMERO_)

      SQLUPDATE("DPDOCPROISLR","RXP_NUMDOC",oDocCxP:DOC_NUMERO,cWhere)

  ENDIF

 // JN 21/08/2014
  IF oDocCxP:DOC_TIPDOC="REI" .OR. oDocCxP:DOC_TIPDOC="CPT"

    EJECUTAR("DPDOCCLIIVA",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO,.T.,;
                           oDocCxP:DOC_DCTO  ,oDocCxP:DOC_RECARG,oDocCxP:DOC_OTROS,oDocCxP:DOC_IMPOTR,"C")

    EJECUTAR("DPREINTOFAC",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO)

  ENDIF

  IF oDocCxP:DOC_TIPDOC="PPF"

     EJECUTAR("DPDOCPROPPFTOPRG",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO,oDocCxP:DOC_NUMFIS)

  ELSE

     oDocCxP:cTipDocAnt:=oDocCxP:cTipDoc

     EJECUTAR("DPPRODOCMNU",oDocCxP:DOC_CODSUC,;
                            oDocCxP:DOC_TIPDOC,;
                            oDocCxP:DOC_NUMERO,;
                            oDocCxP:DOC_CODIGO,NIL,oDocCxP,!lAutoIslr)

  ENDIF

  IF ValType(oDocCxP:oPagos)="O" .AND. oDocCxP:oPagos:oWnd:hWnd>0
    oDocCxP:oPagos:ImportDoc()
    oDocCxP:Close() // Cierra el Formulario
  ENDIF

  // Cuando es Contribuyente Especial, el documento Posee IVA, y se aplica Retención cuando se Registra
  IF oDocCxP:DOC_MTOIVA>0 .AND. (oDocCxP:lPar_RetIva .AND. LEFT(oDp:cTipCon,1)="E" .AND. oDp:cRetIva_C="R" .AND. oDp:lRetIva_A) .OR. lIslr

    SysRefresh(.T.)

    EJECUTAR("DPDOCPRORTISAV",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO,NIL,ISTABMOD("DPDOCPRORTI"),NIL,NIL,NIL,.F.)

  ENDIF

// Inactivado para que no llame los compromisos
/*
  EJECUTAR("DPRUNPROCAUTO",NIL,NIL,.T.)  // ag dp
*/

RETURN .T.

FUNCTION CHANGESERIE()
RETURN .T.

FUNCTION BRWSETFOCUS()
RETURN .T.

FUNCTION PREDELETE()
  LOCAL lResp:=.T.,cNombre:=ALLTRIM(oDocCxP:oTipDoc:aItems[oDocCxP:oTipDoc:nAt]),cWhere,cMemo
  LOCAL lAnuFiscal:=.F.

  oDocCxP:nOption:=5

  IF !EJECUTAR("DPVALFECHA",oDocCxP:DOC_FECHA,.T.,.T.)
    RETURN .F.
  ENDIF

  IF !oDocCxP:ISALTER()
     oDocCxP:nOption:=0
     RETURN .F.
  ENDIF

  cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
          "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND "+;
          "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND DOC_TIPTRA='D'"

 
  IF oDocCxP:DOC_ACT=0

    IF MensajeSN("Desea Reactivar :"+cNombre+" "+oDocCxP:DOC_NUMERO,cNombre+" posee Estatus Anulado")

      SQLUPDATE("DPDOCPRO","DOC_ACT"    ,  1   , cWhere)
      SQLUPDATE("DPDOCPRO","DOC_ESTADO" , "AC" , cWhere)
      SQLUPDATE("DPDOCPRO","DOC_ANUFIS" , .F.  , cWhere)

      // Cuentas del Documento
      cWhere:="CCD_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
              "CCD_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
              "CCD_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND "+;
              "CCD_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND CCD_TIPTRA"+GetWhere("=","D")

      SQLUPDATE("DPDOCPROCTA","CCD_ACT" , 1 , cWhere)

      // Retenciones Asociadas
      EJECUTAR("DPDOCPRODELASO",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO,1)

    IF oDocCxP:DOC_TIPDOC="CHD"
        // Anular Cheque Devuelto 02/04/2009
        SQLUPDATE("DPCTABANCOMOV","MOB_ACT",1," MOB_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC_)+" AND "+;
                                              " MOB_TIPO"  +GetWhere("=","CCD"              )+" AND "+;
                                              " MOB_FECHA" +GetWhere("=",oDocCxP:DOC_FECHA_ )+" AND "+;
                                              " MOB_ORIGEN"+GetWhere("=","DOC"              )+" AND "+;
                                              " MOB_MONTO" +GetWhere("=",oDocCxP:DOC_NETO_  )+" AND "+;
                                              " MOB_DOCASO"+GetWhere("=",oDocCxP:DOC_NUMERO_))
    ENDIF


      oDocCxP:DOC_ACT   :=1
      oDocCxP:DOC_ESTADO:="AC" 
      oDocCxP:oEstado:Refresh(.T.)
    ENDIF

    oDocCxP:nOption:=0
    oDocCxP:BtnPaint()
    oDocCxP:LOADDATA(0)

    RETURN .F.
  ENDIF

  IF !MensajeNS("Desea Anular",ALLTRIM(cNombre)+": "+oDocCxP:DOC_NUMERO)
    RETURN .F.
  ENDIF

  IF oDocCxP:DOC_CXP<>0 .AND. MsgNoYes("Número: "+oDocCxP:DOC_NUMERO,"Aplicar Anulación Fiscal "+oDocCxP:cNomDoc)
    lAnuFiscal:=.T.
  ENDIF

  SQLUPDATE("DPDOCPRO","DOC_ACT"    ,  0         , cWhere)
  SQLUPDATE("DPDOCPRO","DOC_ESTADO" , "NU"       , cWhere)
  SQLUPDATE("DPDOCPRO","DOC_ANUFIS" , lAnuFiscal , cWhere)

  // Cuentas del Documento
  cWhere:="CCD_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
          "CCD_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
          "CCD_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND "+;
          "CCD_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND CCD_TIPTRA"+GetWhere("=","D")

  SQLUPDATE("DPDOCPROCTA","CCD_ACT" , 0 , cWhere)

  // Retenciones Asociadas
  EJECUTAR("DPDOCPRODELASO",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO , 0)

  IF oDocCxP:DOC_TIPDOC="CHD"
    // Anular Cheque Devuelto 02/04/2009
    SQLUPDATE("DPCTABANCOMOV","MOB_ACT",0," MOB_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC_)+" AND "+;
                                          " MOB_TIPO"  +GetWhere("=","CCD"              )+" AND "+;
                                          " MOB_FECHA" +GetWhere("=",oDocCxP:DOC_FECHA_ )+" AND "+;
                                          " MOB_ORIGEN"+GetWhere("=","DOC"              )+" AND "+;
                                          " MOB_MONTO" +GetWhere("=",oDocCxP:DOC_NETO_  )+" AND "+;
                                          " MOB_DOCASO"+GetWhere("=",oDocCxP:DOC_NUMERO_))

  ENDIF

  oDocCxP:DOC_ACT   :=0
  oDocCxP:DOC_ESTADO:="NU" 
  oDocCxP:DOC_ANUFIS:=lAnuFiscal
  oDocCxP:nOption   :=0
  oDocCxP:oEstado:Refresh(.T.)
  oDocCxP:LOADDATA(0)
RETURN .F.

FUNCTION VALFCHDEC()
  LOCAL bLost :=oDocCxP:oDOC_FCHDEC:bLostFocus
  LOCAL cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)


  IF Empty(oDocCxP:DOC_FCHDEC) .AND. (oDocCxP:nOption=1 .OR. oDocCxP:nOption=3)
     oDocCxP:oDOC_FCHDEC:VarPut(oDocCxP:DOC_FECHA)
//   RETURN .F.
  ENDIF

  oDocCxP:oDOC_FCHDEC:bLostFocus:={||NIL}

  IF oDocCxP:DOC_FCHDEC<oDocCxP:DOC_FECHA
    oDocCxP:oDOC_FCHDEC:MsgErr("Fecha de Declaración no puede ser Inferior que "+DTOC(oDocCxP:DOC_FECHA))
    oDocCxP:oDOC_FCHDEC:bLostFocus:=bLost
    EVAL(oDocCxP:oDOC_FCHDEC:bGotFocus)
    oDocCxP:lDOC_FCHDEC:=.T.
    RETURN .F.
  ENDIF

  IF !EJECUTAR("DPVALFECHA",oDocCxP:DOC_FCHDEC,.T.,.T.,oDocCxP:oDOC_FCHDEC)
     oDocCxP:oDOC_FCHDEC:bLostFocus:=bLost
     oDocCxP:lDOC_FCHDEC:=.F.
     RETURN .F.
  ENDIF

  oDocCxP:oDOC_FCHDEC:bLostFocus:=bLost

//IF oDocCxP:nOption=1 .OR. .T.
  DPFOCUS(oDocCxP:aGrids[1]:oBrw)
//ENDIF

  oDocCxP:lDOC_FCHDEC:=.T.
  oDocCxP:oDOC_FCHDEC:SetColor(oDp:GetnCltText,oDp:GetnClrPane) // Recupera Color

RETURN .T.

// Anulación de Documento de Compra
FUNCTION POSTDELETE()
  EJECUTAR("DPDOCPROPOSDEL",oDocCxP)
RETURN .T.

PROCE SETCUENTAS()
  LOCAL aIva,oSayRef,cSql,oCol,oGrid,aTipIva:={}

  aIva:=ASQL("SELECT TIP_CODIGO,TIP_DESCRI FROM DPIVATIP WHERE TIP_ACTIVO=1 AND TIP_COMPRA=1")
  // Aeval(aIva,{|a,n|aIva[n]:=aIva[n,1]+":"+aIva[n,2]})
  Aeval(aIva,{|a,n|AADD(aTipIva,a[1]),aIva[n]:=aIva[n,2]})

  oDocCxP:cSayCta:=SPACE(30)
  oDocCxP:cSayCen:=SPACE(30)
  oDocCxP:cNomCta:=SPACE(30)

  // Font Para el Browse
  @ 2,2 SAY oDocCxP:oNomCta PROMPT oDocCxP:cNomCta+":" RIGHT

  @ 1.0,0 SAYREF oDocCxP:oSayCta PROMPT oDocCxP:cSayCta SIZE 42,12 UPDATE COLORS CLR_HBLUE,oDp:nGris

  oDocCxP:oSayCta:bAction:={||EJECUTAR("DPCTACON",oGrid:CCD_CODCTA)}

  @ 1.0,0 SAYREF oDocCxP:oSayCen PROMPT oDocCxP:cSayCen SIZE 42,12 COLORS CLR_HBLUE,oDp:nGris

  oDocCxP:oSayCen:bAction:={||EJECUTAR("DPCENCOSCON",oGrid:CCD_CENCOS)}

  @ 14,1 SAY oDocCxP:oDpCenCos  PROMPT oDp:xDPCENCOS+":" RIGHT SIZE 40,10

  IF oDocCxP:lCtaEgr 
    @ 14,1 SAY oDocCxP:oDpCtaSay PROMPT GetFromVar("{oDp:xDPCTAEGRESO}")+":" RIGHT SIZE 40,10
  ELSE
    @ 14,1 SAY  oDocCxP:oDpCtaSay PROMPT GetFromVar("{oDp:xDPCTA}")+":" RIGHT SIZE 40,10
  ENDIF

  cSql :="SELECT * FROM DPDOCPROCTA "

  IF !oDocCxP:lCtaEgr
     cSql:=cSql+" LEFT JOIN DPCTA       ON CCD_CTAMOD=CTA_CODMOD AND CCD_CODCTA=CTA_CODIGO "
  ELSE
     cSql:=cSql+" LEFT JOIN DPCTAEGRESO ON CCD_CTAEGR=CEG_CODIGO "
  ENDIF

// ? cSql,"cSql"

  oGrid:=oDocCxP:GridEdit( "DPDOCPROCTA" ,"DOC_CODSUC,DOC_TIPDOC,DOC_CODIGO,DOC_NUMERO","CCD_CODSUC,CCD_TIPDOC,CCD_CODIGO,CCD_NUMERO" , cSql , "CCD_ACT=1" ) 

  oGrid:cScript  :="DPDOCCXP"
  oGrid:aSize    :={0,0,IIF(Empty(oDp:cModeVideo),765,905+165-70),IIF(Empty(oDp:cModeVideo),185,285)}
  oGrid:oFont    :=oFontGrid
  oGrid:bValid   :=".T."
  oGrid:lBar     :=.F.
  oGrid:oDlg     :=oDocCxP:oFolder:aDialogs[1]
  oGrid:aIva     :=ACLONE(aIva)
  oGrid:aTipIva  :=ACLONE(aTipIva)
  oGrid:lAutoRef :=.F. // Referencia Automática
  oGrid:nPorIva  := 0.00
  oGrid:cTipIva  :=""

  oGrid:lTotal   :=.T.
  oGrid:oFontH   :=oFontGrid
  oGrid:oFontB   :=oFontGrid

  oGrid:cPostSave  :="GRIDPOSTSAVE"
  oGrid:cPreSave   :="GRIDPRESAVE"
  oGrid:cPreDelete :="GRIDPREDELETE"
  oGrid:cPostDelete:="GRIDPOSTDELETE" 
  oGrid:cItem      :="CCD_ITEM" 
  oGrid:bChange    :={||oDocCxP:SAYCTA()}
  oGrid:bWhen      :={||!Empty(oDocCxP:DOC_CODIGO) .AND. !Empty(oDocCxP:DOC_NUMERO) .AND. oDocCxP:lNumFis}
  oGrid:aActivo    :={} // {"CODIGO","DESCRI","GRUPO","UBICACION","NUMMEMO"} // Datos del Activo
  oGrid:aCargo     :={} // Contiene los Gastos del Reintegro
  oGrid:aCajMov    :={} // Movimiento de Caja

  oGrid:cLoad    :="GRIDLOAD"
  oGrid:cTotal   :="GRIDTOTAL" 
  oGrid:SetMemo("CCD_NUMMEM","Descripción Amplia",1,1,100,200)

  oGrid:cPrimary    :=oGrid:cLinkGrid+","+oGrid:cItem
  oGrid:cKeyAudita  :=oGrid:cPrimary

  oGrid:nClrPane1   :=oDp:nClrPane1 // 15006969
  oGrid:nClrPane2   :=oDp:nClrPane2 // 14678271

  oGrid:nClrPaneH   := oDp:nGrid_ClrPaneH // 11856126
  oGrid:nClrTextH   := CLR_BLACK

  oGrid:nClrPaneF   := oDp:nGrid_ClrPaneH // 11856126
  oGrid:nClrTextF   := CLR_BLACK

  oGrid:nRecSelColor:= oDp:nRecSelColor

  oGrid:nClrPane1   :=oDp:nClrPane1
  oGrid:nClrPane2   :=oDp:nClrPane2
  oGrid:nClrPaneH   :=oDp:nGrid_ClrPaneH
  oGrid:nClrTextH   :=0
  oGrid:nRecSelColor:=oDp:nRecSelColor  // oDp:nLbxClrHeaderPane // 12578047 // 16763283


  oGrid:SetScope("CCD_ACT=1")
  oGrid:cDeleteUpdate:="CCD_ACT=0" 


  oGrid:AddBtn("activofijos2.bmp","Registro de Activo","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [EJECUTAR("DPDOCACTIVO",oGrid)],"IMP")

  oGrid:AddBtn("facturacompra.bmp","Registro de Compra","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [EJECUTAR("DPDOCPROREIN",oGrid)],"REM")

  oGrid:AddBtn("PROVEEDORPROG.BMP","Referencia de Planificación","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [EJECUTAR("DPDOCPROPROG",oGrid)],"PRO")

  oGrid:AddBtn("instrumentosdecaja.BMP","Ingreso hacia Caja","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [EJECUTAR("DPDOCPROCAJA",oGrid)],"PRO")

  IF oDocCxP:lCtaEgr 
    // Renglon Cuenta de Egreso
    oCol:=oGrid:AddCol("CCD_CTAEGR")
    oCol:cTitle       :=oDp:xDPCTAEGRESO
    oCol:bValid       :={||oGrid:VCCD_CTAEGR(oGrid:CCD_CTAEGR)}
    oCol:cMsgValid    :="Cuenta de Egreso no Existe"
    oCol:cListBox     :="DPCTAEGRESO.LBX"
    oCol:cWhereListBox:="CEG_EGRES=1"
    oCol:bWhen        :="!oDocCxP:DOC_NODEDU"
    oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),130,150+32)
    oCol:nEditType:=EDIT_GET_BUTTON
    oCol:bRunOff  :={||EJECUTAR("DPCTAEGRESOCON",NIL,oGrid:CCD_CTAEGR)}

    IF oDocCxP:lAutoSize
      oCol:=oGrid:AddCol("CEG_DESCRI")
      oCol:cTitle:="Nombre de la Cuenta"
      oCol:bWhen :=".f."
      oCol:bCalc :={||SQLGET("DPCTAEGRESO","CEG_DESCRI","CEG_CODIGO"+GetWhere("=",oGrid:CCD_CTAEGR))}
    ENDIF

    oCol:bRunOff  :={||EJECUTAR("DPCTAEGRESOCON",NIL,oGrid:CCD_CTAEGR)}


  ELSE

    // Renglon Cuenta Contable
    oCol:=oGrid:AddCol("CCD_CODCTA")
    oCol:cTitle   :=oDp:xDPCTA
    oCol:bValid   :={||oGrid:VCCD_CODCTA(oGrid:CCD_CODCTA)}
    oCol:cMsgValid:="Cuenta Contable no Existe"
    oCol:cListBox :="DPCTAACT.LBX"
    oCol:bWhen    :="!oDocCxP:DOC_NODEDU"
    oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),130,150+32)
    oCol:nEditType:=EDIT_GET_BUTTON

    IF oDocCxP:lAutoSize

      oCol:bPostEdit:='oGrid:ColCalc("CTA_DESCRI")'

      oCol:=oGrid:AddCol("CTA_DESCRI")
      oCol:cTitle:="Nombre de la Cuenta"
      oCol:bCalc :={||oDocCxP:cSayCta}
      oCol:bWhen :={||.F.}
    ENDIF

  ENDIF

  // Renglon C. Costo
  oCol:=oGrid:AddCol("CCD_CENCOS")
  oCol:cTitle   :="C.Costo"
  oCol:bValid   :={||oGrid:VCCD_CENCOS(oGrid:CCD_CENCOS)}
  oCol:cMsgValid:="Centro de Costo no Existe"
  oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),90,100)
  oCol:cListBox :="DPCENCOSACT.LBX"
  oCol:nEditType:=EDIT_GET_BUTTON

  // Renglon Descripción
  oCol:=oGrid:AddCol("CCD_DESCRI")
  oCol:cTitle:="Descripción"
  oCol:nWidth:=IIF(Empty(oDp:cModeVideo),295,375)
  oCol:bValid:={|| !Empty(oGrid:CCD_DESCRI) }
 

  // Renglon Monto Base
  oCol:=oGrid:AddCol("CCD_MONTO")
  oCol:cTitle:="Monto Base"
  oCol:nWidth:=IIF(Empty(oDp:cModeVideo),130,150)
  oCol:cPicture:="99,999,999,999.99"
  oCol:lTotal:=.T.
  oCol:bValid:={||oGrid:VCCD_MONTO(oGrid:CCD_MONTO)}
  oCol:lTotal:=.T.
  oDocCxP:nColMonto:=4


  // Renglon % IVA
  oCol:=oGrid:AddCol("CCD_TIPIVA")
  oCol:cTitle    :="IVA"
  oCol:nWidth    :=70
  oCol:aItems    :={||oGrid:BuildIva(.F.)}
  oCol:aItemsData:={||oGrid:BuildIvaCod()}
  oCol:lRepeat   :=.T.
  oCol:bWhen     :="oGrid:CCD_LIBCOM"
  oCol:bValid    :={||oGrid:VCCD_TIPIVA(oGrid:CCD_TIPIVA)}

  oCol:=oGrid:AddCol("CCD_PORIVA")
  oCol:cTitle    :="%IVA"
  oCol:nWidth    :=70
  oCol:bWhen     :=".F."
  oCol:bPostEdit:='oGrid:ColCalc("CCD_TOTAL")'


// Renglon Monto Base
  oCol:=oGrid:AddCol("CCD_TOTAL")
  oCol:cTitle:="Total"
  oCol:nWidth:=IIF(Empty(oDp:cModeVideo),130,150)
  oCol:cPicture:="99,999,999,999,999.99"
  oCol:bWhen :=".f."
  oCol:lTotal:=.T.


RETURN

FUNCTION DOCINI()

  oDocCxP:CALNETO()
  oDocCxP:SAYCTA()
  oDocCxP:oFocusFind:=oDocCxP:oDOC_CODIGO

RETURN .T.

// Después de Borrar
FUNCTION POSTDELETE()
  oDocCxP:CALNETO()
RETURN .T.

// Carga para Incluir o Modificar en el Grid
FUNCTION GRIDLOAD()

  oGrid:Set("CCD_TIPTRA","D"               )
  oGrid:Set("CCD_CODSUC",oDocCxP:DOC_CODSUC)
  oGrid:Set("CCD_NUMERO",oDocCxP:DOC_NUMERO)
  oGrid:Set("CCD_TIPDOC",oDocCxP:DOC_TIPDOC)
  oGrid:Set("CCD_CODIGO",oDocCxP:DOC_CODIGO)

  oGrid:aCargo:={} // JN 01/12/2015

  IF oGrid:nOption=1

    oGrid:=oDocCxP:aGrids[1]

    oGrid:Set("CCD_LIBCOM",.T.)
    oGrid:aActivo:={}
    oGrid:aCajMov:={}
    oGrid:aCargo:={}

    IF !Empty(oDocCxP:DOC_CODIGO) .AND. oDocCxP:nOption=1
      oDocCxP:ASG_ULT_CTA() // Recuerda Ultima Cuenta Contable
    ENDIF

    IF Empty(oGrid:CCD_CENCOS) .OR. COUNT("DPCENCOS")=1
      oGrid:Set("CCD_CENCOS",oDp:cCenCos,.T.)
    ENDIF

  ELSE
    oGrid:aCajMov:=IIF( Empty(oGrid:CCD_CODCAJ), {} , {oGrid:CCD_CODCAJ,oGrid:CCD_CODINS} )
  ENDIF

  IF oGrid:nOption=3
    EJECUTAR("DPDOCACTIVOLOAD",oGrid)
  ENDIF

RETURN NIL

// Ejecución despues de Grabar el Item
// Grabando

FUNCTION GRIDPOSTSAVE()
  LOCAL aIva   :=oGrid:BUILDIVA(.T.)
  LOCAL aTipIva:=oGrid:BUILDIVA(.F.)
  LOCAL nAt,cWhere

  IF !oGrid:CCD_LIBCOM
    oGrid:CCD_PORIVA:=0
  ENDIF

/*
  oGrid:Set("CCD_PORIVA",oGrid:nPorIva,.T.)
  nAt:=MAX(ASCAN(aIva,oGrid:CCD_PORIVA),1)

  oGrid:CCD_TIPIVA:=LEFT(aTipIva[nAt],2)
*/

  nAt:=MAX(ASCAN(aTipIva,{|a,n| oGrid:CCD_TIPIVA=LEFT(a,2)}),1)

  oGrid:SET("CCD_PORIVA",aIva[nAt],.T.)



  IF !Empty(oGrid:cWhere)

     cWhere:=oGrid:cWhere

  ELSE

     cWhere:="     CCD_CODSUC"+GetWhere("=",oGrid:CCD_CODSUC)+" "+;
             " AND CCD_TIPDOC"+GetWhere("=",oGrid:CCD_TIPDOC)+" "+;
             " AND CCD_CODIGO"+GetWhere("=",oGrid:CCD_CODIGO)+" "+;
             " AND CCD_NUMERO"+GetWhere("=",oGrid:CCD_NUMERO)+" "+;
             " AND CCD_ITEM"  +GetWhere("=",oGrid:CCD_ITEM  )+" "+;
             " AND CCD_ACT=1"

  ENDIF

  SQLUPDATE(oGrid:cTable,{"CCD_TIPIVA"    ,"CCD_PORIVA"    },;
                         {oGrid:CCD_TIPIVA,oGrid:CCD_PORIVA},cWhere)

  oDocCxP:CALNETO()

  // Graba el Activo Fijo
 
  EJECUTAR("DPDOCACTIVOGRAB",oGrid)
  EJECUTAR("DPDOCCOMPRAGRAB",oGrid)
  EJECUTAR("DPDOCCAJAGRAB"  ,oGrid)
 
  oGrid:aActivo:={}
  oGrid:aCargo:={}

RETURN .T.

// Genera los Totales por Grid
FUNCTION GRIDTOTAL()
RETURN .T.

// Valida Código de Retención
FUNCTION VCCD_CODCTA(cCodCta)
  LOCAL lResp:=.F.,cCuenta:=""

  IF !ALLTRIM(SQLGET("DPCTA","CTA_CODIGO","CTA_CODIGO"+GetWhere("=",cCodCta)))==ALLTRIM(cCodCta)
       RETURN .F.
  ENDIF

/*
  IF !ALLTRIM(SQLGET("DPCTAEGRESO","CEG_CODIGO,CEG_CUENTA","CEG_CODIGO"+GetWhere("=",cCodCta)))==ALLTRIM(cCodCta)
    RETURN .F.
  ENDIF
*/
  IF !EJECUTAR("ISCTADET",cCodCta , .F. )
    oGrid:GetCol("CCD_CODCTA"):MensajeErr("Cuenta no Acepta Asientos")
    RETURN .F.
  ENDIF

  oDocCxP:SAYCTA()

  EJECUTAR("DPDOCPROPROG",oGrid,.T.)

  // ag dp
  // Se inhabilito ya que ahora CTA_ACTIVO hace referencia a si la cuenta contable
  // estara activa o no. TJ 

//  oGrid:GetCol("CCD_CTADESCTA"):MensajeErr("Cuenta no Acepta Asientos")

/*
  IF SQLGET("DPCTA","CTA_ACTIVO","CTA_CODIGO"+GetWhere("=",cCodCta))
    EJECUTAR("DPDOCACTIVO",oGrid)
  ENDIF
*/

  IF Empty(oGrid:CCD_CENCOS)
    oGrid:Set("CCD_CENCOS",oDp:cCenCos,.T.)
  ENDIF

RETURN .T.

// Valida Código de Retención
FUNCTION VCCD_CTAEGR(cCodCta)
  LOCAL lResp:=.F.,cCuenta:="",oCol:=nil
  LOCAL cTipIva:=""

  IF !ALLTRIM(SQLGET("DPCTAEGRESO","CEG_CODIGO,CEG_CUENTA,CEG_TIPIVA","CEG_CODIGO"+GetWhere("=",cCodCta)))==ALLTRIM(cCodCta)
    RETURN .F.
  ENDIF

//  IF !ISSQLFIND("DPCTAEGRESO","CEG_CODIGO,CEG_CUENTA,CEG_TIPIVA","CEG_CODIGO"+GetWhere("=",cCodCta))
    //=ALLTRIM(cCodCta)
//    RETURN .F.
//  ENDIF

  // ag dp
  SQLGET("DPCTAEGRESO","CEG_CODIGO,CEG_CUENTA,CEG_TIPIVA","CEG_CODIGO"+GetWhere("=",cCodCta))

  cCuenta:=DPSQLROW(2) 
  cTipIva:=DPSQLROW(3) 

  oGrid:=oDocCxP:aGrids[1]
  oGrid:Set("CCD_TIPIVA",cTipIva,.T.)
  oGrid:VCCD_TIPIVA(oGrid:CCD_TIPIVA)

  oCol:=oGrid:GetCol("CEG_DESCRI")

  IF !oCol=NIL
    oCol:RunCalc()
  ENDIF

  oDocCxP:SAYCTA()

  EJECUTAR("DPDOCPROPROG",oGrid,.T.)

  IF Empty(oGrid:CCD_CENCOS)
    oGrid:Set("CCD_CENCOS",oDp:cCenCos,.T.)
  ENDIF
  
  // Se inhabilito ya que ahora CTA_ACTIVO hace referencia a si la cuenta contable
  // estara activa o no. TJ 03-03-2016
/*  
  IF SQLGET("DPCTA","CTA_ACTIVO","CTA_CODIGO"+GetWhere("=",cCuenta))
    EJECUTAR("DPDOCACTIVO",oGrid)
  ENDIF
*/

RETURN .T.
 // Valida Centro de Costos
FUNCTION VCCD_CENCOS(cCenCos)
  LOCAL lResp:=.F.

  IF !ALLTRIM(SQLGET("DPCENCOS","CEN_CODIGO","CEN_CODIGO"+GetWhere("=",cCenCos)))==ALLTRIM(cCenCos)
    RETURN .F.
  ENDIF

  IF !EJECUTAR("ISCENDET",cCenCos , .F. )
    oGrid:GetCol("CCD_CENCOS"):MensajeErr("Centro de Costo no Acepta Asientos")
    RETURN .F.
  ENDIF

  oDocCxP:SAYCTA()
RETURN .T.

// Valida Proyectos  // pq
FUNCTION VCCD_PROYEC(cProyec)
  LOCAL lResp:=.F.
/*
  IF !ALLTRIM(SQLGET("DPPROYECTOS","PRY_CODIGO","PRY_CODIGO"+GetWhere("=",cProyec)))==ALLTRIM(cProyec)
    RETURN .F.
  ENDIF
*/
//  IF !EJECUTAR("ISCENDET",cCenCos , .F. )
//    oGrid:GetCol("CCD_CENCOS"):MensajeErr("Centro de Costo no Acepta Asientos")
//    RETURN .F.
//  ENDIF

//  oDocCxP:SAYCTA()
RETURN .T.

// Valida Monto Base
FUNCTION VCCD_MONTO(nMonto)

  IF Empty(nMonto)
    oGrid:GetCol("CCD_MONTO"):MensajeErr("Monto debe ser Diferente que Cero")
    RETURN .F.
  ENDIF

  oDocCxP:DOC_NETO:=oGrid:CCD_MONTO

  IF Empty(oDocCxP:DOC_NETO)
     oDocCxP:DOC_NETO:=oGrid:CCD_MONTO
  ENDIF

RETURN .T.

FUNCTION GRIDPRINT()
  ? "IMPRIMIR CUENTAS CONTABLES"
RETURN .T.

FUNCTION SETCTANODEDUCC()
   LOCAL cCodCta,cCodEgr
   LOCAL oGrid:=oDocCxP:aGrids[1]

   IF (oGrid:nOption=1 .OR. oGrid:nOption=3) .AND.  oDocCxP:DOC_NODEDU

     cCodCta:=SQLGET("DPCODINTEGRA","CIN_CODCTA","CIN_CODIGO"+GetWhere("=","GASNODEDU"))

     IF Empty(cCodCta)
        cCodCta:=oDp:cCtaIndef
     ENDIF

     IF Empty(oGrid:CCD_CENCOS)
        oGrid:CCD_CENCOS:VarPut(oDp:cCenCos,.T.)
     ENDIF

     cCodEgr:=EJECUTAR("DPCTAEGRESOCREA",cCodCta,.T.)

     oGrid:Set("CCD_CODCTA",cCodCta,.T.)
     oGrid:Set("CCD_CTAEGR",cCodEgr,.T.)

     oGrid:CCD_CTAEGR:=cCodEgr
     oGrid:CCD_CODCTA:=cCodCta

     IF Empty(oGrid:CCD_CENCOS) .OR. COUNT("DPCENCOS")=1
        oGrid:Set("CCD_CENCOS",oDp:cCenCos,.T.)
     ENDIF

  ENDIF

RETURN .T.

// Pre-Grabar
FUNCTION GRIDPRESAVE()
  LOCAL nCol,nPorIva:=0,nAt
  LOCAL aIva   :=oGrid:BUILDIVA(.T.)
  LOCAL aTipIva:=oGrid:BUILDIVA(.F.)
  LOCAL lActivo:=SQLGET("DPIVATIP","TIP_ACTIVO","TIP_CODIGO"+GetWhere("=",oGrid:CCD_TIPIVA))
  LOCAL cCodCta:=""
  LOCAL oGrid   :=oDocCxP:aGrids[1]
  LOCAL cCodCta,cCodEgr

  oGrid:VCCD_TIPIVA(oGrid:CCD_TIPIVA)

  oGrid:CCD_TIPIVA:=LEFT(oGrid:CCD_TIPIVA,2) // no puede exceder 2 digitos



  // Gasto no Deducible, Busca el Codigo de Integración

  IF oDocCxP:DOC_NODEDU

     cCodCta:=SQLGET("DPCODINTEGRA","CIN_CODCTA","CIN_CODIGO"+GetWhere("=","GASNODEDU"))

     IF Empty(cCodCta)
        cCodCta:=oDp:cCtaIndef
     ENDIF

     IF Empty(oGrid:CCD_CENCOS)
        oGrid:CCD_CENCOS:VarPut(oDp:cCenCos,.T.)
     ENDIF

     cCodEgr:=EJECUTAR("DPCTAEGRESOCREA",cCodCta,.T.)

     oGrid:Set("CCD_CODCTA",cCodCta,.T.)
     oGrid:Set("CCD_CTAEGR",cCodEgr,.T.)

     oGrid:CCD_CTAEGR:=cCodEgr
     oGrid:CCD_CODCTA:=cCodCta

  ENDIF

  IF Empty(oGrid:CCD_CENCOS) .OR. COUNT("DPCENCOS")=1
     oGrid:Set("CCD_CENCOS",oDp:cCenCos,.T.)
  ENDIF


  IF !oGrid:CCD_LIBCOM
    nAt:=MAX(ASCAN(aIva,0),1)
    oGrid:CCD_TIPIVA:=aTipIva[nAt]
  ENDIF

  nAt:=MAX(ASCAN(aIva,oGrid:CCD_PORIVA),1)

  IF Empty(oGrid:aCargo) .AND. oDocCxP:DOC_TIPDOC="REI"
 
     IF !EJECUTAR("DPDOCPROREIN",oGrid)
        RETURN .F.
     ENDIF

  ENDIF

  IF !lActivo
     oGrid:MensajeErr("Tipo de IVA "+oGrid:CCD_TIPIVA+" no está Activo o No Existe","Mensaje de Validación")
     DPLBX("DPIVATIP")
     RETURN .F.
  ENDIF

  oGrid:CCD_TIPTRA:="D"
  //oGrid:CCD_TIPIVA:=aTipIva[nAt]
  oGrid:CCD_CODSUC:=oDocCxP:DOC_CODSUC
  oGrid:CCD_NUMERO:=oDocCxP:DOC_NUMERO
  oGrid:CCD_TIPDOC:=oDocCxP:DOC_TIPDOC
  oGrid:CCD_CTAMOD   :=oDp:cCtaMod
  oGrid:CCD_ACT   :=1
  oGrid:CCD_TIPCTA:=IIF(oDocCxP:lCtaEgr,"A","C")

// ? oGrid:CCD_CTAEGR,"oGrid:CCD_CTAEGR",oGrid:Get("CCD_CTAEGR")

  IF oDocCxP:lCtaEgr .AND. EMPTY(oGrid:CCD_CTAEGR)
    oGrid:MensajeErr("Es Necesario Indicar Código de Egreso ")
    RETURN .F.
  ENDIF

  IF EMPTY(oGrid:CCD_CENCOS)
    oGrid:MensajeErr("Es Necesario Indicar Centro de Costo")
    RETURN .F.
  ENDIF

  IF !oDocCxP:lCtaEgr
    oGrid:CCD_CTAEGR:=EJECUTAR("DPCTAEGRESOCREA",oGrid:CCD_CODCTA,.T.)
  ELSE
    oGrid:CCD_CODCTA:=SQLGET("DPCTAEGRESO","CEG_CUENTA","CEG_CODIGO"+GetWhere("=",oGrid:CCD_CTAEGR))
  ENDIF

  IF !Empty(oGrid:aCajMov)
     oGrid:CCD_CODCAJ:= oGrid:aCajMov[1]
     oGrid:CCD_CODINS:= oGrid:aCajMov[2]
  ENDIF

  IF Empty(oDocCxP:DOC_NETO)
      oDocCxP:DOC_NETO:=oGrid:CCD_MONTO
  ENDIF

  //oGrid:Set("CCD_PORIVA",oGrid:nPorIva)

  //? oGrid:CCD_TIPIVA,"oGrid:CCD_TIPIVA",oGrid:nPorIva

RETURN .T.

// Crea en Forma Automática el Documento de Retención
FUNCTION CREARDOC()
RETURN .T.

FUNCTION GRIDPREDELETE()

   oGrid:aCajMov:=IIF( Empty(oGrid:CCD_CODCAJ), {} , {oGrid:CCD_CODCAJ,oGrid:CCD_CODINS} )

RETURN .T.

FUNCTION GRIDPOSTDELETE()
  oGrid:nOption=5

  EJECUTAR("DPDOCCAJAGRAB",oGrid)

  oGrid:GRIDPOSTSAVE()
  // oDocCxP:CALNETO()
RETURN .T.

// Consultar Proveedor
FUNCTION CONCLIENTE()
  EJECUTAR("DPPROVEEDORCON",oDPDOCPROCta,oDocCxP:DOC_CODIGO)
RETURN .T.

// Muestra las Cuentas
FUNCTION SAYCTA()
  LOCAL I,nAt
  LOCAL aLine:={}

  // Hay varios Grids 10/02/2011
  oGrid:=oDocCxP:aGrids[1]

  aLine:=ACLONE(oGrid:oBrw:aArrayData[oGrid:oBrw:nArrayAt])

  //Muestra el registro en la parte superior izquierda
  //oDp:oFrameDp:SetText( oGrid:CCD_CODCTA,"oGrid:CCD_CODCTA")

  IF oDocCxP:lCtaEgr
    oDocCxP:cSayCta:=SQLGET("DPCTAEGRESO","CEG_DESCRI","CEG_CODIGO"+GetWhere("=",oGrid:CCD_CTAEGR))
  ELSE
    oDocCxP:cSayCta:=SQLGET("DPCTA"      ,"CTA_DESCRI","CTA_CODIGO"+GetWhere("=",oGrid:CCD_CODCTA))
  ENDIF

  oDocCxP:cSayCen:=SQLGET("DPCENCOS","CEN_DESCRI","CEN_CODIGO"+GetWhere("=",oGrid:CCD_CENCOS))

  oDocCxP:oSayCta:Refresh(.T.)
  oDocCxP:oSayCen:Refresh(.T.)

RETURN .T.

// Validar Documento
FUNCTION VALDOC()
RETURN .T.

FUNCTION BUILDIVA(lIva)
  LOCAL aData:={},I,nPorIva:=0,nCol
  LOCAL dFecha:=IIF( Empty(oDocCxP:DOC_FACAFE) , oDocCxP:DOC_FECHA , oDocCxP:dFchDocAfe)

  nCol:=IIF(oDocCxP:cZonaNL="N",3,5)

  FOR I=1 TO LEN(oGrid:aIva)
    nPorIva:=EJECUTAR("IVACAL",oGrid:aTipIva[I],nCol,dFecha) // oDocCxP:DOC_FECHA)
    //oDp:oFrameDp:SetText(LEFT(oGrid:aTipIva[I],2))

    IF lIva
      AADD(aData,nPorIva)
    ELSE
      AADD(aData,oGrid:aTipIva[I]+": "+ STRZERO(nPorIva,5,2))
    ENDIF
 NEXT I
RETURN aData

// Actualiza el Número del Documento ojo
FUNCTION UPDATENUMDOC()  
  LOCAL oTable,cWhere

  IF oDocCxP:DOC_NUMERO=oDocCxP:cNumDoc .AND. oDocCxP:DOC_CODIGO=oDocCxP:cCodigo
  // ? "HO HAY CAMBIOS"
    RETURN .T.
  ENDIF

  cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
          "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
          "DOC_CODIGO"+GetWhere("=",oDocCxP:cCodigo   )+" AND "+;
          "DOC_NUMERO"+GetWhere("=",oDocCxP:cNumDoc   )+" AND "+;
          "DOC_TIPTRA='D'"

  oTable:=OpenTable("SELECT DOC_NUMERO,DOC_CODIGO FROM DPDOCPRO WHERE "+cWhere,.T.)

  IF oTable:RecCount()>0
    oTable:REPLACE("DOC_NUMERO",oDocCxP:cNumDoc)
    oTable:REPLACE("DOC_CODIGO",oDocCxP:cCodigo)
    oTable:Commit(cWhere)
    oDocCxP:DOC_NUMERO:=oDocCxP:cNumDoc
    oDocCxP:DOC_CODIGO:=oDocCxP:cCodigo    
  ENDIF

  oTable:End()
RETURN .T.

FUNCTION ISALTER()
  LOCAL cNombre,cMemo,cNumero,cTipDoc

  IF !(oDocCxP:nOption=3 .OR. oDocCxP:nOption=5)
    RETURN .F.
  ENDIF

  IF !EJECUTAR("DPDOCPROISDEL",oDocCxP) // Verifica si Puede ser Modificado
     RETURN .F.
  ENDIF

/* Sustituido por lo de arriba, IF !EJECUTAR("DPDOCPROISDEL",oDocCxP), ya que permitia
 // modificar y/o eliminar Documentos contabilizados. TJ 27-06-2011
  cNombre:=ALLTRIM(oDocCxP:oTipDoc:aItems[oDocCxP:oTipDoc:nAt])

  cMemo:="Documento :"+cNombre+" "+oDocCxP:DOC_NUMERO+CRLF+;
         "No puede Modificarse debido a que tiene Pagos Registrados. Si "+CRLF+;
         "Anula los Recibos de Pago el documento estará disponible para "+CRLF+;
         "la Modificación."

  IF EJECUTAR("DPDOCPROPAGCON",oDocCxP:DOC_CODSUC,oDocCxP:DOC_TIPDOC,oDocCxP:DOC_CODIGO,oDocCxP:DOC_NUMERO,cMemo)
    RETURN .F.
  ENDIF

  IF (oDocCxP:DOC_TIPDOC="RTI" .OR. oDocCxP:DOC_TIPDOC="RET")
    cTipDoc:=SQLGET("DPDOCPRORTI","RTI_TIPDOC,RTI_NUMERO","RTI_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                                                          "RTI_DOCTIP"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                                                          "RTI_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                                                          "RTI_DOCNUM"+GetWhere("=",oDocCxP:DOC_NUMERO))

    IF !Empty(cTipDoc) 
      cNumero:=oDp:aRow[2]
      cTipDoc:=SQLGET("DPTIPDOCPRO","TDC_DESCRI","TDC_TIPO"+GetWhere("=",cTipDoc))

      MensajeErr("Documento Vinculado con "+ALLTRIM(cTipDoc)+" "+cNumero+CRLF+;
                 "No puede ser Alterado")

      RETURN .F.
    ENDIF
  ENDIF
*/

RETURN .T.

FUNCTION PRINTER()
  LOCAL oRep

  oRep:=REPORTE("DOCCXP")

  oRep:SetRango(1,oDocCxP:DOC_NUMERO,oDocCxP:DOC_NUMERO)
  oRep:SetRango(2,oDocCxP:cCodigo   ,oDocCxP:cCodigo)
  oRep:SetCriterio(2,oDocCxP:DOC_TIPDOC)

  oDp:oGenRep:aCargo:=oDocCxP:DOC_TIPDOC
RETURN .T.

// Se ejecuta desde Comprobante de Pago
FUNCTION UPDATEPAGO()
  IF oDocCxP:nOption!=1
    oDocCxP:DOC_ESTADO:=MYSQLGET("DPDOCPRO","DOC_ESTADO",oDocCxP:cWhere)
  ENDIF

  oDocCxP:oEstado:Refresh(.T.)  
RETURN .T.

FUNCTION AUTONUM()

  IF !oDocCxP:lPar_EditNum .AND. oDocCxP:nOption=1 .AND. !oDocCxP:lSaved

    oDocCxP:DOC_NUMERO:=SQLINCREMENTAL("DPDOCPRO","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                                                               "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                                                               "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                                                               "DOC_TIPTRA='D'",NIL,NIL,oDocCxP:lPar_Zero,oDocCxP:nPar_Len) // JN 29/02/2016 

    oDocCxP:oDOC_NUMERO:Refresh(.T.)

  ENDIF

RETURN .T.

// Consulta del Documento
FUNCTION VIEW()
   
// EJECUTAR("DPDOCPRO"+oDocCxP:cTipDoc+"CON",oDocCxP)
   EJECUTAR("DPDOCPROFACCON",oDocCxP)

RETURN 

FUNCTION VALPROYEC()

   IF Empty(oDocCxP:DOC_PROYEC) .OR. !ISSQLGET("DPPROYECTOS","PRY_CODIGO",oDocCxP:DOC_PROYEC)
      oDocCxP:oDOC_PROYEC:KeyBoard(VK_F6)
      RETURN .T.
   ENDIF

   oCbte:oPROYEC:Refresh(.T.)

RETURN .T.

FUNCTION PosKeyDown(nKey)
  // Ya olvide que necesitaba hacer aca... solo se que habia que hacer algo con una tecla.
  // ?? nKey
  // EJECUTAR("INSPECT",oDocCxP)
RETURN NIL

/*
// AG20080401. Filtro de fechas en browser de registros
*/
FUNCTION LIST()
  LOCAL cWhere:="",dDesde,dHasta
  LOCAL nAt:=ASCAN(oDocCxP:aBtn,{|a,n| a[7]="BROWSE"}),oBtnBrw:=IF(nAt>0,oDocCxP:aBtn[nAt,1],NIL)

  oDocCxP:cNomDoc:=ALLTRIM(oDocCxP:cNomDoc)
  
  cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+;
          " AND DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+;
          " AND DOC_TIPTRA='D' AND DOC_DOCORG='D' "

  dHasta:=SQLGETMAX(oDocCxP:cTable,"DOC_FECHA",oDocCxP:cScope)
  dDesde:=FCHINIMES(dHasta)

  IF EJECUTAR("CSRANGOFCH","DPDOCPRO",cWhere,"DOC_FECHA",dDesde,dHasta,oBtnBrw)

	cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:cCodSuc   )+;
        " AND DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+;
        " AND DOC_TIPTRA='D' AND DOC_DOCORG='D' "+;
        " AND (DOC_FECHA"+GetWhere(">=",oDp:dFchIniDoc)+;
        " AND  DOC_FECHA"+GetWhere("<=",oDp:dFchFinDoc)+")"

	oDocCxP:ListBrw(cWhere,"DPDOCPRO_FAC.BRW",oDocCxP:cNomDoc)

  ENDIF

RETURN .T.

FUNCTION SETTERCEROS()

  SETFOLDER(4)

  EJECUTAR("DPDOCCXPCPT",oDocCxP)

RETURN .T.

FUNCTION VCCD_PORIVA()

  // Copia el Valor
  oGrid:nPorIva  := oGrid:CCD_PORIVA
  oGrid:cTipIva  := oGrid:CCD_TIPIVA

RETURN .T.

/*
//
*/
FUNCTION RUNWHEN()
  LOCAL aControl:={oDocCxP:oDOC_NUMERO,oDocCxP:oDOC_NUMFIS,oDocCxP:oDOC_FECHA,oDocCxP:oDOC_FCHDEC}

  AEVAL(aControl,{|o| o:ForWhen(.T.)})

RETURN .T.

FUNCTION BUILDIVACOD()
   LOCAL aIva:=ACLONE(oGrid:BuildIva(.F.))

   AEVAL(aIva,{|a,n,nAt| nAt:=AT(":",a), aIva[n]:=LEFT(a,nAt-1) })

RETURN aIva

FUNCTION VCCD_TIPIVA(cTipIva)
  LOCAL aIva   :=oGrid:BUILDIVA(.T.)
  LOCAL aTipIva:=oGrid:BUILDIVA(.F.)
  LOCAL nAt

  oGrid:SET("CD_TIPIVA",cTipIva,.T.)

  nAt:=MAX(ASCAN(aTipIva,{|a,n| oGrid:CCD_TIPIVA=LEFT(a,2)}),1)

  IF nAt>0
    oGrid:SET("CCD_PORIVA",aIva[nAt],.T.)
  ELSE
    oGrid:SET("CCD_PORIVA",0        ,.T.)
  ENDIF

  oGrid:CCD_TOTAL :=oGrid:CCD_MONTO+(oGrid:CCD_MONTO*(oGrid:CCD_PORIVA/100))
  oGrid:Set("CCD_TOTAL",oGrid:CCD_TOTAL,.T.)

  oGrid:nPorIva  := oGrid:CCD_PORIVA
  oGrid:cTipIva  := oGrid:CCD_TIPIVA

RETURN .T.
/*
// Asigna en el grid la Ultima Cuenta, Descripción e IVA
*/
FUNCTION ASG_ULT_CTA()
  LOCAL cWhere:="DOC_CODSUC"+GetWhere("=",oDocCxP:cCodSuc   )+" AND "+;
                "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                "DOC_TIPTRA"+GetWhere("=","D")               +" AND "+;
                "DOC_DOCORG"+GetWhere("=","D")

  LOCAL cCodCta,cCtaEgr,cDescri,cTipIva:="",cCenCos,nMonto:=0
  LOCAL oCol,nAt
  LOCAL oGrid  :=oDocCxP:aGrids[1]
  // Ultima Factura
  LOCAL cUltDoc:=IF(Empty(oDocCxP:cUltDoc),SQLGET("DPDOCPRO","DOC_NUMERO",;
                 " WHERE "+cWhere+;
                 " ORDER BY CONCAT(DOC_FECHA,DOC_HORA) DESC LIMIT 1 "),oDocCxP:cUltDoc)
  LOCAL aCodCta:={oDp:cCtaIndef}

  oDocCxP:cUltDoc:=cUltDoc

//? cUltDoc,"cUltDoc"

  AEVAL(oGrid:oBrw:aArrayData,{|a,n| IF(!Empty(a[1]),AADD(aCodCta,a[1]),NIL)})

  cWhere:="CCD_CODSUC"+GetWhere("=",oDocCxP:cCodSuc   )+" AND "+;
          "CCD_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
          "CCD_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
          "CCD_NUMERO"+GetWhere("=",cUltDoc)


  IF !Empty(aCodCta) .AND. oDocCxP:lCtaEgr
     cWhere:=cWhere + " AND NOT "+GetWhereOr("CCD_CODCTA",aCodCta)
  ENDIF
 

  IF !Empty(aCodCta) .AND. !oDocCxP:lCtaEgr
     cWhere:=cWhere + " AND NOT "+GetWhereOr("CCD_CODCTA",aCodCta)
  ENDIF

//? cCodCta,"OJO no ubico la incidencia"

  cCodCta:=SQLGET("DPDOCPROCTA","CCD_CODCTA,CCD_CTAEGR,CCD_CENCOS,CCD_DESCRI,CCD_MONTO,CCD_TIPIVA,DOC_FECHA",;
                      " INNER JOIN DPDOCPRO ON CCD_CODSUC=DOC_CODSUC AND CCD_CODIGO=DOC_CODIGO AND CCD_NUMERO=DOC_NUMERO "+;
                      " WHERE "+cWhere+;
                      " ORDER BY CCD_ITEM LIMIT 1 ")

  IF Empty(cCodCta) .AND. !Empty(oGrid:CCD_DESCRI)
     RETURN .F.
  ENDIF

  cCtaEgr:=DPSQLROW(2)
  cCenCos:=DPSQLROW(3)
  cDescri:=PADR(DPSQLROW(4),250)
  nMonto :=DPSQLROW(5)
  cTipIva:=DPSQLROW(6)

  IF oDocCxP:lCtaEgr
    oGrid:Set("CCD_CTAEGR",cCtaEgr,.T.)
  ELSE
    oGrid:Set("CCD_CODCTA",cCodCta,.T.)
  ENDIF

  oGrid:Set("CCD_CENCOS",cCenCos,.T.)
  oGrid:Set("CCD_DESCRI",cDescri,.T.)
  oGrid:Set("CCD_TIPIVA",cTipIva,.T.)
  oGrid:Set("CCD_MONTO" ,nMonto ,.T.)


RETURN NIL

FUNCTION LBXPROVEEDOR()
   LOCAL cWhere:="(PRO_SITUAC='A' OR PRO_SITUAC='C') AND "+oDocCxP:cWherePro
   LOCAL cTitle

   IF oDocCxP:nOption=5

      IF ISDPSTD()
        IniGetLbx(GETFILESTD(oDocCxp:cFileLbx))
      ELSE
        IniGetLbx(MEMOREAD(oDocCxp:cFileLbx))
      ENDIF

      cTitle  :=ALLTRIM(GetFromVar(GetLbx("TITLE"))) +" [ Sólo con Documentos] "

      IF ISRELEASE("16.08")

        cWhere:=" INNER JOIN DPDOCPRO ON PRO_CODIGO=DOC_CODIGO AND "+oDocCxP:cScope+;
                " WHERE "+cWhere

      ENDIF

   ENDIF

   oDpLbx:=DpLbx(oDocCxp:cFileLbx,cTitle,cWhere,NIL,NIL,NIL,NIL,NIL,NIL,oDocCxP:oDOC_CODIGO)
   oDpLbx:GetValue("PRO_CODIGO",oDocCxP:oDOC_CODIGO)

RETURN .T.

/*
// Evitar incidencias por falta de binario 10/10/2016
*/
FUNCTION RECCOUNT()
RETURN .T.

FUNCTION BRWXPRO()
RETURN EJECUTAR("BRWXPRO",oDocCxP)

FUNCTION BRWXTIP()
RETURN EJECUTAR("BRWXTIP",oDocCxP)

FUNCTION BRWXCTAE()
RETURN EJECUTAR("BRWXCXPCTAEGRESO",oDocCxP)

FUNCTION BRWXCTA()
RETURN EJECUTAR("BRWXCXPCTA",oDocCxP)




/*
// Cierra el formulario y guardará el Ancho de la Columna
*/
FUNCTION ONCLOSE()
  LOCAL cAdd :="" // LSTR(LEN(oDocCxP:oBrwD:aCols))+"_"+LSTR(LEN(oDocCxP:oBrw:aCols))
  LOCAL cFile:="MYFORMS\"+cFileNoExt(oDocCxP:cFileEdit)+cAdd+".BRWX"
  LOCAL oIni

  DEFAULT oDocCxP:lStart:=.T.

  IF oDocCxP:lStart
     RETURN .T.
  ENDIF

  ferase(cFile)

  INI oIni File (cFile)

  oDocCxP:oWnd:CoorsUpdate()

  oIni:Set( "cAlias", "nWidth"    , oDocCxP:oWnd:nWidth()   )
  oIni:Set( "cAlias", "nHeight"   , oDocCxP:oWnd:nHeight()  )

RETURN .T.


/*
// Restaurar Tamaño de las Columnas del Browse
*/
FUNCTION CXPRESTBRW()
RETURN EJECUTAR("CXPRESTBRW",oDocCxP)

// EOF
