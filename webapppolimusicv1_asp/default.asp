<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
If IsLoggedIn() Then
    RedirectTo U("home.asp")
Else
    RedirectTo U("login.asp")
End If
%>
