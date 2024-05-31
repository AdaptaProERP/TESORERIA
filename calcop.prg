// Programa   : CALCOP
// Fecha/Hora : 01/06/2024 06:41:00
// Propósito  : Calcular la Cantidad de Pesos que representa n Bs, Según el Valor del Dolar
//              Cuanto representan 1000 Bs en pesos. Tomamos la Base del Dolar, (nBs/nDolar)*oDp:nValCop
// Creado Por : Juan Navas
// Llamado por: DPRECIBOSDIV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(nBs,nValUsd,nValCop,nRound)
    LOCAL nMtoCop:=0,nMtoUsd
   
    DEFAULT oDp:nValCop  :=4000,;
            oDp:nRoundCop:=2

    DEFAULT nBs    :=1000,;
            nValUsd:=oDp:nDivisa,;
            nValCop:=oDp:nValCop,;
            nRound :=oDp:nRoundCop

    nMtoUsd:=nBs/nValUsd
    nMtoCop:=nMtoUsd*nValCop

    IF nRound>0
      nMtoCop:=ROUND(nMtoCop,nRound)
    ENDIF

//  ? nMtoCop,"nMtoCop"
    
RETURN nMtoCop
// 
