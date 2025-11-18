#Include "PROTHEUS.CH"
#INCLUDE "topconn.ch"

#DEFINE CRLF CHR( 13 ) + CHR( 10 )


/* Plentech */
// PLFATAUT.prw - Create a invoice automatically and send to B4YouLog REST API
// Fonte: https://tdn.totvs.com/pages/releaseview.action?pageId=578374528
// Surely your goodness and faithfulness will pursue me all my days - Psalm 23:6



User Function xFatAut

    Local _cEmp         := "AC"     // Company code - Check your company code in SM0->M0_CODIGO
    Local _cFil         := "020003"   // Sucursal code - Check your filial code in SM0->M0_CODFIL

    If Select("SX2") == 0
        RpcSetEnv(_cEmp, _cFil,NIL, NIL, "FAT")
    EndIf
    u_PLFATAUT()

    RpcClearEnv()
return


User Function PLFATAUT()
    Local aData     := { }
    Local nX        := 0
    Local cDoc      := ""
    Local cStatus   := SuperGetMV("PL_B4UAUTH", .f., "AGUARDANDO_NF_PARA_EXPEDICAO") // This status able the order to be invoiced
    Private Rows    := SuperGetMv("PL_B4UROW", .f., 100)                // Number of rows to be processed in each table
    Private lJob    := FwGetRunSchedule()
    u_PlenMsg( "Carregando os dados para serem atualizados. " + Dtoc( Date( ) ) )

    aData  := xDados( "SC5", Rows, " C5_NOTA =' ' AND C5_XB4USTA ='"+cStatus+"' " )

    if !Empty( aData )
        For nX := 1 to len(aData)
            u_PlenMsg( "Processando a tabela: " + aData[nX][1] + " - Registro: " + aData[nX][2] , "PLFATAUT", "B4U" )
            cDoc := fatAut( aData[nX][2] )
            if len(cDoc) == 9
                u_PlenMsg("Pedido: " + aData[nX][2] + " faturado com o documento: " + cDoc, "PLFATAUT", "B4U")
            else
                u_PlenMsg("Erro ao faturar o pedido: " + aData[nX][2] + " -- Erro: "+ cDoc, "PLFATAUT", "B4U")
            EndIf
        Next nX
    else
        u_PlenMsg( "Não houve dados para serem atualizados.  Dia: " + Dtoc( Date( ) ) )
    EndIf


Return Nil

Static Function xDados( Table, Rows, Extra )
    Local aDados := {}
    Local cAlias := GetNextAlias( )
    Default Extra := ""

    TcQuery xQuery( Table, Rows, Extra ) New Alias (cAlias)

    while  (cAlias)->( !EOF( ) )
        aAdd(aDados, {Table, (cAlias)->(C5_FILIAL+C5_NUM)})
        (cAlias)->( DBSkip( ) )
    end
    (cAlias)->( DbCloseArea( ) )
Return aDados

Static Function xQuery( Table, Rows, Extra )
    Local cQuery := ""
    Default Extra := ""

    cQuery += "     SELECT "  /*TOP "+cValToChar(Rows)+*/  // REMOVED BECAUSE THIS DATABASE IS ORACLE AND THIS NOT WORKS
    cQuery += " *  " + CRLF
    cQuery += "         FROM "+RetSQLName(Table)+ CRLF
    cQuery += "     WHERE D_E_L_E_T_!='*' AND  " + CRLF
    IF Empty(Extra)
        cQuery += "     "+Iif(Substr(Table,1,1)='S', Substr(Table,2,2) , Table )+"_XB4U in (' ','1', 'X' )  "+  CRLF
    else
        cQuery += "     "+Extra+"  "+  CRLF
    endif
Return ChangeQuery(cQuery)

