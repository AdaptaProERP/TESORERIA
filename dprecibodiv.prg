// Programa   : DPRECIBODIV
// Fecha/Hora : 13/06/2017 15:04:37
// Propósito  : Crear Recibos de Ingreso desde CxC en Divisas, utilización multi-divisa y calculo del IGTF
// Creado Por : Automáticamente por BRWMAKER
// Llamado por: <DPXBASE>
// Aplicación : Gerencia 
// Tabla      : <TABLA>

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodigo,cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle,cTableA,cRif,nValCam,lAnticipo,oFrmLnk,cLetra,lPagoC,aTipDoc,cTipDes,lCruce,lCliente,nMtoDiv)
   LOCAL aData,aFechas,cFileMem:="USER\BRPLANTILLADOC.MEM",V_nPeriodo:=4,cCodPar
   LOCAL V_dDesde:=CTOD(""),V_dHasta:=CTOD("")
   LOCAL cServer:=oDp:cRunServer,aVars:={}
   LOCAL lConectar:=.F.,cSql,aDataD,aDataR:={}
   LOCAL nColIsMon:=14-1

   oDp:cRunServer:=NIL

   DEFAULT cRif     :=SQLGET("DPBCOCTAREGCON","ECB_RIF,ECB_VALCAM","ECB_RIF"+GetWhere("<>","")+" AND ECB_TIPREL"+GetWhere("=","Cliente")),;
           nValCam  :=DPSQLROW(2,0),;
           lAnticipo:=.F.,;
           cLetra   :="0",;
           lPagoC   :=.F.,;
           cTipDes  :="FAV",;
           lCruce   :=.F.  ,;
           lCliente :=.T.  ,;
           cCodSuc  :=oDp:cSucursal,;
           nMtoDiv  :=0

   // Sitio donde obtiene los datos del cliente
   DEFAULT oDp:cRunData:=oDp:cDsnData 

   // cTipDes="TIK" // documento destino, caso de punto de venta Mostrador

   // lPagoC=Pago Central

   IF ISPCPRG() .AND. .F.
      aTipDoc:={"PED"}
      lPagoC :=.T.
   ENDIF

   // cTipDoc  :=IF(LEN(aTipDoc)>0,cTipDoc,cTipDoc)
  
   IF cTipDes="OPA"
      lCliente :=.F.
      lAnticipo:=.F.
   ENDIF

   IF cTipDes="OIN"
      lCliente :=.T.
      lAnticipo:=.F.
   ENDIF

   EJECUTAR("DPRECIBOSDIVINST")


   // DEFAULT cCodigo:="A-243"

   DEFAULT cCodigo:=SQLGET(IF(lCliente,"VIEW_DOCCLICXCDIV","VIEW_DOCPROCXPDIV"),"CXD_CODIGO")

   IF !Empty(cServer)

     MsgRun("Conectando con Servidor "+cServer+" ["+ALLTRIM(SQLGET("DPSERVERBD","SBD_DOMINI","SBD_CODIGO"+GetWhere("=",cServer)))+"]",;
            "Por Favor Espere",{||lConectar:=EJECUTAR("DPSERVERDBOPEN",cServer)})

     IF !lConectar
        RETURN .F.
     ENDIF

   ENDIF 

   IF Type("oRecDiv")="O" .AND. oRecDiv:oWnd:hWnd>0
      EJECUTAR("BRRUNNEW",oRecDiv,GetScript())
      RETURN oRecDiv
   ENDIF

   cTitle:=IF(lCliente,"Recibos de Ingresos CxC en Divisas ","Comprobante de Pago de CxP en Divisas")+IF(Empty(cTitle),"",cTitle)

   oDp:oFrm:=NIL

   DEFAULT cCodSuc :=oDp:cSucursal,;
           nPeriodo:=4,;
           dDesde  :=CTOD(""),;
           dHasta  :=CTOD(""),;
           cWhere  :="",;
           cTableA :="DPAUDELIMODCNF"	

   aData:=TIPCAJBCO	(NIL,cRif,nValCam,NIL,nColIsMon,lCliente)

   cSql :=oDp:cWhere

   IF Empty(aData)
      MensajeErr("no hay Instrumentos de Caja y Bancos Activos  para "+cTitle,"Información no Encontrada")
      RETURN .F.
   ENDIF

   IF lCliente
     // aDataD:=LEERDOCCLI(cCodigo,aTipDoc,NIL,lAnticipo,lPagoC)
     aDataD:=EJECUTAR("DPRECIBODIV_DOCCLI",cCodigo,aTipDoc,NIL,lAnticipo,lPagoC,NIL,oDp:cRunData)
   ELSE
     aDataD:=EJECUTAR("DPRECIBODIV_DOCPRO",cCodigo,aTipDoc,NIL,lAnticipo,lPagoC,NIL,oDp:cRunData)
   ENDIF

   // AADD(aDataR,{"USD","Dolares"          ,0 ,0  ,0,0})
   ViewData(aData,cTitle,oDp:cWhere,aDataD)

   oDp:oFrm:=oRecDiv
            
RETURN .T. 

FUNCTION ViewData(aData,cTitle,cWhere_,aDataD)
   LOCAL oBrw,oCol,aTotal:=ATOTALES(aData)
   LOCAL oFont,oFontB,oFontBrw
   LOCAL aPeriodos :=ACLONE(oDp:aPeriodos)
   LOCAL aCoors    :=GetCoors( GetDesktopWindow() )
   LOCAL lCuotasPrg:=COUNT("DPCLIENTEPROG","DPG_CODIGO"+GetWhere("=",cCodigo))>0


   DEFINE FONT oFont    NAME "Tahoma" SIZE 0, -10 
   DEFINE FONT oFontB   NAME "Tahoma" SIZE 0, -10 BOLD
   DEFINE FONT oFontBrw NAME "Tahoma" SIZE 0, -10 BOLD

   DpMdi(cTitle,"oRecDiv","DPRECIBOSDIV.EDT")

   // oRecDiv:Windows(0,0,600,1010,.T.) // Maximizado

   oRecDiv:Windows(0,0,aCoors[3]-160,aCoors[4]-10,.T.) // Maximizado

   oRecDiv:lMsgBar   :=.F.
   oRecDiv:cPeriodo  :=aPeriodos[nPeriodo]
   oRecDiv:cCodSuc   :=cCodSuc
   oRecDiv:nPeriodo  :=nPeriodo
   oRecDiv:cNombre   :=""
   oRecDiv:dDesde    :=dDesde
   oRecDiv:cServer   :=cServer
   oRecDiv:dHasta    :=dHasta
   oRecDiv:dFecha    :=oDp:dFecha
   oRecDiv:dFchReg   :=oDp:dFecha // Fecha de Transacción
   oRecDiv:lPagoC    :=lPagoC     // Pago Centralizado
   oRecDiv:lPagEle   :=.F.
   oRecDiv:bAfterSave:=NIL

   // Para asociarlo con los Pedidos
   oRecDiv:REC_TIPORG:=""
   oRecDiv:REC_NUMORG:=""

   
   

   oRecDiv:cHora     :=oDp:cHora
   oRecDiv:cWhere    :=cWhere
   oRecDiv:cWhere_   :=cWhere_
   oRecDiv:cWhereQry :=""
   oRecDiv:cSql      :=oDp:cSql
   oRecDiv:oWhere    :=TWHERE():New(oRecDiv)
   oRecDiv:cCodPar   :=cCodPar // Código del Parámetro
   oRecDiv:lWhen     :=.T.
   oRecDiv:cTextTit  :="" // Texto del Titulo Heredado
   oRecDiv:oDb       :=oDp:oDb
   oRecDiv:cBrwCod   :=""
   oRecDiv:lTmdi     :=.T.
   oRecDiv:cWhereCli :=""
   oRecDiv:cTitleCli :=NIL
   oRecDiv:cCodigo   :=cCodigo
   oRecDiv:lCodigo   :=Empty(oRecDiv:cCodigo)
   oRecDiv:cCodCaja  :=oDp:cCodCaja  
   oRecDiv:lCuotasPrg:=lCuotasPrg
   oRecDiv:cMemo     :=""
   oRecDiv:cTableA   :=cTableA
   oRecDiv:cRif      :=cRif
   oRecDiv:cCodigo   :=cCodigo
   oRecDiv:cRunData  :=oDp:cRunData
   oRecDiv:lDb       :=!(oRecDiv:cRunData=oDp:cDsnData)
   oRecDiv:oDb       :=OpenOdbc(oRecDiv:cRunData)
   oRecDiv:oCenCos   :=NIL
   oRecDiv:oCodVen   :=NIL
   oRecDiv:oFrmDoc   :=NIL

   IF lCliente
     oRecDiv:cCodVen   :=SQLGET("DPCLIENTES","CLI_CODVEN,CLI_CODMON,CLI_NOMBRE,CLI_RIF","CLI_CODIGO"+GetWhere("=",oRecDiv:cCodigo),NIL,oRecDiv:oDb)
     oRecDiv:cCodMon   :=DPSQLROW(2,oDp:cMonedaExt)
     oRecDiv:cNomCli   :=DPSQLROW(3,"")
     oRecDiv:cNomVen   :=SQLGET("DPVENDEDOR","VEN_NOMBRE","VEN_CODIGO"+GetWhere("=",oRecDiv:cCodVen)) 
   ELSE
     oRecDiv:cCodVen   :=SQLGET("DPPROVEEDOR","SPACE(1),PRO_CODMON,PRO_NOMBRE,PRO_RIF","PRO_CODIGO"+GetWhere("=",oRecDiv:cCodigo),NIL,oRecDiv:oDb)
     oRecDiv:cCodMon   :=DPSQLROW(2,oDp:cMonedaExt)
     oRecDiv:cNomCli   :=DPSQLROW(3,"")
     oRecDiv:cNomVen   :=""
   ENDIF

   oRecDiv:cCodMon:=IF(Empty(oRecDiv:cCodMon),oDp:cMonedaExt,oRecDiv:cCodMon)
 
   oRecDiv:nValCam   :=EJECUTAR("DPGETVALCAM",oRecDiv:cCodMon,oRecDiv:dFecha) // nValCam
   oRecDiv:oFrmLnk   :=oFrmLnk // Vinculo con Formulario
   oRecDiv:nMtoDoc   :=0
   oRecDiv:nMtoIGTF  :=0
   oRecDiv:oBrw      :=NIL
   oRecDiv:oBrwD     :=NIL
   oRecDiv:oBrwR     :=NIL
   oRecDiv:nClrText  :=0
   oRecDiv:nClrPane1 :=16774120
   oRecDiv:nClrPane2 :=16771538
   oRecDiv:nClrText1 :=6208256
   oRecDiv:nClrText2 :=16751157  // CLR_HRED // 8667648
   oRecDiv:nClrText3 :=32768
   oRecDiv:nClrText4 :=10440704
   oRecDiv:oBrwFocus :=NIL
   oRecDiv:cLetra    :=cLetra
   oRecDiv:cLetraDes :="A" // Letra Destino
   oRecDiv:aTipDoc   :=ACLONE(aTipDoc)
   oRecDiv:cTipDes   :=cTipDes // Documento Destino
   oRecDiv:cTipDoc   :=cTipDes // Documento Destino
   oRecDiv:lCruce    :=lCruce
   oRecDiv:oHSplit   :=NIL
   oRecDiv:oGTFMismaDiv:=NIL

   oRecDiv:nColSelP  :=7-1 // Seleccionar Pago
   oRecDiv:nColCodMon:=8-1   // Código de Moneda
   oRecDiv:nColCajBco:=9-1  // Caja/Banco

   oRecDiv:nColPorITG:=12-1        // % IGTF
   oRecDiv:nColMtoITG:=13-1        // 13 Monto IGTF
   oRecDiv:nColIsMon :=nColIsMon // Si es Moneda

   oRecDiv:cCenCos   :=oDp:cCenCos

   oRecDiv:lBarDef    :=.T.
   oRecDiv:cTitleCli  :=oDp:DPCLIENTES
   oRecDiv:cWhereCli  :=NIL
   oRecDiv:lValCodCli :=.F.
   oRecDiv:lValCODCAJA:=.F.
   oRecDiv:lValCenCos :=.F.
   oRecDiv:dFecha     :=oDp:dFecha
   oRecDiv:nOption    :=1
   oRecDiv:nColEdit   :=16

   oRecDiv:nMtoPag      :=0
   oRecDiv:nMtoDiv      :=nMtoDiv // Monto Divisa
   oRecDiv:nMtoDoc      :=0
   oRecDiv:nTotal       :=0
   oRecDiv:lAnticipo    :=lAnticipo
   oRecDiv:nResiduo     :=0 // Residuo decimal
   oRecDiv:lGTFMismaDiv :=.F.

   oRecDiv:lCajaAct     :=.T.
   oRecDiv:lBancoAct    :=.T.
   oRecDiv:lSoloEfectivo:=.F.
   oRecDiv:lIGTFCXC     :=.F.  // IGTF Cuentas por Cobrar
   oRecDiv:lIGTF        :=.T.  // Calcular IGTF
   oRecDiv:lEditDifCam  :=.T.  // Editar DIF CAMBIARIOS
   oRecDiv:lEditDivOrg  :=.T.  // Edita Col[7] el monto Origal Impreso en el caso de Cuentas por Pagar que no cuadré 
   oRecDiv:lEditDocDiv  :=.T.  // Permite modificar el valor de la Divisa que está pagando
   oRecDiv:lDifCambiario:=.T.  // Activado Diferencial Cambiario
   oRecDiv:lDifAnticipo :=.F.  // Diferencial de Pago será Anticipado
   oRecDiv:nMtoAnticipo :=0    // Monto Excede será Anticipo
   oRecDiv:lCliente     :=lCliente  // Utiliza Clientes


   IF lCruce 
      oRecDiv:lDifCambiario:=.F. // no calcula diferencial cambiario
   ENDIF
 
   oRecDiv:aCajaAct     :={}
   oRecDiv:aBancoAct    :={}
   oRecDiv:cMonedaSel   :=""

   oRecDiv:nMontoBs   :=0 // 50*7.85
   oRecDiv:nMontoUsd  :=0 // Total en Divisas 
   oRecDiv:nTotal5    :=0
   oRecDiv:oBtnSave   :=NIL

   oRecDiv:aDataR     :=ACLONE(aDataR)

   aData:=oRecDiv:CALDIVISA(aData)

   IF lAnticipo
      aDataD[1,6]:=oRecDiv:nValCam // Valor Divisa del Anticipo
   ENDIF

   oRecDiv:oBrw:=TXBrowse():New( oRecDiv:oWnd)

   oRecDiv:oBrw:SetArray( aData , .F. )
   oRecDiv:oBrw:SetFont(oFontBrw)
   oRecDiv:oBrw:lHScroll    :=.T.
   oRecDiv:oBrw:nHeaderLines:=2
   oRecDiv:oBrw:lFooter     :=.T.
   oRecDiv:oBrw:nDataLines  :=1 

   oRecDiv:aData :=ACLONE(aData)

   oCol:=oRecDiv:oBrw:aCols[1]
   oCol:cHeader      :="Moneda"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120-40


   oCol:=oRecDiv:oBrw:aCols[2]
   oCol:cHeader      :="Equivalente"+CRLF+oDp:cMoneda
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120-40
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,2],FDP(nMonto,oDp:cPictValCam)}
// oCol:cFooter      :=FDP(aTotal[2],"999,999,999.99")


   oCol:=oRecDiv:oBrw:aCols[3]
   oCol:cHeader      :="Remanente"+CRLF+"Sugerido"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 110
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,3],FDP(nMonto,"999,999,999,999.99")}
  
   oCol:=oRecDiv:oBrw:aCols[4]
   oCol:cHeader      :="Recibido"+CRLF+"Divisa"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture := "999,999,999,999.99"
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,4],FDP(nMonto,"999,999,999.99")}
   oCol:nEditType    :=1
   oCol:bOnPostEdit  :={|oCol,uValue|oRecDiv:PUTMONTO(oCol,uValue,4)}
   oCol:oDataFont    :=oFontB
   oCol:cFooter      :=FDP(aTotal[4],"999,999,999.99")

   oCol:=oRecDiv:oBrw:aCols[5]
   oCol:cHeader      :="Equivalente"+CRLF+"Recibido "+oDp:cMoneda
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5],FDP(nMonto,"999,999,999.99")}
   oCol:cFooter      :=FDP(aTotal[5],"999,999,999.99")

