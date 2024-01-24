// Programa   : DPRECIBOSDIVINST
// Fecha/Hora : 26/09/2022 04:35:41
// Propósito  : Cargar Instrumentos de Caja y Bancos
// Creado Por : JUAN NAVAS
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(lVentas,lReset,lPagEle)
  LOCAL I,oTable,cVenta:=""
  LOCAL lView:=.F.
  LOCAL cWhere

  DEFAULT lVentas:=.T.,lReset:=.F.,lPagEle:=.F.

/*
  IF lReset

    oDp:aCajaInst:={}
    oDp:aBancoTip:={}
    oDp:aFormas  :={}

  ENDIF

  IF Empty(oDp:aCajaInst) 

    cWhere:=IF(lPagEle," OR ICJ_PAGELE=1","")

    oDp:aCajaInst:=ASQL("SELECT ICJ_CODIGO,ICJ_NOMBRE,ICJ_DIRBCO,ICJ_MONEDA,ICJ_CODMON,ICJ_BMP,ICJ_REQNUM,ICJ_PORITF FROM DPCAJAINST "+;
                      "WHERE ICJ_ACTIVO=1 AND "+IIF(lVentas,"ICJ_INGRES=1","ICJ_EGRESO=1")+cWhere+" ORDER BY ICJ_NOMBRE")

  ENDIF

  //IF Empty(oDp:aBancoTip) .AND. COUNT("DPCTABANCO")>0
  
  IF Empty(oDp:aBancoTip) .AND. COUNT("DPCTABANCO","BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND BCO_ACTIVA=1")>0  

    cWhere:=IF(lPagEle," AND TDB_PAGELE=1","")

    oDp:aBancoTip:=ASQL("SELECT TDB_CODIGO,TDB_NOMBRE,TDB_BMP FROM DPBANCOTIP "+;
                        "WHERE TDB_ACTIVO=1 AND "+IIF(lVentas,"TDB_INGRES=1","TDB_PAGOS=1")+cWhere)

  ENDIF

  oDp:aFormas:={}

  FOR I=1 TO LEN(oDp:aCajaInst) 

    AADD(oDp:aFormas,{oDp:aCajaInst[I,2],ALLTRIM(oDp:aCajaInst[I,6]),.T.,oDp:aCajaInst[I,3],oDp:aCajaInst[I,7],oDp:aCajaInst[I,1],;
                      oDp:aCajaInst[I,4],oDp:aCajaInst[I,8]})

  NEXT I

  FOR I=1 TO LEN(oDp:aBancoTip)
    AADD(oDp:aFormas,{oDp:aBancoTip[I,2],ALLTRIM(oDp:aBancoTip[I,3]),.F.,.F.,.T.,oDp:aBancoTip[I,1],.F.,0})
  NEXT I

  FOR I=1 TO LEN(oDp:aFormas)
    oDp:aFormas[I,2]:=IIF(Empty(oDp:aFormas[I,2]),"BITMAPS\xCheckOff.bmp",ALLTRIM(oDp:aFormas[i,2]))
  NEXT I
  
  IF Empty(oDp:aBancoDir) 

    oDp:aListMsg:={}

    oTable:=OpenTable("SELECT BAN_NOMBRE,BAN_TELEF1,BAN_TELEF2,BAN_TELEF3,BAN_TELEF4,BAN_WEB  FROM DPBANCODIR ",.T.)
    oTable:Gotop()
    oTable:DbEval({||oTable:Replace("BAN_TELEF1",ALLTRIM(oTable:BAN_TELEF1)+;
                     ALLTRIM(oTable:BAN_TELEF2)+" "+;
                     ALLTRIM(oTable:BAN_TELEF3)+" "+;
                     ALLTRIM(oTable:BAN_TELEF4)+" "+;
                     ALLTRIM(oTable:BAN_WEB))})

    oDp:aBancoDir:=ACLONE(oTable:aDataFill)

    oTable:End()

    AEVAL(oDp:aBancoDir,{|a,n|AADD(oDp:aListMsg,a[2])})

  ENDIF
*/

  oDp:aCuentaBco:=ASQL(" SELECT DPBANCOS.BAN_NOMBRE,DPCTABANCO.BCO_CTABAN,DPBANCOS.BAN_CODIGO FROM DPCTABANCO "+;
                       " INNER JOIN DPBANCOS ON DPBANCOS.BAN_CODIGO = DPCTABANCO.BCO_CODIGO "+;
                       " WHERE BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND BCO_ACTIVA=1 ORDER BY DPBANCOS.BAN_NOMBRE ")
   
  oDp:aNombreBco:=ATABLE(" SELECT DPBANCOS.BAN_NOMBRE FROM DPCTABANCO "+;
                         " INNER JOIN DPBANCOS ON DPBANCOS.BAN_CODIGO = DPCTABANCO.BCO_CODIGO "+;
                         " WHERE BCO_CODSUC"+GetWhere("=",oDp:cSucursal)+" AND BCO_ACTIVA=1 GROUP BY DPBANCOS.BAN_NOMBRE ORDER BY DPBANCOS.BAN_NOMBRE ")

// ViewArray(oDp:aCuentaBco)
// ViewArray(oDp:aNombreBco)

RETURN .T.
// 
