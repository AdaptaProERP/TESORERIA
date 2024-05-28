// Programa   : DPRECIBODIVDIFCAM
// Fecha/Hora : 27/09/2022 12:53:39
// Propósito  : Crear Documento con Diferencial Cambiario
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cRecibo,lReset,nMtoIGTF,lCxC,cDbOrg,lIGTF,oRecDiv)
   LOCAL oTableO,oDocCli,oTableD,oTableP,cSql,cNumero,nMonto,nIva:=0,aDataD,U,cCtaEgr,lLibVta,cSerieF,cNumFis,cSerieF,cLetra:=""
   LOCAL cWhere,cInner
   LOCAL cTipDocD,cDescriD,cCodCtaD
   LOCAL cTipDocC,cDescriC,cCodCtaC
   LOCAL cTipDoc ,cDescri ,cCodCta,cCodMot,cWhereOrg:="",cWhereTDC:=""
   LOCAL nTotDifCam:=0  // la suma revalorización otros documentos diferentes a las facturas
   LOCAL nMtoDifPro:=0  // Monto Proporcional
   LOCAL oDbOrg,oDbDes:=OpenOdbc(oDp:cDsnData)
   LOCAL nCxC

   DEFAULT cCodSuc :=oDp:cSucursal,;
           cRecibo :=SQLGETMAX("DPRECIBOSCLI","REC_NUMERO","REC_CODSUC"+GetWhere("=",cCodSuc)),;
           lReset  :=.F.,;
           nMtoIGTF:=0,;
           lCxC    :=.F.,;
           lIGTF   :=.F.

   // lIGTF   :=(nMtoIGTF>0)
   // lIGTF = Indica si genera documento del IGTF

   DEFAULT cDbOrg:=oDp:cDsnData

   oDbOrg:=OpenOdbc(cDbOrg)

   IF lReset

      cWhere:="DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
              "DOC_RECNUM"+GetWhere("=",cRecibo)+" AND "+;
              "DOC_DOCORG"+GetWhere("=","R"    )

      SQLDELETE("DPDOCCLI",cWhere)

   ENDIF

   cInner  :=" LEFT JOIN DPTIPDOCCLIMOT_CTA ON CIC_CODIGO=MDC_CODIGO LEFT JOIN DPCTA ON CIC_CTAMOD=CTA_CODMOD AND CIC_CUENTA=CTA_CODIGO "

   IF nMtoIGTF>0
     cTipDocD:=SQLGET("DPTIPDOCCLIMOT","MDC_TIPDOC,MDC_DESCRI,CIC_CUENTA",cInner+" WHERE MDC_CODIGO"+GetWhere("=",oDp:cMotDIFD))
   ELSE
     cTipDocD:=SQLGET("DPTIPDOCCLIMOT","MDC_TIPDOC,MDC_DESCRI,CIC_CUENTA",cInner+" WHERE MDC_CODIGO"+GetWhere("=",oDp:cMotDIFC))
   ENDIF

   IF lIGTF
     cTipDocD:=SQLGET("DPTIPDOCCLIMOT","MDC_TIPDOC,MDC_DESCRI,CIC_CUENTA",cInner+" WHERE MDC_CODIGO"+GetWhere("=",oDp:cMotIGTF))
     cWhereTDC:=""

// ? cTipDocD,"cTipDocD",CLPCOPY(oDp:cSql)
/*
   ELSE
     // Diferencial Cambiario solo a documentos fiscales que aplican libro de venta.
     cWhereTDC:=" ( TDC_LIBVTA=1 OR TDC_TIPO"+GetWhere("=","ANT")+")" 

? "ESTO NO DEBE APLICAR"
*/
   ENDIF

   cDescriD:=ALLTRIM(DPSQLROW(2,""))
   cCodCtaD:=DPSQLROW(3,oDp:cCtaIndef)

   cTipDocC:=SQLGET("DPTIPDOCCLIMOT","MDC_TIPDOC,MDC_DESCRI,CIC_CUENTA",cInner+" WHERE MDC_CODIGO"+GetWhere("=",cTipDocD)) // oDp:cMotDIFC))
   cDescriC:=ALLTRIM(DPSQLROW(2,""))
   cCodCtaC:=DPSQLROW(3,oDp:cCtaIndef)

