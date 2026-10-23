<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<!--#include file="includes/upload.asp"-->
<%
RequireAdmin

Dim idP, esEdicion, rs, errorMsg, errUp, imagen, imagenAnterior, nuevaImagen, imagenElegida, libreria, i
Dim titulo, anioTxt, paramAnio

errorMsg = ""
errUp = ""
nuevaImagen = ""
idP = GetInt("id", 0)
esEdicion = False
titulo = ""
anioTxt = ""
imagen = ""
paramAnio = Null

If idP > 0 Then
    Set rs = DBQuery("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = ?", Array(idP))
    If rs.EOF Then
        rs.Close
        Set rs = Nothing
        SetFlash "error", "El álbum no existe."
        DbClose
        RedirectTo U("admin-albums.asp")
    End If
    esEdicion = True
    titulo = CStr(rs("TITLE_ALBUM").Value)
    If Not IsNull(rs("RELEASE_YEAR").Value) Then anioTxt = CStr(rs("RELEASE_YEAR").Value)
    imagen = CStr(rs("ALBUM_IMAGE_PATH").Value & "")
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
        titulo = MF("title")
        anioTxt = MF("year")
        imagenElegida = MF("existing_image")
        paramAnio = Null

        If Len(titulo) = 0 Then
            errorMsg = "El título del álbum es obligatorio."
        ElseIf Len(titulo) > 50 Then
            errorMsg = "El título no puede superar los 50 caracteres."
        End If

        If anioTxt <> "" Then
            If Not IsNumeric(anioTxt) Then
                errorMsg = "El año debe ser un número."
            ElseIf CLng(anioTxt) < 1900 Or CLng(anioTxt) > 2100 Then
                errorMsg = "El año debe estar entre 1900 y 2100."
            Else
                paramAnio = CLng(anioTxt)
            End If
        End If

        If errorMsg = "" Then
            If HasFile("photo") Then
                nuevaImagen = SaveUpload("photo", "albumImages", "jpg,jpeg,png,webp,gif", 5242880, errUp)
                If errUp <> "" Then errorMsg = errUp
            ElseIf imagenElegida <> "" Then
                If Left(LCase(imagenElegida), 14) <> "~/albumimages/" Or Not AssetExists(imagenElegida) Then
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
                    imagenAnterior = CStr(Scalar("SELECT ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = ?", Array(idP)) & "")
                End If
                RunSql "UPDATE TBL_ALBUM SET TITLE_ALBUM = ?, RELEASE_YEAR = ?, ALBUM_IMAGE_PATH = ? WHERE ID_ALBUM = ?", _
                       Array(titulo, paramAnio, imagen, idP)
                If nuevaImagen <> "" And LCase(imagenAnterior) <> LCase(nuevaImagen) Then
                    If Left(LCase(imagenAnterior), 14) = "~/albumimages/" Then
                        If CLng(Scalar("SELECT COUNT(*) FROM TBL_ALBUM WHERE ALBUM_IMAGE_PATH = ?", Array(imagenAnterior))) = 0 Then
                            EliminarArchivoFisico imagenAnterior
                        End If
                    End If
                End If
                SetFlash "ok", "Álbum actualizado correctamente."
            Else
                idP = InsertId("INSERT INTO TBL_ALBUM (TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH) VALUES (?, ?, ?)", _
                               Array(titulo, paramAnio, imagen))
                SetFlash "ok", "Álbum creado correctamente."
            End If
            DbClose
            RedirectTo U("admin-albums.asp")
        End If
    End If
End If

libreria = ListFolder("albumImages", "jpg,jpeg,png,webp,gif")

PageTitle = IfElse(esEdicion, "Editar álbum", "Nuevo álbum")
PageEyebrow = "Administración"
NavActive = "admin-albums"
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="panel">
        <div class="panel-head">
            <div>
                <h2><%= IfElse(esEdicion, "Editar álbum", "Crear álbum") %></h2>
                <p>El título es obligatorio; el año y la portada son opcionales.</p>
            </div>
            <div class="section-actions">
                <a class="btn btn-ghost btn-sm" href="<%= U("admin-albums.asp") %>">Volver al listado</a>
            </div>
        </div>

        <div class="panel-body">
            <% If errorMsg <> "" Then %>
            <div class="flash flash-error" role="alert"><span class="flash-icon">!</span><span><%= H(errorMsg) %></span></div>
            <% End If %>

            <form method="post" enctype="multipart/form-data" action="<%= U("admin-album-form.asp") %>?id=<%= idP %>">
                <input type="hidden" name="id" value="<%= idP %>">

                <div class="form-grid">
                    <div class="field">
                        <label for="title">Título del álbum</label>
                        <input type="text" id="title" name="title" maxlength="50" required value="<%= H(titulo) %>" placeholder="Ej. Rock Album">
                    </div>

                    <div class="field">
                        <label for="year">Año de lanzamiento</label>
                        <input type="number" id="year" name="year" min="1900" max="2100" step="1"
                               value="<%= H(anioTxt) %>" placeholder="Ej. 1976">
                        <span class="hint">Entre 1900 y 2100. Puedes dejarlo vacío.</span>
                    </div>

                    <div class="field field-full">
                        <span class="field-label">Portada</span>
                        <div class="flex items-center gap-3 flex-wrap">
                            <%= CoverHtml(imagen, titulo, "cover") %>
                            <div class="file-drop" style="flex:1;min-width:240px;">
                                <input type="file" name="photo" accept=".jpg,.jpeg,.png,.webp,.gif,image/*">
                                <span class="hint">JPG, PNG, WEBP o GIF &middot; máximo 5 MB</span>
                            </div>
                        </div>
                    </div>

                    <div class="field field-full">
                        <label for="existing_image">…o elegir una portada de la biblioteca</label>
                        <select name="existing_image" id="existing_image">
                            <option value="">— Sin cambios / usar la imagen subida —</option>
                            <% If IsArray(libreria) Then %>
                                <% For i = 0 To UBound(libreria) %>
                                <option value="~/albumImages/<%= H(libreria(i)) %>"><%= H(libreria(i)) %></option>
                                <% Next %>
                            <% End If %>
                        </select>
                    </div>
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn btn-primary">
                        <%= Icon("check") %> <%= IfElse(esEdicion, "Guardar cambios", "Crear álbum") %>
                    </button>
                    <a class="btn btn-ghost" href="<%= U("admin-albums.asp") %>">Cancelar</a>
                </div>
            </form>
        </div>
    </div>
</section>

<!--#include file="includes/layout-bottom.asp"-->
