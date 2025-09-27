#include "TOPCONN.CH"
#include "TBICONN.CH"
#include "TOTVS.CH"
#include "FWBROWSE.CH"
#include "FWMVCDEF.CH"
#include "XMLXFUN.CH"
#include "RESTFUL.CH"
#include "PROTHEUS.CH"

/* Plentech */
// upVendas.prw - WebService to integrage a upVendas
// Surely your goodness and faithfulness will pursue me all my days - Psalm 23:6

// - [ ] Document a payload and responses from all methods

WSRESTFUL upVendas DESCRIPTION "REST Web Service para integração do Up Vendas - PLENTECH"
    // Se quiser usar Self:CNPJ em Customer via QueryString, declare como WSDATA (opcional):
    WSDATA Product      as String OPTIONAL
    WSDATA PageSize     as Number OPTIONAL
    WSDATA PageNumber   as Number OPTIONAL
    WSDATA CGC          as String OPTIONAL

    // Customer por rota com CNPJ
    WSMETHOD GET Customer DESCRIPTION "Buscar Cliente" ;
        WSSYNTAX "/upVendas/customer/" ;
        PATH "/customer/" PRODUCES APPLICATION_JSON

    WSMETHOD POST Cliente DESCRIPTION "Incluir Clientes" ;
        WSSYNTAX "/upVendas/customer/" ;
        PATH "/customer" CONSUMES APPLICATION_JSON PRODUCES APPLICATION_JSON

    WSMETHOD GET Produto DESCRIPTION "Buscar Produto" ;
        WSSYNTAX "/upVendas/product/" ;
        PATH "/product/" PRODUCES APPLICATION_JSON

    WSMETHOD GET TodosProdutos DESCRIPTION "Buscar todos Produtos" ;
        WSSYNTAX "/upVendas/products/" ;
        PATH "/products" PRODUCES APPLICATION_JSON

    WSMETHOD POST PedidoVenda DESCRIPTION "Incluir Pedido de Vendas" ;
        WSSYNTAX "/upVendas/salesOrder/" ;
        PATH "/salesOrder" CONSUMES APPLICATION_JSON PRODUCES APPLICATION_JSON

END WSRESTFUL

WSMETHOD POST Cliente WSSERVICE upVendas
    Local cMsgApi       := ""
    Local aReturn       := {}
    Local cAction       := ""
    // Local cJSON         := Self:GetContent()
    Local oReturn       := JsonObject():New()

    // Variables to break JSON
    Local _cNome        := ""
    Local _cNomeReduz   := "" 
    Local _cInsc        := ""
    Local _cCep         := ""
    Local _cEnd         := ""
    Local _cBairro      := ""
    Local _cEst         := ""
    Local _cMunc        := ""
    Local _cEmail       := ""
    Local _cTel         := ""
    Local _cCodCli      := ""
    Local _cLojaCli     := ""
    Local _cCgc         := ""
    Local __Active      := "2" //1=Inativo;2=Ativo                                                                                                               
    Local _cCodMun      := "" // Codigo do Municipio

    Local cJSON          := Self:GetContent()
    Private oJson        := JsonObject():New()

    Self:SetContentType("application/json")

    ret := oJson:FromJson(cJSON)

    If ValType(ret) == "C"
        oReturn["Processo"] := "Falha ao transformar texto em objeto json!"
        oReturn["Erro"]     := ret
        ::SetStatus( 500 )
        ::SetResponse(oReturn:toJson())
        Return
    EndIf

    cAction    := AllTrim(oJson:GetJsonText("action")) // Incluir ou Alterar

    BreakingJson(oJson, @_cNome, @_cNomeReduz, @_cInsc, @_cCep, @_cEnd, @_cBairro, @_cEst, @_cMunc, @_cEmail, @_cTel, @_cCodCli, @_cLojaCli, @_cCgc, @__Active, @_cCodMun) )

    do case
        case cAction == "add"
            aReturn := u_upIncCustomer(@_cNome, @_cNomeReduz, @_cInsc, @_cCep, @_cEnd, @_cBairro, @_cEst, @_cMunc, @_cEmail, @_cTel, @_cCodCli, @_cLojaCli, @_cCgc, @__Active, @cMsgApi, @oReturn, @_cCodMun)
        case cAction == "alt"
            aReturn := u_upAltCustomer(@_cNome, @_cNomeReduz, @_cInsc, @_cCep, @_cEnd, @_cBairro, @_cEst, @_cMunc, @_cEmail, @_cTel, @_cCodCli, @_cLojaCli, @_cCgc, @__Active, @cMsgApi, @oReturn, @_cCodMun)
        otherwise
            cMsgApi := '{ "mensagem": "Ação inválida. Use Incluir ou Alterar." }'
            ::SetStatus( 400 )
            ::SetResponse(cMsgApi)
            Return
    endcase
    if aReturn[2]
        ::SetResponse(aReturn[1])
        ::SetStatus(200)
    else
        // ::SetResponse('{ "erro" : "Não houve dados a serem consultados"}')
        ::SetResponse(aReturn[1])
        ::SetStatus( 500 )
    endif
