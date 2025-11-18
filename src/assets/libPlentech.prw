#INCLUDE "PROTHEUS.CH"

//Create a log message for debugging or information purposes

User Function PlenMsg(cMsg, _cFunc, Auxiliar)
	Local lLog          := SuperGetMV("PL_LOG", .F., .T.)
	Local lVisible      := !isblind()
	Default _cFunc      := "Geral"
	Default Auxiliar    := "Geral"
	If lLog
		ConOut( "[ " + DtoS(dDataBase) + " - " + Time() + " ] [ Plentech - "+Auxiliar+" - Rest ] [ " + _cFunc + " ] " + cMsg )
		if lVisible .and. GetEnvServer() !='lucas'
			MsgInfo( cMsg, _cFunc )
		EndIf
	EndIf
Return


User Function xSemCarc(cConteudo)

	//Retirando caracteres
	cConteudo := StrTran(cConteudo, "'", "")
	cConteudo := StrTran(cConteudo, "#", "")
	cConteudo := StrTran(cConteudo, "%", "")
	cConteudo := StrTran(cConteudo, "*", "")
	cConteudo := StrTran(cConteudo, "&", "E")
	cConteudo := StrTran(cConteudo, ">", "")
	cConteudo := StrTran(cConteudo, "<", "")
	cConteudo := StrTran(cConteudo, "!", "")
	cConteudo := StrTran(cConteudo, "@", "")
	cConteudo := StrTran(cConteudo, "$", "")
	cConteudo := StrTran(cConteudo, "(", "")
	cConteudo := StrTran(cConteudo, ")", "")
	cConteudo := StrTran(cConteudo, "_", "")
	cConteudo := StrTran(cConteudo, "=", "")
	cConteudo := StrTran(cConteudo, "+", "")
	cConteudo := StrTran(cConteudo, "{", "")
	cConteudo := StrTran(cConteudo, "}", "")
	cConteudo := StrTran(cConteudo, "[", "")
	cConteudo := StrTran(cConteudo, "]", "")
	cConteudo := StrTran(cConteudo, "/", "")
	cConteudo := StrTran(cConteudo, "?", "")
	cConteudo := StrTran(cConteudo, ".", "")
	cConteudo := StrTran(cConteudo, "\", "")
	cConteudo := StrTran(cConteudo, "|", "")
	cConteudo := StrTran(cConteudo, ":", "")
	cConteudo := StrTran(cConteudo, ";", "")
	cConteudo := StrTran(cConteudo, '"', '')
	cConteudo := StrTran(cConteudo, '°', '')
	cConteudo := StrTran(cConteudo, 'ª', '')
	cConteudo := StrTran(cConteudo, ",", "")
	cConteudo := StrTran(cConteudo, "-", "")
	cConteudo := StrTran(cConteudo, "Ø", "")
	cConteudo := StrTran(cConteudo, "º", "")

	cConteudo := StrTran(cConteudo, "ã", "a")
	cConteudo := StrTran(cConteudo, "Ã", "A")
	cConteudo := StrTran(cConteudo, "á", "a")
	cConteudo := StrTran(cConteudo, "Á", "A")
	cConteudo := StrTran(cConteudo, "à", "a")
	cConteudo := StrTran(cConteudo, "À", "A")
	cConteudo := StrTran(cConteudo, "é", "e")
	cConteudo := StrTran(cConteudo, "É", "E")
	cConteudo := StrTran(cConteudo, "ê", "e")
	cConteudo := StrTran(cConteudo, "Ê", "E")
	cConteudo := StrTran(cConteudo, "ë", "e")
	cConteudo := StrTran(cConteudo, "Ë", "E")
	cConteudo := StrTran(cConteudo, "í", "i")
	cConteudo := StrTran(cConteudo, "Í", "I")
	cConteudo := StrTran(cConteudo, "ì", "i")
	cConteudo := StrTran(cConteudo, "Ì", "I")
	cConteudo := StrTran(cConteudo, "ï", "i")
	cConteudo := StrTran(cConteudo, "Ï", "I")
	cConteudo := StrTran(cConteudo, "ó", "o")
	cConteudo := StrTran(cConteudo, "Ó", "O")
	cConteudo := StrTran(cConteudo, "ò", "o")
	cConteudo := StrTran(cConteudo, "Ò", "O")
	cConteudo := StrTran(cConteudo, "õ", "o")
	cConteudo := StrTran(cConteudo, "Õ", "O")
	cConteudo := StrTran(cConteudo, "ô", "o")
	cConteudo := StrTran(cConteudo, "Ô", "O")
	cConteudo := StrTran(cConteudo, "ö", "o")
	cConteudo := StrTran(cConteudo, "Ö", "O")
	cConteudo := StrTran(cConteudo, "ú", "u")
	cConteudo := StrTran(cConteudo, "Ú", "U")
	cConteudo := StrTran(cConteudo, "ù", "u")
	cConteudo := StrTran(cConteudo, "Ù", "U")
	cConteudo := StrTran(cConteudo, "û", "u")
	cConteudo := StrTran(cConteudo, "Û", "U")
	cConteudo := StrTran(cConteudo, "ü", "u")
	cConteudo := StrTran(cConteudo, "Ü", "U")

	cConteudo := StrTran(cConteudo, "ç", "c")
	cConteudo := StrTran(cConteudo, "Ç", "C")

	cConteudo := Alltrim(cConteudo)

Return cConteudo

User Function updB4U(Order)
	Local aArea := GetArea()
	Default Order := SC5->(C5_FILIAL+C5_NUM)
	if isincallstack("MATA410")
		Order := SC5->(C5_FILIAL+C5_NUM)
	endif
	DBSelectArea("SC5")
	SC5->(DbSetOrder(1))
	SC5->(DbGoTop())
	SC5->(DBSeek( Order )) // Filial + Pedido
	if SC5->(Found())
		RecLock("SC5",.F. )
		aGetOrder := u_integB4U("GetOrder", Order ) //get details of order from B4U
		varInfo("Retorno GetOrder ->IntegB4U -> aGetOrder",   aGetOrder)
		if aGetOrder[1] == .t.
			SC5->C5_PESOL       := aGetOrder[2][1] // Weight
			SC5->C5_PBRUTO      := aGetOrder[2][1] // Weight
			SC5->C5_VOLUME1     := aGetOrder[2][2] // Volume
			SC5->C5_XB4USTA     := aGetOrder[2][3] // Status
			SC5->C5_ESPECI1     := SuperGetMV("PL_ESPECIE",.f., "CX") // Volume
			xAtuSC9(Order, aGetOrder[2][4]) // Update items
			Message  := '{ "mensagem": "Status do pedido atualizado com sucesso!" }'
		else
			Message  := '{ "mensagem": "Erro ao obter dados do B4U!" }'
		endif
		u_PlenMsg(Message, "restB4U", "B4U")
		SC5->(MSUnlock())
	endif

	restarea(aArea)

return

/* Atualiza itens de um pedido na tabela SC9
*/
Static Function xAtuSC9(Order, aItens)
	Local lRet 	:= .F.
	Local nI 	:= 0
	Local aArea := GetArea()

	DBSelectArea("SC9")
	SC9->(DbSetOrder(1))
	SC9->(DbGoTop())
	SC9->(DBSeek( Order )) // Filial + Pedido
	while !SC9->(EOF()) .and. SC9->(Found());
			.and. (SC9->(C9_FILIAL+C9_PEDIDO) == Order) //C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED
		// Procurando o item no array retornado do B4U
		for nI := 1 to Len(aItens)
			if Alltrim(SC9->C9_PRODUTO) == aitens[1]:produto:codpeca
				RecLock("SC9",.F. )
				SC9->C9_XQTDB4U := Val(aitens[1]:produto:qtdepeca)
				SC9->(MSUnlock())
				lRet := .T.
				exit
			endif
		next nI
		SC9->(DBSkip())
	enddo


	restarea(aArea)
Return lRet
