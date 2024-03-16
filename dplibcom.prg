// Programa   : DPLIBCOM
// Fecha/Hora : 15/10/2005 12:28:25
// Propósito  : Generar Libro de Compras
// Creado Por : Juan Navas
// Llamado por: DPMENU
// Aplicación : Compras
// Tabla      : DPDOCPRO

#INCLUDE "DPXBASE.CH"

PROCE MAIN(lConEsp,lPlanilla,oLiq,cCodSuc,dDesde,dHasta,cNumero,lFecha,lFrm,lSemana)
  LOCAL oBtn,oFont,cModelo:="",aSeries:={},cWhere,nMes,nAno
  LOCAL cCodigo:="LIBROCOM"
//LOCAL aModelo:={"Clásico","IVA con Rebaja","Rebaja como Alicuota"}
  LOCAL aModelo:={"Rebaja como Alicuota","Clásico sin Rebaja","Sin columna de Importación"}
  LOCAL dDesde_:=dDesde,dHasta_:=dHasta,cNumero_:=cNumero
  LOCAL aRango :={},lRango:=.F.,nRadio:=1
  LOCAL oCursor,oBar,oBtn,oFont,oCol
  LOCAL oDlg:=oLibCom:oDlg
  LOCAL nLin:=0
  LOCAL oData,nLibCom

// ? lConEsp,lPlanilla,oLiq,cCodSuc,dDesde,dHasta,cNumero,lFecha,lFrm,lSemana,"lConEsp,lPlanilla,oLiq,cCodSuc,dDesde,dHasta,cNumero,lFecha,lFrm,lSemana"

  EJECUTAR("DPDOCPRORTICHKNUM") // Valida la numeración de las retenciones de IVA desde seleccion General

  oData:=DATASET("LIBCOM","ALL")

  nLibCom:=oData:Get("nLibCom"   ,1 ) // Número de Libro de Compras
  oData:End(.F.)

  DEFAULT lConEsp:=.F., lPlanilla:=.F., cCodSuc:=oDp:cSucursal

  DEFAULT lFecha :=.F.,;
          lFrm   :=.F.,;
          lSemana:=.T.

  DEFAULT cCodSuc:=oDp:cSucursal

 // Contribuyente especiales 

  IF LEFT(oDp:cTipCon,1)="E" .OR. LEFT(oDp:cTipCon,1)="G" .AND. dDesde=NIL

      IF Empty(dHasta)
         dHasta:=EJECUTAR("GETLUNES",oDp:dFecha)-1
      ENDIF

      IF Empty(dDesde)
         dDesde:=dHasta-6
      ENDIF

      lSemana:=.T.
      lFecha :=.F.
                   
  ENDIF

  IF LEFT(oDp:cTipCon,1)="O" .AND. dDesde=NIL
     dDesde:=FCHINIMES(oDp:dFecha)
     dHasta:=FCHFINMES(dDesde)
  ENDIF

  IF ValType(dDesde)="D" .AND. ValType(dHasta)="D"
     aRango :={dDesde,dHasta}
     lRango :=.T.
     lSemana:=.T.
  ENDIF

  IF lFecha

    // Busca la Primera Fecha Planificada, y sugiere la Fecha Anterior
    cWhere:="PFT_CODSUC"+GetWhere("=",cCodSuc    )+" AND "+;
            "PFT_CODEMP"+GetWhere("=",oDp:cEmpCod)+" AND "+;
            "PFT_CODIGO"+GetWhere("=",cCodigo    )

    dDesde :=SQLGET("DPFORMYTAREASPROG","PFT_DESDE",cWhere+" ORDER BY PFT_DESDE LIMIT 1")
    dDesde :=IF(Empty(dDesde),oDp:dFecha,FCHINIMES(dDesde)-1)
    cNumero:=""

  ENDIF

  IF ValType(oLiq)="O" .AND. !lFrm 

     dDesde:=oLiq:dDesde
     dhasta:=oLiq:dHasta
     dFecha:=oLiq:dFecha
     PUBLICO("oLibCom",oLiq)
     RETURN HACERLIBCOM(dDesde,dHasta,dFecha,oLiq,cCodSuc,.F.,cNumero)  // Envia la Tabla Hacia la LIQ30

  ENDIF

  IF ValType(oLiq)="O" .AND. lFrm
     dDesde:=oLiq:dDesde_
     dhasta:=oLiq:dHasta_
     dFecha:=oLiq:dFecha_
  ENDIF


  IF Type("oLibCom")="O" .AND. oLibCom:oWnd:hWnd>0
     EJECUTAR("BRRUNNEW",oLibCom,GetScript())
     RETURN oLibCom
  ENDIF

// 18/07/2022
//  IF Empty(cNumero)
//     cNumero:=EJECUTAR("GETNUMPLAFYT",cCodigo,dDesde,cCodSuc)
//  ENDIF

  IF Empty(cNumero)
     cNumero:=EJECUTAR("GETNUMPLAFISCAL",cCodSuc,"F30",dHasta)
  ENDIF


//? dDesde,dHasta,"dDesde,dHasta"

  cWhere:="PFT_CODIGO"+GetWhere("=",cCodigo        )+" AND "+;
          "PFT_CODEMP"+GetWhere("=",oDp:cEmpCod    )+" AND "+;
          "PFT_CODSUC"+GetWhere("=",cCodSuc        )+" AND "+;
          GetWhereAnd("PFT_DESDE",oDp:dFchInicio,oDp:dFchCierre)

  // Se cambio a Fecha De inicio de deberes formales en configuracion oDp:dFchInCalF de la Empresa
  // GetWhereAnd("PFT_DESDE",oDp:dFchInicio,oDp:dFchCierre)


  IF COUNT("DPFORMYTAREASPROG",cWhere)=0 .AND. !lFecha .AND. lSemana

     // Crea el Calendario durante el Ejercicio

     EJECUTAR("DPFORMYTAREASP",cCodigo)

/*
// 05/10/2022 , debe ser generado con o sin planificación
     IF COUNT("DPFORMYTAREASPROG",cWhere)=0
        MsgMemo("Libro de Compras no tiene Calendario como Formalidad ["+cCodigo+"]")
        RETURN .T. 
     ENDIF
*/
  ENDIF

  // Libro de Compras debe ser generado desde el Calendario Fiscal

  IF Empty(cNumero) .AND. !lFecha .AND. !lSemana .AND. .F. 
     EJECUTAR("BRLIBCOM")
     RETURN .F.
  ENDIF

/*
  IF Empty(dHasta)
     dHasta:=dDesde
  ENDIF

  IF !Empty(aRango)
     dDesde:=aRango[1]
     dHasta:=aRango[2]
  ENDIF


  IF Empty(cNumero)

     dDesde:=FCHINIMES(oDp:dFecha)

     IF DAY(dDesde)<=15 

        dDesde  :=dDesde-1
        nMes    :=MONTH(dDesde)
        dDesde  :=CTOD("16/"+LSTR(MONTH(dDesde))+"/"+LSTR(YEAR(dDesde)))
        dHasta  :=FCHFINMES(dDesde)
        nAno    :=YEAR(dHasta)
        nRadio  :=2

     ELSE

        nMes    :=MONTH(dDesde)
        dHasta  :=CTOD("15/"+LSTR(MONTH(dDesde))+"/"+LSTR(YEAR(dDesde)))
        nAno    :=YEAR(dHasta)
        nRadio  :=1

     ENDIF

     // dHasta:=FCHFINMES(oDp:dFecha)

  ENDIF
*/


  DPEDIT():New("Libro de Compras ","forms\dplibcom.edt","oLibCom",.T.)

  nMes:=MONTH(dDesde)
  nAno:=YEAR(dDesde)

  oLibCom:aMeses   :={"Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio","Agosto","Septiembre","Octubre","Noviembre","Diciembre"}
  oLibCom:nMes     :=nMes  //  MONTH(oDp:dFecha)
  oLibCom:nAno     :=nAno  //YEAR(oDp:dFecha)
  oLibCom:nRecord  :=0
  oLibCom:cCodSuc  :=oDp:cSucursal
  oLibCom:cModelo  :=cModelo
  oLibCom:lConEsp  :=lConEsp
  oLibCom:dFecha   :=oDp:dFecha
  oLibCom:dDesde   :=dDesde
  oLibCom:dHasta   :=dHasta
  oLibCom:cNumero  :=cNumero
  oLibCom:cCodigo  :="LIBROCOM"
  oLibCom:lFecha   :=lFecha
  oLibCom:cNumLib  :=RIGHT(STRZERO(oLibCom:nAno,4),2)+STRZERO(oLibCom:nMes,2)
  oLibCom:cModelo  :=aModelo[nLibCom]
  oLibCom:aModelo  :=aModelo
  oLibCom:aModRpt  :={"DPLIBCOMCOL.RPT","DPLIBCOMCO.RPT","dplibcomsincolimportación.rpt"}
  oLibCom:lFrm     :=lFrm
  oLibCom:lSemana  :=lSemana
  oLibCom:lRango   :=lRango
  oLibCom:lCrystal :=.F.
  oLibCom:lActivate:=.F.
  oLibCom:nRadio   :=nRadio
  oLibCom:oNumero  :=NIL

  oLibCom:SetScript("DPLIBCOM")
  
  oLibCom:lSemana  :=.T. // JN 18/07/2022 Para seleccionar año y mes
  oLibCom:lFrm     :=.T. 


  @ 03,0 GROUP oGrupo TO 06, 60 PROMPT "Periodo"

  @ 3,2 SAY "Año" RIGHT
  @ 3,2 SAY "Mes" RIGHT

  @ 0.5,3 GET oLibCom:oAno VAR oLibCom:nAno PICTURE "9999" SPINNER;
          WHEN Empty(oLibCom:cNumero) .AND. !oLibCom:lFrm .AND. !oLibCom:lSemana;
          VALID oLibCom:DESDEHASTA()

  oLibCom:oAno:bWhen:={||.T.} // 18/07/2022 Usuario requiere acceder al mes 

  @ 3,2 SAY oLibCom:oSayRecord PROMPT "Registros:"

  @ 2.0,3 COMBOBOX oLibCom:oMes VAR oLibCom:nMes;
          ITEMS oLibCom:aMeses;
          WHEN Empty(oLibCom:cNumero) .AND. !oLibCom:lFrm .AND. !oLibCom:lSemana;
          ON CHANGE oLibCom:DESDEHASTA()

  ComboIni(oLibCom:oMes)

  oLibCom:oMes:bWhen:={||.T.} // 18/07/2022 Usuario requiere acceder al mes 

  oLibCom:oMes:cMsg    :="Seleccione el Mes"
  oLibCom:oMes:cTooltip:="Seleccione el Mes"

  @ 07, 20 BMPGET oLibCom:oDesde  VAR oLibCom:dDesde;
                  PICTURE "99/99/9999";
                  NAME "BITMAPS\Calendar.bmp";
                  ACTION LbxDate(oLibCom:oDesde ,oLibCom:dDesde);
                  SIZE 76,24;
                  WHEN oLibCom:lSemana ;
                  FONT oFont

   oLibCom:oDesde:cToolTip:="F6: Calendario"

   @ 09, 60     BMPGET oLibCom:oHasta  VAR oLibCom:dHasta;
                PICTURE "99/99/9999";
                NAME "BITMAPS\Calendar.bmp";
                ACTION LbxDate(oLibCom:oHasta,oLibCom:dHasta);
                SIZE 80,23;
                WHEN oLibCom:lSemana ;
                FONT oFont


  /*
  // Modelo del libro de Compras
  */
  @ 2.0,3 COMBOBOX oLibCom:oModelo VAR oLibCom:cModelo;
          ITEMS oLibCom:aModelo;
          WHEN LEN(oLibCom:oModelo:aItems)>1

  ComboIni(oLibCom:oModelo)

  oLibCom:oModelo:cMsg    :="Modelo del Libro de Compras"
  oLibCom:oModelo:cTooltip:="Modelo del Libro de Compras"


  // SUCURSAL
  @ .1,06 BMPGET oLibCom:oCodSuc VAR oLibCom:cCodSuc;
                 VALID CERO(oLibCom:cCodSuc,NIL,.T.) .AND.;
                            oLibCom:FindCodSuc();
                 NAME "BITMAPS\FIND.BMP";
                 ACTION (oDpLbx:=DpLbx("DPSUCURSAL",NIL,NIL),;
                         oDpLbx:GetValue("SUC_CODIGO",oLibCom:oCodSuc));
                 WHEN Empty(oLibCom:cNumero);
                 SIZE 48,10

  @ 3,2 SAY oLibCom:oSucNombre PROMPT SQLGET("DPSUCURSAL","SUC_DESCRI","SUC_CODIGO"+GetWhere("=",oLibCom:cCodSuc));
            UPDATE

  @ 02,01 METER oLibCom:oMeter VAR oLibCom:nRecord

  @ 4,1 SAY GetFromVar("{oDp:xDPSUCURSAL}")+":"

  @ 3,2 SAY "Modelo Libro Compras"

  @ 5,10 SAY "Desde" RIGHT
  @ 5,20 SAY "Hasta" RIGHT

  @ 02,10  RADIO oLibCom:oRadio VAR oLibCom:nRadio;
           ITEMS "&Primera Quincena", "&Segunda Quincena" SIZE 60, 13 ;
           ON CHANGE oLibCom:HACERQUINCENA();
           WHEN LEFT(oDp:cTipCon,1)<>"O"

  // Debe buscar el Siguiente 
  @ 3,10 BUTTON oBtn PROMPT " > " ACTION oLibCom:NEXTMES(+1);
                WHEN .T.

  oBtn:cToolTip:="Mes Siguiente"

  @ 3,20 BUTTON oBtn PROMPT " < " ACTION oLibCom:NEXTMES(-1);
                WHEN .T.

  oBtn:cToolTip:="Mes Anterior"


  oLibCom:Activate() // {|| oLibCom:ViewDatBar()})

  oLibCom:lActivate:=.T.

  DEFINE CURSOR oCursor HAND
// DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oLibCom:oDlg 3D CURSOR oCursor


  IF !oDp:lBtnText 
     DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oLibCom:oDlg 3D CURSOR oCursor
   ELSE 
     DEFINE BUTTONBAR oBar SIZE oDp:nBtnWidth+20,oDp:nBarnHeight+6 OF oLibCom:oDlg 3D CURSOR oCursor 
   ENDIF 


  DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 BOLD

  DEFINE BUTTON oBtn;
         OF oBar;
         NOBORDER;
         FONT oFont;
         FILENAME "BITMAPS\RUN.BMP";
         TOP PROMPT "Ejecutar"; 
         ACTION (CursorWait(),;
                 oLibCom:lCrystal:=.F.,;
                 oLibCom:HACERFECHA(),;
                 oLibCom:HACERLIBCOM(oLibCom:dDesde,oLibCom:dHasta,NIL,NIL,oLibCom:cCodSuc,oLibCom:lFecha,oLibCom:cNumero),;
                 EJECUTAR("IVALOAD",oLibCom:dFecha))

  oLibCom:oBtnRun:=oBtn

