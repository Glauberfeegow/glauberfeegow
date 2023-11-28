<%
'======== Alterar para publicar ========
Protocolo = "http://"
URLOrigem = "localhost"
URLDestino = "127.0.0.1"

Protocolo = "https://"
URLOrigem = "app.feegow.com"
URLDestino = "app2.feegow.com"
''======== Alterar para publicar ========

Parametros = request.querystring()
PaginaAtual = req("P")
DiaSemana = weekday(date())
HoraAtual = time()

URLAtual = request.servervariables("SERVER_NAME")

HoraReduzirSemana = cdate("19:30:00")
HoraReduzirSabado = cdate("13:00:00")
UsuarioLogado = session("User")

'Define se está em horário reduzido END
if (DiaSemana=7 and HoraAtual<HoraReduzirSabado) or (DiaSemana<>7 and HoraAtual<HoraReduzirSemana) or DiaSemana=1 then
    HorarioReduzido = 0
else
    HorarioReduzido = 1
end if

'response.write(DiaSemana &"xxx")
'response.end

'1. Se estiver deslogado E (Pagina=Login OU Pagina=Home) E URLAtual=URLDestino E nao for tela de resgate de sessoes SEMPRE vai pro URLOrigem/Login END
if UsuarioLogado="" and (PaginaAtual="Login" or PaginaAtual="Home") and URLAtual=URLDestino and req("RFSS")="" then
    response.redirect(Protocolo & URLOrigem & "/main/?P=Login")
end if
'2. Se o horário for reduzido E no Endereco_Origem E logado E em (tela<>login or tela<>home) SEMPRE guarda as sessões e envia pro captador da URLDestino END
if HorarioReduzido and UsuarioLogado<>"" and URLAtual=URLOrigem and PaginaAtual<>"Login" and PaginaAtual<>"Logout" and PaginaAtual<>"Home" then
    %><!--#include file="./../connectCentral.asp"--><%
    'Apaga lixos anteriores
    dbc.execute("DELETE FROM cliniccentral.temp_sessions WHERE sysUser="& UsuarioLogado)
    'Guarda todas as sessões
    For Each variavel in Session.Contents
        If IsArray(Session(variavel)) then
            For i = LBound(Session(variavel)) to UBound(Session(variavel))
                Response.Write variavel & "(" & i & ") – " & _
                Session(variavel)(i) & "<BR>"
            Next
        Else
            'Response.Write variavel & " :: " & Session.Contents(variavel) & "<BR>"
            NomeSessao = variavel
            ValorSessao = Session.Contents(variavel)
            IsINT = 0
            if not isnull(ValorSessao) then
                if isnumeric(ValorSessao) then
                    if ValorSessao=ccur(ValorSessao) then
                        IsINT = 1
                    end if
                else
                    ValorSessao = replace(ValorSessao, "'", "''")
                end if
            else
                ValorSessao = ""
            end if
            if NomeSessao="AutenticadoPHP" then
                ValorSessao = "false" 'force new php session
            end if
            
            dbc.execute("INSERT INTO cliniccentral.temp_sessions SET sysUser="& UsuarioLogado &", NomeSessao='"& NomeSessao &"', ValorSessao='"& ValorSessao &"', IsINT="& IsINT)
        End If
    Next
    set getPasta = dbc.execute("SELECT PastaAplicacao FROM cliniccentral.licencas WHERE id="& replace(session("Banco"), "clinic", ""))
    if not getPasta.eof then
        PastaAplicacao = getPasta("PastaAplicacao")
    end if
    'Grava a página atual
    dbc.execute("INSERT INTO cliniccentral.temp_sessions SET sysUser="& UsuarioLogado &", NomeSessao='RFSS', ValorSessao='"& request.QueryString() &"'")
    %><!--#include file="./../disconnect.asp"--><%

    'Guarda a página e os parâmetros
    'Redireciona para o captador de sessões no destino
    Destino = Protocolo & URLDestino &"/"& PastaAplicacao &"/?P=Logout&RFSS="& UsuarioLogado
    response.write("Agora vai redirecionar para: "& Destino &" .........")
    'response.end
    session.abandon()
    response.redirect(Destino)

end if

'3. Se estiver no captador da URLDestino, recupera as sessões e manda pra página correta
if req("RFSS")<>"" then
    'Restaurando as sessões
    %><!--#include file="./../connectCentral.asp"--><%

    'Adquire as sessoes no novo servidor
    set ses = dbc.execute("SELECT * FROM cliniccentral.temp_sessions WHERE sysUser="& req("RFSS"))
    while not ses.eof
        ValorSessao = ses("ValorSessao")
        if ses("NomeSessao")<>"RFSS" then
            if ses("IsINT")=1 and isnumeric(ValorSessao) then
                session(ses("NomeSessao")) = ccur(ValorSessao)
            else
                session(ses("NomeSessao")) = ValorSessao
            end if
        else
            RedirecionarPara = ValorSessao
        end if
    ses.movenext
    wend
    ses.close
    set ses = nothing
    'Envia pra página correta
    session("AutenticadoPHP")="false"
    dbc.execute("DELETE FROM cliniccentral.temp_sessions WHERE sysUser="& req("RFSS"))

    if RedirecionarPara<>"" then
        'response.Write("{{{"& RedirecionarPara &"}}}")
        'response.end
        response.redirect("./?"& RedirecionarPara)
    end if
    %><!--#include file="./../disconnect.asp"--><%
    'depois de recuperar já destroi do server
end if
%>