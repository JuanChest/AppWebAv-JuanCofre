<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireLogin

Dim rsSongs, rsArt, rsAlbums, rsArtists, rsMine
Dim artMap, k, nombreArt, totalCanciones, totalAlbumes, totalArtistas, totalPlays, misPlaylists
Dim fila, nFila, cancion, artistaTxt, albumTxt, coverPath, srcPath, coverAttr, playsN

PageTitle = "Inicio"
PageEyebrow = "Bienvenido"
NavActive = "home"

' --- Artistas por cancion -------------------------------------------------
Set artMap = Server.CreateObject("Scripting.Dictionary")
Set rsArt = DBQuery("SELECT p.ID_SONG, a.ARTIST_NAME, a.ARTIST_LASTNAME " & _
               "FROM TBL_PLAYER p INNER JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST " & _
               "ORDER BY a.ARTIST_NAME", Array())
Do Until rsArt.EOF
    k = CStr(rsArt("ID_SONG").Value)
    nombreArt = Trim(CStr(rsArt("ARTIST_NAME").Value & "") & " " & CStr(rsArt("ARTIST_LASTNAME").Value & ""))
    If artMap.Exists(k) Then
        artMap(k) = artMap(k) & ", " & nombreArt
    Else
        artMap.Add k, nombreArt
    End If
    rsArt.MoveNext
Loop
rsArt.Close
Set rsArt = Nothing

' --- Canciones ------------------------------------------------------------
Set rsSongs = DBQuery("SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS, 0) AS PLAYS, " & _
                 "       al.TITLE_ALBUM, al.ALBUM_IMAGE_PATH " & _
                 "FROM TBL_SONG s " & _
                 "OUTER APPLY (SELECT TOP 1 a.TITLE_ALBUM, a.ALBUM_IMAGE_PATH " & _
                 "             FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM " & _
                 "             WHERE t.ID_SONG = s.ID_SONG ORDER BY a.ID_ALBUM) al " & _
                 "ORDER BY s.SONG_NAME", Array())
totalCanciones = rsSongs.RecordCount

' --- Albumes y artistas ---------------------------------------------------
Set rsAlbums = DBQuery("SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
                  "       (SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) AS SONGS " & _
                  "FROM TBL_ALBUM a ORDER BY a.TITLE_ALBUM", Array())

Set rsArtists = DBQuery("SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
                   "       (SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = a.ID_ARTIST) AS SONGS " & _
                   "FROM TBL_ARTIST a ORDER BY a.ARTIST_NAME", Array())

totalAlbumes = 0
Do Until rsAlbums.EOF
    totalAlbumes = totalAlbumes + 1
    rsAlbums.MoveNext
Loop
rsAlbums.MoveFirst

totalArtistas = 0
Do Until rsArtists.EOF
    totalArtistas = totalArtistas + 1
    rsArtists.MoveNext
Loop
rsArtists.MoveFirst

totalPlays = Scalar("SELECT ISNULL(SUM(PLAYS), 0) FROM TBL_SONG", Array())

Set rsMine = DBQuery("SELECT ID_PLAYLIST, TITLE FROM TBL_PLAYLIST WHERE ID_USER = ? ORDER BY TITLE", _
                Array(CurrentUserId()))
misPlaylists = rsMine.RecordCount

PageTitle = "Inicio"
%>
<!--#include file="includes/layout-top.asp"-->