/*
   oCol:=oRecDiv:oBrw:aCols[6]
   oCol:cHeader      :="Original"+CRLF+"Divisa"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,6],FDP(nMonto,"999,999,999.99")}
*/
   oCol:=oRecDiv:oBrw:aCols[oRecDiv:nColSelP]
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:cHeader      :="Ok"
   oCol:AddBmpFile("BITMAPS\checkverde.bmp")
   oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
   oCol:bBmpData    := { |oBrw|oBrw:=oRecDiv:oBrw,IIF(oBrw:aArrayData[oBrw:nArrayAt,oRecDiv:nColSelP],1,2) }
   oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
   oCol:bStrData    :={||""}

   oCol:=oRecDiv:oBrw:aCols[oRecDiv:nColCodMon]
   oCol:cHeader      :="Cód."+CRLF+"Mon."
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 30

   oCol:=oRecDiv:oBrw:aCols[oRecDiv:nColCajBco]
   oCol:cHeader      :="Caj"+CRLF+"Bco"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 30
   oCol:bClrStd      := {|oBrw,nClrText,aLine|oBrw    :=oRecDiv:oBrw,;
                                              aLine   :=oBrw:aArrayData[oBrw:nArrayAt],;
	                                         nClrText:=IF("CAJ"$aLine[09],oRecDiv:nClrText3,oRecDiv:nClrText4),;
                                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

   oCol:=oRecDiv:oBrw:aCols[10-1]
   oCol:cHeader      :="Cód"+CRLF+"Ins"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 35

   oCol:=oRecDiv:oBrw:aCols[11-1]
   oCol:cHeader      :="Instrumento"+CRLF+"Caja/Banco"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120

   oCol:=oRecDiv:oBrw:aCols[oRecDiv:nColPorITG]
   oCol:cHeader      :="%"+CRLF+"IGTF"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 35
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,oRecDiv:nColPorITG],FDP(nMonto,"9.99")}

   oCol:bClrStd:={|oBrw,nClrText,aLine|oBrw    :=oRecDiv:oBrw,;
                                       aLine   :=oBrw:aArrayData[oBrw:nArrayAt],;
	                                       nClrText:=IF(aLine[oRecDiv:nColPorITG]>0,oRecDiv:nClrText1,oRecDiv:nClrText),;
                                       {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

   oCol:=oRecDiv:oBrw:aCols[oRecDiv:nColMtoITG]
   oCol:cHeader      :="Monto"+CRLF+"IGTF "
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 80
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,oRecDiv:nColMtoITG],FDP(nMonto,"999,999,999.99")}
   oCol:cFooter      :=FDP(aTotal[oRecDiv:nColMtoITG],"999,999,999.99")

   oCol:=oRecDiv:oBrw:aCols[oRecDiv:nColIsMon]
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:cHeader      :="Mone"+CRLF+"da"
   oCol:AddBmpFile("BITMAPS\monedas2.bmp")
   oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
   oCol:bBmpData    := { |oBrw|oBrw:=oRecDiv:oBrw,IIF(oBrw:aArrayData[oBrw:nArrayAt,oRecDiv:nColIsMon],1,2) }
   oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
   oCol:bStrData    :={||""}

   oCol:=oRecDiv:oBrw:aCols[15-1]
   oCol:cHeader      :="Marca"+CRLF+"Financiera"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120

   oCol:=oRecDiv:oBrw:aCols[16-1]
   oCol:cHeader      :="Banco"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 20

   oCol:=oRecDiv:oBrw:aCols[17-1]
   oCol:cHeader      :="Cuenta"+CRLF+"Bancaria"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth       := 120

   oCol:=oRecDiv:oBrw:aCols[18-1]
   oCol:cHeader       :="Referencia"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:nWidth        := 120

   oCol:=oRecDiv:oBrw:aCols[18]
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrw:aArrayData ) } 
   oCol:cHeader      :="Dupli-"+CRLF+"car"
   oCol:AddBmpFile("BITMAPS\checkverde.bmp")
   oCol:AddBmpFile("BITMAPS\xcheckon.BMP")
   oCol:bBmpData    := { |oBrw|oBrw:=oRecDiv:oBrw,IIF(oBrw:aArrayData[oBrw:nArrayAt,18],1,2) }
   oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
   oCol:bStrData    :={||""}

   
   oRecDiv:oBrw:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrw,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                                                 nClrText:=oRecDiv:nClrText,;
                                                 nClrText:=IF(!Empty(aLine[4]),oRecDiv:nClrText1,nClrText),;
                                                 nClrText:=IF(aLine[4]>0 .AND. (oRecDiv:nTotal5=oRecDiv:nMontoBs) ,oRecDiv:nClrText2,nClrText),;
                                                 {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

   oRecDiv:oBrw:bClrHeader:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oRecDiv:oBrw:bClrFooter:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oRecDiv:oBrw:bLDblClick:={|oBrw|oRecDiv:RUNCLICK() }

   oRecDiv:oBrwFocus :=oRecDiv:oBrw

// oRecDiv:oBrw:CreateFromCode()

   oRecDiv:bValid   :={|| EJECUTAR("BRWSAVEPAR",oRecDiv)}
   oRecDiv:BRWRESTOREPAR()

   oRecDiv:oBrw:bClrHeader            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oRecDiv:oBrw:bClrFooter            := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}


   oRecDiv:oBrw:bLDblClick:={|oBrw|oRecDiv:RUNCLICK() }

   oRecDiv:oBrw:bChange:={||oRecDiv:BRWCHANGE()}
   oRecDiv:oBrw:CreateFromCode()
   oRecDiv:oBrw:bGotFocus:={|| oRecDiv:oBrwFocus:=oRecDiv:oBrw} 

   oRecDiv:bValid   :={|| EJECUTAR("BRWSAVEPAR",oRecDiv)}
   oRecDiv:BRWRESTOREPAR()


   aTotal:=ATOTALES(aDataD)

   // Otros Pagos y Otros Ingresos
   IF oRecDiv:cTipDes="OPA" .OR. oRecDiv:cTipDes="OIN"

      EJECUTAR("DPRECIBODIV_OPA",oRecDiv,oFontBrw)

   ELSE

   oRecDiv:oBrwD:=TXBrowse():New( IF(oRecDiv:lTmdi,oRecDiv:oWnd,oRecDiv:oDlg ))
   oRecDiv:oBrwD:SetArray( aDataD, .F. )
   oRecDiv:oBrwD:SetFont(oFontBrw)

   oRecDiv:oBrwD:lFooter     := .T.
   oRecDiv:oBrwD:lHScroll    := .T.
   oRecDiv:oBrwD:nHeaderLines:= 2
   oRecDiv:oBrwD:nDataLines  := 1
   oRecDiv:oBrwD:nFooterLines:= 1

   oRecDiv:aDataD            :=ACLONE(aDataD)

   AEVAL(oRecDiv:oBrwD:aCols,{|oCol|oCol:oHeaderFont:=oFontBrw})

   oCol:=oRecDiv:oBrwD:aCols[1]
   oCol:cHeader      :="Tipo"+CRLF+"Doc"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 40

   oCol:bClrStd:={|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrwD,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                               nClrText:=oRecDiv:nClrText,;
                               nClrText:=IF(aLine[7]>0,CLR_HBLUE,nClrText),;
                               nClrText:=IF(aLine[7]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }



   oCol:=oRecDiv:oBrwD:aCols[2]
   oCol:cHeader      :="Nombre"+CRLF+"Documento"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 140
   oCol:bClrStd:={|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrwD,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                               nClrText:=oRecDiv:nClrText,;
                               nClrText:=IF(aLine[7]>0,CLR_HBLUE,nClrText),;
                               nClrText:=IF(aLine[7]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }



   oCol:=oRecDiv:oBrwD:aCols[3]
   oCol:cHeader      :="Número"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 80

   oCol:=oRecDiv:oBrwD:aCols[4]
   oCol:cHeader      :="Fecha"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 76

   // Campo: DOC_NETO
   oCol:=oRecDiv:oBrwD:aCols[5]
   oCol:cHeader      :="Saldo"+CRLF+oDp:cMoneda
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 114
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :="9,999,999,999,999.99"
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5],;
                                     oCol  := oRecDiv:oBrwD:aCols[5],;
                                    FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter:=FDP(aTotal[5],oCol:cEditPicture)

   oCol:bClrStd:={|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrwD,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                               nClrText:=oRecDiv:nClrText,;
                               nClrText:=IF(aLine[5]>0,CLR_HBLUE,nClrText),;
                               nClrText:=IF(aLine[5]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

  // Campo: DOC_VALCAM
   oCol:=oRecDiv:oBrwD:aCols[6]
   oCol:cHeader      :="Valor"+CRLF+"Cambiario"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 96
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :=oDp:cPictValCam
   oCol:bStrData:={|nMonto,oCol|nMonto:= oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,6],;
                                oCol  := oRecDiv:oBrwD:aCols[6],;
                                FDP(nMonto,oCol:cEditPicture)}

   IF oRecDiv:lEditDocDiv
      oCol:nEditType    :=1
      oCol:bOnPostEdit  :={|oCol,uValue,nLastKey,nCol|oRecDiv:PUTMTODIV(uValue,6)}
   ENDIF

   oCol:lAvg:=.T.

   // Campo: DOC_MTODIV
   oCol:=oRecDiv:oBrwD:aCols[7]
   oCol:cHeader      :=IF(oRecDiv:lCliente,"CxC","CXP")+CRLF+"Divisa"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 100
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :="9,999,999,999,999.99"
   oCol:bStrData     := {|nMonto,oCol|nMonto:= oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7],;
                                      oCol  := oRecDiv:oBrwD:aCols[7],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[7],oCol:cEditPicture)

   oCol:bClrStd:={|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrwD,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                               nClrText:=oRecDiv:nClrText,;
                               nClrText:=IF(aLine[7]>0,CLR_HBLUE,nClrText),;
                               nClrText:=IF(aLine[7]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

  IF oRecDiv:lEditDivOrg
    oCol:nEditType    :=1
    oCol:bOnPostEdit  :={|oCol,uValue,nLastKey,nCol|oRecDiv:PUTDIVORG(uValue,7)}
  ENDIF



  // Campo: DOC_MTODIV
  oCol:=oRecDiv:oBrwD:aCols[8]
  oCol:cHeader      :="Pago"+CRLF+"Divisa"
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
  oCol:nWidth       := 100
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :="9,999,999,999,999.99"
  oCol:bStrData:={|nMonto,oCol|nMonto:= oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,8],;
                              oCol  := oRecDiv:oBrwD:aCols[8],;
                              FDP(nMonto,oCol:cEditPicture)}
  oCol:cFooter      :=FDP(aTotal[8],oCol:cEditPicture)

  oCol:nEditType    :=1
  oCol:bOnPostEdit  :={|oCol,uValue,nLastKey,nCol|oRecDiv:PUTMTOPAG(uValue,8)}

  oCol:bClrStd:={|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrwD,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                               nClrText:=oRecDiv:nClrText,;
                               nClrText:=IF(aLine[8]>0,CLR_HBLUE,nClrText),;
                               nClrText:=IF(aLine[8]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }


  // Campo: DOC_MTODIV
  oCol:=oRecDiv:oBrwD:aCols[9]
  oCol:cHeader      :="Pago"+CRLF+oDp:cMoneda
  oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
  oCol:nWidth       := 100
  oCol:nDataStrAlign:= AL_RIGHT 
  oCol:nHeadStrAlign:= AL_RIGHT 
  oCol:nFootStrAlign:= AL_RIGHT 
  oCol:cEditPicture :="9,999,999,999,999.99"
  oCol:bStrData:={|nMonto,oCol|nMonto:= oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,9],;
                              oCol  := oRecDiv:oBrwD:aCols[9],;
                              FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[9],oCol:cEditPicture)

   oCol:bClrStd:={|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrwD,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                               nClrText:=oRecDiv:nClrText,;
                               nClrText:=IF(aLine[9]>0,CLR_HBLUE,nClrText),;
                               nClrText:=IF(aLine[9]<0,CLR_HRED ,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

 // Campo: DOC_MTODIV
   oCol:=oRecDiv:oBrwD:aCols[10]
   oCol:cHeader      :="Diferencia"+CRLF+"Cambiaria"
   oCol:bLClickHeader := {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 100
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture :="9,999,999,999,999.99"
   oCol:bStrData     :={|nMonto,oCol|nMonto:= oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,10],;
                                    oCol  := oRecDiv:oBrwD:aCols[10],;
                                    FDP(nMonto,oCol:cEditPicture)}
   oCol:cFooter      :=FDP(aTotal[10],oCol:cEditPicture)

   IF oRecDiv:lEditDifCam
      oCol:nEditType    :=1
      oCol:bOnPostEdit  :={|oCol,uValue,nLastKey,nCol|oRecDiv:PUTDIFCAM(uValue,10)}
   ENDIF


   oCol:=oRecDiv:oBrwD:aCols[11]
   oCol:cHeader      :="Ok"
   oCol:AddBmpFile("BITMAPS\checkverde.bmp")
   oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
   oCol:bBmpData    := { |oBrw|oBrw:=oRecDiv:oBrwD,IIF(oBrw:aArrayData[oBrw:nArrayAt,11],1,2) }
   oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
   oCol:bStrData    :={||""}


   oCol:=oRecDiv:oBrwD:aCols[12]
   oCol:cHeader      :=IF(oRecDiv:lCliente,"CxC","CxP")
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 56
   oCol:bClrStd      := {|nClrText,uValue|uValue:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,12],;
                         nClrText:=COLOR_OPTIONS("DPTIPDOCCLI","TDC_CXC",uValue),;
                        {nClrText,iif( oRecDiv:oBrwD:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } } 

   oCol:=oRecDiv:oBrwD:aCols[13]
   oCol:cHeader      :="Cód."+CRLF+"Mon."
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 45

   oCol:=oRecDiv:oBrwD:aCols[14]
   oCol:cHeader      :=IF(oRecDiv:lPagoC,"Código"+CRLF+"Cliente","Factura"+CRLF+"Asociada")
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:nWidth       := 70

   oCol:=oRecDiv:oBrwD:aCols[15]
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwD:aArrayData ) } 
   oCol:cHeader      :="Reva-"+CRLF+"loriza"
   oCol:AddBmpFile("BITMAPS\checkverde.bmp")
   oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
   oCol:bBmpData    := { |oBrwD|oBrwD:=oRecDiv:oBrwD,IIF(oBrwD:aArrayData[oBrwD:nArrayAt,15],1,2) }
   oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
   oCol:bStrData    :={||""}


   oRecDiv:oBrwD:bClrStd  := {|oBrw,nClrText,aLine|oBrw:=oRecDiv:oBrwD,aLine:=oBrw:aArrayData[oBrw:nArrayAt],;
                               nClrText:=oRecDiv:nClrText,;
                               nClrText:=IF(aLine[12]="D",oRecDiv:nClrText3,nClrText),;
                              {nClrText,iif( oBrw:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

   oRecDiv:oBrwD:bClrHeader:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oRecDiv:oBrwD:bClrFooter:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oRecDiv:oBrwD:bLDblClick:={|oBrw|oRecDiv:RUNCLICKDOC() }

   oRecDiv:oBrwD:bChange:={||oRecDiv:BRWCHANGEDOC()}

/*
   oCol:=oRecDiv:oBrwD:aCols[oRecDiv:nColEdit]

   oCol:nEditType:=1
   oCol:bOnPostEdit  :={|oCol,uValue,nLastKey,nCol|oRecDiv:PUTMTOPAG(uValue,oRecDiv:nColEdit)}
*/

   oRecDiv:oBrwD:CreateFromCode()

   oRecDiv:oBrwD:bGotFocus:={|| oRecDiv:oBrwFocus:=oRecDiv:oBrwD} 
   oRecDiv:bValid   :={|| EJECUTAR("BRWSAVEPAR",oRecDiv)}

ENDIF

   oRecDiv:BRWRESTOREPAR()

   IF !oRecDiv:lCruce

     @ 0,0 SPLITTER oRecDiv:oHSplit ;
           HORIZONTAL;
           PREVIOUS CONTROLS oRecDiv:oBrw ;
           HINDS CONTROLS oRecDiv:oBrwD;
           TOP MARGIN 40 ;
           BOTTOM MARGIN 40 ;
           SIZE 300, 4  PIXEL ;
           OF oRecDiv:oWnd ;
           _3DLOOK

     oRecDiv:oWnd:oClient := oRecDiv:oHSplit

  ELSE

     oRecDiv:oWnd:oClient := oRecDiv:oBrwD

  ENDIF

  oDp:oRecDiv:=oRecDiv

  oRecDiv:Activate({||oRecDiv:ViewDatBar()})

//? oRecDiv:nMtoDiv,"oRecDiv:nMtoDiv"

  BMPGETBTN(oRecDiv:oCodCli) 
  BMPGETBTN(oRecDiv:oFecha)
  BMPGETBTN(oRecDiv:oCodCaja) 
  BMPGETBTN(oRecDiv:oFchReg) 

  IF oRecDiv:lCliente
    BMPGETBTN(oRecDiv:oCodVen) 
  ELSE
    BMPGETBTN(oRecDiv:oCenCos) 
  ENDIF

/*
  IF oRecDiv:nMtoDiv>0
     oRecDiv:oBrwD:nColSel:=8
     oRecDiv:PUTMTODIV(oRecDiv:nMtoDiv,8) // ,nCol)
     oRecDiv:oBrwD:aArrayData[1,11]:=.T.
     oRecDiv:oBrwD:aArrayData[1,05]:=ROUND(oRecDiv:nMtoDiv*oRecDiv:oBrwD:aArrayData[1,6],2)
     oRecDiv:oBrwD:aArrayData[1,07]:=oRecDiv:nMtoDiv
     oRecDiv:oBrwD:DrawLine(.T.)
  ENDIF
*/

  IF oRecDiv:lCruce
     oRecDiv:oBrw:Hide()
     oRecDiv:oBrwR:Hide()
  ELSE
     oRecDiv:oGTFMismaDiv:ForWhen(.F.)
  ENDIF

  oDp:oCliRec:=oRecDiv

//oRecDiv:oBrwD:Hide()
//)

RETURN .T.



/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol,oFontBrw,aTotal
   LOCAL oDlg:=IF(oRecDiv:lTmdi,oRecDiv:oWnd,oRecDiv:oDlg)
   LOCAL nLin:=0
   LOCAL nWidth:=oRecDiv:oBrw:nWidth()
   LOCAL nAltoBrw:=150-50

   /*   
   //  Ubicamos el Area del Primer Objeto o Browse.
   */

   nAltoBrw:=nAltoBrw+50

   oRecDiv:oBrw:Move(032,0,800,nAltoBrw,.T.)

   IF !oRecDiv:oHSplit=NIL
     oRecDiv:oHSplit:Move(oRecDiv:oBrw:nHeight()+oRecDiv:oBrw:nTop(),0)
   ENDIF

   oRecDiv:oBrwD:Move(oRecDiv:oBrw:nHeight()+oRecDiv:oBrw:nTop()+5,0,800,400,.T.)

   IF !oRecDiv:oHSplit=NIL
     oRecDiv:oHSplit:AdjLeft()
     oRecDiv:oHSplit:AdjRight()
   ENDIF

   oRecDiv:oBrw:GoTop(.T.)
   oRecDiv:oBrw:Refresh(.F.)

   oRecDiv:oBrwD:GoTop(.T.)
   oRecDiv:oBrwD:Refresh(.F.)

   DEFINE CURSOR oCursor HAND

   IF oRecDiv:lCruce
     DEFINE BUTTONBAR oBar SIZE 52-15,150 OF oDlg 3D CURSOR oCursor
   ELSE
     DEFINE BUTTONBAR oBar SIZE 52-15,60-15+30+40+40+30+20+3+20 OF oDlg 3D CURSOR oCursor
   ENDIF

   DEFINE FONT oFont     NAME "Tahoma"   SIZE 0, -10 BOLD
   DEFINE FONT oFontBrw  NAME "Tahoma"   SIZE 0, -12 BOLD

 // Emanager no Incluye consulta de Vinculos

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSAVE.BMP",NIL,"BITMAPS\XSAVEG.BMP";
          TOP PROMPT "Grabar"; 
          WHEN oRecDiv:nTotal=0 .AND. oRecDiv:nMtoPag>0 .AND. oRecDiv:nMtoDoc>0 ;
          ACTION oRecDiv:RECGRABAR()


   IF oRecDiv:lAnticipo
     oBtn:bWhen:={||oRecDiv:nMtoPag>0 }
     // 03/11/2022 oRecDiv:oBrwD:Hide()
   ENDIF

   oBtn:cToolTip:="Crear Recibo de Ingreso"

   oRecDiv:oBtnSave:=oBtn

   IF oRecDiv:lCuotasPrg 

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\PLANTILLAS.BMP";
            TOP PROMPT "Cuotas"; 
            ACTION oRecDiv:GENCUOTAS()

     oBtn:cToolTip:="Agregar Cuotas"

   ELSE

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            TOP PROMPT "Recarga"; 
            FILENAME "BITMAPS\REFRESH.BMP";
            ACTION oRecDiv:RELOADDOCS(.T.)

    oBtn:cToolTip:="Recargar Documentos"

    oRecDiv:oBtnRefresh:=oBtn


   ENDIF

   IF oRecDiv:lCliente

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\CLIENTE.BMP";
            TOP PROMPT "Cliente"; 
            ACTION EJECUTAR("DPCLIENTESCON",NIL,oRecDiv:cCodigo)

     oBtn:cToolTip:="Consultar Cliente"

   ENDIF


   IF .F.

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\VIEW.BMP";
            ACTION EJECUTAR("BRWRUNLINK",oRecDiv:oBrw,oRecDiv:cSql)

     oBtn:cToolTip:="Consultar Vinculos"


   ENDIF


   DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\divisas.BMP";
            TOP PROMPT "Divisa"; 
            ACTION oRecDiv:REFRESH_DIVISA()

   oBtn:cToolTip:="Refrescar Divisas"

 
   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ZOOM.BMP";
          TOP PROMPT "Zoom"; 
          ACTION IF(oRecDiv:oWnd:IsZoomed(),oRecDiv:oWnd:Restore(),oRecDiv:oWnd:Maximize())

   oBtn:cToolTip:="Maximizar"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XFIND.BMP";
          TOP PROMPT "Buscar"; 
          ACTION EJECUTAR("BRWSETFIND",oRecDiv:oBrw)

   oBtn:cToolTip:="Buscar"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\FILTRAR.BMP";
          TOP PROMPT "Filtrar"; 
          MENU EJECUTAR("BRBTNMENUFILTER",oRecDiv:oBrwFocus,oRecDiv);
          ACTION EJECUTAR("BRWSETFILTER",oRecDiv:oBrwFocus)

   oBtn:cToolTip:="Filtrar Registros"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\OPTIONS.BMP",NIL,"BITMAPS\\OPTIONSG.BMP";
          TOP PROMPT "Opciones"; 
          ACTION EJECUTAR("BRWSETOPTIONS",oRecDiv:oBrwFocus);
          WHEN LEN(oRecDiv:oBrwFocus:aArrayData)>1

   oBtn:cToolTip:="Filtrar según Valores Comunes"

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Excel"; 
          FILENAME "BITMAPS\EXCEL.BMP";
          ACTION (EJECUTAR("BRWTOEXCEL",oRecDiv:oBrwFocus,"oRecDiv:cTitle",oRecDiv:cNomCli))

   oBtn:cToolTip:="Exportar hacia Excel"

   oRecDiv:oBtnXls:=oBtn

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\html.BMP";
          TOP PROMPT "Html"; 
          ACTION (EJECUTAR("BRWTOHTML",oRecDiv:oBrwoRecDiv:oBrwFocus))

   oBtn:cToolTip:="Generar Archivo html"

   oRecDiv:oBtnHtml:=oBtn

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xTOP.BMP";
          TOP PROMPT "Primero"; 
          ACTION (oRecDiv:oBrw:GoTop(),oRecDiv:oBrw:Setfocus())

/*
IF nWidth>800 .OR. nWidth=0

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xSIG.BMP";
          ACTION (oRecDiv:oBrw:PageDown(),oRecDiv:oBrw:Setfocus())

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xANT.BMP";
          ACTION (oRecDiv:oBrw:PageUp(),oRecDiv:oBrw:Setfocus())

ENDIF
*/

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\xFIN.BMP";
          TOP PROMPT "Ultimo"; 
          ACTION (oRecDiv:oBrw:GoBottom(),oRecDiv:oBrw:Setfocus())


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Cerrar"; 
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION oRecDiv:Close()

  oRecDiv:oBrw:SetColor(0,oRecDiv:nClrPane1)
  oRecDiv:oBrwD:SetColor(0,oRecDiv:nClrPane1)

  EVAL(oRecDiv:oBrw:bChange)
 
  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oRecDiv:SETBTNBAR(45+2,45+3,oBar)
  
  @ 8,10 SAY "Código "        RIGHT OF oBar BORDER 
  @ 8,80 SAY "Fecha Trans. "  RIGHT OF oBar BORDER

  @ 09,19 BMPGET oRecDiv:oCodCli VAR oRecDiv:cCodigo;
                VALID oRecDiv:VALCODCLI();
                NAME "BITMAPS\FIND.BMP"; 
                WHEN oRecDiv:lCodigo;
                ACTION oRecDiv:LBXCLIENTES();
                SIZE 48,10 OF oBar

  oRecDiv:oCodCli:bLostFocus:={||oRecDiv:VALCODCLI()}
  oRecDiv:oCodCli:bKeyDown  :={|nKey|IF(nKey=13,oRecDiv:VALCODCLI(),NIL)}

  @ 10,19+45 BMPGET oRecDiv:oFecha VAR oRecDiv:dFecha;
                VALID oRecDiv:VALFECHA();
                NAME "BITMAPS\FIND.BMP"; 
                WHEN .T.;
                ACTION LbxDate(oRecDiv:oFecha,oRecDiv:dFecha);
                SIZE 48,10 OF oBar

  oRecDiv:oFecha:bLostFocus:={||oRecDiv:VALFECHA()}
  oRecDiv:oFecha:bKeyDown  :={|nKey|IF(nKey=13,oRecDiv:VALFECHA(),NIL)}

  @ 10,200 SAY oRecDiv:oNombre PROMPT " "+oRecDiv:cNomCli;
               OF oBar PIXEL SIZE 467,20 BORDER COLOR CLR_WHITE,16744448

  @ 1,100 SAY IF(oRecDiv:lCliente,"Vendedor ","C.Costo")  RIGHT OF oBar BORDER COLOR 0,65535

  IF oRecDiv:lCliente

    @ 1,100 SAY oRecDiv:oNombreVend PROMPT " "+SQLGET("DPVENDEDOR","VEN_NOMBRE","VEN_CODIGO"+GetWhere("=",oRecDiv:cCodVen));
            OF oBar PIXEL SIZE 467,20; 
            BORDER COLOR CLR_WHITE,16744448

  ELSE

     @ 10,200 SAY oRecDiv:oNombreCenCos PROMPT SQLGET("DPCENCOS","CEN_DESCRI","CEN_CODIGO"+GetWhere("=",oRecDiv:cCenCos));
                 OF oBar PIXEL SIZE 467,20 BORDER COLOR CLR_WHITE,16744448

  ENDIF

  @ 01,700 SAY IF(oRecDiv:lCruce,"Débitos" ,"Pagos "     ) OF oBar RIGHT PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow BORDER
  @ 20,700 SAY IF(oRecDiv:lCruce,"Créditos","Documentos ") OF oBar RIGHT PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow BORDER
  @ 30,700 SAY "Balance "    OF oBar RIGHT PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow BORDER

  @ 01,800 SAY oRecDiv:oMtoPag PROMPT FDP(oRecDiv:nMtoPag,"999,999,999,999.99") OF oBar RIGHT PIXEL BORDER
  @ 20,800 SAY oRecDiv:oMtoDoc PROMPT FDP(oRecDiv:nMtoDoc,"999,999,999,999.99") OF oBar RIGHT PIXEL BORDER
  @ 30,800 SAY oRecDiv:oTotal  PROMPT FDP(oRecDiv:nTotal ,"999,999,999,999.99") OF oBar RIGHT PIXEL BORDER

  @ 40,400 SAY "Divisa "+oRecDiv:cCodMon+" " RIGHT   OF oBar RIGHT PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow;
           BORDER

  @ 40,500 GET oRecDiv:oValCam  VAR oRecDiv:nValCam;
           PICTURE oDp:cPictValCam OF oBar;
           VALID  oRecDiv:VALVALCAM();
           RIGHT PIXEL 

  oRecDiv:oValCam:bKeyDown  :={|nKey|IF(nKey=13,oRecDiv:VALVALCAM(),NIL)}


  @ 01,700 SAY "IGTF "     OF oBar RIGHT PIXEL COLOR 0,65535 BORDER

  @ 30,800 SAY oRecDiv:oMtoIGTF  PROMPT FDP(oRecDiv:nMtoIGTF,"999,999,999,999.99") OF oBar RIGHT PIXEL BORDER


  @ 14,10 SAY "Caja "      OF oBar RIGHT PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow BORDER


  @ 05.5,12.5 BMPGET oRecDiv:oCodCaja VAR oRecDiv:cCodCaja;
                 VALID oRecDiv:VALCODCAJA();
                 NAME "BITMAPS\FIND.BMP"; 
                 WHEN !oRecDiv:lCruce;
                 ACTION oRecDiv:LBXCAJA();
                 SIZE 48,20 OF oBar

  oRecDiv:oCodCaja:bLostFocus:={||oRecDiv:VALCODCAJA()}
  oRecDiv:oCodCaja:bKeyDown  :={|nKey|IF(nKey=13,oRecDiv:VALCODCAJA(),NIL)}

//  BMPGETBTN(oRecDiv:oCodCaja,NIL,18) // ,oFont,nAncho)

  @ 10,200 SAY oRecDiv:oNombreCaja PROMPT SQLGET("DPCAJA","CAJ_NOMBRE","CAJ_CODIGO"+GetWhere("=",oRecDiv:cCodCaja));
               OF oBar PIXEL SIZE 467,20 BORDER COLOR CLR_WHITE,16744448


  IF !oRecDiv:lCliente

    @ 05.5,12.5 BMPGET oRecDiv:oCenCos VAR oRecDiv:cCenCos;
                 VALID oRecDiv:VALCENCOS();
                 NAME "BITMAPS\FIND.BMP"; 
                 WHEN !oRecDiv:lCruce;
                 ACTION oRecDiv:LBXCENCOS();
                 SIZE 48,20 OF oBar

    oRecDiv:oCenCos:bLostFocus:={||oRecDiv:VALCENCOS()}
    oRecDiv:oCenCos:bKeyDown  :={|nKey|IF(nKey=13,oRecDiv:VALCENCOS(),NIL)}

  ELSE

    @ 05.5,12.5 BMPGET oRecDiv:oCodVen VAR oRecDiv:cCodVen;
                 VALID oRecDiv:VALCODVEN();
                 NAME "BITMAPS\FIND.BMP"; 
                 WHEN !oRecDiv:lCruce;
                 ACTION oRecDiv:LBXCODVEN();
                 SIZE 48,20 OF oBar

    oRecDiv:oCenCos:bLostFocus:={||oRecDiv:VALCODVEN()}
    oRecDiv:oCenCos:bKeyDown  :={|nKey|IF(nKey=13,oRecDiv:VALCODVEN(),NIL)}

  ENDIF

  IF !oRecDiv:lCruce


  @ 1,140 CHECKBOX oRecDiv:oCajaAct VAR  oRecDiv:lCajaAct;
         PROMPT " Caja";
         WHEN (oRecDiv:nOption<>0 .AND. oRecDiv:lBancoAct);
         OF oBar SIZE 100,20;
         ON CHANGE  oRecDiv:SETCAJA()

  oRecDiv:oCajaAct:cMsg    :="Utilizar Instrumentos de Caja"
  oRecDiv:oCajaAct:cToolTip:="Utilizar Instrumentos de Caja"

  @ 2,140 CHECKBOX oRecDiv:oBancoAct VAR  oRecDiv:lBancoAct;
         PROMPT " Banco ";
         WHEN (oRecDiv:nOption<>0 .AND. oRecDiv:lCajaAct);
         OF oBar SIZE 100,20;
         ON CHANGE  oRecDiv:SETBANCO()  

  oRecDiv:oBancoAct:cMsg    :="Utilizar Instrumentos de Bancos"
  oRecDiv:oBancoAct:cToolTip:="Utilizar Instrumentos de Bancos"

  @ 3,140 CHECKBOX oRecDiv:oSoloEfectivo VAR  oRecDiv:lSoloEfectivo;
         PROMPT " Sólo Efectivo ";
         WHEN (oRecDiv:nOption<>0 .AND. oRecDiv:lCajaAct);
         OF oBar SIZE 100,20;
         ON CHANGE  oRecDiv:SOLOEFECTIVO()

  oRecDiv:oSoloEfectivo:cMsg    :="Sólo Efectivo"
  oRecDiv:oSoloEfectivo:cToolTip:="Sólo Efectivo"

 @ 3,140 CHECKBOX oRecDiv:oIGTFCXC VAR  oRecDiv:lIGTFCXC;
         PROMPT " IGTF -> "+IF(oRecDiv:lCliente,"CXC ","CXP ");
         WHEN (oRecDiv:nOption<>0);
         OF oBar SIZE 100,20;
         ON CHANGE  (oRecDiv:CALTOTAL(),oRecDiv:SETSUGERIDO())

  oRecDiv:oIGTFCXC:cMsg    :="IGTF hacia CxC"
  oRecDiv:oIGTFCXC:cToolTip:="IGTF hacia CxC"

 @ 6,140 CHECKBOX oRecDiv:oIGTF VAR  oRecDiv:lIGTF;
         PROMPT " Calcular IGTF ";
         WHEN (oRecDiv:nOption<>0);
         OF oBar SIZE 100,20;
         ON CHANGE  (oRecDiv:CALTOTAL(),oRecDiv:SETSUGERIDO())

  oRecDiv:oIGTFCXC:cMsg    :="IGTF hacia CxC"
  oRecDiv:oIGTFCXC:cToolTip:="IGTF hacia CxC"


 @ 7,140 CHECKBOX oRecDiv:oGTFMismaDiv VAR  oRecDiv:lGTFMismaDiv;
         PROMPT " IGTF Misma Divisa ";
         WHEN (oRecDiv:nOption<>0 .AND. .F.);
         OF oBar SIZE 100,20;
         ON CHANGE  (oRecDiv:IGTFMISMADIVISA())

  oRecDiv:oGTFMismaDiv:cMsg    :="Calcular IGTF con la Misma Divisa"
  oRecDiv:oGTFMismaDiv:cToolTip:="Calcular IGTF con la Misma Divisa"

  @ 8,140 CHECKBOX oRecDiv:oDifCambiario VAR  oRecDiv:lDifCambiario;
         PROMPT " Diferencial Cambiario ";
         WHEN (oRecDiv:nOption<>0);
         OF oBar SIZE 100,20;
         ON CHANGE  (oRecDiv:VALDIFCAMBIARIO())

  oRecDiv:oDifCambiario:cMsg    :="Calcular Diferencial Cambiario"
  oRecDiv:oDifCambiario:cToolTip:="Calcular Diferencial Cambiario"

  @ 9,140 CHECKBOX oRecDiv:oDifAnticipo VAR  oRecDiv:lDifAnticipo;
         PROMPT " Excedente -> Anticipo ";
         WHEN (oRecDiv:nOption<>0 .AND. (oRecDiv:nTotal>0 .OR. oRecDiv:nMtoAnticipo<>0));
         OF oBar SIZE 100,20;
         ON CHANGE  EJECUTAR("DPRECEXCEDEANT",oRecDiv)

  oRecDiv:oDifAnticipo:cMsg    :="Excedente de pago hacia Anticipo"
  oRecDiv:oDifAnticipo:cToolTip:="Excedente de pago hacia Anticipo"


ENDIF

  @ 08,120 SAY "Fecha Reg. "  RIGHT OF oBar RIGHT 	COLOR oDp:nClrYellowText,oDp:nClrYellow BORDER

  @ 10,106 BMPGET oRecDiv:oFchReg VAR oRecDiv:dFchReg;
           VALID oRecDiv:VALFCHREG();
           NAME "BITMAPS\FIND.BMP"; 
           WHEN .T.;
           ACTION LbxDate(oRecDiv:oFchReg,oRecDiv:dFchReg);
           SIZE 48,10 OF oBar

  oRecDiv:oFchReg:bLostFocus:={||oRecDiv:VALFCHREG()}
  oRecDiv:oFchReg:bKeyDown  :={|nKey|IF(nKey=13,oRecDiv:VALFCHREG(),NIL)}

  oRecDiv:oBar:=oBar

  oRecDiv:aDataR:=TOTALRESDIVISA(oRecDiv:oBrw:aArrayData,NIL)

  aTotal:=ATOTALES(oRecDiv:aDataR)
  oRecDiv:oBrwR:=TXBrowse():New( oBar )

  oRecDiv:oBrwR:SetArray( oRecDiv:aDataR , .F. )
  oRecDiv:oBrwR:SetFont(oFontBrw)
  oRecDiv:oBrwR:lHScroll    :=.F.
  oRecDiv:oBrwR:nHeaderLines:=1
  oRecDiv:oBrwR:lFooter     :=.T.
  oRecDiv:oBrwR:nDataLines  :=1 
 
   oCol:=oRecDiv:oBrwR:aCols[1]
   oCol:cHeader      :="Id"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwR:aArrayData ) } 
   oCol:nWidth       := 40
   oCol:oDataFont    :=oFontB

   oCol:=oRecDiv:oBrwR:aCols[2]
   oCol:cHeader      :="Moneda"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwR:aArrayData ) } 
   oCol:nWidth       := 120+40
   oCol:oDataFont    :=oFontB

   oCol:=oRecDiv:oBrwR:aCols[3]
   oCol:cHeader      :="Recibido"
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwR:aArrayData ) } 
   oCol:nWidth       := 120-40
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrwR:aArrayData[oRecDiv:oBrwR:nArrayAt,3],FDP(nMonto,"999,999,999.99")}
   oCol:oDataFont    :=oFontB


   oCol:=oRecDiv:oBrwR:aCols[4]
   oCol:cHeader      :="Equiv. "+oDp:cMoneda
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwR:aArrayData ) }
   oCol:cEditPicture := "999,999,999,999.99"
   oCol:nWidth       := 110
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT
   oCol:oDataFont    :=oFontB
    oCol:bStrData    :={|nMonto|nMonto:= oRecDiv:oBrwR:aArrayData[oRecDiv:oBrwR:nArrayAt,4],FDP(nMonto,oDp:cPictValCam)}
  
   oCol:=oRecDiv:oBrwR:aCols[5]
   oCol:cHeader      :="Recibido en "+oDp:cMoneda
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwR:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture := "999,999,999,999.99"
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrwR:aArrayData[oRecDiv:oBrwR:nArrayAt,5],FDP(nMonto,"999,999,999.99")}
   oCol:oDataFont    :=oFontB
   oCol:cFooter      :=FDP(aTotal[5],"999,999,999.99")

   oCol:=oRecDiv:oBrwR:aCols[6]
   oCol:cHeader      :="Recibido en "+oDp:cMonedaExt
   oCol:bLClickHeader:= {|r,c,f,o| SortArray( o, oRecDiv:oBrwR:aArrayData ) } 
   oCol:nWidth       := 120
   oCol:nDataStrAlign:= AL_RIGHT 
   oCol:nHeadStrAlign:= AL_RIGHT 
   oCol:nFootStrAlign:= AL_RIGHT 
   oCol:cEditPicture := "999,999,999,999.99"
   oCol:bStrData     :={|nMonto|nMonto:= oRecDiv:oBrwR:aArrayData[oRecDiv:oBrwR:nArrayAt,6],FDP(nMonto,"999,999,999.99")}
   oCol:oDataFont    :=oFontB
   oCol:cFooter      :=FDP(aTotal[6],"999,999,999.99")

   oRecDiv:oBrwR:bClrStd  := {|oBrwR,nClrText,aLine|oBrwR:=oRecDiv:oBrwR,;
                                                    aLine:=oBrwR:aArrayData[oBrwR:nArrayAt],;
                                                    nClrText:=oRecDiv:nClrText,;
                                                    nClrText:=IF(!Empty(aLine[3]),oRecDiv:nClrText1,nClrText),;
                                                   {nClrText,iif( oBrwR:nArrayAt%2=0, oRecDiv:nClrPane1, oRecDiv:nClrPane2 ) } }

   oRecDiv:oBrwR:bClrHeader:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
   oRecDiv:oBrwR:bClrFooter:= {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

   oRecDiv:oBrwR:bLDblClick:={|oBrwR|oRecDiv:RUNCLICKR() }

   oRecDiv:oBrwR:SetColor(0,oRecDiv:nClrPane1)
   oRecDiv:oBrwR:CreateFromCode()
   oRecDiv:oBrwR:bGotFocus:={|| oRecDiv:oBrwFocus:=oRecDiv:oBrwR} 

   oRecDiv:bValid   :={|| EJECUTAR("BRWSAVEPAR",oRecDiv)}
   oRecDiv:BRWRESTOREPAR()
 
RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICK()
  LOCAL aLine   :=oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt]
  LOCAL lRefresh:=.F.
  LOCAL nAt     :=oRecDiv:oBrw:nArrayAt,nPos:=0,nMtoIgtf:=0,cCodMon:=""
  LOCAL nRowSel :=oRecDiv:oBrw:nRowSel
  LOCAL aTotalD :=ATOTALES(oRecDiv:oBrwD:aArrayData) // total Documentos
  LOCAL nMtoPag :=0,aTotalP,nResiduo

  IF oRecDiv:oBrw:nColSel=oRecDiv:nColPorITG .AND. aLine[4]<>0 
     oRecDiv:ADDIGTF(oRecDiv:oBrw:nArrayAt) // Agrega el IGTF como pago con la misma moneda
     oRecDiv:SETSUGERIDO()
     RETURN .F.
  ENDIF

  IF (oRecDiv:oBrw:nColSel=18)

     aLine[18]:=.T.
     aLine[04]:=0

     AINSERTAR(oRecDiv:oBrw:aArrayData,nRowSel,ACLONE(aLine))
     oRecDiv:oBrw:nArrayAt:=nAt
     oRecDiv:oBrw:aArrayData:Refresh(.F.)
     oRecDiv:SETSUGERIDO()
    
     RETURN .F.

  ENDIF