// IF ISRELEASE("17.01")


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\RETIVA.bmp";
          TOP PROMPT "Ret/IVA"; 
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  EJECUTAR("BRLIBCOMRTI",NIL,NIL,12,oLibCom:dDesde,oLibCom:dHasta,NIL))

   oBtn:cToolTip:="Retenciones de IVA según Fecha de Declaración"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\bug.BMP";
          TOP PROMPT "Doc.sin #"; 
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  oLibCom:VALREISINNUM(.T.,.F.))

   oBtn:cToolTip:="Documentos sin Número de Control"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\facturacompra.BMP";
          TOP PROMPT "Facturas"; 
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  EJECUTAR("BRDOCPRORET",NIL,NIL,IF(LEFT(oDp:cTipCon,1)="O",oDp:nMensual,3),oLibCom:dDesde,oLibCom:dHasta,NIL))

   oBtn:cToolTip:="Documentos de Compras con Retenciones"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\calendar.BMP";
          TOP PROMPT "Periodos"; 
          ACTION (CursorWait(),;
                  oLibCom:VERDESDEHASTA())

   oBtn:cToolTip:="Ver fechas con documentos"

   oLibCom:oBtnFechas:=oBtn



// ENDIF

IF ISRELEASE("21.09") .OR. .T.

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ReintegroCobro32x32.bmp";
          TOP PROMPT "Reintegros"; 
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  EJECUTAR("BRREIDET",NIL,NIL,3,oLibCom:dDesde,oLibCom:dHasta,NIL))

   oBtn:cToolTip:="Reintegros"

ENDIF

  


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XBROWSEAMARILLO.bmp";
          TOP PROMPT "Sin Fecha"; 
          ACTION (CursorWait(),;             
                  EJECUTAR("BRDPDOCPRODOC","DOC_TIPDOC"+GetWhere("=","FAC")+" AND DOC_FCHDEC"+GetWhere("=",CTOD("")),oDp:nSucursal,12,oLibCom:dDesde,oLibCom:dHasta," [Facturas de Compra sin Fecha de Declaración]"))

   oBtn:cToolTip:="Facturas de Compra sin Fechas de Declaración"

/*  
   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ReintegroCobro32x32.bmp";
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  oLibCom:VALREISINNUM(.T.,.F.))

   oBtn:cToolTip:="Retenciones de IVA según Fecha de Declaración"
*/


IF oDp:lDpXbase .OR. .T.

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.bmp";
          TOP PROMPT "Crystal"; 
          ACTION (CursorWait(),;
                  oLibCom:lCrystal:=.T.,;
                  oLibCom:HACERFECHA(),;
                  oLibCom:HACERLIBCOM(oLibCom:dDesde,oLibCom:dHasta,NIL,NIL,oLibCom:cCodSuc,oLibCom:lFecha,oLibCom:cNumero),;
                  EJECUTAR("IVALOAD",oLibCom:dFecha))


   oBtn:cToolTip:="Editar Formato con Crystal Report debe estar Instalado"+CRLF+"Caso contrario no realiza Ejecución"


ENDIF

/*
   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\excelimportar.BMP";
          ACTION (CursorWait(),;
                  oLibCom:IMPORTXLS())
*/

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\UPLOAD.BMP",NIL,"BITMAPS\UPLOADG.BMP";
          TOP PROMPT "Subir"; 
          ACTION (oLibCom:cFileRpt:="CRYSTAL\"+oLibCom:aModRpt[oLibCom:oModelo:nAt],;
                  EJECUTAR("REPCRYSTAL_UP",NIL,oLibCom:cFileRpt))


   oBtn:cToolTip:="Subir Formatos Crystal Personalizados en AdaptaPro Server"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\DOWNLOAD.BMP",NIL,"BITMAPS\DOWNLOADG.BMP";
          TOP PROMPT "Descarga"; 
          ACTION oLibCom:cFileRpt:="CRYSTAL\"+oLibCom:aModRpt[oLibCom:oModelo:nAt],;
                 EJECUTAR("REPCRYSTAL_DOWN",NIL,oLibCom:cFileRpt);
          WHEN oDp:lDownPerson

   oBtn:cToolTip:="Descargar Formatos Crystal desde AdaptaPro Server"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          TOP PROMPT "Cerrar"; 
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION (CursorWait(),;
                  oLibCom:Close())

   oBtn:cToolTip:="Cerrar"

   oBar:SetColor(CLR_BLACK,oDp:nGris)
   AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})


   oBar:SetSize(0,95,.T.)

   IF !Empty(oLibCom:cNumero)
     @ 65,015 SAY " Número F30 "                             OF oBAR BORDER SIZE 80,20 PIXEL COLOR oDp:nClrLabelText ,oDp:nClrLabelPane  FONT oFont
     @ 65,100 SAY oLibCom:oNumero PROMPT " "+oLibCom:cNumero OF oBAR BORDER SIZE 90,20 PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow     FONT oFont
   ENDIF


// 18/07/2022
//   IF oLibCom:lFrm
//     @ 1,300+60 SAY " Periodo "                                        OF oBAR BORDER SIZE 70,20     PIXEL COLOR oDp:nClrLabelText ,oDp:nClrLabelPane  FONT oFont
//     @ 1,660+60 SAY " "+DTOC(oLibCom:dDesde)+"-"+DTOC(oLibCom:dHasta)  OF oBAR BORDER SIZE 70+120,20 PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow     FONT oFont
//   ENDIF

  // 01/03/2024 viene como parametro desde consulta
  IF !Empty(cNumero_) .AND. !Empty(dDesde_) .AND. !Empty(dHasta_)
     oLibCom:oDesde:VarPut(dDesde_,.T.)
     oLibCom:oHasta:VarPut(dHasta_,.T.)
     oLibCom:oAno:VarPut(YEAR(dDesde_),.T.)
     oLibCom:oMes:Select(MONTH(dDesde_))
     cNumero:=cNumero_
  ELSE
     oLibCom:HACERQUINCENA(.F.)
  ENDIF

RETURN .T.

FUNCTION HACERFECHA()

   IF !oLibCom:lFrm .AND. !oLibCom:lRango
     oLibCom:dDesde:=CTOD("01/"+STRZERO(oLibCom:oMes:nAt,2)+"/"+STRZERO(oLibCom:nAno))
     oLibCom:dHasta:=FCHFINMES(oLibCom:dDesde)
   ENDIF

RETURN
/*
// Barra de Botones
*/
FUNCTION ViewDatBar()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg:=oLibCom:oDlg
   LOCAL nLin:=0

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -12 BOLD

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\RUN.BMP";
          ACTION (CursorWait(),;
                  oLibCom:lCrystal:=.F.,;
                  oLibCom:HACERFECHA(),;
                  oLibCom:HACERLIBCOM(oLibCom:dDesde,oLibCom:dHasta,NIL,NIL,oLibCom:cCodSuc,oLibCom:lFecha,oLibCom:cNumero),;
                  EJECUTAR("IVALOAD",oLibCom:dFecha))

    oLibCom:oBtnRun:=oBtn

IF ISRELEASE("17.01")


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\RETIVA.bmp";
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  EJECUTAR("BRLIBCOMRTI",NIL,NIL,12,oLibCom:dDesde,oLibCom:dHasta,NIL))

   oBtn:cToolTip:="Retenciones de IVA según Fecha de Declaración"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\facturacompra.BMP";
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  EJECUTAR("BRDOCPRORET",NIL,NIL,3,oLibCom:dDesde,oLibCom:dHasta,NIL))

   oBtn:cToolTip:="Documentos de Compras con Retenciones"


ENDIF

IF ISRELEASE("21.09")

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ReintegroCobro32x32.bmp";
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  EJECUTAR("BRREIDET",NIL,NIL,3,oLibCom:dDesde,oLibCom:dHasta,NIL))

   oBtn:cToolTip:="Reintegros"

ENDIF

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\BUG.bmp";
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  oLibCom:VALREISINNUM(.T.,.F.))

   oBtn:cToolTip:="Retenciones de IVA según Fecha de Declaración"

/*  
   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\ReintegroCobro32x32.bmp";
          ACTION (CursorWait(),;
                  oLibCom:HACERFECHA(),;
                  oLibCom:VALREISINNUM(.T.,.F.))

   oBtn:cToolTip:="Retenciones de IVA según Fecha de Declaración"
*/


IF oDp:lDpXbase .OR. .T.

  DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\CRYSTAL.bmp";
          ACTION (CursorWait(),;
                  oLibCom:lCrystal:=.T.,;
                  oLibCom:HACERFECHA(),;
                  oLibCom:HACERLIBCOM(oLibCom:dDesde,oLibCom:dHasta,NIL,NIL,oLibCom:cCodSuc,oLibCom:lFecha,oLibCom:cNumero),;
                  EJECUTAR("IVALOAD",oLibCom:dFecha))


   oBtn:cToolTip:="Editar Formato con Crystal Report debe estar Instalado"+CRLF+"Caso contrario no realiza Ejecución"


ENDIF

/*
   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\excelimportar.BMP";
          ACTION (CursorWait(),;
                  oLibCom:IMPORTXLS())
*/

   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\UPLOAD.BMP",NIL,"BITMAPS\UPLOADG.BMP";
          ACTION (oLibCom:cFileRpt:="CRYSTAL\"+oLibCom:aModRpt[oLibCom:oModelo:nAt],;
                  EJECUTAR("REPCRYSTAL_UP",NIL,oLibCom:cFileRpt))

   oBtn:cToolTip:="Subir Formatos Crystal en AdaptaPro Server"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\DOWNLOAD.BMP",NIL,"BITMAPS\DOWNLOADG.BMP";
          ACTION oLibCom:cFileRpt:="CRYSTAL\"+oLibCom:aModRpt[oLibCom:oModelo:nAt],;
                 EJECUTAR("REPCRYSTAL_DOWN",NIL,oLibCom:cFileRpt);
          WHEN oDp:lDownPerson

   oBtn:cToolTip:="Descargar Formatos Crystal desde AdaptaPro Server"


   DEFINE BUTTON oBtn;
          OF oBar;
          NOBORDER;
          FONT oFont;
          FILENAME "BITMAPS\XSALIR.BMP";
          ACTION (CursorWait(),;
                  oLibCom:Close())

   oBtn:cToolTip:="Cerrar"

   oBar:SetColor(CLR_BLACK,oDp:nGris)
   AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

   IF !Empty(oLibCom:cNumero)
     @ 1,300+60 SAY " Número "          OF oBAR BORDER SIZE 70,20 PIXEL COLOR oDp:nClrLabelText ,oDp:nClrLabelPane  FONT oFont
     @ 1,360+60 SAY " "+oLibCom:cNumero OF oBAR BORDER SIZE 60,20 PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow     FONT oFont

   ENDIF

   IF oLibCom:lFrm
     @ 1,300+60 SAY " Periodo "                                        OF oBAR BORDER SIZE 70,20     PIXEL COLOR oDp:nClrLabelText ,oDp:nClrLabelPane  FONT oFont
     @ 1,660+60 SAY " "+DTOC(oLibCom:dDesde)+"-"+DTOC(oLibCom:dHasta)  OF oBAR BORDER SIZE 70+120,20 PIXEL COLOR oDp:nClrYellowText,oDp:nClrYellow     FONT oFont
   ENDIF

//   oLibCom:Activate(NIL)
 
RETURN .T.


FUNCTION HACERLIBCOM(dDesde,dHasta,dFecha,oLiq,cCodSuc,lFecha,cNumero,lExoner)
  LOCAL cSql,oTable,aTipDoc,nContar:=0,nContar1,oDpMovi,cSqlMovi,cClave:="",cFileHead,nLine:=0,cWhere:=""
  LOCAL aData,aStruct:={},cIndex,aSort,nIVA,nFECHA,nNUMERO,nCODIGO,nRecord:=0,nRecAct:=0,nBase:=0,I,aLine,nAt,cField
  LOCAL nMontoRti:=0,aTipIva:={},aStructP:={},nTIPO,cClav:=""
  LOCAL nIntBas:=0,nIntIva:=0 // Ventas Internas
  LOCAL nExpBas:=0            // Compras Exportación
  LOCAL nExpIva:=0			 // IVa Exportación
  LOCAL nGNBas :=0,nGNIva:=0  // Compras Internas Alicuota General
  LOCAL nS1Bas :=0,nS1Iva:=0  // Compras Internas Alicuota Adicional S1
  LOCAL nS2Bas :=0,nS2Iva:=0  // Compras Internas Alicuota Adicional S2
  LOCAL nRDBas :=0,nRDIva:=0  // Compras Internas Alicuota Adicional Reducida
  LOCAL nCampo
  LOCAL oRei,nBaseRei:=0,nExeRei:=0,nReiRD:=0,nReiGN:=0,nNsjRei:=0                 // Reintegro de Compras
  LOCAL dFchDec :=CTOD("")     // Fecha de Declaración de la Retención de IVA
  LOCAL cFileDbf:="CRYSTAL\DPLIBCOM.DBF"
  LOCAL cFileAju:="CRYSTAL\DPLIBCOMAJUS.DBF"
  LOCAL cTipDoc,cCodigo,cNumero,cFileRpt
  LOCAL cNumRti:=""

  // Totales Anticipos de IVA  // JN 10/04/2012
  LOCAL nTotBINS:=0,nTotBIEX:=0,nTotBIIMGN:=0,nTotBIIMRD:=0,nTotBIIMAD:=0,nTotBIINNS:=0,nTotBIINEX:=0,nTotBIINGN:=0,nTotBIINRD:=0,nTotBIINAD:=0
  LOCAL nTotCFEX:=0,nTotCFIMGN:=0,nTotCFIMRD:=0,nTotCFIMAD:=0,nTotCFINGN:=0,nTotCFINRD:=0,nTotCFINAD:=0
  LOCAL nTotRIEX:=0,nTotRIIMGN:=0,nTotRIIMRD:=0,nTotRIIMAD:=0,nTotRIINGN:=0,nTotRIINRD:=0,nTotRIINAD:=0
  LOCAL nTotAIEX:=0,nTotAIIMGN:=0,nTotAIIMRD:=0,nTotAIIMAD:=0,nTotAIINGN:=0,nTotAIINRD:=0,nTotAIINAD:=0
  LOCAL nTotNSTE:=0,nTotEXTE:=0,nTotEXTIGN:=0,nTotEXTIRD:=0,nTotEXTIAD:=0,nTotEXTNGN:=0,nTotEXTNRD:=0,nTotEXTNAD:=0,nTotEXTEI:=0

  //SYSANDES
  LOCAL aFechao:={}, aOperao:={},i:=1, z:=1

  // Columnas
  LOCAL nIVA_N_EX:=0,nIVA_N_RD:=0,nIVA_N_GN:=0,nIVA_N_S1:=0,nIVA_N_S2:=0,nIVA_N_NS:=0
  LOCAL nIVA_I_EX:=0,nIVA_I_RD:=0,nIVA_I_GN:=0,nIVA_I_S1:=0,nIVA_I_S2:=0,nIVA_I_NS:=0

  // De ver.6
  LOCAL nBASE_GN :=0,nBASE_RD :=0,nBASE_EX :=0
  LOCAL cIvaReb:=""
  LOCAL nField3,nField5,nField6,nField7,nField8,nField9,nField12,nField13,nField14
  LOCAL cDocProCta:=""
  LOCAL cWhereRei :=""
  LOCAL NREINS:=0
  LOCAL oData
 
  DEFAULT dDesde:=FCHINIMES(oDp:dFecha),dHasta:=FCHFINMES(oDp:dFecha),dFecha:=oDp:dFecha

  IF lFecha .AND. !oLibCom:VALDEBYTAR()
    RETURN .F.
  ENDIF

  DEFAULT lExoner:=.F.

  aTipDoc:=ASQL("SELECT TDC_TIPO   FROM DPTIPDOCPRO WHERE TDC_LIBCOM=1 AND TDC_IVA=1")
  aTipIva:=ASQL("SELECT TIP_CODIGO FROM DPIVATIP")

  EJECUTAR("IVALOAD",dHasta)


  IF oLiq=NIL
     nCantid:=oLibCom:VALREISINNUM(.F.,.T.)
  ENDIF



