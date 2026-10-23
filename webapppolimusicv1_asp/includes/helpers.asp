<%
' ===========================================================================
'  helpers.asp  -  Utilidades de presentacion y peticion
' ===========================================================================

Dim gFso

' --- Salida ----------------------------------------------------------------
Function H(v)
    H = Server.HTMLEncode(CStr(v & ""))
End Function

' Convierte una ruta de la BD ("~/songFiles/x.mp3") en URL de la aplicacion.
Function U(path)
    Dim p

    p = CStr(path & "")
    If Left(p, 2) = "~/" Then p = Mid(p, 3)
    If Left(p, 1) = "/" Then p = Mid(p, 2)
    U = gBase & p
End Function

Function AssetExists(path)
    Dim p

    AssetExists = False
    p = CStr(path & "")
    If p = "" Then Exit Function
    If IsEmpty(gFso) Or Not IsObject(gFso) Then Set gFso = Server.CreateObject("Scripting.FileSystemObject")

    On Error Resume Next
    AssetExists = gFso.FileExists(Server.MapPath(U(p)))
    If Err.Number <> 0 Then
        Err.Clear
        AssetExists = False
    End If
    On Error GoTo 0
End Function

' Portada de cancion / album con respaldo tipografico si falta el archivo.
Function CoverHtml(path, titulo, clase)
    Dim letra, cls

    cls = "cover " & clase
    If AssetExists(path) Then
        CoverHtml = "<img class=""" & cls & """ src=""" & H(U(path)) & """ alt=""" & H(titulo) & """ loading=""lazy"">"
    Else
        letra = UCase(Left(Trim(titulo & ""), 1))
        If letra = "" Then letra = "?"
        CoverHtml = "<span class=""" & cls & " cover-tile"" aria-hidden=""true"">" & H(letra) & "</span>"
    End If
End Function

' Avatar de artista / usuario.
Function AvatarHtml(path, titulo, clase)
    Dim letra

    If AssetExists(path) Then
        AvatarHtml = "<img class=""" & clase & """ src=""" & H(U(path)) & """ alt=""" & H(titulo) & """ loading=""lazy"">"
    Else
        letra = UCase(Left(Trim(titulo & ""), 1))
        If letra = "" Then letra = "?"
        AvatarHtml = "<span class=""" & clase & " avatar-tile"" aria-hidden=""true"">" & H(letra) & "</span>"
    End If
End Function

