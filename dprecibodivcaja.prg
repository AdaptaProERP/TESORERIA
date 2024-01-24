// Programa   : DPRECIBODIVCAJA         
// Fecha/Hora : 19/09/2022 01:28:40
// Propósito  : Guardar Caja
// Creado Por :
// Llamado por:
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oRecDiv,cCodSuc,aData,cRecNum,cCodCli,cCodCaja,dFecha,cNomCli,cCenCos)
  LOCAL I,oNew,oRecibo

  IF !ValType(oRecDiv)="O"
     RETURN .F.
  ENDIF

  aData:=IF(Empty(aData),ACLONE(oRecDiv:oBrw:aArrayData),aData)

  IF Empty(aData)
     RETURN .F.
  ENDIF

  DEFAULT cCenCos:=oDp:cCenCos

  ADEPURA(aData,{|a,n| !(a[7-1] .AND. a[9-1]="CAJ")})

// ViewArray(aData)

  oRecibo:=oRecDiv:oRecibo
  oNew   :=OpenTable("SELECT * FROM DPCAJAMOV",.F.)

  FOR I=1 TO LEN(aData)

     oNew:AppendBlank()
     oNew:Replace("CAJ_TIPO"  ,aData[I,10-1])
     oNew:Replace("CAJ_USUARI",oDp:cUsuario)
     oNew:Replace("CAJ_VALCAM",aData[I,2]  )
     oNew:Replace("CAJ_MTOITF",aData[I,13-1] )
     oNew:Replace("CAJ_ACT"   ,1           )
     oNew:Replace("CAJ_DOCASO",cRecNum     )

     IF oRecDiv:lCliente
       oNew:Replace("CAJ_ORIGEN","REC")
       oNew:Replace("CAJ_DEBCRE",1  )
     ELSE
       oNew:Replace("CAJ_ORIGEN","PAG")
       oNew:Replace("CAJ_DEBCRE",-1   )
     ENDIF

     oNew:Replace("CAJ_CODMON",aData[I,8-1]  )
     oNew:Replace("CAJ_MONTO" ,aData[I,5]  )
     oNew:Replace("CAJ_MTODIV",aData[I,4]  )
     oNew:Replace("CAJ_CODSUC",cCodSuc     )
     oNew:Replace("CAJ_CODMAE",cCodCli     )
     oNew:Replace("CAJ_CODCAJ",cCodCaja    )
     oNew:Replace("CAJ_FECHA" ,dFecha      )
     oNew:Replace("CAJ_DESCRI",cNomCli     )
    
     oNew:Replace("CAJ_CONTAB","N"         )
     oNew:Replace("CAJ_PORITF",aData[I,12-1] )
     oNew:Replace("CAJ_NUMCAJ",oDp:cIpLocal)
     oNew:Replace("CAJ_CENCOS",cCenCos     )
     oNew:Replace("CAJ_FCHCON",CTOD("")    )
     oNew:Replace("CAJ_COMPRO",""          )
     oNew:Commit("")

  NEXT I

  oNew:End()

RETURN .T.
// EOF
/*
 C001=CAJ_ACT             ,'N',002,0,'','Indicador de Estatus',0
 C002=CAJ_BCODIR          ,'C',020,0,'','Directorio Bancario',0
 C003=CAJ_CAJORG          ,'L',001,0,'','Estado de Origen de Caja',0
 C004=CAJ_CENCOS          ,'C',008,0,'','Centro de Costos',0
 C005=CAJ_CHQCTA          ,'C',020,0,'','Cuenta del Cheque',0
 C006=CAJ_CHQPLA          ,'C',001,0,'','Componente',0
 C007=CAJ_CMNNAC          ,'C',003,0,'','Moneda Nacional',0
 C008=CAJ_CODBCO          ,'C',006,0,'','C¾digo del banco',1
 C009=CAJ_CODCAJ          ,'C',006,0,'','C¾digo de Caja',1
 C010=CAJ_CODCTA          ,'C',020,0,'','Cuenta Contable',0
 C011=CAJ_CODMAE          ,'C',010,0,'','Cliente o Proveedor',1
 C012=CAJ_CODMON          ,'C',003,0,'','Moneda o Divisa',0
 C013=CAJ_CODSUC          ,'C',006,0,'','Sucursal',1
 C014=CAJ_COMPRO          ,'C',008,0,'','Comprobante contable',0
 C015=CAJ_CONTAB          ,'C',001,0,'','Contabilizado "S" SÝ',0
 C016=CAJ_CTAEGR          ,'C',020,0,'','Cuenta de Egreso',0
 C017=CAJ_CUENTA          ,'C',020,0,'','Cuenta contable de la integraci¾n',0
 C018=CAJ_DEBCRE          ,'N',002,0,'','Operaci¾n Ingreso o Egreso',0
 C019=CAJ_DESCRI          ,'C',060,0,'','Descripci¾n de la operaci¾n',0
 C020=CAJ_DOCASO          ,'C',010,0,'','Documento Asociado',1
 C021=CAJ_FCHCON          ,'D',008,0,'','Fecha para Contabilizar',0
 C022=CAJ_FCHDEP          ,'D',008,0,'','Fecha del dep¾sito',0
 C023=CAJ_FECHA           ,'D',008,0,'','Fecha de emisi¾n',0
 C024=CAJ_FILMAI          ,'N',007,0,'','Digitalizaci¾n',0
 C025=CAJ_HORA            ,'C',005,0,'','Hora',0
 C026=CAJ_MARCAF          ,'C',020,0,'','Marca Financiera',0
 C027=CAJ_MONTO           ,'N',014,2,'','Monto de la operaci¾n',0
 C028=CAJ_MTODIV          ,'N',019,2,'','Monto en Divisa',0
 C029=CAJ_MTOIMP          ,'N',014,2,'','Monto de Impuesto IVA desde Venta',0
 C030=CAJ_NUMCAJ          ,'C',012,0,'','ID del PC',0
 C031=CAJ_NUMDEP          ,'C',020,0,'','N·mero de dep¾sito',0
 C032=CAJ_NUMERO          ,'C',014,0,'','Cheque',0
 C033=CAJ_NUMMEM          ,'N',006,0,'','Memo',0
 C034=CAJ_NUMTRA          ,'C',008,0,'','N·mero de Transacci¾n',1
 C035=CAJ_ORIGEN          ,'C',003,0,'','M¾dulo de origen de la operaci¾n',0
 C036=CAJ_PORCOM          ,'N',006,3,'','% de Comisi¾n Bancaria',0
 C037=CAJ_PORIMP          ,'N',006,2,'','% de ISLR',0
 C038=CAJ_PORITF          ,'N',006,2,'','% ITF',0
 C039=CAJ_POSBCO          ,'C',003,0,'','Punto de Venta Bancario',1
 C040=CAJ_REGDEP          ,'C',008,0,'','Registro de Dep¾sito',1
 C041=CAJ_TIPCTA          ,'C',001,0,'','Tipo de Cuenta',0
 C042=CAJ_TIPO            ,'C',004,0,'','Tipo de operaci¾n',0
 C043=CAJ_USUARI          ,'C',003,0,'','Usuario que origin¾ la operaci¾n',0
 C044=CAJ_VALCAM          ,'N',019,4,'','Valor Cambiario',0
 C045=CAJ_MTOITF          ,'N',019,2,'','Monto IGTF',0
*/
