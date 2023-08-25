// Programa   : DPDOCCXPCPT
// Fecha/Hora : 25/07/23O008 14:41:06
// Propósito  : Documentos de Terceros
// Creado Por : Juan Navas
// Llamado por: DPDOCPRO
// Aplicación : Cuentas po Pagar
// Tabla      : DPDOCPRO

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oDoc)
  LOCAL cSql,oGrid,oCol

  IF oDoc=NIL
     RETURN NIL
  ENDIF

  cSql :=" SELECT "+SELECTFROM("DPDOCPRO"   ,.F.)+;
         " ,      "+SELECTFROM("DPDOCPROCTA",.F.)+;
         " ,DPPROVEEDOR.PRO_NOMBRE "+;
         " FROM DPDOCPRO "+;
         " INNER JOIN DPPROVEEDOR ON PRO_CODIGO=DOC_CODIGO"+;
         " INNER JOIN DPDOCPROCTA ON DOC_CODSUC=CCD_CODSUC AND DOC_TIPDOC=CCD_TIPDOC AND "+;
         "                           DOC_CODIGO=CCD_CODIGO AND DOC_NUMERO=CCD_NUMERO AND "+;
         "                           CCD_ITEM='0001' AND DOC_TIPTRA='D' "

  oGrid:=oDocCxP:GridEdit( "DPDOCPRO" ,"DOC_CODSUC,DOC_TIPDOC,DOC_CODIGO,DOC_NUMERO","DOC_CODSUC,DOC_CXPTIP,DOC_CXPCOD,DOC_CXPDOC", cSql , "DOC_ACT=1" ) 

  oGrid:cScript  :="DPDOCCXPCPT"
  oGrid:aSize    :={0,0,IIF(Empty(oDp:cModeVideo),765,905),IIF(Empty(oDp:cModeVideo),185,285)}
  oGrid:oFont    :=oFontGrid
  oGrid:bValid   :=".T."
  oGrid:lBar     :=.F.
  oGrid:oDlg     :=oDocCxP:oFolder:aDialogs[4]
  oGrid:aIva     :=ACLONE(oDocCxP:aGrids[1]:aIva)
  oGrid:aTipIva  :=ACLONE(oDocCxP:aGrids[1]:aTipIva)
  oGrid:cScope   :=' DOC_DOCORG="T" '
  oGrid:DOC_CODIGO:=""

  oGrid:lTotal   :=.T.
  oGrid:oFontH   :=oFontGrid
  oGrid:oFontB   :=oFontGrid

  oGrid:cPostSave  :="GRIDPOSTSAVE"
  oGrid:cPreSave   :="GRIDPRESAVE"
  oGrid:cPreDelete :="GRIDPREDELETE"
  oGrid:cPostDelete:="GRIDPOSTDELETE" 
  oGrid:cItem      :="DOC_PAGNUM" 
//oGrid:bChange    :={||oDocCxP:SAYCTA()}
  oGrid:bWhen      :={||!Empty(oDocCxP:DOC_CODIGO) .AND. !Empty(oDocCxP:DOC_NUMERO)}
  oGrid:aActivo    :={}  // {"CODIGO","DESCRI","GRUPO","UBICACION","NUMMEMO"} // Datos del Activo
  oGrid:aCargo     :={}  // Contiene los Gastos del Reintegro
  oGrid:aCajMov    :={}  // Movimiento de Caja
  oGrid:lGetRowData:=.F. // Obtiene los Datos desde PostSave
  oGrid:cLoad    :="GRIDLOAD"
  oGrid:cTotal   :="GRIDTOTAL" 
  oGrid:SetMemo("DOC_NUMMEM","Descripción Amplia",1,1,100,200)

  oGrid:nClrPane1   :=15006969
  oGrid:nClrPane2   :=14678271

  oGrid:nClrPaneH   := 11856126
  oGrid:nClrTextH   := CLR_BLACK

  oGrid:nClrPaneF   := 11856126
  oGrid:nClrTextF   := CLR_BLACK

  oGrid:nRecSelColor:= 11856126
