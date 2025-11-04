#Include "protheus.ch"
#Include "totvs.ch"
#Include "tbiconn.ch"
#Include "json.ch"
// #Include "fwrest.ch"

#INCLUDE 'TOPCONN.CH'


/* Plentech */
// B4U.prw - REST API with FWRest class
// This file contains functions to connect to a REST API, send requests, and handle responses.
// It includes methods for connecting to a sample REST API, sending a POST request to B4YouLog API,
// creating a product, canceling an order, and sending XML/JSON data.

// Surely your goodness and faithfulness will pursue me all my days - Psalm 23:6

// PL_RSTURL                := URL to the REST API
// PL_REST_BEARER           := Bearer token for REST API authentication
// PL_LOG                   := Enable or disable logging (default: true)
// PL_B4UTABLE              := Tables to be used in the B4U integration (default: { "SB1", "SC5" })
// PL_B4UFLD                := Path to store invoices related to B4U integration (default: "\b4u\invoices\")

// Fields needed in the database:
// SC5 - Orders
// C5_XB4U - C - Tam 1      := Field to mark orders to be sent to B4U (S = Yes; C= Canceled; 1= Priority to send; blank = Not sent)
// C5_XB4UJSO - Memo        := Field to store the JSON sent to B4U

// SB1 - Products
// B1_XB4U - C - Tam 1      := Field to mark products to be sent to B4U (S = Yes; C= Canceled; 1= Priority to send; blank = Not sent)
// B1_XB4UJSO - Memo        := Field to store the JSON sent to B4U

//Fields to validate use in the API
// SC5 - Orders
// DataFaturamento          := Field to store the billing date
// TipoCanalVenda           := Field to store the sales channel type
// TipoDePedido             := Field to store the order type

// SC6 - Order Items
// NumeroRomaneio           := Field to store the shipping number

// SB1 - Products
// CodigoMontador           := Field to store the assembler code
// ControlaNumeroDeSerie    := Field to indicate if the product controls serial numbers (S/N)


// Things to improve:
// -[x] Change a method to do a connection to the API - FwRest to Httpquote and HTTPGet
// -[ ] Create a Order
//      [x] Create a field to log a status of the order (sent, error, etc)
//      [x] Create a field to log the response from the API (order number, error message, etc)
//      [X] Improve the snippet to flag the status of the order and the JSON sent
//      [ ] Return of Post not working properly - check the return of the Httpquote
//      [ ] Improve the snippet to found a delivery number and tracking code
// -[x] Create a Product
//     [x] Create a field to log a status of the product (created, error, etc)
//     [x] Create a field to log the response from the API (product ID, error message, etc)
//     [x] Improve the snippet to flag the status of the order and the JSON sent
// -[-] Cancel a Order
//      [ ] Not able to do
// -[X] Send XML/JSON data
//      [x] Build a function to find the XML of the NF to send via API
//      [x] Create a field to log a status of the XML/JSON (sent, error, etc)
// -[x] Create e webhook to receive updates from B4YouLog API (order status, tracking number, etc)
// -[x] Do a treatment to getarea and restarea to be able to change de pointer
// -[ ] Change the httppost to httpquote to use others methods (PUT, DELETE, etc) https://tdn.totvs.com/display/tec/HTTPSQuote
//      - [ ] Validate if works




User Function xTestB4U(_Method, _Order)

    Local _cEmp         := "AC"     // Company code - Check your company code in SM0->M0_CODIGO
    Local _cFil         := "020003"   // Sucursal code - Check your filial code in SM0->M0_CODFIL
    Default _Method     := "GetOrder"  // Default method to test
    Default _Order      := "020003000104" // Default order number to test

    If Select("SX2") == 0
        RpcSetEnv(_cEmp, _cFil,NIL, NIL, "FAT")
    EndIf
    if lower(_Method) == lower("Product")
        CreateB4YouLogProduct( "030625" )// Test product creation
    elseif lower(_Method) == lower("Order")
        ConnectB4YouLogOrder(_Order)              // Test order creation
    elseif lower(_Method) == lower("Cancel")
        CancelB4YouLogOrder(_Order)               // Test order cancellation
    elseif lower(_Method) == lower("SendXmlJson")
        SendB4YouLogPedidoXmlJson(_Order) // Test sending XML/JSON data
    elseif lower(_Method) == lower("GetOrder")
        GetOrderB4U(_Order) // Test sending XML/JSON data
    else
        u_PlenMsg("Método inválido: " + _Method, "xTestB4U")
    endif
    RpcClearEnv()
