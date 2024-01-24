// Programa   : DPRECIBODIVOPADIV
// Fecha/Hora : 17/03/2023 04:31:59
// Propósito  : Calcular Monto Divisa 
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv)
   LOCAL aLine  :=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt]
   LOCAL nMtoDiv:=aLine[9]
   LOCAL nMonto :=nMtoDiv*oRecDiv:nValCam
   LOCAL nPorIva:=aLine[6]
   LOCAL nBase  :=ROUND(nMonto/(1+nPorIva/100),2)
   LOCAL nMtoIva:=PORCEN(nBase,nPorIva)
   
   aLine[5]:=nBase
   aLine[7]:=nMtoIva
   aLine[8]:=nMonto

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt]:=ACLONE(aLine)
   oRecDiv:oBrwD:DrawLine(.T.)

   EJECUTAR("BRWCALTOTALES",oRecDiv:oBrwD)

   oRecDiv:SETSUGERIDO()

RETURN .T.
// EOF
