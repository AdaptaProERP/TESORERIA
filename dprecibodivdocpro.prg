// Programa   : DPRECIBODIVDOCPRO
// Fecha/Hora : 19/09/2022 03:32:42
// Propósito  : Guardar Documentos del Proveedor desde Recibos de Ingresos
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv,cCodSuc,aData,cRecNum,dFecha,cCenCos,nValCam,cCodVen,cDbOrg)
   LOCAL I,oNew,aNumDoc,cWhere,oTableO,oTableD,nCxP,oRecibo,oDbOrg,oDbDes:=OpenOdbc(oDp:cDsnData)

   IF !ValType(oRecDiv)="O"
     RETURN .F.
   ENDIF

   aData:=IF(Empty(aData),ACLONE(oRecDiv:oBrwD:aArrayData),aData)

   IF Empty(aData)
      RETURN .F.
   ENDIF

   DEFAULT cDbOrg:=oDp:cDsnData

   oDbOrg:=OpenOdbc(cDbOrg)

   oTableD:=OpenTable("SELECT * FROM DPDOCPRO",.F.,oDbDes)

   ADEPURA(aData,{|a,n| !(a[11] .AND. !Empty(a[9]))})

   FOR I=1 TO LEN(aData)

      nCxP  :=IF(LEFT(ALLTRIM(aData[I,12]),1)="D",-1,1)

      cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc        )+" AND "+;
              "DOC_TIPDOC"+GetWhere("=",aData[I,1]     )+" AND "+;
              "DOC_CODIGO"+GetWhere("=",oRecDiv:cCodigo)+" AND "+;
              "DOC_NUMERO"+GetWhere("=",aData[I,3]     )+" AND "+;
              "DOC_TIPTRA"+GetWhere("=","D")

      oTableO:=OpenTable("SELECT * FROM DPDOCPRO WHERE "+cWhere,.T.,oDbOrg)

      oTableD:AppendBlank()
      AEVAL(oTableO:aFields,{|a,n| oTableD:Replace(a[1],oTableO:FieldGet(n)) })
      oTableD:Replace("DOC_TIPTRA","P")
      oTableD:Replace("DOC_NETO"  ,ABS(aData[I,09]-aData[I,10])) // Resta el diferencial Cambiario
      oTableD:Replace("DOC_MTODIV",ROUND(ABS(aData[I,09]-aData[I,10])/nValCam,2)) // Monto en Divisa
      oTableD:Replace("DOC_MTOCOM",aData[I,10])
      oTableD:Replace("DOC_PAGNUM",cRecNum    )
      oTableD:Replace("DOC_FECHA" ,dFecha     )
      oTableD:Replace("DOC_CXP"   ,nCxP       )
      oTableD:Replace("DOC_DOCORG","D"        ) // 07/12/2022 El pago no debe ser "R"
      oTableD:Replace("DOC_VALCAM",nValCam    )
      oTableD:Replace("DOC_CBTNUM",""         )

// ? aData[I,10],"aData[I,10]"
//    oTableD:Replace("DOC_CODVEN",cCodVen    )
      oTableD:Commit("")
      oTableO:End()

      IF !oTableD:DOC_TIPDOC="ANT"
         SQLUPDATE("DPDOCPRO","DOC_PAGNUM",cRecNum,cWhere,NIL,oDbOrg)
      ENDIF

   NEXT I

   oTableD:End()

//    ? "AQUI ES"
// ViewArray(aData)

RETURN .T.
// EOF


