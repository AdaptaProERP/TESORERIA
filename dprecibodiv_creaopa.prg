// Programa   : DPRECIBODIV_CREAOPA
// Fecha/Hora : 19/03/2006 14:37:17
// Propósito  : Crear Documento en CXP para DPA
// Creado Por : Juan Navas
// Llamado por: DPCBTEPAGO
// Aplicación : Compras
// Tabla      : DPDOCPRO

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cNumCbt,aData,cCodigo,dFecha)
  LOCAL cNumDoc,I,oData,nNeto:=0,nIva:=0,nBruto:=0,nAt:=0
  LOCAL cTipDoc:="OPA",cNumero:="",cCenCos:=oDp:cCenCos,cTipIva:="",cSql
  LOCAL oTable,oPago,cCodSuc,cCodCta,aLine
  LOCAL lAppend:=.T.
  LOCAL lPar_Zero     :=.T.
  LOCAL nPar_Len      :=10

 
  DEFAULT cNumCbt:=STRZERO(1,8) ,;
          cCodigo:=STRZERO(1,10),;
          dFecha :=oDp:dFecha   ,;
          cCodSuc:=oDp:cSucursal

  EJECUTAR("IVALOAD",oDp:dFecha)


  IF Empty(cTipDoc) // Es Requerimiento de Efectivo
     RETURN .T.
  ENDIF

  // JN 12/03/2015
  lPar_Zero:=SQLGET("DPTIPDOCPRO","TDC_ZERO","TDC_TIPO"+GetWhere("=",cTipDoc))
  nPar_Len :=SQLGET("DPTIPDOCPRO","TDC_LEN" ,"TDC_TIPO"+GetWhere("=",cTipDoc))


// RViewArray(oDp:aDpIvaTabC)
// RETURN .T.

  IF !Empty(cNumCbt) .AND. SQLGET("DPDOCPRO","DOC_PAGNUM,DOC_NUMERO",;
                                             "DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                                             "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                                             "DOC_PAGNUM"+GetWhere("=",cNumCbt)+" AND "+;
                                             "DOC_CODIGO"+GetWhere("=",cCodigo))=cNumCbt


     cNumero:=oDp:aRow[2]
     lAppend:=.F.

  ENDIF

  IF aData=NIL
     aData:={}
     AADD(aData,{"ELECTRICIDAD",oDp:cCenCos,"Descripción",10000,14})
  ENDIF

  ADEPURA(aData,{|a,n| Empty(a[1]) })

/*
  WHILE .T.
    nAt:=ASCAN(aData,{|a,n|Empty(a[1])})
    IF nAt>0
      aData:=ARREDUCE(aData,nAt)
    ELSE
      EXIT
    ENDIF
  ENDDO
*/