//oGrid:SetScope("DOC_ACT=1")
  oGrid:cDeleteUpdate:="DOC_ACT=0" 


  oGrid:AddBtn("facturacompra.bmp","Complemento del Documento","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [oGrid:DPDOCPROCTA()],"IMP")

/*
  oGrid:AddBtn("facturacompra.bmp","Registro de Compra","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [EJECUTAR("DPDOCPROREIN",oGrid)],"REM")

  oGrid:AddBtn("PROVEEDORPROG.BMP","Referencia de Planificación","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [EJECUTAR("DPDOCPROPROG",oGrid)],"PRO")


  oGrid:AddBtn("instrumentosdecaja.BMP","Ingreso hacia Caja","oGrid:nOption=1 .OR. oGrid:nOption=3 ",;
                [EJECUTAR("DPDOCPROCAJA",oGrid)],"PRO")

*/

  oCol:=oGrid:AddCol("DOC_CODIGO","cCodPro")
  oCol:cTitle   :=oDp:xDPPROVEEDOR
  oCol:bValid   :={||oGrid:DOCCODIGO()}
  oCol:cMsgValid:=oDp:xDPPROVEEDOR+" no Existe"
  oCol:cListBox :="DPPROVEEDOR.LBX"
  oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),90,110)
  oCol:nEditType:=EDIT_GET_BUTTON
  oCol:cWhereListBox:='"PRO_CODIGO"+GetWhere("<>",oDocCxP:DOC_CODIGO)'

  oCol:=oGrid:AddCol("PRO_NOMBRE") // ,"cNombre")
  oCol:cTitle   :="Nombre de "+oDp:xDPPROVEEDOR
  oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),90,210)
  oCol:nEditType:=0
  oCol:bWhen    :={||.F.}
  oCol:bCalc :={||SQLGET("DPPROVEEDOR","PRO_NOMBRE","PRO_CODIGO"+GetWhere("=",oGrid:cCodPro))}

  oCol:=oGrid:AddCol("DOC_TIPDOC","cTipDoc")
  oCol:cTitle   :="Tipo"
  oCol:bValid   :={||oGrid:DOCTIPDOC()}
  oCol:cMsgValid:="Tipo de Documento no Existe"
  oCol:cListBox :="DPTIPDOCPRO.LBX"
  oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),40,65)
  oCol:nEditType:=EDIT_GET_BUTTON

  oCol:cWhereListBox:="TDC_CXP<>'N'"
  oCol:=oGrid:AddCol("DOC_NUMERO","cNumero")
  oCol:cTitle   :="Número"
  oCol:bValid   :={||oGrid:DOCNUMERO()}
  oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),90,105)
  oCol:lZero    :=.T.

  IF oDocCxP:lCtaEgr 
    // Renglon Cuenta de Egreso
    oCol:=oGrid:AddCol("CCD_CTAEGR")
    oCol:cTitle   :=oDp:xDPCTAEGRESO
    oCol:bValid   :={||oGrid:VCCD_CTAEGR(oGrid:CCD_CTAEGR)}
    oCol:cMsgValid:="Cuenta de Egreso no Existe"
    oCol:cListBox :="DPCTAEGRESO.LBX"
  ELSE
    // Renglon Cuenta Contable
    oCol:=oGrid:AddCol("CCD_CODCTA")
    oCol:cTitle   :=oDp:xDPCTA
    oCol:bValid   :={||oGrid:VCCD_CODCTA(oGrid:CCD_CODCTA)}
    oCol:cMsgValid:="Cuenta Contable no Existe"
    oCol:cListBox :="DPCTAACT.LBX"
  ENDIF

  oCol:nEditType:=EDIT_GET_BUTTON
  oCol:nWidth   :=IIF(Empty(oDp:cModeVideo),130,150)

 // Renglon Monto Base
  oCol:=oGrid:AddCol("CCD_MONTO")
  oCol:cTitle:="Monto Base"
  oCol:nWidth:=IIF(Empty(oDp:cModeVideo),130,130)
  oCol:cPicture:="99,999,999,999.99"
  oCol:lTotal:=.T.
  oCol:bValid:={||oGrid:VCCD_MONTO(oGrid:CCD_MONTO)}
  oCol:lTotal:=.T.

  // Renglon % IVA
  oCol:=oGrid:AddCol("CCD_PORIVA")
  oCol:cTitle    :="% IVA"
  oCol:nWidth    :=IIF(Empty(oDp:cModeVideo),70,80)
  oCol:aItems    :={||oDocCxP:BuildIva(.F.)}
  oCol:aItemsData:={||oDocCxP:BuildIva(.T.)}
  oCol:lRepeat   :=.T.
  oCol:cPicture :="99.99"

