// Programa   : DPDOCCXPSKIP
// Fecha/Hora : 27/10/2010 01:32:21
// Propósito  : Determinar Antes y Despues en Cada Registro de Compra
// Creado Por : Juan Navas
// Llamado por: DPDOCCXP, clase TDOCENC, Método Skip(), 
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(nSkip,oCxP)
   LOCAL cCodSuc:=oDp:cSucursal,cTipDoc:="FAC",cCodigo:=STRZERO(1,10)
   LOCAL cNumero:=STRZERO(1,10),cDocOrg:="D"
   LOCAL cNumSig,cCodSig,cWhere

   DEFAULT nSkip:=1

   IF ValType(oCxP)="O"

      cCodSuc:=oCxP:DOC_CODSUC
      cTipDoc:=oCxP:DOC_TIPDOC
      cCodigo:=oCxP:DOC_CODIGO
      cNumero:=oCxP:DOC_NUMERO

   ENDIF

   cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
           "DOC_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
           "DOC_TIPTRA"+GetWhere("=","D"    )+" AND "+;
           "DOC_DOCORG"+GetWhere("=",cDocOrg)+" AND "+;
           "DOC_NUMERO"+GetWhere(IF(nSkip=-1,"<",">"),cNumero)

   cNumSig:=SQLGET("DPDOCPRO",IF(nSkip=-1,"MAX(DOC_NUMERO)","MIN(DOC_NUMERO)"),cWhere)
   cCodSig:=cCodigo

   IF cNumSig=cNumero .OR. Empty(cNumSig)

     // No hay mas Documentos debe Cambiar el Proveedor

     cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
             "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
             "DOC_CODIGO"+GetWhere(IF(nSkip=-1,"<",">"),cCodigo)+" AND "+;
             "DOC_TIPTRA"+GetWhere("=","D"    )+" AND "+;
             "DOC_DOCORG"+GetWhere("=",cDocOrg)


     cCodSig:=SQLGET("DPDOCPRO",IF(nSkip=-1,"MAX(DOC_CODIGO)","MIN(DOC_CODIGO)"),cWhere)

     IF !Empty(cCodSig)

       // Busca la Ultima Factura del Nuevo Proveedor
       cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
               "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
               "DOC_CODIGO"+GetWhere("=",cCodSig)+" AND "+;
               "DOC_DOCORG"+GetWhere("=",cDocOrg)+" AND "+;
               "DOC_TIPTRA"+GetWhere("=","D"    )

       cNumSig:=SQLGET("DPDOCPRO",IF(nSkip=1,"MIN(DOC_NUMERO)","MAX(DOC_NUMERO)"),cWhere)
  
     ELSE

       cCodSig:=cCodigo

     ENDIF

   ENDIF

   IF Empty(cNumSig)
      cNumSig:=cNumero
   ENDIF

   IF ValType(oCxP)="O" .AND. ((cNumSig<>cNumero) .OR. (cCodigo<>cCodSig))

      oCxP:Set("DOC_CODIGO",cCodSig)
      oCxP:Set("DOC_NUMERO",cNumSig)

      oCxP:cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                   "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                   "DOC_CODIGO"+GetWhere("=",cCodSig)+" AND "+;
                   "DOC_TIPTRA"+GetWhere("=","D"    )+" AND "+;
                   "DOC_DOCORG"+GetWhere("=",cDocOrg)+" AND "+;
                   "DOC_NUMERO"+GetWhere("=",cNumSig)


      oCxP:LoadData(0)

   ENDIF


RETURN NIL
// EOF