//  ViewArray(aData)

  IF Empty(aData) .OR. Empty(aData[1,1])
    RETURN .T.
  ENDIF

  // Calcular Documento
  FOR I=1 TO LEN(aData)
     nNeto  :=nNeto+aData[I,5]
     nIva   :=nIva +PORCEN(aData[I,5],aData[I,6])
     cCenCos:=aData[I,2]
  NEXT I

  nBruto:=nNeto+nIva

  oDp:lMySqlNativo:=.F.

  IF lAppend .OR. Empty(cNumero)

    cNumero:=SQLINCREMENTAL("DPDOCPRO","DOC_NUMERO","DOC_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND "+;
                                                    "DOC_TIPDOC"+GetWhere("=",cTipDoc)+ " AND "+;
                                                    "DOC_CODIGO"+GetWhere("=",cCodigo)+ " AND "+;
                                                    "DOC_TIPTRA"+GetWhere("=","D"))

    // JN 13/07/2015  
    IF lPar_Zero .AND. nPar_Len>1 .AND. ISALLDIGIT(cNumero)
      cNumero:=STRZERO(VAL(cNumero),nPar_Len)
    ENDIF

    oTable:=OpenTable("SELECT * FROM DPDOCPRO",.F.)

    oTable:AppendBlank()
    oTable:Replace("DOC_CODSUC",oDp:cSucursal)
    oTable:Replace("DOC_NUMERO",cNumero      )
    oTable:Replace("DOC_PAGNUM",cNumCbt      )
    oTable:Replace("DOC_TIPDOC",cTipDoc      )
    oTable:Replace("DOC_CENCOS",cCenCos      )
    oTable:Replace("DOC_CODIGO",cCodigo      )
    oTable:Replace("DOC_TIPTRA","D"          )
    oTable:Replace("DOC_DOCORG","P"          )  // Originado en Pagos
    oTable:Replace("DOC_FECHA" ,dFecha       )
    oTable:Replace("DOC_HORA"  ,TIME()       )
    oTable:Replace("DOC_USUARI",oDp:cUsuario )
    oTable:Replace("DOC_NETO"  ,nNeto+nIva   )
    oTable:Replace("DOC_CODMON",oDp:cMoneda  )
    oTable:Replace("DOC_HORA"  ,TIME()       )
    oTable:Replace("DOC_ESTADO","CA"         )
    oTable:Replace("DOC_CXP"   ,IIF(SQLGET("DPTIPDOCPRO","TDC_CXP","TDC_TIPO"+GetWhere("=",cTipDoc))="D",1,-1))
    oTable:Replace("DOC_ACT"   ,1            )
    oTable:Replace("DOC_VALCAM",1            )

    oPago:=OpenTable("SELECT * FROM DPDOCPRO",.F.)
    oPago:Append()

    AEVAL(oPago:aFields,{|a,n|oPago:Replace(a[1],oTable:FieldGet(n))})
    oPago:Replace("DOC_TIPTRA","P")
    oPago:Replace("DOC_CXP"   ,-1 )
    oPago:Commit()

    oTable:Commit()
    oTable:End()

  ELSE
  
     cSql:="SELECT * FROM DPDOCPRO WHERE "+;
           "DOC_CODSUC"+GetWhere("=",cCodSuc  )+" AND "+;
           "DOC_TIPDOC"+GetWhere("=",cTipDoc  )+" AND "+;
           "DOC_PAGNUM"+GetWhere("=",cNumCbt  )+" AND "+;
           "DOC_CODIGO"+GetWhere("=",cCodigo  )+" AND "+;
           "DOC_TIPTRA"+GetWhere("=","D"      )

     oPago:=OpenTable(cSql,.T.)
     // oTable:Replace("DOC_NETO"  ,nNeto+nIva   )
     // oPago:Commit()
     cNumero:=oPago:DOC_NUMERO,CLPCOPY(cSql)

     // ? cNumero,"cNumero, aqui debe buscar","DPCBTE_CREAOPA"

     SQLDELETE("DPDOCPROCTA","CCD_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                             "CCD_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                             "CCD_NUMERO"+GetWhere("=",cNumero)+" AND "+;
                             "CCD_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
                             "CCD_TIPTRA"+GetWhere("=","D"    ))


  //   SQLDELETE("DPDOCPROIVA","IXD_TIPDOC"+GetWhere("=",oPago:DOC_TIPDOC)+" AND "+;
  //                           "IXD_CODSUC"+GetWhere("=",oPago:DOC_CODSUC)+" AND "+;
  //                           "IXD_NUMERO"+GetWhere("=",oPago:DOC_NUMERO)+" AND "+;
  //                           "IXD_CODIGO"+GetWhere("=",oPago:DOC_CODIGO)+" AND "+;
  //                           "IXD_TIPTRA"+GetWhere("=","D"))

     SQLUPDATE("DPDOCPRO","DOC_NETO",nNeto+nIva,"DOC_CODSUC"+GetWhere("=",cCodSuc  )+" AND "+;
                                                "DOC_TIPDOC"+GetWhere("=",cTipDoc  )+" AND "+;
                                                "DOC_PAGNUM"+GetWhere("=",cNumCbt  )+" AND "+;
                                                "DOC_CODIGO"+GetWhere("=",cCodigo  ))


  ENDIF

  FOR I=1 TO LEN(aData)

     nAt    :=ASCAN(oDp:aDpIvaTabC,{|a,n| a[3]=aData[I,6]})
     cTipIva:=IIF(nAt=0 , "", oDp:aDpIvaTabC[nAt,1])
     cCodCta:=SQLGET("DPCTAEGRESO","CEG_CUENTA","CEG_CODIGO"+GetWhere("=",aData[I,1]))

     // ? nAt,aData[I,5],cTipIva,cCodCta

     oTable:=OpenTable("SELECT * FROM DPDOCPROCTA",.F.)

     oTable:Replace("CCD_TIPTRA","D"         )
     oTable:Replace("CCD_CODSUC",cCodSuc     )
     oTable:Replace("CCD_NUMERO",cNumero     )
     oTable:Replace("CCD_TIPDOC",cTipDoc     )
     oTable:Replace("CCD_TIPIVA",cTipIva     )
     oTable:Replace("CCD_PORIVA",aData[I,6]  )
     oTable:Replace("CCD_DOCREF",aData[I,3]  )
     oTable:Replace("CCD_DESCRI",aData[I,4]  )
     oTable:Replace("CCD_CODIGO",cCodigo     )
     oTable:Replace("CCD_ITEM"  ,STRZERO(I,4))
     oTable:Replace("CCD_CTAEGR",aData[I,1]  )
     oTable:Replace("CCD_CODCTA",cCodCta     )
     oTable:Replace("CCD_CODCTA",cCodCta     )
     oTable:Replace("CCD_CTAMOD",oDp:cCtaMod )

     oTable:Replace("CCD_CENCOS",aData[I,2]  )
     oTable:Replace("CCD_ACT"   ,1           )
     oTable:Replace("CCD_MONTO" ,aData[I,5]  )
     oTable:Commit()
     oTable:End()


   NEXT I

   UPDATEDOC() // Crea los Impuestos
   oPago:End()

