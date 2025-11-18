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
    _Order   := AllTrim(oJson:GetJsonText("Id"))
    _Status  := AllTrim(oJson:GetJsonText("Evento"))
    u_PlenMsg("Recebido o pedido: " + _Order + " com status: " + _Status, "restB4U", "B4U")

    If updateSC5(_Order, _Status, @Message )
        u_PlenMsg(Message, "restB4U", "B4U")
        ::SetResponse(Message)
        ::SetStatus( 200 )
    Else
        u_PlenMsg(Message, "restB4U", "B4U")
        ::SetResponse(Message)
        ::SetStatus( 400 )
    EndIf
Return

Static Function updateSC5( Order, Status, Message  )
    Local lRet      := .F.
    Local cStatus   := SuperGetMV("PL_B4UAUTH", .f., "AGUARDANDO_NF_PARA_EXPEDICAO") // This status able the order to be invoiced
    DBSelectArea("SC5")
    SC5->(DbSetOrder(1))
    SC5->(DbGoTop())
    SC5->(DBSeek( Order )) // Filial + Pedido

    if SC5->(Found())
        lRet := .T.
        u_PlenMsg("Pedido encontrado: " + Order, "restB4U", "B4U")
        RecLock("SC5",.F. )
        u_PlenMsg("Atualizando status do pedido: " + Order + " para " + Status, "restB4U", "B4U")
        SC5->C5_XB4USTA := Status
        // SC5->C5_XB4UJSO :=  StatusRet(Alltrim(Status))
        if Alltrim(Status) == cStatus // if empty, set the date
            aGetOrder := u_integB4U("GetOrder", Order ) //get details of order from B4U
            varInfo("Retorno GetOrder ->IntegB4U -> aGetOrder",   aGetOrder)
            if aGetOrder[1] == .t.
                SC5->C5_PESOL       := aGetOrder[2][1] // Weight
                SC5->C5_PBRUTO      := aGetOrder[2][1] // Weight
                SC5->C5_VOLUME1     := aGetOrder[2][2] // Volume
                SC5->C5_ESPECI1     := SuperGetMV("PL_ESPECIE",.f., "CX") // Volume
            endif
        endif
        Message  := '{ "mensagem": "Status do pedido atualizado com sucesso!" }'
        u_PlenMsg(Message, "restB4U", "B4U")
        SC5->(MSUnlock())
    Else
        Message  := '{ "mensagem": "Pedido '+Order+' não encontrado!" }'
        u_PlenMsg(Message, "restB4U", "B4U")
        lRet := .F.
    endif

Return lRet


Static Function StatusRet(Status)
    Do Case
        Case Status == "EM_CARREGAMENTO"
            Status := 'Disparado após a impressão da minuta de recebimento na b4you, neste cenário o Id é a chave eletrônica da NFe (44 dígitos)!'
        Case Status == "AVISO_RECEBIMENTO"
            Status := 'Disparado após a conferencia/bipagem das mercadorias recebidas pela b4you, neste cenário o Id é a chave eletrônica da NFe (44 dígitos)!'
        Case Status == "CONFERENCIA_RECEBIMENTO"
            Status := 'Disparado no final da confirmação do pedido no Checkout, neste cenário o Id é o número do pedido!'
        Case Status == "AGUARDANDO_NF_PARA_EXPEDICAO"
            Status := 'Disparado após a consolidação dos pedidos no Pré-carregamento (pedido pronto para ser expedido), neste cenário o Id é o número do pedido!'
        Case Status == "BLOQUEIO"
            Status := 'Disparado caso ocorre algum bloqueio no pedido, neste cenário o Id é o número do pedido!'
        Case Status == "CANCELADO"
            Status := 'Disparado caso o pedido seja cancelado, neste cenário o Id é o número do pedido!'
        Case Status == "EXPEDIDO"
            Status := 'Disparado quando a minuta de expedição está finalizada, neste cenário o Id é o número do pedido!'
        Otherwise
            Status := 'Status desconhecido!'
    End Case
Return Status

