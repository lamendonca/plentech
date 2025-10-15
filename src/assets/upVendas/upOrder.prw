#Include 'Protheus.ch'
#Include "Tbiconn.ch"
#include "TOPCONN.CH"

/**************************************************************************************************
{Protheus.doc} upOrder -- treatment to change loja701 to mata410 - Pedido de Venda
@param			_cMsg, String, Mensagem de retorno de json
@param			_aCabec, Array, Cabecalho
@param			_aItens, Array, Itens
@param			_aPagmt, Array, Pagamentos
@return		    Logico
*****************************************************************************************************/
User Function upNewOrder( _aCabec, _aItens,_aPagmt,_cMsgApi, _cAction )

    Local _aArea        := GetArea()
    Local _aNewCabec    := {}
    Local _aNewItens    := {}
    Local _aNewPagmt    := {}
    Local _cDoc         := ""
    Local _lReturn		:= .F.
    Local oJson        := JsonObject():New()
    PRIVATE lMsErroAuto := .F.


    DbSelectArea("SC5")



    xHeadOrder(@_aNewCabec, _aCabec, _cDoc)
    xItenOrder(@_aNewItens, _aItens)
    //Implementar pagamentos

    _lReturn := xExecOrder(_aNewItens, _aNewCabec, @_cMsgApi, _cAction)
    oJson:FromJson(_cMsgApi)
    varinfo("Retorno da execucao do pedido -> oJson", oJson)
    if _lReturn .and. !Empty(oJson['numero'])
        xPagmtOrder(@_aNewPagmt, _aPagmt, oJson['numero']) // passando o numero do pedido
        // _lReturn := .T.>
    else
        _lReturn := .F.
        u_PlenMsg("Erro na criacao do pedido", "upNewOrder", "upVendas")
    endif
    SC5->(DbCloseArea())

    RestArea(_aArea)

Return _lReturn
Static Function xExecOrder(_aNewItens, _aNewCabec, _cMsgApi, _cAction)

    MsExecAuto({|x, y, z| MATA410(x, y, z)}, _aNewCabec, _aNewItens, _cAction)

    If !lMsErroAuto
        _cMsgApi += ' { '
        _cMsgApi += '"status":"ok"'                                   +','+ CRLF
        _cMsgApi += '"msg":"Sucesso na execusao do ExecAuto MATA410"' +','+ CRLF
        _cMsgApi += '"numero":"'+AllTrim(SC5->C5_NUM)+'"'             +','+ CRLF
        _cMsgApi += '"filial":"'+AllTrim(SC5->C5_FILIAL)+'"'          + CRLF
        _cMsgApi += ' } '
        Return(.T.)
    Else
        _cMsgApi := MostraErro("P:\Totvs\Protheus12\Data\Protheus_Data_Ofc\erros", "error.log")
        Varinfo("Erro na execusao do ExecAuto MATA410", _cMsgApi)
        Return(.F.)
    EndIf

Return
Static Function xHeadOrder(_aNewCabec, _aCabec, _cDoc)

    Local _nJ := 0
    Aadd(_aNewCabec,{"C5_TIPO",     "N",        Nil}) //TIPO
    // Aadd(_aNewCabec,{"C5_CONDPAG",  "330",      Nil}) //CONDICAO DE PAGAMENTO -- CONDICAO DO TIPO A
    Aadd(_aNewCabec,{"C5_EMISSAO",  dDataBase,  Nil}) //DATA DE EMISSAO
    varinfo("Dados do cabe�alho -> _aCabec", _aCabec)
    For _nJ := 1 To Len(_aCabec)
        if lower(_aCabec[_nJ][1]) == lower("filial")
            Aadd(_aNewCabec,{"C5_FILIAL",   _aCabec[_nJ][2],    Nil}) //FILIAL
            cFilAnt := _aCabec[_nJ][2]
            Aadd(_aNewCabec,{"C5_NUM",      xNumOrder(_cDoc, _aCabec[_nJ][2]),      Nil}) //NUM PEDIDO
        elseif lower(_aCabec[_nJ][1]) == lower("uuid")
            Aadd(_aNewCabec,{"C5_UUID",     _aCabec[_nJ][2],    Nil}) //UUID
        elseif lower(_aCabec[_nJ][1]) == lower("codigoCliente")
            Aadd(_aNewCabec,{"C5_CLIENTE",  substr(_aCabec[_nJ][2],1,6),    Nil}) //CLIENTE
            Aadd(_aNewCabec,{"C5_LOJA",     substr(_aCabec[_nJ][2],7,2),    Nil}) //LOJA
        elseif lower(_aCabec[_nJ][1]) == lower("vendedor")
            Aadd(_aNewCabec,{"C5_VEND1",   _aCabec[_nJ][2],    Nil}) //VENDEDOR
        ElseIf lower(_aCabec[_nJ][1]) == lower("tipoCliente")
            aAdd(_aNewCabec,{"C5_TIPOCLI",  _aCabec[_nJ][2],       Nil}) //tipo cliente
        ElseIf lower(_aCabec[_nJ][1]) == lower("pagamento")
            aAdd(_aNewCabec,{"C5_CONDPAG",  _aCabec[_nJ][2],       Nil}) //tipo cliente
        ElseIf lower(_aCabec[_nJ][1]) == lower("frete")
            aAdd(_aNewCabec,{"C5_TPFRETE",  _aCabec[_nJ][2],       Nil}) //tipo cliente
        endif
    next nX
    // Fields Default
    aAdd(_aNewCabec,{"C5_NATUREZ",  '0101',       Nil}) //tipo cliente


