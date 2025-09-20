#INCLUDE "TOTVS.CH"

/*
    Gravacao das parcelas de COndicao Negociada
*/

User Function MTA410T
Local nX := 0

IF INCLUI
    If TYpe("aColsZZG")<>"U"
        If Len(aColsZZG)>0
            For nX := 1 To Len(aColsZZG)
                Reclock("ZZG",.T.)
				ZZG_FILIAL := xFilial("ZZG")
				ZZG_EMP    := cEmpAnt
				ZZG_FILORI := SC5->C5_FILIAL
				ZZG_TIPO   := ACOLSZZG[nX][1]
				ZZG_PARCEL := ACOLSZZG[nX][2]
				ZZG_VENCRE := ACOLSZZG[nX][3]
				ZZG_VALOR  := ACOLSZZG[nX][4]
				ZZG_PEDIDO := SC5->C5_NUM
                MsUNlock()
            Next
        Endif
    Endif
ElseIf ALTERA
    If TYpe("aColsZZG")<>"U"
        If Len(aColsZZG)>0
            For nX := 1 To Len(aColsZZG)
                dbSelectArea("ZZG")
                dbSetOrder(2)//ZZG_EMP, ZZG_FILORI, ZZG_PEDIDO, ZZG_PARCEL
				If dbSeek( cEmpAnt + SC5->C5_FILIAL + SC5->C5_NUM + Padr(ACOLSZZG[nX][2],TamSx3("ZZG_PARCEL")[1]) )
                    Reclock("ZZG",.F.)
                Else
                    Reclock("ZZG",.T.)
                Endif    
                ZZG_FILIAL := xFilial("ZZG")
                ZZG_EMP    := cEmpAnt
                ZZG_FILORI := SC5->C5_FILIAL
                ZZG_TIPO   := ACOLSZZG[nX][1]
                ZZG_PARCEL := ACOLSZZG[nX][2]
                ZZG_VENCRE := ACOLSZZG[nX][3]
                ZZG_VALOR  := ACOLSZZG[nX][4]
                ZZG_PEDIDO := SC5->C5_NUM
                MsUNlock()
            Next
        Endif
    Endif
Endif    

If TYpe("aColsZZG")<>"U"
    aColsZZG := {}
Endif    

Return
