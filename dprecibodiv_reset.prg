// Programa   : DPRECIBODIV_RESET
// Fecha/Hora : 28/02/2023 23:41:53
// Prop�sito  : Resetear Recibo de Ingres
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV
// Aplicaci�n :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv)
  LOCAL aLine:=ACLONE(oRecDiv:oBrwD:aArrayData[1])
 
  AEVAL(aLine,{|a,n| aLine[n]:=CTOEMPTY(a)})

  oRecDiv:oBrwD:aArrayData:={}
  AADD(oRecDiv:oBrwD:aArrayData,aLine)
  oRecDiv:oBrwD:Gotop()
  oRecDiv:oBrwD:nArrayAt:=1
  oRecDiv:oBrwD:Refresh(.t.)

  AEVAL(oRecDiv:oBrw:aArrayData,{|a,n| oRecDiv:oBrw:aArrayData[n,4]:=0,;
                                       oRecDiv:oBrw:aArrayData[n,5]:=0,;
                                       oRecDiv:oBrw:aArrayData[n,oRecDiv:nColSelP  ]:=.F.,;
                                       oRecDiv:oBrw:aArrayData[n,oRecDiv:nColMtoITG]:=0})

  oRecDiv:oBrw:Refresh(.F.)
  oRecDiv:CALTOTAL()
  oRecDiv:SETSUGERIDO()


RETURN
