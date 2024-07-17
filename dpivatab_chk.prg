// Programa   : DPIVATAB_CHK
// Fecha/Hora : 17/07/2024 04:58:27
// Propósito  : Revisar % de IVA
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()
  LOCAL cFile:="EJEMPLO\DPIVATABC.DBF"

  IF COUNT("DPIVATABC")=0 .AND. FILE(cFile)
     IMPORTDBF32("DPIVATABC",cFile,oDp:cDsnData,oDp:oSay,.T.,.T.)
  ENDIF

  IF COUNT("DPIVATIP")=0

     EJECUTAR("DPIVATIPCREA")

     IF COUNT("DPIVATIP","TIP_CODIGO"+GetWhere("=","EX"))=0
        EJECUTAR("DPIVATIP_CREA","EX","Exento",0)
     ENDIF

  ENDIF

  IF COUNT("DPIVATIP","TIP_ACTIVO=1")=0
     SQLUPDATE("DPIVATIP",{"TIP_ACTIVO","TIP_COMPRA","TIP_VENTA"},{.T.,.T.,.T.},"TIP_CODIGO"+GetWhere("=","GN"))
  ENDIF

RETURN .T.
// EOF
