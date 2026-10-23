<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<!--#include file="includes/upload.asp"-->
<%
RequireAdmin

Dim idP, esEdicion, rsSong, rsArtists, rsAlbums
Dim nombre, plays, errorMsg, errUp, rutaActual, rutaAnterior, nuevaRuta, audioElegido
Dim selArtists, selAlbums, libreria, i

errorMsg = ""
errUp = ""
idP = GetInt("id", 0)
esEdicion = False
nombre = ""
plays = 0
rutaActual = ""
selArtists = Array()
selAlbums = Array()

' --- Cargar cancion existente -------------------------------------------
If idP > 0 Then
    Set rsSong = DBQuery("SELECT ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS, 0) AS PLAYS FROM TBL_SONG WHERE ID_SONG = ?", Array(idP))
    If rsSong.EOF Then
        rsSong.Close
        Set rsSong = Nothing
        SetFlash "error", "La canción no existe."
        DbClose
        RedirectTo U("admin-songs.asp")
    End If
    esEdicion = True
    nombre = CStr(rsSong("SONG_NAME").Value)
    plays = CLng(rsSong("PLAYS").Value)
    rutaActual = CStr(rsSong("SONG_PATH").Value & "")
    rsSong.Close
    Set rsSong = Nothing

    selArtists = IdsDeConsulta("SELECT ID_ARTIST FROM TBL_PLAYER WHERE ID_SONG = ?", Array(idP))
    selAlbums = IdsDeConsulta("SELECT ID_ALBUM FROM TBL_TRACKLIST WHERE ID_SONG = ?", Array(idP))
End If

' --- Guardar -------------------------------------------------------------
If IsPost() Then
    If Request.TotalBytes > UPLOAD_MAX Then
        errorMsg = "El archivo es demasiado grande. El máximo permitido es 30 MB."
    Else
        ParseMultipart
        idP = MFInt("id", idP)
        esEdicion = (idP > 0)
        nombre = MF("name")
        plays = MFInt("plays", 0)
        selArtists = MFList("artists")
        selAlbums = MFList("albums")
        audioElegido = MF("existing_audio")
        nuevaRuta = ""

        If Len(nombre) = 0 Then
            errorMsg = "El nombre de la canción es obligatorio."
        ElseIf Len(nombre) > 50 Then
            errorMsg = "El nombre no puede superar los 50 caracteres."
        End If

        If plays < 0 Then plays = 0

        If errorMsg = "" Then
            If HasFile("audio") Then
                nuevaRuta = SaveUpload("audio", "songFiles", "mp3,wav,ogg", 26214400, errUp)
                If errUp <> "" Then errorMsg = errUp
            ElseIf audioElegido <> "" Then
                If Left(LCase(audioElegido), 12) <> "~/songfiles/" Or Not AssetExists(audioElegido) Then
                    errorMsg = "El archivo de audio elegido no es válido."
                Else
                    nuevaRuta = audioElegido
                End If
            ElseIf esEdicion Then
                nuevaRuta = rutaActual
            Else
                errorMsg = "Debes subir un archivo MP3 o elegir uno de la biblioteca."
            End If
        End If

        If errorMsg = "" And nuevaRuta = "" Then
            errorMsg = "La canción necesita un archivo de audio."
        End If

        If errorMsg = "" Then
            If esEdicion Then
                rutaAnterior = rutaActual
                RunSql "UPDATE TBL_SONG SET SONG_NAME = ?, SONG_PATH = ?, PLAYS = ? WHERE ID_SONG = ?", _
                       Array(nombre, nuevaRuta, plays, idP)
                If nuevaRuta <> "" And LCase(rutaAnterior) <> LCase(nuevaRuta) Then
                    If Left(LCase(rutaAnterior), 12) = "~/songfiles/" Then
                        If CLng(Scalar("SELECT COUNT(*) FROM TBL_SONG WHERE SONG_PATH = ?", Array(rutaAnterior))) = 0 Then
                            EliminarArchivoFisico rutaAnterior
                        End If
                    End If
                End If
                SetFlash "ok", "Canción actualizada correctamente."
            Else
                idP = InsertId("INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (?, ?, ?)", _
                               Array(nombre, nuevaRuta, plays))
                SetFlash "ok", "Canción creada y agregada al Song List."
            End If

            ' Relaciones N:M con artistas y albumes
            RunSql "DELETE FROM TBL_PLAYER WHERE ID_SONG = ?", Array(idP)
            If IsArray(selArtists) Then
                For i = 0 To UBound(selArtists)
                    RunSql "INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) VALUES (?, ?)", Array(idP, selArtists(i))
                Next
            End If

            RunSql "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = ?", Array(idP)
            If IsArray(selAlbums) Then
                For i = 0 To UBound(selAlbums)
                    RunSql "INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) VALUES (?, ?)", Array(selAlbums(i), idP)
                Next
            End If

            DbClose
            RedirectTo U("admin-songs.asp")
        End If
    End If
End If

' --- Datos para el formulario -------------------------------------------
Set rsArtists = DBQuery("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST ORDER BY ARTIST_NAME", Array())
Set rsAlbums = DBQuery("SELECT ID_ALBUM, TITLE_ALBUM FROM TBL_ALBUM ORDER BY TITLE_ALBUM", Array())
libreria = ListFolder("songFiles", "mp3,wav,ogg")

