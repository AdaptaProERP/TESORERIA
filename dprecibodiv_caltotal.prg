// Programa   : DPRECIBODIV_CALTOTAL
// Fecha/Hora : 28/02/2023 23:52:41
// Propósito  :
// Creado Por : Juan Navas
// Llamado por: DPRECIBOCLI
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv,lRefresh)

   LOCAL aTotal:={},oCol,aTotalD
 
   IF !ValType(oRecDiv:oBrw)="O"
      RETURN .T.
   ENDIF

   aTotal          :=ATOTALES(oRecDiv:oBrw:aArrayData)
   aTotalD         :=ATOTALES(oRecDiv:oBrwD:aArrayData)

   oRecDiv:nMtoDifCam:=0

   IF oRecDiv:lCruce

      // total debitos es la suma de los documentos seleccionados
      oRecDiv:nMtoPag:=0
      oRecDiv:nMtoDoc:=0
      AEVAL(oRecDiv:oBrwD:aArrayData,{|a,n| oRecDiv:nMtoPag:=oRecDiv:nMtoPag+IF(a[9]>0,a[9]*+1,0),;
                                            oRecDiv:nMtoDoc:=oRecDiv:nMtoDoc+IF(a[9]<0,a[9]*-1,0)})

      oRecDiv:nTotal:=oRecDiv:nMtoPag-oRecDiv:nMtoDoc


   ELSE

      oRecDiv:nMtoIGTF:=ROUND(aTotal[oRecDiv:nColMtoITG] ,2)

      IF !oRecDiv:lIGTF
        oRecDiv:nMtoIGTF:=0
      ENDIF

      oRecDiv:nMtoPag :=ROUND(aTotal[05] ,2)

      IF oRecDiv:cTipDes="OPA" .OR. oRecDiv:cTipDes="OIN"
        oRecDiv:nMtoDoc :=ROUND(aTotalD[07+1],2)
      ELSE
        oRecDiv:nMtoDoc :=ROUND(aTotalD[09],2)
      ENDIF

      oRecDiv:nTotal :=ROUND(oRecDiv:nMtoPag-(oRecDiv:nMtoDoc+IF(oRecDiv:lIGTFCXC,0,oRecDiv:nMtoIGTF)),2)

      oRecDiv:nTotal :=oRecDiv:nTotal - IF(oRecDiv:lDifAnticipo,oRecDiv:nMtoAnticipo,0) // Excede -> Anticipo

      oRecDiv:nTotal :=INT(oRecDiv:nTotal*100)/100

      // 17/03/2023 Si el total de pagos es 0, el total debe ser su valor invertido
      IF oRecDiv:nMtoPag=0
        oRecDiv:nTotal:=oRecDiv:nMtoDoc*-1
      ENDIF

      oRecDiv:nMtoDifCam:=aTotalD[10]

   ENDIF

   oRecDiv:nTotal :=IF("-0.00"$LSTR(oRecDiv:nTotal,19,2),0.00,oRecDiv:nTotal)

   // Si cuadra documentos y pagos, la diferencia será el IGTF
   IF oRecDiv:nMtoPag=oRecDiv:nMtoDoc .AND. !oRecDiv:lIGTFCXC
      oRecDiv:nTotal:=oRecDiv:nMtoIGTF
   ENDIF 
   
   oCol:=oRecDiv:oBrw:aCols[4]
   oCol:cFooter      :=FDP(aTotal[4],oCol:cEditPicture)

   oCol:=oRecDiv:oBrw:aCols[5]
   oCol:cFooter      :=FDP(aTotal[5],oCol:cEditPicture)

   oCol:=oRecDiv:oBrw:aCols[12]
   oCol:cFooter      :=FDP(aTotal[12],oCol:cEditPicture)

   oRecDiv:oBrw:RefreshFooters()

   oRecDiv:oMtoPag:Refresh(.t.)
   oRecDiv:oMtoDoc:Refresh(.t.)
   oRecDiv:oMtoIGTF:Refresh(.T.)
   oRecDiv:oTotal:Refresh(.t.)

   IF ValType(oRecDiv:oBtnSave)="O"
     oRecDiv:oBtnSave:ForWhen(.T.)
   ENDIF

RETURN .T. 
// EOF
