// #Include "fwrest.ch"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "RESTFUL.CH"
#INCLUDE 'TOPCONN.CH'

#Include "protheus.ch"
#Include "totvs.ch"
#Include "tbiconn.ch"
#Include "json.ch"
// #Include "fwrest.ch"

/* Plentech */
// upCustomer.prw - File auxiliar to get customers from Protheus
// Surely your goodness and faithfulness will pursue me all my days - Psalm 23:6

User Function upCustomer(cSearch)

    Local cQuery := ""
    Local cAlias := GetNextAlias()
    Local cJson
    Local cMsgApi := ""

    cQuery := " SELECT DISTINCT                       " + CRLF
    cQuery += " A1_COD,                               " + CRLF
    cQuery += " A1_LOJA,                              " + CRLF
    cQuery += " A1_NOME,                              " + CRLF
    cQuery += " A1_NREDUZ,                            " + CRLF
    cQuery += " A1_END,                               " + CRLF
    cQuery += " A1_MUN,                               " + CRLF
    cQuery += " A1_BAIRRO,                            " + CRLF
    cQuery += " A1_CEP,                               " + CRLF
    cQuery += " A1_EST,                                " + CRLF
    cQuery += " A1_INSCR,                             " + CRLF
    cQuery += " A1_EMAIL,                             " + CRLF
    cQuery += " A1_TEL,                             " + CRLF
    cQuery += " A1_CGC                                " + CRLF
    cQuery += " FROM                                  " + CRLF
    cQuery += " 	" + RetSQLName("SA1") + " A1      " + CRLF
    cQuery += " WHERE                                 " + CRLF
    cQuery += "  A1.D_E_L_E_T_ = ''                   " + CRLF
    cQuery += "  AND (A1.A1_CGC = '"+cSearch+"'          " + CRLF
    cQuery += "  OR A1.A1_NOME LIKE '%"+cSearch+"%' OR A1.A1_NREDUZ LIKE '%"+cSearch+"%' )         " + CRLF
    cQuery := ChangeQuery(cQuery)
    TcQuery cQuery New Alias (cAlias)

    If Empty((cAlias)->A1_COD)
        cMsgApi := {"Nenhum dado para ser consultado no código", .f.}
        
        u_PlenMsg(cMsgApi[1], "upCustomer", "Customer")
    Else
        cJson := jsonClient(cAlias)
        u_PlenMsg("Consulta do código realizada com sucesso!", "upCustomer", "Customer")
        cMsgApi := cJson
    EndIf
    (cAlias)->(DbCloseArea())
Return(cMsgApi)

Static Function jsonClient(cAlias)
    Local oCustomer  := JsonObject():New()
    Local oCustomers := JsonObject():New()
    Local aCustomer := {}
    Local lRet := .F.
    (cAlias)->( DBGoTop() )

    While (cAlias)->( !Eof() )
        oCustomer  := JsonObject():New()
        oCustomer["customerCode"]       := Alltrim((cAlias)->(A1_COD+A1_LOJA))
        oCustomer["customerName"]       := Alltrim((cAlias)->A1_NOME)
        oCustomer["tradeName"]          := Alltrim((cAlias)->A1_NREDUZ)
        oCustomer["address"]            := Alltrim((cAlias)->A1_END)
        oCustomer["district"]           := Alltrim((cAlias)->A1_BAIRRO)
        oCustomer["city"]               := Alltrim((cAlias)->A1_MUN)
        oCustomer["postalCode"]         := Alltrim((cAlias)->A1_CEP)
        oCustomer["state"]              := Alltrim((cAlias)->A1_EST)
        oCustomer["document"]           := Alltrim((cAlias)->A1_CGC)
        oCustomer["stateRegistration"]  := Alltrim((cAlias)->A1_INSCR)
        oCustomer["mail"]               := Alltrim((cAlias)->A1_EMAIL)
        oCustomer["mobile"]             := Alltrim((cAlias)->A1_TEL)
        aAdd(aCustomer, oCustomer)
        (cAlias)->(DbSkip())
        lRet := .t.
    EndDo
    oCustomers["customers"] := aCustomer

Return {oCustomers:toJson(),lRet}


User function upAltCustomer(_cNome, _cNomeReduz,_cInsc,  _cCep, _cEnd, _cBairro, _cEst, _cMunc, _cEmail, _cTel, _cCodCli, _cLojaCli, cCGC, active, _cCodMun)
    Local aReturn := {}

    aReturn := vldCustomer(_cCodCli, _cLojaCli ) // validate if the client exists
    If aReturn[2] // if true, client exists and can be altered

        aReturn := fRecordCli(  _cNome, _cNomeReduz,_cInsc,  _cCep, _cEnd, _cBairro, _cEst, _cMunc, _cEmail, _cTel, _cCodCli, _cLojaCli, cCGC, active, _cCodMun)

    EndIf

Return(aReturn)