//  IF oRecDiv:nMtoIGTF=oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5]
//     oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,11]:=0
//  ENDIF



  IF (oRecDiv:oBrw:nColSel=oRecDiv:nColSelP .OR. oRecDiv:oBrw:nColSel=3) .AND. (oRecDiv:nMtoDoc>0 .OR. oRecDiv:nMtoPag>0)

     // no existe Sugerido
     IF !oRecDiv:oBrw:aArrayData[nAt,oRecDiv:nColSelP] .AND. Empty(aLine[3]) 
        RETURN .F.
     ENDIF

     oRecDiv:oBrw:aArrayData[nAt,oRecDiv:nColSelP]:=!oRecDiv:oBrw:aArrayData[nAt,oRecDiv:nColSelP]

     IF !oRecDiv:oBrw:aArrayData[nAt,oRecDiv:nColSelP]

        // Registro Clonado del IGTF
        // 16/10/2022
        IF .F. // aLine[4]=aLine[5] .AND. aLine[4]=aLine[6] .AND. aLine[2]<>1

          ARREDUCE(oRecDiv:oBrw:aArrayData,nAt)
          nAt:=MAX(nAt,LEN(oRecDiv:oBrw:aArrayData))

        ELSE

          IF aLine[oRecDiv:nColMtoITG]>0
             oRecDiv:ADDIGTF(nAt) // Quitar el IGTF
             oRecDiv:SETSUGERIDO()
	     ENDIF

          oRecDiv:oBrw:aArrayData[nAt,4]:=0
          oRecDiv:oBrw:aArrayData[nAt,5]:=0
          // oRecDiv:oBrw:aArrayData[nAt,6]:=0

        ENDIF
      
     ELSE

        // obtiene el monto Sugerido
        // 16/10/2022 
        oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,4]:=aLine[3]
        oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5]:=ROUND(aLine[3]*aLine[2],2) 

        // 22/05/2024, IGTF Pagado con COP no aplica
        IF oRecDiv:nMtoIGTF=oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5]
           oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,11]:=0
        ENDIF

        aTotalP :=ATOTALES(oRecDiv:oBrw:aArrayData)

        IF oRecDiv:cTipDes="OPA" .OR. oRecDiv:cTipDes="OIN"
          nResiduo:=aTotalP[5]-aTotalD[7]
        ELSE
          nResiduo:=aTotalP[5]-aTotalD[9]
        ENDIF

        // Calcula el IGTF Automatico en la misma oficina
        IF oRecDiv:lGTFMismaDiv .AND. oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,oRecDiv:nColPorITG]>0
