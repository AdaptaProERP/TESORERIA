// Programa   : BRWTRANSFBCO
// Fecha/Hora : 13/09/2023 11:12:23
// Propósito  : Browse de Transferencia Bancaria
// Creado Por : Juan Navas
// Llamado por: DPBRWPAG
// Aplicación :
// Tabla      :

#INCLUDE "DPXBASE.CH"

PROCE MAIN(oDpBrw)
   LOCAL oDlg,I,oBrw,oFont,aArray:={},cJoin:="",cView,oCol,nAt,oBrwPag
   LOCAL aData:={}
   LOCAL nStyle      :=GetLbx("STYLE"       ,NIL,"N")
   LOCAL nClrPane1   :=GetLbx("COLORPANE1"  ,NIL,"N")
   LOCAL nClrPane2   :=GetLbx("COLORPANE2"  ,NIL,"N")
   LOCAL nClrText    :=GetLbx("COLORTEXT"   ,NIL,"N")
   LOCAL nFreeze     :=GetLbx("FREEZE"      ,NIL,"N")
   LOCAL nHeaderLin  :=GetLbx("HEADERLINES" ,NIL,"N")
   LOCAL aTotal      :={}
   LOCAL nClrCol     :=0
   LOCAL lTotal      :=.F.
   LOCAL bInit       :={||.T.}

   IF oDpBrw=NIL
       RETURN NIL
   ENDIF

   aArray:=oDpBrw:aData

   oBrwPag:=oDpBrw

   DEFINE DIALOG oDlg TITLE GetFromVar(oDpBrw:cTitle);
           FROM oDpBrw:nRow,oDpBrw:nCol TO oDpBrw:nRow+oDpBrw:nHeight,oDpBrw:nCol+oDpBrw:nWidth

    oDpBrw:oDlg:=oDlg
    oDpBrw:oDlg:lHelpIcon:=.F.

    oBrw := TXBrowse():New( oDlg )

    oBrw:SetArray(oDpBrw:aData,.F.) // JN

    IF nStyle=1
      oBrw:nColDividerStyle    := LINESTYLE_BLACK
      oBrw:nRowDividerStyle    := LINESTYLE_BLACK
      oBrw:lColDividerComplete := .t.
      oBrw:nMarqueeStyle       := MARQSTYLE_HIGHLROW
    ENDIF

    IF !EMPTY(nClrPane1) .AND. !EMPTY(nClrPane2)
      bInit:={||oBrw:SetColor(nClrText,nClrPane1)}
      oBrw:bClrStd := {|| {nClrText, iif( oBrw:nArrayAt%2=0, nClrPane1  ,   nClrPane2 ) } }
    ELSEIF !EMPTY(nClrPane1)
      oBrw:bClrStd := {|| {nClrText, nClrPane1} }
      bInit:={||oBrw:SetColor(nClrText,nClrPane1)}
    ENDIF

    IIF( !Empty(nFreeze),oBrw:nFreeze:= nFreeze,NIL)

    oBrw:SetFont(oFont)

    oBrw:lHScroll        := oDpBrw:lHScroll
    oBrw:lVScroll        := oDpBrw:lVScroll
    oBrw:nRowSel         := 1
    oBrw:lRecordSelector := .F.
    oBrw:nHeaderLines    := MAX(nHeaderLin,1)
    oBrw:lFooter         :=.T.  //::lTotal
    oBrw:nFooterLines    := 1

    FOR I := 1 TO LEN(oDpBrw:aCols)

      cView  :=oDpBrw:aCols[I]:cView
      oCol   :=oBrw:aCols[I]
      nClrCol:=oDpBrw:aCols[I]:nClrText