// ? oDp:cSql

   cSql    :=" SELECT * FROM dpdoccli "+;
             " INNER JOIN DPTIPDOCCLI ON DOC_TIPDOC=TDC_TIPO AND TDC_REVALO=1 "+IF(Empty(cWhereTDC),""," AND ")+cWhereTDC+;   
             " WHERE "+;
             " DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
             " DOC_RECNUM"+GetWhere("=",cRecibo)+" AND "+;
             " DOC_TIPTRA"+GetWhere("=",IF(oRecDiv:lAnticipo,"D","P"))

   IF !lIGTF
       cSql:=cSql+" AND DOC_MTOCOM<>0"
   ELSE
       cSql:=cSql+" LIMIT 1" // un solo documento
   ENDIF


   // oTableP:=OpenTable(" SELECT * FROM DPDOCCLI",.F.)

   oTableD:=OpenTable(" SELECT * FROM DPDOCCLICTA",.F.,oDbDes)
   oTableO:=OpenTable(cSql,.T.,oDbOrg)

   IF lIGTF
     oTableO:Replace("DOC_MTOCOM",nMtoIGTF)
   ENDIF

//   oTableO:Browse()

   oDocCli:=OpenTable("SELECT * FROM DPDOCCLI",.F.,oDbDes)
   // 06/12/2022
   // Los documentos revalorizados y diferentes a Facturas deben ser sumados hacia los documentos asociados con facturas y de manera proporcional
   WHILE !oTableO:Eof()  

     IF oTableO:DOC_MTOCOM<>0
        nTotDifCam:=nTotDifCam+(oTableO:DOC_MTOCOM*(oTableO:DOC_CXC*-1))
// ? nTotDifCam,oTableO:DOC_MTOCOM,"oTableO:DOC_MTOCOM"
     ENDIF

     oTableO:DbSkip()

   ENDDO

// oTableO:Browse()
//
// ? nTotDifCam,"nTotDifCam"

   IF nTotDifCam<>0 .AND. !lIGTF

      oTableO:GoTop()
      WHILE !oTableO:Eof()

        oTableO:Replace("DOC_MTOCOM",0)

        // por ahora aplicará diferencial cambiario en la primera factura  
        IF oTableO:DOC_TIPDOC="FAV"
           oTableO:Replace("DOC_MTOCOM",nTotDifCam)
           nTotDifCam:=0 // Solo puede colocarlo una vez
        ENDIF

        oTableO:DbSkip()

      ENDDO

   ENDIF
 	
   oTableO:GoTop()

