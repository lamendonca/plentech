#INCLUDE "TOTVS.CH"

/*
    Ponto de Entrada para excluir as parcelas infiormadas quando condicao negociada na exclusão do pedido de venda
*/

User Function MA410DEL

dbSelectArea("ZZG")
dbSetOrder(2)//ZZG_EMP, ZZG_FILORI, ZZG_PEDIDO, ZZG_PARCEL
If dbSeek( cEmpAnt + SC5->(C5_FILIAL+C5_NUM) )
    While ZZG->(!Eof()) .And. ZZG->(ZZG_EMP+ZZG_FILORI+ZZG_PEDIDO) == cEmpAnt + SC5->C5_FILIAL + SC5->C5_NUM
        Reclock("ZZG",.F.)
        dbDelete()
        MsUnlock()
        ZZG->(dbSkip())
    End    
Endif


Return 
