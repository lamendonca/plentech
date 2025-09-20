#Include "PROTHEUS.CH"
#INCLUDE "topconn.ch"

#DEFINE CRLF CHR( 13 ) + CHR( 10 )

User Function b4uschedule()
    Local aData    := { }
    Local nX        := 0
    Local aTables   := SuperGetMv("PL_B4UTABLE",.f.,{ "SB1", "SC5" })   // Tables to be used in the B4U integration
    Private Rows    := SuperGetMv("PL_B4UROW", .f., 100)                // Number of rows to be processed in each table
    Private lJob    := FwGetRunSchedule()
    u_PlenMsg( "Carregando os dados para serem atualizados. " + Dtoc( Date( ) ) )

    For nX := 1 to len(aTables)
        aData  := xDados( aTables[nX], Rows )
    next nX

    if !Empty( aData )
        For nX := 1 to len(aData)
            u_integB4U( aData[nX][2] )
        Next nX
    else
        u_PlenMsg( "Não houve dados para serem atualizados.  Dia: " + Dtoc( Date( ) ) )
    EndIf

Return Nil

Static Function xDados( Table, Rows )
    Local aDados := {}
    Local cAlias := GetNextAlias( )

    TcQuery xQuery( Table, Rows ) New Alias (cAlias)

    while  (cAlias)->( !EOF( ) )
        Do Case
            Case Table = "SB1"
                aAdd(aDados, {Table, (cAlias)->B1_COD})
            Case Table = "SC5"
                aAdd(aDados, {Table, (cAlias)->(C5_FILIAL+C5_NUM)})
        end case
        (cAlias)->( DBSkip( ) )
    end
    (cAlias)->( DbCloseArea( ) )
Return aDados

Static Function xQuery( Table, Rows )
    Local cQuery := ""

    cQuery += "     SELECT TOP "+cValToChar(Rows)+" *  " + CRLF
    cQuery += "         FROM "+Table+ " WHERE " + CRLF
    cQuery += "     WHERE D_E_L_E_T_!='*' AND  " + CRLF
    // Check if the table is SB1 or SC5 and adjust the query accordingly
    if fieldpos("B1_B4USTA") > 0 .and. fieldpos("B1_XB4U") > 0 .and. fieldpos("C5_B4USTA") > 0 .and. fieldpos("C5_XB4UJSO") > 0
        cQuery += "     "+Iif(Substr(Table,1,1)='S', Substr(Table,2,2) , Table )+"_XB4U in (' ','1')  " + CRLF
    endif
Return cQuery

Static Function u_PlenMsg(msg, lVarInfo, variavel)
    Default lVarInfo := .F.
    conout("*********** API PLENTECH - B4U ***********")
    msg := cValToChar( TIME() ) +  msg
    if lVarInfo
        VarInfo(msg,variavel)
    else
        Conout(msg)
    endif
    conout("******************************************")

Return nil

Static Function Scheddef()
    Local aParam := {}
    aParam := {;
        /*Tipo R para relatorio P para processo*/               "P"    , ;
        /*Pergunte do relatorio, caso nao use passar ParamDef*/ ""     , ;
        /*Alias*/                                               ""     , ;
        /*Array de ordens*/                                     {}     , ;
        }
Return aParam