return

User Function integB4U( _Method, aInfo )
    Local aData := {}
    if _Method == "Product"
        CreateB4YouLogProduct( aInfo )
    elseif _Method == "Order"
        ConnectB4YouLogOrder( aInfo )
    elseif _Method == "Cancel"
        CancelB4YouLogOrder( aInfo )
    elseif _Method == "SendXmlJson"
        SendB4YouLogPedidoXmlJson( aInfo )
    elseif _Method == "GetOrder"
        aData := GetOrderB4U( aInfo )
    elseif _Method == "SendPurchases"
        sendPurchasesOrderB4U( aInfo )
    else
        u_PlenMsg("Método inválido: " + _Method, "integB4U")
    endif
Return aData 


// Static Function to set credentials for REST API -- Bearer Token of Sandbox
Static Function SetRestBearer()
    Local cBearer   := SuperGetMV("PL_RSTBEAR",   .F.,    "T0xGQToybXk2ZXFjeGlhOHQ0cGI5MWxzNWR3aG8=")
    Local cUrl      := SuperGetMV("PL_RSTURL",        .f.,    "https://sandbox-api.b4youlog.com/v1")
    Local _aHeader  := {}
    AAdd(_aHeader, 'Content-Type: application/json; charset=utf-8')
    AAdd(_aHeader, 'Authorization: Bearer ' + cBearer  )

Return {_aHeader, cUrl }

Static Function sendPurchasesOrderB4U(_PurchasesOrder)
    Local lReturn := .F.
    Local cUrl      := "/recebimento/xml-fornecedor" // https://api.b4youlog.com/v1/recebimento/xml-fornecedor?Usuario=&ChaveNFeFornecedor=
    Local oJSONRet  := Nil
    Local cHeaderGet:= ""
    Local aInfo     := '{"xmlNFe":"<xml>...</xml>","usuario":"usuario_teste","chaveNFeFornecedor":"12345678901234567890123456789012345678901234"}' // Example JSON payload

    DBSelectArea("SF1")
    SF1->(DbSetOrder(1))
    SF1->(DBSeek( _PurchasesOrder ))

    if SF1->(FOUND())
        aInfo := '{"usuario":"'+SuperGetMV("PL_B4UUSER", .f., "Schedule")+'","chaveNFeFornecedor":"'+AllTrim(SF1->F1_CHVNFE)+'"}'
        FWJsonDeserialize(Httpquote(  ;
            /*url*/ SetRestBearer()[2]+cUrl ,;
            /* Method*/ 'POST',;
            /* cGetParms */ ,;
            /* cPostParms */ aInfo ,;
            /* nTimeOut */80,;
            /* aHeadrStr */ SetRestBearer()[1],;
            /* cHeaderGet */ @cHeaderGet  ), @oJSONRet)
        if Val(SubStr(strtokarr(cHeaderGet, Chr(10))[1], 10, 3)) == 200 // Check if the HTTP status code is 200 OK
            u_PlenMsg( "Httpquote OK - Pedido retornado: " + aInfo, "sendPurchasesOrderB4U" ) // Log success message
            lReturn    := .t.
            SF1->(RecLock(.F.))
            SF1->F1_XB4URET := oJSONRet:Mensagem
            SF1->(MSUnlock())

        else
            u_PlenMsg("Erro Httpquote: " + aInfo , "sendPurchasesOrderB4U")
        EndIf
    EndIf

Return lReturn
Static Function GetOrderB4U(_Order)

    Local cUrl      := "/pedido?numeroPedido=" //https://api.b4youlog.com/v1/pedido?numeroPedido=numeroDoPedido
    Local oJSONRet  := Nil
    Local lRet      := .F. // Return value
    Local cHeaderGet:= ""
    Local aReturn   := {}
    FWJsonDeserialize(Httpquote(  ;
        /*url*/ SetRestBearer()[2]+cUrl+_Order ,;
        /* Method*/ 'GET',;
        /* cGetParms */ ,;
        /* cPostParms */ ,;
        /* nTimeOut */80,;
        /* aHeadrStr */ SetRestBearer()[1],;
        /* cHeaderGet */ @cHeaderGet  ), @oJSONRet)
    if Val(SubStr(strtokarr(cHeaderGet, Chr(10))[1], 10, 3)) == 200 // Check if the HTTP status code is 200 OK
        u_PlenMsg( "Httpquote OK - Pedido retornado: " + _Order, "GetOrderB4U" ) // Log success message
        lRet    := .t.
        aReturn:= {lRet, {val(ojsonret[1]:dados:pedido:pesototal), val(ojsonret[1]:dados:pedido:totalcaixas)}}
    else
        u_PlenMsg("Erro Httpquote: " + _Order , "GetOrderB4U")
        aReturn:= {lRet, {oJsonRet:Mensagem, 0}}
    EndIf

    varinfo("aReturn GetOrderB4U", aReturn)