/*
  IF oLiq=NIL

     oTable:=OpenTable("SELECT * FROM DPLIBCOMPRAS WHERE "+;
                       "LIB_CODSUC"+GetWhere("=",cCodSuc        )+" AND "+;
                       "LIB_CODIGO"+GetWhere("=",oLibCom:cNumLib),.T.)
 
     IF oTable:RecCount()=0
       oTable:AppendBlank()
       oTable:cWhere:=""
     ENDIF

     oTable:Replace("LIB_CODIGO",oLibCom:cNumLib)
     oTable:Replace("LIB_CODSUC",cCodSuc        )
     oTable:Replace("LIB_FECHA" ,dHasta         )
     oTable:Replace("LIB_FCHEJE",oDp:dFecha     )
     oTable:Replace("LIB_OPEN"  ,.T.            )
     oTable:Commit(oTable:cWhere)
     oTable:End()

  ENDIF
*/

// " AND " + GetWhereOr("DOC_TIPDOC",aTipDoc)+;
// cWhereRei:=GetWhereAnd("DOC_FECHA",dDesde,dHasta)+" AND CCD_TIPDOC"+GetWhere("=","REI")+" AND DOC_NUMERO IS NULL " 
// ? cWhereRei,"cWhereRei"
// EJECUTAR("DPREINTOFAC",NIL,NIL,NIL,NIL,NIL,cWhereRei)

  SQLUPDATE("DPDOCPRO","DOC_ORIGEN","N",GetWhereAnd("DOC_FECHA",dDesde,dHasta)+[ AND DOC_ORIGEN IS NULL OR DOC_ORIGEN=""])
  SQLUPDATE("DPDOCPRO","DOC_CXP"   ,1  ,GetWhereAnd("DOC_FECHA",dDesde,dHasta)+[ AND DOC_TIPDOC]+GetWhere("=","FAC")+[ AND DOC_TIPTRA="D" AND DOC_CXP=0])

  EJECUTAR("DPDOCPROREIFIX",dDesde,dHasta,.F.,.F.)
  EJECUTAR("DPEMPGETRIF")

  cDocProCta:=" INNER JOIN DPDOCPRO ON CCD_CODSUC=DOC_CODSUC AND CCD_TIPDOC=DOC_TIPDOC AND CCD_CODIGO=DOC_CODIGO AND CCD_NUMERO=DOC_NUMERO AND CCD_TIPTRA=DOC_TIPTRA "

  cSql:="SELECT IF(DOC_ESTADO='NU',0,DOC_NETO) AS DOC_NETO,"+;
        "       DOC_FECHA ,"+;
        "       DOC_FCHDEC,"+;     
	   "       DOC_BASNET,"+;
        "       DOC_ORIGEN,"+;
        "       RTI_DOCNUM,"+;
        "       RTI_PORCEN,"+;
        "       RTI_NUMTRA,"+;
        "       RTI_FECHA,"+;
        "       RTI_TIPDOC,"+;
        "       DOC_CODIGO,"+;
        "       PRO_NIT   ,"+;
        "       PRO_TIPPER,"+;
        "       DOC_CODSUC,"+;
        "       IF(DOC_CODIGO='0000000000',DPPROVEEDORCERO.CCG_RIF   ,DPPROVEEDOR.PRO_RIF   ) AS PRO_RIF    ,"+;
        "       IF(DOC_CODIGO='0000000000',DPPROVEEDORCERO.CCG_NOMBRE,DPPROVEEDOR.PRO_NOMBRE) AS PRO_NOMBRE ,"+;
        "       IF(DOC_TIPDOC='FAC' OR DOC_TIPDOC='FCE'        ,DOC_NUMERO ,SPACE(10) ) AS DOC_FACTURA,"+;
        "       IF(DOC_TIPDOC='DEB'       ,DOC_NUMERO          ,SPACE(10)             ) AS DOC_DEBITO ,"+;
        "       IF(DOC_TIPDOC='DEV'       ,DOC_NUMERO          ,SPACE(10)             ) AS DOC_CREDITO,"+;
        "       IF(DOC_TIPDOC='RTI'       ,RTI_NUMTRA          ,SPACE(10)             ) AS RTI_NUMERO,"+;
        "       DOC_NUMFIS, "+;
        "       DOC_TIPDOC, "+;
        "       DOC_NUMERO, "+;
        "       IF(DOC_TIPDOC='RTI'       ,RTI_NUMERO           ,DOC_FACAFE           ) AS DOC_FACAFE,"+;
        "       IF(DOC_ESTADO='NU',0,MOV_IVA) AS MOV_IVA,"+;
        "       MOV_TIPIVA, "+;
        "       DOC_DCTO  , "+;
        "       DOC_RECARG, "+;
        "       DOC_OTROS , "+;
        "       DOC_ESTADO, "+;
        "       DOC_ANUFIS, "+;
        "       DOC_CXP   , "+;
        "       DOC_PLAIMP, "+;
        "       DOC_EXPIMP, "+;
        "       DOC_MTOIVA, "+;
        "       DOC_IVAREB, "+;
        "       DOC_IVABAS, "+;
        "       DOC_CREFIS, "+;
        "       DOC_NODEDU, "+;
        "       0 AS DOC_MTOSCF, "+;
        "       TDC_LIBTRA, "+;
        "       RTI_PORCEN, "+;
        "       RTI_NUMERO, "+;
        "       RTI_NUMRET, "+;
        "       RTI_NUMMRT, "+;
        "       RTI_NUMCRR, "+;
        "       SUM(MOV_TOTAL) AS MOV_TOTAL, "+;
        "       CCD_PORIVA, CCD_TIPIVA, CCD_TOTAL, CCD_ACT " +;
        " FROM DPDOCPRO "+;
        " INNER JOIN DPPROVEEDOR ON DOC_CODIGO=PRO_CODIGO "+;
        " INNER JOIN DPTIPDOCPRO ON DOC_TIPDOC=TDC_TIPO AND TDC_LIBCOM=1 AND TDC_IVA=1 "+;
        " LEFT JOIN DPPROVEEDORCERO ON DOC_CODSUC=CCG_CODSUC AND "+;
        "                              DOC_TIPDOC=CCG_TIPDOC AND "+;
        "                              DOC_NUMERO=CCG_NUMDOC "+;
        " LEFT JOIN DPMOVINV ON MOV_CODSUC=DOC_CODSUC AND "+;
        "                       MOV_TIPDOC=DOC_TIPDOC AND "+;
        "                       MOV_CODCTA=DOC_CODIGO AND "+;
        "                       MOV_DOCUME=DOC_NUMERO AND MOV_INVACT=1 "+IF(!lExoner,""," AND MOV_TIPIVA "+GetWhere("=","EX"))+;
        " LEFT JOIN DPIVATIP    ON MOV_TIPIVA=TIP_CODIGO   "+;
        " LEFT JOIN DPDOCPRORTI ON DOC_CODSUC=RTI_CODSUC AND "+;
        "                          DOC_CODIGO=RTI_CODIGO AND "+;
        "                          DOC_TIPDOC=RTI_TIPDOC AND "+;
        "                          DOC_NUMERO=RTI_NUMERO AND "+;
        "                          DOC_TIPTRA=RTI_TIPTRA AND "+;
        "                          RTI_PORCEN!=0         AND "+;
        "                          MONTH(DOC_FCHDEC)=MONTH(RTI_FCHDEC) AND "+;
        "                          YEAR(DOC_FCHDEC)=YEAR(RTI_FCHDEC) "+;
        " LEFT JOIN DPDOCPROCTA ON " +;
        "		CCD_CODSUC = DOC_CODSUC AND " +;
        "		CCD_TIPDOC = DOC_TIPDOC AND " +;
        "		CCD_CODIGO = DOC_CODIGO AND " +;
        "		CCD_NUMERO = DOC_NUMERO AND " +;
        "		CCD_TIPTRA = DOC_TIPTRA AND " +;
        "		CCD_ACT = 1 " +;
        " WHERE DOC_CODSUC "+GetWhere("=",cCodSuc)+;
        " AND " + GetWhereAnd("DOC_FCHDEC",dDesde,dHasta)+;
        " AND DOC_TIPTRA"+GetWhere("=",'D')+; 
        " AND DOC_ACT"+GetWhere("=",1)+;
        " "+IF(Empty(cWhere),""," AND ")+cWhere+;
        " GROUP BY DOC_NETO,"+;
        "          DOC_FECHA ,"+;
        "          DOC_ORIGEN,"+;
        "          RTI_DOCNUM,"+;
        "          RTI_PORCEN,"+;
        "          RTI_NUMTRA,"+;
        "          RTI_TIPDOC,"+;
        "          DOC_CODIGO,"+;
        "          DOC_CODSUC,"+;
        "          PRO_RIF    ,"+;
        "          PRO_NOMBRE ,"+;
        "          DOC_FACTURA,"+;
        "          DOC_DEBITO ,"+;
        "          DOC_CREDITO,"+;
        "          DOC_TIPTRA,"+;
        "          DOC_NUMFIS, "+;
        "          DOC_TIPDOC, "+;
        "          DOC_NUMERO, "+;
        "          DOC_FACAFE, "+;
        "          TIP_CODIGO, "+;
        "          MOV_IVA   , "+;
        "          MOV_TIPIVA, "+;
        "          DOC_DCTO  , "+;
        "          DOC_RECARG, "+;
        "          DOC_OTROS , "+;
        "          DOC_ESTADO, "+;
        "          DOC_ANUFIS, "+;
        "          DOC_CXP   , "+;
        "          DOC_PLAIMP, "+;
        "          DOC_EXPIMP  "+;
        " ORDER BY DOC_NUMERO, DOC_FECHA, MOV_IVA "


  DPWRITE("TEMP\DPLIBCOM.SQL",csql)

  // 22/11/2021 Requiere recalcular los anulados
  oTable:=OpenTable("SELECT * FROM DPDOCPRO WHERE "+GetWhereAnd("DOC_FCHDEC",dDesde,dHasta)+" AND DOC_ACT=0",.T.)
  WHILE !oTable:Eof()

     EJECUTAR("DPDOCCLIIMP",oTable:DOC_CODSUC,oTable:DOC_TIPDOC,oTable:DOC_CODIGO,oTable:DOC_NUMERO,.T.,;
                            oTable:DOC_DCTO  ,oTable:DOC_RECARG,oTable:DOC_OTROS,"C",oTable:DOC_IVAREB)

     oTable:DbSkip()

  ENDDO

  oTable:End()

 
  // 8/2/2017, Modificado  RTI_FECHA por RTI_FCHDEC para coincidir con el programa LIBCAGREGARRTI      

  oTable:=OpenTable(cSql,.T.)

//  ? CLPCOPY(oDp:cSql)
//  oTable:Browse()
// ? "aqui 1"

  IF oTable:RecCount()=0
     oTable:aDataFill:=EJECUTAR("SQLARRAYEMPTY",cSql)
  ENDIF

 //? oTable:DOC_MTOIVA,"MOT IVA A"

  WHILE !oTable:Eof()

    IF Empty(oTable:DOC_TIPDOC)
       oTable:DbSkip()
       LOOP
    ENDIF

    IF oTable:DOC_ANUFIS
      oTable:Replace("TDC_LIBTRA","00-ANU")
    ENDIF

    IF oTable:DOC_TIPDOC='DEB'
      oTable:Replace("DOC_FACTURA",SPACE(10))
      oTable:Replace("DOC_DEBITO" ,oTable:DOC_NUMERO)
    ENDIF

    IF oTable:DOC_TIPDOC='CRE' .OR. oTable:DOC_TIPDOC='DVC'
      oTable:Replace("DOC_FACTURA",SPACE(10))
      oTable:Replace("DOC_CREDITO",oTable:DOC_NUMERO)
    ENDIF

    IF oLiq=NIL

       SQLUPDATE("DPDOCPRO","DOC_LIBCOM",oLibCom:cNumLib,"DOC_CODSUC"+GetWhere("=",oTable:DOC_CODSUC)+" AND "+;
                                                         "DOC_TIPDOC"+GetWhere("=",oTable:DOC_TIPDOC)+" AND "+;
                                                         "DOC_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                         "DOC_NUMERO"+GetWhere("=",oTable:DOC_NUMERO)+" AND "+;
                                                         "DOC_TIPTRA"+GetWhere("=","D"))

    ENDIF

    // 18/07/2022 

    cNumRti:=oTable:FieldGet(oDp:cFieldRti)
    IF !Empty(cNumRti)
      oTable:Replace("RTI_NUMTRA",cNumRti)
    ENDIF

// ? oTable:FieldPos(oDp:cFieldRti),"POS",oDp:cFieldRti,cNumRti,"<-cNumRti"
//? oDp:cFieldRti,"oDp:cFieldRti",cNumRti,"cNumRti"

    oTable:DbSkip()

  ENDDO

 
  // Verifica si la configuracion del sistema manejara las retenciones 
  // con correlativo Infinita(RTI_NUMTRA) o Mensual(RTI_NUMCRR)
/*
// 17/07/2021
  IF oDp:lRetIva_M=.F.
     oTable:Replace("RTI_NUMTRA",oTable:RTI_NUMTRA)
  ELSE
     oTable:Replace("RTI_NUMTRA",oTable:RTI_NUMCRR)
  ENDIF
*/

//? oTable:DOC_MTOIVA,"MOT IVA B"

  oTable:Replace("DOC_OPERAC",STRZERO(0,6)) // Número de Transacción
  oTable:Replace("DOC_FACAFE",SPACE(10))    // Factura Afectada
  oTable:Replace("DOC_MTOIVA",0        )    // Factura Afectada
  oTable:Replace("DOC_EXONER",0        )    // Exento
  oTable:Replace("DOC_NOSUJE",0        )    // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
  oTable:Replace("DOC_MTORTI",0        )    // Monto de Retención RTI
  oTable:Replace("DOC_MTOSCF",0        )    // Monto sin derecho a crédito fiscal segun el campo DOC_CREFIS J 
  oTable:Replace("DOC_IVA_RD",0        ) // Reducido
  oTable:Replace("DOC_IVAGN3",0 ) // General 3
  oTable:Replace("DOC_IVAGN5",0 ) // General 5

  oTable:Replace("DOC_EXONER",0  ) // Asigna Monto Exonerado 07/11/2017
  oTable:Replace("DOC_BAS_RD",0  ) // Reducido
  oTable:Replace("DOC_BAS_GN",0  ) // General

  oTable:Replace("DOC_IVA_RD",0  ) // Reducido
  oTable:Replace("DOC_IVA_GN",0  ) // General

  oTable:Replace("DOC_BASGN5",0  ) // Reducido
  oTable:Replace("DOC_BASGN3",0  ) // General
  oTable:Replace("DOC_IVAGN5",0  ) // Reducido
  oTable:Replace("DOC_IVAGN3",0  ) // General



  oTable:Gotop()

