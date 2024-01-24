// Programa   : DPRECIBODIV_CTAEGR
// Fecha/Hora : 04/03/2023 01:34:16
// Propósito  : Validar Cuenta de Egreso
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(uValue,lNext,oRecDiv)

   DEFAULT lNext:=.T.

   IF oRecDiv:lAcction 
      oRecDiv:lAcction  :=.F.
      RETURN .F. // uValue
   ENDIF

   IF Empty(uValue) .OR. !SQLGET("DPCTAEGRESO","CEG_CODIGO","CEG_CODIGO"+GetWhere("=",uValue))==uValue
      oRecDiv:lAcction  :=.T.
      oRecDiv:EDITCTAEGRE()
      RETURN .F.
   ENDIF

   IF !lNext
      RETURN .T.
   ENDIF

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,1]:=uValue
   oRecDiv:oBrwD:SelectCol(2)
   oRecDiv:lAcction  :=.F.

RETURN uValue


