// Programa   : DPRECIBODIVBANCO
// Fecha/Hora : 25/09/2022 03:51:42
// Propósito  : Guardar los Registros de Movimiento Bancarios
// Creado Por : Juan Navas
// Llamado por: DPRECIBODIV
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv,cCodSuc,aData,cRecNum,cCodCli,cCodCaja,dFecha,cNomCli,cCenCos)
  LOCAL I,oNew,cNumTra,oRecibo,aLine
  LOCAL cTipDoc,cCtaBco,cCodBco,nMonto,cCodMon,nValCam,nMtoDiv,nIDB,cNumero

  IF !ValType(oRecDiv)="O"
     RETURN .F.
  ENDIF

//  aData:=IF(Empty(aData),ACLONE(oRecDiv:oBrw:aArrayData),aData)
  aData:=ACLONE(oRecDiv:oBrw:aArrayData)

  IF Empty(aData)
     RETURN .F.
  ENDIF

  DEFAULT cCenCos:=oDp:cCenCos

  oRecibo:=oRecDiv:oRecibo
  nValCam:=oRecibo:REC_VALCAM

  ADEPURA(aData,{|a,n| !(a[7-1] .AND. a[9-1]="BCO")})

  oNew:=OpenTable("SELECT * FROM DPCTABANCOMOV",.F.)

// ViewArray(aData)

  FOR I=1 TO LEN(aData)

    cWhere :=""
    aLine  :=aData[I]
    cTipDoc:=aData[I,09]
    cCtaBco:=aData[I,15+1] // 17-1]
    cCodBco:=SQLGET("DPCTABANCO","BCO_CODIGO","BCO_CTABAN"+GetWhere("=",cCtaBco))

    nMonto :=aData[I,05]
    cCodMon:=aData[I,08-1]
    nMtoDiv:=aData[I,04]
    cNumero:=aData[I,17]
    
    cNumTra:=SQLINCREMENTAL("DPCTABANCOMOV","MOB_NUMTRA",;
                   "    MOB_CUENTA"+GetWhere("=",cCtaBco)+;
                   "AND MOB_CODBCO"+GetWhere("=",cCodBco)+;
                   "AND MOB_TIPO"  +GetWhere("=",cTipDoc))

    nIDB:=EJECUTAR("IDBCAL",cTipDoc,nMonto,dFecha)

    oNew:Append()

    oNew:Replace("MOB_NUMTRA",SQLINCREMENTAL("DPCTABANCOMOV","MOB_NUMTRA",;
                   "    MOB_CUENTA"+GetWher	e("=",cCtaBco)+;
                   "AND MOB_CODBCO"+GetWhere("=",cCodBco)+;
                   "AND MOB_TIPO"  +GetWhere("=",cTipDoc)))

    oNew:Replace("MOB_DOCASO",oRecibo:REC_NUMERO)
    oNew:Replace("MOB_FECHA" ,dFecha            )
    oNew:Replace("MOB_FCHCON",dFecha            ) // Movimiento Conciliado
    oNew:Replace("MOB_FCHREG",dFecha            )
    oNew:Replace("MOB_CODSUC",oRecibo:REC_CODSUC)

    oNew:Replace("MOB_HORA"  ,oRecibo:REC_HORA )
    oNew:Replace("MOB_MONTO" ,nMonto )
    oNew:Replace("MOB_CODBCO",cCodBco)
    oNew:Replace("MOB_CUENTA",cCtaBco)
    oNew:Replace("MOB_DOCUME",cNumero)
    oNew:Replace("MOB_TIPO"  ,cTipDoc)
    oNew:Replace("MOB_IDB"   ,nIDB   )

    IF oRecDiv:lCliente
      oNew:Replace("MOB_DESCRI",GetFromVar("{oDp:xDPCLIENTES}")+": "+cNomCli)
      oNew:Replace("MOB_ORIGEN","REC") 
    ELSE
      oNew:Replace("MOB_DESCRI",GetFromVar("{oDp:xDPPROVEEDOR}")+": "+cNomCli)
      oNew:Replace("MOB_ORIGEN","PAG") 
    ENDIF

    oNew:Replace("MOB_CODMAE",oRecibo:REC_CODIGO)
    oNew:Replace("MOB_USUARI",oDp:cUsuario)
    oNew:Replace("MOB_ACT"   ,1 ) 
    oNew:Replace("MOB_CENCOS",oRecibo:REC_CENCOS)
    oNew:Replace("MOB_FCHCON",CTOD(""))
    oNew:Replace("MOB_VALCAM",nValCam)
    oNew:Replace("MOB_MTODIV",nMtoDiv)
    oNew:Replace("MOB_CODMON",cCodMon)
    oNew:Replace("MOB_RIF"   ,oRecDiv:cRif)
    oNew:Replace("MOB_NUMTRA",cNumTra    )
    oNew:Replace("MOB_ESTADO","A"        )
    oNew:Replace("MOB_CODMOD",oDp:cCtaMod)
    oNew:Replace("MOB_MONNAC",nMonto     )
    oNew:Commit("")

    IF oRecDiv:lCliente
       SQLUPDATE("DPBANCOTIP","TDB_INGRES",.T.,"TDB_CODIGO"+GetWhere("=",cTipDoc))
    ELSE
       SQLUPDATE("DPBANCOTIP","TDB_PAGOS",.T.,"TDB_CODIGO"+GetWhere("=",cTipDoc))
    ENDIF

  NEXT I

  oNew:End()

RETURN .T.
// EOF
