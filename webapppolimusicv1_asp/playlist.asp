<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireLogin

Dim idP, uid, rsP, rsSongs, rsArt, rsAvail, artMap, total, disponibles
Dim accion, songId, k, artistaTxt, cancion, coverPath, srcPath, coverAttr, playsN, nFila

uid = CurrentUserId()
idP = GetInt("id", 0)
If idP = 0 And IsPost() Then idP = PostInt("id", 0)

If idP = 0 Then
    SetFlash "error", "Selecciona una playlist para abrirla."
    RedirectTo U("playlists.asp")
End If

Set rsP = DBQuery("SELECT ID_PLAYLIST, ID_USER, TITLE, CREATION_DATE, [TYPE], PHOTO " & _
             "FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ? AND ID_USER = ?", Array(idP, uid))
If rsP.EOF Then
    rsP.Close
    Set rsP = Nothing
    SetFlash "error", "Esa playlist no existe o no te pertenece."
    RedirectTo U("playlists.asp")
End If

' --- Acciones sobre canciones de la playlist ---------------------------
If IsPost() Then
    accion = PostStr("action")
    songId = PostInt("song", 0)

    If accion = "add" And songId > 0 Then
        If CLng(Scalar("SELECT COUNT(*) FROM TBL_SONG WHERE ID_SONG = ?", Array(songId))) = 0 Then
            SetFlash "error", "La canción ya no existe."
        ElseIf CLng(Scalar("SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?", Array(idP, songId))) > 0 Then
            SetFlash "info", "Esa canción ya estaba en la playlist."
        Else
            RunSql "INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) VALUES (?, ?)", Array(idP, songId)
            SetFlash "ok", "Canción agregada a la playlist."
        End If
    ElseIf accion = "remove" And songId > 0 Then
        RunSql "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ? AND ID_SONG = ?", Array(idP, songId)
        SetFlash "ok", "Canción quitada de la playlist."
    End If

    DbClose
    RedirectTo U("playlist.asp") & "?id=" & idP
End If

' --- Artistas por cancion -----------------------------------------------
Set artMap = Server.CreateObject("Scripting.Dictionary")
Set rsArt = DBQuery("SELECT p.ID_SONG, a.ARTIST_NAME, a.ARTIST_LASTNAME " & _
               "FROM TBL_PLAYER p INNER JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
               "ORDER BY a.ARTIST_NAME", Array())
Do Until rsArt.EOF
    k = CStr(rsArt("ID_SONG").Value)
    If artMap.Exists(k) Then
        artMap(k) = artMap(k) & ", " & Trim(CStr(rsArt("ARTIST_NAME").Value & "") & " " & CStr(rsArt("ARTIST_LASTNAME").Value & ""))
    Else
        artMap.Add k, Trim(CStr(rsArt("ARTIST_NAME").Value & "") & " " & CStr(rsArt("ARTIST_LASTNAME").Value & ""))
    End If
    rsArt.MoveNext
Loop
rsArt.Close
Set rsArt = Nothing

' --- Canciones de la playlist -------------------------------------------
Set rsSongs = DBQuery("SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS, 0) AS PLAYS, " & _
                 "       al.TITLE_ALBUM, al.ALBUM_IMAGE_PATH " & _
                 "FROM TBL_PLAYLIST_SONG ps " & _
                 "INNER JOIN TBL_SONG s ON s.ID_SONG = ps.ID_SONG " & _
                 "OUTER APPLY (SELECT TOP 1 a.TITLE_ALBUM, a.ALBUM_IMAGE_PATH " & _
                 "             FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM " & _
                 "             WHERE t.ID_SONG = s.ID_SONG ORDER BY a.ID_ALBUM) al " & _
                 "WHERE ps.ID_PLAYLIST = ? ORDER BY s.SONG_NAME", Array(idP))
total = rsSongs.RecordCount

' --- Canciones que aun se pueden agregar --------------------------------
Set rsAvail = DBQuery("SELECT ID_SONG, SONG_NAME FROM TBL_SONG " & _
                 "WHERE ID_SONG NOT IN (SELECT ID_SONG FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ?) " & _
                 "ORDER BY SONG_NAME", Array(idP))
disponibles = rsAvail.RecordCount

