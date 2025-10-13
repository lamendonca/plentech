#INCLUDE "PROTHEUS.CH"

//Create a log message for debugging or information purposes
User Function PlenMsg(cMsg, _cFunc, Auxiliar)
    Local lLog          := SuperGetMV("PL_LOG", .F., .T.)
    Local lVisible      := !isblind()
    Default _cFunc      := "Geral"
    Default Auxiliar    := "Geral"
    If lLog
        ConOut( "[ " + DtoS(dDataBase) + " - " + Time() + " ] [ Plentech - "+Auxiliar+" - Rest ] [ " + _cFunc + " ] " + cMsg )
        if lVisible 
            MsgInfo( cMsg, _cFunc )
        EndIf
    EndIf
Return
