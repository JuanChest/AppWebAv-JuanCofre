<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireLogin

Dim rs, total

PageTitle = "Artistas"
PageEyebrow = "Explorar"
NavActive = "artists"

Set rs = DBQuery("SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
            "       (SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = a.ID_ARTIST) AS SONGS " & _
            "FROM TBL_ARTIST a ORDER BY a.ARTIST_NAME", Array())
total = rs.RecordCount
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Artistas del catálogo</h2>
            <p><%= Plural(total, "artista registrado", "artistas registrados") %> en PoliMusic.</p>
        </div>
        <% If IsAdmin() Then %>
        <div class="section-actions">
            <a class="btn btn-primary btn-sm" href="<%= U("admin-artist-form.asp") %>"><%= Icon("plus") %> Nuevo artista</a>
        </div>
        <% End If %>
    </div>

    <% If total = 0 Then %>
    <div class="panel">
        <div class="empty">
            <span class="empty-icon"><%= Icon("artist") %></span>
            <h3>Todavía no hay artistas</h3>
            <p>Un administrador puede registrar artistas y asociarlos a las canciones.</p>
            <% If IsAdmin() Then %>
            <a class="btn btn-primary" href="<%= U("admin-artist-form.asp") %>"><%= Icon("plus") %> Registrar artista</a>
            <% End If %>
        </div>
    </div>
    <% Else %>
    <div class="grid-artists">
        <% Do Until rs.EOF %>
        <article class="artist-card">
            <%= AvatarHtml(rs("ARTIST_IMAGE").Value, rs("ARTIST_NAME").Value, "avatar") %>
            <div class="artist-body">
                <strong><%= H(Trim(rs("ARTIST_NAME").Value & " " & rs("ARTIST_LASTNAME").Value & "")) %></strong>
                <small><%= Plural(rs("SONGS").Value, "canción", "canciones") %></small>
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