return aReturn

// Static function to connect and send a POST request to B4YouLog API
Static Function ConnectB4YouLogOrder(_Order)
    Local cUrl      := "/pedido"
    Local oOrder    := JsonObject():New()
    Local lRet      := .F. // Return value
    Local oJSONRet  := Nil
    Local nItem     := 0
    Local aItens    := {}
    Local cHeaderGet:= ""
    Local _cReturn      := "" // Variable to hold the response from the API
    Local aArea     := GetArea()

    DBSelectArea("SC5")
    SC5->(DbSetOrder(1))
    SC5->(DBSeek( _Order ))

    DBSelectArea("SC6")
    SC6->(DbSetOrder(1))
    SC6->(DBSeek( _Order ))

    DBSelectArea("SA1")
    SA1->(DbSetOrder(1))
    SA1->(DBSeek(xFilial("SA1")+ SC5->(C5_CLIENTE+C5_LOJACLI) ))

    DBSelectArea("SB1")
    SB1->(DbSetOrder(1))


    if SC5->(Found()) .and. ;
            ((SC5->(C5_LIBEROK) == "S" .and. Empty(SC5->(C5_NOTA)) .and. xValidC9B4U( _Order )) .Or. ;
            SC5->C5_XB4U == "1") // Check if order is released and not invoiced and valid to B4U or marked as priority to send


        oOrder["NumeroPedido"]              := SC5->(C5_FILIAL+C5_NUM)
        oOrder["CodigoCliente"]             := SC5->C5_CLIENTE
        if !Empty(SC5->C5_EMISSAO)
            oOrder["DataEmissao"]               := SUBSTRING(DTOS(SC5->C5_EMISSAO),1,4)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),5,2)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),7,2)
        ENDIF
        oOrder["CnpjTransportadora"]        := Posicione("SA4", 1, xFilial("SA4")+SC5->C5_TRANSP, "A4_CGC")
        if !Empty(SC5->(C5_SERIE+C5_NOTA)) .and. !Empty(SC5->C5_EMISSAO)
            oOrder["DataFaturamento"]           := SUBSTRING(DTOS(SC5->C5_EMISSAO),1,4)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),5,2)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),7,2)
        endif
        oOrder["TipoCanalVenda"]            := "4"                  // 1 = CORPORATIVO; 2 = ATACADO; 3 = TELEVENDAS; 4 = SITE; 5 = MARKETPLACE; 7 = LICITACAO
        oOrder["TipoDePedido"]              := "1"                  // 1 = CONSUMIDOR FINAL; 2 = TRANSFERENCIA FULL; 3 = TRANSFERENCIA; 4 = ATACADO; 5 = CORPORATIVO; 6 = LICITACAO; 7 = TROCA
        oOrder["OrdemDeCompra"]             := ""
        oOrder["NumeroPedidoCLiente"]       := ""

        // Clientes
        IF SA1->(Found())
            oOrder["NomeCliente"]           := u_xSemCarc(Alltrim(SA1->A1_NOME))
            oOrder["EnderecoCliente"]       := u_xSemCarc(Alltrim(SA1->A1_END))
            oOrder["BairroCliente"]         := u_xSemCarc(Alltrim(SA1->A1_BAIRRO))
            oOrder["MunicipioCliente"]      := u_xSemCarc(Alltrim(SA1->A1_MUN))
            oOrder["CepCLiente"]            := u_xSemCarc(Alltrim(SA1->A1_CEP))
            oOrder["EstadoCliente"]         := u_xSemCarc(Alltrim(SA1->A1_EST))
            oOrder["CnpjCpfCliente"]        := u_xSemCarc(Alltrim(SA1->A1_CGC))
            oOrder["IeCliente"]             := u_xSemCarc(Alltrim(SA1->A1_INSCR))
        Else
            // If the client is not found, set dummy values to complete the json object
            oOrder["NomeCliente"]           := "Cliente não encontrado"
            oOrder["EnderecoCliente"]       := "Cliente não encontrado"
            oOrder["EstadoCliente"]         := "SP"
            oOrder["CnpjCpfCliente"]        := "00.000.000/0001-91"
            oOrder["IeCliente"]             := "ISENTO"
            oOrder["CepCLiente"]            := "70070-110"
            oOrder["NumeroPedidoCLiente"]   := ""
            oOrder["MunicipioCliente"]      := "São Paulo"
            u_PlenMsg("Cliente não encontrado: " + SC5->(C5_CLIENTE+C5_LOJACLI), "ConnectB4YouLogOrder")
            lRet    := .F.
        ENDIF

        While SC6->(!EOF()) .and. SC6->(C6_FILIAL+C6_NUM) == _Order

            oOrderItens := JsonObject():New() // Array to hold order items
            oOrderItens["NumeroPedido"]     := SC5->(C5_FILIAL+C5_NUM)

            // TODO: REMOVE BEFORE PRODUCTION
            // SB1->(DBSeek(xFilial("SB1") + SC6->C6_PRODUTO )) // Seek product in SB1
            // if SB1->(Found())
            //     if !(SB1->B1_XB4U == "S") // Check if product is marked for B4U
            // If CreateB4YouLogProduct(SC6->C6_PRODUTO) // Re-fetch product details
            //     u_PlenMsg("Produto ainda não havia sido criado: " + SC6->C6_PRODUTO, "ConnectB4YouLogOrder")
            // endif
            // endif
            // else
            // u_PlenMsg("Produto não encontrado: " + SC6->C6_PRODUTO, "ConnectB4YouLogOrder")
            // lRet    := .F.
            // endif
            oOrderItens["CodigoProduto"]            := Alltrim(SC6->C6_PRODUTO)
            oOrderItens["QtdVendida"]               := StrTran(AllTrim(TRANSFORM(SC6->C6_QTDVEN,"@E 99999999.9999")),",",".")
            oOrderItens["PrecoVenda"]               := StrTran(AllTrim(TRANSFORM(SC6->C6_VALOR,"@E 99999999.9999")),",",".")
            oOrderItens["ValorItem"]                := StrTran(AllTrim(TRANSFORM(SC6->C6_PRCVEN,"@E 99999999.9999")),",",".")
            oOrderItens["Almoxarifado"]             := ""
            oOrderItens["SeqItens"]                 := Strzero(Val(SC6->C6_ITEM),3)

            nItem++
            aAdd(aItens, oOrderItens) // Add item to the array
            SC6->(DbSkip())
        Enddo


        oOrder["Produtos"]      := aItens
        oOrder["QtdItenPedido"] := nItem
        u_PlenMsg("Criando pedido: " + _Order + " - "+ SC5->C5_CLIENTE, "ConnectB4YouLogOrder")
        // Httpquote( < cUrl >, < cMethod >, [ cGETParms ], [ cPOSTParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderRet ] )
        _cReturn := FWJsonDeserialize(HttpQuote( ;
            /*url*/ SetRestBearer()[2]+cUrl  ,;
            /* cMethod*/ 'POST',;
            /* GetParms */,;
            /* PostParms */ oOrder:ToJson() ,;
            /* timeout*/ 80 ,;
            /*aHeader*/ SetRestBearer()[1] ,;
            /* cHeaderGet */  @cHeaderGet ) , @oJSONRet)
        if Val(SubStr(strtokarr(cHeaderGet, Chr(10))[1], 10, 3)) == 200 // Check if the HTTP status code is 200 OK
            u_PlenMsg( "Httpquote OK", "Httpquote" ) // Log success message
            // Log the order as sent to B4U
            // if  FieldPos("C5_XB4U") > 0 .and.  FieldPos("C5_XB4UJSO") > 0
            RecLock("SC5", .F.)
            SC5->C5_XB4U     := "S"                         // Mark product as sent to B4U
            // SC5->C5_XB4UJSO  := FwNoAccent(oOrder:ToJson()) // Store JSON sent to B4U
            SC5->(MSUnlock())
            // endif
            lRet    := .t.
        Else
            RecLock("SC5", .F.)
            SC5->C5_XB4U     := "E"                         // Mark product as sent to B4U
            SC5->C5_XB4UJSO  := oJSONRet:Mensagem // Store JSON sent to B4U
            SC5->(MSUnlock())
            u_PlenMsg("Erro Httpquote: " + _Order + " - "+ oOrder:ToJson(), "ConnectB4YouLogOrder")
        EndIf
    else
        u_PlenMsg("Pedido não encontrado: " + _Order, "ConnectB4YouLogOrder")
        lRet    := .f.
    EndIf
    RestArea(aArea)