// ? "AGREGAR ADDIGTF",nAt
          oRecDiv:ADDIGTF(nAt) 
          oRecDiv:SETSUGERIDO()
        ENDIF

        IF ABS(nResiduo)<1
           oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5]:=oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5]-nResiduo
        ENDIF

        // oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,7]:=(aLine[3]>0)
        
     ENDIF

     oRecDiv:oBrw:aArrayData:=oRecDiv:CALDIVISA(oRecDiv:oBrw:aArrayData,oRecDiv:oBrw)

     lRefresh:=.T.

     IF aLine[oRecDiv:nColCajBco]="BCO"
       oRecDiv:oBrw:nColSel:=16-1
     ENDIF

     oRecDiv:BRWCHANGE()

  ENDIF
 
  oRecDiv:CALTOTAL()

  oRecDiv:SETSUGERIDO()


/*
  IF lRefresh
     oRecDiv:oBrw:Refresh(.F.)
     oRecDiv:oBrw:nArrayAt:=nAt 
     oRecDiv:oBrw:nRowSel :=nRowSel
  ENDIF
*/
RETURN .T.

/*
// Evento para presionar CLICK
*/
FUNCTION RUNCLICKDOC()
   LOCAL aLine  :=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt],nCol:=8
   LOCAL nMtoDoc:=aLine[07]
   LOCAL cTipDoc:=aLine[01]
   LOCAL cNumero:=aLine[03]
   LOCAL nMtoDiv:=aLine[08]
   LOCAL aTotal :=ATOTALES(oRecDiv:oBrwD:aArrayData)

