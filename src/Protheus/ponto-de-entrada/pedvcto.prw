#Include "Totvs.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FWADAPTEREAI.CH"
#INCLUDE 'FWLIBVERSION.CH'

/*
	Interface para informar as parcelas da Condicao Negociada
*/ 

User Function PedVcto()
	Local cCondPg	  := Alltrim(GetMv("MV_XCONDX",,"NEG"))
	Local aButtons	  := {}
	Local aNoFields   := {"ZZG_PEDIDO","ZZG_EMP","ZZG_FILORI","ZZG_DOC","ZZG_SERIE","ZZG_XPAYOR","ZZG_LINKPG"}
	Local nX          := 0
	Local nOpcA       := 0
	Local lRet        := .F.
	Local nPosVlr     := 0
	Local nIt 		  := 1  
	Local __cCondB    := ""
	
	Private nVlrInfo 	:= 0
	Private nParc     := 0
	Private nVlTot    := 0
	Private oSize
	Private oDlgVenc
	Private oVlTot
	Private oGetMan
	Private oGetDad

	If IsInCallStack('U_MT410TOK')
		
		__cCondB    := M->C5_CONDPAG
		
		nPosVlr := aScan(aHeader,{|x| UPPER(ALLTRIM(X[2])) == "C6_VALOR"})
		For nIt := 1 To Len(aCols)
			If !aCols[nIt][Len(aHeader)+1]
				nVlrInfo  += aCols[nIt][nPosVlr]
			Endif
		Next	
		If nVlrInfo<=0
			FWAlertError("Informar o valor do pedido de venda no campo [ Parcela 1 ] para a distribuição do valor informado.")
			Return .F.
		Endif
		If ALTERA
			aColsZZG:={}
			dbSelectArea("ZZG")
			dbSetOrder(1)
			dbGotop()
			If dbSeek( cEmpAnt + SC5->C5_FILIAL + SC5->C5_NUM )
				While ZZG->(!Eof()) .And. cEmpAnt + xFilial("SC5") + ZZG->ZZG_PEDIDO == cEmpAnt + SC5->C5_FILIAL + SC5->C5_NUM

					nParc++

					aAdd(aColsZZG,{;
									ZZG->ZZG_TIPO 	,;
									ZZG->ZZG_PARCEL	,;
									ZZG->ZZG_VENCRE	,;
									ZZG->ZZG_VALOR	,;
									.F.})

					ZZG->(dbSkip())
				End
			Endif
		Endif	
	Else
		__cCondB  := SC5->C5_CONDPAG
		nVlrInfo  := 0
		aColsZZG  :={}
		dbSelectArea("ZZG")
		dbSetOrder(1)
		dbGotop()
		If dbSeek( cEmpAnt + SC5->C5_FILIAL + SC5->C5_NUM )
			While ZZG->(!Eof()) .And. cEmpAnt + xFilial("SC5") + ZZG->ZZG_PEDIDO == cEmpAnt + SC5->C5_FILIAL + SC5->C5_NUM

				nParc++

				aAdd(aColsZZG,{;
								ZZG->ZZG_TIPO 	,;
								ZZG->ZZG_PARCEL	,;
								ZZG->ZZG_VENCRE	,;
								ZZG->ZZG_VALOR	,;
								.F.})

				ZZG->(dbSkip())
			End
		Endif
	Endif

	If __cCondB<>cCondPg
		FwAlertInfo("Disponivel apenas para pedidos com condição Negociada")
		Return
	Endif

	If Len(aColsZZG)==0
		aAdd(aColsZZG,{"","",CTOD("  /  /  "),0,.F.})
	Endif

	DEFINE MSDIALOG oDlgVenc FROM 000,000 TO 350,735 TITLE "Vencimentos" Of oMainWnd PIXEL STYLE DS_MODALFRAME STATUS
	oDlgVenc:lEscClose := .F.

	oSize := FwDefSize():New(.T.,,,oDlgVenc)

	oSize:AddObject( "CABECALHO",  100, 10, .T., .T. ) // Totalmente dimensionavel
	oSize:AddObject( "GETDADOS" ,  100, 80, .T., .T. ) // Totalmente dimensionavel
	oSize:AddObject( "RODAPE"   ,  100, 10, .T., .T. ) // Totalmente dimensionavel

	oSize:lProp 	:= .T. // Proporcional
	oSize:aMargins 	:= { 4, 4, 4, 4 } // Espaco ao lado dos objetos 0, entre eles 3

	oSize:Process() 	   // Dispara os calculos

	@ oSize:GetDimension("CABECALHO","LININI") ,oSize:GetDimension("CABECALHO","COLINI") SAY "Nr. Parcelas: "	  Of oDlgVenc PIXEL SIZE 100,9

	@ oSize:GetDimension("CABECALHO","LININI") ,oSize:GetDimension("CABECALHO","COLINI")+60 MSGET oPerc VAR nParc Of oDlgVenc PIXEL SIZE 060,9 ;
		WHEN IsInCallStack('U_MT410TOK') Valid(Comparar())


	oGetDad := MsNewGetDados():New(oSize:GetDimension("GETDADOS","LININI"),oSize:GetDimension("GETDADOS","COLINI"),;
		oSize:GetDimension("GETDADOS","LINEND"),oSize:GetDimension("GETDADOS","COLEND"),;
		IIF(INCLUI .OR. ALTERA,GD_INSERT+GD_UPDATE+GD_DELETE,0),"AllwaysTrue","U_ZZGTOk","+ZZG_PARCEL",,,999,/* - */,/*superdel*/,/*delok*/,oDlgVenc,@aHeadZZG,@aColsZZG)


	@ oSize:GetDimension("RODAPE","LININI"),oSize:GetDimension("RODAPE","COLINI")     Say "TOTAL" FONT oDlgVenc:oFont OF oDlgVenc PIXEL
	@ oSize:GetDimension("RODAPE","LININI"),oSize:GetDimension("RODAPE","COLINI")+40  Say oVlTot VAR nVlTot Picture PesqPict("ZZG","ZZG_VALOR ") FONT oDlgVenc:oFont COLOR CLR_HBLUE OF oDlgVenc PIXEL

	ACTIVATE MSDIALOG oDlgVenc CENTERED ON INIT EnchoiceBar(oDlgVenc,{||IIF(U_ZZGTOk(),(nOpcA:=1,oDlgVenc:End()),(nOpcA:=0))},{||oDlgVenc:End()},,aButtons)

	If (nOpcA == 1 .AND. (INCLUI .OR. ALTERA))
		aColsZZG := aClone(oGetDad:aCols)
		For nX := 1 To Len(aColsZZG)
			If !aColsZZG[nX][Len(aHeadZZG)+1]
				lRet:=.T.
			Endif
		Next		
	Endif

