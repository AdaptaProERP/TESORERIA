// Programa   : DPCTABANCO
// Fecha/Hora : 02/09/2005 00:44:05
// Propósito  : Incluir/Modificar DPCTABANCO
// Creado Por : DpXbase
// Llamado por: DPCTABANCO.LBX
// Aplicación : Compras y Cuentas por Pagar             
// Tabla      : DPCTABANCO

#INCLUDE "DPXBASE.CH"
#INCLUDE "TSBUTTON.CH"
#INCLUDE "IMAGE.CH"

FUNCTION DPCTABANCO(nOption,cCodigo,cCodBco)
  LOCAL oBtn,oTable,oGet,oFont,oFontB,oFontG
  LOCAL cSql,cFile,cExcluye:=""
  LOCAL nClrText
  LOCAL cTitle:="Cuentas Bancarias",;
         aItems1:=GETOPTIONS("DPCTABANCO","BCO_TIPCTA")
  LOCAL oDpLbx

  cExcluye:="BCO_CODIGO,;
             BCO_TIPCTA,;
             BCO_CTABAN,;
             BCO_CODMON,;
             BCO_CUENTA,;
             BCO_INGRES,;
             BCO_PAGAR,;
             BCO_OBSERV"

  DEFAULT cCodigo:="1234",nOption:=1,cCodBco:=""

  IF !Empty(SQLGET("DPBANCOS","BAN_CODIGO","BAN_NOMBRE"+GetWhere("=",cCodBco)))
     cCodBco:=oDp:aRow[1]
  ENDIF

  DEFINE FONT oFont  NAME "Tahoma" SIZE 0, -11 BOLD
  DEFINE FONT oFontB NAME "Tahoma" SIZE 0, -12 BOLD 
  DEFINE FONT oFontG NAME "Tahoma" SIZE 0, -12 BOLD

  nClrText:=10485760 // Color del texto

  cSql    :=" SELECT * FROM DPCTABANCO WHERE BCO_CODIGO"+GetWhere("=",cCodigo)+" AND "+;
            " BCO_CTABAN"+GetWhere("=",cCodBco)

  IF nOption!=1 // Incluir
    cTitle   :=IIF(nOption=2,"Consultar","Modificar")+" "+oDp:DPCTABANCO
  ENDIF

  oTable   :=OpenTable(cSql,"WHERE "$cSql,GETDBSERVER()) // nOption!=1)

  oTable:cWhere

  IF nOption=1 .OR. oTable:RecCount()=0 // Genera Cursor Vacio
     cTitle   :="Incluir "+oDp:DPCTABANCO
     oTable:End()
     cSql     :=[SELECT * FROM DPCTABANCO]
     oTable   :=OpenTable(cSql,.F.) // nOption!=1)
  ENDIF

  oTable:cPrimary:="BCO_CTABAN,BCO_CODIGO" // Clave de Validación de Registro
 
  oCTABANCO:=DPEDIT():New(cTitle,"DPCTABANCO.edt","oCTABANCO" , .F.)

  oCTABANCO:nOption  :=nOption
  oCTABANCO:SetTable( oTable , .F. ) // Asocia la tabla <cTabla> con el formulario oCTABANCO
  oCTABANCO:SetScript()        // Asigna Funciones DpXbase como Metodos de oCTABANCO
  oCTABANCO:SetDefault()       // Asume valores standar por Defecto, CANCEL,PRESAVE,POSTSAVE,ORDERBY
  oCTABANCO:nClrPane:=oDp:nGris
  oCTABANCO:BAN_CODIGO:=""
  oCTABANCO:BCO_OBSERV:=ALLTRIM(oCTABANCO:BCO_OBSERV)
  oCTABANCO:SetMemo("BCO_NUMMEM")    // Campo para el Valor Memo

  IF oDp:nVersion>=6 .OR. .T.

    oCTABANCO:BCO_CUENTA:=EJECUTAR("DPGETCTAMOD","DPCTABANCO_CTA",oCTABANCO:BCO_CODIGO,oCTABANCO:BCO_CTABAN,"CUENTA")

  ENDIF

  IF oCTABANCO:nOption=1 // Incluir en caso de ser Incremental

      // Repetir Valores
      oCTABANCO:BCO_CODIGO:=oTable:BCO_CODIGO           // Código de la Cuenta Bancaria
      oCTABANCO:BCO_TIPCTA:=oTable:BCO_TIPCTA           // Tipo de Cuenta
      oCTABANCO:BCO_CODMON:=oDp:cMoneda // oTable:BCO_CODMON           // Código de Moneda
      oCTABANCO:BCO_TITULA:=PADR(oDp:cEmpresa,LEN(oCTABANCO:BCO_TITULA))  // Titular de la Cuenta
      oCTABANCO:BCO_CODSUC:=oDp:cSucursal
      oCTABANCO:BCO_ACTIVA:=.T.
      oCTABANCO:BCO_INGRES:=.T.
      oCTABANCO:BCO_PAGAR :=.T.
      // oCTABANCO:oBCO_CODMON:VarPut(oDp:cMoneda,.T.)

      // AutoIncremental 

  ENDIF

  // Aqui se Indica el Formulario que llama es Dialog