//? oRecDiv:oBrwD:nColSel,"oRecDiv:oBrwD:nColSel"

   IF oRecDiv:oBrwD:nColSel<=3

      // Si viene desde otra BD, no se puede consultar

      IF oRecDiv:lDb 
         RETURN .F.
      ENDIF

      IF oRecDiv:lCliente
         RETURN EJECUTAR("VERDOCCLI",oRecDiv:cCodSuc,cTipDoc,oRecDiv:cCodigo,cNumero) // ,"D")  
      ELSE
         RETURN EJECUTAR("VERDOCPRO",oRecDiv:cCodSuc,cTipDoc,oRecDiv:cCodigo,cNumero) // ,"D")  
      ENDIF

   ENDIF

   IF (oRecDiv:oBrwD:nColSel=7 .OR. oRecDiv:oBrwD:nColSel=11) .AND. oRecDiv:lCruce
      // Cruce de documentos

      IF !Empty(aLine[08])
        nMtoDoc:=0
      ENDIF

      IF oRecDiv:nTotal<0 .AND. nMtoDoc>0

         IF nMtoDoc>aTotal[8]
           nMtoDoc:=aTotal[8]*-1
         ENDIF

      ENDIF

      IF oRecDiv:nTotal>0 .AND. nMtoDoc<0

         IF ABS(nMtoDoc)>aTotal[8]
           nMtoDoc:=aTotal[8]*-1
         ENDIF

      ENDIF

      oRecDiv:PUTMTOPAG(nMtoDoc,nCol)
      oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,11]:=(nMtoDoc<>0)
      oRecDiv:oBrwD:DrawLine(.T.)

   ENDIF

   IF (oRecDiv:oBrwD:nColSel=7 .OR. oRecDiv:oBrwD:nColSel=11) .AND. !oRecDiv:lCruce

      IF !Empty(aLine[08])

        nMtoDoc:=0

      ELSE

        IF oRecDiv:nTotal>0
          nMtoDoc:=MIN(nMtoDoc,oRecDiv:nTotal) // no puede superar el monto del documento
        ENDIF

      ENDIF

      oRecDiv:PUTMTOPAG(nMtoDoc,08)
      oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,11]:=(nMtoDoc<>0)

      // IF MONTO EN DIVISA ES PARCIAL, DIFERENCIAL CAMBIARIO ES 0

      oRecDiv:oBrwD:DrawLine(.T.)

      // 15/10/2022 oRecDiv:oBrw:aArrayData:=oRecDiv:CALDIVISA(oRecDiv:oBrw:aArrayData,oRecDiv:oBrw)

      oRecDiv:SETSUGERIDO()

      RETURN .T.

   ENDIF

RETURN .T.

/*
// Imprimir
*/
FUNCTION IMPRIMIR()
RETURN .T.

FUNCTION LEEFECHAS()
RETURN .T.

FUNCTION HACERWHERE(dDesde,dHasta,cWhere_,lRun)
RETURN cWhere

FUNCTION LEERDATA(cWhere,oBrw,cServer,cTableA)
RETURN aData


/*
// Permite Crear Filtros para las Búquedas
*/
FUNCTION BRWQUERY()
     EJECUTAR("BRWQUERY",oRecDiv)
RETURN .T.

/*
// Ejecución Cambio de Linea 
*/
FUNCTION BRWCHANGE()
   LOCAL aLine:=oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt]
   LOCAL oCol :=oRecDiv:oBrw:aCols[16-1]

//   oDp:oFrameDp:SetText(LSTR(LEN(aLine))+" VALTYPE ALINE[8]"+ValType(aLine[8]))

   IF aLine[09-1]="BCO" .AND. oRecDiv:nMtoDoc>0 .AND. aLine[oRecDiv:nColSelP] .AND. LEN(oDp:aCuentaBco)>0

      oCol:nEditType     :=EDIT_LISTBOX
      oCol:aEditListTxt  :=ACLONE(oDp:aNombreBco)
      oCol:aEditListBound:=ACLONE(oDp:aNombreBco)
      oCol:bOnPostEdit   :={|oCol,uValue|oRecDiv:PUTBANCO(oCol,uValue,16-1)} // Debe seleccionar las cuentas bancarias
      oRecDiv:oBrw:DrawLine(.T.)
      
   ELSE

      oCol:nEditType    :=0
      oCol:bOnPostEdit  :=NIL

   ENDIF


RETURN NIL

FUNCTION PUTBANCO(oCol,uValue,nCol)
   LOCAL oColEdit:=oRecDiv:oBrw:aCols[17-1]
   LOCAL aCuentas:=ACLONE(oDp:aCuentaBco)

   ADEPURA(aCuentas,{|a,n| !ALLTRIM(a[1])=ALLTRIM(uValue)})

   AEVAL(aCuentas,{|a,n| aCuentas[n]:=a[2]})

   oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,16-1]:=uValue

   IF LEN(aCuentas)>1

     oColEdit:nEditType     :=EDIT_LISTBOX
     oColEdit:aEditListTxt  :=ACLONE(aCuentas)
     oColEdit:aEditListBound:=ACLONE(aCuentas)
     oColEdit:bOnPostEdit   :={|oCol,uValue|oRecDiv:PUTCUENTA(oCol,uValue,17-1)} // Debe seleccionar las cuentas bancarias
     oRecDiv:oBrw:nColSel   :=17-1

   ELSE

     oColEdit:nEditType     :=0
     oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,17-1]:=aCuentas[1]
     oRecDiv:oBrw:nColSel   :=18-1

   ENDIF

   // Editar Referencia
   oColEdit:=oRecDiv:oBrw:aCols[18-1]
   oColEdit:nEditType     :=1
   oColEdit:bOnPostEdit   :={|oCol,uValue|oRecDiv:PUTREFERENCIA(oCol,uValue,17)} 

   oRecDiv:oBrw:DrawLine(.T.)

RETURN .T.

FUNCTION PUTCUENTA(oCol,uValue,nCol)

   oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,17-1]:=uValue
   oRecDiv:oBrw:DrawLine(.T.)

RETURN .T.

FUNCTION BRWCHANGEDOC()
RETURN NIL


/*
// Refrescar Browse
*/
FUNCTION BRWREFRESCAR()
RETURN NIL

FUNCTION BRWRESTOREPAR()
RETURN EJECUTAR("BRWRESTOREPAR",oRecDiv)

FUNCTION VERAUDITORIA()
RETURN EJECUTAR("DPCREARECFROMBCO",oRecDiv:cCodigo,NIL,NIL,NIL,NIL,NIL,NIL,"DPAUDELIMODCNF_HIS")

FUNCTION VALCODCLI()
 
  oRecDiv:cNomCli:=SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",oRecDiv:cCodigo))
  oRecDiv:oNombre:Refresh(.T.)

  IF Empty(oRecDiv:cCodigo)
     RETURN .F.
  ENDIF

  IF !ISSQLFIND("DPCLIENTES","CLI_CODIGO"+GetWhere("=",oRecDiv:cCodigo))
     oRecDiv:lValCodCli:=.F.
     EVAL(oRecDiv:oCodCli:bAction)
     RETURN .F.
  ENDIF

  oRecDiv:cRif:=SQLGET("DPCLIENTES","CLI_RIF","CLI_CODIGO"+GetWhere("=",oRecDiv:cCodigo))

  oRecDiv:oNombre:Refresh(.T.)
  oRecDiv:lValCodCli:=.T.

  oRecDiv:TIPCAJBCO()

