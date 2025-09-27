#Include "protheus.ch"

/*
    Ponto de ENtrada Utilizado para declarar variaveis publicas no inicio da rotina MATA410
*/
User Function MA410COR()
    Local aCoresPE  := ParamIXB
    Local aNoFields := {"ZGZ_PEDIDO","ZGZ_EMP","ZGZ_FILORI","ZGZ_DOC","ZGZ_SERIE","ZGZ_XPAYOR","ZGZ_LINKPG"}

    Public aHeadZGZ := {}
    Public aColsZGZ := {}
    Local lAuto 			:= IsInCallStack("MSEXECAUTO")

    if !lAuto // se não for msexecauto, carrega as informações
        If Empty(aHeadZGZ)
            dbSelectArea("SX3")
            dbSetOrder(1)
            MsSeek("ZGZ")
            While !EOF() .And. (SX3->X3_ARQUIVO == "ZGZ")
                IF X3USO(SX3->X3_USADO) .AND. cNivel >= SX3->X3_NIVEL .And. aScan(aNoFields,{|x| AllTrim(x)==AllTrim(SX3->X3_CAMPO)}) == 0
                    AADD(aHeadZGZ,{ TRIM(x3Titulo()),;
                        SX3->X3_CAMPO,;
                        SX3->X3_PICTURE,;
                        SX3->X3_TAMANHO,;
                        SX3->X3_DECIMAL,;
                        SX3->X3_VALID,;
                        SX3->X3_USADO,;
                        SX3->X3_TIPO,;
                        SX3->X3_F3,;
                        SX3->X3_CONTEXT } )
                EndIf
                dbSelectArea("SX3")
                dbSkip()
            EndDo
        EndIf
    EndIf

Return aCoresPE