//  IF ValType(oCTABANCO:oDpLbx)="O"
//
//  ENDIF

  oCTABANCO:lMdi:=.F.
  oCTABANCO:lDlg:=.T.

  oCTABANCO:CreateWindow()       // Presenta la Ventana

  
  oCTABANCO:ViewTable("DPBANCOS"  ,"BAN_NOMBRE","BAN_CODIGO","BCO_CODIGO")
  oCTABANCO:ViewTable("DPTABMON"  ,"MON_DESCRI","MON_CODIGO","BCO_CODMON")
  oCTABANCO:ViewTable("DPCTA"     ,"CTA_DESCRI","CTA_CODIGO","BCO_CUENTA")
  oCTABANCO:ViewTable("DPSUCURSAL","SUC_DESCRI","SUC_CODIGO","BCO_CODSUC")

  
  //
  // Campo : BCO_CODIGO
  // Uso   : Código de la Cuenta Bancaria            
  //
  @ 1.0, 1.0 BMPGET oCTABANCO:oBCO_CODIGO  VAR oCTABANCO:BCO_CODIGO ;
                    VALID CERO(oCTABANCO:BCO_CODIGO) .AND. oCTABANCO:VALBCOCODIGO();
                    NAME "BITMAPS\FIND.BMP"; 
                    ACTION (oDpLbx:=DpLbx("DPBANCOS"), oDpLbx:GetValue("BAN_CODIGO",oCTABANCO:oBCO_CODIGO)); 
                    WHEN (AccessField("DPCTABANCO","BCO_CODIGO",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                    FONT oFontG;
                    SIZE 24,10
/*
  @ 1.0, 1.0 BMPGET oCTABANCO:oBCO_CODIGO  VAR oCTABANCO:BCO_CODIGO ;
                    VALID CERO(oCTABANCO:BCO_CODIGO);
                   .AND. oCTABANCO:oDPBANCOS:SeekTable("BAN_CODIGO",oCTABANCO:oBCO_CODIGO,NIL,oCTABANCO:oBAN_NOMBRE);
                    NAME "BITMAPS\FIND.BMP"; 
                    ACTION (oDpLbx:=DpLbx("DPBANCOS",NIL,NIL,NIL,"BAN_CODIGO",NIL,NIL,oCTABANCO:lDialog,oCTABANCO:oDb,oCTABANCO:oBCO_CODIGO), oDpLbx:GetValue("BAN_CODIGO",oCTABANCO:oBCO_CODIGO)); 
                    WHEN (AccessField("DPCTABANCO","BCO_CODIGO",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                    FONT oFontG;
                    SIZE 24,10

*/

    oCTABANCO:oBCO_CODIGO:cMsg    :="Código de la Cuenta Bancaria"
    oCTABANCO:oBCO_CODIGO:cToolTip:="Código de la Cuenta Bancaria"

  @ 0,0 SAY GetFromVar("{oDp:xDPBANCOS}")

//oCTABANCO:oDPBANCOS:cSingular
  @ oCTABANCO:oBCO_CODIGO:nTop,oCTABANCO:oBCO_CODIGO:nRight+5 SAY oCTABANCO:oBAN_NOMBRE;
                            PROMPT oCTABANCO:oDPBANCOS:BAN_NOMBRE PIXEL;
                            SIZE NIL,12 FONT oFont COLOR 16777215,16711680



  @ 2.8, 1.0 FOLDER oCTABANCO:oFolder ITEMS "Básicos","Otros Datos","Observaciones";
                      FONT oFontG

     SETFOLDER( 1)
  //
  // Campo : BCO_TIPCTA
  // Uso   : Tipo de Cuenta                          
  //
  @ 0.6, 0.0 COMBOBOX oCTABANCO:oBCO_TIPCTA VAR oCTABANCO:BCO_TIPCTA ITEMS aItems1;
                      WHEN (AccessField("DPCTABANCO","BCO_TIPCTA",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                      FONT oFontG;


 ComboIni(oCTABANCO:oBCO_TIPCTA)


    oCTABANCO:oBCO_TIPCTA:cMsg    :="Tipo de Cuenta"
    oCTABANCO:oBCO_TIPCTA:cToolTip:="Tipo de Cuenta"

  @ oCTABANCO:oBCO_TIPCTA:nTop-08,oCTABANCO:oBCO_TIPCTA:nLeft SAY "Tipo de Cuenta" PIXEL;
                            SIZE NIL,7 FONT oFont COLOR nClrText,oDp:nGris


  //
  // Campo : BCO_CTABAN
  // Uso   : Cuenta Bancaria                         
  //
  @ 2.4, 0.0 GET oCTABANCO:oBCO_CTABAN  VAR oCTABANCO:BCO_CTABAN ;
                    VALID oCTABANCO:BCOCTABAN();
                    WHEN (AccessField("DPCTABANCO","BCO_CTABAN",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                    FONT oFontG;
                    SIZE 80,10

    oCTABANCO:oBCO_CTABAN:cMsg    :="Cuenta Bancaria"
    oCTABANCO:oBCO_CTABAN:cToolTip:="Cuenta Bancaria"

  @ oCTABANCO:oBCO_CTABAN:nTop-08,oCTABANCO:oBCO_CTABAN:nLeft SAY "Cuenta Bancaria" PIXEL;
                            SIZE NIL,7 FONT oFont COLOR nClrText,oDp:nGris



  @ 1.0, 1.0 GET oCTABANCO:oBCO_TITULA  VAR oCTABANCO:BCO_TITULA;
             VALID !EMPTY(oCTABANCO:BCO_TITULA);
                   .AND. oCTABANCO:oDPBANCOS:SeekTable("BAN_CODIGO",oCTABANCO:oBCO_TITULA,NIL,oCTABANCO:oBAN_NOMBRE);
             WHEN (AccessField("DPCTABANCO","BCO_TITULA",oCTABANCO:nOption);
                   .AND. oCTABANCO:nOption!=0)


  oCTABANCO:oBCO_TITULA:cMsg    :="Nombre del Titular de la Cuenta"
  oCTABANCO:oBCO_TITULA:cToolTip:="Nombre del Titular de la Cuenta"

  //
  // Campo : BCO_CODMON
  // Uso   : Código de Moneda                        
  //
  @ 4.2, 0.0 BMPGET oCTABANCO:oBCO_CODMON  VAR oCTABANCO:BCO_CODMON ;
                VALID oCTABANCO:oDPTABMON:SeekTable("MON_CODIGO",oCTABANCO:oBCO_CODMON,NIL,oCTABANCO:oMON_DESCRI);
                    NAME "BITMAPS\FIND.BMP"; 
                    ACTION (oDpLbx:=DpLbx("DPTABMON",NIL,NIL,NIL,"MON_CODIGO",NIL,NIL,oCTABANCO:lDialog,oCTABANCO:oDb,oCTABANCO:oBCO_CODMON), oDpLbx:GetValue("MON_CODIGO",oCTABANCO:oBCO_CODMON)); 
                    WHEN (AccessField("DPCTABANCO","BCO_CODMON",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                    FONT oFontG;
                    SIZE 12,10

    oCTABANCO:oBCO_CODMON:cMsg    :="Código de Moneda"
    oCTABANCO:oBCO_CODMON:cToolTip:="Código de Moneda"

  @ 0,0 SAY GETFROMVAR("{oDp:xDPTABMON}")

//oCTABANCO:oDPTABMON:cSingular
  @ oCTABANCO:oBCO_CODMON:nTop,oCTABANCO:oBCO_CODMON:nRight+5 SAY oCTABANCO:oMON_DESCRI;
                            PROMPT oCTABANCO:oDPTABMON:MON_DESCRI PIXEL;
                            SIZE NIL,12 FONT oFont COLOR 16777215,16711680  


  //
  // Campo : BCO_CUENTA
  // Uso   : Cuenta Contable                         
  //
  @ 6.0, 0.0 BMPGET oCTABANCO:oBCO_CUENTA  VAR oCTABANCO:BCO_CUENTA;
             VALID oCTABANCO:oDPCTA:SeekTable("CTA_CODIGO",oCTABANCO:oBCO_CUENTA,NIL,oCTABANCO:oCTA_DESCRI);
             NAME "BITMAPS\FIND.BMP"; 
             ACTION (oDpLbx:=DpLbx("DPCTAACT",NIL,NIL,NIL,"CTA_CODIGO",NIL,NIL,oCTABANCO:lDialog,oCTABANCO:oDb,oCTABANCO:oBCO_CUENTA), oDpLbx:GetValue("CTA_CODIGO",oCTABANCO:oBCO_CUENTA)); 
             WHEN (AccessField("DPCTABANCO","BCO_CUENTA",oCTABANCO:nOption);
                  .AND. oCTABANCO:nOption!=0);
             FONT oFontG;
             SIZE 80,10

  oCTABANCO:oBCO_CUENTA:cMsg    :="Cuenta Contable"
  oCTABANCO:oBCO_CUENTA:cToolTip:="Cuenta Contable"

  @ 0,0 SAY GETFROMVAR("{oDp:xDPCTA}")

  @ 0,0 SAY oCTABANCO:oCTA_DESCRI;
        PROMPT oCTABANCO:oDPCTA:CTA_DESCRI PIXEL;
        SIZE NIL,12 FONT oFont COLOR 16777215,16711680  


  //
  // Campo : BCO_INGRES
  // Uso   : Depósito de Clientes                    
  //
  @ 7.8, 0.0 CHECKBOX oCTABANCO:oBCO_INGRES  VAR oCTABANCO:BCO_INGRES  PROMPT ANSITOOEM("Depósitos de Clientes");
                    WHEN (AccessField("DPCTABANCO","BCO_INGRES",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 166,10;
                    SIZE 4,10

    oCTABANCO:oBCO_INGRES:cMsg    :="Depósito de Clientes"
    oCTABANCO:oBCO_INGRES:cToolTip:="Depósito de Clientes"

  //
  // Campo : BCO_PAGAR 
  // Uso   : Pagar                                   
  //
  @ 9.6, 0.0 CHECKBOX oCTABANCO:oBCO_PAGAR   VAR oCTABANCO:BCO_PAGAR   PROMPT ANSITOOEM("Realiza Pagos");
                    WHEN (AccessField("DPCTABANCO","BCO_PAGAR",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 118,10;
                    SIZE 4,10

    oCTABANCO:oBCO_PAGAR :cMsg    :="Pagar"
    oCTABANCO:oBCO_PAGAR :cToolTip:="Pagar"


  @ 7,0 SAY "Nombre de la Empresa"


  //
  // Campo : BCO_IDB
  // Uso   : Depósito de Clientes                    
  //
  @ 7.8, 0.0 CHECKBOX oCTABANCO:oBCO_IDB  VAR oCTABANCO:BCO_IDB  PROMPT ANSITOOEM("Aplicar I.T.F");
                    WHEN (AccessField("DPCTABANCO","BCO_IDB",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 166,10;
                    SIZE 4,10

    oCTABANCO:oBCO_IDB:cMsg    :="Aplicar ITF"
    oCTABANCO:oBCO_IDB:cToolTip:="Aplicar ITF"


  //
  // Campo : BCO_ACTIVA
  // Uso   : Cuenta Activa
  //
  @ 7.8, 0.0 CHECKBOX oCTABANCO:oBCO_ACTIVA  VAR oCTABANCO:BCO_ACTIVA  PROMPT ANSITOOEM("Cuenta Activa");
                    WHEN (AccessField("DPCTABANCO","BCO_ACTIVA",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 166,10;
                    SIZE 4,10

    oCTABANCO:oBCO_ACTIVA:cMsg    :="Cuenta Activa"
    oCTABANCO:oBCO_ACTIVA:cToolTip:="Cuenta Activa"

  //
  // Campo : BCO_INCREM
  // Uso   : Incrementa Cheques
  //
  @ 7.8, 0.0 CHECKBOX oCTABANCO:oBCO_INCREM  VAR oCTABANCO:BCO_INCREM PROMPT ANSITOOEM("Incrementa Cheques");
                    WHEN (AccessField("DPCTABANCO","BCO_INCREM",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 166,10;
                    SIZE 4,10

    oCTABANCO:oBCO_ACTIVA:cMsg    :="Incrementa Cheques"
    oCTABANCO:oBCO_ACTIVA:cToolTip:="Incrementa Cheques"


  //
  // Campo : BCO_IMPDOC
  // Uso   : Imprime en Documentos del Cliente
  //
  @ 9.8, 10 CHECKBOX oCTABANCO:oBCO_IMPDOC  VAR oCTABANCO:BCO_IMPDOC PROMPT ANSITOOEM("Imprime en Documento de Clientes");
                    WHEN (AccessField("DPCTABANCO","BCO_IMPDOC",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 166,10;
                    SIZE 4,10

    oCTABANCO:oBCO_ACTIVA:cMsg    :="Imprime en Documento de Clientes"
    oCTABANCO:oBCO_ACTIVA:cToolTip:="Imprime en Documento de Clientes"

 //
  // Campo : BCO_FILSUC
  // Uso   : Imprime en Documentos del Cliente
  //
  @ 9.8, 10 CHECKBOX oCTABANCO:oBCO_FILSUC  VAR oCTABANCO:BCO_FILSUC PROMPT ANSITOOEM("Filtra por "+oDp:xDPSUCURSAL);
                    WHEN (AccessField("DPCTABANCO","BCO_FILSUC",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 166,10;
                    SIZE 4,10

    oCTABANCO:oBCO_ACTIVA:cMsg    :="Filtra por "+oDp:xDPSUCURSAL
    oCTABANCO:oBCO_ACTIVA:cToolTip:="Filtra por "+oDp:xDPSUCURSAL

  //
  // Campo : BCO_CODSUC
  // Uso   : Sucursal
  //
  @ 6.0, 0.0 BMPGET oCTABANCO:oBCO_CODSUC  VAR oCTABANCO:BCO_CODSUC ;
             VALID oCTABANCO:oDPSUCURSAL:SeekTable("SUC_CODIGO",oCTABANCO:oBCO_CODSUC,NIL,oCTABANCO:oSUC_DESCRI);
             NAME "BITMAPS\FIND.BMP"; 
             ACTION (oDpLbx:=DpLbx("DPSUCURSAL",NIL,NIL,NIL,"SUC_CODIGO",NIL,NIL,oCTABANCO:lDialog,oCTABANCO:oDb,oCTABANCO:oBCO_CODSUC), oDpLbx:GetValue("SUC_CODIGO",oCTABANCO:oBCO_CODSUC)); 
                    WHEN (AccessField("DPCTABANCO","BCO_CODSUC",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
             FONT oFontG;
             SIZE 80,10

    oCTABANCO:oBCO_CODSUC:cMsg    :=oDp:DPSUCURSAL
    oCTABANCO:oBCO_CODSUC:cToolTip:=oDp:DPSUCURSAL

  @ 0,0 SAY oDp:xDPSUCURSAL

  @ 12,0 SAY oCTABANCO:oSUC_DESCRI;
         PROMPT oCTABANCO:oDPSUCURSAL:SUC_DESCRI PIXEL;
         SIZE NIL,12 FONT oFont COLOR 16777215,16711680  


  // Campo : BCO_CONDIG
  // Uso   : Conciliación Digital
  //
  @ 9.8, 10 CHECKBOX oCTABANCO:oBCO_CONDIG  VAR oCTABANCO:BCO_CONDIG PROMPT ANSITOOEM("Conciliación Digital ");
                    WHEN (AccessField("DPCTABANCO","BCO_CONDIG",oCTABANCO:nOption);
                    .AND. oCTABANCO:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 166,10;
                    SIZE 4,10

    oCTABANCO:oBCO_CONDIG:cMsg    :="Conciliación Digital"
    oCTABANCO:oBCO_CONDIG:cToolTip:="Conciliación Digital"


  SETFOLDER( 2)

  oCTABANCO:oScroll:=oCTABANCO:SCROLLGET("DPCTABANCO","DPCTABANCO.SCG",cExcluye)

  IF  oCTABANCO:IsDef("oScroll")
     oCTABANCO:oScroll:SetEdit(.T.)
  ENDIF

  oCTABANCO:oScroll:SetColSize(220,250+064,240-240)

  oCTABANCO:oScroll:SetColorHead(CLR_BLACK ,6220027,oFont) 

//  oCTABANCO:oScroll:SetColor(14612478,CLR_GREEN,1,13104638,oFontB) 
//  oCTABANCO:oScroll:SetColor(14612478,0,2,13104638,oFont) 
//  oCTABANCO:oScroll:SetColor(14612478,0,3,13104638,oFontB) 
//  oCTABANCO:oScroll:SetColSize(250+30,290+75+95-30,240)

  oCTABANCO:oScroll:SetColorHead(CLR_BLACK ,oDp:nGrid_ClrPaneH,oFontB) 
  oCTABANCO:oScroll:SetColor(oDp:nClrPane1,0,1,oDp:nClrPane2,oFont) 
  oCTABANCO:oScroll:SetColor(oDp:nClrPane1,0,2,oDp:nClrPane2,oFont) 
  oCTABANCO:oScroll:SetColor(oDp:nClrPane1,0,3,oDp:nClrPane2,oFont)



  @ 8,1 GROUP oCTABANCO:oGroup TO 12, 21.5 PROMPT " Formatos de Impresión para el Depósito "    

  @ 7,0 SAY "Otros Bancos o Mixto"
  @ 8,0 SAY "Del Mismo Banco"


  //
  // Campo : BCO_RPTOTR   
  // Uso   : Archivo RPT para Bancos de Otras Plazas                            
  //
  @ 6.4,1.0 BMPGET oCTABANCO:oBCO_RPTOTR  VAR oCTABANCO:BCO_RPTOTR;
                   NAME "BITMAPS\CRYSTAL2.BMP"; 
                   ACTION (oDp:cFile:=cGetFile32("RPT File (*.RPT) |*.RPT|Archivos Crystal Report (*.RPT) |*.RPT",;
                           "Seleccionar Archivo CRYSTAL (RPT)",1,cFilePath(oCTABANCO:BCO_RPTOTR),.f.,.t.),;
                           oDp:cFile:=STRTRAN(oDp:cFile,"\","/"),;
                           oCTABANCO:BCO_RPTOTR:=IIF(!EMPTY(oDp:cFile),oDp:cFile,oCTABANCO:BCO_RPTOTR),;
                           oCTABANCO:oBCO_RPTOTR:Refresh(.T.));
                   WHEN (AccessField("DPCTABANCO","BCO_RPTOTR",oCTABANCO:nOption) .AND. oCTABANCO:nOption!=0);
                   SIZE 70,10

    oCTABANCO:oBCO_RPTOTR   :cMsg    :="Modelo de Impresión para Cheques de Otros Bancos"
    oCTABANCO:oBCO_RPTOTR   :cToolTip:="Modelo de Impresión para Cheques de Otros Bancos"   


  //
  // Campo : BCO_RPTBCO   
  // Uso   : Archivo RPT para Bancos de Otras Plazas                            
  //
  @ 7.4,1.0 BMPGET oCTABANCO:oBCO_RPTBCO  VAR oCTABANCO:BCO_RPTBCO;
                   NAME "BITMAPS\CRYSTAL2.BMP"; 
                   ACTION (oDp:cFile:=cGetFile32("RPT File (*.RPT) |*.RPT|Archivos Crystal Report (*.RPT) |*.RPT",;
                           "Seleccionar Archivo CRYSTAL (RPT)",1,cFilePath(oCTABANCO:BCO_RPTBCO),.f.,.t.),;
                           oDp:cFile:=STRTRAN(oDp:cFile,"\","/"),;
                           oCTABANCO:BCO_RPTBCO:=IIF(!EMPTY(oDp:cFile),oDp:cFile,oCTABANCO:BCO_RPTBCO),;
                           oCTABANCO:oBCO_RPTBCO:Refresh(.T.));
                   WHEN (AccessField("DPCTABANCO","BCO_RPTBCO",oCTABANCO:nOption) .AND. oCTABANCO:nOption!=0);
                   SIZE 70,10

    oCTABANCO:oBCO_RPTBCO   :cMsg    :="Modelo de Impresión para Cheques del Mismo Banco"
    oCTABANCO:oBCO_RPTBCO   :cToolTip:="Modelo de Impresión para Cheques del Mismo Banco"

    SETFOLDER( 3)

   oCTABANCO:BCO_OBSERV:=ALLTRIM(oCTABANCO:BCO_OBSERV)  

  //
  // Campo : BCO_OBSERV
  // Uso   : Observaciónes                           
  //
  @ 1.1, 0.0 GET oCTABANCO:oBCO_OBSERV  VAR oCTABANCO:BCO_OBSERV;
           MEMO SIZE 80,80; 
           ON CHANGE 1=1;
           WHEN (AccessField("DPCTABANCO","BCO_OBSERV",oCTABANCO:nOption);
          .AND. oCTABANCO:nOption!=0);
           FONT oFontG;
           SIZE 40,10

    oCTABANCO:oBCO_OBSERV:cMsg    :="Observaciónes"
    oCTABANCO:oBCO_OBSERV:cToolTip:="Observaciónes"



     SETFOLDER(0)
/*
  IF nOption!=2

    @09, 33  SBUTTON oBtn ;
             SIZE 45, 20 FONT oFont;
             FILE "BITMAPS\XSAVE.BMP" NOBORDER;
             LEFT PROMPT "Grabar";
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION (oCTABANCO:Save())

    oBtn:cToolTip:="Grabar Registro"
    oBtn:cMsg    :=oBtn:cToolTip

    @09, 43 SBUTTON oBtn ;
            SIZE 45, 20 FONT oFont;
            FILE "BITMAPS\XCANCEL.BMP" NOBORDER;
            LEFT PROMPT "Cancelar";
            COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
            ACTION (oCTABANCO:Cancel()) CANCEL

    oBtn:lCancel :=.T.
    oBtn:cToolTip:="Cancelar y Cerrar Formulario "
    oBtn:cMsg    :=oBtn:cToolTip

  ELSE


     @09, 43 SBUTTON oBtn ;
             SIZE 42, 23 FONT oFontB;
             FILE "BITMAPS\XSALIR.BMP" NOBORDER;
             LEFT PROMPT "Salir";
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION (oCTABANCO:Cancel()) CANCEL

             oBtn:lCancel:=.T.
             oBtn:cToolTip:="Cerrar Formulario"
             oBtn:cMsg    :=oBtn:cToolTip

  ENDIF
*/
  oCTABANCO:Activate({||oCTABANCO:CTABCOINI()})

  STORE NIL TO oTable,oGet,oFont,oGetB,oFontG

RETURN oCTABANCO

FUNCTION CTABCOINI()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg:=oCTABANCO:oDlg


   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52-15,60-15 OF oDlg 3D CURSOR oCursor
   DEFINE FONT oFont  NAME "Arial"   SIZE 0, -10 BOLD

   IF oCTABANCO:nOption<>2

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XSAVE.BMP";
            ACTION oCTABANCO:Save()

     oBtn:cToolTip:="Grabar Registro"
     oBtn:cMsg    :=oBtn:cToolTip
/*
     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XMEMO.BMP";
            ACTION (oCTABANCO:CAMPOMEMO())

     oBtn:cToolTip:="Campo Memo"
     oBtn:cMsg    :=oBtn:cToolTip
*/

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XCANCEL.BMP";
            ACTION oCTABANCO:Cancel()

     oBtn:lCancel:=.T.
     oBtn:cToolTip:="Cerrar Formulario"
     oBtn:cMsg    :=oBtn:cToolTip

   ELSE


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XSALIR.BMP";
            ACTION oCTABANCO:Close()

   ENDIF


  oBar:SetColor(CLR_BLACK,oDp:nGris)

  AEVAL(oBar:aControls,{|o,n|o:SetColor(CLR_BLACK,oDp:nGris)})

  oCTABANCO:oBar:=oBar

  AEVAL(oBar:aControls,{|o|o:ForWhen(.T.)})

  oCTABANCO:oScroll:oBrw:SetColor(NIL,oDp:nClrPane1)

RETURN .T.
/*
// Carga de Datos, para Incluir
*/
FUNCTION LOAD()


  IF .T.
  //oDp:nVersion>=6

     oCTABANCO:BCO_CUENTA:=EJECUTAR("DPGETCTAMOD","DPCTABANCO_CTA",oCTABANCO:BCO_CODIGO,oCTABANCO:BCO_CTABAN,"CUENTA")

  ENDIF

  IF oCTABANCO:nOption=1 // Incluir en caso de ser Incremental
       // Para cargar mas rapido
      oCTABANCO:BCO_OBSERV:=""
           // Repetir Valores
      oCTABANCO:BCO_CODIGO:=oTable:BCO_CODIGO           // Código de la Cuenta Bancaria
      oCTABANCO:BCO_TIPCTA:=oTable:BCO_TIPCTA           // Tipo de Cuenta
      oCTABANCO:BCO_CODMON:=oTable:BCO_CODMON           // Código de Moneda
     // AutoIncremental 
  ENDIF

RETURN .T.
/*
// Ejecuta Cancelar
*/
FUNCTION CANCEL()
RETURN .T.

/*
// Ejecución PreGrabar
*/
FUNCTION PRESAVE()
  LOCAL lResp:=.T.

  oCTABANCO:BCO_OBSERV:=ALLTRIM(oCTABANCO:BCO_OBSERV)

  IF !EVAL(oCTABANCO:oBCO_CTABAN:bValid)
    RETURN .F.
  ENDIF

 
RETURN lResp

/*
// Ejecución despues de Grabar
*/
FUNCTION POSTSAVE()

  // Registrar la Cuenta Contable
  IF oDp:nVersion>=6 .OR. .T.
    EJECUTAR("SETCTAINTMOD","DPCTABANCO_CTA",oCTABANCO:BCO_CODIGO,oCTABANCO:BCO_CTABAN,"CUENTA",oCTABANCO:BCO_CUENTA,.T.)
  ENDIF

RETURN .T.

FUNCTION BCOCTABAN()

  IF Empty(oCTABANCO:BCO_CTABAN)
     oCTABANCO:oBCO_CTABAN:MsgErr("Es necesaria la Cuenta Bancaria")
     RETURN .F.
  ENDIF

  IF !oCTABANCO:VALUNIQUE(oCTABANCO:BCO_CODIGO+oCTABANCO:BCO_CTABAN,"BCO_CODIGO,BCO_CTABAN")
     RETURN .F.
  ENDIF

RETURN .T.

FUNCTION CAMPOMEMO()

    oCTABANCO:aMemo[2]:="Descripción Amplia, Código:"+ALLTRIM(oCTABANCO:BCO_CODIGO+oCTABANCO:BCO_CTABAN)+" / "+ALLTRIM(oCTABANCO:oBAN_NOMBRE:GetText())

   _DPMEMOEDIT(oCTABANCO,oCTABANCO:oEditMemo)

RETURN .T.

FUNCTION VALBCOCODIGO()
  LOCAL cBanco:=SQLGET("DPBANCOS","BAN_NOMBRE","BAN_CODIGO"+GetWhere("=",oCTABANCO:BCO_CODIGO))
 
  oCTABANCO:oBAN_NOMBRE:SETTEXT(cBanco)

RETURN .T.

/*
<LISTA:BCO_CODIGO:N:BMPGETL:N:Y:Y:Código del Banco,Pestaña01:N:GET:N:N:N:Básicos,BCO_TIPCTA:N:COMBO:N:Y:Y:Tipo de Cuenta,BCO_CTABAN:N:GET:N:N:Y:Cuenta Bancaria
,BCO_CODMON:N:BMPGETL:N:Y:Y:Código de Moneda,BCO_CUENTA:N:BMPGETL:N:N:Y:Cuenta Contable,BCO_INGRES:N:CHECKBOX:N:N:Y:Depósitos de Clientes,BCO_PAGAR:N:CHECKBOX:N:N:Y:Realiza Pagos
,Pestaña02:N:GET:N:N:N:Otros Datos,SCROLLGET:N:GET:N:N:N:Para Diversos Campos,Pestaña03:N:GET:N:N:N:Observaciones,BCO_OBSERV:N:MGET:N:N:Y:
>
*/