RETURN .T.

FUNCTION LBXCLIENTES()
   LOCAL cFileLbx:="DPCLIENTES"

   IF !oRecDiv:lCliente
     cFileLbx:="DPPROVEEDOR"
     oDpLbx:=DpLbx(cFileLbx,oRecDiv:cTitleCli,oRecDiv:cWhereCli,NIL,NIL,NIL,NIL,NIL,NIL,oRecDiv:oCodCli)
     oDpLbx:GetValue("PRO_CODIGO",oRecDiv:oCodCli)
   ELSE
     oDpLbx:=DpLbx(cFileLbx,oRecDiv:cTitleCli,oRecDiv:cWhereCli,NIL,NIL,NIL,NIL,NIL,NIL,oRecDiv:oCodCli)
     oDpLbx:GetValue("CLI_CODIGO",oRecDiv:oCodCli)
   ENDIF

RETURN .T.

/*
// Refresca las divisas
*/
FUNCTION REFRESH_DIVISA()
  LOCAL aData:=oRecDiv:TIPCAJBCO(oRecDiv,NIL,oRecDiv:nValCam,NIL,oRecDiv:nColIsMon,oRecDiv)

  oRecDiv:SETMONEDA(aData)

RETURN .T.

/*
// Lectura del Estado de Cuenta Bancario
*/
FUNCTION TIPCAJBCO(oRecDiv,cRif,nValCam,oBrw,nColIsMon,lCliente)
RETURN EJECUTAR("DPRECIBODIV_CAJBCO",oRecDiv,cRif,nValCam,oBrw,nColIsMon,lCliente)

FUNCTION CALDIVISA(aData,oBrw)
   LOCAL I,nMtoEqv,oCol,aTotalP:={},nSaldo:=oRecDiv:nMontoBs,nTotalRecB:=0,nAt:=0,nMtoIGTF:=0
   LOCAL nAt,nRowSel,nTotalUsd:=0,aTotalD:={},nMontoBs:=0,nTotalUsdD:=0,nTotalUsdP:=0,nMontoUsd,nTotalDif:=0
   LOCAL aDataR

   DEFAULT oBrw :=oRecDiv:oBrw,;
           aData:=oRecDiv:oBrw:aArrayData

   aDataR:=oRecDiv:TOTALRESDIVISA(aData) // Resumen por Divisa
   // JN 13/09/2022
   oRecDiv:nMtoIGTF:=0
   oRecDiv:CALIGTF(.T.)

   aTotalP:=ATOTALES(aDataR) // Antes Data

   IF ABS(oRecDiv:nTotal)>=.2 .AND. ABS(oRecDiv:nTotal)<1
      oRecDiv:CALRESIDUO()
      RETURN aData
   ENDIF

   IF !oRecDiv:oBrwD=NIL
      aTotalD   :=ATOTALES(oRecDiv:oBrwD:aArrayData)
      nTotalUsdD:=ROUND(aTotalD[8],2)  // -aTotal[4]
   ENDIF

   nTotalUsdP:=ROUND(aTotalP[6],2)
   nTotalDif :=nTotalUsdD-nTotalUsdP // Total Diferencia

   oRecDiv:nMontoBs:=ROUND(oRecDiv:nMontoUsd*oRecDiv:nValCam,2)+oRecDiv:nMtoIGTF

   nMontoUsd:=oRecDiv:nMontoUsd-aTotalP[4]
   nMontoBs :=ROUND(nTotalDif*oRecDiv:nValCam,2)+oRecDiv:nMtoIGTF
   nMontoUsd:=nTotalDif

RETURN aData

FUNCTION CALSUG(nMtoSug,nMoneda,cCodMon)
    LOCAL nMonto:=0

    IF cCodMon=oDp:cCodCop
       nMonto:=EJECUTAR("CALCOP",nMtoSug,oRecDiv:nValCam)
    ELSE
       nMonto:=ROUND(nMtoSug/nMoneda,2)
    ENDIF

RETURN nMonto

/*
// Sugerido en Panel de Pagos
*/
FUNCTION SETSUGERIDO()
   LOCAL aData  :=oRecDiv:oBrw:aArrayData,I,nAt:=oRecDiv:oBrw:nArrayAt,nRowSel:=oRecDiv:oBrw:nRowSel
   LOCAL nMtoSug:=0

   oRecDiv:nMtoIGTF:=0
   oRecDiv:CALIGTF(.T.)

   nMtoSug:=oRecDiv:nTotal*-1

   FOR I=1 TO LEN(aData)

      // 31/05/2024

      // aData[I,3]:=oRecDiv:CALSUG(nMtoSug,aData[I,7])
      aData[I,3]:=oRecDiv:CALSUG(nMtoSug,aData[I,2],aData[I,7])

/*
      IF aData[I,7]=oDp:cCodCop

        aData[I,3]:=EJECUTAR("CALCOP",nMtoSug,oRecDiv:nValCam)

      ELSE

        IF aData[I,7]=oRecDiv:cCodMon //  Si cambia la divisa del Cliente debe hacerlo tambien con los intrumentos de caja oDp:cMonedaExt
          aData[I,2]:=oRecDiv:nValCam
        ENDIF

        aData[I,3]:=ROUND(nMtoSug/aData[I,2],2) 

      ENDIF
*/
   NEXT I

   IF oRecDiv:nTotal<0

    nMtoSug:=oRecDiv:nTotal*-1

     FOR I=1 TO LEN(aData)
        aData[I,3]:=oRecDiv:CALSUG(nMtoSug,aData[I,2],aData[I,7])
//        aData[I,3]:=ROUND(nMtoSug/aData[I,2],2) 
     NEXT I

   ENDIF

   FOR I=1 TO LEN(aData)

     IF aData[I,5]>0 .AND. aData[I,oRecDiv:nColPorITG]>0
        aData[I,oRecDiv:nColMtoITG]:=PORCEN(aData[I,5],aData[I,oRecDiv:nColPorITG],2)
     ELSE
        aData[I,oRecDiv:nColMtoITG]:=0
     ENDIF

     IF aData[I,4]>0
      //  aData[I,6]:=aData[I,4]
     ENDIF

   NEXT I

   // no tiene sugerido
   oRecDiv:oBrw:aArrayData:=aData
   oRecDiv:CALIGTF(.T.)

   IF oRecDiv:nTotal=0

     FOR I=1 TO LEN(aData)
        aData[I,3]:=0
     NEXT I

   ENDIF
  
   oRecDiv:oBrw:aArrayData:=aData
   oRecDiv:CALIGTF(.T.)

   IF oRecDiv:nMtoIGTF>0 .AND. ROUND(oRecDiv:nTotal,2)=ROUND(oRecDiv:nMtoIGTF,2)

      nMtoSug:=oRecDiv:nMtoIGTF

      FOR I=1 TO LEN(aData)
        // aData[I,3]:=ROUND(nMtoSug/aData[I,2],2) 
        aData[I,3]:=oRecDiv:CALSUG(nMtoSug,aData[I,2],aData[I,7])
      NEXT I

   ENDIF

   oRecDiv:oBrw:aArrayData:=aData

   oRecDiv:CALIGTF(.T.)

   IF oRecDiv:nTotal<0

     nMtoSug:=oRecDiv:nTotal*-1

     FOR I=1 TO LEN(aData)
       aData[I,3]:=oRecDiv:CALSUG(nMtoSug,aData[I,2],aData[I,7])
//     aData[I,3]:=ROUND(nMtoSug/aData[I,2],2) 
     NEXT I

   ENDIF

   oRecDiv:oBrw:aArrayData:=aData
   oRecDiv:CALIGTF(.T.)

   oRecDiv:oBrw:Refresh(.F.)
   oRecDiv:oBrw:nArrayAt:=nAt
   oRecDiv:oBrw:nRowSel :=nRowSel

   IF ValType(oRecDiv:oBrwR)="O"
     oRecDiv:TOTALRESDIVISA(oRecDiv:oBrw:aArrayData,oRecDiv:oBrwR) // Resumen por Divisa
   ENDIF

   IF ValType(oRecDiv:oBtnSave)="O"
      oRecDiv:oBtnSave:ForWhen(.T.)
   ENDIF

RETURN .T.

FUNCTION PUTMONTO(oCol,uValue,nCol,nAt,lRefresh)
  LOCAL aLine:=oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt]
  LOCAL aTotales:={}
  LOCAL nRowSel :=oRecDiv:oBrw:nRowSel

  DEFAULT lRefresh:=.T.,;
          nAt     :=oRecDiv:oBrw:nArrayAt

  oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,nCol]:=uValue
  oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5   ]:=ROUND(uValue*aLine[2],2)

  IF oRecDiv:nMtoIGTF=oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5]
     oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,11]:=0
  ENDIF


// ? oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,5   ],"ES IGUAL AL MONTO DEL IGTF NO DEBE APLICARLO NUEVAMENTE",oRecDiv:nMtoIGTF
//  oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,10  ]:=uValue-aLine[5]

  oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,oRecDiv:nColSelP]:=(uValue>0)

  oRecDiv:SETSUGERIDO()
  // 15/10/2022  oRecDiv:oBrw:aArrayData:=oRecDiv:CALDIVISA(oRecDiv:oBrw:aArrayData,oRecDiv:oBrw)

RETURN .T.

FUNCTION VALFECHA()

   oRecDiv:nValCam:=EJECUTAR("DPGETVALCAM",oRecDiv:cCodMon,oRecDiv:dFecha) // nValCam
   oRecDiv:oValCam:Refresh(.T.)

   oRecDiv:VALVALCAM()

RETURN .T.

FUNCTION CALTOTALBCO()
RETURN .T.

FUNCTION PUTMTOPAG(nMonto,nCol)
   LOCAL aTotal,oCol,aLines:={},nMtoDif:=0

   DEFAULT nCol:=oRecDiv:nColEdit

   oCol:=oRecDiv:oBrwD:aCols[nCol]

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol  ]:=nMonto

   IF nMonto=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7] .AND. oRecDiv:nValCam=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,6] 

     // Mismo Monto en Dolares
     oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol+1]:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5]

   ELSE

     IF oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,15] 

        oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol+1]:=ROUND(nMonto*oRecDiv:nValCam,2)

     ELSE

        oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,8     ]:=0      // Sin valor Divisa
        oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol+1]:=nMonto // documento no se revaloriza

     ENDIF

  ENDIF

   // diferencia cambiaria
   IF nMonto<>0 .AND. oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,15] .AND. oRecDiv:lDifCambiario

     nMtoDif:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,9]-oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5]
     oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,10    ]:=nMtoDif

   ELSE

     oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,10    ]:=0

   ENDIF

   // Si el pago es parcial, valor cambiario es 0
   IF oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7]<>oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,8]
      oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,10]:=0 // ojo
   ENDIF

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,11]:=!(nMonto=0)

   oRecDiv:oBrwD:DrawLine(.T.)
   aTotal :=ATOTALES(oRecDiv:oBrwD:aArrayData)

   oCol:cFooter      :=FDP(aTotal[nCol],oCol:cEditPicture)
   oRecDiv:oBrwD:RefreshFooters()

   oCol:=oRecDiv:oBrwD:aCols[nCol+1]
   oRecDiv:nMtoDoc:=aTotal[nCol+1]
   oCol:cFooter   :=FDP(aTotal[nCol+1],oCol:cEditPicture)

   oCol:=oRecDiv:oBrwD:aCols[10]
   oCol:cFooter      :=FDP(aTotal[10],oCol:cEditPicture)

   oRecDiv:oBrwD:RefreshFooters()

   oRecDiv:nMontoBs :=oRecDiv:nMtoDoc
   oRecDiv:nMontoUsd:=ROUND(aTotal[8],2) 

   oRecDiv:CALTOTAL()
   // oRecDiv:CALDIVISA()
   oRecDiv:oBrw:aArrayData:=oRecDiv:CALDIVISA(oRecDiv:oBrw:aArrayData,oRecDiv:oBrw)

   oRecDiv:SETSUGERIDO() // 01/03/2023

RETURN .T.

FUNCTION CALTOTAL(lRefresh)
RETURN EJECUTAR("DPRECIBODIV_CALTOTAL",oRecDiv,lRefresh)


/*
// Guardar Recibo
*/
FUNCTION RECGRABAR()

  IF oRecDiv:lCliente
    EJECUTAR("DPRECGRABARCLI",oRecDiv)
  ELSE
    EJECUTAR("DPRECGRABARPRO",oRecDiv)
  ENDIF

  IF ValType(oRecDiv:oFrmLnk)="O" .AND. oRecDiv:oFrmLnk:oWnd:hWnd>0
     oRecDiv:oFrmLnk:BRWREFRESCAR()
  ENDIF

  IF ValType(oRecDiv:bAfterSave)="B"
     EVAL(oRecDiv:bAfterSave)
  ENDIF

  IF ValType(oRecDiv:bAfterSave)="C"
     EVAL(BloqueCod(oRecDiv:bAfterSave))
  ENDIF

RETURN .T.

FUNCTION VERRECIBO(cNumero)
  LOCAL aLine:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt]
  LOCAL lAuto:=.F.,cTipPag:=NIL,cCodSuc:=oDp:cSucursal,cCodigo:=NIL,cRecord:=NIL,lView:=.T.,cSucCli:=NIL,lPagEle:=NIL,cCenCos:=NIL
  
  DEFAULT cNumero:=aLine[20]

  cRecord:="REC_NUMERO"+GetWhere("=",cNumero)

// ? cRecord

  EJECUTAR("DPRECIBOSCLIX")
//,lAuto,cTipPag,cCodSuc,cCodigo,cRecord,lView,cSucCli,lPagEle,cCenCos)
 
RETURN NIL

FUNCTION CALIGTF(lRefresh)

  DEFAULT lRefresh:=.F.

  oRecDiv:CALTOTAL()
  
