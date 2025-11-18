#Include "PROTHEUS.CH"
#INCLUDE "topconn.ch"

#DEFINE CRLF CHR( 13 ) + CHR( 10 )


User Function b4uschedule()
    Local aData    := { }
    Local nX        := 0
    // Local aTables   := SuperGetMv("PL_B4UTABLE",.f.,{ "SB1" })   // Tables to be used in the B4U integration
    Local aTables   := SuperGetMv("PL_B4UTABLE",.f.,{ "SB1", "SC5" })   // Tables to be used in the B4U integration
    // Local aTables   := SuperGetMv("PL_B4UTABLE",.f.,{  "SC5" })   // Tables to be used in the B4U integration
    Private Rows    := SuperGetMv("PL_B4UROW", .f., 100)                // Number of rows to be processed in each table
    Private lJob    := FwGetRunSchedule()

    u_PlenMsg( "Carregando os dados para serem atualizados. " + Dtoc( Date( ) ) )

    // Send xml to B4U
    aData  := xDados( "SC5", Rows, " C5_NOTA!=' ' AND C5_XB4U='S' " ) // get orders to send

    For nX := 1 to len(aTables)
        u_PlenMsg( "Processando a tabela: " + aTables[nX] + " - Registros por vez: " + cValToChar(Rows) , "b4uSchedule", "B4U" )
        aData  := xDados( aTables[nX], Rows )

        if !Empty( aData )
            For nX := 1 to len(aData)
                u_PlenMsg( "Processando a tabela: " + aData[nX][1] + " - Registro: " + aData[nX][2] , "b4uSchedule", "B4U" )
                u_integB4U( iif(aData[nX][1]=="SC5","Order","Product") , aData[nX][2] )
            Next nX
        else
            u_PlenMsg( "Não houve dados para serem atualizados.  Dia: " + Dtoc( Date( ) ) )
        EndIf
    next nX

    // Get status order from B4U
    aData  := xDados( "SC5", Rows, " C5_NOTA =' ' AND C5_XB4U='S' AND C5_XB4USTA<> 'AGUARDANDO_NF_PARA_EXPEDICAO' " ) // get orders to send
    For nX := 1 to len(aData)
        u_PlenMsg( "Verificando status do pedido: " + aData[nX][2] , "b4uSchedule", "B4U" )
        u_updB4U( aData[nX][2] )
    Next nX

Return Nil

User Function b4uinteg()
    Processa({|| u_b4uschedule()})


Return Nil

Static Function xDados( Table, Rows, Extra )
    Local aDados := {}
    Local cAlias := GetNextAlias( )
    Default Extra := ""

    TcQuery xQuery( Table, Rows, Extra ) New Alias (cAlias)

    while  (cAlias)->( !EOF( ) )
        Do Case
            Case Table = "SB1"
                aAdd(aDados, {Table, (cAlias)->B1_COD})
            Case Table = "SC5"
                if (cAlias)->(C5_XB4U) =="X" //Canceled orders only
                    u_PlenMsg("Pedido cancelado: " + (cAlias)->(C5_FILIAL+C5_NUM), "xDados", "B4U")
                    // aAdd(aDados, {Table, (cAlias)->(C5_FILIAL+C5_NUM)})
                    u_integB4U( "Cancel" , (cAlias)->(C5_FILIAL+C5_NUM) )
                elseif (cAlias)->(C5_XB4U) =="S" .and.; // Orders integrated successfully
                        !Empty((cAlias)->(C5_NOTA)) .and.; // and with invoice issued
                        (cAlias)->(C5_NOTA)!='XXXXXX' // and not canceled invoice
                    u_PlenMsg("XML para enviar: " + (cAlias)->(C5_FILIAL+C5_NUM), "xDados", "B4U")
                    // aAdd(aDados, {Table, (cAlias)->(C5_FILIAL+C5_NUM)})
                    u_integB4U( "SendXmlJson" , (cAlias)->(C5_FILIAL+C5_NUM) )
                else // orders not canceled and to be sent
                    aAdd(aDados, {Table, (cAlias)->(C5_FILIAL+C5_NUM)})
                endif
        end case
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

Static Function Scheddef()
    Local aParam := {}
    aParam := {;
        /*Tipo R para relatorio P para processo*/               "P"    , ;
        /*Pergunte do relatorio, caso nao use passar ParamDef*/ ""     , ;
        /*Alias*/                                               ""     , ;
        /*Array de ordens*/                                     {}     , ;
        }
Return aParam
