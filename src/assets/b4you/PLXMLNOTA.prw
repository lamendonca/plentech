#INCLUDE "PROTHEUS.CH"
#INCLUDE "APWIZARD.CH"
#INCLUDE "FILEIO.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "TOTVS.CH"
#INCLUDE "PARMTYPE.CH"
/*/{Protheus.doc} PLXMLNOTA   
    (Consulta status de NFe para expedir.
	Tem que estar posicionado na SF2.
	Funções estraidas dos fontes SPEDNFE, DANFEII)
/*/
User Function PLXMLNOTA(xCXMLNFE)
	Local aAreaPP    := GetArea()
	Local cIdEnt     := ""
	Local cProtocolo := ""
	// Local cCodRet	 := ""
	Local nX         := 0
	Local aNota      := {}
	Local cModalidade:= ""
	Local lAutomato  := .F.
	Local aXml       := {}
	Private lUsaColab := UsaColaboracao("1")
	Default xCXMLNFE := ""
	aadd(aNota,{})
	aadd(Atail(aNota),.F.)
	aadd(Atail(aNota),"S")
	aadd(Atail(aNota),SF2->F2_EMISSAO)
	aadd(Atail(aNota),SF2->F2_SERIE)
	aadd(Atail(aNota),SF2->F2_DOC)
	aadd(Atail(aNota),SF2->F2_CLIENTE)
	aadd(Atail(aNota),SF2->F2_LOJA)
	If IsReady(,,,lUsaColab)
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³Obtem o codigo da entidade                                              ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		cIdEnt := GetIdEnt(lUsaColab)
		If !Empty(cIdEnt)
			aXml := GetXML(cIdEnt,aNota,@cModalidade, lAutomato)
			For nX := 1 To Len(aXml)
				cProtocolo := aXml[nX][1] // Protocolo
				If !zIsLock('SF2', SF2->(RecNo()))
					SF2->(MsUnlock())
				EndIf
				// Begin Transaction
				// 	//Atualiza tabela
				// 	If !Empty(cProtocolo)
				// 		// RecLock("SF2", .F.)
				// 		// SF2->F2_FIMP := "S"
				// 		// SF2->F2_CHVNFE := SubStr(NfeIdSPED(aXML[nX][2],"Id"),4)
				// 		// SF2->(MsUnlock())
				// 		// Xml da NF para integrar com a plataforma Set Canhoto
						xCXMLNFE := aXML[nX][2]
				// 	EndIf
				// 	If cCodRet $ RetCodDene() // Uso Denegado
				// 		// RecLock("SF2", .F.) 
				// 		// SF2->F2_FIMP := "D" 
				// 		// SF2->(MsUnlock()) 
				// 	EndIf
				// End Transaction
			Next nX
		Else
			Aviso("SPED","Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!",{"OK"},3)	 //"Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!"
		EndIf
	Else
		Aviso("SPED","Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!",{"OK"},3) //"Execute o módulo de configuração do serviço, antes de utilizar esta opção!!!"
	EndIf
	RestArea(aAreaPP)
