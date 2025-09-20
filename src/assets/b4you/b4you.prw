#Include "protheus.ch"
#Include "totvs.ch"
#Include "tbiconn.ch"
#Include "json.ch"
// #Include "fwrest.ch"

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

//Fields to validate use in the API (TODO: Create these fields in the respective tables)
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

    Local _cEmp         := "01"     // Company code - Check your company code in SM0->M0_CODIGO
    Local _cFil         := "0207"   // Sucursal code - Check your filial code in SM0->M0_CODFIL
    Private lTest       := .T.      //TODO: Remove it before go to production
    Default _Method     := "Cancel"  // Default method to test
    Default _Order      := "028071" // Default order number to test
    If Select("SX2") == 0
        RpcSetEnv(_cEmp, _cFil,NIL, NIL, "FAT")
    EndIf
    if lower(_Method) == lower("Product")
        CreateB4YouLogProduct( "030625" )// Test product creation
    elseif lower(_Method) == lower("Order")
        ConnectB4YouLogOrder(_Order)              // Test order creation
    elseif lower(_Method) == lower("Cancel")  //TODO: Not possible to cancel a order across Httpquo
        CancelB4YouLogOrder(_Order)               // Test order cancellation
    elseif lower(_Method) == lower("SendXmlJson")
        SendB4YouLogPedidoXmlJson(_Order) // Test sending XML/JSON data
    else
        u_PlenMsg("Método inválido: " + _Method, "xTestB4U")
    endif
    RpcClearEnv()
return

User Function integB4U( _Method, aInfo )
    if _Method == "Product"
        CreateB4YouLogProduct( aInfo[2] )
    elseif _Method == "Order"
        ConnectB4YouLogOrder( aInfo[2] )
    elseif _Method == "Cancel"
        CancelB4YouLogOrder( aInfo[2] )
    elseif _Method == "SendXmlJson"
        SendB4YouLogPedidoXmlJson( aInfo[2] )
    else
        u_PlenMsg("Método inválido: " + _Method, "integB4U")
    endif
Return


// Static Function to set credentials for REST API -- Bearer Token of Sandbox
Static Function SetRestBearer()
    Local cBearer   := SuperGetMV("PL_REST_BEARER",   .F.,    "T0xGQToybXk2ZXFjeGlhOHQ0cGI5MWxzNWR3aG8=")
    Local cUrl      := SuperGetMV("PL_RSTURL",        .f.,    "https://api.b4youlog.com/sandbox/v1")
    Local _aHeader  := {}
    AAdd(_aHeader, 'Content-Type: application/json')
    AAdd(_aHeader, 'Authorization: Bearer ' + cBearer  )