Return lRet

// Static function to create a Json product
Static Function CreateB4YouLogProduct(_Product)
    Local cUrl          := "/produto"
    Local oProduct      := JsonObject():New()
    Local oJSONRet      := Nil
    Local lRet          := .F. // Return value
    Local cHeaderGet    := ""
    Local aArea         := GetArea()
    DBSelectArea("SB1")
    SB1->(DbSetOrder(1))
    SB1->(DBSeek(xFilial("SB1")+ _Product ))

    if SB1->(Found())
        oProduct["CodigoReferencia"]        := Alltrim(SB1->B1_COD)
        oProduct["Unidade"]                 := SB1->B1_UM
        oProduct["GrupoDeProduto"]          := SB1->B1_GRUPO
        oProduct["DescricaoProduto"]        := Alltrim(SB1->B1_DESC)
        oProduct["Peso"]                    := SB1->B1_PESO
        oProduct["Volume"]                  := Val("1")
        oProduct["CodigoDeBarras"]          := Alltrim(SB1->B1_CODBAR)
        oProduct["AlmoxarifadoPadrao"]      := ""   //Not able to use //StrZero(Val(SB1->B1_LOCPAD),4)
        oProduct["CodigoMontador"]          := ""   // Not able to use
        oProduct["ControlaNumeroDeSerie"]   := "N"

        u_PlenMsg("Criando produto: " + _Product + " - "+ SB1->B1_DESC, "CreateB4YouLogProduct")

        // Deserialize the returned JSON from the API

        // Httpquote( < cUrl >, < cMethod >, [ cGETParms ], [ cPOSTParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderRet ] )
        FWJsonDeserialize(Httpquote(;
            /* url */ SetRestBearer()[2]+cUrl ,;
            /* Method*/'POST',;
            /* cGetParms */ ,;
            /* cPostParms */ '['+oProduct:ToJson()+']',;
            /* nTimeOut */ 80,;
            /* aHeadStr */SetRestBearer()[1],;
            /* cHeaderRet */  @cHeaderGet  ), @oJSONRet)


        if Val(SubStr(strtokarr(cHeaderGet, Chr(10))[1], 10, 3)) == 200 // Check if the HTTP status code is 200 OK
            u_PlenMsg( "Httpquote OK", "Httpquote" ) // Log success message
            //Log the product as sent to B4U
            if  FieldPos("B1_XB4U") > 0 .and.  FieldPos("B1_XB4UJSO") > 0
                RecLock("SB1", .F.)
                SB1->B1_XB4U     := "S" // Mark product as sent to B4U
                SB1->B1_XB4UJSO  := oJSONRet // Store JSON sent to B4U
                SB1->(MSUnlock())
            endif
            lRet    := .t.
        else
            RecLock("SB1", .F.)
            SB1->B1_XB4U     := "E" // Mark product as sent to B4U
            SB1->B1_XB4UJSO  := oJSONRet:Mensagem // Store JSON sent to B4U
            SB1->(MSUnlock())

            u_PlenMsg("Erro Httpquote: " + _Product + " - "+ SB1->B1_DESC, "CreateB4YouLogProduct")
            lRet    := .f.
        endif
    else
        u_PlenMsg("Produto não encontrado: " + _Product, "CreateB4YouLogProduct")
        lRet    := .F.
    endif
    RestArea(aArea)
