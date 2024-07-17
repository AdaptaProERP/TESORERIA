// Programa   : DPIVATIPCREA
// Fecha/Hora : 22/01/2005 21:44:10
// Propósito  : Crear Diversos Tabuladores de IVA
// Creado Por : Juan Navas
// Llamado por: DPINI o Cambio de Empresa
// Aplicación : INVENTARIO
// Tabla      : DPIVA

#INCLUDE "DPXBASE.CH"

PROCE MAIN()

  LOCAL oTable,aTipos:={},I,aFiles:={}

/*
  IF Count("DPCTA")=0 
     oTable:=OpenTable("SELECT * FROM DPCTA",.F.)
     oTable:Append()
     oTable:Replace("CTA_CODIGO",oDp:cCtaIndef)
     oTable:Replace("CTA_DESCRI",oDp:cCtaIndef)
     oTable:Commit()
     oTable:End()
  ENDIF
*/

  IF Count("DPIVATIP")=0 .OR. COUNT("DPIVATABC")=0

     AADD(aFiles,{"EJEMPLO\DPTABMON.dbf"   ,"DPIVATABC"  ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPCTA.dbf"      ,"DPCTA"      ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPIVATIP.dbf"   ,"DPIVATIP"   ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPIVATAB.dbf"   ,"DPIVATAB"   ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPIVATABC.dbf"  ,"DPIVATABC"  ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPBANCOTIP.dbf" ,"DPBANCOTIP" ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPCAJAINST.dbf" ,"DPCAJAINST" ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPBANCODIR.dbf" ,"DPBANCODIR" ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPCARGOS.dbf"   ,"DPCARGOS"   ,NIL,})
     AADD(aFiles,{"EJEMPLO\DPTIPDOCCLI.dbf","DPTIPDOCCLI",NIL,})
     AADD(aFiles,{"EJEMPLO\DPTIPDOCPRO.dbf","DPTIPDOCPRO",NIL,})

     EJECUTAR("IMPORTDP",oDp:cDsnData,aFiles,NIL,NIL,NIL,NIL,.F.,.F.)

  ENDIF




RETURN .T.
// EOF