//oCol:bWhen     :="oGrid:CCD_LIBCOM"


RETURN

// Carga para Incluir o Modificar en el Grid
FUNCTION GRIDLOAD()

   oGrid:cWhere2:=""
   oGrid:cWhere3:=""
 
   IF oGrid:nOption=1

      oGrid:SET("DOC_TIPDOC" , "FAC"              , .T. )
      oGrid:SET("DOC_FECHA"  , oDocCxP:DOC_FECHA  , NIL )
      oGrid:SET("DOC_FCHVEN" , oDocCxP:DOC_FCHVEN , NIL )
      oGrid:SET("DOC_CENCOS" , oDp:cCenCos        , NIL )
      oGrid:SET("DOC_HORA"   , TIME()             , NIL )
      oGrid:SET("DOC_DOCORG" , "T"                , NIL )

   ELSE

      oGrid:cWhere2:=" WHERE "+;
                     "CCD_CODSUC"+GetWhere("=",oGrid:DOC_CODSUC)+" AND "+;
                     "CCD_TIPDOC"+GetWhere("=",oGrid:DOC_TIPDOC)+" AND "+;
                     "CCD_CODIGO"+GetWhere("=",oGrid:DOC_CODIGO)+" AND "+;
                     "CCD_NUMERO"+GetWhere("=",oGrid:DOC_NUMERO)

      oGrid:cWhere3:=" WHERE "+;
                     "DOC_CODSUC"+GetWhere("=",oGrid:DOC_CODSUC)+" AND "+;
                     "DOC_TIPDOC"+GetWhere("=",oGrid:DOC_TIPDOC)+" AND "+;
                     "DOC_CODIGO"+GetWhere("=",oGrid:DOC_CODIGO)+" AND "+;
                     "DOC_NUMERO"+GetWhere("=",oGrid:DOC_NUMERO)+" AND DOC_TIPTRA='T'"

   ENDIF

RETURN NIL

/*
// Pregrabar
*/
FUNCTION GRIDPRESAVE()
  LOCAL nTotal:=0,cItem
  LOCAL cCxP:=SQLGET("DPTIPDOCPRO","TDC_CXP","TDC_TIPO"+GetWhere("=",oGrid:cTipDoc))

  nTotal:=oGrid:CCD_MONTO+PORCEN(oGrid:CCD_MONTO,oGrid:CCD_PORIVA)
  cItem :=STRZERO(LEN(oGrid:oBrw:aArrayData),6)

  oGrid:SET("DOC_NETO"   , nTotal                        )
  oGrid:SET("DOC_TIPTRA" , "D"                           )
  oGrid:SET("DOC_PAGNUM" , STRZERO(1,6)                  )
  oGrid:SET("DOC_ACT"    , 1                             )
  oGrid:SET("DOC_PAGNUM" , cItem                         )
  oGrid:SET("DOC_ESTADO" , "PA"                          )
  oGrid:SET("DOC_CXP"    , IIF(cCxP="D", 1,oGrid:DOC_CXP))
  oGrid:SET("DOC_CXP"    , IIF(cCxP="H",-1,oGrid:DOC_CXP))
  oGrid:SET("DOC_DOCPRG" , "T"                           )

// ? oGrid:DOC_PAGNUM,"DEBE SER AUTOMATICO"