Return lRet

// Static function to cancel a pedido via B4YouLog API
Static Function CancelB4YouLogOrder(_Order) //Not possible to cancel a order across Httpquote
    Local cUrl          := "/pedido/cancelar"
    Local oOrder        := JsonObject():New()
    Local oJSONRet      := Nil
    Local lRet          := .F. // Return value
    Local cHeaderGet    := ""
    Local aArea         := GetArea()
    DBSelectArea("SC5")
    SC5->(DbSetOrder(1))
    SC5->(DBSeek( _Order))

    if SC5->(Found())
        oOrder["NumeroPedido"]          := SC5->C5_NUM              // Set the order number to cancel
        oOrder["MotivoCancelamento"]    := ""                       // Set the cancellation reason
        oOrder["Usuario"]               := UsrRetName(__cUserId)    // Set the user performing the cancellation

        // Httpquote( < cUrl >, < cMethod >, [ cGETParms ], [ cPOSTParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderRet ] )
        FWJsonDeserialize(Httpquote(  ;
            /*url*/ SetRestBearer()[2]+cUrl ,;
            /* Method*/ 'DELETE',;
            /* cGetParms */ ,;
            /* cPostParms */ oOrder:ToJson(),;
            /* nTimeOut */80,;
            /* aHeadrStr */ SetRestBearer()[1],;
            /* cHeaderGet */ @cHeaderGet  ), @oJSONRet)

        if Val(SubStr(strtokarr(cHeaderGet, Chr(10))[1], 10, 3)) == 200 // Check if the HTTP status code is 200 OK
            u_PlenMsg( "Httpquote OK", "Httpquote" ) // Log success message
            //Log the product as sent to B4U
            if  FieldPos("C5_XB4U") > 0 .and.  FieldPos("C5_XB4UJSO") > 0
                RecLock("SC5", .F.)
                SC5->C5_XB4U     := "C" // Mark product as sent to B4U
                SC5->C5_XB4UJSO  := oOrder:ToJson() // Store JSON sent to B4U
                SC5->(MSUnlock())
            endif
            lRet    := .t.
        else
            RecLock("SC5", .F.)
            SC5->C5_XB4U     := "X" // Mark product as sent to B4U
            SC5->C5_XB4UJSO  := oOrder:ToJson() // Store JSON sent to B4U
            SC5->(MSUnlock())
            u_PlenMsg("Erro Httpquote: " + _oRDER + " - "+ oOrder:toJson(), "CancelB4YouLogOrder")
            lRet    := .f.
        endif

        u_PlenMsg("Cancelando pedido: " + SC5->C5_NUM, "CancelB4YouLogOrder")
        lRet    := .t.
    Else
        u_PlenMsg("Pedido não encontrado: " + _Order, "CancelB4YouLogOrder")
        lRet    := .f.
    EndIf
    RestArea(aArea) // Restore the area to the previous state'
