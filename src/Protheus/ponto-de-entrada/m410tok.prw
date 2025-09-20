#INCLUDE "TOTVS.CH"

/*
Ponto de ENtrada para abrir tela de parcelas
*/

User Function MT410TOK 
	Local lRet 				:= .T.
	Local cCondPg			:= Alltrim(GetMv("MV_XCONDX",,"NEG"))
	Local lAuto 			:= IsInCallStack("MSEXECAUTO")

	If Funname() == "MATA410" .And. !lAuto
		If (Alltrim(M->C5_CONDPAG)==Alltrim(cCondPg) .And. (ALTERA .OR. INCLUI))
			lRet := U_PedVcto() 
		Endif
	Endif

Return lRet  