<section class="hero">
    <div class="hero-copy">
        <span class="hero-eyebrow"><%= Icon("spark") %> Sesión activa &middot; <%= H(RoleName(CurrentUserType())) %></span>
        <h1 class="hero-title">Bienvenido,<br><em><%= H(CurrentUserName()) %></em></h1>
        <p class="hero-sub">
            Este es tu punto de partida: a continuación se presenta el <strong>Song List</strong>
            con todas las canciones disponibles en PoliMusic. Dale play y arma tu banda sonora.
        </p>
        <div class="hero-actions">
            <button type="button" class="btn btn-primary js-play-all">
                <%= Icon("play") %> Reproducir todo
            </button>
            <a class="btn btn-ghost" href="<%= U("playlists.asp") %>">
                <%= Icon("playlist") %> Mis playlists
            </a>
            <% If IsAdmin() Then %>
            <a class="btn btn-soft" href="<%= U("admin-songs.asp") %>">
                <%= Icon("edit") %> Administrar catálogo
            </a>
            <% End If %>
        </div>
        <div class="hero-stats">
            <div class="stat"><span class="stat-num"><%= totalCanciones %></span><span class="stat-label">Canciones</span></div>
            <div class="stat"><span class="stat-num"><%= totalAlbumes %></span><span class="stat-label">Álbumes</span></div>
            <div class="stat"><span class="stat-num"><%= totalArtistas %></span><span class="stat-label">Artistas</span></div>
            <div class="stat"><span class="stat-num"><%= totalPlays %></span><span class="stat-label">Reproducciones</span></div>
        </div>
    </div>
    <div class="hero-art" aria-hidden="true">
        <div class="vinyl"></div>
        <span class="hero-art-note">now spinning</span>
    </div>
</section>

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Song List</h2>
            <p><%= Plural(totalCanciones, "canción disponible", "canciones disponibles") %> &middot; <span id="songVisible"><%= totalCanciones %></span> visibles</p>
        </div>
        <div class="section-actions">
            <div class="searchbox">
                <%= Icon("search") %>
                <input type="search" id="songSearch" placeholder="Buscar canción, artista o álbum…" aria-label="Buscar en el Song List">
            </div>
            <% If IsAdmin() Then %>
            <a class="btn btn-ghost btn-sm" href="<%= U("admin-song-form.asp") %>">
                <%= Icon("plus") %> Nueva canción
            </a>
            <% End If %>
        </div>
    </div>

    <div class="panel">
        <div class="song-list-head" aria-hidden="true">
            <span>#</span>
            <span>Canción</span>
            <span>Álbum</span>
            <span style="text-align:right;">Plays</span>
            <span style="text-align:right;">Acciones</span>
        </div>

        <div class="song-list" id="songList">
        <% If totalCanciones = 0 Then %>
            <div class="empty">
                <span class="empty-icon"><%= Icon("music") %></span>
                <h3>Aún no hay canciones</h3>
                <p>El catálogo está vacío. Un administrador puede subir la primera canción.</p>
                <% If IsAdmin() Then %>
                <a class="btn btn-primary" href="<%= U("admin-song-form.asp") %>"><%= Icon("plus") %> Subir canción</a>
                <% End If %>
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
                albumTxt = CStr(rsSongs("TITLE_ALBUM").Value & "")
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
                        <% If albumTxt <> "" Then %><span><%= H(albumTxt) %></span><% Else %><span class="muted">Sin álbum</span><% End If %>
                    </div>
                    <div class="song-plays" title="Reproducciones">
                        <%= Icon("headphones") %><span class="js-play-count"><%= playsN %></span>
                    </div>
                    <div class="song-actions">
                        <button type="button" class="icon-btn js-add" data-add-song="<%= k %>"
                                data-song-title="<%= H(cancion) %>" title="Agregar a una playlist" aria-label="Agregar <%= H(cancion) %> a una playlist">
                            <%= Icon("plus") %>
                        </button>
                        <% If IsAdmin() Then %>
                        <a class="icon-btn" href="<%= U("admin-song-form.asp") %>?id=<%= k %>" title="Editar canción" aria-label="Editar <%= H(cancion) %>">
                            <%= Icon("edit") %>
                        </a>
                        <% End If %>
                    </div>
                </div>
                <% rsSongs.MoveNext %>
            <% Loop %>
            <div class="empty" id="searchEmpty" hidden>
                <span class="empty-icon"><%= Icon("search") %></span>
                <h3>Sin coincidencias</h3>
                <p>Prueba con otro nombre de canción, artista o álbum.</p>
            </div>
        <% End If %>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Álbumes</h2>
            <p>Colecciones que agrupan el catálogo.</p>
        </div>
        <div class="section-actions">
            <a class="btn btn-ghost btn-sm" href="<%= U("albums.asp") %>">Ver todos <%= Icon("chevron") %></a>
        </div>
    </div>

    <div class="grid-albums">
        <% If totalAlbumes = 0 Then %>
            <div class="empty" style="grid-column:1/-1;">
                <span class="empty-icon"><%= Icon("album") %></span>
                <h3>Sin álbumes todavía</h3>
            </div>
        <% Else %>
            <% Do Until rsAlbums.EOF %>
            <article class="album-card">
                <div class="album-art">
                    <%= CoverHtml(rsAlbums("ALBUM_IMAGE_PATH").Value, rsAlbums("TITLE_ALBUM").Value, "cover") %>
                    <% If Not IsNull(rsAlbums("RELEASE_YEAR").Value) Then %>
                    <span class="album-year"><%= rsAlbums("RELEASE_YEAR").Value %></span>
                    <% End If %>
                </div>
                <div class="album-body">
                    <strong><%= H(rsAlbums("TITLE_ALBUM").Value) %></strong>
                    <small><%= Plural(rsAlbums("SONGS").Value, "canción", "canciones") %></small>
                </div>
            </article>
            <% rsAlbums.MoveNext %>
            <% Loop %>
        <% End If %>
    </div>