Static Function fatAut( cOrder )
    Local aArea     := GetArea()
    Local cDoc      := ""
    Local cSerie    := SuperGetMV("PL_SERIE", .f., "1") // Serie to be used in the invoice
    Local aPvlDocS  := {}
    Local nPrcVen   := 0
    Local cEmbExp := ""


    // Opening necessary tables //////
    DBSelectArea("SC5")
    SC5->(DbSetOrder(1))
    SC5->(DbGoTop())
    SC5->(DBSeek( cOrder )) // Filial + Pedido

    if !SC5->(Found()) // Validate if the order exists
        u_PlenMsg("Pedido não encontrado: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Pedido não encontrado: " + cOrder
    endif

    DBSelectArea("SC6")
    SC6->(DbSetOrder(1))
    SC6->(DbGoTop())
    SC6->(DBSeek( cOrder ))

    if !SC6->(Found()) // Validate if the order has items
        u_PlenMsg("Pedido sem itens: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Pedido sem itens: " + cOrder
    Endif

    DbSelectArea("SC9")
    SC9->(DbSetOrder(1))
    SC9->(DbGoTop())
    SC9->(DBSeek( cOrder )) // Filial + Pedido

    if !SC9->(Found()) // Validate if the order has items in SC9
        u_PlenMsg("Pedido sem itens na SC9: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Pedido sem itens na SC9: " + cOrder
    endif

    DBSelectArea("SE4")
    SE4->(DbSetOrder(1))
    SE4->(DbGoTop())
    SE4->(DBSeek(xFilial("SE4")+SC5->C5_CONDPAG) )  //FILIAL+CONDICAO PAGTO

    if !SE4->(Found()) // Validate if the payment condition exists
        u_PlenMsg("Condição de pagamento não encontrada: " + SC5->C5_CONDPAG + " do pedido: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Condição de pagamento não encontrada: " + SC5->C5_CONDPAG + " do pedido: " + cOrder
    Endif

    DBSelectArea("SA1")
    SA1->(DbSetOrder(1))
    SA1->(DbGoTop())
    SA1->(DBSeek(xFilial("SA1")+ SC5->(C5_CLIENTE+C5_LOJACLI) ))

    if !SA1->(Found()) // Validate if the customer exists
        u_PlenMsg("Cliente não encontrado: " + SC5->(C5_CLIENTE+C5_LOJACLI) + " do pedido: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Cliente não encontrado: " + SC5->(C5_CLIENTE+C5_LOJACLI) + " do pedido: " + cOrder
    Endif

    DBSelectArea("SB1")
    SB1->(DbSetOrder(1))
    SB1->(DbGoTop())
    SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))    //FILIAL+PRODUTO
    if !SB1->(Found()) // Validate if the product exists
        u_PlenMsg("Produto não encontrado: " + SC6->C6_PRODUTO + " do pedido: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Produto não encontrado: " + SC6->C6_PRODUTO + " do pedido: " + cOrder
    Endif

    DBSelectArea("SB2")
    SB2->(DbSetOrder(1))
    SB2->(DbGoTop())
    SB2->(MsSeek(xFilial("SB2")+SC6->(C6_PRODUTO+C6_LOCAL))) //FILIAL+PRODUTO+LOCAL
    if !SB2->(Found()) // Validate if the product stock exists
        u_PlenMsg("Estoque do produto não encontrado: " + SC6->C6_PRODUTO + " Local: " + SC6->C6_LOCAL + " do pedido: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Estoque do produto não encontrado: " + SC6->C6_PRODUTO + " Local: " + SC6->C6_LOCAL + " do pedido: " + cOrder
    Endif

    DBSelectArea("SF4")
    SF4->(DbSetOrder(1))
    SF4->(DbGoTop())
    SF4->(MsSeek(xFilial("SF4")+SC6->C6_TES))   //FILIAL+TES
    if !SF4->(Found()) // Validate if the TES exists
        u_PlenMsg("TES não encontrada: " + SC6->C6_TES + " do pedido: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "TES não encontrada: " + SC6->C6_TES + " do pedido: " + cOrder
    Endif
    //////////////////////////////////

    // Confirm if the order is in the correct status to be invoiced
    Pergunte("MT460A",.F.)

    // Collecting items to be invoiced
    While SC6->(!Eof() .And. C6_FILIAL == xFilial("SC6")) .And. SC6->C6_NUM == SC5->C5_NUM

        SB1->(MsSeek(xFilial("SB1")+SC6->C6_PRODUTO))    //FILIAL+PRODUTO
        SB2->(MsSeek(xFilial("SB2")+SC6->(C6_PRODUTO+C6_LOCAL))) //FILIAL+PRODUTO+LOCAL
        SF4->(MsSeek(xFilial("SF4")+SC6->C6_TES))   //FILIAL+TES

        nPrcVen := SC9->C9_PRCVEN
        If ( SC5->C5_MOEDA <> 1 )
            nPrcVen := xMoeda(nPrcVen,SC5->C5_MOEDA,1,dDataBase)
        EndIf

        If AllTrim(SC9->C9_BLEST) == "" .And. AllTrim(SC9->C9_BLCRED) == "" //TODO: corrigir aqui
            AAdd(aPvlDocS,{ SC9->C9_PEDIDO,;
                SC9->C9_ITEM,;
                SC9->C9_SEQUEN,;
                SC9->C9_QTDLIB,;
                nPrcVen,;
                SC9->C9_PRODUTO,;
                .F.,;
                SC9->(RecNo()),;
                SC5->(RecNo()),;
                SC6->(RecNo()),;
                SE4->(RecNo()),;
                SB1->(RecNo()),;
                SB2->(RecNo()),;
                SF4->(RecNo())})
        EndIf

        SC6->(DbSkip())
    EndDo

    SetFunName("MATA461")
    if Empty(aPvlDocS)
        u_PlenMsg("Pedido sem itens válidos para faturamento: " + cOrder, "PLFATAUT", "B4U")
        restarea(aArea)
        return "Pedido sem itens válidos para faturamento: " + cOrder
    Endif
    cDoc := MaPvlNfs(  /*aPvlNfs*/         aPvlDocS,;  // 01 - Array com os itens a serem gerados
        /*cSerieNFS*/       cSerie,;    // 02 - Serie da Nota Fiscal
        /*lMostraCtb*/      .F.,;       // 03 - Mostra Lançamento Contábil
        /*lAglutCtb*/       .F.,;       // 04 - Aglutina Lançamento Contábil
        /*lCtbOnLine*/      .F.,;       // 05 - Contabiliza On-Line
        /*lCtbCusto*/       .F.,;       // 06 - Contabiliza Custo On-Line
        /*lReajuste*/       .F.,;       // 07 - Reajuste de preço na Nota Fiscal
        /*nCalAcrs*/        0,;         // 08 - Tipo de Acréscimo Financeiro
        /*nArredPrcLis*/    0,;         // 09 - Tipo de Arredondamento
        /*lAtuSA7*/         .T.,;       // 10 - Atualiza Amarração Cliente x Produto
        /*lECF*/            .F.,;       // 11 - Cupom Fiscal
        /*cEmbExp*/         cEmbExp,;   // 12 - Número do Embarque de Exportação
        /*bAtuFin*/         {||},;      // 13 - Bloco de Código para complemento de atualização dos títulos financeiros. É executado com a função Eval recebendo recno da SE1. Ex:bAtuFin:={|nRecSe1|U_RecSe1(nRecSe1)}
        /*bAtuPGerNF*/      {||},;      // 14 - Bloco de Código para complemento de atualização dos dados após a geração da Nota Fiscal
        /*bAtuPvl*/         {||},;      // 15 - Bloco de Código de atualização do Pedido de Venda antes da geração da Nota Fiscal
        /*bFatSE1*/         {|| .T. },; // 16 - Bloco de Código para indicar se o valor do Titulo a Receber será gravado no campo F2_VALFAT quando o parâmetro MV_TMSMFAT estiver com o valor igual a "2".
        /*dDataMoe*/        dDatabase,; // 17 - Data da cotação para conversão dos valores da Moeda do Pedido de Venda para a Moeda Forte
        /*lJunta*/          .F.)        // 18 - Aglutina Pedido Iguais

    If !Empty(cDoc)
        u_PlenMsg("Documento de Saída: " + cSerie + "-" + cDoc + ", gerado com sucesso!!!", "PLFATAUT", "B4U")
        Reclock("SC5",.F.)
        SC5->C5_NOTA := cDoc
        SC5->C5_SERIE := cSerie
        SC5->(MSUnlock())
    Else
        u_PlenMsg("Erro ao gerar o documento de saída para o pedido: " + cOrder, "PLFATAUT", "B4U")
        cDoc := "Erro ao gerar o documento de saída para o pedido: " + cOrder
    EndIf

Return cDoc

Static Function Scheddef()
    Local aParam := {}
    aParam := {;
        /*Tipo R para relatorio P para processo*/               "P"    , ;
        /*Pergunte do relatorio, caso nao use passar ParamDef*/ ""     , ;
        /*Alias*/                                               ""     , ;
        /*Array de ordens*/                                     {}     , ;
        }
Return aParam
