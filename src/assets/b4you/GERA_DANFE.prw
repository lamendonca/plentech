
/*/{Protheus.doc} User Function GERA_DANFE
    Gera nota danfe
    @type User Function
    @author Lucas Mendona
    @since 28/09/2020
    @version 1.0
    @param xcFilial, String, Numero da filial
    @param xcNota, String, Numero da Nota do documento
    @param xcSerie, String, Numero da Srie do documento
    @param xData, Date, Data da emisso
    @return url, String, Caminho da nota
/*/

#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"
#include 'fileio.ch'
#include 'protheus.ch'
#include 'topconn.ch'



User Function GERADANFE(XCFILIAL,XCNOTA,XCSERIE,XDATA, XTIPO)
	Local aArea     := GetArea()
	Local cIdent    := ""
	Local cArquivo  := ""
	Local oDanfe    := Nil
	Local lEnd      := .F.
	Local nTamNota  := TamSX3('F2_DOC')[1]
	Local nTamSerie := TamSX3('F2_SERIE')[1]
	Local cReturn 	:= ""

	Local _aAreaSM0 := {}
	Local _oAppBk := oApp //Guardo a variavel resposavel por componentes visuais
	Local cPasta  := SuperGetMv("PL_B4UFLD",.f.,"\b4u\invoices")

	Private PixelX
	Private PixelY
	Private nConsNeg
	Private nConsTex
	Private oRetNF
	Private nColAux
	DEFAULT XTIPO := 2 //SAÍDA

	dbSelectArea("SM0")
	_aAreaSM0 := SM0->(GetArea())
	_cEmpBkp := SM0->M0_CODIGO //Guardo a empresa atual
	_cFilBkp := ALLTRIM(SM0->M0_CODFIL) //Guardo a filial atual

	SM0->(dbSetOrder(1))
	SM0->(dbSeek(CEMPANT+XCFILIAL,.T.)) //Posiciona Empresa
	cEmpAnt := SM0->M0_CODIGO //Seto as variaveis de ambiente
	cFilAnt := SM0->M0_CODFIL
	//Se existir nota
	If !Empty(XCNOTA)
		//Pega o IDENT da empresa
		cerror := ""
		// cIdEnt := getCfgEntidade(@cError)

		cIdent := RetIdEnti()

		//Se o ltimo caracter da pasta No for barra, ser barra para integridade
		If SubStr(cPasta, Len(cPasta), 1) != "\"
			cPasta += "\"
		EndIf

		//Gera o XML da Nota
		cArquivo := XCNOTA + "_" + dToS(Date()) + "_" + StrTran(Time() + "_" +cValToChar(Randomize(0,999)), ":", "-")

		//Define as perguntas da DANFE
		Pergunte("NFSIGW",.F.)
		MV_PAR01 := PadR(XCNOTA,  nTamNota)     //Nota Inicial
		MV_PAR02 := PadR(XCNOTA,  nTamNota)     //Nota Final
		MV_PAR03 := PadR(XCSERIE, nTamSerie)    //Srie da Nota
		MV_PAR04 := XTIPO                       //NF de Saida
		MV_PAR05 := 2                          //Frente e Verso = Sim
		MV_PAR06 := 2                          //DANFE simplificado = Nao
		MV_PAR07 := XDATA
		MV_PAR08 := XDATA

		//Cria a Danfe
		oDanfe := FWMSPrinter():New(cArquivo, IMP_PDF, .F., cPasta, .T.)

		//Propriedades da DANFE
		oDanfe:SetResolution(78)
		oDanfe:SetPortrait()
		oDanfe:SetPaperSize(DMPAPER_A4)
		oDanfe:SetMargin(60, 60, 60, 60)

		//Fora a impresso em PDF
		oDanfe:nDevice  := 6
		oDanfe:cPathPDF := cPasta
		oDanfe:lServer  := .T.
		oDanfe:lViewPDF := .F.

		//Variveis obrigatrias da DANFE (pode colocar outras abaixo)
		PixelX    := oDanfe:nLogPixelX()
		PixelY    := oDanfe:nLogPixelY()
		nConsNeg  := 0.4
		nConsTex  := 0.5
		oRetNF    := Nil
		nColAux   := 0

		XLDANFORI := .F.

		//Chamando a impresso da danfe no RDMAKE
		U_DANFEPROC(@oDanfe, @lEnd, cIdent, , , .F.) 
		oDanfe:Print()

	EndIf

	dbSelectArea("SM0")
	SM0->(dbSetOrder(1))
	SM0->(RestArea(_aAreaSM0))              //Restaura Tabela
	cFilAnt := ALLTRIM(SM0->M0_CODFIL)      //Restaura variaveis de ambiente
	cEmpAnt := SM0->M0_CODIGO

	oApp := _oAppBk //Backup do componente visual

	RestArea(aArea)
	cReturn := xFileBase64(cPasta +'\'+cArquivo + ".pdf")

Return( cReturn ) 

Static Function xFileBase64(cArquivo)
    Local cConteudo := ""
    Local cString64 := ""
    Local oFile
 
    //Se o arquivo existir
    If File(cArquivo)
 
        //Tenta abrir o arquivo e pegar o conteudo
        oFile := FwFileReader():New(cArquivo)
        If oFile:Open()
 
            //Se deu certo abrir o arquivo, pega o conteudo e transforma em base 64
            cConteudo  := oFile:FullRead()
            cString64  := Encode64(cConteudo, , .F., .F.)
        EndIf
        oFile:Close()
    EndIf
Return cString64
