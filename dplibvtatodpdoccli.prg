// Programa   : DPLIBVTATODPDOCCLI
// Fecha/Hora : 23/11/2022 05:49:10
// Propósito  : Crear Documentos del Proveedor desde Libro de Ventas
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,dFchDec,cWhere)
    LOCAL oTable,cCodCli:=STRZERO(0,10),oTableO,oTableC,cTipDoc,cNumero
    LOCAL oDb:=OpenOdbc(oDp:cDsnData),cOrg:="D",cCxC,cNumPar,cSql,nCXC

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
      // SQLDELETE("DPDOCCLI")
      //  SQLDELETE("DPDOCCLICTA")
    ENDIF

    SQLUPDATE("DPLIBVENTASDET","LBC_USOCON","Cuentas por Pagar","LBC_USOCON IS NULL OR LBC_USOCON"+GetWhere("=",""))
/*
    cSql:=[ UPDATE DPCLIENTES SET CLI_CODIGO=LEFT(CLI_RIF,10) WHERE CLI_CODIGO]+GetWhere("=","")
    oDb:Execute(cSql)

    cSql:=[ UPDATE DPLIBVENTASDET INNER JOIN DPCLIENTES ON LBC_RIF=CLI_RIF SET LBC_CODIGO=CLI_CODIGO WHERE LBC_CODIGO IS NULL OR LBC_CODIGO]+GetWhere("=","")
    oDb:Execute(cSql)
*/
    oTableO:=OpenTable(" SELECT * FROM DPDOCCLI ",.F.)

    oTable :=OpenTable(" SELECT * FROM DPLIBVENTASDET "+;
                       " INNER JOIN DPTIPDOCCLI ON LBC_TIPDOC=TDC_TIPO "+;
                       " WHERE "+cWhere+" ORDER BY CONCAT(LBC_NUMPAR,LBC_ITEM) ",.T.)
    // oTable:Browse()
    oTable:Gotop()

    WHILE !oTable:Eof() 

       IF oTable:LBC_ITEM=STRZERO(1,5)

         // cCodCli:=ALLTRIM(oTable:LBC_RIF)
         cCodCli:=oTable:LBC_CODIGO 
         cNumPar:=oTable:LBC_NUMPAR
         cTipDoc:=oTable:LBC_TIPDOC
         cNumero:=oTable:LBC_NUMFAC

         nCXC   :=0
         nCXC   :=IF(oTable:TDC_CXC="D", 1,nCXC)   
         nCXC   :=IF(oTable:TDC_CXC="C",-1,nCXC)

         cWhere:=oTable:cWhere+" AND LBC_NUMPAR"+GetWhere("=",oTable:LBC_NUMPAR)+" AND LBC_ITEM  "+GetWhere("=",oTable:LBC_ITEM)

         IF oTable:LBC_VALCAM=0 .OR. oTable:LBC_VALCAM=1
            oTable:LBC_VALCAM:=EJECUTAR("DPGETVALCAM",oDp:cMonedaExt,oTable:LBC_FECHA)
         ENDIF

         SQLUPDATE("DPLIBVENTASDET",{"LBC_CXC","LBC_VALCAM"},{nCXC,oTable:LBC_VALCAM},cWhere)

         IF Empty(cCodCli)
            cCodCli:=SQLGET("DPCLIENTES","CLI_CODIGO","CLI_RIF"+GetWhere("=",oTable:LBC_RIF))
         ENDIF

         IF !ISSQLFIND("DPCLIENTES","CLI_RIF"+GetWhere("=",cCodCli))
          // EJECUTAR("DPCLIENTESCREA",cCodCli,oTable:RIF_NOMBRE,cCodCli,"Ocasionales")
         ENDIF

         // SQLUPDATE("DPCLIENTES","CLI_RIF",oTable:LBC_RIF,"CLI_CODIGO"+GetWhere("=",cCodCli))

         EJECUTAR("DPDOCCLICREA",oTable:LBC_CODSUC,oTable:LBC_TIPDOC,oTable:LBC_NUMFAC,oTable:LBC_NUMFIS,cCodCli,oTable:LBC_FECHA,oDp:cMonedaExt,cOrg,oTable:LBC_CENCOS,oTable:LBC_BASIMP,;
                                 oTable:LBC_MTOIVA,oTable:LBC_VALCAM,oTable:LBC_FCHDEC,NIL,oTableO,nCXC)

         cWhere:="DOC_CODSUC"+GetWhere("=",oTable:LBC_CODSUC)+" AND "+;
                 "DOC_TIPDOC"+GetWhere("=",oTable:LBC_TIPDOC)+" AND "+;
                 "DOC_CODIGO"+GetWhere("=",cCodCli          )+" AND "+;
                 "DOC_NUMERO"+GetWhere("=",oTable:LBC_NUMFAC)+" AND "+;
                 "DOC_TIPTRA"+GetWhere("=","D"              )

         cCxC:="CXC"
         cCxC:=IF(ALLTRIM(oTable:LBC_USOCON)=="Caja"        ,"CAJ",cCxC)
         cCxC:=IF(ALLTRIM(oTable:LBC_USOCON)=="Caja Divisa" ,"CJE",cCxC)
         cCxC:=IF(ALLTRIM(oTable:LBC_USOCON)=="Banco"       ,"BCO",cCxC)
         cCxC:=IF(ALLTRIM(oTable:LBC_USOCON)=="Banco Divisa","BCE",cCxC)

         SQLUPDATE("DPDOCCLI",{"DOC_RIF","DOC_CXC"},{cCodCli,cCxC},cWhere)

        ENDIF

        cWhere:="CCD_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                "CCD_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                "CCD_CODIGO"+GetWhere("=",cCodCli)+" AND "+;
                "CCD_NUMERO"+GetWhere("=",cNumero)

        SQLUPDATE("DPDOCCLICTA","CCD_ACT",0,cWhere)