Return lRet

// Static function to send XML/JSON data to B4YouLog API
Static Function SendB4YouLogPedidoXmlJson(_Order)
    Local cUrl          := "/pedido/xml-json"
    Local lRet          := .F. // Return value
    Local oOrder        := JsonObject():New()
    Local oJSONRet      := Nil
    Local cHeaderGet    := ""
    Local aArea         := GetArea() // Save the current area

    DBSelectArea("SC5")
    SC5->(DbSetOrder(1))
    SC5->(DbGoTop())
    SC5->(DBSeek( _Order))
    u_PlenMsg("Enviando pedido XML/JSON: " + _Order, "SendB4YouLogPedidoXmlJson")
    if SC5->(Found())
        DBSelectArea("SF2")
        SF2->(DbSetOrder(1))
        SF2->(DbGoTop())
        u_PlenMsg("Buscando NF para o pedido: " + SC5->(C5_FILIAL+C5_NUM), "SendB4YouLogPedidoXmlJson")
        u_PlenMsg(SC5->(C5_FILIAL+C5_NOTA+C5_SERIE+C5_CLIENTE+C5_LOJACLI), "Chave SF2")
        SF2->(DBSeek(SC5->(C5_FILIAL+C5_NOTA+C5_SERIE+C5_CLIENTE+C5_LOJACLI)))
        if SF2->(Found())
            oOrder["NumeroPedido"]      := SC5->C5_NUM // Set the order number
            oOrder["Xml"]               := _FoundXml( "XML", SC5->C5_SERIE, SC5->C5_NOTA, SC5->C5_CLIENTE, SC5->C5_LOJACLI )           // XML data of the invoice
            // oOrder["EtiquetaZpl"]       := _FoundXml( "EtiquetaZpl" )
            oOrder["NfPdf"]             := _FoundXml( "NfPdf", SC5->C5_SERIE, SC5->C5_NOTA, SC5->C5_CLIENTE, SC5->C5_LOJACLI, SF2->F2_FILIAL, SF2->F2_EMISSAO ) // memowrite record to a temp file and read the file to a variable
            // Httpquote( < cUrl >, < cMethod >, [ cGETParms ], [ cPOSTParms ], [ nTimeOut ], [ aHeadStr ], [ @cHeaderRet ] )
            FWJsonDeserialize(Httpquote(  SetRestBearer()[2]+cUrl /*url*/,;
                /* Method */'POST' ,;
                /* cGetParms */,;
                /* cPostParms */oOrder:ToJson() ,;
                /*timeout*/80 ,;
                /*aHeader*/SetRestBearer()[1],;
                @cHeaderGet /* cHeaderGet */ ), @oJSONRet)

            if Val(SubStr(strtokarr(cHeaderGet, Chr(10))[1], 10, 3)) == 200 // Check if the HTTP status code is 200 OK
                u_PlenMsg( "Httpquote OK", "Httpquote" ) // Log success message
                //Log the product as sent to B4U
                RecLock("SC5", .F.)
                SC5->C5_XB4U     := "I" // Mark product as sent to B4U
                SC5->C5_XB4UJSO  := oOrder:ToJson() // Store JSON sent to B4U
                lRet    := .t.
                SC5->(MSUnlock())
                u_PlenMsg("Enviando pedido XML/JSON: " + SC5->C5_NUM, "SendB4YouLogPedidoXmlJson")
            else
                RecLock("SC5", .F.)
                SC5->C5_XB4U     := "F" // Mark product as sent to B4U
                SC5->C5_XB4UJSO  := oJSONRet:Mensagem // Store JSON sent to B4U
                u_PlenMsg("Erro Httpquote: " + _oRDER + " - "+ oOrder:toJson(), "SendB4YouLogPedidoXmlJson")
                SC5->(MSUnlock())
                lRet    := .f.
            endif
        Else
            lRet    := .F.
            u_PlenMsg("Nota não encontrada: " + SC5->(C5_SERIE+C5_NOTA), "SendB4YouLogPedidoXmlJson")
        EndIf
    else
        u_PlenMsg("Pedido não encontrado: " + _Order, "SendB4YouLogPedidoXmlJson")
        lRet    := .f.
    EndIf
    RestArea(aArea) // Restore the area to the previous state