RETURN .T.

/*
// Ejecución despues de Grabar el Item
*/
FUNCTION GRIDPOSTSAVE()
  LOCAL oTable,cWhere:=oGrid:cWhere2,cCodCta
  LOCAL nAt
  LOCAL aIva   :=oDocCxP:BUILDIVA(.T.)
  LOCAL aTipIva:=oDocCxP:BUILDIVA(.F.)
  LOCAL aCampos:={}

  nAt:=MAX(ASCAN(aIva,oGrid:CCD_PORIVA),1)

  oTable:=OpenTable("SELECT * FROM DPDOCPROCTA "+cWhere , !Empty(cWhere) )
 
  IF oTable:RecCount()=0
    oTable:Append()
  ENDIF

  oTable:Replace("CCD_CODSUC" , oDocCxP:DOC_CODSUC )
  oTable:Replace("CCD_TIPDOC" , oGrid:cTipDoc      )
  oTable:Replace("CCD_CODIGO" , oGrid:cCodPro      )
  oTable:Replace("CCD_NUMERO" , oGrid:DOC_NUMERO   )
  oTable:Replace("CCD_MONTO"  , oGrid:CCD_MONTO    )
  oTable:Replace("CCD_ITEM"   , "0001"             )
  oTable:Replace("CCD_TIPTRA" , "D"                )
  oTable:Replace("CCD_TIPIVA" , LEFT(aTipIva[nAt],2))
  oTable:Replace("CCD_CENCOS" , oDp:cCenCos         )
  oTable:Replace("CCD_ACT"    , 1                   )
  oTable:Replace("CCD_PORIVA" , oGrid:CCD_PORIVA    )
  oTable:Replace("CCD_TOTAL"  , oGrid:DOC_NETO      )

  IF oDocCxP:lCtaEgr 
    oTable:Replace("CCD_CTAEGR",oGrid:CCD_CTAEGR)
  ELSE
    oTable:Replace("CCD_CODCTA",oGrid:CCD_CODCTA)
  ENDIF

  IF !oDocCxP:lCtaEgr
    oTable:Replace("CCD_CTAEGR",EJECUTAR("DPCTAEGRESOCREA",oGrid:CCD_CODCTA,.T.))
  ELSE
    oTable:Replace("CCD_CODCTA",SQLGET("DPCTAEGRESO","CEG_CUENTA","CEG_CODIGO"+GetWhere("=",oGrid:CCD_CTAEGR)))
  ENDIF

  oTable:Commit(cWhere)
  oTable:End()

  // Aqui debo Generar el Documento Contrario para el Balance de la CxP
  oTable:=OpenTable("SELECT * FROM DPDOCPRO "+oGrid:cWhere3, !Empty(oGrid:cWhere3) )
  AEVAL(oTable:aFields,{|a,n| oTable:FieldPut(n,oGrid:Get(a[1]))})
  oTable:Replace("DOC_TIPTRA" , "T"               )
  oTable:Replace("DOC_CXP"    , oTable:DOC_CXP*-1 )
  oTable:Commit(oGrid:cWhere3)


RETURN .T.

// Genera los Totales por Grid
FUNCTION GRIDTOTAL()

  oDocCxP:DOC_NETO:=SQLGET("DPDOCPRO","SUM(DOC_NETO*DOC_CXP)","DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                                                              "DOC_CXPTIP"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                                                              "DOC_CXPCOD"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                                                              "DOC_CXPDOC"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND DOC_TIPTRA='D'")

  oDocCxP:DOC_BASNET := oDocCxP:DOC_NETO
  oDocCxP:DOC_MTOIVA :=0

  oDocCxP:CALNETO()
