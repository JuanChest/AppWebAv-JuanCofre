<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
Response.ContentType = "application/json"
Response.Charset = "utf-8"
Response.CacheControl = "no-cache"

Dim idCancion, plays

If Not IsLoggedIn() Then
    Response.Status = "401 Unauthorized"
    Response.Write "{""ok"":false,""error"":""sesion""}"
    Response.End
End If

idCancion = GetInt("id", 0)
If idCancion <= 0 Then
    Response.Status = "400 Bad Request"
    Response.Write "{""ok"":false,""error"":""id""}"
    Response.End
End If

RunSql "UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS, 0) + 1 WHERE ID_SONG = ?", Array(idCancion)
plays = CLng(Scalar("SELECT ISNULL(PLAYS, 0) FROM TBL_SONG WHERE ID_SONG = ?", Array(idCancion)))
DbClose

Response.Write "{""ok"":true,""plays"":" & plays & "}"
%>