' --- Peticion --------------------------------------------------------------
Function IsPost()
    IsPost = (UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST")
End Function

Function PostStr(nombre)
    PostStr = Trim(CStr(Request.Form(nombre) & ""))
End Function

Function PostInt(nombre, porDefecto)
    Dim v

    v = PostStr(nombre)
    If IsNumeric(v) Then
        PostInt = CLng(v)
    Else
        PostInt = porDefecto
    End If
End Function

Function GetInt(nombre, porDefecto)
    Dim v

    v = Trim(CStr(Request.QueryString(nombre) & ""))
    If IsNumeric(v) Then
        GetInt = CLng(v)
    Else
        GetInt = porDefecto
    End If
End Function

Function GetStr(nombre)
    GetStr = Trim(CStr(Request.QueryString(nombre) & ""))
End Function

' Lista de IDs enviada en un campo repetido ("3,7,9") -> array de Long.
Function IdList(valor)
    Dim partes, i, n, res(), k

    If Trim(valor & "") = "" Then
        IdList = Array()
        Exit Function
    End If

    partes = Split(valor, ",")
    n = 0
    ReDim res(0)
    For i = 0 To UBound(partes)
        k = Trim(partes(i))
        If IsNumeric(k) Then
            If CLng(k) > 0 Then
                ReDim Preserve res(n)
                res(n) = CLng(k)
                n = n + 1
            End If
        End If
    Next

    If n = 0 Then
        IdList = Array()
    Else
        ReDim Preserve res(n - 1)
        IdList = res
    End If
End Function

Function InIdList(lista, valor)
    Dim i

    InIdList = False
    If Not IsArray(lista) Then Exit Function
    For i = 0 To UBound(lista)
        If CLng(lista(i)) = CLng(valor) Then
            InIdList = True
            Exit Function
        End If
    Next
End Function

Function LikeTerm(q)
    Dim s

    s = Replace(q & "", "[", "[[]")
    s = Replace(s, "%", "[%]")
    s = Replace(s, "_", "[_]")
    LikeTerm = "%" & s & "%"
End Function

Sub RedirectTo(url)
    Response.Redirect url
    Response.End
End Sub

' --- Mensajes flash (sobreviven a un redirect) ----------------------------
Sub SetFlash(tipo, mensaje)
    Session("flash_tipo") = tipo
    Session("flash_msg") = mensaje
End Sub

Sub ShowFlash()
    Dim tipo, msg, icono

    tipo = CStr(Session("flash_tipo") & "")
    msg = CStr(Session("flash_msg") & "")
    Session("flash_tipo") = ""
    Session("flash_msg") = ""

    If msg = "" Then Exit Sub
    If tipo <> "ok" And tipo <> "error" And tipo <> "info" Then tipo = "info"

    icono = "i"
    If tipo = "ok" Then icono = "&#10003;"
    If tipo = "error" Then icono = "!"

    Response.Write "<div class=""flash flash-" & tipo & """ role=""status"">" & _
                   "<span class=""flash-icon"">" & icono & "</span>" & _
                   "<span>" & H(msg) & "</span>" & _
                   "<button type=""button"" class=""flash-close"" aria-label=""Cerrar"">&times;</button>" & _
                   "</div>"
End Sub

' --- Textos ---------------------------------------------------------------
Function RoleName(tipo)
    If CLng(tipo) = 1 Then
        RoleName = "Administrador"
    Else
        RoleName = "Usuario"
    End If
End Function

Function PlaylistTypeName(tipo)
    If CLng(tipo) = 1 Then
        PlaylistTypeName = "Privada"
    Else
        PlaylistTypeName = "Publica"
    End If
End Function

Function HumanDate(v)
    If IsNull(v) Or v = "" Then
        HumanDate = "-"
    Else
        On Error Resume Next
        HumanDate = Right("0" & Day(v), 2) & "/" & Right("0" & Month(v), 2) & "/" & Year(v)
        If Err.Number <> 0 Then
            Err.Clear
            HumanDate = "-"
        End If
        On Error GoTo 0
    End If
End Function

Function ShortText(v, n)
    Dim s

    s = CStr(v & "")
    If Len(s) > n Then
        ShortText = Left(s, n - 1) & "..."
    Else
        ShortText = s
    End If
End Function

Function Plural(n, singular, pluralTxt)
    If CLng(n) = 1 Then
        Plural = n & " " & singular
    Else
        Plural = n & " " & pluralTxt
    End If
End Function

' Pequeño equivalente a IIf (VBScript no lo trae de serie).
Function IfElse(condicion, siVerdadero, siFalso)
    If condicion Then
        IfElse = siVerdadero
    Else
        IfElse = siFalso
    End If
End Function

' Borra un archivo del disco a partir de una ruta tipo "~/carpeta/archivo.ext".
Sub EliminarArchivoFisico(ruta)
    Dim fso, fisica

    If CStr(ruta & "") = "" Then Exit Sub
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    On Error Resume Next
    fisica = Server.MapPath(U(ruta))
    If fso.FileExists(fisica) Then fso.DeleteFile fisica, True
    If Err.Number <> 0 Then Err.Clear
    On Error GoTo 0
End Sub

' --- Iconografia (SVG en linea, sin dependencias) --------------------------
Function Icon(nombre)
    Dim ini, fin

    ini = "<svg class=""icon"" viewBox=""0 0 24 24"" fill=""none"" stroke=""currentColor"" stroke-width=""1.7"" stroke-linecap=""round"" stroke-linejoin=""round"" aria-hidden=""true"">"
    fin = "</svg>"

    Select Case LCase(nombre)
        Case "home"
            Icon = ini & "<path d=""M3 10.7 12 3l9 7.7V20a1 1 0 0 1-1 1h-5.2v-6.4H9.2V21H4a1 1 0 0 1-1-1z""/>" & fin
        Case "playlist"
            Icon = ini & "<path d=""M4 6h10M4 11h10M4 16h6""/><circle cx=""17.5"" cy=""16.5"" r=""3.2""/><path d=""M20.7 16.5V8l-2.4 1""/>" & fin
        Case "album"
            Icon = ini & "<circle cx=""12"" cy=""12"" r=""8.5""/><circle cx=""12"" cy=""12"" r=""2.2""/><path d=""M12 3.5v3""/>" & fin
        Case "artist"
            Icon = ini & "<circle cx=""12"" cy=""8"" r=""3.4""/><path d=""M5 20.2c.7-3.4 3.6-5.4 7-5.4s6.3 2 7 5.4""/>" & fin
        Case "music"
            Icon = ini & "<path d=""M9 18V6.5l10-2V16""/><circle cx=""6.5"" cy=""18"" r=""2.6""/><circle cx=""16.5"" cy=""16"" r=""2.6""/>" & fin
        Case "logout"
            Icon = ini & "<path d=""M14 4h4a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2h-4""/><path d=""M10 8l-4 4 4 4M6 12h9""/>" & fin
        Case "play"
            Icon = "<svg class=""icon"" viewBox=""0 0 24 24"" fill=""currentColor"" aria-hidden=""true""><path d=""M8 5.2v13.6L19 12z""/></svg>"
        Case "pause"
            Icon = "<svg class=""icon"" viewBox=""0 0 24 24"" fill=""currentColor"" aria-hidden=""true""><rect x=""6"" y=""5"" width=""4"" height=""14"" rx=""1""/><rect x=""14"" y=""5"" width=""4"" height=""14"" rx=""1""/></svg>"
        Case "next"
            Icon = "<svg class=""icon"" viewBox=""0 0 24 24"" fill=""currentColor"" aria-hidden=""true""><path d=""M5 5.5v13L15 12z""/><rect x=""16.5"" y=""5"" width=""2.5"" height=""14"" rx=""1""/></svg>"
        Case "prev"
            Icon = "<svg class=""icon"" viewBox=""0 0 24 24"" fill=""currentColor"" aria-hidden=""true""><path d=""M19 5.5v13L9 12z""/><rect x=""5"" y=""5"" width=""2.5"" height=""14"" rx=""1""/></svg>"
        Case "search"
            Icon = ini & "<circle cx=""11"" cy=""11"" r=""6.5""/><path d=""m16 16 4.2 4.2""/>" & fin
        Case "plus"
            Icon = ini & "<path d=""M12 5v14M5 12h14""/>" & fin
        Case "trash"
            Icon = ini & "<path d=""M4 7h16M9 7V4.8h6V7M6.5 7l.8 12.2a1 1 0 0 0 1 .8h7.4a1 1 0 0 0 1-.8L17.5 7M10 11v5M14 11v5""/>" & fin
        Case "edit"
            Icon = ini & "<path d=""M4 20h4.2L19 9.2a2.1 2.1 0 0 0-3-3L5 17.2z""/><path d=""M14.5 6.5l3 3""/>" & fin
        Case "menu"
            Icon = ini & "<path d=""M4 7h16M4 12h16M4 17h16""/>" & fin
        Case "close"
            Icon = ini & "<path d=""M6 6l12 12M18 6 6 18""/>" & fin
        Case "volume"
            Icon = ini & "<path d=""M4 10v4h3l4 3.5v-11L7 10z""/><path d=""M15 9.2a4 4 0 0 1 0 5.6M17.6 6.8a7.5 7.5 0 0 1 0 10.4""/>" & fin
        Case "mute"
            Icon = ini & "<path d=""M4 10v4h3l4 3.5v-11L7 10z""/><path d=""M15.5 10l4 4M19.5 10l-4 4""/>" & fin
        Case "check"
            Icon = ini & "<path d=""m5 12.5 4.5 4.5L19 6.5""/>" & fin
        Case "alert"
            Icon = ini & "<path d=""M12 4 2.8 20h18.4z""/><path d=""M12 9v4.5M12 16.8v.2""/>" & fin
        Case "info"
            Icon = ini & "<circle cx=""12"" cy=""12"" r=""8.5""/><path d=""M12 11v5M12 7.8v.2""/>" & fin
        Case "clock"
            Icon = ini & "<circle cx=""12"" cy=""12"" r=""8.5""/><path d=""M12 7.5V12l3 2""/>" & fin
        Case "spark"
            Icon = ini & "<path d=""M12 3.5 13.8 9l5.7 1.8-5.7 1.8L12 18.2 10.2 12.6 4.5 10.8 10.2 9z""/>" & fin
        Case "chevron"
            Icon = ini & "<path d=""m9 6 6 6-6 6""/>" & fin
        Case "headphones"
            Icon = ini & "<path d=""M4 14v-2a8 8 0 0 1 16 0v2""/><path d=""M4 14h3v6H5.5A1.5 1.5 0 0 1 4 18.5zM20 14h-3v6h1.5a1.5 1.5 0 0 0 1.5-1.5z""/>" & fin
        Case Else
            Icon = ini & "<circle cx=""12"" cy=""12"" r=""7""/>" & fin
    End Select
End Function
%>