//? oTable:DOC_MTOIVA,"MOT IVA C"


  nTIPO  := oTable:FieldPos("DOC_TIPDOC")
  nIVA   := oTable:FieldPos("MOV_IVA")
  nFECHA := oTable:FieldPos("DOC_FECHA")
  nNUMERO:= oTable:FieldPos("DOC_NUMERO")
  nCODIGO:= oTable:FieldPos("DOC_CODIGO")
  oTable:GoTop()

  // Busca los Impuestos de los Documentos
  WHILE !oTable:Eof()

    oDp:BAS_RD:=0
    oDp:BAS_GN:=0

    IF Empty(oTable:MOV_TIPIVA) .OR. .T.

      EJECUTAR("DPDOCCLIIMP",oTable:DOC_CODSUC,oTable:DOC_TIPDOC,oTable:DOC_CODIGO,oTable:DOC_NUMERO,oTable:DOC_BASNET=0,;
                             oTable:DOC_DCTO  ,oTable:DOC_RECARG,oTable:DOC_OTROS,"C",oTable:DOC_IVAREB)

//? oDp:BAS_GN,oDp:BAS_RD,oDp:BAS_EX,"oDp:BAS_GN,oDp:BAS_RD,oDp:BAS_EX"

      oTable:Replace("DOC_EXONER",oDp:BAS_EX  ) // Asigna Monto Exonerado 07/11/2017
      oTable:Replace("DOC_BAS_RD",oDp:BAS_RD  ) // Reducido
      oTable:Replace("DOC_BAS_GN",oDp:BAS_GN  ) // General

      oTable:Replace("DOC_IVA_RD",oDp:IVA_RD  ) // Reducido
      oTable:Replace("DOC_IVA_GN",oDp:IVA_GN  ) // General

      oTable:Replace("DOC_BASGN5",0           ) // Reducido
      oTable:Replace("DOC_BASGN3",0           ) // General
      oTable:Replace("DOC_IVAGN5",0           ) // Reducido
      oTable:Replace("DOC_IVAGN3",0           ) // General

      IF oTable:DOC_IVAREB=5

         oTable:Replace("DOC_BASGN5",oDp:BAS_GN ) // General
         oTable:Replace("DOC_IVAGN5",oDp:IVA_GN ) // General
         oTable:Replace("DOC_BAS_GN",0 ) // General
         oTable:Replace("DOC_IVA_GN",0           ) // Reducido

      ENDIF

      IF oTable:DOC_IVAREB=3

         oTable:Replace("DOC_BASGN3",oDp:BAS_GN  ) // General
         oTable:Replace("DOC_IVAGN3",oDp:IVA_GN  ) // General  
         oTable:Replace("DOC_BAS_GN",0 ) // General
         oTable:Replace("DOC_IVA_GN",0           ) // Reducido
       ENDIF

      IF oTable:DOC_CREFIS
         oTable:Replace("DOC_MTOSCF",oDp:nNeto   ) // BAS_GN+oDp:BAS_RD)    // Monto sin derecho a crédito fiscal segun el campo DOC_CREFIS JN 05/03/2024
         oTable:Replace("DOC_IVA_GN",0           ) // Reducido
      ENDIF

   ENDIF

    oTable:DbSkip()

  ENDDO

  // oTable:Browse()

 //?  oTable:DOC_MTOSCF,"oTable:DOC_MTOSCF"

  aSort:=ACLONE(oTable:aDataFill)

  ASORT(aSort,,, { |x, y| DTOS(x[nFECHA])+x[nCODIGO]+x[nTIPO]+x[nNUMERO]+STR(100-x[nIVA],6,2)<DTOS(y[nFECHA])+y[nCODIGO]+y[nTIPO]+y[nNUMERO]+STR(100-y[nIVA],6,2) })

// ViewArray(aSort)
  oTable:aDataFill:=ACLONE(aSort)

  /////////////////////////////////////////
  // Debemos Agregar los Reintegro de Compras

  // Reitegro de Compras
  cSql:=" SELECT DOC_ORIGEN,CCD_ACT,TDC_LIBTRA,CCD_FECHA,CCD_FACTUR,CCD_MONTO,CCD_TIPIVA,CCD_CODSUC,CCD_RIF,CCG_NOMBRE,CCD_DOCTIP,CCD_NUMFIS,CCD_PORIVA,CCD_MONTO AS CCD_BASE,CCD_CODIGO,CCD_FCHDEC FROM DPDOCPROCTA "+;
        " INNER JOIN DPPROVEEDORCERO ON CCD_CODSUC=CCG_CODSUC AND CCD_TIPDOC=CCG_TIPDOC AND CCD_CODIGO=CCG_CODIGO AND CCD_NUMERO=CCG_NUMDOC AND CCD_RIF=CCG_RIF "+;
        " INNER JOIN DPDOCPRO        ON CCD_CODSUC=DOC_CODSUC AND CCD_TIPDOC=DOC_TIPDOC AND CCD_CODIGO=DOC_CODIGO AND CCD_NUMERO=DOC_NUMERO AND DOC_ACT=1 "+;
        " INNER JOIN DPTIPDOCPRO     ON CCD_DOCTIP=TDC_TIPO "+;
        " WHERE "+GetWhereAnd("CCD_FCHDEC",dDesde,dHasta)+; 
        "       AND CCD_CODSUC "+GetWhere("=",cCodSuc)+;
        "       AND CCD_LIBCOM=1 "+;
        "       AND CCD_ACT=1 "+;
        "       AND DOC_TIPTRA"+GetWhere("=","D")+;  
        " GROUP BY CCD_FECHA,CCD_FACTUR,CCD_RIF,CCG_NOMBRE,CCD_DOCTIP"

  oRei:=OpenTable(cSql,.F.) // No incluye los Reintegros, ahora los registros estan en DPDOCPRO

  nContar:=oTable:Reccount()

  WHILE !oRei:Eof()

    nBaseRei:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO)","CCD_FACTUR"+GetWhere("=",oRei:CCD_FACTUR)+" AND "+;
                                                    "CCD_CODIGO"+GetWhere("=",oRei:CCD_CODIGO)+" AND "+;
                                                    "CCD_RIF"   +GetWhere("=",oRei:CCD_RIF   )+" AND "+;
                                                    "CCD_TIPIVA"+GetWhere("<>","EX")           +" AND "+;
                                                    "CCD_ACT"   +GetWhere("=",1)              +" AND "+;
                                                    "CCD_LIBCOM"+GetWhere("=","1")) 


    nExeRei:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO)", "CCD_FACTUR"+GetWhere("=",oRei:CCD_FACTUR)+" AND "+;
                                                    "CCD_CODIGO"+GetWhere("=",oRei:CCD_CODIGO)+" AND "+;
                                                    "CCD_RIF"   +GetWhere("=",oRei:CCD_RIF   )+" AND "+;
                                                    "CCD_TIPIVA"+GetWhere("=","EX")           +" AND "+;
                                                    "CCD_ACT"   +GetWhere("=",1)              +" AND "+;
                                                    "CCD_LIBCOM"+GetWhere("=","1")) 

    // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
    nNsjRei:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO)", "CCD_FACTUR"+GetWhere("=",oRei:CCD_FACTUR)+" AND "+;
                                                    "CCD_CODIGO"+GetWhere("=",oRei:CCD_CODIGO)+" AND "+;
                                                    "CCD_RIF"   +GetWhere("=",oRei:CCD_RIF   )+" AND "+;
                                                    "CCD_TIPIVA"+GetWhere("=","NS")           +" AND "+;
                                                    "CCD_ACT"   +GetWhere("=",1)              +" AND "+;
                                                    "CCD_LIBCOM"+GetWhere("=","1")) 


    nReiGn:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO*0.12)","CCD_FACTUR"+GetWhere("=",oRei:CCD_FACTUR)+" AND "+;
                                                       "CCD_CODIGO"+GetWhere("=",oRei:CCD_CODIGO)+" AND "+;
                                                       "CCD_RIF"   +GetWhere("=",oRei:CCD_RIF   )+" AND "+;
                                                       "CCD_TIPIVA"+GetWhere("=","GN")           +" AND "+;
                                                       "CCD_ACT"   +GetWhere("=",1)              +" AND "+;
                                                       "CCD_LIBCOM"+GetWhere("=","1"))    

    nReiRD:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO*0.08)","CCD_FACTUR"+GetWhere("=",oRei:CCD_FACTUR)+" AND "+;
                                                       "CCD_CODIGO"+GetWhere("=",oRei:CCD_CODIGO)+" AND "+;
                                                       "CCD_RIF"   +GetWhere("=",oRei:CCD_RIF   )+" AND "+;
                                                       "CCD_TIPIVA"+GetWhere("=","RD")           +" AND "+;
                                                       "CCD_ACT"   +GetWhere("=",1)              +" AND "+;
                                                       "CCD_LIBCOM"+GetWhere("=","1"))  


    oDp:cSqlRei :=oRei:cSql+",CCD_TIPIVA"
    oDp:cSqlRei :=STRTRAN(oDp:cSqlRei," GROUP BY "," AND "+;
                          "CCD_FACTUR"+GetWhere("=",oRei:CCD_FACTUR)+" AND "+;
                          "CCD_CODIGO"+GetWhere("=",oRei:CCD_CODIGO)+" GROUP BY ")


    oDp:nExo    :=0
    oDp:nBaseRei:=0


    oTable:AddRecord(.T.) // Agregamos Registro Vacio
    oTable:Replace( "DOC_OPERAC" , STRZERO(nContar,6))
    oTable:Replace( "DOC_FECHA"  , oRei:CCD_FECHA)
    oTable:Replace( "DOC_FCHDEC" , oRei:CCD_FCHDEC)
    oTable:Replace( "DOC_ORIGEN" , "N")
    oTable:Replace( "RTI_PORCEN" , 0 )
    oTable:Replace( "PRO_TIPPER" , "J")
    oTable:Replace( "DOC_CODSUC" , oRei:CCD_CODSUC)
    oTable:Replace( "DOC_CODIGO" , oRei:CCD_RIF)
    oTable:Replace( "PRO_RIF"    , oRei:CCD_RIF)
    oTable:Replace( "PRO_NOMBRE" , oRei:CCG_NOMBRE)
    oTable:Replace( "DOC_NUMERO" , oRei:CCD_FACTUR)
    oTable:Replace( "DOC_FACTURA", oRei:CCD_FACTUR)
    oTable:Replace( "DOC_NUMFIS" , oRei:CCD_NUMFIS)
    oTable:Replace( "TDC_LIBTRA" , oRei:TDC_LIBTRA)
    oTable:Replace( "MOV_TIPIVA" , oRei:CCD_TIPIVA)
    oTable:Replace( "DOC_DCTO"   , CTOO(oRei:DOC_DCTO,"N"))
    oTable:Replace( "DOC_RECARG" , 0)
    oTable:Replace( "DOC_OTROS"  , 0)
    oTable:Replace( "DOC_MOTIVA"  ,(oRei:CCD_MONTO*(oRei:CCD_PORIVA/100)))
    oTable:Replace( "DOC_CXP"    , oRei:CCD_ACT    )
    oTable:Replace( "DOC_TIPDOC" , oRei:CCD_DOCTIP )
    // oTable:Replace( "DOC_NETO"   , (oRei:CCD_BASE+(oRei:CCD_BASE*(oRei:CCD_PORIVA/100))))
    oTable:Replace( "MOV_IVA"    , oRei:CCD_PORIVA)


    IF oRei:CCD_ACT=0
      oTable:Replace( "DOC_ANUFIS" , .T. )
      oTable:Replace( "DOC_ESTADO" , "NU")
    ELSE
      oTable:Replace( "DOC_ANUFIS" , .F. )
      oTable:Replace( "DOC_ESTADO" , "AC")
    ENDIF


   oDp:aDataRei:=ASQL(oDp:cSqlRei,.T.)

   cClav:=oRei:CCD_DOCTIP+oRei:CCD_FACTUR+oRei:CCD_CODIGO //.AND. !oTable:Eof()

 //  FOR I=1 TO LEN(oDp:aDataRei)
 //  NEXT I

    oTable:Replace( "MOV_BASE"   , oDp:nBaseRei)
    oTable:Replace( "DOC_EXONER" , nExeRei)
    oTable:Replace( "DOC_NOSUJE" , nNsjRei)
    oTable:Replace( "DOC_MTORTI" , 0 )
    oTable:Replace( "MOV_TOTAL"  , oRei:CCD_BASE )

    oTable:Replace( "DOC_NETO"   ,(oRei:CCD_BASE+(oRei:CCD_BASE*oRei:CCD_PORIVA)/100))
    oTable:Replace( "CCD_TIPIVA" ,oRei:CCD_TIPIVA )  
    oTable:Replace( "LIB_TASAGN" , oDp:nTasaGN )
    oTable:Replace( "LIB_TASARD" , oDp:nTasaRD )
    oTable:Replace( "LIB_TASAS1" , oDp:nTasaS1 )
    oTable:Replace( "LIB_TASAS2" , oDp:nTasaS2 )

    // JN 20/01/2010
    oTable:Replace( "DOC_BASNET" , nBaseRei)
  
    //Agregado no sujeto
    oTable:Replace( "DOC_NETO"   , nBaseRei+nExeRei+nReiGn+nReiRD+nNsjRei)

    oRei:DbSkip()
    
  ENDDO

//? "tres"
// oTable:BROWSE()
  oRei:End()

// oRei:BROWSE()
// VIEWArray(oRei:aDataFill)


/*
// Agregar Retenciones Extemporáneas 
// JN 13/06/2011
*/

  oTable:AddFields("RETENCION",.F.)

  EJECUTAR("LIBCAGREGARRTI",oTable,cCodSuc,dDesde,dHasta,cNumero)

  oTable:GoTop()

// ? "4to"
// oTable:BROWSE()

  oLibCom:oMeter:SetTotal(oTable:RecCount())

  WHILE !oTable:Eof()
    oLibCom:oMeter:Set(oTable:RecNo())

    IF !oLibCom:oSayRecord=NIL
      oLibCom:oSayRecord:SetText("Registro:"+LSTR(oTable:Recno())+"/"+LSTR(oTable:Reccount()))
    ENDIF

    cClave:=oTable:DOC_TIPDOC+oTable:DOC_NUMERO+oTable:DOC_CODIGO

    nContar++
    nLine  :=0
    nRecord:=oTable:Recno() // Primer Renglón

    WHILE cClave=oTable:DOC_TIPDOC+oTable:DOC_NUMERO+oTable:DOC_CODIGO .AND. !oTable:Eof()
          oTable:Replace("DOC_OPERAC",STRZERO(nContar,6))
          IF oTable:DOC_ANUFIS
             oTable:Replace("MOV_TOTAL",0)
          ENDIF

      oDp:nDesc     :=oTable:DOC_DCTO
      oDp:nRecarg   :=oTable:DOC_RECARG
      oDp:nDocOtros :=oTable:DOC_OTROS

      oDp:nBruto    :=oTable:MOV_TOTAL
      oDp:nMtoDesc  :=Porcen(oDp:nBruto,oDp:nDesc  )
      oDp:nMtoRecarg:=Porcen(oDp:nBruto,oDp:nRecarg)
      oDp:nNeto     :=oDp:nBruto+oDp:nMtoRecarg-oDp:nMtoDesc+oDp:nDocOtros

      oDp:nMtoVar :=oDp:nBruto-oDp:nNeto
      oDp:nPorVar :=(100-RATA(oDp:nNeto,oDp:nBruto))*-1

        
      oTable:Replace("MOV_BASE"  ,oTable:MOV_TOTAL+PORCEN(oTable:MOV_TOTAL,oDp:nPorVar))
   
      IF oTable:MOV_IVA>0
        // oTable:Replace("MOV_BASE"  ,oTable:MOV_TOTAL+PORCEN(oTable:MOV_TOTAL,oDp:nPorVar))
         oTable:Replace("DOC_MTOIVA",PORCEN(oTable:MOV_BASE,oTable:MOV_IVA-oTable:DOC_IVAREB))

      ELSE
         //oTable:Replace("MOV_BASE"  ,0)
         oTable:Replace("DOC_EXONER",oTable:DOC_EXONER+oTable:MOV_BASE)
         oTable:Replace("MOV_BASE"  ,0)
      ENDIF

