// Programa   : DPLIBCOMTOBANCOS  
// Fecha/Hora : 17/07/2024 05:31:56
// Propósito  : Crear los Registros en transacciones de bancos
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,dFchDec,cWhere)
    LOCAL oTable,cCodPro:=STRZERO(0,10),oTableO,oTableC,oTableISRL:=NIL,oTableRTI:=NIL,cTipDoc:="FAC",cNumero
    LOCAL oDb:=OpenOdbc(oDp:cDsnData),cOrg:="D",cCxpTip:="CXP",cNumPar,cSql,nCxP,cWhereRet
    LOCAL cInner:="",cWhereC,cCtaComNac:="",nRecno:=0,lWhere:=.F.
    LOCAL cCodBco:="",cCtaBco:="",cCtaEgr:=oDp:cCtaIndef,cCtaBco:=oDp:cCtaIndef,cTipDoc,cNumTra:=""


    DEFAULT cCodSuc:=oDp:cSucursal,;
            dFchDec:=FCHFINMES(oDp:dFecha)

    oDb:EXECUTE("SET FOREIGN_KEY_CHECKS = 0")

    EJECUTAR("DPCTABANCO_CREA") // Crea cuentas Bancarias

    IF Empty(cWhere)

      cWhere:="LBC_CODSUC"+GetWhere("=" ,cCodSuc)+" AND "+;
              "LBC_FCHDEC"+GetWhere("=" ,dFchDec)+" AND "+;
              "LBC_NUMFAC"+GetWhere("<>","")

      SQLDELETE("DPCTABANCOMOV","MOB_CODSUC"+GetWhere("=",cCodSuc)+" AND MOB_FECHA"+GetWhere("=",dFchDec)+" AND MOB_ORIGEN"+GetWhere("=","LBC"))

    ELSE

      lWhere:=.T.

    ENDIF

    cWhere        :=cWhere+" AND LEFT(LBC_USOCON,5)"+GetWhere("Banco")
    cCtaComNac    :=EJECUTAR("CODINTGETCTA",oDp:cCtaComNac,"COMNAC")
    oDp:cAbrComNac:=oDp:cAbrevia 

    IF "DOC_"$cWhere
       cInner:=[ LEFT  JOIN DPDOCPRO     ON LBC_CODSUC=DOC_CODSUC AND LBC_TIPDOC=DOC_TIPDOC AND LBC_CODIGO=DOC_CODIGO AND LBC_NUMFAC=DOC_NUMERO AND DOC_TIPTRA='D' ]
    ENDIF 

    cInner:=IF(Empty(cInner),"",cInner)

    cInner:=cInner+IF(Empty(cInner),"",CRLF)+;
            [ LEFT  JOIN DPPROVEEDOR   ON LBC_RIF=PRO_RIF ]

    oTableO:=OpenTable(" SELECT * FROM DPCTABANCOMOV ",.F.)
    oTableO:lAuditar:=.F.

/*
    oTable:=OpenTable(" SELECT LBC_CODIGO,LBC_NUMFAC,COUNT(*) AS CUANTOS FROM dplibcomprasdet WHERE "+cWhere+" GROUP BY LBC_CODIGO,LBC_NUMFAC HAVING CUANTOS=1",.T.)

     WHILE !oTable:Eof() .AND. oTable:RecCount()>1
         SQLUPDATE("dplibcomprasdet",{"LBC_ITEM","LBC_NUMPAR"},{STRZERO(1,5),STRZERO(oTable:Recno(),5)},cWhere+" AND LBC_CODIGO"+GetWhere("=",oTable:LBC_CODIGO)+" AND LBC_NUMFAC"+GetWhere("=",oTable:LBC_NUMFAC))
         oTable:DbSkip()
     ENDDO
     oTable:End()
*/

    cSql:=" SELECT LBC_CODSUC,LBC_TIPDOC,LBC_RIF,LBC_NUMFAC,LBC_FCHDEC,SUM(LBC_MTOBAS+LBC_MTOIVA+LBC_MTOEXE) AS LBC_NETO FROM DPLIBCOMPRASDET "+;
          " INNER JOIN DPTIPDOCPRO ON LBC_TIPDOC=TDC_TIPO "+;
          cInner+;
          " WHERE "+cWhere+;
          " GROUP BY LBC_CODSUC,LBC_TIPDOC,LBC_RIF,LBC_NUMFAC,LBC_FCHDEC "+;
          " ORDER BY CONCAT(LBC_NUMPAR,LBC_ITEM) "

    oTable :=OpenTable(cSql,.T.)
 
    WHILE !oTable:Eof()

       cCodBco:=STRZERO(0,6)
       cCtaBco:="Indefinida"
       cTipDoc:="PAG"

       cNumTra:=SQLINCREMENTAL("DPCTABANCOMOV","MOB_NUMTRA",;
                "    MOB_CUENTA"+GetWhere("=",cCtaBco)+;
                "AND MOB_CODBCO"+GetWhere("=",cCodBco)+;
                "AND MOB_TIPO"  +GetWhere("=",cTipDoc))


       oTableO:AppendBlank()
       oTableO:Replace("MOB_CODSUC" ,oTable:LBC_CODSUC)
       oTableO:Replace("MOB_CODMON" ,oDp:cMoneda)
       oTableO:Replace("MOB_CODBCO" ,cCodBco)
       oTableO:Replace("MOB_CUENTA" ,cCtaBco)
       oTableO:Replace("MOB_ACT"    ,1)
       oTableO:Replace("MOB_CTAEGR" ,cCtaEgr)
       oTableO:Replace("MOB_CTACON" ,cCtaBco)
       oTableO:Replace("MOB_RIF"    ,oTable:LBC_RIF)
       oTableO:Replace("MOB_ORIGEN" ,"LBC")
       oTableO:Replace("MOB_DOCUME" ,oTable:LBC_NUMFAC)
       oTableO:Replace("MOB_FECHA"  ,oTable:LBC_FCHDEC)
       oTableO:Replace("MOB_NUMTRA" ,cNumTra)
       oTableO:Replace("MOB_ESTADO" ,"Activo")
       oTableO:Replace("MOB_MONTO"  ,oTable:LBC_NETO)
       oTableO:Replace("MOB_TIPO"   ,cTipDoc)

       oTableO:Commit()
       oTable:DbSkip()

    ENDDO

//  oTable:Browse()
    oTable:End()

    // Cuentas bancarias
    oTableO:End()

RETURN NIL
// EOF
