#Include "Totvs.ch"

/*
    Ponto de Entrada no faturamento da Nota fiscal para gravar o contas a receber de acordo com parcelas informadas na condicao negociada
*/

User Function MT461VCT
    Local _aVencto := ParamIxb[1]
    Local _aTitulo := ParamIxb[2]
    Local aAux     := {}
    Local lAuto 			:= IsInCallStack("MSEXECAUTO")

    if !lAuto
        dbSelectArea("ZZG")
        dbSetOrder(1)//ZZG_EMP, ZZG_FILORI, ZZG_PEDIDO, R_E_C_N_O_, D_E_L_E_T_
        If dbSeek( cEmpAnt + xFilial("SC5") + SC5->C5_NUM )

            While ZZG->(!Eof()) .And. ZZG->ZZG_EMP  +   ZZG->ZZG_FILORI +   ZZG->ZZG_PEDIDO==;
                    cEmpAnt       +   xFilial("SC5")  +   SC5->C5_NUM

                aAdd(aAux,{;
                    ZZG->ZZG_VENCRE ,;
                    ZZG->ZZG_VALOR  })

                ZZG->(dbSkip())
            End

            If Len(aAux)>0
                _aVencto := aClone(aAux)
            Endif
        Endif
    Endif

Return _aVencto