// ? CLPCOPY(oDp:cSql)

        WHILE !oTable:Eof() .AND. (cNumPar=oTable:LBC_NUMPAR) 

          cWhere:="CCD_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                  "CCD_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                  "CCD_CODIGO"+GetWhere("=",cCodCli)+" AND "+;
                  "CCD_NUMERO"+GetWhere("=",cNumero)+" AND "+;
                  "CCD_ITEM"  +GetWhere("=",oTable:LBC_ITEM  )

          oTableC:=OpenTable("SELECT * FROM DPDOCCLICTA WHERE "+cWhere,.T.)

          IF oTableC:RecCount()=0
            oTableC:AppendBlank()
            oTableC:cWhere:=""
          ENDIF

          IF Empty(oTable:LBC_CENCOS)
            oTableC:Replace("CCD_CENCOS",oDp:cCenCos)
          ELSE
            oTableC:Replace("CCD_CENCOS",oTable:LBC_CENCOS)
          ENDIF

          oTableC:Replace("CCD_CODSUC",cCodSuc          )
          oTableC:Replace("CCD_TIPDOC",cTipDoc          )
          oTableC:Replace("CCD_CODIGO",cCodCli          )
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
          oTableC:Replace("CCD_MONTO" ,oTable:LBC_BASIMP)
          oTableC:Replace("CCD_TOTAL" ,oTable:LBC_MTONET)
          oTableC:Replace("CCD_TIPTRA","D"              )
          oTableC:Replace("CCD_CODPRO",cCodCli          )
          oTableC:Commit(oTableC:cWhere)
          oTableC:End()

          oTable:DbSkip()

        ENDDO

        EJECUTAR("DPDOCCLIIMP",cCodSuc,cTipDoc,cCodCli,cNumero,.T.,0,0,0,"C",0)

        // oTable:DbSkip()

    ENDDO

    cSql:="UPDATE DPDOCCLI SET DOC_MTODIV=ROUND(DOC_NETO/DOC_VALCAM,2) WHERE DOC_FCHDEC"+GetWhere("=",dFchDec)+" AND DOC_TIPTRA"+GetWhere("=","D")
    oDb:EXECUTE(cSql)
    // oTable:Browse()
    oTable:End()

    oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 1")

RETURN .T.
// EOF
