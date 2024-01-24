// Programa   : DPRECIBODIVANTPRO
// Fecha/Hora : 03/11/2022 11:33:30
// Propósito  : Crear Documento Anticipo en Proveedor desde Recibo de Ingreso dolarizado
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV 
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cRecibo,nMonto)
    LOCAL oRecibo,cNumero,cWhere,cTipDoc:="ANT"

    DEFAULT cCodSuc:=oDp:cSucursal,;
            cRecibo:=SQLGETMAX("DPCBTEPAGO","PAG_NUMERO","PAG_CODSUC"+GetWhere("=",cCodSuc)+" AND PAG_TIPPAG"+GetWhere("=","A")),;
            nMonto :=oRecibo:PAG_MONTO

    oRecibo:=OpenTable("SELECT * FROM DPCBTEPAGO WHERE PAG_CODSUC"+GetWhere("=",cCodSuc)+;
                                                   " AND PAG_NUMERO"+GetWhere("=",cRecibo),.T.)
//    oRecibo:Browse()
    oRecibo:End()
                           
    cNumero:=EJECUTAR("DPDOCPROCREA",NIL,"ANT",cRecibo,NIL,oRecibo:PAG_CODIGO,oRecibo:PAG_FECHA,oRecibo:PAG_CODMON,"C",NIL,nMonto,0,oRecibo:PAG_VALCAM,oRecibo:PAG_FECHA)
//  cNumero:=EJECUTAR("DPDOCPROCREA",oTable:LBC_CODSUC,oTable:LBC_TIPDOC,oTable:LBC_NUMFAC,oTable:LBC_NUMFIS,cCodPro           ,oTable:LBC_FCHDEC,oDp:cMonedaExt,cOrg,oTable:LBC_CENCOS,oTable:LBC_BASIMP,oTable:LBC_MTOIVA,oTable:LBC_VALCAM,dFchDec)

    cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
            "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
            "DOC_TIPTRA"+GetWhere("=","D"    )

    SQLUPDATE("DPDOCPRO",{"DOC_DOCORG","DOC_VALCAM","DOC_NETO","DOC_CODMON","DOC_PAGNUM"},;
                         {"R"         ,oRecibo:PAG_VALCAM,nMonto,oRecibo:PAG_CODMON,cRecibo},cWhere)

RETURN .T.
// EOF