return

Static function BreakingJson(oJson, _cNome, _cNomeReduz, _cInsc,  _cCep, _cEnd,  _cBairro, _cEst, _cMunc, _cEmail, _cTel, _cCodCli, _cLojaCli, _cCgc, __Active, _cCodMun) )

    Local names
    Local lenJson
    Local item
    Local aJson := {}
    Local I := 0

    lenJson := len(oJson)

    If lenJson > 0
        For i := 1 to lenJson
            BreakingJson(oJson[i])
        Next
    Else
        names := oJson:Getnames()
        For i := 1 to len(names)
            item := oJson[names[i]]

            If ValType(item) == "C"
                Aadd(aJson,{names[i], cvaltochar(oJson[names[i]])})

                _cNome        := IIF(AllTrim(Lower(names[i]))  == lower("customerName"),       AllTrim(oJson[names[i]]),                _cNome      )
                _cNomeReduz   := IIF(AllTrim(Lower(names[i]))  == lower("tradeName"),          AllTrim(oJson[names[i]]),                _cNomeReduz )
                _cInsc        := IIF(AllTrim(Lower(names[i]))  == lower("stateRegistration"),  AllTrim(oJson[names[i]]),                _cInsc      )
                _cCep         := IIF(AllTrim(Lower(names[i]))  == lower("postalCode"),         AllTrim(oJson[names[i]]),                _cCep       )
                _cEnd         := IIF(AllTrim(Lower(names[i]))  == lower("address"),            AllTrim(oJson[names[i]]),                _cEnd       )
                _cBairro      := IIF(AllTrim(Lower(names[i]))  == lower("district"),           AllTrim(oJson[names[i]]),                _cBairro    )
                _cEst         := IIF(AllTrim(Lower(names[i]))  == lower("state"),              AllTrim(oJson[names[i]]),                _cEst       )
                _cMunc        := IIF(AllTrim(Lower(names[i]))  == lower("city"),               AllTrim(oJson[names[i]]),                _cMunc      )
                _cEmail       := IIF(AllTrim(Lower(names[i]))  == lower("mail"),               AllTrim(oJson[names[i]]),                _cEmail     )
                _cTel         := IIF(AllTrim(Lower(names[i]))  == lower("mobile"),             AllTrim(oJson[names[i]]),                _cTel       )
                _cCodCli      := IIF(AllTrim(Lower(names[i]))  == lower("customerCode"),       Substr(AllTrim(oJson[names[i]]),1,6),    _cCodCli    )
                _cLojaCli     := IIF(AllTrim(Lower(names[i]))  == lower("customerCode"),       Substr(AllTrim(oJson[names[i]]),7,2),    _cLojaCli   )
                _cCgc         := IIF(AllTrim(Lower(names[i]))  == lower("document"),           AllTrim(oJson[names[i]]),                _cCgc       )
                __Active      := IIF(AllTrim(Lower(names[i]))  == lower("active"),             AllTrim(oJson[names[i]]),                __Active    )
                _cCodMun      := IIF(AllTrim(Lower(names[i]))  == lower("cityCode"),           AllTrim(oJson[names[i]]),                _cCodMun    )

            Elseif ValType(item) == "N"
            endif
        Next i

    Endif

Return


WSMETHOD GET Customer WSSERVICE upVendas
    Local CGC       := AllTrim(Self:CGC) //Take all json contents

    If Empty(CGC)
        ::SetResponse('{ "erro": "Nenhum cliente não informado!" }')
        ::SetStatus(404)
    EndIf

    aReturn := u_upCustomer(CGC)

    if aReturn[2]
        ::SetResponse(aReturn[1])
        ::SetStatus(200)
    else
        ::SetResponse('{ "erro" : "Não houve dados a serem consultados"}')
        ::SetStatus( 500 )
    endif

Return