</section>

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Artistas</h2>
            <p>Quienes dan vida a cada pista.</p>
        </div>
        <div class="section-actions">
            <a class="btn btn-ghost btn-sm" href="<%= U("artists.asp") %>">Ver todos <%= Icon("chevron") %></a>
        </div>
    </div>

    <div class="grid-artists">
        <% If totalArtistas = 0 Then %>
            <div class="empty" style="grid-column:1/-1;">
                <span class="empty-icon"><%= Icon("artist") %></span>
                <h3>Sin artistas todavía</h3>
            </div>
        <% Else %>
            <% Do Until rsArtists.EOF %>
            <article class="artist-card">
                <%= AvatarHtml(rsArtists("ARTIST_IMAGE").Value, rsArtists("ARTIST_NAME").Value, "avatar") %>
                <div class="artist-body">
                    <strong><%= H(Trim(rsArtists("ARTIST_NAME").Value & " " & rsArtists("ARTIST_LASTNAME").Value & "")) %></strong>
                    <small><%= Plural(rsArtists("SONGS").Value, "canción", "canciones") %></small>
                </div>
            </article>
            <% rsArtists.MoveNext %>
            <% Loop %>
        <% End If %>
    </div>
</section>

<div class="modal" id="addModal" hidden>
    <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="addModalTitle">
        <div class="modal-head">
            <h3 id="addModalTitle">Agregar a playlist</h3>
            <button type="button" class="icon-btn" data-modal-close aria-label="Cerrar"><%= Icon("close") %></button>
        </div>
        <div class="modal-body">
            <div class="song-ref"><%= Icon("music") %><span id="addSongLabel">Canción</span></div>
            <% If misPlaylists > 0 Then %>
            <form method="post" action="<%= U("playlist.asp") %>">
                <input type="hidden" name="action" value="add">
                <input type="hidden" name="song" id="addSongId" value="">
                <div class="field">
                    <label for="addPlaylist">Playlist de destino</label>
                    <select name="id" id="addPlaylist" required>
                        <% Do Until rsMine.EOF %>
                        <option value="<%= rsMine("ID_PLAYLIST").Value %>"><%= H(rsMine("TITLE").Value) %></option>
                        <% rsMine.MoveNext %>
                        <% Loop %>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary btn-block mt-3"><%= Icon("plus") %> Agregar canción</button>
            </form>
            <% Else %>
            <p class="muted">Todavía no tienes playlists. Crea una para empezar a guardar canciones.</p>
            <a class="btn btn-primary btn-block" href="<%= U("playlists.asp") %>"><%= Icon("plus") %> Crear mi primera playlist</a>
            <% End If %>
        </div>
    </div>
</div>

<%
rsSongs.Close
rsAlbums.Close
rsArtists.Close
rsMine.Close
Set rsSongs = Nothing
Set rsAlbums = Nothing
Set rsArtists = Nothing
Set rsMine = Nothing
%>
<!--#include file="includes/layout-bottom.asp"-->
