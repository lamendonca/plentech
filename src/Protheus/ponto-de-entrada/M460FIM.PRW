#Include "Totvs.ch"

/*
    Ponto de Entrada no faturamento da Nota fiscal para enviar o xml/json para o B4You
*/

USER FUNCTION M460FIM // PE DO FATURAMENTO
    U_integB4U( "SendXmlJson", SC5->(C5_FILIAL+C5_NUM) )
RETURN
