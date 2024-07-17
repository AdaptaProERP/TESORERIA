// Programa   : DPCTABANCO_CREA          
// Fecha/Hora : 17/07/2024 06:47:28
// Propósito  : Crear Cuenta Bancaria Indefinida
// Creado Por : Juan Navas
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN()

   IF COUNT("DPBANCOS")=0

    EJECUTAR("CREATERECORD","DPBANCOS",{"BAN_CODIGO","BAN_NOMBRE","BAN_ACTIVO"},;
                                       {STRZERO(0,6),"Indefinido",.T.},;
                                        NIL,.T.,"BAN_CODIGO"+GetWhere("=",STRZERO(0,6)))

   ENDIF

   IF COUNT("DPCTABANCO")=0

     EJECUTAR("CREATERECORD","DPCTABANCO",{"BCO_CODIGO"  ,"BCO_CTABAN","BCO_CODMON","BCO_ACTIVA","BCO_PAGAR","BCO_TIPCTA"},;
                                        {STRZERO(0,6),"Indefinida",oDp:cMoneda,.T.,.T.,"Otras"},;
                                         NIL,.T.,"BCO_CTABAN"+GetWhere("=","Indefinida"))

   ENDIF

RETURN .T.
// EOF
