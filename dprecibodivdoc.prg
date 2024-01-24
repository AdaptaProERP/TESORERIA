// Programa   : DPRECIBODIVDOC
// Fecha/Hora : 19/09/2022 03:32:42
// Propósito  : Guardar Documentos desde Recibos de Ingresos
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv,cCodSuc,aData,cRecNum,dFecha,cCenCos,nValCam,cCodVen,cDbOrg)
   LOCAL I,oNew,aNumDoc,cWhere,oTableO,oTableD,nCxC,oRecibo,oDbOrg,oDbDes:=OpenOdbc(oDp:cDsnData)

   IF !ValType(oRecDiv)="O"
     RETURN .F.
   ENDIF

   aData:=IF(Empty(aData),ACLONE(oRecDiv:oBrwD:aArrayData),aData)

   IF Empty(aData)
      RETURN .F.
   ENDIF

   DEFAULT cDbOrg:=oDp:cDsnData

   oDbOrg :=OpenOdbc(cDbOrg)

   oTableD:=OpenTable("SELECT * FROM DPDOCCLI",.F.,oDbDes)

   ADEPURA(aData,{|a,n| !(a[11] .AND. !Empty(a[9]))})

   FOR I=1 TO LEN(aData)

      nCxC  :=IF(LEFT(ALLTRIM(aData[I,12]),1)="D",-1,1)

      cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc   )+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",aData[I,1])+" AND "+;
              "DOC_NUMERO"+GetWhere("=",aData[I,3])+" AND "+;
              "DOC_TIPTRA"+GetWhere("=","D"       )+" AND "+;
              "DOC_ACT=1"

      oTableO:=OpenTable("SELECT * FROM DPDOCCLI WHERE "+cWhere+" LIMIT 1",.T.,oDbOrg)

      // oTableO:Browse()

      oTableD:AppendBlank()
      AEVAL(oTableO:aFields,{|a,n| oTableD:Replace(a[1],oTableO:FieldGet(n)) })

      oTableD:Replace("DOC_TIPTRA","P")
      oTableD:Replace("DOC_NETO"  ,ABS(aData[I,09]-aData[I,10])) // Resta el diferencial Cambiario
      oTableD:Replace("DOC_MTODIV",ROUND(ABS(aData[I,09]-aData[I,10])/nValCam,2)) // Resta el diferencial Cambiario

      oTableD:Replace("DOC_MTOCOM",aData[I,10])
      oTableD:Replace("DOC_RECNUM",cRecNum    )
      oTableD:Replace("DOC_FECHA" ,dFecha     )
//    oTableD:Replace("DOC_CXC"   ,nCxC       )
      oTableD:Replace("DOC_DOCORG","D"        ) // 07/12/2022 El pago no debe ser "R"
      oTableD:Replace("DOC_VALCAM",nValCam    )
      oTableD:Replace("DOC_CODVEN",cCodVen    )
      oTableD:Replace("DOC_CBTNUM",""         )
      oTableD:Replace("DOC_CXC"   ,oTableO:DOC_CXC*-1)
      oTableD:Commit("")

      // ? oTableO:DOC_CXC*-1,"oTableO:DOC_CXC*-1, NO PUEDE TENER VALOR CERO"

      oTableO:End()

      IF !oTableD:DOC_TIPDOC="ANT"
        SQLUPDATE("DPDOCCLI","DOC_RECNUM",cRecNum,cWhere,NIL,oDbOrg)
      ENDIF

   NEXT I

   oTableD:End()

   SysRefresh(.T.)

// ? "AQUI ES, debe validar en donde se duplica el registro "
// ViewArray(aData)

RETURN .T.
// EOF

