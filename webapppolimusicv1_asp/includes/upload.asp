<%
' ===========================================================================
'  upload.asp  -  Lectura de formularios multipart y guardado de archivos
'
'  Estrategia: el cuerpo completo se guarda en un ADODB.Stream BINARIO.
'  Para localizar las partes se lee una copia de texto (1 byte = 1 posicion),
'  y los bytes de cada campo/archivo se extraen con CopyTo desde el stream
'  binario original. Asi los archivos se guardan sin ninguna perdida.
' ===========================================================================

Dim gForm, gFiles, gMultipartListo, gUploadError, gRawStream

Dim CRLF
CRLF = vbCrLf

Sub ParseMultipart()
    Dim ct, boundary, pos, body, st, delim, delimPos, after, headerEnd
    Dim headers, cStart, nextDelim, cLen, re, coinc
    Dim nombre, nombreArchivo, tipoArchivo, valor

    If gMultipartListo Then Exit Sub
    gMultipartListo = True
    gUploadError = ""

    Set gForm  = Server.CreateObject("Scripting.Dictionary")
    Set gFiles = Server.CreateObject("Scripting.Dictionary")
    gForm.CompareMode  = 1
    gFiles.CompareMode = 1

    ct = CStr(Request.ServerVariables("CONTENT_TYPE") & "")
    If InStr(LCase(ct), "multipart/form-data") = 0 Then Exit Sub
    If Request.TotalBytes = 0 Then Exit Sub

    pos = InStr(LCase(ct), "boundary=")
    If pos = 0 Then Exit Sub
    boundary = Trim(Mid(ct, pos + 9))
    If InStr(boundary, ";") > 0 Then boundary = Left(boundary, InStr(boundary, ";") - 1)
    boundary = Trim(boundary)
    If Left(boundary, 1) = """" Then boundary = Mid(boundary, 2)
    If Right(boundary, 1) = """" Then boundary = Left(boundary, Len(boundary) - 1)
    If boundary = "" Then Exit Sub

    ' --- Cuerpo binario original -----------------------------------------
    Set gRawStream = Server.CreateObject("ADODB.Stream")
    gRawStream.Type = 1
    gRawStream.Open
    gRawStream.Write Request.BinaryRead(Request.TotalBytes)
    gRawStream.Position = 0

    ' --- Copia de texto solo para localizar limites (1 byte = 1 posicion) -
    Set st = Server.CreateObject("ADODB.Stream")
    st.Type = 1
    st.Open
    gRawStream.CopyTo st
    st.Position = 0
    st.Type = 2
    st.Charset = "iso-8859-1"
    body = st.ReadText
    st.Close
    Set st = Nothing

    Set re = Server.CreateObject("VBScript.RegExp")
    re.Global = False
    re.IgnoreCase = True

    delim = "--" & boundary
    delimPos = InStr(1, body, delim)

    Do While delimPos > 0
        after = delimPos + Len(delim)

        ' Delimitador final: --boundary--
        If Mid(body, after, 2) = "--" Then Exit Do

        If Mid(body, after, 2) = CRLF Then after = after + 2

        headerEnd = InStr(after, body, CRLF & CRLF)
        If headerEnd = 0 Then Exit Do

        headers = ReadUtf8Slice(after, headerEnd - after)
        cStart  = headerEnd + 4

        nextDelim = InStr(cStart, body, CRLF & delim)
        If nextDelim = 0 Then Exit Do

        cLen = nextDelim - cStart

        nombre = ""
        nombreArchivo = ""
        tipoArchivo = ""

        re.Pattern = "name=""([^""]*)"""
        Set coinc = re.Execute(headers)
        If coinc.Count > 0 Then nombre = coinc(0).SubMatches(0)

        re.Pattern = "filename=""([^""]*)"""
        Set coinc = re.Execute(headers)
        If coinc.Count > 0 Then nombreArchivo = coinc(0).SubMatches(0)

        re.Pattern = "Content-Type:\s*([^\r\n]+)"
        Set coinc = re.Execute(headers)
        If coinc.Count > 0 Then tipoArchivo = Trim(coinc(0).SubMatches(0))

        If nombre <> "" Then
            If InStrRev(nombreArchivo, "\") > 0 Then
                nombreArchivo = Mid(nombreArchivo, InStrRev(nombreArchivo, "\") + 1)
            End If
            If InStrRev(nombreArchivo, "/") > 0 Then
                nombreArchivo = Mid(nombreArchivo, InStrRev(nombreArchivo, "/") + 1)
            End If

            If nombreArchivo = "" Then
                valor = ReadUtf8Slice(cStart, cLen)
                If gForm.Exists(nombre) Then
                    gForm(nombre) = gForm(nombre) & "," & valor
                Else
                    gForm(nombre) = valor
                End If
            Else
                If gFiles.Exists(nombre) Then gFiles.Remove nombre
                gFiles.Add nombre, Array(nombreArchivo, tipoArchivo, cStart, cLen)
            End If
        End If

        delimPos = nextDelim + 2
    Loop
End Sub

' Extrae [inicio, longitud] del cuerpo binario y devuelve el Stream (binario).
Function RawSlice(inicio, longitud)
    Dim tmp

    Set tmp = Server.CreateObject("ADODB.Stream")
    tmp.Type = 1
    tmp.Open
    If longitud > 0 Then
        gRawStream.Position = inicio - 1
        gRawStream.CopyTo tmp, longitud
    End If
    Set RawSlice = tmp
End Function

' Extrae un fragmento de texto UTF-8 a partir de sus bytes originales.
Function ReadUtf8Slice(inicio, longitud)
    Dim tmp

    If longitud <= 0 Then
        ReadUtf8Slice = ""
        Exit Function
    End If

    Set tmp = RawSlice(inicio, longitud)
    tmp.Position = 0
    tmp.Type = 2
    tmp.Charset = "utf-8"
    ReadUtf8Slice = tmp.ReadText
    tmp.Close
    Set tmp = Nothing
End Function

Function MF(nombre)
    If Not IsObject(gForm) Then MF = "" : Exit Function
    If gForm.Exists(nombre) Then
        MF = Trim(CStr(gForm(nombre) & ""))
    Else
        MF = ""
    End If
End Function

Function MFInt(nombre, porDefecto)
    Dim v

    v = MF(nombre)
    If IsNumeric(v) Then
        MFInt = CLng(v)
    Else
        MFInt = porDefecto
    End If
End Function

Function MFList(nombre)
    MFList = IdList(MF(nombre))
End Function

Function HasFile(nombre)
    Dim f

    HasFile = False
    If Not IsObject(gFiles) Then Exit Function
    If Not gFiles.Exists(nombre) Then Exit Function
    f = gFiles(nombre)
    HasFile = (CStr(f(0)) <> "" And CLng(f(3)) > 0)
End Function

Function FileSizeBytes(nombre)
    Dim f

    FileSizeBytes = 0
    If Not IsObject(gFiles) Then Exit Function
    If Not gFiles.Exists(nombre) Then Exit Function
    f = gFiles(nombre)
    FileSizeBytes = CLng(f(3))
End Function

Function SanitizeFileName(s)
    Dim i, c, res, prevDash

    res = ""
    prevDash = False
    s = LCase(Trim(s & ""))
    For i = 1 To Len(s)
        c = Mid(s, i, 1)
        If (c >= "a" And c <= "z") Or (c >= "0" And c <= "9") Then
            res = res & c
            prevDash = False
        ElseIf c = " " Or c = "-" Or c = "_" Then
            If Not prevDash And Len(res) > 0 Then
                res = res & "-"
                prevDash = True
            End If
        End If
    Next
    If Right(res, 1) = "-" Then res = Left(res, Len(res) - 1)
    If res = "" Then res = "archivo"
    SanitizeFileName = res
End Function

' Guarda el archivo del campo indicado. Devuelve la ruta tipo "~/carpeta/archivo.ext"
' o "" si no se subio nada. En caso de error deja el mensaje en errMsg.
Function SaveUpload(field, carpeta, extensiones, maxBytes, ByRef errMsg)
    Dim f, original, ext, base, nombre, fisica, src, dst, inicio, longitud

    SaveUpload = ""
    If Not HasFile(field) Then Exit Function

    f = gFiles(field)
    original = CStr(f(0))
    inicio = CLng(f(2))
    longitud = CLng(f(3))

    ext = ""
    If InStrRev(original, ".") > 0 Then ext = LCase(Mid(original, InStrRev(original, ".")))

    If InStr("," & LCase(extensiones) & ",", "," & Mid(ext, 2) & ",") = 0 Then
        errMsg = "Formato no permitido (" & ext & "). Usa: " & extensiones & "."
        Exit Function
    End If

    If longitud > maxBytes Then
        errMsg = "El archivo supera el limite de " & FormatNumber(maxBytes / 1048576, 0) & " MB."
        Exit Function
    End If

    base = original
    If InStrRev(base, ".") > 0 Then base = Left(base, InStrRev(base, ".") - 1)

    Randomize
    nombre = SanitizeFileName(base) & "-" & _
             Year(Now) & Right("0" & Month(Now), 2) & Right("0" & Day(Now), 2) & "-" & _
             Right("0" & Hour(Now), 2) & Right("0" & Minute(Now), 2) & Right("0" & Second(Now), 2) & "-" & _
             CStr(Int(Rnd * 900) + 100) & ext

    fisica = Server.MapPath(gBase & carpeta & "/" & nombre)

    On Error Resume Next
    Set dst = Server.CreateObject("ADODB.Stream")
    dst.Type = 1
    dst.Open

    gRawStream.Position = inicio - 1
    gRawStream.CopyTo dst, longitud
    dst.SaveToFile fisica, 2
    dst.Close
    Set dst = Nothing

    If Err.Number <> 0 Then
        errMsg = "No se pudo guardar el archivo: " & Err.Description
        Err.Clear
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0

    SaveUpload = "~/" & carpeta & "/" & nombre
End Function

' Lista los archivos de una carpeta (para reutilizar assets existentes).
Function ListFolder(carpeta, extensiones)
    Dim fso, carpetaFisica, f, res(), n, ext

    Set fso = Server.CreateObject("Scripting.FileSystemObject")

    On Error Resume Next
    carpetaFisica = Server.MapPath(gBase & carpeta)
    On Error GoTo 0

    n = 0
    ReDim res(0)

    If fso.FolderExists(carpetaFisica) Then
        For Each f In fso.GetFolder(carpetaFisica).Files
            ext = LCase(fso.GetExtensionName(f.Name))
            If InStr("," & LCase(extensiones) & ",", "," & ext & ",") > 0 Then
                ReDim Preserve res(n)
                res(n) = f.Name
                n = n + 1
            End If
        Next
    End If

    If n = 0 Then
        ListFolder = Array()
    Else
        ReDim Preserve res(n - 1)
        ListFolder = res
    End If
End Function
%>