// ?oTable:DOC_MTOIVA,"MOT IVA F"

      oTable:Replace("DOC_NETO"  ,oTable:DOC_NETO  *oTable:DOC_CXP)
      oTable:Replace("MOV_BASE"  ,oTable:MOV_BASE  *oTable:DOC_CXP)
      oTable:Replace("DOC_MTOIVA",oTable:DOC_MTOIVA*oTable:DOC_CXP)
      oTable:Replace("DOC_BASNET",oTable:DOC_BASNET*oTable:DOC_CXP)

//? oTable:MOV_BASE,oTable:DOC_BASNET,"? oTable:MOV_BASE,oTable:DOC_BASNET , OK"

      nLine:=nLine+1


     IF nLine=1 .AND. !Empty(oTable:RTI_DOCNUM) .AND. oTable:RTI_TIPDOC="FAC"
        
        // Sólo puede declarar Retenciones de IVA con el mismo mes de la compra.
        // GetWhereAnd("DOC_FECHA ",dDesde,dHasta)+" AND "+;

        nMontoRti:=SQLGET("DPDOCPRO","DOC_NETO,DOC_FECHA","DOC_CODSUC"+GetWhere("=",oLibCom:cCodSuc)+" AND "+;
                                                          "DOC_TIPDOC"+GetWhere("=","RTI")            +" AND "+;
                                                          "DOC_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                          GetWhereAnd("DOC_FECHA ",dDesde,dHasta)+" AND "+;
                                                          "DOC_NUMERO"+GetWhere("=",oTable:RTI_DOCNUM))


        // JN 13/06/2011     
        dFchDec:=SQLGET("DPDOCPRORTI","RTI_FCHDEC","RTI_CODSUC"+GetWhere("=",oLibCom:cCodSuc)+" AND "+;
                                                   "RTI_TIPDOC"+GetWhere("=",oTable:DOC_TIPDOC)+" AND "+;
                                                   "RTI_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                   "RTI_NUMERO"+GetWhere("=",oTable:DOC_NUMERO))


// Antes "RTI_DOCNUM"+GetWhere("=",oTable:DOC_NUMERO))
       // La retencion esta en el Mismo Periodo
        IF dFchDec>=dDesde .AND. dFchDec<=dHasta
           oTable:Replace("DOC_MTORTI",nMontoRti)
        ELSE
           oTable:Replace("DOC_MTORTI",0        )
           oTable:Replace("RTI_FECHA" ,""       )
           oTable:Replace("RTI_NUMTRA",""       )
        ENDIF

     ENDIF

     IF nLine=1 .AND. !Empty(oTable:RTI_DOCNUM) .AND. (oTable:RTI_TIPDOC="CRE" .OR. oTable:RTI_TIPDOC="DVC")
 
      nMontoRti:=SQLGET("DPDOCPRO","DOC_NETO","DOC_CODSUC"+GetWhere("=",oLibCom:cCodSuc)+" AND "+;
                                                "DOC_TIPDOC"+GetWhere("=","RVI")            +" AND "+;
                                                "DOC_CODIGO"+GetWhere("=",oTable:DOC_CODIGO)+" AND "+;
                                                "DOC_NUMERO"+GetWhere("=",oTable:RTI_DOCNUM))

// Multiplicado por -1 para el monto de retencion salga en Negativo en el Libro de Compras  nMontoRti
// ? nMontoRti,"SIN MULTIPLICAR * -1"
// oTable:Replace("DOC_MTORTI",nMontoRti*-1)
      
         nMontoRti:=nMontoRti*-1
  
    oTable:Replace("DOC_MTORTI",nMontoRti)

    ENDIF


    //  ? oTable:DOC_NOSUJE,"oTable:DOC_NOSUJE"

/*
      IF nLine=1  .AND. oTable:MOV_IVA=0 .AND. oTable:MOV_TIPIVA="EX" .AND. oTable:DOC_EXONER=0
  //? oTable:DOC_NETO,"hey 1"
        oTable:Replace("DOC_EXONER",oTable:DOC_NETO)
        oTable:Replace("MOV_BASE",0)    // No va para el Libro de Venta
        oTable:Replace("DOC_BASNET",0)
      ENDIF
*/

      // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
      IF nLine=1  .AND. oTable:MOV_IVA=0 .AND. oTable:MOV_TIPIVA="NS" .AND. oTable:DOC_NOSUJE=0
  //  ?    oTable:DOC_NETO,"hey 2"

        oTable:Replace("DOC_NOSUJE",oTable:DOC_NETO)
        oTable:Replace("MOV_BASE",0)    // No va para el Libro de Venta
        oTable:Replace("DOC_BASNET",0)
      ENDIF

      IF nLine>1
        oTable:Replace("DOC_NETO",0)
        nBase :=oTable:MOV_BASE         // EXENTO

        IF oTable:MOV_IVA=0             // EXENTO

   //? nbase,"hola"
          oTable:Replace("MOV_BASE",0)  // No va para el Libro de Venta
          oTable:Replace("DOC_NETO",0)  //
          nRecAct:=oTable:Recno()
          oTable:Goto(nRecord)          // Registro Anterior
          oTable:Replace("DOC_EXONER",nBase)
          oTable:Replace("DOC_BASNET",oTable:MOV_BASE)
          oTable:Goto(nRecAct)
        ENDIF

      ENDIF

      IF oTable:DOC_ANUFIS
        oTable:Replace("MOV_BASE",0)
        oTable:Replace("MOV_IVA",0)
        oTable:Replace("DOC_MTOIVA",0)
        oTable:Replace("DOC_MTORTI",0)
        oTable:Replace("DOC_EXONER",0)
        oTable:Replace("DOC_NOSUJE",0)
      ENDIF
 
      oTable:DbSkip()
    ENDDO

  ENDDO

  oTable:AddFields("MOV_IVA_12",0,"N",19,2)
  oTable:AddFields("MOV_IVA_12",0,"N",19,2)

  oTable:AddFields("MOV_BAS_12",0,"N",19,2)
  oTable:AddFields("MOV_BAS_12",0,"N",19,2)

  oTable:AddFields("IVA_RET_12",0,"N",19,2)
  oTable:AddFields("IVA_RET_12",0,"N",19,2)



  oTable:AddFields("MOV_IVA_3",0,"N",19,2)
  oTable:AddFields("MOV_IVA_5",0,"N",19,2)

  oTable:AddFields("MOV_BAS_3",0,"N",19,2)
  oTable:AddFields("MOV_BAS_5",0,"N",19,2)

  oTable:AddFields("IVA_RET_3",0,"N",19,2)
  oTable:AddFields("IVA_RET_5",0,"N",19,2)
  
  nField3:=oTable:FieldPos("MOV_IVA_3")
  nField5:=oTable:FieldPos("MOV_IVA_5")
  nField12:=oTable:FieldPos("MOV_IVA_12")


  nField6:=oTable:FieldPos("MOV_BAS_3")
  nField7:=oTable:FieldPos("MOV_BAS_5")
  nField13:=oTable:FieldPos("MOV_BAS_12")

  nField8:=oTable:FieldPos("IVA_RET_3")
  nField9:=oTable:FieldPos("IVA_RET_5")
  nField14:=oTable:FieldPos("IVA_RET_12")

  oTable:Gotop()

// ? "5to"
//  oTable:Browse()

 //? oTable:DOC_MTOIVA,"oTable:DOC_MTOIVA"

  WHILE !oTable:EOF()

  oDp:BAS_GN:=0
  oDp:BAS_EX:=0
  oDp:BAS_RD:=0

  oDp:IVA_GN:=0
  oDp:IVA_EX:=0
  oDp:IVA_RD:=0

   EJECUTAR("DPDOCCLIIMP",oTable:DOC_CODSUC,oTable:DOC_TIPDOC,oTable:DOC_CODIGO,oTable:DOC_NUMERO,oTable:DOC_BASNET=0,;
                          oTable:DOC_DCTO  ,oTable:DOC_RECARG,oTable:DOC_OTROS,"C",oTable:DOC_IVAREB)


//? oDp:BAS_GN,oDp:BAS_EX,oDp:BAS_RD,"oDp:BAS_GN,oDp:BAS_EX,oDp:BAS_RD DDDDD"

//oDp:SET("POR_"+cVar,oTable:MOV_IVA   ) // Porcentaje
//? oTable:DOC_BASNET,oTable:DOC_EXONER, oDp:nBaseNet,"oTable:DOC_BASNET-oTable:DOC_EXONER,oDp:nBaseNet xxxxxx"

     oTable:Replace("DOC_BASNET",oDp:nBaseNet)
     oTable:Replace("DOC_EXONER",oDp:nMontoEx) // Asigna Monto Exonerado 07/11/2017

//oTable:Replace("MOV_BASNET",oDp:nBaseNet)
//? oTable:DOC_BASNET,oTable:DOC_EXONER,"oTable:DOC_BASNET-oTable:DOC_EXONER"
//? oTable:MOV_BASE,"oTable:MOV_BASE"
//? oTable:MOV_IVA,oTable:MOV_TIPIVA,"oTable:MOV_IVA,oTable:MOV_TIPIVA"

     IF oTable:DOC_IVAREB=0 .AND. oDp:BAS_GN>0 

//? oTable:DOC_MTORTI,"AQIIIIIIII"
        oTable:Replace("MOV_IVA_12",oDp:IVA_GN)
        oTable:Replace("MOV_BAS_12",oDp:BAS_GN)
        oTable:Replace("IVA_RET_12",oTable:DOC_MTORTI)

/*
oTable:Replace("MOV_IVA_12",oTable:DOC_MTOIVA)
        oTable:Replace("MOV_BAS_12",oTable:DOC_BASNET)
        oTable:Replace("MOV_RET_12",oTable:DOC_MTORTI)
*/


//? oTable:DOC_MTOIVA,oTable:MOV_BASE,oTable:DOC_MTORTI,"oTable:DOC_MTOIVA,oTable:MOV_BASE,oTable:DOC_MTORTI"
/*
        oTable:FieldPut(nField13,oTable:MOV_BASE)
        oTable:FieldPut(nField14,oTable:DOC_MTORTI)


        oTable:FieldPut(nField12,oTable:DOC_MTOIVA)
        oTable:FieldPut(nField13,oTable:MOV_BASE)
        oTable:FieldPut(nField14,oTable:DOC_MTORTI)
*/

        //oTable:FieldPut("MOV_BAS_3",oTable:MOV_BASE)
     ENDIF



     IF oTable:DOC_IVAREB=3
        oTable:FieldPut(nField3,oTable:DOC_MTOIVA)
        oTable:FieldPut(nField6,oTable:MOV_BASE)
        oTable:FieldPut(nField8,oTable:DOC_MTORTI)
        //oTable:FieldPut("MOV_BAS_3",oTable:MOV_BASE)
     ENDIF

//? oTable:DOC_MTOIVA,"oTable:DOC_MTOIVA"

     IF oTable:DOC_IVAREB=5
        oTable:FieldPut(nField5,oTable:DOC_MTOIVA )
        oTable:FieldPut(nField7,oTable:MOV_BASE)
        oTable:FieldPut(nField9,oTable:DOC_MTORTI)
        //oTable:FieldPut("MOV_BAS_5",oTable:MOV_BASE)
     ENDIF

     IF oTable:DOC_BASNET=0 .OR. .T.

        EJECUTAR("DPDOCCLIIMP",oTable:DOC_CODSUC,oTable:DOC_TIPDOC,oTable:DOC_CODIGO,oTable:DOC_NUMERO,.T.,;
                               oTable:DOC_DCTO  ,oTable:DOC_RECARG,oTable:DOC_OTROS,"C",oTable:DOC_IVAREB)


     ENDIF


     oTable:DbSkip()

  ENDDO

//? "6to"
//  oTable:Browse()

  oLibCom:oMeter:Set(oTable:RecCount())

  // para forma 30
  IF ValType(oLiq)="O"
    RETURN oTable
  ENDIF

  /*
  // Calcular Columnas por Tasa COMPRA NACIONAL
  */

  oTable:AddFields("IVA_N_GN",0,"N",19,2)
  oTable:AddFields("IVA_N_RD",0,"N",19,2)
  oTable:AddFields("IVA_N_EX",0,"N",19,2)
  oTable:AddFields("IVA_N_NS",0,"N",19,2)  // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ 
  oTable:AddFields("IVA_N_S1",0,"N",19,2)
  oTable:AddFields("IVA_N_S2",0,"N",19,2)

  oTable:IVA_N_GN:=0
  oTable:IVA_N_RD:=0
  oTable:IVA_N_EX:=0
  oTable:IVA_N_NS:=0 // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
  oTable:IVA_N_S1:=0
  oTable:IVA_N_S2:=0

  /*
  // Calcular Columnas por Tasa IMPORTACION
  */

  oTable:AddFields("IVA_I_GN",0,"N",19,2)
  oTable:AddFields("IVA_I_RD",0,"N",19,2)
  oTable:AddFields("IVA_I_EX",0,"N",19,2)
  oTable:AddFields("IVA_I_S1",0,"N",19,2)
  oTable:AddFields("IVA_I_S2",0,"N",19,2)

  oTable:IVA_I_GN:=0
  oTable:IVA_I_RD:=0
  oTable:IVA_I_EX:=0
  oTable:IVA_I_S1:=0
  oTable:IVA_I_S2:=0

  // Detalle del Libro de Compras
  // ? CLPCOPY(oTable:cSql)
  // oTable:browse()

  oTable:CTODBF("CRYSTAL\DPLIBCOMDET.DBF")

//  EJECUTAR("DBFVIEWARRAY","CRYSTAL\DPLIBCOMDET.DBF")

  CLOSE ALL
  USE ("CRYSTAL\DPLIBCOMDET.DBF") EXCLU VIA "DBFCDX"

//owse()
//? "AQUI VA ELIMINAR REGISTROS EN CERO"

// 29/02/2024
  DELETE ALL FOR MOV_BASE=0 .AND. DOC_NETO=0 .AND. !RETENCION
  GO TOP

// browse()

  REPLACE ALL DOC_NETO   WITH 0,MOV_TOTAL WITH  0;
          FOR  DOC_ESTADO="N" .AND. !RETENCION

  PACK

  USE 

  USE ("CRYSTAL\DPLIBCOMDET.DBF") EXCLU VIA "DBFCDX"
  GO TOP

// browse()
  GO TOP

  WHILE !EOF()

    IF DOC_ORIGEN="C"
       REPLACE DOC_ORIGEN WITH "N"
    ENDIF

    // ? DOC_ORIGEN,"DOC_ORIGEN"

    nIntBas:=nIntBas+IIF(DOC_ORIGEN="N",MOV_BASE  ,0)                     // Compras Internas
    nIntIva:=nIntIva+IIF(DOC_ORIGEN="N",DOC_MTOIVA,0)                     // Compras Internas
    nExpBas:=nExpBas+IIF(DOC_ORIGEN="I",MOV_BASE  ,0)                     // Compras Importación
    nExpIva:=nExpIva+IIF(DOC_ORIGEN="I",DOC_MTOIVA,0)                     // Compras Importación


    nGNBas :=nGNBas +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="GN" .OR. CCD_TIPIVA ="GN"),MOV_BASE  ,0) // Compras Internas Alicuota General
    nGNIva :=nGNIva +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="GN" .OR. CCD_TIPIVA ="GN"),DOC_MTOIVA,0) // IVA    Internas Alicuota General

    nS1Bas :=nS1Bas +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="S1" .OR. CCD_TIPIVA ="S1"),MOV_BASE  ,0) // Compras Internas S1
    nS1Iva :=nS1Iva +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="S1" .OR. CCD_TIPIVA ="S1"),DOC_MTOIVA,0) // IVA    Internas S1

    nS2Bas :=nS2Bas +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="S2" .OR. CCD_TIPIVA ="S2"),MOV_BASE  ,0) // Compras Internas S2
    nS2Iva :=nS2Iva +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="S2" .OR. CCD_TIPIVA ="S2"),DOC_MTOIVA,0) // IVA    Internas S2

    nRDBas :=nRDBas +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="RD" .OR. CCD_TIPIVA ="RD"),MOV_BASE  ,0) // Compras Internas RD   
    nRDIva :=nRDIva +IIF(DOC_ORIGEN="N".AND.(MOV_TIPIVA="RD" .OR. CCD_TIPIVA ="RD"),DOC_MTOIVA,0) // IVA    Internas RD

    // Nuevo Totalizador 10/04/2012 (JN)
    // Importaciones Base Imponible

    // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
    nTotBINS  :=nTotBIEX  + IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC) .AND. MOV_TIPIVA="NS"  , DOC_NOSUJE , 0)  // Base Imponible Exonerado

    nTotBIEX  :=nTotBIEX  + IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC) .AND. MOV_TIPIVA="EX"  , DOC_EXONER , 0)  // Base Imponible Exonerado
    nTotBIIMRD:=nTotBIIMRD+ IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC) .AND. MOV_TIPIVA="RD" , MOV_BASE   , 0)  // Base Imponible Alicuota Reducida
    nTotBIIMGN:=nTotBIIMGN+ IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC) .AND. MOV_TIPIVA="GN" , MOV_BASE   , 0)  // Base Imponible Alicuota General 
    nTotBIIMAD:=nTotBIIMAD+ IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC) .AND. (MOV_TIPIVA="S1" .OR. MOV_TIPIVA="S2") , MOV_BASE   , 0)  // Base Imponible Alicuota General + Adicional

    nTotEXTEI :=nTotEXTEI + IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC) .AND. MOV_TIPIVA="EX"  , DOC_EXONER , 0)  // Base Imponible Exonerado
    nTotEXTIRD:=nTotEXTIRD+ IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC) .AND. MOV_TIPIVA="RD" , MOV_BASE   , 0)  // Base Imponible Alicuota Reducida
    nTotEXTIGN:=nTotEXTIGN+ IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC) .AND. MOV_TIPIVA="GN" , MOV_BASE   , 0)  // Base Imponible Alicuota General 
    nTotEXTIAD:=nTotEXTIAD+ IIF( DOC_ORIGEN="I" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC) .AND. (MOV_TIPIVA="S1" .OR. MOV_TIPIVA="S2") , MOV_BASE   , 0)  // Base Imponible Alicuota General + Adicional

    // Compras Internas Base Imponible
    nTotBIINEX:=nTotBIINEX + oTable:DOC_EXONER

