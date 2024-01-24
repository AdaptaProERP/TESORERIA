// Programa   : DPRECIBODIVFCHTRAN         
// Fecha/Hora : 19/10/2022 03:31:54
// Propósito  : Crear Recibo segun fecha de Transacción
// Creado Por : JUAN NAVAS
// Llamado por: DPRECIBODIV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cNumero,cLetraDes)
   LOCAL cWhere,cRecibo,oRecOrg,oRecDes,oDb:=OpenOdbc(oDp:cDsnData),cWhereD
   LOCAL oTableO,oTableD,nMonto:=0
   LOCAL lReset:=.F.

   DEFAULT cCodSuc  :=oDp:cSucursal,;
           cLetraDes:="A"

   IF lReset
      oDb:EXECUTE([UPDATE dpreciboscli SET REC_NUMORG=""])
      oDb:EXECUTE([DELETE FROM dpreciboscli WHERE LEFT(REC_NUMERO,1)="A"])
   ENDIF

   IF Empty(cNumero)

      cWhere :="REC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
               "REC_NUMORG"+GetWhere("=",""     )+" AND "+;
               "REC_FCHREG>REC_FECHA"

      cNumero:=SQLGET("DPRECIBOSCLI","REC_NUMERO",cWhere)

   ENDIF

   cWhereD:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "DOC_RECNUM"+GetWhere("=",cNumero)+" AND "+;
            "(DOC_GIRNUM"+GetWhere("=",oDp:cMotDIFD)+" OR DOC_GIRNUM"+GetWhere("=",oDp:cMotDIFC)+")"

   // no hay diferencial cambiario
   IF !ISSQLFIND("DPDOCCLI",cWhereD)
      RETURN ""
   ENDIF

   // Fecha del recibo nuevo
   cRecibo:=EJECUTAR("RECNUMERO",cCodSuc,cLetraDes)

   cWhere :="REC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
            "REC_NUMERO"+GetWhere("=",cNumero)
   
   oRecOrg:=OpenTable("SELECT * FROM DPRECIBOSCLI WHERE "+cWhere,.T.)
// oRecOrg:Browse()
   oRecDes:=OpenTable("SELECT * FROM DPRECIBOSCLI",.F.)
   oRecDes:AppendBlank()
   AEVAL(oRecOrg:aFields,{|a,n| oRecDes:FieldPut(n,oRecOrg:FieldGet(n))})

   oRecDes:Replace("REC_NUMERO",cRecibo)
   oRecDes:Replace("REC_FECHA" ,oRecOrg:REC_FCHREG)
   oRecDes:Replace("REC_NUMORG",cNumero)
   oRecDes:Commit("")

   /*
   // las diferencias cambiarias segan migradas hacia el nuevo recibo
   */
   
   // ? CLPCOPY(cWhereD)

   nMonto:=SQLGET("DPDOCCLI","SUM(DOC_NETO*DOC_CXC)",cWhereD+" AND DOC_TIPTRA"+GetWhere("=","D"))

   
   // Crea Anticipo de la diferencia cambiaria 
   oTableO:=OpenTable("SELECT * FROM DPDOCCLI WHERE "+cWhereD+" LIMIT 1",.T.)

   IF !lReset   

     SQLUPDATE("DPDOCCLI",{"DOC_RECNUM","DOC_FECHA"       },;
                          {cRecibo     ,oRecOrg:REC_FCHREG},cWhereD)

     SQLUPDATE("DPRECIBOSCLI","REC_NUMORG",cRecibo,cWhere)

   ENDIF

// oTableO:Browse()

   oTableD:=OpenTable("SELECT * FROM DPDOCCLI",.F.)

   oTableD:AppendBlank()
   AEVAL(oTableO:aFields,{|a,n| oTableD:FieldPut(n,oTableO:FieldGet(n))})
   oTableD:Replace("DOC_TIPDOC","ANT"  )
   oTableD:Replace("DOC_TIPTRA","D"    )
   oTableD:Replace("DOC_CXC"   ,-1     )
   oTableD:Replace("DOC_NUMGIR",""     )
   oTableD:Replace("DOC_NUMERO",cNumero)
   oTableD:Replace("DOC_RECNUM",cNumero)
   oTableD:Replace("DOC_NETO"  ,nMonto )
   oTableD:Replace("DOC_BASNET",nMonto )
   oTableD:Replace("DOC_MTOIVA",0      )
   oTableD:Replace("DOC_NUMFIS",""     )
   oTableD:Replace("DOC_SERFIS",""     )
   oTableD:Replace("DOC_DOCORG","R"    )

   oTableD:Commit("")

// ? oDp:cSql

   oTableD:AppendBlank()
   AEVAL(oTableO:aFields,{|a,n| oTableD:FieldPut(n,oTableO:FieldGet(n))})
   oTableD:Replace("DOC_TIPDOC","ANT"  )
   oTableD:Replace("DOC_TIPTRA","P"    )
   oTableD:Replace("DOC_CXC"   ,1      )
   oTableD:Replace("DOC_NUMGIR",""     )
   oTableD:Replace("DOC_NUMERO",cNumero)
   oTableD:Replace("DOC_RECNUM",cRecibo)
   oTableD:Replace("DOC_NETO"  ,nMonto )
   oTableD:Replace("DOC_BASNET",nMonto )
   oTableD:Replace("DOC_FECHA" ,oRecOrg:REC_FCHREG)
   oTableD:Replace("DOC_MTOIVA",0      )
   oTableD:Replace("DOC_NUMFIS",""     )
   oTableD:Replace("DOC_SERFIS",""     )
   oTableD:Commit("")

// ? oDp:cSql
 

   oRecDes:End()
   oRecOrg:End()

   oTableD:End()
   oTableO:End()
 
// ? cRecibo,"NUEVO"

RETURN cRecibo
// EOF
