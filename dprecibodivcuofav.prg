// Programa   : DPRECIBODIVCUOFAV
// Fecha/Hora : 20/09/2022 19:48:22
// Propósito  : Generar Facturas desde Cuotas Facturadas
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cRecibo,cTipDoc,cTipDes,cSerie)
    LOCAL aNumDoc:={},cNumero,dFecha,lReset:=.F.,cWhere,nMtoPag:=0,nMtoDif:=0,oTableO,oTableD,cWhereD,oDb:=OpenOdbc(oDp:cDsnData)
    LOCAL cAplOrg:="V",cImpFis:=""

    DEFAULT cCodSuc:=oDp:cSucursal,;
            cTipDoc:="CUO",;
            cRecibo:=SQLGET("DPDOCCLI","DOC_RECNUM","DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","P")),;
            cTipDes:="FAV"

    IF Empty(cSerie)
      cSerie:=SQLGET("dptipdoccli","SFI_LETRA","INNER JOIN dpseriefiscal ON TDC_SERIEF=SFI_MODELO  WHERE TDC_TIPO"+GetWhere("=",cTipDes))
    ENDIF

// ? cSerie,"cSerie"

/*
    IF Empty(cSerie)
      cSerie :=SQLGET("DPSERIEFISCAL","SFI_LETRA,SFI_IMPFIS","SFI_PCNAME"+GetWhere("=",oDp:cPcName))
      cAplOrg:="P" // punto de Venta, ademas de la impresora fiscal debe generar un ticket
    ENDIF

    IF Empty(cSerie)
      cSerie:=SQLGET("dptipdoccli","SFI_LETRA","INNER JOIN dpseriefiscal ON TDC_SERIEF=SFI_MODELO  WHERE TDC_TIPO"+GetWhere("=",cTipDes))
    ENDIF

    cImpFis:=SQLGET("DPSERIEFISCAL","SFI_IMPFIS","SFI_LETRA"+GetWhere("=",cSerie))
    cImpFis:=ALLTRIM(UPPER(cImpFis))

    IF !"NIN"$cImpFis .AND. !Empty(cImpFis)
       cTipDes:="TIK"
    ENDIF
*/

//   ? cSerie,"tiene impresora fiscal",cImpFis,"impresora fiscal",cImpFis,"cImpFis"

    aNumDoc:=ATABLE("SELECT DOC_NUMERO FROM DPDOCCLI WHERE DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_RECNUM"+GetWhere("=",cRecibo)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_TIPTRA"+GetWhere("=","P"))

// ? LEN(aNumDoc),CLPCOPY(oDp:cSql)

    IF Empty(aNumDoc)
       RETURN ""
    ENDIF

    oDb:EXECUTE("UPDATE DPTIPDOCCLI SET TDC_IMPTOT=1,TDC_AUTIMP=1 WHERE TDC_TIPO"+GetWhere("=",cTipDoc))

    cWhereD:=GetWhereOr("DOC_NUMERO",aNumDoc)

    dFecha :=SQLGET("DPRECIBOSCLI","REC_FECHA","REC_CODSUC"+GetWhere("=",cCodSuc)+" AND REC_NUMERO"+GetWhere("=",cRecibo))

    cNumero:=EJECUTAR("DPDOCCLIGENDOC",cCodSuc,cTipDoc,aNumDoc,cTipDes,lReset,dFecha,.F.)

    cNumero:=IF(ValType(cNumero)="C",cNumero,oDp:cNumero)


    // ? cNumero,"cNumero,creado"
    // Desactiva Todas las cuotas, ahora debe crear la diferencia cambiaria.

    cWhere :="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
             "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+cWhereD

    SQLUPDATE("DPDOCCLI","DOC_CXC",0,cWhere) // Quita el estatus de CxC

    nMtoPag:=SQLGET("DPDOCCLI","SUM(DOC_NETO),SUM(DOC_MTOCOM)",cWhere+" AND DOC_TIPTRA"+GetWhere("=","P"))
    nMtoDif:=DPSQLROW(2)

//   EJECUTAR("DPDOCCLIIMP",cCodSuc,cTipDes,NIL,cNumero,.T.,NIL,NIL,NIL,"V")

    oTableO:=OpenTable("SELECT * FROM DPDOCCLI WHERE DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDes)+" AND DOC_NUMERO"+GetWhere("=",cNumero)+" AND DOC_TIPTRA"+GetWhere("=","D"),.T.)
 
    // Colocar la Serie FISCAL
    IF Empty(cSerie) .OR. "NIN"$UPPER(cSerie)
      cSerie:=SQLGET("dptipdoccli","SFI_LETRA","INNER JOIN dpseriefiscal ON TDC_SERIEF=SFI_MODELO  WHERE TDC_TIPO"+GetWhere("=",cTipDes))
    ENDIF

// ? cSerie,"cSerie será grabada"

    SQLUPDATE("DPDOCCLI",{"DOC_SERFIS","DOC_DOCORG"},{cSerie,cAplOrg},oTableO:cWhere)
    oTableD:=OpenTable("SELECT * FROM DPDOCCLI",.F.)
   
    AEVAL(oTableO:aFields,{|a,n| oTableD:FieldPut(n,oTableO:FieldGet(n))})
    oTableD:Replace("DOC_TIPTRA","P")
    oTableD:Replace("DOC_CXC"   ,-1 )
    oTableD:Replace("DOC_SERFIS",cSerie )
//  oTableD:Replace("DOC_NETO"  ,nMtoPag)
//  oTableD:Replace("DOC_MTOCOM",nMtoDif)
//   oTableO:DOC_NETO,nMtoPag,"MONTO NETO"

    oTableD:Commit("")
    oTableD:End()
    oTableO:End()

// ? "cNumero",cNumero,"cTipDes",cTipDes

RETURN cNumero
// EOF
