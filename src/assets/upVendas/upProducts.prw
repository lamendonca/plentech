
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE 'TOPCONN.CH'

#Include "protheus.ch"
#Include "totvs.ch"
#Include "tbiconn.ch"
#Include "json.ch"

/* Plentech */
// upProducts.prw - File auxiliar to get products from Protheus

// Surely your goodness and faithfulness will pursue me all my days - Psalm 23:6
User Function upProducts(_cProduto, isDetailed, PageSize, PageNumber)

    Local cQuery := ""
    Local cAlias := GetNextAlias()
    Local cTotal := GetNextAlias()
    Local cJson
    Local cMsgApi := ""
    Local totalRecords := 0
    Default isDetailed := .T.


    cQueryTotal := " SELECT                                 " + CRLF
    cQueryTotal += " COUNT(*) AS TOTALRECORDS               " + CRLF
    cQueryTotal += " FROM                                   " + CRLF
    cQueryTotal += " 	" + RetSQLName("SB1") + " B1       " + CRLF
    cQueryTotal += " 	INNER JOIN " + RetSQLName("SBM") + " BM ON BM.D_E_L_E_T_!='*' AND BM_GRUPO = B1_GRUPO " + CRLF
    cQueryTotal += " WHERE                                  " + CRLF
    cQueryTotal += "  B1.D_E_L_E_T_ = ''                    " + CRLF
    if isDetailed
        cQueryTotal += " AND (B1.B1_COD LIKE '%"+Alltrim(_cProduto)+"%'          " + CRLF
        cQueryTotal += " or B1.B1_DESC LIKE '%"+Alltrim(_cProduto)+"%' )         " + CRLF
    endif
    cQueryTotal := ChangeQuery(cQueryTotal)
    TcQuery cQueryTotal New Alias (cTotal)

    cQuery := " SELECT                                 " + CRLF
    cQuery += " B1_COD CODIGO,                         " + CRLF
    cQuery += " B1_DESC DESCRICAO,                     " + CRLF
    cQuery += " B1_UM UNIDADEMEDIDA,                   " + CRLF
    cQuery += " BM_DESC GRUPO,                         " + CRLF
    cQuery += " B1_PESO PESO,                          " + CRLF
    cQuery += " 1 VOLUME,                              " + CRLF
    cQuery += " B1_CODBAR CODIGODEBARRAS,              " + CRLF
    cQuery += " B1_PRV1 PRECO                          " + CRLF
    cQuery += " FROM                                   " + CRLF
    cQuery += " 	" + RetSQLName("SB1") + " B1       " + CRLF
    cQuery += " 	INNER JOIN " + RetSQLName("SBM") + " BM ON BM.D_E_L_E_T_!='*' AND BM_GRUPO = B1_GRUPO " + CRLF
    cQuery += " WHERE                                  " + CRLF
    cQuery += "  B1.D_E_L_E_T_ = ''                    " + CRLF
    if isDetailed
        cQuery += " AND (B1.B1_COD LIKE '%"+Alltrim(_cProduto)+"%'          " + CRLF
        cQuery += " or B1.B1_DESC LIKE '%"+Alltrim(_cProduto)+"%' )         " + CRLF
    endif
    if !Empty(PageNumber) .and. !Empty(PageSize)
        cQuery += " ORDER BY B1.R_E_C_N_O_ ASC "
        cQuery += " OFFSET ("+cvaltochar(PageNumber)+" - 1) * "+cvaltochar(PageSize)+" ROWS "
        cQuery += " FETCH NEXT "+cvaltochar(PageSize)+" ROWS ONLY "
    endif
    cQuery := ChangeQuery(cQuery)
    TcQuery cQuery New Alias (cAlias)

    If Empty((cAlias)->DESCRICAO)
        cMsgApi := {"Nenhum dado para ser consultado",.f.}
        u_PlenMsg(cMsgApi[1], "upProducts", "Product")
    Else
        totalRecords := (cTotal)->TOTALRECORDS

        cJson := jsonProduto(cAlias, isDetailed, pageSize, PageNumber, totalRecords)
        u_PlenMsg("Consulta realizada com sucesso!", "upProducts", "Product")
        cMsgApi := cJson
    EndIf

    (cAlias)->(DbCloseArea())
Return(cMsgApi)

Static Function jsonProduto(cAlias, isDetailed, pageSize, pageNumber, totalRecords)
    Local oProduct := JsonObject():New()
    Local oProducts := JsonObject():New()
    Local aProducts := {}
    Local lRet := .F.
    Default isDetailed := .T.

    oProducts["Page"] := Iif(Empty(pageNumber), 1, Val(pageNumber))
    oProducts["PageSize"] := Iif(Empty(pageSize), 1, Val(pageSize))
    oProducts["TotalRecords"] := totalRecords
    While (cAlias)->( !Eof() )
        oProduct := JsonObject():New()
        oProduct["productCode"]        := Alltrim((cAlias)->CODIGO)
        oProduct["productDescription"]        := Alltrim((cAlias)->DESCRICAO)
        oProduct["unit"]                 := (cAlias)->UNIDADEMEDIDA
        oProduct["productGroup"]          := Alltrim((cAlias)->GRUPO)
        oProduct["barcode"]          := Alltrim((cAlias)->CODIGODEBARRAS)
        if isDetailed
            oProduct["price"]                   := xGetPrice((cAlias)->CODIGO,(cAlias)->PRECO)
            oProduct["weight"]                    := (cAlias)->PESO
            oProduct["volume"]                  := (cAlias)->VOLUME
            oProduct["stock"]                 := xGetStock(Alltrim((cAlias)->CODIGO))
        endif
        aAdd(aProducts, oProduct)
        (cAlias)->(DbSkip())

        lRet := .t.

    EndDo
    oProducts["items"] := aProducts


Return {oProducts:toJson(),lRet}

/*/{Protheus.doc} xGetPrice - Function used to get price based on price table /*/
Static Function xGetPrice(Codigo, PrecoTabela)
    Local nReturn := 0
    Local TabPrice := SuperGetMV("PL_TABPRICE",.f., '01') // Default price table 1

    If TabPrice == "01"
        nReturn := PrecoTabela // Get always price from field B1_PRV1
    Else
        nReturn := PrecoTabela // Here you can implement a more complex logic to get price based on the price table
    endif
Return nReturn

/*/{Protheus.doc} xGetStock - function used to get detailed stock from product/*/
Static Function xGetStock( cProduto, cLocal )
    Local nEstoque := 0
    If Empty(cLocal)
        cLocal := "01" // Default local
    endif
    DBSelectArea("SB2")
    SB2->(DbSetOrder(1))
    SB2->(DBSeek(cProduto + cLocal)) // Product + Local

    If SB2->(Found())
        nEstoque := SB2->B2_QATU
    EndIf
    SB1->(DbCloseArea() )
Return nEstoque