// ? nTotBIINEX,"nTotBIINEX"

    // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
    nTotBIINNS:=nTotBIINNS + oTable:DOC_NOSUJE
    
   // nTotBIINEX:=nTotBIINEX+IIF(MOV_TIPIVA="EX" .AND. DOC_ORIGEN="N" , DOC_EXONER , 0)  // TJ Base Imponible Exonerado
    nTotBIINRD:=nTotBIINRD+ IIF(DOC_ORIGEN="N" .AND.  MOV_TIPIVA="RD" .AND.   			      MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC), MOV_BASE ,0)                          // Base Imponible Reducida
    nTotBIINGN:=nTotBIINGN+ IIF(DOC_ORIGEN="N" .AND.  MOV_TIPIVA="GN" .AND. 					 MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC), MOV_BASE, 0)                         // Base Imponible Alicuota General 
    nTotBIINAD:=nTotBIINAD+ IIF((MOV_TIPIVA="S1" .OR. MOV_TIPIVA="S2").AND. DOC_ORIGEN="N" .AND. MONTH(DOC_FECHA) = MONTH(DOC_FCHDEC) , MOV_BASE   , 0)  // Base Imponible Alicuota General + Adicional

   // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
    nTotNSTE:=nTotNSTE+ IIF    ( DOC_ORIGEN = "N"   .AND. MOV_TIPIVA="NS" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC), DOC_NOSUJE , 0)                          // Base Imponible en Extemporaneas 

    nTotEXTE:=nTotEXTE+ IIF    ( DOC_ORIGEN = "N"   .AND. MOV_TIPIVA="EX" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC), DOC_EXENER , 0)                          // Base Imponible en Extemporaneas
    nTotEXTNGN:=nTotEXTNGN+ IIF( DOC_ORIGEN = "N"   .AND. MOV_TIPIVA="GN" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC), MOV_BASE   , 0)                          // Base Imponible Alicuota General
    nTotEXTNRD:=nTotEXTNRD+ IIF( DOC_ORIGEN = "N"   .AND. MOV_TIPIVA="RD" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC), MOV_BASE   , 0)                          // Base Imponible Reducida
    nTotEXTNAD:=nTotEXTNAD+ IIF( DOC_ORIGEN = "N"   .AND. MOV_TIPIVA="S1" .AND. MONTH(DOC_FECHA) <> MONTH(DOC_FCHDEC), MOV_BASE   , 0)                          // Base Imponible Alicuota Suntuario

    // Compras Internas Base Imponible (Extemporanea)
                                                                   //antes MOV_MTOIVA
    // Importaciones Crédito Fiscal
    nTotCFIMRD:=nTotCFIMRD+ IIF( DOC_ORIGEN="I" .AND. MOV_TIPIVA="RD" , DOC_MTOIVA   , 0)  // Crédito Fiscal Alicuota Reducida
    nTotCFIMGN:=nTotCFIMGN+ IIF( DOC_ORIGEN="I" .AND. MOV_TIPIVA="GN" .OR. CCD_TIPIVA="GN" , DOC_MTOIVA   , 0)  // Crédito Fiscal Alicuota General 
    nTotCFIMAD:=nTotCFIMAD+ IIF( DOC_ORIGEN="I" .AND. (MOV_TIPIVA="S1" .OR. MOV_TIPIVA="S2") , DOC_MTOIVA   , 0)  // Crédito Fiscal Alicuota General + Adicional


    // Compras Internas Crédito Fiscal
    nTotCFINRD:=nTotCFINRD+ IIF( DOC_ORIGEN="N" .AND. MOV_TIPIVA="RD" , DOC_MTOIVA   , (oRei:CCD_MONTO)*(oRei:CCD_PORIVA/100))                          // Crédito Fiscal Reducida
    nTotCFINGN:=nTotCFINGN+ IIF( DOC_ORIGEN="N" .AND. MOV_TIPIVA="GN" , DOC_MTOIVA   , (oRei:CCD_MONTO)*(oRei:CCD_PORIVA/100))                         // Crédito Fiscal Alicuota General 
    nTotCFINAD:=nTotCFINAD+ IIF( DOC_ORIGEN="N" .AND. (MOV_TIPIVA="S1" .OR. MOV_TIPIVA="S2") , DOC_MTOIVA   , 0)  // Crédito Fiscal Alicuota General + Adicional

    DBSKIP()

  ENDDO

  COPY TO (cFileDbf) FOR (DOC_TIPDOC$"RTI,RVI")

  CLOSE ALL

  FERASE("CRYSTAL\DPLIBCOMDET.CDX")

  SELECT A
  USE ("CRYSTAL\DPLIBCOMDET.DBF") EXCLU VIA "DBFCDX"

  INDEX ON DOC_TIPDOC+DOC_CODIGO+DOC_NUMERO TO ("CRYSTAL\DPLIBCOMDET.CDX")
  SET INDEX TO ("CRYSTAL\DPLIBCOMDET.CDX")

  SET FILTER TO !(DOC_TIPDOC$"RTI,RVI")
  GO TOP

  SELECT B
  USE (cFileDbf) EXCLU VIA "DBFCDX"

  /*
  // Resumen del Libro de Compras por Columnas
  */ 

  GO TOP

// BROWSE()

  WHILE !A->(EOF())

    cTipDoc:=A->DOC_TIPDOC
    cCodigo:=A->DOC_CODIGO
    cNumero:=A->DOC_NUMERO

    SELECT B

    APPEND BLANK

    AEVAL(DbStruct(),{|a,n| B->(FieldPut(n,A->(FieldGet(n)))) })

    nIVA_N_NS:=0  // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
    nIVA_N_EX:=0
    nIVA_N_RD:=0
    nIVA_N_GN:=0
    nIVA_N_S1:=0
    nIVA_N_S2:=0

    nIVA_I_EX:=0
    nIVA_I_RD:=0
    nIVA_I_GN:=0
    nIVA_I_S1:=0
    nIVA_I_S2:=0

    WHILE !A->(EOF()) .AND. cTipDoc=A->DOC_TIPDOC .AND. cCodigo=A->DOC_CODIGO .AND. cNumero=A->DOC_NUMERO

    nReiGn:=0
    nReiGn:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO*0.12)","CCD_FACTUR"+GetWhere("=",cNumero)+" AND "+;
                                                       "CCD_RIF   "+GetWhere("=",cCodigo)+" AND "+;
                                                       "CCD_TIPIVA"+GetWhere("=","GN")   +" AND "+;
                                                       "CCD_ACT"   +GetWhere("=",1)      +" AND "+;
                                                       "CCD_LIBCOM"+GetWhere("=","1")) 

    nReiRD:=0
    nReiRD:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO*0.08)","CCD_FACTUR"+GetWhere("=",cNumero)+" AND "+;
                                                       "CCD_RIF   "+GetWhere("=",cCodigo)+" AND "+;
                                                       "CCD_TIPIVA"+GetWhere("=","RD")   +" AND "+;
                                                       "CCD_ACT"   +GetWhere("=",1)      +" AND "+;
                                                       "CCD_LIBCOM"+GetWhere("=","1"))


   // IVA No Sujeto para cuentas por Pagar 04-03-2016 TJ
    nReiNS:=0
    nReiNS:=SQLGET("DPDOCPROCTA","SUM(CCD_MONTO)","CCD_FACTUR"+GetWhere("=",cNumero)+" AND "+;
                                                  "CCD_RIF   "+GetWhere("=",cCodigo)+" AND "+;
                                                  "CCD_TIPIVA"+GetWhere("=","NS")   +" AND "+;
                                                  "CCD_ACT"   +GetWhere("=",1)      +" AND "+;
                                                  "CCD_LIBCOM"+GetWhere("=","1"))





     //Nacionales
     nIVA_N_EX:=nIVA_N_EX+IIF(A-> DOC_ORIGEN="N" .AND. A->DOC_EXONER>0   , A->DOC_EXONER   , 0)
     nIVA_N_NS:=nIVA_N_NS+IIF(A-> DOC_ORIGEN="N" .AND. (A->MOV_TIPIVA="NS" .OR.(A->CCD_TIPIVA="NS" .AND. A->CCD_ACT=1)), A->DOC_MTOIVA   , (oRei:CCD_BASE)) 
     nIVA_N_RD:=nIVA_N_RD+IIF(A-> DOC_ORIGEN="N" .AND. (A->MOV_TIPIVA="RD" .OR.(A->CCD_TIPIVA="RD" .AND. A->CCD_ACT=1)), A->DOC_MTOIVA   , (oRei:CCD_BASE*(oRei:CCD_PORIVA/100)))
     nIVA_N_GN:=nIVA_N_GN+IIF(A-> DOC_ORIGEN="N" .AND. (A->MOV_TIPIVA="GN" .OR.(A->CCD_TIPIVA="GN" .AND. A->CCD_ACT=1)), A->DOC_MTOIVA   , (oRei:CCD_BASE*(oRei:CCD_PORIVA/100)))
     nIVA_N_S1:=nIVA_N_S1+IIF(A-> DOC_ORIGEN="N" .AND. A->MOV_TIPIVA="S1", A->DOC_MTOIVA   , (oRei:CCD_BASE*(oRei:CCD_PORIVA/100)))
     nIVA_N_S2:=nIVA_N_S2+IIF(A-> DOC_ORIGEN="N" .AND. A->MOV_TIPIVA="S2", A->DOC_MTOIVA   , (oRei:CCD_BASE*(oRei:CCD_PORIVA/100)))

     IF nReiGn>0
        nIVA_N_GN:=nReiGn
     ENDIF

     IF nReiRD>0
        nIVA_N_RD:=nReiRD
     ENDIF


     IF nReiNS>0
        nIVA_N_NS:=nReiNS
     ENDIF 

     // Importación
     // Si el % MOV_IVA es CERO, se obtiene nuevamente
     // 15/02/2022, libro de compras lo Asumen como Interna o no como Importación
     IF A->DOC_ORIGEN="I"     //.AND. A->MOV_IVA=0 .AND. A->MOV_IVA<>"EX"

       // Recupera el IVA
       REPLACE A->MOV_IVA  WITH EJECUTAR("IVACAL",A->MOV_TIPIVA,NIL,A->DOC_FECHA),;
               A->DOC_MTOIVA WITH PORCEN(A->MOV_TOTAL,A->MOV_IVA)

       nIVA_I_EX:=nIVA_I_EX+IIF(A->DOC_ORIGEN="I" .AND. A->DOC_EXONER>0   , A->DOC_EXONER , 0)
       nIVA_I_RD:=nIVA_I_RD+IIF(A->DOC_ORIGEN="I" .AND. A->MOV_TIPIVA="RD", A->DOC_MTOIVA , 0)
 

       nIVA_I_GN:=nIVA_I_GN+IIF(A->DOC_ORIGEN="I" .AND. A->MOV_TIPIVA="GN", A->DOC_MTOIVA , 0)
       nIVA_I_S1:=nIVA_I_S1+IIF(A->DOC_ORIGEN="I" .AND. A->MOV_TIPIVA="S1", A->DOC_MTOIVA , 0)
       nIVA_I_S2:=nIVA_I_S2+IIF(A->DOC_ORIGEN="IN" .AND. A->MOV_TIPIVA="S2", A->DOC_MTOIVA , 0)

     ENDIF

    REPLACE A->IVA_N_EX WITH nIVA_N_EX,;
            A->IVA_N_RD WITH nIVA_N_RD,;
            A->IVA_N_NS WITH nIVA_N_NS,;
            A->IVA_N_GN WITH nIVA_N_GN,; 
            A->IVA_N_S1 WITH nIVA_N_S1,;
            A->IVA_N_S2 WITH nIVA_N_S2

     A->(DBSKIP())

    REPLACE A->IVA_I_EX WITH nIVA_I_EX,;
            A->IVA_I_RD WITH nIVA_I_RD,;
            A->IVA_I_GN WITH nIVA_I_GN,;
            A->IVA_I_S1 WITH nIVA_I_S1,;
            A->IVA_I_S2 WITH nIVA_I_S2

    ENDDO

    //BROWSE()

  ENDDO

  GO TOP

