// Programa   : DPRECIBOCONT
// Fecha/Hora : 23/03/2006 15:51:58
// Propósito  : Contabilizar Comprobante de Pago
// Creado Por : Juan Navas
// Llamado por: DPCBTEPAGOCON
// Aplicación : Compras
// Tabla      : DPRECIBOSCLI
// Se filtro transaciones por sucursales ya que traia movimientos de ambas. 
// lineas 145,245,281 (TJ) se filtra para que contabilize las diferentes formasde pago
// con feche de recibo y no con fecha del pago ya que descuadra los comprobantes contables
// 06-08-2008  Inclusion de Asignacion de Numero Cbte desde DPNUMCBTE
// 08-08-2008  Llamado Programa DPDELCBTEV a fin de Borrar DPCBTE si queda sin Detalle en DPASIENTOS
// 13-08-2008  Inclusion de variable oDp:lNumcom a fin de agrupar o no asientos por modulo

#INCLUDE "DPXBASE.CH"

PROCE MAIN(cCodSuc,cNum1,cNum2,cNumCom,lVenta,lAsk)
    LOCAL oBcoMov,oCajMov,nCxC,oData,lView,lClose,cCodigo,oFontG,oBtn
    LOCAL oTable,cWhere,cCbtNum:="",cCtaCxC,nMonto,cOrg,cDescri,cCodigo
    LOCAL cDocCli:="DPDOCPRO",cTitle,dFecha

    DEFAULT cNum1  :=STRZERO(800,8),;
            cNum2  :=STRZERO(800,8),;
            cNumCom:=oDp:cNumCom,;
            cCodSuc:=oDp:cSucursal ,;
            lVenta :=.T.,;
            lAsk   :=.T.,;
            oDp:lNumCom:=.F.

   IF !lAsk

      RUNASIENTO(cCodSuc,cNum1,cNum2,cNumCom,lVenta,lAsk)
      RETURN .T.

   ENDIF

   cCodigo:=SQLGET("DPRECIBOSCLI","REC_CODIGO,REC_FECHA","REC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                                                         "REC_NUMERO"+GetWhere("=",cNum1))
   dFecha :=DPSQLROW(2,oDp:dFecha)

   cTitle:=GetFromVar("{oDp:xDPRECIBOSCLI}")

   oData:=DATASET("RECCONTAB","ALL")

   lClose:=oData:Get("CLOSE",.T.)
   lView :=oData:Get("VIEW" ,.T.)

   oData:End()

   DPEDIT():New("Contabilizar "+cTitle,"DPRECIBOCONTAB.EDT","oConRec",.T.)

   oConRec:cTableTip:=IIF(lVenta,"DPTIPDOCCLI","DPTIPDOCPRO")

   IF lVenta
     oConRec:cNumCom:=EJECUTAR("DPNUMCBTEXTIPDOC","DPRECIBOSCLI","REC",dFecha)
   ELSE
     oConRec:cNumCom:=EJECUTAR("DPNUMCBTEXTIPDOC","DPCBTEPAGO"  ,"PAG",dFecha)
   ENDIF

/*
   IF oDp:lNumCom
      oConRec:cNumCom:=EJECUTAR("DPNUMCBTE","TESORE")
     ELSE
      oConRec:cNumCom:=oDp:cNumCom
   ENDIF 
*/

   oConRec:cCodSuc  :=cCodSuc
   oConRec:cTipDoc  :=GetFromVar("{oDp:xDPRECIBOSCLI}") //cTipDoc      
   oConRec:cCodigo  :=cCodigo
   oConRec:cNumero  :=cNum1
   oConRec:lVenta   :=lVenta
   oConRec:lView    :=lView
   oConRec:lClose   :=lClose
   oConRec:cResp    :="Documento sin Contabilizar"
   oConRec:cTipTra  :="P" // cTipTra
   oConRec:lMsgBar  :=.F.
   oConRec:bAction  :={||.T.}

   @ 1, 1.0 GROUP oConRec:oGroup TO 11.4,6 PROMPT " Documento ";
            FONT oFontG

   @ 1, 1.0 GROUP oConRec:oGroup TO 11.4,6 PROMPT GetFromVar("{oDp:xDPRECIBOSCLI}");
            FONT oFontG

   @ 1, 1.0 GROUP oConRec:oGroup TO 11.4,6 PROMPT " Proceso ";
            FONT oFontG

   @ 0,0 SAY "Número:" RIGHT

   @ 1,1 SAY GetFromVar("{oDp:xDPCLIENTES}")   RIGHT
   @ 2,1 SAY "Código:" RIGHT
   @ 3,1 SAY "Número:" RIGHT

    @ 1,10 SAY SQLGET("DPCLIENTES","CLI_NOMBRE","CLI_CODIGO"+GetWhere("=",oConRec:cCodigo)) 
    @ 2,10 SAY oConRec:cCodigo RIGHT
    @ 3,10 SAY oConRec:cNumero RIGHT

    @ 4,10 SAY oConRec:oResp;
               PROMPT oConRec:cResp

    @ 1,1 GET oConRec:oNumero VAR oConRec:cNumCom;
          RIGHT;
          VALID CERO(oConRec:cNumCom)

    @ 6.4, 1.0 CHECKBOX oConRec:oView;
                      VAR oConRec:lView;
                      PROMPT ANSITOOEM("Visualizar")

    @ 6.4, 1.0 CHECKBOX oConRec:oClose;
                      VAR oConRec:lClose;
                      PROMPT ANSITOOEM("Cerrar al Finalizar")

/*
    @04, 13  SBUTTON oBtn ;
             SIZE 42, 23 FONT oFontG;
             FILE "BITMAPS\RUN.BMP" ;
             LEFT PROMPT "Ejecutar";
             NOBORDER;
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION (oConRec:RUNASIENTO(oConRec:cCodSuc,oConRec:cNumero,oConRec:cNumero,oConRec:cNumCom,oConRec:lVenta),;
                     oConRec:RUNSAVE())

   @04, 13  SBUTTON oBtn ;
            SIZE 42, 23 FONT oFontG;
            FILE "BITMAPS\XSALIR.BMP" ;
            LEFT PROMPT "Cerrar";
            NOBORDER;
            COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
            ACTION oConRec:Close() CANCEL
*/

    oConRec:Activate({||NMCONBAR(oConRec)})


RETURN .T.


/*
// Coloca la Barra de Botones
*/
FUNCTION NMCONBAR(oConRec)
   LOCAL oCursor,oBar,oBtn,oFont,oCol,nDif
   LOCAL nWidth :=0 // Ancho Calculado seg£n Columnas
   LOCAL nHeight:=0 // Alto
   LOCAL nLines :=0 // Lineas
   LOCAL oDlg:=oConRec:oDlg
   
   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52,60 OF oDlg 3D CURSOR oCursor

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -10 BOLD

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Ejecutar";
          FILENAME "BITMAPS\RUN.BMP";
          ACTION (oConRec:RUNASIENTO(oConRec:cCodSuc,oConRec:cNumero,oConRec:cNumero,oConRec:cNumCom,oConRec:lVenta),;
                  EVAL(oConRec:bAction),;
                  oConRec:RUNSAVE())



   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Cerrar";
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION oConRec:Close()

   oBar:SetColor(CLR_BLACK,oDp:nGris)
   AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  
RETURN .T.



PROCE RUNASIENTO(cCodSuc,cNum1,cNum2,cNumCom,lVenta)
    LOCAL oBcoMov,oCajMov,nCxC
    LOCAL dFchRec  //Fecha del Recibo
    LOCAL oTable,cWhere,cCbtNum:="",cCtaCXC,nMonto,cOrg,cDescri,cCodigo,cCtaCaj
    LOCAL cDocCli:="DPDOCPRO"
    LOCAL cRevCta,cRevCtaCli
    LOCAL oDb:=OpenOdbc(oDp:cDsnData),cSql

    // ?  cCodSuc,cNum1,cNum2,cNumCom,lVenta

    DEFAULT cNum1  :=STRZERO(001,8),;
            cNum2  :=STRZERO(100,8),;
            cNumCom:=STRZERO(1,8)  ,;
            cCodSuc:=oDp:cSucursal ,;
            lVenta :=.F.
           
    oDp:cCtaCxCExt:=SQLGET("DPCODINTEGRA","CIN_CODCTA","CIN_CODIGO='CXCEXT'"    )
    oDp:cCtaCxCNac:=SQLGET("DPCODINTEGRA","CIN_CODCTA","CIN_CODIGO='CXCNAC'"    )
    cOrg          :="VTA"
    nCxC          :=1

   cOrg  :="VTA"

   cWhere:="REC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
           GetWhereAnd("REC_NUMERO",cNum1,cNum2)


   /*
   // JN 07/11/2020 Resuelve Fechas de Asientos
   */

    cSql:=[ UPDATE DPASIENTOS ]+;
          [ INNER JOIN DPRECIBOSCLI ON REC_CODSUC=MOC_CODSUC AND REC_NUMERO=MOC_DOCPAG AND MOC_ORIGEN="VTA"  ]+;
          [ SET MOC_FECHA=REC_FECHA ]+;
          [ WHERE ]+cWhere

   oDb:Execute(cSql)
 
   oTable:=OpenTable(" SELECT HIGH_PRIORITY REC_NUMERO,REC_CODIGO,CLI_NOMBRE,REC_CODSUC,DOC_TIPDOC,DOC_CODIGO,DOC_NUMERO,DOC_CXC,"+;
                     " DOC_NETO , REC_FECHA AS PAG_FECHA , TDC_CODCTA , TDC_DESCRI, "+;
                     " CLI_RESIDE AS RESIDE, REC_CBTNUM,REC_FECHA, REC_TIPDOC,REC_NUMDOC,DOC_CENCOS,REC_TIPPAG,REC_MONTO "+;
                     " FROM  DPRECIBOSCLI "+;
                     " LEFT  JOIN DPDOCCLI    ON REC_NUMERO=DOC_RECNUM AND REC_CODSUC=DOC_CODSUC AND REC_CODIGO=DOC_CODIGO AND REC_FECHA=DOC_FECHA AND DOC_TIPTRA='P' AND DOC_ACT<>0 "+;
                     " INNER JOIN DPCLIENTES  ON REC_CODIGO=CLI_CODIGO "+;
                     " LEFT  JOIN DPTIPDOCCLI ON DOC_TIPDOC=TDC_TIPO   "+;
                     " WHERE "+cWhere+;
                     " ORDER BY REC_NUMERO ",.T.)

//    ?clpcopy(oTable:cSql)
   WHILE !oTable:Eof()

      cCbtNum:=oTable:REC_NUMERO
      cCodigo:=oTable:REC_CODIGO
      dFchRec:=oTable:REC_FECHA

      IF !Empty(oTable:REC_CBTNUM)


          cWhere:=" MOC_CODSUC"+GetWhere("=" , cCodSuc          )+" AND "+;
                  " MOC_DOCPAG"+GetWhere("=" , cCbtNum          )+" AND "+;
                  " MOC_NUMCBT"+GetWhere("=" , oTable:REC_CBTNUM)+" AND "+;
                  " MOC_ACTUAL"+GetWhere("=" , "S"              )+" AND "+;
                  " MOC_TIPTRA"+GetWhere("=" , "P"              )+" AND "+;
                  " MOC_ORIGEN"+GetWhere("=" , cOrg             )

          IF MYSQLGET("DPASIENTOS","MOC_ACTUAL",cWhere)="S"
             oTable:DbSkip()
             LOOP
          ENDIF

          cWhere:=" MOC_CODSUC"+GetWhere("=" , cCodSuc          )+" AND "+;
                  " MOC_DOCPAG"+GetWhere("=" , cCbtNum          )+" AND "+;
                  " MOC_NUMCBT"+GetWhere("=" , oTable:REC_CBTNUM)+" AND "+;
                  " MOC_ACTUAL"+GetWhere("=" , "N"              )+" AND "+;
                  " MOC_TIPTRA"+GetWhere("=" , "P"              )+" AND "+;
                  " MOC_ORIGEN"+GetWhere("=" , cOrg             )

          SQLDELETE("DPASIENTOS",cWhere)

// ? oDp:cSql,"ELIMINAR"

      ENDIF

      EJECUTAR("DPDELCBTEV")

      oDp:cTipAsiento:="PAG" // Recibo de Ingreso
  
      WHILE !oTable:Eof() .AND. cCbtNum=oTable:REC_NUMERO 

         // ? cCbtNum,oTable:RESIDE,oTable:REC_TIPDOC
         // Anticipos

         oDp:cTipAsiento:="CXC" // documento del pago
         
         IF oTable:REC_TIPPAG="A"

           cWhere :="DOC_CODSUC"+GetWhere("=",oDp:cSucursal    )+" AND "+;
                    "DOC_TIPDOC"+GetWhere("=","ANT"            )+" AND "+;
                    "DOC_NUMERO"+GetWhere("=",oTable:REC_NUMDOC)+" AND "+;
                    "DOC_TIPTRA"+GetWhere("=","D"              )

           EJECUTAR("AUDITORIA","CNT",.F.,"DPDOCCLI",oDp:cSucursal+",ANT,"+oTable:REC_NUMDOC+",P",NIL,NIL,NIL,NIL,cNumCom)

           SQLUPDATE("DPDOCCLI",{"DOC_NETO","DOC_ESTADO","DOC_ACT","DOC_FECHA"},{oTable:REC_MONTO,"A",1,oTable:PAG_FECHA},cWhere)

        ELSE

           EJECUTAR("AUDITORIA","CNT",.F.,"DPDOCCLI",oDp:cSucursal+","+oTable:DOC_TIPDOC+","+oTable:DOC_NUMERO+",P",NIL,NIL,NIL,NIL,cNumCom)

        ENDIF

        IF !Empty(oTable:REC_TIPDOC)  
            // ? oTable:DOC_CODSUC,oTable:REC_TIPDOC,oTable:REC_CODIGO,oTable:REC_NUMDOC
            EJECUTAR("DPDOCCONTAB",cNumCom,oTable:REC_CODSUC,oTable:REC_TIPDOC,oTable:REC_CODIGO,oTable:REC_NUMDOC,lVenta, .F. , cCbtNum , "D")
            // Debe Contabilizar el Documento
        ENDIF

        IF oTable:DOC_TIPDOC="OPA" // otros Pagos
            EJECUTAR("DPDOCCONTAB",cNumCom,oTable:REC_CODSUC,oTable:DOC_TIPDOC,oTable:DOC_CODIGO,oTable:DOC_NUMERO,lVenta, .F. , cCbtNum , "P")
            // Debe Contabilizar el Documento
        ENDIF

        IF oTable:DOC_TIPDOC!="OPA" // .AND. !oTable:REC_TIPDOC="ANT"
 
           cCtaCXC:=MYSQLGET("DPCLIENTECTA","CXC_CTACRE,CXC_CTADEB","CXC_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                            "CXC_TIPDOC"+GetWhere("=",oTable:DOC_TIPDOC))
           
           // Revisa las Cuentas Asignadas en Ficha del Cliente Cuenta por Cobrar
              cRevCtaCli:=MYSQLGET("DPCLIENTES"  ,"CLI_CUENTA","CLI_CODIGO"+GetWhere("=",cCodigo))

           // Verifica si hay Cuenta Asignadas distintas a Indefinida Segun ficha del Cliente 
           IF Empty(cCtaCXC)  .AND. !cRevCtaCli=oDp:cCtaIndef  //.OR.cCtaCxC="Indefinida" 
              cCtaCxC:=MYSQLGET("DPCLIENTES"  ,"CLI_CUENTA","CLI_CODIGO"+GetWhere("=",cCodigo))
           ENDIF
     
           // Cuenta Según Código de Integración
           IF Empty(cCtaCXC).OR.cCtaCxC="indefinida" 
              cCtaCXC:=IIF(!oTable:RESIDE="S",oDp:cCtaCxCExt, oDp:cCtaCxCNac)
           ENDIF
   
           // Verifica si hay Cuenta Asignadas distintas a Indefinida Segun ficha del Cliente 
           IF Empty(cCtaCXC).OR.cCtaCxC="Indefinida" 
              cCtaCxC:=MYSQLGET("DPCLIENTES"  ,"CLI_CUENTA","CLI_CODIGO"+GetWhere("=",cCodigo))
           ENDIF 

           IF oTable:DOC_TIPDOC="RTI" // otros Pagos
              cCtaCXC:=MYSQLGET("DPTIPDOCCLI","TDC_CODCTA","TDC_TIPO"+GetWhere("=",oTable:DOC_TIPDOC))
           ENDIF

           IF oTable:DOC_TIPDOC="RVI" // otros Pagos
              cCtaCXC:=MYSQLGET("DPTIPDOCCLI","TDC_CODCTA","TDC_TIPO"+GetWhere("=",oTable:DOC_TIPDOC))
           ENDIF

           IF oTable:DOC_TIPDOC="RET" // otros Pagos
              cCtaCXC:=MYSQLGET("DPTIPDOCCLI","TDC_CODCTA","TDC_TIPO"+GetWhere("=",oTable:DOC_TIPDOC))
           ENDIF

           IF oTable:DOC_TIPDOC="RMU" // otros Pagos
              cCtaCXC:=MYSQLGET("DPTIPDOCCLI","TDC_CODCTA","TDC_TIPO"+GetWhere("=",oTable:DOC_TIPDOC))
           ENDIF

           IF oTable:DOC_TIPDOC="RMC" // otros Pagos
              cCtaCXC:=MYSQLGET("DPTIPDOCCLI","TDC_CODCTA","TDC_TIPO"+GetWhere("=",oTable:DOC_TIPDOC))
           ENDIF

           nMonto :=oTable:DOC_NETO*oTable:DOC_CXC 
           cDescri:=GetFromVar("Rec./Ingr. ")+":"+cCbtNum+" "+ALLTRIM(oTable:TDC_DESCRI)+" "+;
                    oTable:DOC_NUMERO+" "+oTable:CLI_NOMBRE

           oDp:cTipAsiento:="CXC" // documento del pago
  
// ? "CREAR ASIENTO", oDp:cTipAsiento

           EJECUTAR("ASIENTOCREA",cCodSuc,cNumCom,oTable:REC_FECHA,cOrg,cCtaCXC,oTable:DOC_TIPDOC,oTable:DOC_NUMERO,cDescri,nMonto,cCodigo , "P" , cCbtNum , oTable:DOC_CENCOS,cNum1)

        ENDIF

        SQLUPDATE("DPRECIBOSCLI","REC_CBTNUM",cNumCom,"REC_CODSUC"+GetWhere("=",cCodSuc)+" AND "+;
                                                      "REC_NUMERO"+GetWhere("=",cCbtNum))

        oTable:DbSkip()

       ENDDO

       // Aqui Lee los Asientos de Caja
       oCajMov:=OpenTable(" SELECT HIGH_PRIORITY CAJ_FECHA,CAJ_CODCAJ,CAJ_TIPO,CAJ_BCODIR,CAJ_FECHA,CAJ_NUMERO,CAJ_MONTO,CAJ_NUMTRA, "+;
                          " ICJ_CUENTA,ICJ_NOMBRE,CAJ_DESCRI,CAJ_CODCAJ,CAJ_CENCOS "+;
                          " FROM DPCAJAMOV "+;
                          " INNER JOIN DPCAJAINST ON CAJ_TIPO=ICJ_CODIGO "+;
                          " WHERE CAJ_DOCASO"+GetWhere("=",cCbtNum)+;
                          " AND CAJ_CODSUC"+GetWhere("=",cCodSuc)+;  
                          " AND CAJ_ORIGEN"  +GetWhere("=","REC")+;
                          " AND CAJ_ACT=1",.T.)


        oCajMov:GoTop()

        WHILE !oCajMov:Eof()

           oDp:cTipAsiento:="REC" // Recibo de Ingreso

           nMonto :=oCajMov:CAJ_MONTO*nCxC
           cCtaCaj:=SQLGET("DPCAJA","CAJ_CODCTA","CAJ_CODIGO"+GetWhere("=",oCajMov:CAJ_CODCAJ))

           IF oDp:cCtaIndef=ALLTRIM(cCtaCaj)
              cCtaCaj:=oCajMov:ICJ_CUENTA
           ENDIF

           cDescri:="Recibo: "+cCbtNum +" "+oCajMov:CAJ_DESCRI

           EJECUTAR("AUDITORIA","CNT",.F.,"DPCAJAMOV",oDp:cSucursal+","+oCajMov:CAJ_TIPO+","+oCajMov:CAJ_NUMERO,NIL,NIL,NIL,NIL,cNumCom)

           EJECUTAR("ASIENTOCREA",cCodSuc,cNumCom,dFchRec,cOrg,cCtaCaj,oCajMov:CAJ_TIPO,oCajMov:CAJ_NUMERO,cDescri,nMonto,oCajMov:CAJ_CODCAJ, "P" , cCbtNum, oCajMov:CAJ_CENCOS)

           oCajMov:DbSkip()

        ENDDO

        oCajMov:End()

        //
        // Busca los Asientos de Banco
        // 

        oBcoMov:=OpenTable(" SELECT HIGH_PRIORITY MOB_TIPO,MOB_CUENTA,MOB_FECHA,MOB_CODBCO,MOB_DOCUME,MOB_MONTO,MOB_DESCRI,"+;
                           " BAN_NOMBRE,MOB_NUMTRA, "+;
                           " BCO_CUENTA,BCO_CTABAN,MOB_CENCOS "+;
                           " FROM DPCTABANCOMOV "+;
                           " INNER JOIN DPBANCOS   ON DPBANCOS.BAN_CODIGO = MOB_CODBCO "+;
                           " INNER JOIN DPCTABANCO ON BCO_CODIGO=MOB_CODBCO AND BCO_CTABAN=MOB_CUENTA "+;
                           " WHERE MOB_DOCASO"+GetWhere("=",cCbtNum)+;
                           "   AND MOB_CODSUC"+GetWhere("=",cCodSuc)+;
                           "   AND MOB_ORIGEN"+GetWhere("=","REC"  )+;
                           "   AND MOB_ACT=1",.T.)

//   ?CLPCOPY(oBcoMov:cSql)

         WHILE !oBcoMov:Eof() 

            oDp:cTipAsiento:="REC" // Recibo de Ingreso
 
            nMonto :=oBcoMov:MOB_MONTO*nCxC
            cCtaCXC:=oBcoMov:BCO_CUENTA
            //cDescri:=GetFromVar("{oDp:xDPRECIBOSCLI}")+":"+cCbtNum+" "+ALLTRIM(oBcoMov:MOB_DESCRI) // +" / "+ALLTRIM(oCajMov:ICJ_NOMBRE)
            cDescri:="Recibo: "+cCbtNum+" "+ALLTRIM(oBcoMov:MOB_DESCRI) // +" / "+ALLTRIM(oCajMov:ICJ_NOMBRE)
            //EJECUTAR("ASIENTOCREA",cCodSuc,cNumCom,oBcoMov:MOB_FECHA,cOrg,cCtaCXC,oBcoMov:MOB_TIPO,oBcoMov:MOB_DOCUME,cDescri,nMonto,oBcoMov:BCO_CTABAN, "P" , cCbtNum, oBcoMov:MOB_CENCOS )

            EJECUTAR("AUDITORIA","CNT",.F.,"DPCTABANCOMOV",oDp:cSucursal+","+oBcoMov:MOB_TIPO+","+oBcoMov:MOB_DOCUME,NIL,NIL,NIL,NIL,cNumCom)

            EJECUTAR("ASIENTOCREA",cCodSuc,cNumCom,dFchRec,cOrg,cCtaCXC,oBcoMov:MOB_TIPO,oBcoMov:MOB_DOCUME,cDescri,nMonto,oBcoMov:BCO_CTABAN, "P" , cCbtNum, oBcoMov:MOB_CENCOS )
            oBcoMov:DbSkip()
         ENDDO

         oBcoMov:End()

    ENDDO

    // oTable:Browse()
    oTable:End()

RETURN .T.

FUNCTION RUNSAVE()
  LOCAL oData

  oConRec:cResp:="Documento Contabilizado Exitosamente"
  oConRec:oResp:Refresh(.T.)


  oData:=DATASET("RECCONTAB","ALL")

  oData:Set("CLOSE",oConRec:lClose)
  oData:Set("VIEW" ,oConRec:lView )

  oData:Save()
  oData:End()

  IF oConRec:lView

     EJECUTAR("DPPAGVIEWCON",oConRec:cCodSuc,oConRec:cNumero,oConRec:lVenta)

  ENDIF

  IF oConRec:lClose   
     oConRec:Close()
  ENDIF

RETURN .T.
// EOF ESTANDAR