Return
Static Function IsReady(cURL,nTipo,lHelp,lUsaColab)
	Local cHelp  := ""
	local cError := ""
	Local lRetorno := .F.
	DEFAULT nTipo := 1
	DEFAULT lHelp := .F.
	DEFAULT lUsaColab := .F.
	if !lUsaColab
		If FunName() <> "LOJA701"
			If !Empty(cURL) .And. !PutMV("MV_SPEDURL",cURL)
				RecLock("SX6",.T.)
				&('SX6->X6_FIL') := xFilial( "SX6" )
				&('SX6->X6_VAR') := "MV_SPEDURL"
				&('SX6->X6_TIPO') := "C"
				&('SX6->X6_DESCRIC') := "URL SPED NFe"
				MsUnLock()
				PutMV("MV_SPEDURL",cURL)
			EndIf
			SuperGetMv() //Limpa o cache de parametros - nao retirar
			DEFAULT cURL      := PadR(GetNewPar("MV_SPEDURL","http://"),250)
		Else
			If !Empty(cURL) .And. !PutMV("MV_NFCEURL",cURL)
				RecLock("SX6",.T.)
				&('SX6->X6_FIL') := xFilial( "SX6" )
				&('SX6->X6_VAR') := "MV_NFCEURL"
				&('SX6->X6_TIPO') := "C"
				&('SX6->X6_DESCRIC') := "URL de comunicação com TSS"
				MsUnLock()
				PutMV("MV_NFCEURL",cURL)
			EndIf
			SuperGetMv() //Limpa o cache de parametros - nao retirar
			DEFAULT cURL      := PadR(GetNewPar("MV_NFCEURL","http://"),250)
		EndIf
		//Verifica se o servidor da Totvs esta no ar
		if(isConnTSS(@cError))
			lRetorno := .T.
		Else
			If lHelp
				Aviso("SPED",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
			EndIf
			lRetorno := .F.
		EndIf
		//Verifica se Há Certificado configurado
		If nTipo <> 1 .And. lRetorno
			if( isCfgReady(, @cError) )
				lRetorno := .T.
			else
				If nTipo == 3
					cHelp := cError
					If lHelp .And. !"003" $ cHelp
						Aviso("SPED",cHelp,{"OK"},3)
						lRetorno := .F.
					EndIf
				Else
					lRetorno := .F.
				EndIf
			endif
		EndIf
		//Verifica Validade do Certificado
		If nTipo == 2 .And. lRetorno
			isValidCert(, @cError)
		EndIf
	else
		lRetorno := ColCheckUpd()
		if lHelp .And. !lRetorno .And. !lAuto
			MsgInfo("UPDATE do TOTVS Colaboração 2.0 não aplicado. Desativado o uso do TOTVS Colaboração 2.0")
		endif
	endif
Return(lRetorno)
//-----------------------------------------------------------------------
/*/{Protheus.doc} RetCodDene
Função que retorna os codigos de uso denegado
@author Natalia Sartori
@since 01.03.2012
@version 1.00
@Return	cString - retorna os códigos de uso denegado da NFe/CTe
/*/
//-----------------------------------------------------------------------
Static Function RetCodDene()
	Local cString := "'110','301','205','302','303','304','305','306'"
Return cString
Static Function GetIdEnt(lUsaColab)
	local cIdEnt := ""
	local cError := ""
	Default lUsaColab := .F.
	If !lUsaColab
		cIdEnt := getCfgEntidade(@cError)
		if(empty(cIdEnt))
			Aviso("SPED", cError, {"OK"}, 3)
		endif
	else
		if !( ColCheckUpd() )
			Aviso("SPED","UPDATE do TOTVS Colaboração 2.0 não aplicado. Desativado o uso do TOTVS Colaboração 2.0",{"OK"},3)
		else
			cIdEnt := "000000"
		endif
	endIf
Return(cIdEnt)
Static Function GetXML(cIdEnt,aIdNFe,cModalidade, lAutomato)
	Local aRetorno		:= {}
	Local aDados		:= {}
	Local cURL			:= PadR(GetNewPar("MV_SPEDURL","http://localhost:8080/sped"),250)
	Local cModel		:= "55"
	Local nZ			:= 0
	Local nCount		:= 0
	Local oWS
	default lAutomato := .F.
	If Empty(cModalidade)
		oWS := WsSpedCfgNFe():New()
		oWS:cUSERTOKEN := "TOTVS"
		oWS:cID_ENT    := cIdEnt
		oWS:nModalidade:= 0
		oWS:_URL       := AllTrim(cURL)+"/SPEDCFGNFe.apw"
		oWS:cModelo    := cModel
		if lAutomato
			if FindFunction("getParAuto")
				aRetAuto := GetParAuto("AUTONFETestCase")
				cModalidade := aRetAuto[07]
			endif
		else
			If oWS:CFGModalidade()
				cModalidade    := SubStr(oWS:cCfgModalidadeResult,1,1)
			Else
				cModalidade    := ""
			EndIf
		endif
	EndIf
	oWs := nil
	For nZ := 1 To len(aIdNfe)
		nCount++
		aDados := executeRetorna( aIdNfe[nZ], cIdEnt, , lAutomato )
		if ( nCount == 10 )
			delClassIntF()
			nCount := 0
		endif
		aAdd(aRetorno,aDados)
	Next nZ
Return(aRetorno)
static function executeRetorna( aNfe, cIdEnt, lUsacolab, lAutomato )
	Local aRetorno		:= {}
	Local aDados		:= {}
	Local aIdNfe		:= {}
	Local aWsErro		:= {}
	Local cAviso		:= ""
	Local cCodRetNFE	:= ""
	Local cDHRecbto		:= ""
	Local cDtHrRec		:= ""
	Local cDtHrRec1		:= ""
	Local cErro			:= ""
	Local cModTrans		:= ""
	Local cProtDPEC		:= ""
	Local cProtocolo	:= ""
	Local cMsgNFE		:= ""
	local cMsgRet		:= ""
	Local cRetDPEC		:= ""
	Local cRetorno		:= ""
	Local cURL			:= PadR(GetNewPar("MV_SPEDURL","http://localhost:8080/sped"),250)
	Local cCodStat		:= ""
	Local dDtRecib		:= CToD("")
	Local nDtHrRec1		:= 0
	Local nX			:= 0
	Local nY			:= 0
	Local nZ			:= 1
	Local nPos			:= 0
	Local cVersaoNF     := ""
	Local cFullXML      := ""
	Private oWS
	Private oDHRecbto
	Private oNFeRet
	Private oDoc
	default lUsacolab	:= .F.
	default lAutomato	:= .F.
	aAdd(aIdNfe,aNfe)
	if !lUsacolab
		oWS:= WSNFeSBRA():New()
		oWS:cUSERTOKEN        := "TOTVS"
		oWS:cID_ENT           := cIdEnt
		oWS:nDIASPARAEXCLUSAO := 0
		oWS:_URL 			  := AllTrim(cURL)+"/NFeSBRA.apw"
		oWS:oWSNFEID          := NFESBRA_NFES2():New()
		oWS:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
		aadd(aRetorno,{"","",aIdNfe[nZ][4]+aIdNfe[nZ][5],"","","",CToD(""),"","","",""})
		aadd(oWS:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
		Atail(oWS:oWSNFEID:oWSNotas:oWSNFESID2):cID := aIdNfe[nZ][4]+aIdNfe[nZ][5]
		If oWS:RETORNANOTASNX() //#CPP Ajustado (Delleon 26/05/2020) //Trecho antigo -> lAutomato .or. oWS:RETORNANOTASNX()
			if lAutomato
				if FindFunction("getParAuto")
					aRetAuto := GetParAuto("AUTONFETestCase")
					oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS := NFESBRA_ARRAYOFNFES5():New()
					aAdd( oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5, NFESBRA_NFES5():New() )
					oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[1]:CID := aRetAuto[01]
					oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[1]:oWSNFE := NFESBRA_NFEPROTOCOLO():New()
					oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[1]:oWSNFE:CPROTOCOLO := aRetAuto[02]
					oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[1]:oWSNFE:CXML := aRetAuto[03]
					oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[1]:oWSNFE:CXMLPROT := aRetAuto[04]
				endif
			endif
			If Len(oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5) > 0
				For nX := 1 To Len(oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5)
					cRetorno        := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSNFE:CXML
					cProtocolo      := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSNFE:CPROTOCOLO
					cDHRecbto  		:= oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSNFE:CXMLPROT
					oNFeRet			:= XmlParser(cRetorno,"_",@cAviso,@cErro)
					cModTrans		:= IIf(ValAtrib("oNFeRet:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT") <> "U",IIf (!Empty("oNFeRet:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT"),oNFeRet:_NFE:_INFNFE:_IDE:_TPEMIS:TEXT,1),1)
					cCodStat		:= ""
					If ValType(oWs:OWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:OWSDPEC)=="O"
						cRetDPEC        := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSDPEC:CXML
						cProtDPEC       := oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:oWSDPEC:CPROTOCOLO
					EndIf
					//Tratamento para gravar a hora da transmissao da NFe
					If !Empty(cProtocolo)
						oDHRecbto		:= XmlParser(cDHRecbto,"","","")
						cDtHrRec		:= IIf(ValAtrib("oDHRecbto:_ProtNFE:_INFPROT:_DHRECBTO:TEXT")<>"U",oDHRecbto:_ProtNFE:_INFPROT:_DHRECBTO:TEXT,"")
						nDtHrRec1		:= RAT("T",cDtHrRec)
						cMsgRet 		:= IIf(ValAtrib("oDHRecbto:_ProtNFE:_INFPROT:_XMSG:TEXT")<>"U",oDHRecbto:_ProtNFE:_INFPROT:_XMSG:TEXT,"")
						cCodStat		:= IIf(ValAtrib("oDHRecbto:_ProtNFE:_INFPROT:_CSTAT:TEXT")<>"U",oDHRecbto:_ProtNFE:_INFPROT:_CSTAT:TEXT,"")
						cVersaoNF       := IIf(ValAtrib("oDHRecbto:_PROTNFE:_VERSAO:TEXT")<>"U",oDHRecbto:_PROTNFE:_VERSAO:TEXT,"")
						If nDtHrRec1 <> 0
							cDtHrRec1   :=	SubStr(cDtHrRec,nDtHrRec1+1)
							dDtRecib	:=	SToD(StrTran(SubStr(cDtHrRec,1,AT("T",cDtHrRec)-1),"-",""))
						EndIf
						// Xml da NF para integrar com a plataforma Set Canhoto
						cFullXML := '<nfeProc versao="'+cVersaoNF+'" xmlns="http://www.portalfiscal.inf.br/nfe">'
						cFullXML += cRetorno+cDHRecbto
						cFullXML += '</nfeProc>'
						cRetorno := cFullXML
					EndIf
					nY := aScan(aIdNfe,{|x| x[4]+x[5] == SubStr(oWs:oWSRETORNANOTASNXRESULT:OWSNOTAS:OWSNFES5[nX]:CID,1,Len(x[4]+x[5]))})
					oWS:cIdInicial    := aIdNfe[nZ][4]+aIdNfe[nZ][5]
					oWS:cIdFinal      := aIdNfe[nZ][4]+aIdNfe[nZ][5]
					If oWS:MONITORFAIXA()
						nPos    := 0
						aWsErro := {}
						If !Empty(cProtocolo) .AND. !Empty(cCodStat)
							aWsErro := oWS:OWSMONITORFAIXARESULT:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE
							For nPos := 1 To Len(aWsErro)
								If Alltrim(aWsErro[nPos]:CCODRETNFE) == Alltrim(cCodStat)
									Exit
								Endif
							Next
						Endif
						If nPos > 0 .And. nPos <= Len(aWsErro)
							cCodRetNFE := oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE[nPos]:CCODRETNFE
							cMsgNFE	:= oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE[nPos]:CMSGRETNFE
						Else
							cCodRetNFE := oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE[len(oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE)]:CCODRETNFE
							cMsgNFE	:= oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE[len(oWS:oWsMonitorFaixaResult:OWSMONITORNFE[1]:OWSERRO:OWSLOTENFE)]:CMSGRETNFE
						Endif
					EndIf
					If nY > 0
						aRetorno[nY][1] := cProtocolo
						aRetorno[nY][2] := cRetorno
						aRetorno[nY][4] := cRetDPEC
						aRetorno[nY][5] := cProtDPEC
						aRetorno[nY][6] := cDtHrRec1
						aRetorno[nY][7] := dDtRecib
						aRetorno[nY][8] := cModTrans
						aRetorno[nY][9] := cCodRetNFE
						aRetorno[nY][10]:= cMsgNFE
						aRetorno[nY][11]:= cMsgRet
					EndIf
					cRetDPEC := ""
					cProtDPEC:= ""
				Next nX
			EndIf
		Else
			if !lAutomato
				Aviso("DANFE",IIf(Empty(GetWscError(3)),GetWscError(1),GetWscError(3)),{"OK"},3)
			endif
		EndIf
	else
		oDoc 			:= ColaboracaoDocumentos():new()
		oDoc:cModelo	:= "NFE"
		oDoc:cTipoMov	:= "1"
		oDoc:cIDERP	:= aIdNfe[nZ][4]+aIdNfe[nZ][5]+FwGrpCompany()+FwCodFil()
		aadd(aRetorno,{"","",aIdNfe[nZ][4]+aIdNfe[nZ][5],"","","",CToD(""),"","","",""})
		if odoc:consultar()
			aDados := ColDadosNf(1)
			if !Empty(oDoc:cXMLRet)
				cRetorno	:= oDoc:cXMLRet
			else
				cRetorno	:= oDoc:cXml
			endif
			aDadosXml := ColDadosXMl(cRetorno, aDados, @cErro, @cAviso)
			if '<obsCont xCampo="nRegDPEC">' $ cRetorno
				aDadosXml[9] := SubStr(cRetorno,At('<obsCont xCampo="nRegDPEC"><xTexto>',cRetorno)+35,15)
			endif
			cProtocolo		:= aDadosXml[3]
			cModTrans		:= IIF(Empty(aDadosXml[5]),aDadosXml[7],aDadosXml[5])
			cCodRetNFE 		:= aDadosXml[1]
			cMsgNFE 		:= iif (aDadosXml[2]<> nil ,aDadosXml[2],"")
			cMsgRet			:= aDadosXml[11]
			//Dados do DEPEC
			If !Empty( aDadosXml[9] )
				cRetDPEC        := cRetorno
				cProtDPEC       := aDadosXml[9]
			EndIf
			//Tratamento para gravar a hora da transmissao da NFe
			If !Empty(cProtocolo)
				cDtHrRec		:= aDadosXml[4]
				nDtHrRec1		:= RAT("T",cDtHrRec)
				If nDtHrRec1 <> 0
					cDtHrRec1   :=	SubStr(cDtHrRec,nDtHrRec1+1)
					dDtRecib	:=	SToD(StrTran(SubStr(cDtHrRec,1,AT("T",cDtHrRec)-1),"-",""))
				EndIf
			EndIf
			aRetorno[1][1] := cProtocolo
			aRetorno[1][2] := cRetorno
			aRetorno[1][4] := cRetDPEC
			aRetorno[1][5] := cProtDPEC
			aRetorno[1][6] := cDtHrRec1
			aRetorno[1][7] := dDtRecib
			aRetorno[1][8] := cModTrans
			aRetorno[1][9] := cCodRetNFE
			aRetorno[1][10]:= cMsgNFE
			aRetorno[1][11]:= cMsgRet
			cRetDPEC := ""
			cProtDPEC:= ""
		endif
	endif
	oWS       := Nil
	oDHRecbto := Nil
	oNFeRet   := Nil
return aRetorno[len(aRetorno)]
static Function ValAtrib(atributo)
Return (type(atributo) )
Static Function zIsLock(cAliasLock, nRegLock)
	Local aArea        := GetArea()
	Local lTravado     := .F.
	Local aTravas      := {}
	Default cAliasLock := aArea[POS_ALIAS]
	Default nRegLock   := 0
	//Se tiver zerado o RecNo
	If nRegLock == 0
		//Se for o Mesmo Alias do GetArea()
		If cAliasLock == aArea[POS_ALIAS]
			nRegLock := aArea[POS_RECNO]
			//Senão, abre a tabela e pega o RecNo atual
		Else
			DbSelectArea(cAliasLock)
			nRegLock := (cAliasLock)->(RecNo())
		EndIf
	EndIf
	//Pegando os registros travados em memória
	aTravas := (cAliasLock)->(DBRLockList())
	//Se encontrar o recno nos travados na memória, o registro está travado
	If aScan(aTravas,{|x| x == nRegLock }) > 0
		lTravado := .T.
	EndIf
	RestArea(aArea)
Return lTravado