Static Function vldCustomer(Customer, Sucursal, _cMsg)
    Local lRet := .t.
    Local oReturn := JsonObject():New()
    Public _cMsg := ""
    DbSelectArea("SA1")
    SA1->(DbSetorder(1))// A1_FILIAL + A1_COD + A1_LOJA

    If Empty(Customer) .OR. Empty(Sucursal)
        u_PlenMsg("Loja ou codigo do cliente em branco", "vldCustomer", "upCustomer")
        _cMsg := "Loja ou codigo do cliente em branco"
        
        lRet := .F.
    EndIf

    If !(SA1->(DbSeek(xFilial("SA1")+ Customer +  Sucursal)) )
        u_PlenMsg("Nao foi possivel localizar o cliente", "vldCustomer", "upCustomer")
        lRet := .F.
        _cMsg := "Nao foi possivel localizar o cliente"
    EndIf
    oReturn["Processo"] := _cMsg
Return {oReturn:toJson(), lRet}

Static Function fRecordCli(  __cNome, _cNomeReduz,_cInsc,  _cCep, _cEnd, _cBairro, _cEst, _cMunc, _cEmail, _cTel, _cCodCli, _cLojaCli, cCGC, active, _cCodMun)

    Local lOk     := .F.
    Local oReturn       := JsonObject():New()
    Public _cNomeCli    := __cNome


    oModel := FWLoadModel("MATA030")
    oModel:SetOperation(4)
    oModel:Activate()

    oSA1Mod:= oModel:getModel("MATA030_SA1")

    oSA1Mod:setValue("A1_NOME"    ,   _cNomeCli      ) // Variable Public to use in other places
    oSA1Mod:setValue("A1_NREDUZ"  ,   _cNomeReduz    )
    oSA1Mod:setValue("A1_INSCR"   ,   _cInsc         )
    oSA1Mod:setValue("A1_CEP"     ,   _cCep          )
    oSA1Mod:setValue("A1_END"     ,   _cEnd          )
    oSA1Mod:setValue("A1_BAIRRO"  ,   _cBairro       )
    oSA1Mod:setValue("A1_EST"     ,   _cEst          )
    oSA1Mod:setValue("A1_MUN"     ,   _cMunc         )
    oSA1Mod:setValue("A1_EMAIL"   ,   _cEmail        )
    oSA1Mod:setValue("A1_TEL"     ,   _cTel          )
    oSA1Mod:setValue("A1_CGC"     ,   cCGC           )
    oSA1Mod:setValue("A1_MSBLQL"  ,   active         )
    oSA1Mod:setValue("A1_TIPO"    ,   ""              ) // TIPO DE PESSOA // 1 = Fisica ; 2 = Juridica
    oSA1Mod:setValue("A1_COD_MUN" ,   _cCodMun        ) // CODIGO DO MUNICIPIO

    If oModel:VldData()

        If oModel:CommitData()
            lOk := .T.
            _cMsg := "[upCustomer] -> Cliente alterado com sucesso"
        Else
            lOk := .F.
            _cMsg := "[upCustomer] -> Falha na tentativa de realizar o commit" +CRLF
        EndIf

    Else
        lOk := .F.
        _cMsg := "[upCustomer] -> Erro na validacao de informacoes "+CRLF
    EndIf

    If !lOk
        aErro := oModel:GetErrorMessage()

        oReturn["IdFormOrig"]           := AllToChar(aErro[01])
        oReturn["IdCampoOrig"]          := AllToChar(aErro[02])
        oReturn["IdFormularioErro"]     := AllToChar(aErro[03])
        oReturn["IdCampoErro"]          := AllToChar(aErro[04])
        oReturn["IdErro"]               := AllToChar(aErro[05])
        oReturn["MsgErro"]              := AllToChar(aErro[06])
        oReturn["MsgSolucao"]           := AllToChar(aErro[07])
        oReturn["VlrAtribuido"]         := AllToChar(aErro[08])
        oReturn["VlrAnterior"]          := AllToChar(aErro[09])
    EndIf

    oModel:DeActivate()

    u_PlenMsg(_cMsg)
    oReturn["Processo"] := _cMsg
Return {oReturn:toJson(), lOk}