//? I,oDpBrw:aCols[I]:cHeader

      IF !Empty(oDpBrw:aCols[I]:cHeader) .AND. ValType(oDpBrw:aCols[I]:cHeader)="C"
       oDpBrw:aCols[I]:cHeader:=ALLTRIM(oDpBrw:aCols[I]:cHeader)
       oBrw:aCols[I]:cHeader:=STRTRAN(oDpBrw:aCols[I]:cHeader,";",CRLF)
      ELSE
       oDpBrw:aCols[I]:cHeader:=ALLTRIM(oDpBrw:aCols[I]:cHeader)
       oBrw:aCols[I]:cHeader:=oDpBrw:aCols[I]:cHeader
      ENDIF

      IF ValType(oDpBrw:aCols[I]:nWidth)="N"
        oBrw:aCols[I]:nWidth:=oDpBrw:aCols[I]:nWidth
      ENDIF

      IF LEN(aArray)>0 .AND. ValType(aArray[1,I])="N"
         oBrw:aCols[I]:nDataStrAlign:= AL_RIGHT
         oBrw:aCols[I]:nHeadStrAlign:= AL_RIGHT
      ENDIF

      IF !Empty(oDpBrw:aCols[I]:cPicture)
         BrwSetPicture(oBrw,oDpBrwoDpBrw:aCols[I]:cPicture , I)
      ENDIF

      IF !Empty(aArray) .AND. ValType(aArray[1,I])="L" .AND. cView="2"

          oCol:AddBmpFile("BITMAPS\xCheckOn.bmp")
          oCol:AddBmpFile("BITMAPS\xCheckOff.bmp")
          oCol:bBmpData:=GetFromLogic( oBrw, I )
          oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
          oCol:bStrData    := {||""} 

      ENDIF


      IF !Empty(aArray) .AND. ValType(aArray[1,I])="L" .AND. cView="3"
         oCol:AddBmpFile("BITMAPS\ledverde.bmp")
         oCol:AddBmpFile("BITMAPS\ledrojo.bmp")
         oCol:bBmpData:=GetFromLogic( oBrw, I )
         oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
         oCol:bStrData    := {||""} 
      ENDIF

      IF !Empty(aArray) .AND. ValType(aArray[1,I])="L" .AND. cView="4"
         oCol:AddBmpFile("BITMAPS\checkverde.bmp")
         oCol:AddBmpFile("BITMAPS\checkrojo.bmp")
         oCol:bBmpData:=GetFromLogic( oBrw, I )
         oCol:nDataStyle  := oCol:DefStyle( AL_LEFT, .F.)
         oCol:bStrData    := {||""} 
      ENDIF

      IF oDpBrw:aCols[I]:lTotal .AND. !Empty(oDpBrw:aCols[I]:cPicture)
         oBrw:lFooter               :=.T.
         oBrw:aCols[I]:cFooter      :=FDP(aTotal[I],"9"+::aCols[I]:cPicture)
         oBrw:aCols[I]:nFootStrAlign:= AL_RIGHT
         lTotal:=.T.
      ENDIF

      oBrw:aCols[I]:bLClickHeader := {|r,c,f,o| SortArray( o, oBrw:aArrayData ) }


      // Color de la Columna
      IF nClrCol<>0
         oBrw:aCols[I]:bClrStd:=BRWCOLSETCOLOR(oBrw,nClrCol,nClrPane1,nClrPane2)
      ENDIF

      // Color Definible de la Columna, segun campo Estado

      nAt:=ASCAN(oDpBrw:aColColor,{|a,n| a[1]=I})

      IF nAt>0
        oBrw:aCols[I]:bClrStd:=BRWCOLSETCOLORDEF(oBrw,oDpBrw:aColColor[nAt,1],oDpBrw:aColColor[nAt,2],oDpBrw:aColColor[nAt,3],nClrPane1,nClrPane2)
      ENDIF

      IF !Empty(oDpBrw:aCols[I]:cFont)
         oBrw:aCols[I]:oDataFont:=oFont(oDpBrw:aCols[I]:cFont)
      ENDIF

    NEXT

    IF lTotal
       oCol:=oBrw:aCols[1]
       oCol:cFooter      :=ALLTRIM(FDP(LEN(oBrw:aArrayData),"9,999,999"))
       oCol:nFootStrAlign:=AL_RIGHT
    ENDIF

    oBrw:bLDblClick:={||oDpBrw:Select()} // eval(::bLDblClick)}
    oBrw:bKeyDown := {| nKey | if( nKey == 13  ,oDpBrw:Select() , NIL )}

    oBrw:bClrFooter          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}
    oBrw:bClrHeader          := {|| { oDp:nLbxClrHeaderText, oDp:nLbxClrHeaderPane}}

    oBrw:CreateFromCode()

    oDpBrw:oBrw:=oBrw

    EJECUTAR("BRWPAGRESTOREPAR",oBrwPag)

    ACTIVATE DIALOG oDlg  ON INIT (EJECUTAR("DPBRWPAGINI",oDpBrw,oDlg,oBrw),;
                                   DPBRWSETBAR(oDlg,oBrw,oDpBrw),;
                                   ChangeSysMenu(oDpBrw),;
                                   Eval(bInit),.F.);
                                   VALID (oBrw:End(),oDpBrw:oTable:End(),EVAL(oDpBrw:bValid) ,.T.)

RETURN NIL
// EOF

