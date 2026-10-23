<%
' ===========================================================================
'  db.asp  -  Acceso a datos (ADODB + SQL Server)
' ===========================================================================

Dim gConn

' Abre (una sola vez por peticion) la conexion global.
Sub DbOpen()
    Dim msg

    If IsObject(gConn) Then
        If gConn.State = 1 Then Exit Sub
    End If

    On Error Resume Next
    Set gConn = Server.CreateObject("ADODB.Connection")
    gConn.CursorLocation = 3          ' adUseClient: permite varias consultas abiertas
    gConn.Open CONN_STRING
    If Err.Number <> 0 Then
        msg = Err.Description
        Err.Clear
        On Error GoTo 0
        Response.Status = "500 Error de base de datos"
        Response.Write "<!DOCTYPE html><html lang=""es""><meta charset=""utf-8"">" & _
            "<body style=""font-family:system-ui;background:#0b0b0d;color:#f5f5f5;padding:40px"">" & _
            "<h1 style=""color:#ff6b1a"">No se pudo conectar a SQL Server</h1>" & _
            "<p>Revisa que el servicio est&eacute; activo y que la base <strong>BDD_PoliMusic</strong> exista.</p>" & _
            "<pre style=""background:#1b1c20;padding:16px;border-radius:8px;white-space:pre-wrap"">" & _
            Server.HTMLEncode(msg) & "</pre></body></html>"
        Response.End
    End If
    On Error GoTo 0
End Sub

Sub DbClose()
    On Error Resume Next
    If IsObject(gConn) Then
        If gConn.State = 1 Then gConn.Close
        Set gConn = Nothing
    End If
    On Error GoTo 0
End Sub

' Agrega parametros posicionales (?) al comando como nvarchar.
' Los NULL se envian como NULL; el resto viaja como texto y SQL Server
' hace la conversion implicita al tipo de la columna.
Sub DbAddParams(cmd, params)
    Dim i, v, sz

    If Not IsArray(params) Then Exit Sub

    For i = 0 To UBound(params)
        v = params(i)
        If IsNull(v) Then
            cmd.Parameters.Append cmd.CreateParameter("p" & i, adVarWChar, adParamInput, 1, Null)
        Else
            sz = Len(CStr(v))
            If sz = 0 Then sz = 1
            If sz > 4000 Then sz = 4000
            cmd.Parameters.Append cmd.CreateParameter("p" & i, adVarWChar, adParamInput, sz, CStr(v))
        End If
    Next
End Sub

' Devuelve un Recordset (cursor de cliente: no bloquea la conexion).
Function DBQuery(sql, params)
    Dim cmd, rs

    DbOpen
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = gConn
    cmd.CommandType = adCmdText
    cmd.CommandText = sql
    DbAddParams cmd, params

    Set rs = Server.CreateObject("ADODB.Recordset")
    rs.CursorLocation = 3
    rs.Open cmd, , 0, 1              ' adOpenForwardOnly, adLockReadOnly
    Set DBQuery = rs
End Function

' Primera columna de la primera fila (o Empty).
Function Scalar(sql, params)
    Dim rs

    Set rs = DBQuery(sql, params)
    If rs.EOF Then
        Scalar = Empty
    Else
        Scalar = rs.Fields(0).Value
    End If
    rs.Close
    Set rs = Nothing
End Function

' Devuelve un array con los enteros de la primera columna de una consulta.
Function IdsDeConsulta(sql, params)
    Dim rs, n, res()

    Set rs = DBQuery(sql, params)
    n = 0
    ReDim res(0)
    Do Until rs.EOF
        ReDim Preserve res(n)
        res(n) = CLng(rs.Fields(0).Value)
        n = n + 1
        rs.MoveNext
    Loop
    rs.Close
    Set rs = Nothing

    If n = 0 Then
        IdsDeConsulta = Array()
    Else
        ReDim Preserve res(n - 1)
        IdsDeConsulta = res
    End If
End Function

' Ejecuta INSERT / UPDATE / DELETE. Devuelve filas afectadas.
Function RunSql(sql, params)
    Dim cmd, affected

    DbOpen
    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = gConn
    cmd.CommandType = adCmdText
    cmd.CommandText = sql
    DbAddParams cmd, params
    cmd.Execute affected
    RunSql = affected
    Set cmd = Nothing
End Function

' Ejecuta un INSERT y devuelve el IDENTITY generado.
' El SQL debe terminar con: ; SELECT CAST(SCOPE_IDENTITY() AS int) AS NEW_ID
Function InsertId(sql, params)
    Dim rs, v

    Set rs = DBQuery("SET NOCOUNT ON; " & sql & "; SELECT CAST(SCOPE_IDENTITY() AS int) AS NEW_ID", params)
    v = 0
    If Not rs.EOF Then
        If Not IsNull(rs.Fields("NEW_ID").Value) Then v = CLng(rs.Fields("NEW_ID").Value)
    End If
    rs.Close
    Set rs = Nothing
    InsertId = v
End Function
%>
