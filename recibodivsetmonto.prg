// Programa   : RECIBODIVSETMONTO
// Fecha/Hora : 23/07/2023 09:59:18
// Prop�sito  : Asignar monto en el caso de Anticipo
// Creado Por :
// Llamado por:
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecibo,nMtoDiv)

  oRecibo:SETSCRIPT("DPRECIBODIV")
//  oRecibo:PUTMTODIV(nMtoDiv)
  oRecibo:oBrwD:aArrayData[oRecibo:oBrwD:nArrayAt,06]:=nMtoDiv
//oRecibo:oBrwD:aArrayData[oRecibo:oBrwD:nArrayAt,11]:=.T.
  oRecibo:oBrwD:nColSel:=11
  oRecibo:oBrwD:DrawLine(.T.)
  
RETURN .T.
// EOF
