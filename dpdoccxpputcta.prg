// Programa   : DPDOCCXPPUTCTA
// Fecha/Hora : 16/10/2008 00:35:08
// Propósito  : Generar los Items Automáticos
// Creado Por : Juan navas
// Llamado por: DPDOCPRO
// Aplicación : Compras
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oFrm)
   LOCAL i,aData,cCodCta,cCodEgr,cRef,cDescri

   IF !ValType(oFrm)="O"
       RETURN NIL
   ENDIF
   
   aData:=ACLONE(oDocCxP:aDataGrid)
 
   FOR I=1 TO LEN(aData)


      cDescri:=aData[I,1]
      oGrid:=oDocCxP:aGrids[1]
//    oGrid:lAutoRef:= .T. // Referencia Automática

      // Es Cuenta
      IF aData[I,11] 

        cCodCta:=aData[I,9]
        EJECUTAR("DPCTAEGRESOCREA",cCodCta,.T.,oGrid:CCD_TIPIVA)
        cCodEgr=SQLGET("DPCTAEGRESO","CEG_CODIGO","CEG_CUENTA"+GetWhere("=",cCodCta))
        cDescri:=aData[I,12]

      ELSE

        cCodEgr:=aData[I,9]
        cCodCta:=SQLGET("DPCTAEGRESO","CEG_CUENTA","CEG_CODIGO"+GetWhere("=",cCodEgr))

      ENDIF

      IF Empty(cDescri)
         cDescri:="Falta Descripción"
      ENDIF


      IF oDocCxP:lCtaEgr
         // Coloca la Cta Contable
      ENDIF

      IF !Empty(aData[I,4])

        oGrid:lAutoRef := .T. // Referencia Automática
        oGrid:oBrw:SetFocus()
        oGrid:oBrw:SelectCol( 1 )
        oGrid:Set("CCD_CODCTA", cCodCta   , .T. )  // Cuenta Contable
        oGrid:Set("CCD_CTAEGR", cCodEgr   , .T. )  // Cuenta Egreso
        oGrid:Set("CCD_REFERE", aData[I,1], .T. )  // Referencia
        oGrid:Set("CCD_DESCRI", cDescri   , .T. )  // Descripción
        oGrid:Set("CCD_MONTO" , aData[I,4], .T. )  // Monto
        oGrid:Set("CCD_TIPIVA", aData[I,2], .T. )  // Tipo de IVA
        oGrid:Set("CCD_PORIVA", aData[I,5], .T. )  // % IVA

        oGrid:BtnSave()

      ENDIF

   NEXT I 
  
RETURN
// EOF