RETURN .T.
/*
// REALIZA CALCULO POR DIVISA
*/
FUNCTION TOTALRESDIVISA(aDataP,oBrwR)
  LOCAL aDataR:={},cCodMon,I,nAt,aData,aTotal,nRowSel,oCol

  DEFAULT aDataP:=oRecDiv:oBrw:aArrayData

  FOR I=1 TO LEN(aDataP)

    cCodMon:=aDataP[I,oRecDiv:nColCodMon]
    nAt    :=ASCAN(aDataR,{|a,n| a[1]=cCodMon})

    IF nAt=0
       AADD(aDataR,{cCodMon,aDataP[I,1],0,aDataP[I,2],0,0})
    ENDIF

  NEXT I

  // TOTALIZAR

  
  FOR I=1 TO LEN(aDataR)

    aData  :=ACLONE(aDataP)
    cCodMon:=aDataR[I,1]
    ADEPURA(aData,{|a,n|a[oRecDiv:nColCodMon]<>cCodMon})
    aTotal :=ATOTALES(aData)
    aDataR[I,3]:=aTotal[4]
    aDataR[I,5]:=aDataR[I,4]*aDataR[I,3]
   // aDataR[I,6]:=aDataR[I,5]/oRecDiv:nValCam

  NEXT I

  IF ValType(oBrwR)="O"
     aTotal:=ATOTALES(aDataR)

     nRowSel:=oBrwR:nRowSel
     nAt    :=oBrwR:nArrayAt

     oBrwR:aArrayData:=ACLONE(aDataR)
     // oBrwR:GoTop()
     oBrwR:Refresh(.F.)
     oBrwR:nRowSel :=nRowSel
     oBrwR:nArrayAt:=nAt

     oCol:=oBrwR:aCols[5]
     oCol:cFooter      :=FDP(aTotal[5],"999,999,999.99")

     oCol:=oBrwR:aCols[6]
     oCol:cFooter      :=FDP(aTotal[6],"999,999,999.99")

     oBrwR:RefreshFooters()

  ENDIF


 
RETURN aDataR

FUNCTION VALCODCAJA()
 
  oRecDiv:oNombreCaja:Refresh(.T.)

  IF Empty(oRecDiv:cCODCAJA)
     RETURN .F.
  ENDIF

  IF !ISSQLFIND("DPCAJA","CAJ_CODIGO"+GetWhere("=",oRecDiv:cCODCAJA))
     oRecDiv:lValCODCAJA:=.F.
     EVAL(oRecDiv:oCODCAJA:bAction)
     RETURN .F.
  ENDIF

  oRecDiv:oNombreCaja:Refresh(.T.)
  oRecDiv:lValCODCAJA:=.T.


RETURN .T.

FUNCTION LBXCAJA()
   LOCAL cFileLbx:="DPCAJA"

   oDpLbx:=DpLbx(cFileLbx,NIL,"CAJ_ACTIVO=1",NIL,NIL,NIL,NIL,NIL,NIL,oRecDiv:oCODCAJA)
   oDpLbx:GetValue("CAJ_CODIGO",oRecDiv:oCODCAJA)

RETURN .T.

FUNCTION CALRESIDUO()
  LOCAL nAt,I,nRowSel,nTotal,aTotal,oCol

  oRecDiv:nResiduo:=0

//  oDp:oFrameSetText("CALRESIDUO"+LSTR(oRecDiv:nTotal)+" nResiduo")

  IF ABS(oRecDiv:nTotal)>.02
     RETURN .F.
  ENDIF

  IF !ValType(oRecDiv:oBrw)="O"
     RETURN .F.
  ENDIF

RETURN .T.

/*
// Agrega el IGTF como pago con la misma moneda
*/
FUNCTION ADDIGTF(nAt,lRefresh)
   LOCAL aLine,nMtoIGTF,cCodMon,nPos

   DEFAULT nAt     :=oRecDiv:oBrw:nArrayAt,;
           lRefresh:=.T.

   aLine   :=ACLONE(oRecDiv:oBrw:aArrayData[nAt])

   nMtoIGTF:=aLine[oRecDiv:nColMtoITG] // monto del IGTF
   cCodMon :=aLine[1]
   nPos    :=ASCAN(oRecDiv:oBrw:aArrayData,{|a,n| a[1]=cCodMon .AND. a[5]=nMtoIGTF})

   // Desmarcar pago con IGTF
   IF !aLine[oRecDiv:nColSelP] .AND. nPos=0
	 RETURN .F.
   ENDIF

   IF nPos>0

      // Eliminar el IGTF
      ARREDUCE(oRecDiv:oBrw:aArrayData,nPos)

   ELSE

      aLine[05]:=aLine[oRecDiv:nColMtoITG]

      //31/05/2024 aLine[04]:=ROUND(DIV(aLine[05],aLine[02]),2)
      // ? "OJO AQUI CALCULA EL IGTF CON LA MISMA MONEDA",aLine[oRecDiv:nColMtoITG],aLine[02],aLine[07]

      aLine[04]:=oRecDiv:CALSUG(aLine[oRecDiv:nColMtoITG],aLine[02],aLine[07])

// ?  aLine[04],"aqui es"
// nMontoSug,nMoneda,cCodMon
     
	 //aLine[06]:=aLine[04]
      aLine[oRecDiv:nColMtoITG]:=0
      aLine[oRecDiv:nColPorITG]:=0

      // AADD(oRecDiv:oBrw:aArrayData,aLine)

      AINSERTAR(oRecDiv:oBrw:aArrayData,nAt+1,aLine)

      nAt:=nAt+1
      // oRecDiv:oBrw:nArrayAt:=nAt+1
      // oRecDiv:oBrw:DrawLine(.T.)

    ENDIF

    IF lRefresh
      oRecDiv:oBrw:Refresh(.F.)
      oRecDiv:oBrw:nArrayAt:=nAt
      oRecDiv:CALTOTAL()
    ENDIF

RETURN .t.

FUNCTION SETCAJA()
  LOCAL nAt    :=oRecDiv:oBrw:nArrayAt
  LOCAL nRowSel:=oRecDiv:oBrw:nRowSel
  LOCAL aData  :=oRecDiv:oBrw:aArrayData


  // Apagar, Copia todos Componentes de Caja
  IF !oRecDiv:lCajaAct
     oRecDiv:aCajaAct:={}
     AEVAL(  aData,{|a,n| IF(a[oRecDiv:nColCajBco]="CAJ" .AND. a[5]=0,AADD(oRecDiv:aCajaAct,ACLONE(a)),NIL)})
     ADEPURA(aData,{|a,n| a[oRecDiv:nColCajBco]="CAJ" .AND. a[5]=0})
     nAt:=MIN(nAt,LEN(aData))
  ELSE
     // AEVAL(oRecDiv:aCajaAct,{|a,n| AADD(aData,a)})
     AEVAL(aData,{|a,n| AADD(oRecDiv:aCajaAct,a)})
     aData:=oRecDiv:aCajaAct
  ENDIF

  oRecDiv:oBrw:aArrayData:=ACLONE(aData)
  oRecDiv:oBrw:nArrayAt:=1
  oRecDiv:oBrw:nRowSel :=1
  oRecDiv:oBrw:Refresh(.T.)

  oRecDiv:oBancoAct:ForWhen(.T.)
  oRecDiv:oCajaAct:ForWhen(.T.)

RETURN .T.

FUNCTION SETBANCO()
  LOCAL nAt    :=oRecDiv:oBrw:nArrayAt
  LOCAL nRowSel:=oRecDiv:oBrw:nRowSel
  LOCAL aData  :=oRecDiv:oBrw:aArrayData

  // Ambos no pueden estar Vacio
//  IF !oRecDiv:lBancoAct .AND.   !oRecDiv:lCajaAct
//     oRecDiv:lCajaAct:=.T.
//   oRecDiv:SETCAJA()
//  ENDIF
 
  // Apagar, Copia todos Componentes de Banco
  IF !oRecDiv:lBancoAct
     oRecDiv:aBancoAct:={}
     AEVAL(  aData,{|a,n| IF(a[oRecDiv:nColCajBco]="BCO" .AND. a[5]=0,AADD(oRecDiv:aBancoAct,ACLONE(a)),NIL)})
     ADEPURA(aData,{|a,n| a[oRecDiv:nColCajBco]="BCO" .AND. a[5]=0})
     nAt:=MIN(nAt,LEN(aData))
  ELSE
     // AEVAL(oRecDiv:aBancoAct,{|a,n| AADD(aData,a)})
     AEVAL(aData,{|a,n| AADD(oRecDiv:aBancoAct,a)})
     aData:=oRecDiv:aBancoAct
  ENDIF

  oRecDiv:oBrw:aArrayData:=ACLONE(aData)
  oRecDiv:oBrw:nArrayAt:=1
  oRecDiv:oBrw:nRowSel :=1
  oRecDiv:oBrw:Refresh(.T.)

  oRecDiv:oBancoAct:ForWhen(.T.)
  oRecDiv:oCajaAct:ForWhen(.T.)


RETURN .T.

/*
// 
*/
FUNCTION RUNCLICKR()

  IF oRecDiv:oBrwR:nColSel>=1 .OR. oRecDiv:oBrwR:nColSel<=3
     oRecDiv:SETMONEDA()
     RETURN .F.
  ENDIF

RETURN .T.


/*
// Filtrar por Moneda
*/
FUNCTION SETMONEDA(aData)
  LOCAL oCol    :=oRecDiv:oBrw:aCols[oRecDiv:nColCodMon]
  LOCAL uValue  :=oRecDiv:oBrwR:aArrayData[oRecDiv:oBrwR:nArrayAt,1]
  LOCAL nLastKey:=13
  LOCAL aPagos  :=ACLONE(oRecDiv:oBrw:aArrayData) // Copia de los Pagos para no perder los datos
  LOCAL I,nAt

  ADEPURA(aPagos,{|a,n| !a[oRecDiv:nColSelP]})

  oRecDiv:oBrw:nColSel:=oRecDiv:nColCodMon

  IF oRecDiv:cMonedaSel=uValue
     uValue:=CTOEMPTY(uValue)
  ENDIF

  EJECUTAR("BRWFILTER",oCol,uValue,nLastKey,oCol:CARGO)

  // Cuando se bloquean con una sola moneda, necesario restaurar todas las monedas

  IF !Empty(aData)
     oRecDiv:oBrw:aArrayData:=aData
  ENDIF

  FOR I=1 TO LEN(aPagos)
    // remover del arreglo para que no se repitan
    nAt:=ASCAN(oRecDiv:oBrw:aArrayData,{|a,n| a[1]=aPagos[I,1] .AND. a[8]=aPagos[I,8] .AND. a[9]=aPagos[I,9]})
    IF nAt>0
       ARREDUCE(oRecDiv:oBrw:aArrayData,nAt)
    ENDIF
  NEXT I

  AEVAL(aPagos,{|a,n| AINSERTAR(oRecDiv:oBrw:aArrayData,1,a)})

  IF Empty(uValue) .AND. LEN(oRecDiv:oBrwR:aArrayData)=1
     oRecDiv:oBrwR:aArrayData:=TOTALRESDIVISA(oRecDiv:oBrw:aArrayData,NIL)
     oRecDiv:oBrwR:Refresh(.T.)
     oRecDiv:oBrwR:Gotop(.T.)
//   oRecDiv:SETSUGERIDO()       
  ENDIF

  oRecDiv:SETSUGERIDO()       
  
  oRecDiv:oBrw:Refresh(.F.)

  oRecDiv:cMonedaSel:=uValue

RETURN .T.

/*
// Filtrar por Moneda
*/
FUNCTION SOLOEFECTIVO()
  LOCAL oCol    :=oRecDiv:oBrw:aCols[oRecDiv:nColIsMon]
  LOCAL nLastKey:=13
  LOCAL uValue  :=IF(oRecDiv:lSoloEfectivo,.T.	,"")
  LOCAL aPagos  :=ACLONE(oRecDiv:oBrw:aArrayData) // Copia de los Pagos para no perder los datos
  LOCAL I,nAt

  ADEPURA(aPagos,{|a,n| !a[oRecDiv:nColSelP]})

  EJECUTAR("BRWFILTER",oCol,uValue,nLastKey,oCol:CARGO,oRecDiv:nColIsMon)

  FOR I=1 TO LEN(aPagos)
    // remover del arreglo para que no se repitan
    nAt:=ASCAN(oRecDiv:oBrw:aArrayData,{|a,n| a[1]=aPagos[I,1] .AND. a[8]=aPagos[I,8] .AND. a[9]=aPagos[I,9]})
    IF nAt>0
       ARREDUCE(oRecDiv:oBrw:aArrayData,nAt)
    ENDIF
  NEXT I

  AEVAL(aPagos,{|a,n| AINSERTAR(oRecDiv:oBrw:aArrayData,1,a)})

  oRecDiv:SETSUGERIDO() 

RETURN .T.

/*
// Generar Cuotas
*/
FUNCTION GENCUOTAS()

   EJECUTAR("BRCSCLIRESCUO",NIL,NIL,NIL,NIL,NIL,NIL,oRecDiv:cCodigo,.T.,NIL,oRecDiv:dFecha,oRecDiv:nValCam,oRecDiv)

RETURN .T.

FUNCTION RELOADDOCS(lRefresh)
  LOCAL aDataD:={},aTipDoc:=oRecDiv:aTipDoc,cWhereNot:=""
  LOCAL aData :=oRecDiv:oBrwD:aArrayData,aLine:={}

  DEFAULT lRefresh:=.F.

  AEVAL(aData,{|a,n| cWhereNot:=cWhereNot+IF(Empty(cWhereNot),""," OR ")+;
                     " (DOC_TIPDOC"+GetWhere("=",a[1])+" AND DOC_NUMERO"+GetWhere("=",a[3])+")" })

  cWhereNot:=IF(Empty(cWhereNot),""," AND NOT ("+cWhereNot+")")


