<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<!--#include file="includes/upload.asp"-->
<%
RequireLogin

Dim idP, esEdicion, rs, errorMsg, errUp, nuevoFoto
Dim titulo, tipoP, foto, fotoAnterior, uid

uid = CurrentUserId()
errorMsg = ""
errUp = ""
nuevoFoto = ""
idP = GetInt("id", 0)
esEdicion = False
titulo = ""
tipoP = 0
foto = "~/playlistImages/default.jpg"

' --- Cargar playlist si se esta editando --------------------------------
If idP > 0 Then
    Set rs = DBQuery("SELECT ID_PLAYLIST, ID_USER, TITLE, TYPE, PHOTO FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ? AND ID_USER = ?", _
                Array(idP, uid))
    If rs.EOF Then
        rs.Close
        Set rs = Nothing
        SetFlash "error", "La playlist no existe o no te pertenece."
        DbClose
        RedirectTo U("playlists.asp")
    End If
    esEdicion = True
    titulo = CStr(rs("TITLE").Value)
    tipoP = CLng(rs("TYPE").Value)
    foto = CStr(rs("PHOTO").Value & "")
    If foto = "" Then foto = "~/playlistImages/default.jpg"
    rs.Close
    Set rs = Nothing
End If

' --- Guardar ------------------------------------------------------------
If IsPost() Then
    If Request.TotalBytes > UPLOAD_MAX Then
        errorMsg = "El archivo es demasiado grande. El máximo permitido es 30 MB."
    Else
        ParseMultipart
        idP = MFInt("id", idP)
        esEdicion = (idP > 0)
        titulo = MF("title")
        tipoP = MFInt("type", 0)

        If Len(titulo) = 0 Then
            errorMsg = "El título de la playlist es obligatorio."
        ElseIf Len(titulo) > 50 Then
            errorMsg = "El título no puede superar los 50 caracteres."
        End If

        If tipoP <> 0 And tipoP <> 1 Then tipoP = 0

        If errorMsg = "" Then
            If HasFile("photo") Then
                nuevoFoto = SaveUpload("photo", "playlistImages", "jpg,jpeg,png,webp,gif", 5242880, errUp)
                If errUp <> "" Then errorMsg = errUp
            End If
        End If

        If errorMsg = "" Then
            If esEdicion Then
                fotoAnterior = foto
                If nuevoFoto <> "" Then foto = nuevoFoto
                RunSql "UPDATE TBL_PLAYLIST SET TITLE = ?, [TYPE] = ?, PHOTO = ? WHERE ID_PLAYLIST = ? AND ID_USER = ?", _
                       Array(titulo, tipoP, foto, idP, uid)
                If nuevoFoto <> "" And LCase(fotoAnterior) <> LCase(nuevoFoto) Then
                    If Left(LCase(fotoAnterior), 17) = "~/playlistimages/" And LCase(fotoAnterior) <> "~/playlistimages/default.jpg" Then
                        If CLng(Scalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE PHOTO = ?", Array(fotoAnterior))) = 0 Then
                            EliminarArchivoFisico fotoAnterior
                        End If
                    End If
                End If
                SetFlash "ok", "Playlist actualizada correctamente."
            Else
                If nuevoFoto <> "" Then foto = nuevoFoto
                idP = InsertId("INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, [TYPE], PHOTO) VALUES (?, ?, GETDATE(), ?, ?)", _
                               Array(uid, titulo, tipoP, foto))
                SetFlash "ok", "Playlist creada. ¡Ahora agrega tus canciones!"
            End If
            DbClose
            RedirectTo U("playlist.asp") & "?id=" & idP
        End If
    End If
End If

PageTitle = IfElse(esEdicion, "Editar playlist", "Nueva playlist")
PageEyebrow = "Playlists personales"
NavActive = "playlists"
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="panel">
        <div class="panel-head">
            <div>
                <h2><%= IfElse(esEdicion, "Editar playlist", "Crear una playlist") %></h2>
                <p>Las playlists son personales: solo tú puedes verlas y modificarlas.</p>
            </div>
            <div class="section-actions">
                <a class="btn btn-ghost btn-sm" href="<%= U("playlists.asp") %>">Volver</a>
            </div>
        </div>

        <div class="panel-body">
            <% If errorMsg <> "" Then %>
            <div class="flash flash-error" role="alert">
                <span class="flash-icon">!</span><span><%= H(errorMsg) %></span>
            </div>
            <% End If %>

            <form method="post" enctype="multipart/form-data"
                  action="<%= U("playlist-form.asp") %>?id=<%= idP %>">
                <input type="hidden" name="id" value="<%= idP %>">

                <div class="form-grid">
                    <div class="field field-full">
                        <label for="title">Título de la playlist</label>
                        <input type="text" id="title" name="title" maxlength="50" required
                               value="<%= H(titulo) %>" placeholder="Ej. Road trip al sol">
                    </div>

                    <div class="field field-full">
                        <span class="field-label">Privacidad</span>
                        <div class="radio-row">
                            <label class="radio-card">
                                <input type="radio" name="type" value="0" <%= IfElse(tipoP = 0, "checked", "") %>>
                                <strong>Pública</strong>
                                <small>Visible para el resto de la comunidad.</small>
                            </label>
                            <label class="radio-card">
                                <input type="radio" name="type" value="1" <%= IfElse(tipoP = 1, "checked", "") %>>
                                <strong>Privada</strong>
                                <small>Solo tú puedes abrirla.</small>
                            </label>
                        </div>
                    </div>

                    <div class="field field-full">
                        <span class="field-label">Portada</span>
                        <div class="flex items-center gap-3 flex-wrap">
                            <%= CoverHtml(foto, titulo, "cover") %>
                            <div class="file-drop" style="flex:1;">
                                <input type="file" name="photo" accept=".jpg,.jpeg,.png,.webp,.gif,image/*">
                                <span class="hint">JPG, PNG, WEBP o GIF &middot; máximo 5 MB</span>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn btn-primary">
                        <%= Icon("check") %> <%= IfElse(esEdicion, "Guardar cambios", "Crear playlist") %>
                    </button>
                    <a class="btn btn-ghost" href="<%= IfElse(esEdicion, U("playlist.asp") & "?id=" & idP, U("playlists.asp")) %>">Cancelar</a>
                    <span class="spacer"></span>
                    <% If esEdicion Then %>
                    <a class="btn btn-soft btn-sm" href="<%= U("playlist.asp") %>?id=<%= idP %>">Administrar canciones</a>
                    <% End If %>
                </div>
            </form>
        </div>
    </div>
</section>

<!--#include file="includes/layout-bottom.asp"-->
