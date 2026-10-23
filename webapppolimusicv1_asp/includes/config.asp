<%
' ===========================================================================
'  config.asp  -  Configuracion global de PoliMusic
'  Debe incluirse como PRIMER include de cada pagina.
' ===========================================================================
Option Explicit

' --- Base de datos ---------------------------------------------------------
' SQL Server en el puerto por defecto (1433).
Const DB_SERVER   = "localhost,1433"
Const DB_NAME     = "BDD_PoliMusic"
Const DB_USER     = "usr_polimusic"
Const DB_PASSWORD = "Politecnica1"

' VBScript no permite concatenar en Const: se construye una sola vez.
Dim CONN_STRING
CONN_STRING = "Provider=SQLOLEDB;Data Source=" & DB_SERVER & _
              ";Initial Catalog=" & DB_NAME & _
              ";User ID=" & DB_USER & _
              ";Password=" & DB_PASSWORD & _
              ";Persist Security Info=False;"

' --- Aplicacion ------------------------------------------------------------
Const APP_NAME    = "PoliMusic"
Const APP_TAGLINE = "Tu musica, en naranja y negro."
Const UPLOAD_MAX  = 31457280   ' 30 MB por peticion

' --- Constantes ADO (evitamos adovbs.inc) ---------------------------------
Const adCmdText    = 1
Const adParamInput = 1
Const adVarWChar   = 202
Const adInteger    = 3
Const adBigInt     = 20
Const adBoolean    = 11

' --- Codificacion ----------------------------------------------------------
Response.CodePage = 65001
Response.Charset  = "utf-8"
Session.CodePage  = 65001
Response.Expires  = 0

' --- Ruta virtual base de la aplicacion ("/" o "/carpeta/") ----------------
Dim gScriptPath, gBase

gScriptPath = Request.ServerVariables("SCRIPT_NAME")
gBase = Left(gScriptPath, InStrRev(gScriptPath, "/"))
If LCase(Right(gBase, 6)) = "admin/" Then
    gBase = Left(gBase, Len(gBase) - 6)
End If
If gBase = "" Then gBase = "/"
If Right(gBase, 1) <> "/" Then gBase = gBase & "/"

' --- Variables que cada pagina puede sobrescribir antes del layout ---------
Dim PageTitle, NavActive, PageEyebrow

PageTitle   = "Inicio"
NavActive   = "home"
PageEyebrow = "PoliMusic"
%>
