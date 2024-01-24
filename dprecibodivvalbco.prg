// Programa   : DPRECIBODIVVALBCO
// Fecha/Hora : 25/09/2022 03:51:42
// Propósito  : Validar Cuentas Bancarias
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv,cCodSuc,aData,cRecNum,cCodCli,cCodCaja,dFecha,cNomCli,cCenCos)
  LOCAL I,aLine,nAt
  LOCAL cTipDoc,cCtaBco,cCodBco,cError:="",lResp:=.T.,cLine:="",aError:={}
  LOCAL aDataO,nColSel:=0
  LOCAL nRowErr:=0

  IF !ValType(oRecDiv)="O"
     RETURN .F.
  ENDIF

  aData:=IF(Empty(aData),ACLONE(oRecDiv:oBrw:aArrayData),aData)

  IF Empty(aData)
     RETURN .T.
  ENDIF

  aDataO:=ACLONE(oRecDiv:oBrw:aArrayData)

  ADEPURA(aData,{|a,n| !(a[7-1] .AND. a[9-1]="BCO")})

  IF Empty(aData)
     RETURN .T.
  ENDIF


  nAt:=oRecDiv:oBrw:nArrayAt

  oRecDiv:oBrw:aArrayData:=aData
  oRecDiv:oBrw:nArrayAt:=1
  oRecDiv:oBrw:Gotop()
  oRecDiv:oBrw:Refresh(.T.)

  aData:=ACLONE(aDataO)


  FOR I=1 TO LEN(aData)

    cError :=""

    IF aData[I,6] .AND. aData[I,9-1]="BCO"

      cWhere :=""
      aLine  :=aData[I]
      cLine  :=ALLTRIM(aLine[1])+" Monto="+ALLTRIM(FDP(aLine[5],"999,999,999,999.99"))
      cTipDoc:=aData[I,09-1]
      cCtaBco:=aData[I,17-1]
      cNumero:=aData[I,18-1]
      cCodBco:=SQLGET("DPCTABANCO","BCO_CODIGO","BCO_CTABAN"+GetWhere("=",cCtaBco))
      cError :=""

      IF Empty(cCtaBco)
        cError :="Falta=Cuenta Bancaria"     
        nColSel:=IF(nColSel=0,15,nColSel)
      ENDIF

      IF Empty(cCodBco)
        cError:=cError+IF(Empty(cError),"",",")+" Falta=Cód. del Banco" 
        nColSel:=IF(nColSel=0,16,nColSel)
      ENDIF

      IF Empty(cNumero)
         cError:=cError+IF(Empty(cError),"",",")+" Falta=Número de Trans." 
         nColSel:=IF(nColSel=0,17,nColSel)
      ENDIF
   
    ENDIF

    IF !Empty(cError)
      AADD(aError,{cLine,cError})
      nRowErr:=I
    ENDIF

  NEXT I

  IF !Empty(aError)

     oRecDiv:oBrw:nColSel:=1
     EJECUTAR("MSGBROWSE",aError,"Complete los Datos", NIL  ,200  ,NIL       ,NIL  ,.T., oRecDiv:oBrw)

     oRecDiv:oBrw:aArrayData:=aDataO
//     oRecDiv:oBrw:nArrayAt  :=nRowErr
//     oRecDiv:oBrw:nRowSel   :=nRowErr
     oRecDiv:oBrw:Refresh(.T.)
     oRecDiv:oBrw:nArrayAt  :=nRowErr
     oRecDiv:oBrw:nRowSel   :=nRowErr

//? nRowErr,"nRowErr"


     IF LEN(aData)=1
       oRecDiv:oBrw:nColSel   :=nColSel
       // oRecDiv:oBrw:KeyBoard(13)
     ELSE
       oRecDiv:oBrw:nColSel   :=15
     ENDIF

     lResp:=.F.

  ENDIF

RETURN lResp
// EOF

