<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
LogoutUser
RedirectTo U("login.asp") & "?bye=1"
%>