User Function upIncCustomer(_cNome, _cNomeReduz, _cInsc,  _cCep, _cEnd, _cBairro,_cEst, _cMunc, _cEmail, _cTel, _cCodCli, _cLojaCli, _cCgc, _cCodMun)

    Local lOk           := .F.
    Local cCod          := ""
    Local oReturn       := JsonObject():New()
    Public _cNomeCli    := _cNome


    oModel := FWLoadModel("MATA030")
    oModel:SetOperation(3)
    oModel:Activate()

    fConsultCli(@cCod, @_cLojaCli,_cCgc) // get the number of A1_COD and A1_LOJA

    oSA1Mod:= oModel:getModel("MATA030_SA1")
    oSA1Mod:setValue("A1_COD"     ,   cCod            ) // CODIGO
    oSA1Mod:setValue("A1_LOJA"    ,   _cLojaCli       ) // LOJA
    oSA1Mod:setValue("A1_CGC"     ,   _cCgc           ) // CNPJ - CPF
    oSA1Mod:setValue("A1_NREDUZ"  ,   _cNomeReduz     ) // NOME FANTASIA
    oSA1Mod:setValue("A1_END"     ,   _cEnd           ) // ENDERECO
    oSA1Mod:setValue("A1_NOME"    ,   _cNomeCli       ) // NOME
    oSA1Mod:setValue("A1_BAIRRO"  ,   _cBairro        ) // BAIRRO
    oSA1Mod:setValue("A1_INSCR"   ,   _cInsc          ) // INSCRICAO ESTADUAL
    oSA1Mod:setValue("A1_EST"     ,   _cEst           ) // ESTADO
    oSA1Mod:setValue("A1_MUN"     ,   _cMunc          ) // MUNICIPIO
    oSA1Mod:setValue("A1_CEP"     ,   _cCep           ) // CEP
    oSA1Mod:setValue("A1_PAIS"    ,   "105"           ) // PAIS - DEFAULT 105
    oSA1Mod:setValue("A1_EMAIL"   ,   _cEmail         ) // EMAIL
    oSA1Mod:setValue("A1_TEL"     ,   _cTel           ) // TELEFONE
    oSA1Mod:setValue("A1_CODPAIS" ,   "01058"         ) // CODIGO DO PAIS - DEFAULT  01058
    oSA1Mod:setValue("A1_CONTRIB" ,   "2"             ) // CONTRIBUINTE // 2 = Não Contribuinte ; 1 = Contribuinte
    oSA1Mod:setValue("A1_TIPO"    ,   ""              ) // TIPO DE PESSOA // 1 = Fisica ; 2 = Juridica
    oSA1Mod:setValue("A1_COD_MUN" ,   _cCodMun        ) // CODIGO DO MUNICIPIO
    oSA1Mod:setValue("A1_PESSOA" ,   if(len(_cCgc)=11,"F","J")        ) // 
    oSA1Mod:setValue("A1_TIPO" ,   "F"        ) // 

    //Valida as informacoes
    If oModel:VldData()

        If oModel:CommitData()
            lOk := .T.
            oReturn["Processo"]:= "Cliente incluido com sucesso!"
            oReturn["Codigo"]:= SA1->A1_COD
            oReturn["Loja"]:= SA1->A1_LOJA

        Else
            lOk := .F.
            oReturn["Processo"] :=  "Falha na tentativa de realizar o commit"
        EndIf

    Else
        lOk := .F.
        oReturn["Processo"] := "Erro na validacao de informacoes "
    EndIf

    If ! lOk

        aErro := oModel:GetErrorMessage()

        oReturn["IdFormOrig"]           := AllToChar(aErro[01])
        oReturn["IdCampoOrig"]          := AllToChar(aErro[02])
        oReturn["IdFormularioErro"]     := AllToChar(aErro[03])
        oReturn["IdCampoErro"]          := AllToChar(aErro[04])
        oReturn["IdErro"]               := AllToChar(aErro[05])
        oReturn["MsgErro"]              := AllToChar(aErro[06])
        oReturn["MsgSolucao"]           := AllToChar(aErro[07])
        oReturn["VlrAtribuido"]         := AllToChar(aErro[08])
        oReturn["VlrAnterior"]          := AllToChar(aErro[09])

    EndIf

    oModel:DeActivate()
    // u_PlenMsg()

Return { oReturn:toJson(), lOk }

Static Function fConsultCli(cCod, _cLojaCli, _cCgc)

    Local _cAliasCli    :=  GetNextAlias()
    Local _cQry         := ""

    _cQry := " SELECT                           " + CRLF
    _cQry += " TOP 1                            " + CRLF
    _cQry += " A1_CGC,                          " + CRLF
    _cQry += " A1_COD,                          " + CRLF
    _cQry += " A1_LOJA                          " + CRLF
    _cQry += " FROM	"+RetSqlName("SA1")+" SA1   " + CRLF
    _cQry += " WHERE                            " + CRLF
    _cQry += " A1_CGC = '"+_cCgc+"'             " + CRLF
    _cQry += " AND D_E_L_E_T_ = ''              " + CRLF
    _cQry += " ORDER BY A1_LOJA DESC            " + CRLF
    _cQry := ChangeQuery(_cQry)
    TcQuery _cQry New Alias (_cAliasCli)

    If !Empty((_cAliasCli)->A1_COD)
        _cLojaCli   := Soma1((_cAliasCli)->A1_LOJA)
        cCod        := (_cAliasCli)->A1_COD
        (_cAliasCli)->(DbCloseArea())
        Return(.T.)
    else
        _cLojaCli   := strzero("01",TamSX3("A1_LOJA")[1]) // Fully with zeros before the 1 until the size of the field
        cCod        := SubStr(_cCGC,1,8) // return 8 first digits of CNPJ/CPF
    EndIf

Return(.F.)
