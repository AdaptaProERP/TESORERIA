// Programa   : DPRECIBOSDIV_EDIT
// Fecha/Hora : 16/08/2024 09:28:26
// Propósito  : Editar Recibo de Ingreso
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cNumRec,lEdit)
  LOCAL cCodigo:=NIL,cWhere:=NIL,nOption:=3

  DEFAULT cCodSuc:=oDp:cSucursal,;
          cNumRec:="00074812",;
          lEdit  :=.F.

  nOption:=IF(lEdit,3,0) // Modificar o Consultar
  cCodigo:=SQLGET("DPRECIBOSCLI","REC_CODIGO","REC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                                              "REC_NUMERO"+GetWhere("=",cNumRec))

  EJECUTAR("DPRECIBODIV",cCodigo,cWhere,cCodSuc,nOption,cNumRec)

RETURN .T.
// EOF