PageTitle = CStr(rsP("TITLE").Value)
PageEyebrow = "Playlist"
NavActive = "playlists"
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="panel playlist-hero">
        <div class="playlist-hero-art">
            <%= CoverHtml(rsP("PHOTO").Value, rsP("TITLE").Value, "cover") %>
        </div>
        <div class="playlist-hero-body">
            <div class="flex items-center gap-2 flex-wrap">
                <span class="badge badge-accent"><%= H(PlaylistTypeName(rsP("TYPE").Value)) %></span>
                <span class="badge"><%= Plural(total, "canción", "canciones") %></span>
            </div>
            <h2><%= H(rsP("TITLE").Value) %></h2>
            <p class="muted">Creada el <%= HumanDate(rsP("CREATION_DATE").Value) %> &middot; playlist personal de <%= H(CurrentUserName()) %></p>
            <div class="flex items-center gap-2 flex-wrap mt-3">
                <button type="button" class="btn btn-primary js-play-all" <%= IfElse(total = 0, "disabled", "") %>>
                    <%= Icon("play") %> Reproducir
                </button>
                <a class="btn btn-ghost" href="<%= U("playlist-form.asp") %>?id=<%= idP %>"><%= Icon("edit") %> Editar</a>
                <form method="post" action="<%= U("playlists.asp") %>" class="inline-form"
                      data-confirm="¿Eliminar la playlist &quot;<%= H(rsP("TITLE").Value) %>&quot; y todas sus canciones?">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="<%= idP %>">
                    <button type="submit" class="btn btn-danger"><%= Icon("trash") %> Eliminar</button>
                </form>
            </div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Agregar canciones</h2>
            <p><%= Plural(disponibles, "canción disponible", "canciones disponibles") %> para sumar a esta playlist.</p>
        </div>
    </div>

    <div class="panel">
        <div class="panel-body">
            <% If disponibles = 0 Then %>
            <p class="muted">Todas las canciones del catálogo ya forman parte de esta playlist.</p>
            <% Else %>
            <form method="post" action="<%= U("playlist.asp") %>?id=<%= idP %>" class="flex items-center gap-2 flex-wrap">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="id" value="<%= idP %>">
                <div class="field" style="flex:1;min-width:240px;">
                    <label for="song" class="sr-only">Canción</label>
                    <select name="song" id="song" required>
                        <option value="">Selecciona una canción…</option>
                        <% Do Until rsAvail.EOF %>
                        <option value="<%= rsAvail("ID_SONG").Value %>"><%= H(rsAvail("SONG_NAME").Value) %></option>
                        <% rsAvail.MoveNext %>
                        <% Loop %>
                    </select>
                </div>
                <button type="submit" class="btn btn-soft"><%= Icon("plus") %> Agregar</button>
            </form>
            <% End If %>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Song List de la playlist</h2>
            <p>El orden de reproducción sigue el nombre de las canciones.</p>
        </div>
        <div class="section-actions">
            <span class="badge"><%= Icon("headphones") %> <%= total %> en cola</span>
        </div>
    </div>

    <div class="panel">
        <div class="song-list-head" aria-hidden="true">
            <span>#</span><span>Canción</span><span>Álbum</span>
            <span style="text-align:right;">Plays</span><span style="text-align:right;">Acciones</span>
        </div>
        <div class="song-list">
        <% If total = 0 Then %>
            <div class="empty">
                <span class="empty-icon"><%= Icon("music") %></span>
                <h3>Esta playlist está vacía</h3>
                <p>Usa el selector de arriba para agregar canciones del catálogo.</p>
            </div>
        <% Else %>
            <% nFila = 0 %>
            <% Do Until rsSongs.EOF %>
                <%
                nFila = nFila + 1
                cancion = CStr(rsSongs("SONG_NAME").Value)
                k = CStr(rsSongs("ID_SONG").Value)
                artistaTxt = "Artista desconocido"
                If artMap.Exists(k) Then artistaTxt = artMap(k)
                coverPath = CStr(rsSongs("ALBUM_IMAGE_PATH").Value & "")
                srcPath = U(rsSongs("SONG_PATH").Value)
                playsN = CLng(rsSongs("PLAYS").Value)
                coverAttr = ""
                If AssetExists(coverPath) Then coverAttr = " data-cover=""" & H(U(coverPath)) & """"
                %>
                <div class="song-row" data-track data-id="<%= k %>"
                     data-title="<%= H(cancion) %>" data-artist="<%= H(artistaTxt) %>"
                     data-src="<%= H(srcPath) %>"<%= coverAttr %>>
                    <span class="song-index"><%= Right("0" & nFila, 2) %></span>
                    <div class="song-main">
                        <div class="cover-wrap">
                            <%= CoverHtml(coverPath, cancion, "cover-sm") %>
                            <button type="button" class="cover-play js-play" aria-label="Reproducir <%= H(cancion) %>">
                                <%= Icon("play") %>
                            </button>
                        </div>
                        <div class="song-text">
                            <span class="song-title"><%= H(cancion) %></span>
                            <span class="song-artist"><%= H(artistaTxt) %></span>
                        </div>
                    </div>
                    <div class="song-album">
                        <% If CStr(rsSongs("TITLE_ALBUM").Value & "") <> "" Then %>
                        <span><%= H(rsSongs("TITLE_ALBUM").Value) %></span>
                        <% Else %>
                        <span class="muted">Sin álbum</span>
                        <% End If %>
                    </div>
                    <div class="song-plays" title="Reproducciones"><%= Icon("headphones") %><span><%= playsN %></span></div>
                    <div class="song-actions">
                        <form method="post" action="<%= U("playlist.asp") %>?id=<%= idP %>" class="inline-form"
                              data-confirm="¿Quitar &quot;<%= H(cancion) %>&quot; de esta playlist?">
                            <input type="hidden" name="action" value="remove">
                            <input type="hidden" name="id" value="<%= idP %>">
                            <input type="hidden" name="song" value="<%= k %>">
                            <button type="submit" class="icon-btn is-danger" title="Quitar de la playlist" aria-label="Quitar <%= H(cancion) %>">
                                <%= Icon("trash") %>
                            </button>
                        </form>
                    </div>
                </div>
                <% rsSongs.MoveNext %>
            <% Loop %>
        <% End If %>
        </div>
    </div>
</section>

<%
rsSongs.Close
rsAvail.Close
rsP.Close
Set rsSongs = Nothing
Set rsAvail = Nothing
Set rsP = Nothing
%>
<!--#include file="includes/layout-bottom.asp"-->
