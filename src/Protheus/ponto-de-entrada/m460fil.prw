#include 'protheus.ch'
//https://tdn.totvs.com/pages/releaseview.action?pageId=6784179
User Function M460FIL
    Local cStatus   := SuperGetMV("PL_B4UAUTH", .f., "AGUARDANDO_NF_PARA_EXPEDICAO") // This status able the order to be invoiced
    Local cFilter   := ""

    cFilter += "SC9->C9_BLEST ==' ' .AND. SC9->C9_BLCRED==' ' "+;
    " .and. '"+cStatus+"' == Posicione('SC5', 1, SC9->(C9_FILIAL+C9_PEDIDO), 'C5_XB4USTA') "

Return cFilter