//  ? cWhereNot,"cWhereNot"

  IF oRecDiv:lCliente
    aDataD:=EJECUTAR("DPRECIBODIV_DOCCLI",oRecDiv:cCodigo,aTipDoc,cWhereNot,oRecDiv:lAnticipo,oRecDiv:lPagoC)
  ELSE
    aDataD:=EJECUTAR("DPRECIBODIV_DOCPRO",oRecDiv:cCodigo,aTipDoc,cWhereNot,oRecDiv:lAnticipo,oRecDiv:lPagoC)
  ENDIF

  //  ViewArray(aData)
  //  aDataD:=oRecDiv:LEERDOCCLI(oRecDiv:cCodigo,aTipDoc,cWhereNot)
  ADEPURA(aDataD,{|a,n| Empty(a[1])})

  IF EMPTY(aData) .AND. oRecDiv:lPagoC
     aLine:=ACLONE(oRecDiv:oBrwD:aArrayData,1)
     aData:={}
     AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(a[n])})
     AADD(aData,aLine)
  ENDIF

  IF oRecDiv:lPagoC

     // Debe resetar los pagos
     AEVAL(oRecDiv:oBrw:aArrayData,{|a,n| oRecDiv:oBrw:aArrayData[n,5               ]:=0,;
                                          oRecDiv:oBrw:aArrayData[n,4               ]:=0,;
                                          oRecDiv:oBrw:aArrayData[n,oRecDiv:nColSelP]:=.F.})
     oRecDiv:oBrw:Refresh(.F.)

  ENDIF

  IF LEN(aDataD)>0

    ADEPURA(oRecDiv:oBrwD:aArrayData,{|a,n| Empty(a[1])}) // Remover registro vacio

    IF !lRefresh

       AEVAL(aDataD,{|a,n| aDataD[n,11]:=.T. ,;
                           aDataD[n,08]:=a[7],;
                           aDataD[n,09]:=a[5]})
    ENDIF

    IF oRecDiv:lPagoC
       oRecDiv:oBrwD:aArrayData:={}
    ENDIF

    AEVAL(aDataD,{|a,n| AADD(oRecDiv:oBrwD:aArrayData,a)})
    oRecDiv:oBrwD:Refresh(.F.)
    oRecDiv:oBrwD:GoTop()

    EJECUTAR("BRWCALTOTALES",oRecDiv:oBrwD,.F.)

    oRecDiv:oBrw:aArrayData:=oRecDiv:CALDIVISA(oRecDiv:oBrw:aArrayData,oRecDiv:oBrw)

    oRecDiv:SETSUGERIDO()
    oRecDiv:CALTOTAL()

  ENDIF

  IF Empty(aDataD) .AND. lRefresh
     oRecDiv:oBtnRefresh:MsgErr("No hay Documentos para Recargar","Refrescamiento",240,120)
     DPFOCUS(oRecDiv:oBrwD)
  ENDIF

RETURN .T.
/*
// Debe recalcular los documentos pagados
*/
FUNCTION VALVALCAM()
  LOCAL I,nCol:=8,nMonto

  FOR I=1 TO LEN(oRecDiv:oBrwD:aArrayData)
 
   nMonto:=oRecDiv:oBrwD:aArrayData[I,nCol]

   IF nMonto<>0

     IF nMonto=oRecDiv:oBrwD:aArrayData[I,7] .AND. oRecDiv:nValCam=oRecDiv:oBrwD:aArrayData[I,6] 
       oRecDiv:oBrwD:aArrayData[I,nCol+1]:=oRecDiv:oBrwD:aArrayData[I,5]
     ELSE
       oRecDiv:oBrwD:aArrayData[I,nCol+1]:=ROUND(nMonto*oRecDiv:nValCam,2)
     ENDIF

    ENDIF

  NEXT I

  oRecDiv:oBrwD:Refresh(.F.)
  EJECUTAR("BRWCALTOTALES",oRecDiv:oBrwD)
  oRecDiv:CALTOTAL(.T.)
  oRecDiv:oBrw:aArrayData:=oRecDiv:CALDIVISA(oRecDiv:oBrw:aArrayData,oRecDiv:oBrw)
  oRecDiv:SETSUGERIDO()

RETURN .T.
/*
// Modificar el valor de la Divisa en el Documento de Origen
*/
FUNCTION PUTMTODIV(nMonto,nCol)
   LOCAL aTotal,oCol,aLines:={},nMtoDif:=0

   DEFAULT nCol:=6

   nMonto:=IF(nMonto<=0,1,nMonto)
   oCol:=oRecDiv:oBrwD:aCols[nCol]

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol  ]:=nMonto
   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol+1]:=ROUND(nMonto/oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5],2)

   oRecDiv:oBrwD:Drawline(.t.)
   oRecDiv:VALVALCAM()

RETURN .T.


/*
// Modificar el diferencial Cambiario
*/
FUNCTION PUTDIFCAM(nMonto,nCol)
   LOCAL aTotal,oCol,aLines:={},nMtoDif:=0

   DEFAULT nCol:=6

   //nMonto:=IF(nMonto<=0,0,nMonto)
   oCol:=oRecDiv:oBrwD:aCols[nCol]

   // no está Activo
   IF !oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,11]
      oRecDiv:oBrwD:nColSel=11 
      oRecDiv:RUNCLICKDOC()
      oRecDiv:oBrwD:nColSel=10
   ENDIF

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol    ]:=nMonto
   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,09      ]:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5]-nMonto
   oRecDiv:oBrwD:Drawline(.t.)
   oRecDiv:SETSUGERIDO()

// oRecDiv:VALVALCAM()

RETURN .T.

/*
// Al finalizar recibo debe resetear
*/
FUNCTION RECRESET()
RETURN EJECUTAR("DPRECIBODIV_RESET",oRecDiv)

/*
// Valida Fecha de Registro debe ser Superior a la Fecha de Registro
*/
FUNCTION VALFCHREG()
RETURN .T.

/*
// Calcular IGTF 
*/
FUNCTION IGTFMISMADIVISA()
  LOCAL I

  ? oRecDiv:lGTFMismaDiv


RETURN .T.

/*
// Modificar el monto impreso de la factura columna 7
*/
FUNCTION PUTDIVORG(nMonto,nCol)
   LOCAL aTotal,oCol,aLine:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt],nMtoDif:=0,cSql
   LOCAL nValCam:=0 // Diferencia Cambiaria Nueva.
   LOCAL oDb    :=OpenOdbc(oDp:cDsnData)
   LOCAL cWhere :="DOC_CODSUC"+GetWhere("=",oRecDiv:cCodSuc)+" AND "+;
                  "DOC_TIPDOC"+GetWhere("=",aLine[1]       )+" AND "+;
                  "DOC_NUMERO"+GetWhere("=",aLine[3]       )+" AND "+;
                  "DOC_CODIGO"+GetWhere("=",oRecDiv:cCodigo)+" AND "+;
                  "DOC_TIPTRA"+GetWhere("=","D"            )


   IF oRecDiv:lAnticipo
     nValCam:=oRecDiv:nValCam
   ELSE
     nValCam:=aLine[05]/nMonto
   ENDIF

   DEFAULT nCol:=7

   //nMonto:=IF(nMonto<=0,0,nMonto)
   oCol:=oRecDiv:oBrwD:aCols[nCol]

   // no está Activo
   IF !oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,11]
      oRecDiv:oBrwD:nColSel=11 
      oRecDiv:RUNCLICKDOC()
      oRecDiv:oBrwD:nColSel=7
   ENDIF

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,6     ]:=nValCam
   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol  ]:=nMonto
   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,nCol+1]:=nMonto

   IF oRecDiv:lAnticipo
     oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,09]:=ROUND(nValCam*nMonto,2)
     oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,11]:=.T.
   ENDIF

   oRecDiv:oBrwD:Drawline(.t.)

   oRecDiv:CALTOTAL()
   oRecDiv:SETSUGERIDO()

   cSql:="UPDATE DPDOCCLI SET DOC_VALCAM="+LSTR(nValCam,19,6)+" WHERE "+cWhere
   
   oDb:EXECUTE(cSql)

RETURN .T.

/*
// Desactivar revalorización de documentos
*/
FUNCTION VALDIFCAMBIARIO()
  LOCAL I,oBrwD:=oRecDiv:oBrwD,nAt:=oBrwD:nArrayAt,nRowSel:=oBrwD:nRowSel
  LOCAL aTotal:={}

  IF !oRecDiv:lDifCambiario

     AEVAL(oBrwD:aArrayData,{|a,n| oBrwD:aArrayData[n,10]:=0})

  ELSE

     AEVAL(oBrwD:aArrayData,{|a,n| oBrwD:aArrayData[n,10]:=IF(!a[11],a[10],oBrwD:aArrayData[n,9]-oBrwD:aArrayData[n,5])})

  ENDIF

  aTotal:=ATOTALES(oBrwD:aArrayData)
  oBrwD:aCols[10]:cFooter:=FDP(aTotal[10],"999,999,999,999,999.99")
  oBrwD:Refresh(.T.)

  oBrwD:nRowSel :=nRowSel
  oBrwD:nArrayAt:=nAt
  oRecDiv:CALTOTAL()
  oRecDiv:SETSUGERIDO()
   
RETURN .T.

/*
// Otros Pagos, valida Cuenta de Egreso
*/
FUNCTION VALCTAEGRE(uValue,lNext,oRecDiv)
RETURN EJECUTAR("DPRECIBODIV_CTAEGR",uValue,lNext,oRecDiv)

// Editar Cuenta de Egreso
FUNCTION EDITCTAEGRE()
   LOCAL oBrw  :=oRecDiv:oBrwD,oLbx
   LOCAL uValue:=oBrw:aArrayData[oBrw:nArrayAt,1]

   oLbx:=DpLbx("DPCTAEGRESO.LBX",NIL,NIL,NIL,NIL,NIL,NIL,NIL,NIL) // ,oBrw)
   oLbx:GetValue("CEG_CODIGO",oBrw:aCols[1],,,uValue)
   oRecDiv:lAcction  :=.T.

   SysRefresh(.t.)

RETURN uValue

// Editar Cuenta de Egreso
FUNCTION EDITCENCOS()
   LOCAL oBrw  :=oRecDiv:oBrwD,oLbx
   LOCAL uValue:=oBrw:aArrayData[oBrw:nArrayAt,2]

   oLbx:=DpLbx("DPCENCOSACT.LBX")
   oLbx:GetValue("CEN_CODIGO",oBrw:aCols[2],,,uValue)
   oRecDiv:lAcction  :=.T.

   SysRefresh(.t.)

RETURN uValue

FUNCTION VALCENCOSOPA(uValue,lNext)
   DEFAULT lNext:=.T.

   IF oRecDiv:lAcction 
      oRecDiv:lAcction  :=.F.
      RETURN uValue
   ENDIF 

   IF Empty(uValue) .OR. !SQLGET("DPCENCOS","CEN_CODIGO","CEN_CODIGO"+GetWhere("=",uValue))==uValue
      oRecDiv:lAcction  :=.T.
      oRecDiv:EDITCENCOS()
      RETURN .F.
   ENDIF

   IF !lNext
      RETURN .T.
   ENDIF

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,2]:=uValue
   oRecDiv:oBrwD:SelectCol(3)

RETURN uValue

// Valida IVA
FUNCTION VALIVA(nIva)
   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,6]:=nIva
   EJECUTAR("DPRECIBODIV_OPAGRABA",oRecDiv)
RETURN .T.

FUNCTION VALCENCOS()
 
  oRecDiv:oNombreCenCos:Refresh(.T.)

  IF Empty(oRecDiv:cCenCos)
     RETURN .F.
  ENDIF

  IF !ISSQLFIND("DPCENCOS","CEN_CODIGO"+GetWhere("=",oRecDiv:cCenCos))
     oRecDiv:lValCenCos:=.F.
     EVAL(oRecDiv:oCenCos:bAction)
     RETURN .F.
  ENDIF

  oRecDiv:oNombreCenCos:Refresh(.T.)
  oRecDiv:lValCenCos:=.T.

RETURN .T.

FUNCTION LBXCENCOS()
   LOCAL cFileLbx:="DPCENCOS"

   oDpLbx:=DpLbx(cFileLbx,NIL,"CEN_ACTIVO=1",NIL,NIL,NIL,NIL,NIL,NIL,oRecDiv:oCenCos)
   oDpLbx:GetValue("CEN_CODIGO",oRecDiv:oCenCos)

RETURN .T.


FUNCTION VALCODVEN()
 
  oRecDiv:oNombreVend:Refresh(.T.)

  IF Empty(oRecDiv:cCodVen)
     RETURN .F.
  ENDIF

  IF !ISSQLFIND("DPCODVEN","VEN_CODIGO"+GetWhere("=",oRecDiv:cCodVen))
     oRecDiv:lValCosVen:=.F.
     EVAL(oRecDiv:oCodVen:bAction)
     RETURN .F.
  ENDIF

  oRecDiv:oNombreVend:Refresh(.T.)
  oRecDiv:lValCodVen:=.T.

RETURN .T.

FUNCTION LBXCODVEN()
   LOCAL cFileLbx:="DPVENDEDOR"

   oDpLbx:=DpLbx(cFileLbx,NIL,"LEFT(VEN_SITUAC,1)"+GetWhere("=","A"),NIL,NIL,NIL,NIL,NIL,NIL,oRecDiv:oCodVen)
   oDpLbx:GetValue("VEN_CODIGO",oRecDiv:oCodVen)

RETURN .T.

// oRecDiv:cCodigo,oRecDiv:aTipDoc,NIL,oRecDiv:lAnticipo,oRecDiv:lPagoC,oRecDiv:oBrwD)
FUNCTION LEERDOCCLI(cCodigo,aTipDoc)

 oRecDiv:lCliente:=.T.
 oRecDiv:RELOADDOCS(.T.)

RETURN .T.

FUNCTION PUTREFERENCIA(oCol,nValue,nCol)

   oRecDiv:oBrw:aArrayData[oRecDiv:oBrw:nArrayAt,nCol]:=nValue
   oRecDiv:oBrw:DrawLine(.T.)

RETURN .T.

/*
// Todos los documento son pagados automaticamente, caso del Ticket del Punto de venta.
*/
FUNCTION SETAUTOSELDOC()
  
   AEVAL(oRecDiv:oBrwD:aArrayData,{|a,n| oRecDiv:oBrwD:aArrayData[n,11]:=.T.,;
                                         oRecDiv:oBrwD:aArrayData[n,08]:=a[7],; 
                                         oRecDiv:oBrwD:aArrayData[n,09]:=a[5]}) 

   oRecDiv:CALTOTAL()
   oRecDiv:SETSUGERIDO()

RETURN .T.

// EOF