Return
Static Function xItenOrder(_aNewItens, _aItens)

    Local _aTreatItns := {}
    Local _nX := 0
    Local _nG := 0
    Local Quantidade := Preco := 0

    For _nX := 1 To Len(_aItens)

        _aTreatItns := {}
        varinfo("Dados dos produtos -> _aItens", _aItens)
        For _nG := 1 To len(_aItens[_nX]) // traduzir os campos para os campos do mata410
            if lower(_aItens[_nX][_nG][1]) == lower("codigoProduto")
                aAdd( _aTreatItns, {"C6_PRODUTO", _aItens[_nX][_nG][2] , NIL} )
            elseif lower(_aItens[_nX][_nG][1]) == lower("qtdVendida")
                aAdd( _aTreatItns, {"C6_QUANT",   _aItens[_nX][_nG][2] , NIL} )
                aAdd( _aTreatItns, {"C6_QTDVEN",   _aItens[_nX][_nG][2] , NIL} )
                Quantidade := _aItens[_nX][_nG][2]
            elseif lower(_aItens[_nX][_nG][1]) == lower("precoUnitario")
                aAdd( _aTreatItns, {"C6_VLRUNIT", _aItens[_nX][_nG][2] , NIL} )
                aAdd( _aTreatItns, {"C6_PRCVEN", _aItens[_nX][_nG][2] , NIL} )
                aAdd( _aTreatItns, {"C6_PRUNIT", _aItens[_nX][_nG][2] , NIL} )
                Preco := _aItens[_nX][_nG][2]
            endif
        Next _nG
        aAdd( _aTreatItns, {"C6_VALOR",   Quantidade * Preco , NIL} )
        aAdd( _aTreatItns, {"C6_TES",   '501', NIL} )

        aadd(_aNewItens,_aTreatItns)

    Next _nX

Return

Static Function xPagmtOrder(_aNewPgto, _aPgto, _nPedido)
    // Record lines in ZZG
    Local _nX :=  _nG   := 0
    Local _aTreatPgto   := {}
    Local _nValor       := 0
    Local _cForma       := ""
    Local _nParcelas    := ""
    Local _dVencre      := dDataBase

    For _nX := 1 to len(_aPgto)
        _aTreatPgto := {}
        For _nG := 1 To len(_aPgto[_nX]) // traduzir os campos para os campos do mata410
            if lower(_aPgto[_nX][_nG][1]) == lower("valor")
                _nValor := _aPgto[_nX][_nG][2]
            elseif lower(_aPgto[_nX][_nG][1]) == lower("forma")
                _cForma := _aPgto[_nX][_nG][2]
            elseif lower(_aPgto[_nX][_nG][1]) == lower("vencimento")
                _dVencre := ctod(_aPgto[_nX][_nG][2])
            elseif lower(_aPgto[_nX][_nG][1]) == lower("parcelas")
                _nParcelas := _aPgto[_nX][_nG][2]
            endif
        Next _nG

        varInfo("Dados de Pagamento -> _aPgto",   _aPgto[_nX])
        DBSelectArea("ZZG")
        Reclock("ZZG",.T.)
        ZZG_FILIAL := xFilial("ZZG")
        ZZG_EMP    := cEmpAnt
        ZZG_FILORI := cFilAnt
        ZZG_TIPO   := _cForma
        ZZG_PARCEL := StrZero(_nG, TamSx3("ZZG_PARCEL")[1])
        ZZG_VENCRE := _dVencre
        ZZG_VALOR  := _nValor
        ZZG_PEDIDO := _nPedido
        ZZG->(MsUNlock())

    next _nX

Return

Static Function xNumOrder(_cDoc, __xFilial)
    _cDoc := GetSXENum("SC5","C5_NUM")
    SC5->(dbSetOrder(1))
    // xHeadOrder/C5_FILIAL, C5_NUM)
    While SC5->(dbSeek(__xFilial+_cDoc))
        ConfirmSX8()
        _cDoc := GetSXENum("SC5","C5_NUM")
    EndDo
Return _cDoc