PageTitle = IfElse(esEdicion, "Editar canción", "Nueva canción")
PageEyebrow = "Administración"
NavActive = "admin-songs"
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="panel">
        <div class="panel-head">
            <div>
                <h2><%= IfElse(esEdicion, "Editar canción", "Subir una canción") %></h2>
                <p>Define el audio, el nombre, los artistas y los álbumes a los que pertenece.</p>
            </div>
            <div class="section-actions">
                <a class="btn btn-ghost btn-sm" href="<%= U("admin-songs.asp") %>">Volver al listado</a>
            </div>
        </div>

        <div class="panel-body">
            <% If errorMsg <> "" Then %>
            <div class="flash flash-error" role="alert">
                <span class="flash-icon">!</span><span><%= H(errorMsg) %></span>
            </div>
            <% End If %>

            <form method="post" enctype="multipart/form-data" action="<%= U("admin-song-form.asp") %>?id=<%= idP %>">
                <input type="hidden" name="id" value="<%= idP %>">

                <div class="form-grid">
                    <div class="field">
                        <label for="name">Nombre de la canción</label>
                        <input type="text" id="name" name="name" maxlength="50" required
                               value="<%= H(nombre) %>" placeholder="Ej. Midnight Drive">
                    </div>

                    <div class="field">
                        <label for="plays">Reproducciones iniciales</label>
                        <input type="number" id="plays" name="plays" min="0" step="1" value="<%= plays %>">
                        <span class="hint">Se incrementa automáticamente cada vez que alguien la reproduce.</span>
                    </div>

                    <div class="field field-full">
                        <span class="field-label">Archivo de audio</span>
                        <% If rutaActual <> "" And AssetExists(rutaActual) Then %>
                        <div class="file-drop" style="justify-content:space-between;">
                            <span class="mono"><%= H(ShortText(rutaActual, 60)) %></span>
                            <audio controls preload="none" src="<%= H(U(rutaActual)) %>" style="max-width:320px;"></audio>
                        </div>
                        <% End If %>
                        <div class="file-drop">
                            <input type="file" name="audio" accept=".mp3,.wav,.ogg,audio/*">
                            <span class="hint">MP3, WAV u OGG &middot; máximo 25 MB</span>
                        </div>
                    </div>

                    <div class="field field-full">
                        <label for="existing_audio">…o elegir un audio de la biblioteca</label>
                        <select name="existing_audio" id="existing_audio">
                            <option value="">— Sin cambios / usar el archivo subido —</option>
                            <% If IsArray(libreria) Then %>
                                <% For i = 0 To UBound(libreria) %>
                                <option value="~/songFiles/<%= H(libreria(i)) %>"><%= H(libreria(i)) %></option>
                                <% Next %>
                            <% End If %>
                        </select>
                        <span class="hint">Útil para reutilizar los audios incluidos con el proyecto.</span>
                    </div>

                    <div class="field field-full">
                        <span class="field-label">Artistas</span>
                        <% If rsArtists.EOF Then %>
                        <div class="file-drop" style="justify-content:space-between;">
                            <span>No hay artistas registrados.</span>
                            <a class="btn btn-soft btn-sm" href="<%= U("admin-artist-form.asp") %>"><%= Icon("plus") %> Crear artista</a>
                        </div>
                        <% Else %>
                        <div class="check-grid">
                            <% Do Until rsArtists.EOF %>
                            <label class="check">
                                <input type="checkbox" name="artists" value="<%= rsArtists("ID_ARTIST").Value %>"
                                       <%= IfElse(InIdList(selArtists, rsArtists("ID_ARTIST").Value), "checked", "") %>>
                                <%= AvatarHtml(rsArtists("ARTIST_IMAGE").Value, rsArtists("ARTIST_NAME").Value, "avatar avatar-sm") %>
                                <span><%= H(Trim(rsArtists("ARTIST_NAME").Value & " " & rsArtists("ARTIST_LASTNAME").Value & "")) %></span>
                            </label>
                            <% rsArtists.MoveNext %>
                            <% Loop %>
                        </div>
                        <% End If %>
                    </div>

                    <div class="field field-full">
                        <span class="field-label">Álbumes</span>
                        <% If rsAlbums.EOF Then %>
                        <div class="file-drop" style="justify-content:space-between;">
                            <span>No hay álbumes registrados.</span>
                            <a class="btn btn-soft btn-sm" href="<%= U("admin-album-form.asp") %>"><%= Icon("plus") %> Crear álbum</a>
                        </div>
                        <% Else %>
                        <div class="check-grid">
                            <% Do Until rsAlbums.EOF %>
                            <label class="check">
                                <input type="checkbox" name="albums" value="<%= rsAlbums("ID_ALBUM").Value %>"
                                       <%= IfElse(InIdList(selAlbums, rsAlbums("ID_ALBUM").Value), "checked", "") %>>
                                <span><%= H(rsAlbums("TITLE_ALBUM").Value) %></span>
                            </label>
                            <% rsAlbums.MoveNext %>
                            <% Loop %>
                        </div>
                        <% End If %>
                    </div>
                </div>

                <div class="form-actions">
                    <button type="submit" class="btn btn-primary">
                        <%= Icon("check") %> <%= IfElse(esEdicion, "Guardar cambios", "Crear canción") %>
                    </button>
                    <a class="btn btn-ghost" href="<%= U("admin-songs.asp") %>">Cancelar</a>
                </div>
            </form>
        </div>
    </div>
</section>

<%
rsArtists.Close
rsAlbums.Close
Set rsArtists = Nothing
Set rsAlbums = Nothing
%>
<!--#include file="includes/layout-bottom.asp"-->
