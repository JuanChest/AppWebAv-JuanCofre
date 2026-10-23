<%
' ===========================================================================
'  auth.asp  -  Sesion y control de roles
'     USER_TYPE: 0 = Usuario normal | 1 = Administrador
' ===========================================================================

Function IsLoggedIn()
    IsLoggedIn = (CStr(Session("uid") & "") <> "")
End Function

Function CurrentUserId()
    If IsLoggedIn() Then
        CurrentUserId = CLng(Session("uid"))
    Else
        CurrentUserId = 0
    End If
End Function

Function CurrentUserName()
    CurrentUserName = CStr(Session("uname") & "")
End Function

Function CurrentUserPhoto()
    CurrentUserPhoto = CStr(Session("uphoto") & "")
End Function

Function CurrentUserType()
    If CStr(Session("utype") & "") = "" Then
        CurrentUserType = 0
    Else
        CurrentUserType = CLng(Session("utype"))
    End If
End Function

Function IsAdmin()
    IsAdmin = (IsLoggedIn() And CurrentUserType() = 1)
End Function

Sub LoginUser(idUsuario, nombre, tipo, foto)
    Session("uid")    = CLng(idUsuario)
    Session("uname")  = CStr(nombre)
    Session("utype")  = CLng(tipo)
    Session("uphoto") = CStr(foto & "")
    Session.Timeout   = 60
End Sub

Sub LogoutUser()
    Session.Contents.RemoveAll
    Session.Abandon
End Sub

' Devuelve una URL interna segura para volver despues del login.
Function SafeNext(valor)
    Dim s

    s = CStr(valor & "")
    If s = "" Then
        SafeNext = U("home.asp")
        Exit Function
    End If
    If InStr(s, "://") > 0 Or InStr(s, "\") > 0 Or Left(s, 2) = "//" Then
        SafeNext = U("home.asp")
        Exit Function
    End If
    If Left(s, 1) <> "/" Then s = gBase & s
    If Left(LCase(s), Len(gBase)) <> LCase(gBase) Then
        SafeNext = U("home.asp")
        Exit Function
    End If
    SafeNext = s
End Function

Sub RequireLogin()
    Dim destino

    If Not IsLoggedIn() Then
        destino = Request.ServerVariables("URL")
        If Request.ServerVariables("QUERY_STRING") <> "" Then
            destino = destino & "?" & Request.ServerVariables("QUERY_STRING")
        End If
        RedirectTo U("login.asp") & "?next=" & Server.URLEncode(destino)
    End If
End Sub

Sub RequireAdmin()
    RequireLogin
    If Not IsAdmin() Then
        SetFlash "error", "Necesitas una cuenta de administrador para acceder a esa seccion."
        RedirectTo U("home.asp")
    End If
End Sub
%>
