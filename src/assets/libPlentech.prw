#INCLUDE "PROTHEUS.CH"

//Create a log message for debugging or information purposes

User Function PlenMsg(cMsg, _cFunc, Auxiliar)
    Local lLog          := SuperGetMV("PL_LOG", .F., .T.)
    Local lVisible      := !isblind()
    Default _cFunc      := "Geral"
    Default Auxiliar    := "Geral"
    If lLog
        ConOut( "[ " + DtoS(dDataBase) + " - " + Time() + " ] [ Plentech - "+Auxiliar+" - Rest ] [ " + _cFunc + " ] " + cMsg )
        if lVisible 
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
