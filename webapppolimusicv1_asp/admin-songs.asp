<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireAdmin

Dim rs, rsArt, rsAlb, artMap, albMap, total, songId, ruta, restantes
Dim k, nombreArt, nombreAlb

PageTitle = "Canciones"
PageEyebrow = "Administración"
NavActive = "admin-songs"

' --- Eliminar ------------------------------------------------------------
If IsPost() Then
    If PostStr("action") = "delete" Then
        songId = PostInt("id", 0)
        If songId > 0 Then
            ruta = CStr(Scalar("SELECT SONG_PATH FROM TBL_SONG WHERE ID_SONG = ?", Array(songId)) & "")
            If ruta <> "" Then
                RunSql "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = ?", Array(songId)
                RunSql "DELETE FROM TBL_PLAYER WHERE ID_SONG = ?", Array(songId)
                RunSql "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = ?", Array(songId)
                RunSql "DELETE FROM TBL_SONG WHERE ID_SONG = ?", Array(songId)

                restantes = CLng(Scalar("SELECT COUNT(*) FROM TBL_SONG WHERE SONG_PATH = ?", Array(ruta)))
                If restantes = 0 And Left(LCase(ruta), 12) = "~/songfiles/" Then
                    EliminarArchivoFisico ruta
                End If
                SetFlash "ok", "Canción eliminada del catálogo."
            Else
                SetFlash "error", "La canción ya no existe."
            End If
        End If
        DbClose
        RedirectTo U("admin-songs.asp")
    End If
End If

' --- Artistas y albumes por cancion -------------------------------------
Set artMap = Server.CreateObject("Scripting.Dictionary")
Set rsArt = DBQuery("SELECT p.ID_SONG, a.ARTIST_NAME, a.ARTIST_LASTNAME " & _
               "FROM TBL_PLAYER p INNER JOIN TBL_ARTIST a ON a.ID_ARTIST = p.ID_ARTIST ORDER BY a.ARTIST_NAME", Array())
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

Set albMap = Server.CreateObject("Scripting.Dictionary")
Set rsAlb = DBQuery("SELECT t.ID_SONG, a.TITLE_ALBUM FROM TBL_TRACKLIST t " & _
               "INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM ORDER BY a.TITLE_ALBUM", Array())
Do Until rsAlb.EOF
    k = CStr(rsAlb("ID_SONG").Value)
    nombreAlb = CStr(rsAlb("TITLE_ALBUM").Value)
    If albMap.Exists(k) Then
        albMap(k) = albMap(k) & ", " & nombreAlb
    Else
        albMap.Add k, nombreAlb
    End If
    rsAlb.MoveNext
Loop
rsAlb.Close
Set rsAlb = Nothing

Set rs = DBQuery("SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS, 0) AS PLAYS, al.ALBUM_IMAGE_PATH " & _
            "FROM TBL_SONG s OUTER APPLY (SELECT TOP 1 a.ALBUM_IMAGE_PATH " & _
            "  FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM " & _
            "  WHERE t.ID_SONG = s.ID_SONG ORDER BY a.ID_ALBUM) al ORDER BY s.SONG_NAME", Array())
total = rs.RecordCount
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Catálogo de canciones</h2>
            <p>Crea, edita y elimina las pistas del Song List. Solo visible para administradores.</p>
        </div>
        <div class="section-actions">
            <a class="btn btn-primary" href="<%= U("admin-song-form.asp") %>"><%= Icon("plus") %> Nueva canción</a>
        </div>
    </div>

    <div class="panel">
        <div class="table-tools">
            <div class="searchbox">
                <%= Icon("search") %>
                <input type="search" placeholder="Filtrar canciones…" data-table-search="tablaCanciones" aria-label="Filtrar canciones">
            </div>
            <span class="badge"><%= Plural(total, "canción", "canciones") %></span>
            <a class="btn btn-ghost btn-sm" href="<%= U("home.asp") %>">Ver Song List</a>
        </div>

        <div class="table-scroll">
            <table class="data-table" id="tablaCanciones">
                <thead>
                    <tr>
                        <th scope="col">Canción</th>
                        <th scope="col">Artistas</th>
                        <th scope="col">Álbumes</th>
                        <th scope="col" class="num">Plays</th>
                        <th scope="col" style="text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                <% If total = 0 Then %>
                    <tr><td colspan="5">
                        <div class="empty">
                            <span class="empty-icon"><%= Icon("music") %></span>
                            <h3>Sin canciones</h3>
                            <p>Sube la primera canción para comenzar el catálogo.</p>
                            <a class="btn btn-primary" href="<%= U("admin-song-form.asp") %>"><%= Icon("plus") %> Subir canción</a>
                        </div>
                    </td></tr>
                <% Else %>
                    <% Do Until rs.EOF %>
                    <tr>
                        <td>
                            <div class="cell-main">
                                <%= CoverHtml(rs("ALBUM_IMAGE_PATH").Value, rs("SONG_NAME").Value, "cover cover-xs") %>
                                <span>
                                    <strong><%= H(rs("SONG_NAME").Value) %></strong>
                                    <small class="mono"><%= H(ShortText(rs("SONG_PATH").Value, 42)) %></small>
                                </span>
                            </div>
                        </td>
                        <td>
                            <% k = CStr(rs("ID_SONG").Value) %>
                            <% If artMap.Exists(k) Then %><%= H(artMap(k)) %><% Else %><span class="muted">Sin artistas</span><% End If %>
                        </td>
                        <td>
                            <% If albMap.Exists(k) Then %><%= H(albMap(k)) %><% Else %><span class="muted">Sin álbum</span><% End If %>
                        </td>
                        <td class="num"><%= rs("PLAYS").Value %></td>
                        <td>
                            <div class="row-actions">
                                <a class="icon-btn" href="<%= U("admin-song-form.asp") %>?id=<%= k %>" title="Editar" aria-label="Editar <%= H(rs("SONG_NAME").Value) %>">
                                    <%= Icon("edit") %>
                                </a>
                                <form method="post" action="<%= U("admin-songs.asp") %>" class="inline-form"
                                      data-confirm="¿Eliminar la canción &quot;<%= H(rs("SONG_NAME").Value) %>&quot;? También se quitará de álbumes y playlists.">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="id" value="<%= k %>">
                                    <button type="submit" class="icon-btn is-danger" title="Eliminar" aria-label="Eliminar <%= H(rs("SONG_NAME").Value) %>">
                                        <%= Icon("trash") %>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                    <% rs.MoveNext %>
                    <% Loop %>
                <% End If %>
                </tbody>
            </table>
        </div>
    </div>
</section>

<%
rs.Close
Set rs = Nothing
%>
<!--#include file="includes/layout-bottom.asp"-->
