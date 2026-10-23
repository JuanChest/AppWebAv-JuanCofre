<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireLogin

Dim rs, total, pid, uid, foto

PageTitle = "Mis playlists"
PageEyebrow = "Biblioteca"
NavActive = "playlists"
uid = CurrentUserId()

If IsPost() Then
    If PostStr("action") = "delete" Then
        pid = PostInt("id", 0)
        If pid > 0 Then
            If CLng(Scalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ? AND ID_USER = ?", Array(pid, uid))) > 0 Then
                foto = CStr(Scalar("SELECT PHOTO FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ? AND ID_USER = ?", Array(pid, uid)) & "")
                RunSql "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = ?", Array(pid)
                RunSql "DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = ? AND ID_USER = ?", Array(pid, uid)
                If foto <> "" And LCase(foto) <> "~/playlistimages/default.jpg" Then
                    If CLng(Scalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE PHOTO = ?", Array(foto))) = 0 Then
                        EliminarArchivoFisico foto
                    End If
                End If
                SetFlash "ok", "La playlist se eliminó correctamente."
            Else
                SetFlash "error", "No tienes permiso para eliminar esa playlist."
            End If
        End If
        DbClose
        RedirectTo U("playlists.asp")
    End If
End If

Set rs = DBQuery("SELECT p.ID_PLAYLIST, p.TITLE, p.CREATION_DATE, p.TYPE, p.PHOTO, " & _
            "       (SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS SONGS " & _
            "FROM TBL_PLAYLIST p WHERE p.ID_USER = ? ORDER BY p.CREATION_DATE DESC, p.ID_PLAYLIST DESC", _
            Array(uid))
total = rs.RecordCount
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Tus playlists</h2>
            <p><%= Plural(total, "playlist personal", "playlists personales") %> de <strong><%= H(CurrentUserName()) %></strong>.</p>
        </div>
        <div class="section-actions">
            <a class="btn btn-primary" href="<%= U("playlist-form.asp") %>"><%= Icon("plus") %> Nueva playlist</a>
        </div>
    </div>

    <% If total = 0 Then %>
    <div class="panel">
        <div class="empty">
            <span class="empty-icon"><%= Icon("playlist") %></span>
            <h3>Crea tu primera playlist</h3>
            <p>Guarda tus canciones favoritas en colecciones públicas o privadas y escúchalas cuando quieras.</p>
            <a class="btn btn-primary" href="<%= U("playlist-form.asp") %>"><%= Icon("plus") %> Crear playlist</a>
        </div>
    </div>
    <% Else %>
    <div class="grid-playlists">
        <% Do Until rs.EOF %>
        <article class="playlist-card">
            <a class="playlist-cover" href="<%= U("playlist.asp") %>?id=<%= rs("ID_PLAYLIST").Value %>">
                <span class="playlist-type <%= IfElse(CLng(rs("TYPE").Value) = 1, "is-private", "is-public") %>">
                    <%= H(PlaylistTypeName(rs("TYPE").Value)) %>
                </span>
                <%= CoverHtml(rs("PHOTO").Value, rs("TITLE").Value, "cover") %>
            </a>
            <div class="playlist-body">
                <h3><%= H(rs("TITLE").Value) %></h3>
                <p><%= Plural(rs("SONGS").Value, "canción", "canciones") %> &middot; creada el <%= HumanDate(rs("CREATION_DATE").Value) %></p>
                <div class="card-actions">
                    <a class="btn btn-soft btn-sm" href="<%= U("playlist.asp") %>?id=<%= rs("ID_PLAYLIST").Value %>">
                        <%= Icon("play") %> Abrir
                    </a>
                    <a class="icon-btn" href="<%= U("playlist-form.asp") %>?id=<%= rs("ID_PLAYLIST").Value %>" title="Editar playlist" aria-label="Editar <%= H(rs("TITLE").Value) %>">
                        <%= Icon("edit") %>
                    </a>
                    <form method="post" action="<%= U("playlists.asp") %>" class="inline-form"
                          data-confirm="¿Eliminar la playlist &quot;<%= H(rs("TITLE").Value) %>&quot; y todas sus canciones?">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="id" value="<%= rs("ID_PLAYLIST").Value %>">
                        <button type="submit" class="icon-btn is-danger" title="Eliminar playlist" aria-label="Eliminar <%= H(rs("TITLE").Value) %>">
                            <%= Icon("trash") %>
                        </button>
                    </form>
                </div>
            </div>
        </article>
        <% rs.MoveNext %>
        <% Loop %>
    </div>
    <% End If %>
</section>

<%
rs.Close
Set rs = Nothing
%>
<!--#include file="includes/layout-bottom.asp"-->
