//Bibliotecas
#Include 'Protheus.ch'
#Include 'RwMake.ch'
#Include 'TopConn.ch'

/*------------------------------------------------------------------------------------------------------*
 | P.E.:  MA410MNU                                                                                      |
 | Desc:  Adição de opção no menu de ações relacionadas do Pedido de Vendas                             |
 | Links: http://tdn.totvs.com/display/public/mp/MA410MNU                                               |
*------------------------------------------------------------------------------------------------------*/

User Function MA410MNU()
    Local aArea := GetArea()

    //Adicionando função de vincular
    aadd(aRotina,{"Atu. Volume B4YOU","u_updB4U", 0 , 4, 0 , Nil})

    RestArea(aArea)
Return
