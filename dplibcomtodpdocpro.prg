// Programa   : DPLIBCOMTODPDOCPRO
// Fecha/Hora : 23/11/2022 05:49:10
// Propósito  : Crear Documentos del Proveedor desde Libro de Compras
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,dFchDec,cWhere)
    LOCAL oTable,cCodPro:=STRZERO(0,10),oTableO,oTableC,oTableISRL:=NIL,oTableRTI:=NIL,cTipDoc,cNumero
    LOCAL oDb:=OpenOdbc(oDp:cDsnData),cOrg:="D",cCxpTip:="",cNumPar,cSql,nCxP,cWhereRet

    DEFAULT cCodSuc:=oDp:cSucursal,;
            dFchDec:=FCHFINMES(oDp:dFecha)

    oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 0")

    IF Empty(cWhere)

      cWhere:="LBC_CODSUC"+GetWhere("=" ,cCodSuc)+" AND "+;
              "LBC_FCHDEC"+GetWhere("=" ,dFchDec)+" AND "+;
              [( LBC_NUMFAC]+GetWhere("<>","")+[ OR LBC_ITEM]+GetWhere("<>",STRZERO(1,5))+")"

    ENDIF

// ? cWhere,"cWhere"

    IF ISPCPRG()
      // SQLDELETE("DPDOCPRO")
      //  SQLDELETE("DPDOCPROCTA")
    ENDIF

    SQLUPDATE("dplibcomprasdet","LBC_USOCON","Cuentas por Pagar","LBC_USOCON IS NULL OR LBC_USOCON"+GetWhere("=",""))
    SQLUPDATE("dplibcomprasdet","LBC_CENCOS",oDp:cCenCos,"LBC_CENCOS IS NULL OR LBC_CENCOS"+GetWhere("=",""))

IF .F.
    cSql:=[ UPDATE DPPROVEEDOR SET PRO_CODIGO=LEFT(PRO_RIF,10) WHERE PRO_CODIGO]+GetWhere("=","")
    oDb:Execute(cSql)

    cSql:=[ UPDATE DPLIBCOMPRASDET INNER JOIN dpproveedor ON LBC_RIF=PRO_RIF SET LBC_CODIGO=PRO_CODIGO WHERE LBC_CODIGO IS NULL OR LBC_CODIGO]+GetWhere("=","")
    oDb:Execute(cSql)
ENDIF

    oTableO:=OpenTable(" SELECT * FROM DPDOCPRO ",.F.)

    // oTableISRL:=OpenTable(" SELECT * FROM DPDOCPROISLR ",.F.) 
    // oTableRTI :=OpenTable(" SELECT * FROM DPDOCCLIRTI " ,.F.)

    oTable :=OpenTable(" SELECT * FROM DPLIBCOMPRASDET "+;
                       " INNER JOIN DPTIPDOCPRO ON LBC_TIPDOC=TDC_TIPO "+;
                       " WHERE "+cWhere+" ORDER BY CONCAT(LBC_NUMPAR,LBC_ITEM) ",.T.)
    DpMsgRun("Generando Documentos ")
    DpMsgSetTotal(oTable:RecCount())

    oTable:Gotop()

    WHILE !oTable:Eof() 

       DpMsgSet(oTable:RecNo(),.T.,NIL,oTable:LBC_TIPDOC+" "+oTable:LBC_CODIGO+" "+oTable:LBC_NUMFAC)

       IF oTable:LBC_ITEM=STRZERO(1,5)

         // cCodPro:=ALLTRIM(oTable:LBC_RIF)
         cCodPro:=oTable:LBC_CODIGO 
         cNumPar:=oTable:LBC_NUMPAR
         cTipDoc:=oTable:LBC_TIPDOC
         cNumero:=oTable:LBC_NUMFAC

         nCxP   :=oTable:LBC_CXP
         nCxP   :=IF(oTable:TDC_CXP="D", 1,nCxP)   
         nCxP   :=IF(oTable:TDC_CXP="C",-1,nCxP)

         cWhere:=oTable:cWhere+" AND LBC_NUMPAR"+GetWhere("=",oTable:LBC_NUMPAR)+" AND LBC_ITEM  "+GetWhere("=",oTable:LBC_ITEM)

         IF oTable:LBC_VALCAM=0 .OR. oTable:LBC_VALCAM=1
            oTable:LBC_VALCAM:=EJECUTAR("DPGETVALCAM",oDp:cMonedaExt,oTable:LBC_FECHA)
         ENDIF

// ? oTable:LBC_CENCOS,"CENCOS"

         SQLUPDATE("DPLIBCOMPRASDET",{"LBC_CXP","LBC_VALCAM"},{nCxP,oTable:LBC_VALCAM},cWhere)

//  ? oDp:cSql,oTable:LBC_VALCAM,oTable:LBC_CENCOS
// ? oTable:cWhere,oTable:LBC_NUMPAR,oTable:LBC_ITEM,cWhere

         IF Empty(cCodPro)
            cCodPro:=SQLGET("DPPROVEEDOR","PRO_CODIGO","PRO_RIF"+GetWhere("=",oTable:LBC_RIF))
         ENDIF

         IF !ISSQLFIND("DPPROVEEDOR","PRO_RIF"+GetWhere("=",cCodPro))
          // EJECUTAR("DPPROVEEDORCREA",cCodPro,oTable:RIF_NOMBRE,cCodPro,"Ocasionales")
         ENDIF

         // SQLUPDATE("DPPROVEEDOR","PRO_RIF",oTable:LBC_RIF,"PRO_CODIGO"+GetWhere("=",cCodPro))

         EJECUTAR("DPDOCPROCREA",oTable:LBC_CODSUC,oTable:LBC_TIPDOC,oTable:LBC_NUMFAC,oTable:LBC_NUMFIS,cCodPro,oTable:LBC_FECHA,oDp:cMonedaExt,cOrg,oTable:LBC_CENCOS,oTable:LBC_BASIMP,;
                                 oTable:LBC_MTOIVA,oTable:LBC_VALCAM,oTable:LBC_FCHDEC,NIL,oTableO,nCxP)

         cWhere:="DOC_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                 "DOC_TIPDOC"+GetWhere("=",oTable:LBC_TIPDOC)+" AND "+;
                 "DOC_CODIGO"+GetWhere("=",cCodPro          )+" AND "+;
                 "DOC_NUMERO"+GetWhere("=",oTable:LBC_NUMFAC)+" AND "+;
                 "DOC_TIPTRA"+GetWhere("=","D"              )

         cCxpTip:="CXP"
         cCxpTip:=IF(ALLTRIM(oTable:LBC_USOCON)=="Caja"        ,"CAJ",cCxpTip)
         cCxpTip:=IF(ALLTRIM(oTable:LBC_USOCON)=="Caja Divisa" ,"CJE",cCxpTip)
         cCxpTip:=IF(ALLTRIM(oTable:LBC_USOCON)=="Banco"       ,"BCO",cCxpTip)
         cCxpTip:=IF(ALLTRIM(oTable:LBC_USOCON)=="Banco Divisa","BCE",cCxpTip)

         SQLUPDATE("DPDOCPRO",{"DOC_RIF","DOC_CXPTIP","DOC_CENCOS","DOC_LBCPAR","DOC_CXP"},{cCodPro,cCxpTip,oTable:LBC_CENCOS,cNumPar,nCxP},cWhere)

        ENDIF

        // Genera Retención de ISLR
        IF !Empty(oTable:LBC_NUMISR)

           IF oTableISRL=NIL
              oTableISRL:=OpenTable(" SELECT * FROM DPDOCPROISLR ",.F.)
           ENDIF

           cWhereRet :="DOC_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                       "DOC_TIPDOC"+GetWhere("=","RET"            )+" AND "+;
                       "DOC_CODIGO"+GetWhere("=",cCodPro          )+" AND "+;
                       "DOC_NUMERO"+GetWhere("=",oTable:LBC_NUMISR)+" AND "+;
                       "DOC_TIPTRA"+GetWhere("=","D"              )

           SQLDELETE("DPDOCPRO",cWhereRet)

           cWhereRet:="RXP_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                      "RXP_TIPDOC"+GetWhere("=",cTipDoc          )+" AND "+;
                      "RXP_CODIGO"+GetWhere("=",cCodPro          )+" AND "+;
                      "RXP_NUMDOC"+GetWhere("=",oTable:LBC_NUMFAC)+" AND "+;
                      "RXP_TIPTRA"+GetWhere("=","D"              )

           SQLDELETE("DPDOCPROISLR",cWhereRet)

           EJECUTAR("DPDOCPROCREA",oTable:LBC_CODSUC,"RET",oTable:LBC_NUMISR,oTable:LBC_NUMFIS,cCodPro,oTable:LBC_FECHA,oDp:cMonedaExt,cOrg,oTable:LBC_CENCOS,oTable:LBC_MTOISR,;
                                   0,oTable:LBC_VALCAM,oTable:LBC_FCHDEC,NIL,oTableO,nCxP*-1)

           SQLUPDATE("DPDOCPRO",{"DOC_PLAIMP","DOC_LBCPAR","DOC_ESTADO"},{oTable:LBC_CONISR,cNumPar,"AC"},;
                                 "DOC_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                                 "DOC_TIPDOC"+GetWhere("=","RET"            )+" AND "+;
                                 "DOC_CODIGO"+GetWhere("=",cCodPro          )+" AND "+;
                                 "DOC_NUMERO"+GetWhere("=",oTable:LBC_NUMISR)+" AND "+;
                                 "DOC_TIPTRA"+GetWhere("=","D"))

           oTableISRL:AppendBlank()
           oTableISRL:Replace("RXP_CODSUC",oTable:LBC_CODSUC)
           oTableISRL:Replace("RXP_MTOBAS",oTable:LBC_MTOBAS)
           oTableISRL:Replace("RXP_MTORET",oTable:LBC_MTOISR)
           oTableISRL:Replace("RXP_MTOSUJ",oTable:LBC_MTOBAS)
           oTableISRL:Replace("RXP_PORCEN",oTable:LBC_PORISR)
           oTableISRL:Replace("RXP_CODCON",oTable:LBC_CONISR)
           oTableISRL:Replace("RXP_CODEQI",oTable:LBC_CONISR)
           oTableISRL:Replace("RXP_CODIGO",cCodPro)
           oTableISRL:Replace("RXP_TIPDOC",cTipDoc)
           oTableISRL:Replace("RXP_DOCTIP","RET"  ) // IF(cTipDoc="FAC","RET",)
           oTableISRL:Replace("RXP_TIPTRA","D"    )
           oTableISRL:Replace("RXP_DOCNUM",oTable:LBC_NUMISR)
           oTableISRL:Replace("RXP_NUMDOC",cNumero)
           oTableISRL:Replace("RXP_DESCRI",SQLGET("DPCONRETISLR","CTR_DESCRI","CTR_CODIGO"+GetWhere("=",oTable:LBC_CONISR)))
           oTableISRL:Commit("")
        
        ENDIF

        // Genera Retención de IVA
        IF !Empty(oTable:LBC_NUMRTI)

           IF oTableRTI=NIL
              oTableRTI:=OpenTable(" SELECT * FROM DPDOCPRORTI " ,.F.)
           ENDIF

           cWhereRet :="DOC_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                       "DOC_TIPDOC"+GetWhere("=","RTI"            )+" AND "+;
                       "DOC_CODIGO"+GetWhere("=",cCodPro          )+" AND "+;
                       "DOC_NUMERO"+GetWhere("=",oTable:LBC_NUMRTI)+" AND "+;
                       "DOC_TIPTRA"+GetWhere("=","D"              )

           SQLDELETE("DPDOCPRO",cWhereRet)

           cWhereRet:="RTI_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                      "RTI_TIPDOC"+GetWhere("=",cTipDoc          )+" AND "+;
                      "RTI_CODIGO"+GetWhere("=",cCodPro          )+" AND "+;
                      "RTI_NUMERO"+GetWhere("=",oTable:LBC_NUMFAC)+" AND "+;
                      "RTI_TIPTRA"+GetWhere("=","D"              )

           SQLDELETE("DPDOCPRORTI",cWhereRet)

           EJECUTAR("DPDOCPROCREA",oTable:LBC_CODSUC,"RTI",oTable:LBC_NUMRTI,oTable:LBC_NUMFIS,cCodPro,oTable:LBC_FECHA,oDp:cMonedaExt,cOrg,oTable:LBC_CENCOS,oTable:LBC_MTORTI,;
                                   0,oTable:LBC_VALCAM,oTable:LBC_FCHDEC,NIL,oTableO,nCxP*-1)

           SQLUPDATE("DPDOCPRO",{"DOC_PLAIMP","DOC_LBCPAR","DOC_ESTADO"},{oTable:LBC_CONISR,cNumPar,"AC"},;
                                 "DOC_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                                 "DOC_TIPDOC"+GetWhere("=","RTI"            )+" AND "+;
                                 "DOC_CODIGO"+GetWhere("=",cCodPro          )+" AND "+;
                                 "DOC_NUMERO"+GetWhere("=",oTable:LBC_NUMISR)+" AND "+;
                                 "DOC_TIPTRA"+GetWhere("=","D"))

           oTableRTI:AppendBlank()
           oTableRTI:Replace("RTI_CODSUC",oTable:LBC_CODSUC)
           oTableRTI:Replace("RTI_CODIGO",cCodPro)
           oTableRTI:Replace("RTI_TIPDOC",cTipDoc)
           oTableRTI:Replace("RTI_DOCTIP","RTI"  ) 
           oTableRTI:Replace("RTI_TIPTRA","D"    )
           oTableRTI:Replace("RTI_NUMTRA",oTable:LBC_NUMRTI)
           oTableRTI:Replace("RTI_DOCNUM",oTable:LBC_NUMRTI)
           oTableRTI:Replace("RTI_NUMERO",cNumero)
           oTableRTI:Replace("RTI_FCHDEC",dFchDec)
           oTableRTI:Replace("RTI_FECHA" ,oTable:LBC_FECHA)
           oTableRTI:Replace("RTI_AAMM"  ,LEFT(DTOS(dFchDec),4))	
           oTableRTI:Replace("RTI_PORCEN",oTable:LBC_PORRTI)
           oTableRTI:Replace("RTI_NUMRET",SQLINCREMENTAL("DPDOCPRORTI","RTI_NUMRET","1=1",NIL,NIL,.T.,8))
           oTableRTI:Replace("RTI_NUMMRT",SQLINCREMENTAL("DPDOCPRORTI","RTI_NUMRET","RTI_CODIGO"+GetWhere("=",cCodigo),NIL,NIL,.T.,8))
           oTableRTI:Commit("")

        
        ENDIF

        // SQLUPDATE("DPDOCPROCTA","CCD_ACT",0,cWhere) // Por ahora, luego debera removerlos

        cWhere:="CCD_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                "CCD_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                "CCD_CODIGO"+GetWhere("=",cCodPro)+" AND "+;
                "CCD_NUMERO"+GetWhere("=",cNumero)

        SQLDELETE("DPDOCPROCTA",cWhere) // Por ahora, luego debera removerlos

        WHILE !oTable:Eof() .AND. (cNumPar=oTable:LBC_NUMPAR) 

          cWhere:="CCD_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                  "CCD_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                  "CCD_CODIGO"+GetWhere("=",cCodPro)+" AND "+;
                  "CCD_NUMERO"+GetWhere("=",cNumero)+" AND "+;
                  "CCD_ITEM"  +GetWhere("=",oTable:LBC_ITEM  )

          oTableC:=OpenTable("SELECT * FROM DPDOCPROCTA WHERE "+cWhere,.T.)

          IF oTableC:RecCount()=0
            oTableC:AppendBlank()
            oTableC:cWhere:=""
          ENDIF

          IF Empty(oTable:LBC_CENCOS)
            oTableC:Replace("CCD_CENCOS",oDp:cCenCos)
          ELSE
            oTableC:Replace("CCD_CENCOS",oTable:LBC_CENCOS)
          ENDIF

          IF Empty(oTable:LBC_CODCTA)
             oTable:Replace("LBC_CODCTA",oDp:cCtaIndef)
          ENDIF

          IF Empty(oTable:LBC_CTAEGR)
             oTable:Replace("LBC_CTAEGR",oDp:cCtaIndef)
          ENDIF

          oTableC:Replace("CCD_CODSUC",cCodSuc          )
          oTableC:Replace("CCD_TIPDOC",cTipDoc          )
          oTableC:Replace("CCD_CODIGO",cCodPro          )
          oTableC:Replace("CCD_NUMERO",cNumero          )
          oTableC:Replace("CCD_ITEM"  ,oTable:LBC_ITEM  )
          oTableC:Replace("CCD_TIPIVA",oTable:LBC_TIPIVA)
          oTableC:Replace("CCD_PORIVA",oTable:LBC_PORIVA)
          oTableC:Replace("CCD_DESCRI",oTable:LBC_DESCRI)
          oTableC:Replace("CCD_CTAEGR",oTable:LBC_CTAEGR)
          oTableC:Replace("CCD_CODCTA",oTable:LBC_CODCTA)
          oTableC:Replace("CCD_CTAMOD",oDp:cCtaMod      )
          oTableC:Replace("CCD_CENCOS",oTable:LBC_CENCOS)
          oTableC:Replace("CCD_ACT"   ,1                )
          oTableC:Replace("CCD_MONTO" ,oTable:LBC_MTOBAS)
          oTableC:Replace("CCD_TOTAL" ,oTable:LBC_MTONET)
          oTableC:Replace("CCD_TIPTRA","D"              )
          oTableC:Replace("CCD_CODPRO",cCodPro          )
          oTableC:Commit(oTableC:cWhere)
          oTableC:End(.T.)

          oTable:DbSkip()

        ENDDO

        EJECUTAR("DPDOCCLIIMP",cCodSuc,cTipDoc,cCodPro,cNumero,.T.,0,0,0,"C",0)


        // oTable:DbSkip()

    ENDDO

    cSql:="UPDATE DPDOCPRO SET DOC_MTODIV=ROUND(DOC_NETO/DOC_VALCAM,2) WHERE DOC_FCHDEC"+GetWhere("=",dFchDec)+" AND DOC_TIPTRA"+GetWhere("=","D")
    oDb:EXECUTE(cSql)
    // oTable:Browse()
    oTable:End()

    oTableISRL:End(.T.)
    oTableRTI:End(.T.)

    oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")

    DpMsgClose()

RETURN .T.
// EOF
