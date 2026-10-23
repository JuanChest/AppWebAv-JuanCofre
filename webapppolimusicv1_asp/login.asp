<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
Dim errorMsg, infoMsg, usuario, clave, rs, destino
Dim uid, uname, utype, uphoto

errorMsg = ""
infoMsg = ""
If GetStr("bye") = "1" Then infoMsg = "Tu sesión se cerró correctamente. ¡Hasta la próxima!"
destino = SafeNext("")
If GetStr("next") <> "" Then
    destino = SafeNext(GetStr("next"))
ElseIf CStr(Request.Form("next") & "") <> "" Then
    destino = SafeNext(Request.Form("next"))
End If

If IsLoggedIn() Then RedirectTo destino

If IsPost() Then
    usuario = PostStr("username")
    clave = PostStr("password")

    If usuario = "" Or clave = "" Then
        errorMsg = "Escribe tu usuario y tu contraseña."
    Else
        Set rs = DBQuery("SELECT TOP 1 ID_USER, USERNAME, USER_TYPE, USER_PHOTO " & _
                    "FROM TBL_USER " & _
                    "WHERE USERNAME = ? AND (PASSWORD = ? OR PASSWORD = UPPER(CONVERT(varchar(40), HASHBYTES('SHA1', CONVERT(varchar(50), ?)), 2)))", _
                    Array(usuario, clave, clave))

        If rs.EOF Then
            errorMsg = "Usuario o contraseña incorrectos."
        Else
            uid = rs("ID_USER")
            uname = rs("USERNAME")
            utype = rs("USER_TYPE")
            uphoto = rs("USER_PHOTO")
            rs.Close
            Set rs = Nothing

            LoginUser uid, uname, utype, uphoto
            SetFlash "ok", "¡Bienvenido de nuevo, " & uname & "!"
            DbClose
            RedirectTo destino
        End If

        If IsObject(rs) Then
            If rs.State = 1 Then rs.Close
            Set rs = Nothing
        End If
    End If
End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Iniciar sesión &middot; PoliMusic</title>
<link rel="stylesheet" href="<%= U("css/app.css") %>">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%23ff6b1a'/%3E%3Cpath d='M18 40V24M26 46V18M34 38V26M42 44V20M50 34V30' stroke='%230b0b0d' stroke-width='5' stroke-linecap='round'/%3E%3C/svg%3E">
</head>
<body>
<div class="auth">

    <section class="auth-art">
        <div class="auth-brand">
            <span class="brand-mark" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i></span>
            <span>
                <strong>Poli<span>Music</span></strong>
                <small>streaming club</small>
            </span>
        </div>

        <div class="auth-hero">
            <h1>Tu catálogo.<br>Tu ritmo.<br><em>Todo en naranja.</em></h1>
            <p>Escucha el Song List completo, arma tus playlists y, si eres administrador, gestiona canciones, álbumes y artistas desde un solo lugar.</p>
            <div class="auth-tags">
                <span class="auth-tag">2 roles</span>
                <span class="auth-tag">Reproductor integrado</span>
                <span class="auth-tag">Playlists personales</span>
                <span class="auth-tag">CRUD de catálogo</span>
            </div>
        </div>

        <div class="auth-art-foot">
            <span class="brand-mark" style="width:26px;height:26px;padding:6px 5px;border-radius:8px;" aria-hidden="true"><i></i><i></i><i></i><i></i><i></i></span>
            <span>PoliMusic &middot; ASP clásico + SQL Server</span>
        </div>
        <div class="auth-disc" aria-hidden="true"></div>
    </section>

    <section class="auth-panel">
        <div class="auth-card">
            <h2>Bienvenido</h2>
            <p>Inicia sesión para entrar a tu biblioteca musical.</p>

            <% If infoMsg <> "" Then %>
            <div class="flash flash-info" style="margin-bottom:18px;">
                <span class="flash-icon">i</span><span><%= H(infoMsg) %></span>
            </div>
            <% End If %>

            <% If errorMsg <> "" Then %>
            <div class="error-box" role="alert">
                <span class="flash-icon" style="background:rgba(255,77,61,.15);color:#ff4d3d;">!</span>
                <span><%= H(errorMsg) %></span>
            </div>
            <% End If %>

            <form method="post" action="<%= U("login.asp") %>" autocomplete="on">
                <input type="hidden" name="next" value="<%= H(destino) %>">

                <div class="field">
                    <label for="username">Usuario</label>
                    <input type="text" id="username" name="username" value="<%= H(usuario) %>"
                           placeholder="userNormal" maxlength="50" required autofocus>
                </div>

                <div class="field">
                    <label for="password">Contraseña</label>
                    <input type="password" id="password" name="password" placeholder="••••••••" maxlength="50" required>
                </div>

                <button type="submit" class="btn btn-primary btn-block">
                    Entrar <%= Icon("chevron") %>
                </button>
            </form>

            <div class="auth-divider">Cuentas de prueba</div>
            <div class="demo-box">
                <span>Usuario normal: <code>userNormal</code> / <code>12345678</code></span>
                <span>Administrador: <code>userAdmin</code> / <code>12345678</code></span>
            </div>
        </div>
    </section>
</div>
<%
DbClose
%>
</body>
</html>
