#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE 'TOPCONN.CH'

/*/{Protheus.doc} User Function restB4U  */

/* Plentech */
// B4U.prw - REST API with FWRest class
// This file contains a webservice to receive a webhook from B4YouLog.
// It is used to receive purchase orders and send them to the Protheus system.
// Surely your goodness and faithfulness will pursue me all my days - Psalm 23:6


WSRESTFUL restB4U DESCRIPTION "PLENTECH - REST Web Service para integração " FORMAT "application/json"

    //Input data
    WSDATA Token        AS String OPTIONAL
    WSDATA Produto      AS String OPTIONAL
    WSDATA CNPJ		    AS String OPTIONAL

    //Output data
    WSDATA Json         AS String OPTIONAL

    WSMETHOD POST WEBHOOK DESCRIPTION "Receber Status Pedido" ;
        WSSYNTAX "/restB4U/WEBHOOK/" PATH "/WEBHOOK" PRODUCES APPLICATION_JSON

END WSRESTFUL



WSMETHOD POST WEBHOOK WSSERVICE restB4U

    Local Message   := ""
    Local _Order    := _Status :=""
    Local cJSON     := Self:GetContent()
    Private oJson   := JsonObject():New()
    Private _cAlias := GetNextAlias()
    Private _cFil   := "0207" // Default branch 1 if CNPJ is empty
    Self:SetContentType("application/json")

    ret := oJson:FromJson(cJSON)
    If ValType(ret) == "C"
        Message  := '{ "mensagem": "Falha ao transformar texto em objeto json!"' +','+ CRLF
        Message  += ' "erro" : '+  ret +'}'
        u_PlenMsg(Message, "restB4U", "B4U")
        ::SetStatus( 500 )
        ::SetResponse(Message)
        Return
    EndIf

    // Exemple de JSON received
    // {
    // "Evento": "EM_CARREGAMENTO"
    // "Id": "028071"
    // }
    _Order   := AllTrim(oJson:GetJsonText(Upper("Id")))
    _Status  := AllTrim(oJson:GetJsonText(Upper("Evento")))


    If updateSC5(_cFil, _Order, _Status, @Message )
        u_PlenMsg(Message, "restB4U", "B4U")
        ::SetResponse(Message)
        ::SetStatus( 200 )
    Else
        u_PlenMsg(Message, "restB4U", "B4U")
        ::SetResponse(Message)
        ::SetStatus( 400 )
    EndIf
Return

Static Function updateSC5( Sucursal, Order, Status, Message  )
    Local lRet      := .F.
    DBSelectArea("SC5")
    SC5->(DbSetOrder(1))
    SC5->(DBSeek(Sucursal + Order )) // Filial + Pedido

    if SC5->(Found())
        lRet := .T.
        u_PlenMsg("Pedido encontrado: " + Sucursal + Order, "restB4U", "B4U")
        //TODO: Remove the comments
        if fieldPos("C5_B4USTA") > 0 .and. fieldPos("C5_XB4UJSO") > 0 // Check if the fields exist
            if !(SB1->C5_B4USTA == "S")
                RecLock("SC5",.F. )
                u_PlenMsg("Atualizando status do pedido: " + Order + " para " + Status, "restB4U", "B4U")
                SC5->C5_B4USTA := Status
                SC5->C5_XB4UJSO :=  StatusRet(Status)
                Message  := '{ "mensagem": "Status do pedido atualizado com sucesso!" }'
                u_PlenMsg(Message, "restB4U", "B4U")
                SC5->(MSUnlock())
            Else
                Message  := '{ "mensagem": "Status do pedido não pode ser atualizado!" }'
                u_PlenMsg(Message, "restB4U", "B4U")
                ::SetResponse(Message)
                ::SetStatus( 400 )
            endif
        endif
    Else
        Message  := '{ "mensagem": "Pedido não encontrado!" }'
        u_PlenMsg(Message, "restB4U", "B4U")
        lRet := .F.
    endif

Return lRet


Static Function StatusRet(Status)
    Do Case
        Case Status == "EM_CARREGAMENTO"
            Status := '{ "mensagem": "Disparado após a impressão da minuta de recebimento na b4you, neste cenário o Id é a chave eletrônica da NFe (44 dígitos)!" }'
        Case Status == "AVISO_RECEBIMENTO"
            Status := '{ "mensagem": "Disparado após a conferencia/bipagem das mercadorias recebidas pela b4you, neste cenário o Id é a chave eletrônica da NFe (44 dígitos)!" }'
        Case Status == "CONFERENCIA_RECEBIMENTO"
            Status := '{ "mensagem": "Disparado no final da confirmação do pedido no Checkout, neste cenário o Id é o número do pedido!" }'
        Case Status == "AGUARDANDO_NF_PARA_EXPEDICAO"
            Status := '{ "mensagem": "Disparado após a consolidação dos pedidos no Pré-carregamento (pedido pronto para ser expedido), neste cenário o Id é o número do pedido!" }'
        Case Status == "BLOQUEIO"
            Status := '{ "mensagem": "Disparado caso ocorre algum bloqueio no pedido, neste cenário o Id é o número do pedido!" }'
        Case Status == "CANCELADO"
            Status := '{ "mensagem": "Disparado caso o pedido seja cancelado, neste cenário o Id é o número do pedido!" }'
        Case Status == "EXPEDIDO"
            Status := '{ "mensagem": "Disparado quando a minuta de expedição está finalizada, neste cenário o Id é o número do pedido!" }'
        Otherwise
            Status := '{ "mensagem": "Status desconhecido!" }'
    End Case
Return Status