//? "antes del copy to",cFileAju
//  BROWSE()

  // Debe Copiar en Nueva Tabla los Ajustes (Facturas de Compra de Otro Mes)

  COPY TO (cFileAju) FOR DOC_FECHA<>DOC_FCHDEC
  CLOSE ALL

  USE (cFileAju)
//  BROWSE()

  oTable:End()

  AADD(aStruct,{"LIB_EMPRES","C",120,0})
  AADD(aStruct,{"LIB_RIF"   ,"C",020,0})
  AADD(aStruct,{"LIB_NIT"   ,"C",020,0})
  AADD(aStruct,{"LIB_DIRECC","C",160,0})
  AADD(aStruct,{"LIB_DESDE" ,"D",008,0})
  AADD(aStruct,{"LIB_HASTA" ,"D",008,0})
  AADD(aStruct,{"LIB_FECHA" ,"D",008,0})
  AADD(aStruct,{"LIB_INTBAS","N",019,2})
  AADD(aStruct,{"LIB_INTIVA","N",019,2})
  AADD(aStruct,{"LIB_EXPBAS","N",019,2})
  AADD(aStruct,{"LIB_GNBAS" ,"N",019,2})
  AADD(aStruct,{"LIB_GNIVA" ,"N",019,2})
  AADD(aStruct,{"LIB_ADBAS" ,"N",019,2})
  AADD(aStruct,{"LIB_ADIVA" ,"N",019,2})
  AADD(aStruct,{"LIB_RDBAS" ,"N",019,2})
  AADD(aStruct,{"LIB_RDIVA" ,"N",019,2})
  AADD(aStruct,{"LIB_TASAGN","N",006,2}) //  General
  AADD(aStruct,{"LIB_TASARD","N",006,2}) //  Reducido
  AADD(aStruct,{"LIB_TASAS1","N",006,2}) //  Suntuario
  AADD(aStruct,{"LIB_TASAS2","N",006,2}) //  Suntuario 2
  

  cFileHead:="CRYSTAL\DPLIBCOM_.DBF"
  FERASE(cFileHead)

  IF FILE(cFileHead)
    MensajeErr(cFileHead+" está  Abierto")
  ENDIF

  SELECT 1
  USE ("CRYSTAL\DPLIBCOM.DBF") EXCLU
  GO TOP
  INDEX ON DTOC(DOC_FECHA)+DOC_TIPDOC TAG "DPLIBCOM" TO ("CRYSTAL\DPLIBCOM.CDX")
  SET INDEX TO DPLIBCOM

  AADD(aStructP,{"RIF"      ,"C",015,0})
  AADD(aStructP,{"NOMBRE"   ,"C",050,0})
  AADD(aStructP,{"NFACTURA" ,"C",010,0})
  AADD(aStructP,{"NDEBITO"  ,"C",010,0})
  AADD(aStructP,{"NCREDITO" ,"C",010,0})        
  AADD(aStructP,{"TRANS"    ,"C",010,0}) 
  AADD(aStructP,{"RETENIDO" ,"N",019,2})
  AADD(aStructP,{"FACTURA"  ,"C",010,0})
  AADD(aStructP,{"TIPO"     ,"C",003,0})
  AADD(aStructP,{"FECHA"    ,"D",008,0})
  AADD(aStructP,{"TOTAL"    ,"N",019,2})
  AADD(aStructP,{"IVA"      ,"N",019,2})
  AADD(aStructP,{"EXONER"   ,"N",019,2})
  AADD(aStructP,{"MON_IVA"  ,"N",019,2})
  AADD(aStructP,{"BASE"     ,"N",019,2})
  AADD(aStructP,{"IVA8"     ,"N",019,2})
  AADD(aStructP,{"BASE8"    ,"N",019,2})
  AADD(aStructP,{"MON_IVA8" ,"N",019,2})
  AADD(aStructP,{"IVA14"    ,"N",019,2})
  AADD(aStructP,{"BASE14"   ,"N",019,2})
  AADD(aStructP,{"MON_IVA14","N",019,2})
  AADD(aStructP,{"CONTROL"  ,"C",015,0})
  AADD(aStructP,{"AFECTADA" ,"C",015,0})

  // Totales para el Final de Informe Crystal
  // Total Base Imponible
  AADD(aStructP,{"TOTBI_EX"   ,"N",019,2})  // Total Base Imponible Excentas
  AADD(aStructP,{"TOTBI_IMGN" ,"N",019,2})  // Total Base Imponible Importación, Alícuota General
  AADD(aStructP,{"TOTBI_IMRD" ,"N",019,2})  // Total Base Imponible Importación, Alícuota Reducida
  AADD(aStructP,{"TOTBI_IMAD" ,"N",019,2})  // 
  AADD(aStructP,{"TOTBI_IEAD" ,"N",019,2})  // Total Base Imponible Importación, Alícuota General + Adicional
  AADD(aStructP,{"TOTBI_IEEX" ,"N",019,2})  // Total Base Imponible Excentas (Extemporaneas)
  AADD(aStructP,{"TOTBI_IEGN" ,"N",019,2})  // Total Base Imponible Importación, Alícuota General (Extemporaneas)
  AADD(aStructP,{"TOTBI_IERD" ,"N",019,2})  // Total Base Imponible Importación, Alícuota Reducida (Extemporaneas)
  AADD(aStructP,{"TOTBI_IEAD" ,"N",019,2})  // Total Base Imponible Importación, Alícuota General + Adicional (Extemporaneas)
  AADD(aStructP,{"TOTBI_INEX" ,"N",019,2})  // Total Base Imponible Excentas, TJ
  AADD(aStructP,{"TOTBI_INGN" ,"N",019,2})  // Total Base Imponible Internas, Alícuota General
  AADD(aStructP,{"TOTBI_INRD" ,"N",019,2})  // Total Base Imponible Internas, Alícuota Reducida
  AADD(aStructP,{"TOTBI_INAD" ,"N",019,2})  // Total Base Imponible Internas, Alícuota General + Adicional
  AADD(aStructP,{"TOTBI_INEA" ,"N",019,2})  // Total Base Imponible Internas, Alícuota General + Adicional (Extemporaneas)
  AADD(aStructP,{"TOTBI_INEG" ,"N",019,2})  // Total Base Imponible Internas, Alícuota General (Extemporaneas)
  AADD(aStructP,{"TOTBI_INER" ,"N",019,2})  // Total Base Imponible Internas, Alícuota Reducida (Extemporaneas)
  AADD(aStructP,{"TOTBI_INEE" ,"N",019,2})  // Total Base Imponible Internas, Exento (Extemporaneas)
  AADD(aStructP,{"TOTBI_INED" ,"N",019,2})  // Total Base Imponible Internas, Exento (Extemporaneas)
  AADD(aStructP,{"TOTBI_INNS" ,"N",019,2})  // JN 28/03/2016


  // Total Crédito Fiscal
  AADD(aStructP,{"TOTCF_EX"   ,"N",019,2})  // Total Crédito Fiscal Excentas
  AADD(aStructP,{"TOTCF_IMGN" ,"N",019,2})  // Total Crédito Fiscal Importación, Alícuota General
  AADD(aStructP,{"TOTCF_IMRD" ,"N",019,2})  // Total Crédito Fiscal Importación, Alícuota Reducida
  AADD(aStructP,{"TOTCF_IMAD" ,"N",019,2})  // Total Crédito Fiscal Importación, Alícuota General + Adicional
  AADD(aStructP,{"TOTCF_INGN" ,"N",019,2})  // Total Crédito Fiscal Internas, Alícuota General
  AADD(aStructP,{"TOTCF_INRD" ,"N",019,2})  // Total Crédito Fiscal Internas, Alícuota Reducida
  AADD(aStructP,{"TOTCF_INAD" ,"N",019,2})  // Total Crédito Fiscal Internas, Alícuota General + Adicional

  // Total Retenciones de IVA
  AADD(aStructP,{"TOTRI_EX"   ,"N",019,2})  // Total Retenciones de IVA Excentas
  AADD(aStructP,{"TOTRI_IMGN" ,"N",019,2})  // Total Retenciones de IVA Importación, Alícuota General
  AADD(aStructP,{"TOTRI_IMRD" ,"N",019,2})  // Total Retenciones de IVA Importación, Alícuota Reducida
  AADD(aStructP,{"TOTRI_IMAD" ,"N",019,2})  // Total Retenciones de IVA Importación, Alícuota General + Adicional
  AADD(aStructP,{"TOTRI_INGN" ,"N",019,2})  // Total Retenciones de IVA Internas, Alícuota General
  AADD(aStructP,{"TOTRI_INRD" ,"N",019,2})  // Total Retenciones de IVA Internas, Alícuota Reducida
  AADD(aStructP,{"TOTRI_INAD" ,"N",019,2})  // Total Retenciones de IVA Internas, Alícuota General + Adicional

  // Total Anticipos de IVA
  AADD(aStructP,{"TOTAI_EX"   ,"N",019,2})  // Total Anticipos de IVA Excentas
  AADD(aStructP,{"TOTAI_IMGN" ,"N",019,2})  // Total Anticipos de IVA Importación, Alícuota General
  AADD(aStructP,{"TOTAI_IMRD" ,"N",019,2})  // Total Anticipos de IVA Importación, Alícuota Reducida
  AADD(aStructP,{"TOTAI_IMAD" ,"N",019,2})  // Total Anticipos de IVA Importación, Alícuota General + Adicional
  AADD(aStructP,{"TOTAI_INGN" ,"N",019,2})  // Total Anticipos de IVA Internas, Alícuota General
  AADD(aStructP,{"TOTAI_INRD" ,"N",019,2})  // Total Anticipos de IVA Internas, Alícuota Reducida
  AADD(aStructP,{"TOTAI_INAD" ,"N",019,2})  // Total Anticipos de IVA Internas, Alícuota General + Adicional
  // Tasa Impositivas
  FERASE("CRYSTAL\PLA30COM.DBF")

  IF FILE("CRYSTAL\PLA30COM.DBF")
    MensajeErr("CRYSTAL\PLA30COM.DBF"+" está  Abierto")
  ENDIF

  DBCREATE("CRYSTAL\PLA30COM.DBF",aStructP,"DBFCDX")
  SELECT 2
  USE ("CRYSTAL\PLA30COM.DBF") EXCLU
  GO TOP
  INDEX ON TIPO+FACTURA TAG "PLA30COM" TO ("CRYSTAL\PLA30COM.CDX")
  SET INDEX TO PLA30COM

  APPEND BLANK

  SELECT DPLIBCOM
  GO TOP
  WHILE !EOF()
    SELECT PLA30COM
//    REPLACE PLA30COM->RETENIDO  WITH DPLIBCOM->DOC_MTORTI+RETENIDO
    REPLACE PLA30COM->BASE    WITH DPLIBCOM->MOV_BASE+PLA30COM->BASE
    REPLACE PLA30COM->EXONER  WITH DPLIBCOM->DOC_EXONER+PLA30COM->EXONER
    REPLACE PLA30COM->MON_IVA WITH DPLIBCOM->DOC_MTOIVA+PLA30COM->MON_IVA
    REPLACE PLA30COM->TOTAL   WITH DPLIBCOM->DOC_NETO+PLA30COM->TOTAL

    IF DPLIBCOM->MOV_IVA = oDp:nTasaGN
      REPLACE PLA30COM->IVA14  WITH DPLIBCOM->MOV_IVA
      REPLACE PLA30COM->BASE14  WITH DPLIBCOM->MOV_BASE
      REPLACE PLA30COM->MON_IVA14 WITH DPLIBCOM->DOC_MTOIVA
    ENDIF

    IF DPLIBCOM->MOV_IVA = oDp:nTasaRD
      REPLACE PLA30COM->IVA8  WITH DPLIBCOM->MOV_IVA
      REPLACE PLA30COM->BASE8  WITH DPLIBCOM->MOV_BASE
      REPLACE PLA30COM->MON_IVA8 WITH DPLIBCOM->DOC_MTOIVA
    ENDIF

    SELECT DPLIBCOM

    DBSKIP()
  ENDDO

  // Totalizador 10/04/2012
  // Almacenamiento de Variables

  // Nuevo Totalizador 10/04/2012 (JN)
  // Importaciones
  REPLACE PLA30COM->TOTBI_EX   WITH nTotBIEX
  REPLACE PLA30COM->TOTBI_IMRD WITH nTotBIIMRD
  REPLACE PLA30COM->TOTBI_IMGN WITH nTotBIIMGN
  REPLACE PLA30COM->TOTBI_IMAD WITH nTotBIIMAD