// ? nTotDifCam,"nTotDifCam"
// ? oTableO:Browse(),"DOCUMENTO"

   WHILE !oTableO:Eof()

      IF oTableO:DOC_MTOCOM<>0

        cTipDoc :=cTipDocD    
        cCodMot :=oDp:cMotDIFD
        cCodCta :=cCodCtaD
        cDescri :=cDescriD

        IF lIGTF
           cCodMot:=oDp:cMotIGTF
        ENDIF

      ELSE

        cTipDoc :=cTipDocC    
        cCodMot :=oDp:cMotDIFC
        cCodCta :=cCodCtaC
        cDescri :=cDescriC

      ENDIF

      // obtenemos la cuenta desde el tipo de documento
      IF EMPTY(cCodCta) .OR. "INDEF"$UPPER(cCodCta)
         cCodCta:=SQLGET("DPTIPDOCCLI_CTA","CIC_CUENTA","CIC_CODIGO"+GetWhere("=",cTipDoc)+" AND CIC_CTAMOD"+GetWhere("=",oDp:cCtaMod))
      ENDIF

      IF Empty(cCodCta)
         cCodCta:=oDp:cCtaIndef
      ENDIF

      nMonto  :=ABS(oTableO:DOC_MTOCOM)

      IF nMonto=0
         oTableO:DbSkip()
         LOOP
      ENDIF

      nIva    :=0  // Debemos obtener el % del IVA

      lLibVta:=SQLGET("DPTIPDOCCLI","TDC_LIBVTA,TDC_SERIEF","TDC_TIPO"+GetWhere("=",cTipDoc))
      cSerieF:=DPSQLROW(2,"")
      cNumFis:=""

      // QUIBOR REQUIERE FECHA IGTF Según Fecha del Registro
      IF oRecDiv:lAnticipo
        cNumero:=EJECUTAR("DPDOCCLICREA",cCodSuc,cTipDoc,NIL,oTableO:DOC_CODIGO,oRecDiv:dFecha,oTableO:DOC_CODMON,NIL,NIL,nMonto,nIva,oTableO:DOC_VALCAM,oRecDiv:dFecha,oDocCli)
      ELSE
        cNumero:=EJECUTAR("DPDOCCLICREA",cCodSuc,cTipDoc,NIL,oTableO:DOC_CODIGO,oTableO:DOC_FECHA,oTableO:DOC_CODMON,NIL,NIL,nMonto,nIva,oTableO:DOC_VALCAM,oTableO:DOC_FECHA,oDocCli)
      ENDIF

      IF lLibVta .AND. !lIGTF
        cLetra :=SQLGET("DPSERIEFISCAL","SFI_LETRA,SFI_IMPFIS,SFI_PUERTO","SFI_MODELO"+GetWhere("=",cSerieF))
        cNumFis:=EJECUTAR("DPDOCCLIGETNUMFIS",cCodSuc,cLetra,cTipDoc)
      ENDIF

      cWhereOrg:=cWhereOrg+IF(Empty(cWhereOrg),""," AND ")+;
                 "DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND DOC_NUMERO"+GetWhere("=",cNumero)+" AND DOC_TIPTRA"+GetWhere("=","D")

      SQLUPDATE("DPDOCCLI",{"DOC_GIRNUM","DOC_RECNUM","DOC_VALCAM"      ,"DOC_DOCORG","DOC_NUMFIS","DOC_SERFIS","DOC_IMPRES","DOC_FACAFE"      ,"DOC_TIPAFE"     },;
                           {cCodMot     ,cRecibo     ,oTableO:DOC_VALCAM,"R"         ,cNumFis     ,cLetra      ,.F.         ,oTableO:DOC_NUMERO,oTableO:DOC_TIPDOC},;
                           "DOC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                           "DOC_TIPDOC"+GetWhere("=",cTipDoc)+" AND "+;
                           "DOC_NUMERO"+GetWhere("=",cNumero)+" AND "+;
                           "DOC_TIPTRA"+GetWhere("=","D"    ))

      //oDocDes:Replace("DOC_GIRNUM",oMOTCREADOC:cCodMot) // Motivo
      IF lIGTF
        aDataD:={}
        AADD(aDataD,{STRZERO(1,5),"EX",0,0,nMtoIGTF,0,0,nMtoIGTF})
      ELSE
        aDataD:=EJECUTAR("DPDOCCLIRATAIVA",oTableO:DOC_CODSUC,oTableO:DOC_TIPDOC,oTableO:DOC_NUMERO,nMonto)
      ENDIF

      // ViewArray(aDataD)	

      FOR U=1 TO LEN(aDataD)
        
        cCtaEgr:=EJECUTAR("DPCTAEGRESOCREA",cCodCta,NIL,aDataD[U,2])
        nMonto :=aDataD[U,8]
        oTableD:AppendBlank()
        oTableD:Replace("CCD_ITEM"  ,aDataD[U,1]    )
        oTableD:Replace("CCD_TIPTRA","D"            )
        oTableD:Replace("CCD_CODSUC",cCodSuc        )
        oTableD:Replace("CCD_NUMERO",cNumero        )  
        oTableD:Replace("CCD_TIPDOC",cTipDoc        )
        oTableD:Replace("CCD_TIPIVA",aDataD[U,2]    )
        oTableD:Replace("CCD_TIPCTA","C"            )
        oTableD:Replace("CCD_PORIVA",aDataD[U,6]    )
        oTableD:Replace("CCD_MONTO" ,nMonto         ) // aDataD[U,8]    )
        oTableD:Replace("CCD_DESCRI",cDescri        )
        oTableD:Replace("CCD_CTAEGR",cCtaEgr        )
        oTableD:Replace("CCD_CODCTA",cCodCta        )
        oTableD:Replace("CCD_CTAMOD",oDp:cCtaMod    )
        oTableD:Replace("CCD_CENCOS",oTableO:DOC_CENCOS)
        oTableD:Replace("CCD_ACT"   ,1                 )
        oTableD:Replace("CCD_CODIGO",oTableO:DOC_CODIGO)
        oTableD:Replace("CCD_FECHA" ,oRecDiv:dFecha    )
        oTableD:Commit()

     NEXT U

     oTableO:DbSkip()

   ENDDO

//   oTableO:Browse()
   oTableO:End()
   oDocCli:End()
   oTableD:End()

   IF !Empty(cWhereOrg) .AND. !lCxC

//  nCxC  :=EJECUTAR("DPTIPCXC",cTipDoc)
//? nCxC,"nCxC",cTipDoc,"NO PUEDE SER CERO"

     oTableP:=OpenTable("SELECT * FROM DPDOCCLI",.F.,oDbDes)
     cSql   :="SELECT * FROM DPDOCCLI WHERE "+cWhereOrg
     oTableO:=OpenTable(cSql,.T.,oDbOrg)

     WHILE !oTableO:EOF()

        oTableP:AppendBlank()
        AEVAL(oTableO:aFields,{|a,n| oTableP:FieldPut(n,oTableO:FieldGet(n))})
        oTableP:Replace("DOC_MTOCOM",0)
        oTableP:Replace("DOC_TIPTRA","P")
        oTableP:Replace("DOC_CXC"   ,oTableO:DOC_CXC*-1 )
        oTableP:Commit("")
        oTableO:DbSkip()

     ENDDO

     oTableO:End()
     oTableP:End()

   ENDIF

RETURN (oTableO:RecCount()>0)
// EOF