WSMETHOD GET TodosProdutos WSSERVICE upVendas
    Local PageSize       := AllTrim(Self:PageSize)
    Local PageNumber     := AllTrim(Self:PageNumber)

    If Empty(PageSize) .OR. Empty(PageNumber)
        PageSize   := 100 // Default page size
        PageNumber := 1   // Default page number
    EndIf

    aReturn := u_upProducts("",.F., PageSize, PageNumber)
    if aReturn[2]
        ::SetResponse(aReturn[1])
        ::SetStatus(200)
    else
        ::SetResponse('{ "erro" : "Não houve dados a serem consultados"}')
        ::SetStatus( 500 )
    endif

Return

WSMETHOD GET PRODUTO WSSERVICE upVendas

    Local Product       := AllTrim(Self:Product) //Take all json contents

    If Empty(Product)
        ::SetResponse('{ "erro": "Produto não informado!" }')
        ::SetStatus(404)
    EndIf

    aReturn := u_upProducts(Product)

    if aReturn[2]
        ::SetResponse(aReturn[1])
        ::SetStatus(200)
    else
        ::SetResponse('{ "erro" : "Não houve dados a serem consultados"}')
        ::SetStatus( 500 )
    endif
Return


WSMETHOD POST PedidoVenda WSSERVICE upVendas

    Local cMsgApi       := ""
    Local _aCabec       := {}
    Local _aItens       := {}
    Local _aPagmt       := {}
    Local _cFil         := ""
    Local cJSON         := Self:GetContent()
    Private oJson       := JsonObject():New()
    Private _cAlias     := GetNextAlias()

    Self:SetContentType("application/json")

    ret := oJson:FromJson(cJSON)
    If ValType(ret) == "C" // Check if there was an error converting JSON
        oReturn["Processo"] := "Falha ao transformar texto em objeto json!"
        oReturn["Erro"]     := ret
        ::SetStatus( 500 )
        ::SetResponse(oReturn:toJson())
        Return
    EndIf

    fDesArray(oJson,@_aCabec, @_aItens, @_aPagmt)
    If U_upNewOrder(_aCabec, _aItens, _aPagmt, @cMsgApi, 3 /*3 = Incluir - 2 = Alterar*/) 
        ::SetResponse(cMsgApi)
        ::SetStatus( 200 )
    Else
        ::SetResponse(cMsgApi)
        ::SetStatus( 200 ) // retorno 200 exclusivo para a upVendas
    EndIf
Return

Static Function fDesArray(jsonObj, _aCabec, _aItens, _aPagmt)
    Local k, l
    Local names
    Local lenJson
    Local item
    lenJson := len(jsonObj)
    If lenJson > 0
        For k := 1 to lenJson
            fDesArray(jsonObj[k])
        Next
    Else
        names := jsonObj:Getnames()
        For k := 1 to len(names)
            item := jsonObj[names[k]]
            If ValType(item) == "A" .AND. AllTrim(names[k]) == "itens" 
                _aItens := Array(len(item))
                For l := 1 to len(item)
                    QbraJson(item[l], @_aItens, l, 1)
                Next l
            ElseIf ValType(item) == "A" .AND. AllTrim(names[k]) == "cabecalho"
                _aCabec := Array(len(item))
                For l := 1 to len(item)
                    QbraJson(item[l], @_aCabec, l, 2)
                Next l
            ElseIf ValType(item) == "A" .AND. AllTrim(names[k]) == "pagamentos"
                _aPagmt := Array(len(item))
                For l := 1 to len(item)
                    QbraJson(item[l], @_aPagmt, l, 1)
                Next l
            Endif
        Next k
    Endif
Return

Static Function QbraJson(jsonObj, _aItens, j, _nTipo)
    local i
    Local o
    local names
    local lenJson
    local item
    Local _aGeral := {}
    lenJson := len(jsonObj)
    If lenJson > 0
        For i := 1 to lenJson
            QbraJson(jsonObj[i])
        Next
    Else
        names := aSort(jsonObj:GetNames(), , , {|x, y| x < y})
        For i := 1 to len(names)
            item := jsonObj[names[i]]
            If ValType(item) == "C" .or.  ValType(item) == "N"
                Aadd(_aGeral,{names[i], jsonObj[names[i]]})
            Else
                If ValType(item) == "A"
                    For o := 1 to len(item)
                        If ValType(item[o]) == "J"
                            QbraJson(item[o])
                        Endif
                    Next o
                Endif
            Endif
        Next i
    Endif
    If _nTipo == 1
        _aItens[J] := _aGeral
    Else
        _aItens  := _aGeral
    EndIf
Return