Return(lRet)

Static Function Comparar()
	Local nDiff      := 0
	Local lRet       := .T.
	Local nLin       := 1
	Local lEntrada   := .F.
	Local __nValParc := 0
	Local dEmissao   := dDataBase

	If nParc<=0
		FwAlertInfo("O numero de parcelas deve ser maior que zero!")
		Return .F.
	Endif

	nVlTot :=0

	If FWAlertYesNo("Negociação com Entrada ?","Atencao")
		lEntrada := .T.
	Endif

	aColsZZG := {}

	__nValParc := Round(nVlrInfo/nParc,2)

	For nLin := 1 To nParc
		If lEntrada .And. nLin==1
			aadd(aColsZZG,{Space(3),Alltrim(Str(nLin)),dEmissao   ,__nValParc,.F.})
		Else
			dEmissao+=30
			dEmissao := DataValida(dEmissao)

			aadd(aColsZZG,{Space(3),Alltrim(Str(nLin)),dEmissao,__nValParc,.F.})
		Endif
		nVlTot+=__nValParc
	Next

	If nVlrInfo<>nVlTot
		nDiff := nVlrInfo - nVlTot
		If nDiff>0//Pedido de Venda Maior
			If Len(aColsZZG)>0
				aColsZZG[1][4]-=nDiff
			Endif
		Else
			If Len(aColsZZG)>0
				aColsZZG[1][4]+=nDiff
			Endif
		Endif
		nVlTot :=0
		For nLin := 1 To Len(aColsZZG)
			nVlTot+=aColsZZG[nLin][4]
		Next
	Endif

	oGetDad:SetArray(aColsZZG,.T.)
	oGetDad:Refresh()

	oVlTot:Refresh()