Return {_aHeader, cUrl }


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
    SC5->(DBSeek(xFilial("SC5")+ _Order ))

    DBSelectArea("SC6")
    SC6->(DbSetOrder(1))
    SC6->(DBSeek(xFilial("SC6")+ _Order ))

    DBSelectArea("SA1")
    SA1->(DbSetOrder(1))
    SA1->(DBSeek(xFilial("SA1")+ SC5->(C5_CLIENTE+C5_LOJACLI) ))

    DBSelectArea("SB1")
    SB1->(DbSetOrder(1))

    if SC5->(Found())

        oOrder["NumeroPedido"]              := SC5->C5_NUM
        oOrder["CodigoCliente"]             := SC5->C5_CLIENTE
        oOrder["DataEmissao"]               := SUBSTRING(DTOS(SC5->C5_EMISSAO),1,4)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),5,2)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),7,2)
        oOrder["CnpjTransportadora"]        := Posicione("SA4", 1, xFilial("SA4")+SC5->C5_TRANSP, "A4_CGC")

        oOrder["DataFaturamento"]           := SUBSTRING(DTOS(SC5->C5_EMISSAO),1,4)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),5,2)+'-'+SUBSTRING(DTOS(SC5->C5_EMISSAO),7,2)//TODO: Validar uso do campo
        oOrder["TipoCanalVenda"]            := "4"                  // 1 = CORPORATIVO; 2 = ATACADO; 3 = TELEVENDAS; 4 = SITE; 5 = MARKETPLACE; 7 = LICITACAO //TODO: Validar uso do campo
        oOrder["TipoDePedido"]              := "1"                  // 1 = CONSUMIDOR FINAL; 2 = TRANSFERENCIA FULL; 3 = TRANSFERENCIA; 4 = ATACADO; 5 = CORPORATIVO; 6 = LICITACAO; 7 = TROCA //TODO: Validar uso do campo
        oOrder["OrdemDeCompra"]             := ""
        oOrder["NumeroPedidoCLiente"]       := ""

        // Clientes
        IF SA1->(Found()) .and. lTest
            oOrder["NomeCliente"]           := SA1->A1_NOME
            oOrder["EnderecoCliente"]       := SA1->A1_END
            oOrder["BairroCliente"]         := SA1->A1_BAIRRO
            oOrder["MunicipioCliente"]      := SA1->A1_MUN
            oOrder["CepCLiente"]            := SA1->A1_CEP
            oOrder["EstadoCliente"]         := SA1->A1_EST
            oOrder["CnpjCpfCliente"]        := SA1->A1_CGC
            oOrder["IeCliente"]             := SA1->A1_INSCR
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
            u_PlenMsg("Cliente não encontrado: " + SC5->(C5_CLIENTE+C5_LOJA), "ConnectB4YouLogOrder")
            lRet    := .F.
        ENDIF

        While SC6->(!EOF()) .and. SC6->C6_NUM == _Order .and. SC6->C6_FILIAL == xFilial("SC6")

            oOrderItens := JsonObject():New() // Array to hold order items
            oOrderItens["NumeroPedido"]     := SC5->C5_NUM

            SB1->(DBSeek(xFilial("SB1") + SC6->C6_PRODUTO )) // Seek product in SB1
            if SB1->(Found())

                if fieldPos("B1_XB4U") > 0 .and. fieldPos("B1_XB4UJSO") > 0 //Validate if the fields exist
                    if !(SB1->B1_XB4U == "S") // Check if product is marked for B4U
                        If CreateB4YouLogProduct(SC6->C6_PRODUTO) // Re-fetch product details // Se não encontrar o produto, tenta criar
                            u_PlenMsg("Produto ainda não havia sido criado: " + SC6->C6_PRODUTO, "ConnectB4YouLogOrder")
                        endif
                    endif
                endif
            else
                u_PlenMsg("Produto não encontrado: " + SC6->C6_PRODUTO, "ConnectB4YouLogOrder")
                lRet    := .F.
            endif
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
            if  FieldPos("B5_XB4U") > 0 .and.  FieldPos("B5_XB4UJSO") > 0
                RecLock("SC5", .F.)
                SC5->B5_XB4U     := "S"                         // Mark product as sent to B4U
                SC5->B5_XB4UJSO  := FwNoAccent(oOrder:ToJson()) // Store JSON sent to B4U
                SC5->(MSUnlock())
            endif
            lRet    := .t.
        Else
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
        if lTest
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
        else
            oProduct["CodigoReferencia"]        := "Descricao Produto"//Alltrim(SB1->B1_COD)
            oProduct["Unidade"]                 := SB1->B1_UM
            oProduct["GrupoDeProduto"]          := SB1->B1_GRUPO
            oProduct["DescricaoProduto"]        := Alltrim(SB1->B1_DESC)
            oProduct["Peso"]                    := SB1->B1_PESO
            oProduct["Volume"]                  := Val("1")
            oProduct["CodigoDeBarras"]          := Alltrim(SB1->B1_CODBAR)
            oProduct["AlmoxarifadoPadrao"]      := ""
            oProduct["CodigoMontador"]          := ""                   // Not able to use
            oProduct["ControlaNumeroDeSerie"]   := "N"
        end
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
                SB1->B1_XB4UJSO  := FwNoAccent(oProduct:ToJson()) // Store JSON sent to B4U
                SB1->(MSUnlock())
            endif
            lRet    := .t.
        else
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
    SC5->(DBSeek(xFilial("SC5")+ _Order))

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
                SC5->B5_XB4U     := "C" // Mark product as sent to B4U
                SC5->B5_XB4UJSO  := oOrder:ToJson() // Store JSON sent to B4U
            endif
            lRet    := .t.
        else
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
    SC5->(DBSeek(xFilial("SC5") + _Order))

    DBSelectArea("SF2")
    SF2->(DbSetOrder(1))
    SF2->(DbGoTop())
    SF2->(DBSeek(xFilial("SF2") + SC5->(C5_NOTA+C5_SERIE+C5_CLIENTE+C5_LOJACLI)))

    if SC5->(Found()) .AND. SF2->(Found())
        oOrder["NumeroPedido"]      := SC5->C5_NUM // Set the order number
        oOrder["Xml"]               := _FoundXml( "XML", SC5->C5_SERIE, SC5->C5_NOTA, SC5->C5_CLIENTE, SC5->C5_LOJACLI )           // XML data of the invoice
        oOrder["EtiquetaZpl"]       := _FoundXml( "EtiquetaZpl" )
        oOrder["NfPdf"]             := _FoundXml( "NfPdf" ) // memowrite record to a temp file and read the file to a variable
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
            if  FieldPos("C5_XB4U") > 0 .and.  FieldPos("C5_XB4UJSO") > 0
                RecLock("SC5", .F.)
                SC5->B5_XB4U     := "I" // Mark product as sent to B4U
                SC5->B5_XB4UJSO  := oOrder:ToJson() // Store JSON sent to B4U
            endif
            lRet    := .t.
            u_PlenMsg("Enviando pedido XML/JSON: " + SC5->C5_NUM, "SendB4YouLogPedidoXmlJson")
        else
            u_PlenMsg("Erro Httpquote: " + _oRDER + " - "+ oOrder:toJson(), "SendB4YouLogPedidoXmlJson")
            lRet    := .f.
        endif
    Else
        lRet    := .F.
        u_PlenMsg("Nota não encontrada: " + SC5->(C5_SERIE+C5_NOTA), "SendB4YouLogPedidoXmlJson")
    EndIf
    RestArea(aArea) // Restore the area to the previous state
