// Programa   : DPRECIBODIVANT
// Fecha/Hora : 03/11/2022 11:33:30
// Propósito  : Crear Documento Anticipo desde Recibo de Ingreso dolarizado
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV 
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cRecibo,nMonto)
    LOCAL oRecibo,cNumero,cWhere,cTipDoc:="ANT"

    DEFAULT cCodSuc:=oDp:cSucursal,;
            cRecibo:=SQLGETMAX("DPRECIBOSCLI","REC_NUMERO","REC_CODSUC"+GetWhere("=",cCodSuc)+" AND REC_TIPPAG"+GetWhere("=","A")),;
            nMonto :=oRecibo:REC_MONTO

    oRecibo:=OpenTable("SELECT * FROM DPRECIBOSCLI WHERE REC_CODSUC"+GetWhere("=",cCodSuc)+;
                                                   " AND REC_NUMERO"+GetWhere("=",cRecibo),.T.)
//    oRecibo:Browse()
    oRecibo:End()
                           
//  cNumero:=EJECUTAR("DPDOCCLICREA",NIL,"ANT",cRecibo,oRecibo:REC_CODIGO,oRecibo:REC_FECHA,oRecibo:REC_CODMON,"V",NIL,nMonto,0,oRecibo:REC_VALCAM,oRecibo:REC_FECHA)
    cNumero:=EJECUTAR("DPDOCCLICREA",NIL,"ANT",cRecibo,oRecibo:REC_CODIGO,oRecibo:REC_FCHREG,oRecibo:REC_CODMON,"V",NIL,nMonto,0,oRecibo:REC_VALCAM,oRecibo:REC_FECHA)


    cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
            "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
            "DOC_TIPTRA"+GetWhere("=","D"    )

    SQLUPDATE("DPDOCCLI",{"DOC_DOCORG","DOC_VALCAM","DOC_NETO","DOC_CODMON","DOC_RECNUM"},;
                         {"R"         ,oRecibo:REC_VALCAM,nMonto,oRecibo:REC_CODMON,cRecibo},cWhere)

RETURN .T.
// EOF