// Importaciones (Extemporaneas)

  REPLACE PLA30COM->TOTBI_IEEX WITH nTotEXTEI
  REPLACE PLA30COM->TOTBI_IERD WITH nTotEXTIRD
  REPLACE PLA30COM->TOTBI_IEGN WITH nTotEXTIGN
  REPLACE PLA30COM->TOTBI_IEAD WITH nTotEXTIAD

  // Crédito Fiscal Compras Importación
  REPLACE PLA30COM->TOTCF_IMRD WITH nTOTCFIMRD
  REPLACE PLA30COM->TOTCF_IMGN WITH nTOTCFIMGN
  REPLACE PLA30COM->TOTCF_IMAD WITH nTOTCFIMAD

  // Compras Internas Base Imponible
  REPLACE PLA30COM->TOTBI_INEX WITH nTotBIINEX    // TJ
  REPLACE PLA30COM->TOTBI_INNS WITH nTotBIINNS   
  REPLACE PLA30COM->TOTBI_INRD WITH nTotBIINRD
  REPLACE PLA30COM->TOTBI_INGN WITH nTotBIINGN
  REPLACE PLA30COM->TOTBI_INAD WITH nTotBIINAD

  // Compras Internas Base Imponible Nacional (Extemporanea)
  REPLACE PLA30COM->TOTBI_INNS WITH nTotNSTE 
  REPLACE PLA30COM->TOTBI_INEE WITH nTotEXTE    // TJ
  REPLACE PLA30COM->TOTBI_INER WITH nTotEXTNRD
  REPLACE PLA30COM->TOTBI_INEG WITH nTotEXTNGN
  REPLACE PLA30COM->TOTBI_INED WITH nTotEXTNAD

  // Credito Fiscal Compras Internas
  REPLACE PLA30COM->TOTCF_INRD WITH nTOTCFINRD
  REPLACE PLA30COM->TOTCF_INGN WITH nTOTCFINGN
  REPLACE PLA30COM->TOTCF_INAD WITH nTOTCFINAD

 
  CLOSE ALL

  DBCREATE(cFileHead,aStruct,"DBFCDX")
  SELECT 3
  USE (cFileHead) SHARED VIA "DBFCDX"
  APPEND BLANK
  BLOC()

  EJECUTAR("IVALOAD",dDesde)
  
  REPLACE LIB_DESDE  WITH dDesde,;
          LIB_HASTA  WITH dHasta,;
          LIB_FECHA  WITH dFecha,;
          LIB_EMPRES WITH oDp:cEmpresa,;
          LIB_RIF    WITH oDp:cRif,;
          LIB_NIT    WITH oDp:cNit,;
          LIB_DIRECC WITH ALLTRIM(oDp:cDir1)+" "+ALLTRIM(oDp:cDir2)+" "+ALLTRIM(oDp:cDir3)+" "+ALLTRIM(oDp:cDir4),;
          LIB_INTBAS WITH nIntBas,;
          LIB_INTIVA WITH nIntIva,;
          LIB_GNBAS  WITH nGNBas,;
          LIB_ADIVA  WITH nS1Iva+nS2Iva,;
          LIB_ADBAS  WITH nS1Bas+nS2Bas,;
          LIB_RDIVA  WITH nRDIva,;
          LIB_RDBAS  WITH nRDBas,;
          LIB_TASAGN WITH oDp:nTasaGN,;
          LIB_TASARD WITH oDp:nTasaRD,;
          LIB_TASAS1 WITH oDp:nTasaS1,;
          LIB_TASAS2 WITH oDp:nTasaS2;

   USE

   CLOSE ALL

 
  CLOSE ALL
  USE ("CRYSTAL\DPLIBCOM.DBF") EXCLU

  SELECT DPLIBCOM
  GO TOP
  WHILE !EOF()

    AADD(aOperao,{DPLIBCOM->DOC_FECHA,DPLIBCOM->DOC_OPERAC})
   
    i:=i+1
   
    DBSKIP()
  ENDDO
  
  CLOSE ALL

  aOperao:=ASORT(aOperao,,,{|X,Y| DTOS(X[1])<DTOS(Y[1]) })

  CLOSE ALL
  USE ("CRYSTAL\DPLIBCOM.DBF") EXCLU

  SELECT DPLIBCOM
  GO TOP
  WHILE !EOF()

    REPLACE DPLIBCOM->DOC_OPERAC WITH oLibCom:REMPLAZA(DPLIBCOM->DOC_FECHA,DPLIBCOM->DOC_OPERAC,aOperao)
   
    DBSKIP()
  ENDDO
  
  CLOSE ALL

  cFileRpt:="CRYSTAL\"+oLibCom:aModRpt[oLibCom:oModelo:nAt]

  //  CLPCOPY(cFileRpt)
  // Definicion del Reporte de Crystal
  // ? oLibCom:lCrystal,"oLibCom:lCrystal"

  EJECUTAR("DPFORMYTARGRAB" , oLibCom:cCodigo, NIL , dDesde , dHasta,cCodSuc,NIL,NIL,NIL,NIL,oLibCom:cNumero) // Guarda la Ejecución del Proceso

  IF oLibCom:nRecord>0 .OR. .T.

    // RUNRPT("CRYSTAL\DPLIBCOMCO.RPT",{cFileHead},1,"Libro de Compras")
    // EJECUTAR("RUNRPT","CRYSTAL\DPLIBCOMCO.RPT",1,"Libro de Compras") // JN/03/2016

    IF !oLibCom:lCrystal
       EJECUTAR("RUNRPT",cFileRpt,1,"Libro de Compras") // JN/03/2016
    ELSE
      SHELLEXECUTE(oDp:oFrameDp:hWND,"open",cFileRpt)
    ENDIF

    //EJECUTAR("DPFORMYTARGRAB" , "LIBROCOM" , NIL , dDesde , dHasta) // Guarda la Ejecución del Proceso

  ELSE
    //MensajeErr("No hay información durante el periodo "+DTOC(dDesde)+" - "+DTOC(dHasta) +" se mostrara Libro de Compras en blanco")
    MsgMemo("No se ha registrado información de Compras en Periodo "+CRLF+;
              "["+ALLTRIM(cMes(dDesde))+" / "+LSTR(YEAR(dDesde))+" ] "+DTOC(dDesde)+"-"+DTOC(dHasta))
 
    // RUNRPT("CRYSTAL\DPLIBCOMSC.RPT",{cFileHead},1,"Libro de Compras") // JN/07/03/2016
    EJECUTAR("RUNRPT","CRYSTAL\DPLIBCOMSC.RPT",1,"Libro de Compras")


  ENDIF


  SQLUPDATE("DPFORMYTAREASPROG",{"PFT_FCHEJE","PFT_ESTADO","PFT_USUARI"},{oDp:dFecha,"E",oDp:cUsuario},;
            "PFT_CODEMP"+GetWhere("=",oDp:cEmpCod    )+" AND "+;
            "PFT_CODSUC"+GetWhere("=",cCodSuc        )+" AND "+;
            "PFT_NUMERO"+GetWhere("=",oLibCom:cNumero)+" AND "+;
            "PFT_NUMEJE"+GetWhere("=",oLibCom:nAno   )+" AND "+;
            "PFT_CODIGO"+GetWhere("=",oLibCom:cCodigo))

  // 27/07/2021 Graba el Libro preseleccionado
  oData:=DATASET("LIBCOM","ALL")
  oData:Set("nLibCom"   ,oLibCom:oModelo:nAt) // Número de Libro de Compras
  oData:End(.T.)

  IF Type("oCOMLIB")="O" .AND. oCOMLIB:oWnd:hWnd>0
      oCOMLIB:BRWREFRESCAR()
  ENDIF

RETURN .T.

FUNCTION REMPLAZA(XFECHA,XOPERA,aOperao)

  LOCAL RET,nAt

  nAt:=ASCAN(aOperao,{|a,n| a[1]=XFECHA .AND. a[2]=XOPERA })
 
  RET := STRZERO(nAt,6)

RETURN RET

FUNCTION FINDCODSUC()
  oLibCom:oSucNombre:Refresh(.T.)

  IF !oLibCom:cCodSuc==SQLGET("DPSUCURSAL","SUC_CODIGO","SUC_CODIGO"+GetWhere("=",oLibCom:cCodSuc))
    EVAL(oLibCom:oCodSuc:bAction)
    RETURN .F.
  ENDIF
RETURN .T.

/*
// Valida que la Fecha no pertenece a Planificación
*/
FUNCTION VALDEBYTAR(lSay)
  LOCAL oTable,cNumero

  LOCAL cWhere:="PFT_CODSUC"+GetWhere("=",cCodSuc        )+" AND "+;
                "PFT_CODEMP"+GetWhere("=",oDp:cEmpCod    )+" AND "+;
                "PFT_CODIGO"+GetWhere("=",oLibCom:cCodigo)+" AND "+;
                GetWhereAnd("PFT_DESDE",oLibCom:dDesde,oLibCom:dHasta)

  DEFAULT lSay:=.T.

  cNumero:=EJECUTAR("GETNUMPLAFISCAL",oLibCom:cCodSuc,"F30",oLibCom:dHasta)

  IF ValType(oLibCom:oNumero)="O"
     oLibCom:cNumero:=cNumero
     oLibCom:oNumero:Refresh(.T.)
  ENDIF

/*
  cNumero:=SQLGET("DPFORMYTAREASPROG","PFT_NUMERO",cWhere)

  IF !Empty(cNumero) .AND. lSay
    oLibCom:oAno:MsgErr("Fecha "+DTOC(oLibCom:dDesde)+" - "+DTOC(oLibCom:dHasta)+CRLF+"Posee registro de Planificación "+cNumero)
    RETURN .T.
  ENDIF

  IF ValType(oLibCom:oNumero)="O"
     oLibCom:cNumero:=cNumero
     oLibCom:oNumero:Refresh(.T.)
  ENDIF
*/
RETURN .T.

/*
// Validar Documentos de Reintegros sin Numero de Control
*/
FUNCTION VALREISINNUM(lView,lMsg)
  LOCAL cWhere
  LOCAL cCodSuc:=oDp:cSucursal,nPeriodo:=12,dDesde:=oLibCom:dDesde,dHasta:=oLibCom:dHasta,cTitle:=" [ Libro de Compras "+oLibCom:cNumLib+"]",nCantid:=0

  DEFAULT lView:=.F.,;
          lMsg :=.F.

  cWhere:=" INNER JOIN DPTIPDOCPRO ON CCD_DOCTIP=TDC_TIPO AND TDC_LIBCOM=1 "+;
          " INNER JOIN DPPROVEEDOR ON CCD_CODIGO=PRO_CODIGO  "+;
          " WHERE CCD_CODSUC"+GetWhere("=",oDp:cSucursal)+;
          " AND CCD_TIPDOC='REI' "+;
          " AND (CCD_FACTUR='' OR CCD_NUMFIS='' OR CCD_RIF='') AND CCD_ACT=1 "+;
          " AND "+GetWhereAnd("CCD_FCHDEC",dDesde,dHasta)

  nCantid:=COUNT("DPDOCPROCTA",cWhere)

  IF lMsg .AND. nCantid>0
     MensajeErr(LSTR(nCantid)+" Documentos en Reintegros sin Número, ni Control ni RIF"+CRLF+"Periodo "+DTOC(dDesde)+" "+DTOC(dHasta))
  ENDIF

  IF nCantid>0 .OR. lView

    cWhere:=NIL

    EJECUTAR("BRREIDOCSINNUM",cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle)

  ENDIF

RETURN nCantid

FUNCTION IMPORTXLS()

? "IMPORTAR DESDE EXCEL"

RETURN .T.


  cWhere:=" INNER JOIN DPTIPDOCPRO ON CCD_DOCTIP=TDC_TIPO AND TDC_LIBCOM=1 "+;
          " INNER JOIN DPPROVEEDOR ON CCD_CODIGO=PRO_CODIGO  "+;
          " WHERE CCD_CODSUC"+GetWhere("=",oDp:cSucursal)+;
          " AND CCD_TIPDOC='REI' "+;
          " AND (CCD_FACTUR='' OR CCD_NUMFIS='' OR CCD_RIF='') AND CCD_ACT=1 "+;
          " AND "+GetWhereAnd("CCD_FCHDEC",dDesde,dHasta)

  nCantid:=COUNT("DPDOCPROCTA",cWhere)

  IF lMsg .AND. nCantid>0
     MensajeErr(LSTR(nCantid)+" Documentos en Reintegros sin Número, ni Control ni RIF"+CRLF+"Periodo "+DTOC(dDesde)+" "+DTOC(dHasta))
  ENDIF

  IF nCantid>0 .OR. lView

    cWhere:=NIL

    EJECUTAR("BRREIDOCSINNUM",cWhere,cCodSuc,nPeriodo,dDesde,dHasta,cTitle)

  ENDIF

RETURN nCantid

FUNCTION IMPORTXLS()

? "IMPORTAR DESDE EXCEL"

RETURN .T.

FUNCTION HACERQUINCENA()
   LOCAL dDesde,dHasta,nMes,nAno,nPeriodo,cMes

   IF !oLibCom:lActivate
      RETURN .F.
   ENDIF

   dDesde:=FCHINIMES(oDp:dFecha)

   IF !LEFT(oDp:cTipCon,1)="O"

  
     IF oLibCom:nRadio=2

       dDesde  :=dDesde-1
       nMes    :=MONTH(dDesde)
       dDesde  :=CTOD("15/"+LSTR(MONTH(dDesde))+"/"+LSTR(YEAR(dDesde)))
       dHasta  :=FCHFINMES(dDesde)
       nAno    :=YEAR(dHasta)
       nPeriodo:=2

    ELSE

       nMes    :=MONTH(dDesde)
       dHasta  :=CTOD("15/"+LSTR(MONTH(dDesde))+"/"+LSTR(YEAR(dDesde)))
       nAno    :=YEAR(dHasta)
       nPeriodo:=1

    ENDIF

   ELSE

     dDesde  :=FCHINIMES(oDp:dFecha)
     dHasta  :=FCHFINMES(dDesde)
     nMes    :=MONTH(dDesde)
     nAno    :=YEAR(dHasta)

   ENDIF

   oLibCom:oDesde:VarPut(dDesde,.T.)
   oLibCom:oHasta:VarPut(dHasta,.T.)

   oLibCom:oMes:Select(nMes)
   oLibCom:oAno:VarPut(nAno,.T.)

   oLibCom:VALDEBYTAR(.F.)


// ? dDesde,dHasta,oLibCom:lActivate

RETURN .T.

FUNCTION DESDEHASTA()

  oLibCom:dDesde:=CTOD(LSTR(DAY(oLibCom:dDesde))+"/"+LSTR(oLibCom:oMes:nAt)+"/"+LSTR(oLibCom:nAno))
  oLibCom:dHasta:=CTOD(LSTR(DAY(oLibCom:dHasta))+"/"+LSTR(oLibCom:oMes:nAt)+"/"+LSTR(oLibCom:nAno))

  IF LEFT(oDp:cTipCon,1)="O"
    oLibCom:dDesde:=CTOD("01/"+LSTR(oLibCom:nMes)+"/"+LSTR(oLibCom:nAno))
    oLibCom:dHasta:=FCHFINMES(oLibCom:dDesde)
  ENDIF


  oLibCom:oDesde:Refresh(.T.)
  oLibCom:oHasta:Refresh(.T.)

  oLibCom:VALDEBYTAR(.F.)

RETURN .T.

FUNCTION NEXTMES(nStep)

  IF LEFT(oDp:cTipCon,1)="O"

    IF nStep=1
      oLibCom:dDesde:=FCHFINMES(oLibCom:dDesde)+1
      oLibCom:dHasta:=FCHFINMES(oLibCom:dDesde)
    ELSE
      oLibCom:dDesde:=FCHINIMES(FCHINIMES(oLibCom:dDesde)-1)
      oLibCom:dHasta:=FCHFINMES(oLibCom:dDesde)
    ENDIF

    oLibCom:oDesde:Refresh(.T.)
    oLibCom:oHasta:Refresh(.T.)

  ELSE

    EJECUTAR("NEXTQUINCENA",oLibCom:oDesde,oLibCom:oHasta,nStep)

  ENDIF

  oLibCom:nAno:=YEAR(oLibCom:dHasta)
  oLibCom:oAno:Refresh(.T.)

  oLibCom:nMes:=MONTH(oLibCom:dHasta)
  oLibCom:oMes:Select(oLibCom:nMes)
 

  oLibCom:VALDEBYTAR(.F.)

RETURN .T.

FUNCTION VERDESDEHASTA()
  LOCAL cWhere:="DOC_CODSUC"+GetWhere("=",oLibCom:cCodSuc)

  oDp:aLine:={}

  IF LEFT(oDp:cTipCon,1)="O"

    EJECUTAR("DPLIBCOM_MENSUAL",oLibCom,oLibCom:oBtnFechas,cWhere)

  ELSE

    EJECUTAR("DPLIBCOM_QUINCENAL",oLibCom,oLibCom:oBtnFechas,cWhere)

  ENDIF

  IF !Empty(oDp:aLine)

    oLibCom:oAno:VarPut(CTOO(oDp:aLine[1],"N"),.T.)
    oLibCom:oMes:Select(oDp:aLine[2])
   
    oLibCom:oDesde:VarPut(oDp:dFchIniDoc,.T.)
    oLibCom:oHasta:VarPut(oDp:dFchFinDoc,.T.)
   
  ENDIF

 
RETURN 
// EOF
