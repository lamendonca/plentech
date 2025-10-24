#INCLUDE "PROTHEUS.CH"

User Function M410PVNF()

    Local lRet      := .T.
    Local cOrder    := SC5->(C5_FILIAL+C5_NUM)
    Local cStatus   := SuperGetMV("PL_B4UAUTH", .f., "AGUARDANDO_NF_PARA_EXPEDICAO") // This status able the order to be invoiced

    if !(Alltrim(SC5->C5_XB4USTA) == Alltrim(cStatus)) // Not in the correct status to send to B4U
        lRet := .F.
        u_PlenMsg("Pedido ainda não separado pela B4YOU: " + cOrder + CRLF+CRLF+ ;
        "Status Atual: " + IIF(Empty(SC5->C5_XB4USTA),"EM BRANCO", SC5->C5_XB4USTA) +CRLF +;
        "Status Liberado: " + cStatus , "M410PVNF", "B4U")
        return lRet

    Endif

Return lRet
