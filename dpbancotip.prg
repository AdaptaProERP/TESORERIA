// Programa   : DPBANCOTIP
// Fecha/Hora : 30/08/2005 22:58:21
// Propósito  : Incluir/Modificar DPBANCOTIP
// Creado Por : DpXbase
// Llamado por: DPBANCOTIP.LBX
// Aplicación : Bancos y Caja                           
// Tabla      : DPBANCOTIP

#INCLUDE "DPXBASE.CH"
#INCLUDE "TSBUTTON.CH"
#INCLUDE "IMAGE.CH"

FUNCTION DPBANCOTIP(nOption,cCodigo)
  LOCAL oBtn,oTable,oGet,oFont,oFontB,oFontG
  LOCAL cTitle,cSql,cFile,cExcluye:=""
  LOCAL nClrText
  LOCAL cTitle:="Tipo de Transacciones Bancarias"

  cExcluye:="TDB_CODIGO,;
             TDB_NOMBRE,;
             TDB_INGRES,;
             TDB_PAGOS"

  DEFAULT cCodigo:="1234"

  DEFAULT nOption:=1

   nOption:=IIF(nOption=2,0,nOption) 

  DEFINE FONT oFont  NAME "Tahoma" SIZE 0, -10 BOLD
  DEFINE FONT oFontB NAME "Tahoma" SIZE 0, -12 BOLD ITALIC
  DEFINE FONT oFontG NAME "Tahoma" SIZE 0, -11

  nClrText:=10485760 // Color del texto

  IF nOption=1 // Incluir
    cSql     :=[SELECT * FROM DPBANCOTIP WHERE ]+BuildConcat("TDB_CODIGO")+GetWhere("=",cCodigo)+[]
    cTitle   :=" Incluir {oDp:DPBANCOTIP}"
  ELSE // Modificar o Consultar
    cSql     :=[SELECT * FROM DPBANCOTIP WHERE ]+BuildConcat("TDB_CODIGO")+GetWhere("=",cCodigo)+[]
    cTitle   :=IIF(nOption=2,"Consultar","Modificar")+" Tipo de Transacciones Bancarias         "
    cTitle   :=IIF(nOption=2,"Consultar","Modificar")+" {oDp:DPBANCOTIP}"
  ENDIF

  oTable   :=OpenTable(cSql,"WHERE"$cSql) // nOption!=1)

  IF nOption=1 .AND. oTable:RecCount()=0 // Genera Cursor Vacio
     oTable:End()
     cSql     :=[SELECT * FROM DPBANCOTIP]
     oTable   :=OpenTable(cSql,.F.) // nOption!=1)
  ENDIF

  oTable:cPrimary:="TDB_CODIGO" // Clave de Validación de Registro

  oBANCOTIP:=DPEDIT():New(cTitle,"DPBANCOTIP.edt","oBANCOTIP" , .F. )

  oBANCOTIP:nOption  :=nOption
  oBANCOTIP:SetTable( oTable , .F. ) // Asocia la tabla <cTabla> con el formulario oBANCOTIP
  oBANCOTIP:SetScript()        // Asigna Funciones DpXbase como Metodos de oBANCOTIP
  oBANCOTIP:SetDefault()       // Asume valores standar por Defecto, CANCEL,PRESAVE,POSTSAVE,ORDERBY
  oBANCOTIP:nClrPane:=oDp:nGris

  oBANCOTIP:TDB_SIGNO:=IIF(oBANCOTIP:TDB_SIGNO=-1,2,1)

  IF oBANCOTIP:nOption=1 // Incluir en caso de ser Incremental
     // oBANCOTIP:RepeatGet(NIL,"TDB_CODIGO") // Repetir Valores
     // AutoIncremental 
  ENDIF
  //Tablas Relacionadas con los Controles del Formulario

  oBANCOTIP:CreateWindow()       // Presenta la Ventana

  oBANCOTIP:ViewTable("DPTABMON"  ,"MON_DESCRI","MON_CODIGO","TDB_CODMON")

  @ 2,1 GROUP oBANCOTIP:oGrupo TO 4, 16.0 PROMPT "Transacción"    

  // Opciones del Formulario

  
  //
  // Campo : TDB_CODIGO
  // Uso   : Código                                  
  //
  @ 1.0, 1.0 GET oBANCOTIP:oTDB_CODIGO  VAR oBANCOTIP:TDB_CODIGO  VALID CERO(oBANCOTIP:TDB_CODIGO);
                    WHEN (AccessField("DPBANCOTIP","TDB_CODIGO",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                    FONT oFontG;
                    SIZE 16,10

    oBANCOTIP:oTDB_CODIGO:cMsg    :="Código"
    oBANCOTIP:oTDB_CODIGO:cToolTip:="Código"

  @ oBANCOTIP:oTDB_CODIGO:nTop-08,oBANCOTIP:oTDB_CODIGO:nLeft SAY "Código" PIXEL;
                            SIZE NIL,7 FONT oFont COLOR nClrText,oDp:nGris


  //
  // Campo : TDB_NOMBRE
  // Uso   : Nombre                                  
  //
  @ 2.8, 1.0 GET oBANCOTIP:oTDB_NOMBRE  VAR oBANCOTIP:TDB_NOMBRE ;
                    WHEN (AccessField("DPBANCOTIP","TDB_NOMBRE",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                    FONT oFontG;
                    SIZE 160,10

    oBANCOTIP:oTDB_NOMBRE:cMsg    :="Nombre"
    oBANCOTIP:oTDB_NOMBRE:cToolTip:="Nombre"

  @ oBANCOTIP:oTDB_NOMBRE:nTop-08,oBANCOTIP:oTDB_NOMBRE:nLeft SAY "Nombre" PIXEL;
                            SIZE NIL,7 FONT oFont COLOR nClrText,oDp:nGris


  //
  // Campo : TDB_CODMON
  // Uso   : Código de Moneda                        
  //
  @ 2.8,15.0 BMPGET oBANCOTIP:oTDB_CODMON  VAR oBANCOTIP:TDB_CODMON  VALID  !VACIO(oBANCOTIP:TDB_CODMON,NIL);
                   .AND. oBANCOTIP:oDPTABMON:SeekTable("MON_CODIGO",oBANCOTIP:oTDB_CODMON,NIL,oBANCOTIP:oMON_DESCRI);
                    NAME "BITMAPS\FIND.BMP"; 
                     ACTION (oDpLbx:=DpLbx("DPTABMON",NIL,NIL,NIL,NIL,oBANCOTIP:TDB_CODMON,NIL,NIL,NIL,oBANCOTIP:oTDB_CODMON), oDpLbx:GetValue("MON_CODIGO",oBANCOTIP:oTDB_CODMON)); 
                    WHEN (AccessField("DPCAJAINST","TDB_CODMON",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                    FONT oFontG;
                    SIZE 12,10

    oBANCOTIP:oTDB_CODMON:cMsg    :="Código de Moneda"
    oBANCOTIP:oTDB_CODMON:cToolTip:="Código de Moneda"




  // Campo : TDB_ACTIVO
  // Uso   : Registro Activo                
  //
  @ 4.6, 1.0 CHECKBOX oBANCOTIP:oTDB_ACTIVO  VAR oBANCOTIP:TDB_ACTIVO  PROMPT ANSITOOEM("Activo");
                    WHEN (AccessField("DPBANCOTIP","TDB_ACTIVO",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 172,10;
                    SIZE 4,10

    oBANCOTIP:oTDB_ACTIVO:cMsg    :="Activo"
    oBANCOTIP:oTDB_ACTIVO:cToolTip:="Activo"

  //
  // Campo : TDB_INGRES
  // Uso   : Ingresa desde Clientes                  
  //
  @ 4.6, 1.0 CHECKBOX oBANCOTIP:oTDB_INGRES  VAR oBANCOTIP:TDB_INGRES  PROMPT ANSITOOEM("Recibos de Ingreso");
                    WHEN (AccessField("DPBANCOTIP","TDB_INGRES",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 172,10;
                    SIZE 4,10

    oBANCOTIP:oTDB_INGRES:cMsg    :="Recibo de Ingreso"
    oBANCOTIP:oTDB_INGRES:cToolTip:="Recibo de Ingreso"


  //
  // Campo : TDB_PAGOS 
  // Uso   : Realiza Pagos                           
  //
  @ 6.4, 1.0 CHECKBOX oBANCOTIP:oTDB_PAGOS   VAR oBANCOTIP:TDB_PAGOS   PROMPT ANSITOOEM("Realiza Pagos");
                    WHEN (AccessField("DPBANCOTIP","TDB_PAGOS",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 118,10;
                    SIZE 4,10

    oBANCOTIP:oTDB_PAGOS :cMsg    :="Realiza Pagos"
    oBANCOTIP:oTDB_PAGOS :cToolTip:="Realiza Pagos"


//
  // Campo : TDB_ITF 
  // Uso   : Genera ITF                         
  //
  @ 6.4, 1.0 CHECKBOX oBANCOTIP:oTDB_ITF   VAR oBANCOTIP:TDB_ITF   PROMPT ANSITOOEM("Genera ITF");
                    WHEN (AccessField("DPBANCOTIP","TDB_ITF",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                     FONT oFont COLOR nClrText,NIL SIZE 118,10;
                    SIZE 4,10

    oBANCOTIP:oTDB_ITF :cMsg    :="Genera ITF"
    oBANCOTIP:oTDB_ITF :cToolTip:="Genera ITF"



  @ 6,10 RADIO oBANCOTIP:oTDB_SIGNO VAR oBANCOTIP:TDB_SIGNO;
         PROMPT ANSITOOEM("Débito"),ANSITOOEM("Crédito")


  @ 8,2  CHECKBOX oBANCOTIP:oTDB_CTRNUM VAR oBANCOTIP:TDB_CTRNUM;
         PROMPT ANSITOOEM("Control de Números ")


  //
  // Campo : TDB_BMP   
  // Uso   : Archivo Bmp                             
  //
  @ 6.4,15.0 BMPGET oBANCOTIP:oTDB_BMP     VAR oBANCOTIP:TDB_BMP    ;
                    NAME "BITMAPS\FOLDER5.BMP"; 
                    ACTION (cFile:=cGetFile32("Bmp File (*.bmp) |*.bmp|Archivos BitMaps (*.bmp) |*.bmp",;
                    "Seleccionar Archivo BITMAP (BMP)",1,cFilePath(oBANCOTIP:TDB_BMP),.f.,.t.),;
                    cFile:=STRTRAN(cFile,"\","/"),;
                    oBANCOTIP:TDB_BMP:=IIF(!EMPTY(cFile),cFile,oBANCOTIP:TDB_BMP),;
                    oBANCOTIP:oTDB_BMP   :Refresh(),;
                    oBANCOTIP:oImage1:LoadBmp(cFile));
                    WHEN .T.;
                    FONT oFontG

    oBANCOTIP:oTDB_BMP   :cMsg    :="Archivo Bmp"
    oBANCOTIP:oTDB_BMP   :cToolTip:="Archivo Bmp"

  @ 0,10 SAY "Archivo Bmp" PIXEL;
              SIZE NIL,7 FONT oFont COLOR nClrText,NIL 


  @ oBANCOTIP:oTDB_BMP:nBottom+1,oBANCOTIP:oTDB_BMP:nLeft BITMAP oBANCOTIP:oImage1 FILENAME oBANCOTIP:TDB_BMP PIXEL;
                            SIZE 30,30 ADJUST

  @ 04,0 SAY GetFromVar("{oDp:xDPTABMON}")

  @ 04,3 SAY oBANCOTIP:oMON_DESCRI;
         PROMPT oBANCOTIP:oDPTABMON:MON_DESCRI PIXEL;
         SIZE NIL,12 FONT oFont COLOR 0,oDp:nGris2 

  @ 14,0 SAY GetFromVar("{oDp:xDPCTABANCO}")

  //
  // Campo : TDB_CTABCO
  // Uso   : Código de Moneda                        
  //
  @ 14,15.0 BMPGET oBANCOTIP:oTDB_CTABCO  VAR oBANCOTIP:TDB_CTABCO;
                    VALID oBANCOTIP:VALCTABCO();
                    NAME "BITMAPS\FIND.BMP"; 
                     ACTION (oDpLbx:=DpLbx("DPCTABANCO",NIL,NIL,NIL,NIL,oBANCOTIP:TDB_CTABCO,NIL,NIL,NIL,oBANCOTIP:oTDB_CTABCO),;
                             oDpLbx:GetValue("BCO_CTABAN",oBANCOTIP:oTDB_CTABCO)); 
                    WHEN (AccessField("DPCAJAINST","TDB_CTABCO",oBANCOTIP:nOption);
                    .AND. oBANCOTIP:nOption!=0);
                    FONT oFontG;
                    SIZE 12,10

    oBANCOTIP:oTDB_CTABCO:cMsg    :="Cuenta Bancaria"
    oBANCOTIP:oTDB_CTABCO:cToolTip:="Cuenta Bancaria"
 
   @ 14,3 SAY oBANCOTIP:oCTABANCO;
          PROMPT SQLGET("DPCTABANCO",[CONCAT(BCO_CODIGO," ",BAN_NOMBRE)],"INNER JOIN DPBANCOS ON BCO_CODIGO=BAN_CODIGO WHERE BCO_CTABAN"+GetWhere("=",oBANCOTIP:TDB_CTABCO));
          PIXEL SIZE NIL,12 FONT oFont COLOR 0,oDp:nGris2 

/*
  IF nOption!=2

    @09, 33  SBUTTON oBtn ;
             SIZE 45, 20 FONT oFont;
             FILE "BITMAPS\XSAVE.BMP" NOBORDER;
             LEFT PROMPT "Grabar";
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION (oBANCOTIP:Save())

    oBtn:cToolTip:="Grabar Registro"
    oBtn:cMsg    :=oBtn:cToolTip

    @09, 43 SBUTTON oBtn ;
            SIZE 45, 20 FONT oFont;
            FILE "BITMAPS\XCANCEL.BMP" NOBORDER;
            LEFT PROMPT "Cancelar";
            COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
            ACTION (oBANCOTIP:Cancel()) CANCEL

    oBtn:lCancel :=.T.
    oBtn:cToolTip:="Cancelar y Cerrar Formulario "
    oBtn:cMsg    :=oBtn:cToolTip

  ELSE


     @09, 43 SBUTTON oBtn ;
             SIZE 42, 23 FONT oFontB;
             FILE "BITMAPS\XSALIR.BMP" NOBORDER;
             LEFT PROMPT "Salir";
             COLORS CLR_BLACK, { CLR_WHITE, CLR_HGRAY, 1 };
             ACTION (oBANCOTIP:Cancel()) CANCEL

             oBtn:lCancel:=.T.
             oBtn:cToolTip:="Cerrar Formulario"
             oBtn:cMsg    :=oBtn:cToolTip

  ENDIF
*/

  oBANCOTIP:Activate({||oBANCOTIP:INICIO()})

  STORE NIL TO oTable,oGet,oFont,oGetB,oFontG

RETURN oBANCOTIP


FUNCTION INICIO()
   LOCAL oCursor,oBar,oBtn,oFont,oCol
   LOCAL oDlg:=oBANCOTIP:oDlg
   LOCAL nLin:=0

   DEFINE CURSOR oCursor HAND
   DEFINE BUTTONBAR oBar SIZE 52,60 OF oDlg 3D CURSOR oCursor

   DEFINE FONT oFont  NAME "Tahoma"   SIZE 0, -10 BOLD

   IF oBANCOTIP:nOption!=2

     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            TOP PROMPT "Grabar";
            FILENAME "BITMAPS\XSAVE.BMP",NIL,"BITMAPS\XSAVEG.BMP";
            ACTION (oBANCOTIP:Save())

     oBtn:cToolTip:="Guardar"

     oBANCOTIP:oBtnSave:=oBtn


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XCANCEL.BMP";
            TOP PROMPT "Cancela";
            ACTION (oBANCOTIP:Cancel()) CANCEL


   
   ELSE


     DEFINE BUTTON oBtn;
            OF oBar;
            NOBORDER;
            FONT oFont;
            FILENAME "BITMAPS\XSALIR.BMP";
            TOP PROMPT "Cerrar";
            ACTION (oBANCOTIP:Cancel()) CANCEL

   ENDIF

   oBar:SetColor(CLR_BLACK,oDp:nGris)

   AEVAL(oBar:aControls,{|o,n| o:SetColor(CLR_BLACK,oDp:nGris) })


 
RETURN .T.



/*
// Carga de Datos, para Incluir
*/
FUNCTION LOAD()

  IF oBANCOTIP:nOption=1 // Incluir en caso de ser Incremental
     
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

  // Condiciones para no Repetir el Registro
  oBANCOTIP:TDB_SIGNO:=IIF(oBANCOTIP:TDB_SIGNO=2,-1,1)

RETURN lResp

/*
// Ejecución despues de Grabar
*/
FUNCTION POSTSAVE()

  oDp:aBancoTip:={}
  oDp:aCajaInst:={}
  oDp:aFormas  :={}

RETURN .T.


FUNCTION VALCTABCO()

  IF !Empty(oBANCOTIP:TDB_CTABCO) .AND. !ISSQLFIND("DPCTABANCO","BCO_CTABAN"+GetWhere("=",oBANCOTIP:TDB_CTABCO))
     EVAL(oBANCOTIP:oTDB_CTABCO:bAction)
     RETURN .T.
  ENDIF

  oBANCOTIP:oCTABANCO:Refresh(.T.)

RETURN .T.

/*
<LISTA:TDB_CODIGO:N:GET:N:N:Y:Código,TDB_NOMBRE:N:GET:N:N:Y:Nombre,TDB_INGRES:N:CHECKBOX:N:N:Y:Ingresa desde Clientes,TDB_PAGOS:N:CHECKBOX:N:N:Y:Realiza Pagos
>
*/