RETURN .T.

/*
// Actualiza el Documento
*/
FUNCTION UPDATEDOC(lUpdate)
   LOCAL oTable,cSql,aData,I,cWhere,nMtoIva:=0

   DEFAULT lUpdate:=.T.

   cSql:="SELECT CCD_TIPIVA,CCD_PORIVA,SUM(CCD_MONTO) AS CCD_MONTO FROM DPDOCPROCTA WHERE "+;
         "CCD_TIPDOC"+GetWhere("=",oPago:DOC_TIPDOC)+" AND "+;
         "CCD_CODSUC"+GetWhere("=",oPago:DOC_CODSUC)+" AND "+;
         "CCD_CODIGO"+GetWhere("=",oPago:DOC_CODIGO)+" AND "+;
         "CCD_NUMERO"+GetWhere("=",oPago:DOC_NUMERO)+" AND "+;
         "CCD_ACT = 1 "+;
         "GROUP BY CCD_TIPIVA,CCD_PORIVA "

   oTable:=OpenTable(cSql,.T.)
   aData:=ACLONE(oTable:aDataFill)
   oTable:Gotop()

   oDp:nDesc    :=0
   oDp:nRecarg  :=0
   oDp:nDocOtros:=0
   oDp:nBruto   :=nBruto
   oDp:nNeto    :=nNeto

/*
   WHILE !oTable:Eof()

      nMtoIva      :=nMtoIva   + PORCEN(oTable:CCD_MONTO,oTable:CCD_PORIVA)
      oDp:nBruto   :=oDp:nBruto+oTable:CCD_MONTO
      oTable:DbSkip()

   ENDDO
*/  
   oTable:End()

   nMtoIva       :=nIva
   oDp:nIva      :=nIva
   oDp:nBruto    :=nBruto
   oDp:nMtoDesc  :=Porcen(oDp:nBruto,oDp:nDesc  )
   oDp:nMtoRecarg:=Porcen(oDp:nBruto,oDp:nRecarg)
   oDp:nNeto     :=oDp:nBruto+oDp:nMtoRecarg;
                             -oDp:nMtoDesc;
                             +oDp:nDocOtros

   oDp:nMtoVar :=oDp:nBruto-oDp:nNeto
   oDp:nPorVar :=(100-RATA(oDp:nNeto,oDp:nBruto))*-1
   oDp:nBaseNet:=0
   oDp:nIva    :=oDp:nIva-PORCEN(oDp:nIva,oDp:nPorVar)
   oDp:nNeto   :=oDp:nNeto+oDp:nIva

   IF .F.
    
     cSql:="SELECT * FROM DPDOCPROIVA WHERE "+;
           "IXD_TIPDOC"+GetWhere("=",oPago:DOC_TIPDOC)+" AND "+;
           "IXD_CODSUC"+GetWhere("=",oPago:DOC_CODSUC)+" AND "+;
           "IXD_NUMERO"+GetWhere("=",oPago:DOC_NUMERO)+" AND "+;
           "IXD_CODIGO"+GetWhere("=",oPago:DOC_CODIGO)+" AND "+;
           "IXD_TIPTRA"+GetWhere("=","D")

     oTable:=OpenTable(cSql,.F.)

     IF .T.  // oTable:RecCount()=0 
 
        FOR I=1 TO LEN(aData)

          aData[I,3]:=CTOO(aData[I,3],"N")
          aData[I,2]:=CTOO(aData[I,2],"N")

          oTable:Append()
          oTable:Replace("IXD_TIPDOC",oPago:DOC_TIPDOC)
          oTable:Replace("IXD_CODSUC",oPago:DOC_CODSUC)
          oTable:Replace("IXD_NUMERO",oPago:DOC_NUMERO)
          oTable:Replace("IXD_CODIGO",oPago:DOC_CODIGO)
          oTable:Replace("IXD_TIPTRA","D"	)
          oTable:Replace("IXD_TIPIVA",aData[I,1])
          oTable:Replace("IXD_MTOBAS",aData[I,3])
          oTable:Replace("IXD_IVA"   ,aData[I,2])
          oTable:Replace("IXD_MTOIVA",PORCEN(aData[I,3],aData[I,2]))
          oTable:Commit()

        NEXT I

        // oTable:End()

     ENDIF

     oTable:End()

   ENDIF

RETURN .T.

// cNumDoc