/*
  IF oDocCxP:nOption<>0

     SQLUPDATE("DPDOCPRO","DOC_NETO"      ,;
                          oDocCxP:DOC_NETO,;
                          "DOC_CODSUC"+GetWhere("=",oDocCxP:DOC_CODSUC)+" AND "+;
                          "DOC_TIPDOC"+GetWhere("=",oDocCxP:DOC_TIPDOC)+" AND "+;
                          "DOC_CODIGO"+GetWhere("=",oDocCxP:DOC_CODIGO)+" AND "+;
                          "DOC_NUMERO"+GetWhere("=",oDocCxP:DOC_NUMERO)+" AND "+;
                          "DOC_TIPTRA='D'")

    MensajeErr(CLPCOPY(oDp:cSql))

  ENDIF
*/
RETURN .T.

FUNCTION DOCCODIGO()

  IF Empty(oGrid:cCodPro)
     RETURN .F.
  ENDIF

  IF oGrid:cCodPro=oDocCxP:DOC_CODIGO
     MensajeErr(oDp:xDPPROVEEDOR+" ["+oGrid:cCodPro+"] debe ser Diferente ")
     RETURN .F.
  ENDIF

  oGrid:GetCol("PRO_NOMBRE"):RunCalc()

RETURN .T.

/*
// Tipo de Documento 
*/
FUNCTION DOCTIPDOC()

  IF Empty(oGrid:cTipDoc)
     RETURN .F.
  ENDIF

  IF !ISSQLGET("DPTIPDOCPRO","TDC_TIPO",oGrid:cTipDoc , NIL , "TDC_CXP<>'N'" )
     MensajeErr(oDp:xDPTIPDOCPRO+" ["+oGrid:cTipDoc+"] no Existe o no Afecta CXP ")
     RETURN .F.
  ENDIF

RETURN .T.

FUNCTION DOCNUMERO()
RETURN .T.

FUNCTION VCCD_MONTO()
RETURN .T.

FUNCTION SAYCTA()
RETURN .T.

/*
// Complemento del Documento
*/
FUNCTION DPDOCPROCTA()
   
   DEFINE DIALOG oDp:oDlg TITLE "Datos Complementarios del Documento";
          SIZE 300,200

   @ 1,1 SAY "Nro de Control:" RIGHT
   @ 2,1 SAY "Descripción   :" RIGHT
   @ 3,1 SAY "Exonerado     :" RIGHT
 
   ACTIVATE DIALOG oDp:oDlg CENTERED 

RETURN .T.

/*
// Valida Cuenta Contable
*/
FUNCTION VCCD_CODCTA(cCodCta)
  LOCAL lResp:=.F.

  IF !ALLTRIM(SQLGET("DPCTA","CTA_CODIGO","CTA_CODIGO"+GetWhere("=",cCodCta)))==ALLTRIM(cCodCta)
    RETURN .F.
  ENDIF

  IF !EJECUTAR("ISCTADET",cCodCta , .F. )
    oGrid:GetCol("CCD_CODCTA"):MensajeErr("Cuenta no Acepta Asientos")
    RETURN .F.
  ENDIF

  oDocCxP:SAYCTA()

  EJECUTAR("DPDOCPROPROG",oGrid,.T.)

RETURN .T.
/*
// Valida Código de Retención
*/
FUNCTION VCCD_CTAEGR(cCodCta)
  LOCAL lResp:=.F.
  LOCAL lResp:=.F.,cCuenta:=""
  LOCAL cTipIva:=""

? "aqui es,VCCD_CTAEGR"

  IF !ALLTRIM(SQLGET("DPCTAEGRESO","CEG_CODIGO,CEG_CUENTA,CEG_TIPIVA","CEG_CODIGO"+GetWhere("=",cCodCta)))==ALLTRIM(cCodCta)
    RETURN .F.
  ENDIF
  // ag dp
  cCuenta:=DPSQLROW(2) 
  cTipIva:=DPSQLROW(3) 

//  IF !ALLTRIM(SQLGET("DPCTAEGRESO","CEG_CODIGO","CEG_CODIGO"+GetWhere("=",cCodCta)))==ALLTRIM(cCodCta)
//    RETURN .F.
//  ENDIF

RETURN .T.

FUNCTION GRIDPREDELETE()
RETURN .T.

FUNCTION GRIDPOSTDELETE()
RETURN .T.



// EOF


