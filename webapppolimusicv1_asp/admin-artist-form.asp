<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<!--#include file="includes/upload.asp"-->
<%
RequireAdmin

Dim idP, esEdicion, rs, errorMsg, errUp, imagen, imagenAnterior, nuevaImagen, imagenElegida, libreria, i
Dim nombre, apellido

errorMsg = ""
errUp = ""
nuevaImagen = ""
idP = GetInt("id", 0)
esEdicion = False
nombre = ""
apellido = ""
imagen = ""

If idP > 0 Then
    Set rs = DBQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = ?", Array(idP))
    If rs.EOF Then
        rs.Close
        Set rs = Nothing
        SetFlash "error", "El artista no existe."
        DbClose
        RedirectTo U("admin-artists.asp")
    End If
    esEdicion = True
    nombre = CStr(rs("ARTIST_NAME").Value)
    apellido = CStr(rs("ARTIST_LASTNAME").Value & "")
    imagen = CStr(rs("ARTIST_IMAGE").Value & "")
    rs.Close
    Set rs = Nothing
End If

If IsPost() Then
    If Request.TotalBytes > UPLOAD_MAX Then
        errorMsg = "La imagen es demasiado grande. El máximo permitido es 30 MB."
    Else
        ParseMultipart
        idP = MFInt("id", idP)
        esEdicion = (idP > 0)
        nombre = MF("name")
        apellido = MF("lastname")
        imagenElegida = MF("existing_image")

        If Len(nombre) = 0 Then
            errorMsg = "El nombre del artista es obligatorio."
        ElseIf Len(nombre) > 100 Then
            errorMsg = "El nombre no puede superar los 100 caracteres."
        ElseIf Len(apellido) > 100 Then
            errorMsg = "El apellido no puede superar los 100 caracteres."
        End If

        If errorMsg = "" Then
            If HasFile("photo") Then
                nuevaImagen = SaveUpload("photo", "ArtistImages", "jpg,jpeg,png,webp,gif", 5242880, errUp)
                If errUp <> "" Then errorMsg = errUp
            ElseIf imagenElegida <> "" Then
                If Left(LCase(imagenElegida), 15) <> "~/artistimages/" Or Not AssetExists(imagenElegida) Then
                    errorMsg = "La imagen elegida no es válida."
                Else
                    nuevaImagen = imagenElegida
                End If
            End If
        End If

        If errorMsg = "" Then
            If nuevaImagen <> "" Then imagen = nuevaImagen

            If esEdicion Then
                If nuevaImagen <> "" Then
                    imagenAnterior = CStr(Scalar("SELECT ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = ?", Array(idP)) & "")
                End If
                RunSql "UPDATE TBL_ARTIST SET ARTIST_NAME = ?, ARTIST_LASTNAME = ?, ARTIST_IMAGE = ? WHERE ID_ARTIST = ?", _
                       Array(nombre, apellido, imagen, idP)
                If nuevaImagen <> "" And LCase(imagenAnterior) <> LCase(nuevaImagen) Then
                    If Left(LCase(imagenAnterior), 15) = "~/artistimages/" Then
                        If CLng(Scalar("SELECT COUNT(*) FROM TBL_ARTIST WHERE ARTIST_IMAGE = ?", Array(imagenAnterior))) = 0 Then
                            EliminarArchivoFisico imagenAnterior
                        End If
                    End If
                End If
                SetFlash "ok", "Artista actualizado correctamente."
            Else
                idP = InsertId("INSERT INTO TBL_ARTIST (ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE) VALUES (?, ?, ?)", _
                               Array(nombre, apellido, imagen))
                SetFlash "ok", "Artista registrado correctamente."
            End If
            DbClose
            RedirectTo U("admin-artists.asp")
        End If
    End If
End If

libreria = ListFolder("ArtistImages", "jpg,jpeg,png,webp,gif")

PageTitle = IfElse(esEdicion, "Editar artista", "Nuevo artista")
PageEyebrow = "Administración"
NavActive = "admin-artists"
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="panel">
        <div class="panel-head">
            <div>
                <h2><%= IfElse(esEdicion, "Editar artista", "Registrar artista") %></h2>
                <p>El nombre es obligatorio; la imagen es opcional y se usa en todo el catálogo.</p>
            </div>
            <div class="section-actions">
                <a class="btn btn-ghost btn-sm" href="<%= U("admin-artists.asp") %>">Volver al listado</a>
            </div>
        </div>

        <div class="panel-body">
            <% If errorMsg <> "" Then %>
            <div class="flash flash-error" role="alert"><span class="flash-icon">!</span><span><%= H(errorMsg) %></span></div>
            <% End If %>

            <form method="post" enctype="multipart/form-data" action="<%= U("admin-artist-form.asp") %>?id=<%= idP %>">
                <input type="hidden" name="id" value="<%= idP %>">

                <div class="form-grid">
                    <div class="field">
                        <label for="name">Nombre</label>
                        <input type="text" id="name" name="name" maxlength="100" required value="<%= H(nombre) %>" placeholder="Ej. Mariah">
                    </div>

                    <div class="field">
                        <label for="lastname">Apellido</label>
                        <input type="text" id="lastname" name="lastname" maxlength="100" value="<%= H(apellido) %>" placeholder="Ej. Carey">
                    </div>

                    <div class="field field-full">
                        <span class="field-label">Fotografía</span>
                        <div class="flex items-center gap-3 flex-wrap">
                            <%= AvatarHtml(imagen, nombre, "avatar avatar-lg") %>
                            <div class="file-drop" style="flex:1;min-width:240px;">
                                <input type="file" name="photo" accept=".jpg,.jpeg,.png,.webp,.gif,image/*">
                                <span class="hint">JPG, PNG, WEBP o GIF &middot; máximo 5 MB</span>
                            </div>
                        </div>
                    </div>

                    <div class="field field-full">
                        <label for="existing_image">…o elegir una imagen de la biblioteca</label>
                        <select name="existing_image" id="existing_image">
                            <option value="">— Sin cambios / usar la imagen subida —</option>
                            <% If IsArray(libreria) Then %>
                                <% For i = 0 To UBound(libreria) %>
                                <option value="~/ArtistImages/<%= H(libreria(i)) %>"><%= H(libreria(i)) %></option>
                                <% Next %>
                            <% End If %>
                        </select>
                    </div>
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn btn-primary">
                        <%= Icon("check") %> <%= IfElse(esEdicion, "Guardar cambios", "Registrar artista") %>
                    </button>
                    <a class="btn btn-ghost" href="<%= U("admin-artists.asp") %>">Cancelar</a>
                </div>
            </form>
        </div>
    </div>
</section>

<!--#include file="includes/layout-bottom.asp"-->
