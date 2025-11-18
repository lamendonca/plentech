#include "rwmake.ch"
User Function M460QRY()

    Local cQuery    :=paramixb[1]
    Local cCodQry   := paramixb[2]
    Local cFilter   := " AND C9_BLEST = ' ' AND C9_BLCRED = ' ' "
    Local cStatus   := SuperGetMV("PL_B4UAUTH", .f., "AGUARDANDO_NF_PARA_EXPEDICAO") // This status able the order to be invoiced

    cQuery += cFilter
    cQuery += " and C9_FILIAL + C9_PEDIDO IN (SELECT C5_FILIAL + C5_NUM FROM "+RetSQLName("SC5")+" WHERE C5_XB4USTA = '"+cStatus+"') "

Return(cQuery)