Return lRet

User Function ZZGLOk()
	Local lRet := .T.
	Local nLin := 1
	Local nVld := 0

	For nLin := 1 To Len(aColsZZG)
		nVld += aColsZZG[nLin][4]
	Next

	If nVld<>nVlrInfo

		cTexto := 'O valor total é maior que o informado no pedido de venda.'+chr(13)+chr(10)
		cTexto += ''+chr(13)+chr(10)
		cTexto += 'Total Digitado..: '+Alltrim(Str(nVld))+chr(13)+chr(10)
		cTexto += 'Valor do Pedido.: '+Alltrim(Str(nVlrInfo))

		FwAlertInfo(cTexto)
		lRet := .F.

	Endif

Return lRet

User Function ZZGTOk()
	Local lRet := .T.
	Local nLin := 1
	Local nVld := 0

	If IsInCallStack('U_MT410TOK')

		For nLin := 1 To Len(aColsZZG)
			nVld += aColsZZG[nLin][4]
		Next

		If nVld<>nVlrInfo

			cTexto := 'O valor total é maior que o informado no pedido de venda.'+chr(13)+chr(10)
			cTexto += ''+chr(13)+chr(10)
			cTexto += 'Total Digitado..: '+Alltrim(Str(nVld))+chr(13)+chr(10)
			cTexto += 'Valor do Pedido.: '+Alltrim(Str(nVlrInfo))

			FwAlertInfo(cTexto)
			lRet := .F.

		Endif
	Endif

Return lRet

User Function ZZGVAL()
	Local aAux := oGetDad:aCols
	Local lRet := .T.
	Local nLin := 1
	Local cCpo := ReadVar()
	Local nVDi := 0
	Local nX

	nVlrDig := 0
	For nLin := 1 To Len(aAux)
		If nLin < n
			nVlrDig += aAux[nLin][4]
		Elseif nLin == n
			nVlrDig += &cCpo
			aAux[n][4] := &cCpo
		Elseif nLin > n
			Exit
		Endif
	Next

	nVlrDistr := nVlrInfo-nVlrDig
	nParcNew  := Round((nVlrDistr/(Len(aAux)-n)),2)

	For nX := nLin To Len(aAux)
		aAux[nX][4] := nParcNew
	Next

	nVlTot := 0
	For nX := 1 To Len(aAux)
		nVlTot += aAux[nX][4]
	Next

	If nVlrInfo<>nVlTot
		nDiff := nVlrInfo - nVlTot
		If nDiff>0//Pedido de Venda Maior
			If Len(aAux)>0
				aAux[1][4]-=nDiff
			Endif
		Else
			If Len(aAux)>0
				aAux[1][4]+=nDiff
			Endif
		Endif
		nVlTot :=0
		For nLin := 1 To Len(aAux)
			nVlTot+=aAux[nLin][4]
		Next
	Endif

	aCols     := aClone(aAux)
	aColsZZG  := aClone(aAux)

	oGetDad:aCols := aClone(aColsZZG)
	oGetDad:Refresh()
	oGetDad:oBrowse:Refresh()

	oVlTot:Refresh()
	oDlgVenc:Refresh()


Return lRet