Return lRet

Static Function _FoundXml( cOption, Serie, Nota, Cliente, Loja )
    Local cReturn       := ""
    Local xCXMLNFE      := "" //XML data of the invoice
    Do Case
        Case cOption == "XML"
            // TODO: carregar XML real (ex.: a partir da SF2/SD2, tabela própria, ou caminho em MV)
            U_PLXMLNOTA(@xCXMLNFE)
            cReturn := xCXMLNFE // Return the XML data
        Case cOption == "EtiquetaZpl"
            cReturn := "need-to-do"
        Case cOption == "EtiquetaPdf"
            cReturn := "need-to-do"
        Case cOption == "NfPdf"
            cReturn := "need-to-do" //How to transform a PDF in base64?
            if .f. //TODO: implementar
                //Nota

                _cNilNF := u_GERA_DANFE( Filial, Nota, Serie, xData ) // Generate the PDF file

                ADir( _cNilNF, aFiles, aSizes)//Verifica o tamanho do arquivo, parâmetro exigido na FRead.

                nHandle := fopen( _cNilNF, FO_READWRITE + FO_SHARED )
                cString := ""
                FRead( nHandle, cString, aSizes[1] ) //Carrega na variável cString, a string ASCII do arquivo.

                _cTextNf := Encode64(cString) //Converte o arquivo para BASE64

                fclose(nHandle)
            endif
        Otherwise
            cReturn := ""
    EndCase
Return cReturn