Return lRet

Static Function _FoundXml( cOption, Serie, Nota, Cliente, Loja, Filial, xData )
    Local cReturn       := ""
    Local xCXMLNFE      := "" //XML data of the invoice
    Do Case
        Case cOption == "XML"
            U_PLXMLNOTA(@xCXMLNFE)
            cReturn := Encode64(xCXMLNFE) // Return the XML data
        Case cOption == "EtiquetaZpl"
            cReturn := "need-to-do"
        Case cOption == "EtiquetaPdf"
            cReturn := "need-to-do"
        Case cOption == "NfPdf"
            //Nota
            cReturn := u_GERADANFE( Filial, Nota, Serie, xData ) // Generate the PDF file
        Otherwise
            cReturn := ""
    EndCase
Return cReturn

Static Function xValidC9B4U( _Order )
    Local lValid := .t.
    Local cQuery := ""
    Local cAlias := GetNextAlias()

    cQuery := " SELECT DISTINCT                                 " + CRLF
    cQuery += " *                                               " + CRLF
    cQuery += " FROM                                            " + CRLF
    cQuery += " 	" + RetSQLName("SC9") + " C9                " + CRLF
    cQuery += " WHERE                                           " + CRLF
    cQuery += "  C9.D_E_L_E_T_    != '*'                        " + CRLF
    cQuery += "  AND C9.C9_BLEST  != ' '                        " + CRLF
    cQuery += "  AND C9.C9_BLCRED != ' '                        " + CRLF
    cQuery += " AND C9.C9_FILIAL = '" + SubStr(_Order,1,6) + "' " + CRLF
    cQuery += " and C9.C9_PEDIDO = '" + SubStr(_Order,7,6) + "' " + CRLF

    cQuery := ChangeQuery(cQuery)
    varInfo("Consulta de produto na SC9 -> cQuery",   cQuery)
    TcQuery cQuery New Alias (cAlias)

    While (cAlias)->(!EOF())
        lValid := .f.
        (cAlias)->(DBSkip())
    enddo

Return lValid
