// Programa   : DPRECIBODIV_OPAGRABAR
// Fecha/Hora : 20/03/2006 20:09:58
// Propósito  : Grabar Línea de Cuentas por Concepto         
// Creado Por : Juan Navas
// Llamado por: DPCBTEPAGO
// Aplicación : Tesoreria
// Tabla      : DPCBTEPAGO

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv)
   LOCAL aLine   :=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt]
   LOCAL nTotal  :=0
   LOCAL cCenCos :=aLine[2]
   LOCAL lIncluir:=.F.
   LOCAL nMtoIva :=0

   oRecDiv:lAcction:=.F.

   IF Empty(aLine[1])
      MensajeErr("Indique la Cuenta de Egreso","Registro Inválido")
      RETURN .F.
   ENDIF

   IF !oRecDiv:VALCTAEGRE(aLine[1],.F.,oRecDiv)
      RETURN .F.
   ENDIF

   IF !oRecDiv:VALCENCOSOPA(aLine[2],.F.)
      RETURN .F.
   ENDIF

   IF Empty(aLine[3])
      oRecDiv:oBrwD:SelectCol(3)
      DpFocus(oRecDiv:oBrwD)
      RETURN .F.
   ENDIF

   IF Empty(aLine[4])
      DpFocus(oRecDiv:oBrwD)
      oRecDiv:oBrwD:SelectCol(4)
      RETURN .F.
   ENDIF

   nMtoIva:=PORCEN(oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5],oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,6])

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7+0]:=nMtoIva

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7+1]:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5]+nMtoIva
                                                       
/*
   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7+1]:=oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5]+;
                                                       PORCEN(oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,5],oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,6])
*/

   oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,8+1]:=ROUND(oRecDiv:oBrwD:aArrayData[oRecDiv:oBrwD:nArrayAt,7+1]/oRecDiv:nValCam,2) 


   oRecDiv:oBrwD:DrawLine(.T.)

   // Si no tiene base imponible solicita el valor en DOLARES
   IF Empty(aLine[5])
      DpFocus(oRecDiv:oBrwD)
      oRecDiv:oBrwD:SelectCol(9)
      RETURN .F.
   ENDIF


   oRecDiv:CalTotal() //CalcOtr()

   // Verifica si el ultimo está Vacio
   IF !Empty(ATAIL(oRecDiv:oBrwD:aArrayData)[1])
      lIncluir:=.T.
   ENDIF

   IF lIncluir .OR. LEN(oRecDiv:oBrwD:aArrayData)=oRecDiv:oBrwD:nArrayAt // Este es el ultimo

      AEVAL(aLine,{|a,n|aLine[n]:=CTOEMPTY(a)})
      aLine[2]:=cCenCos
      AADD(oRecDiv:oBrwD:aArrayData,aLine)
      oRecDiv:lAcction:=.F.
      oRecDiv:oBrwD:SelectCol(1)

      oRecDiv:oBrwD:GoBottom()
      oRecDiv:oBrwD:DrawLine(.T.)
      oRecDiv:oBrwD:KeyBoard(VK_END) // Bajar
      oRecDiv:oBrwD:SetFocus()

    ELSE

      oRecDiv:oBrwD:SelectCol(1)

    ENDIF

    EJECUTAR("BRWCALTOTALES",oRecDiv:oBrwD,.F.)

    oRecDiv:SETSUGERIDO()

RETURN .T.
// EOF



