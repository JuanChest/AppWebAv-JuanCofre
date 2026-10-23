<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireLogin

Dim rs, total

PageTitle = "Álbumes"
PageEyebrow = "Explorar"
NavActive = "albums"

Set rs = DBQuery("SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
            "       (SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) AS SONGS " & _
            "FROM TBL_ALBUM a ORDER BY a.TITLE_ALBUM", Array())
total = rs.RecordCount
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Álbumes del catálogo</h2>
            <p><%= Plural(total, "álbum disponible", "álbumes disponibles") %> en PoliMusic.</p>
        </div>
        <% If IsAdmin() Then %>
        <div class="section-actions">
            <a class="btn btn-primary btn-sm" href="<%= U("admin-album-form.asp") %>"><%= Icon("plus") %> Nuevo álbum</a>
        </div>
        <% End If %>
    </div>

    <% If total = 0 Then %>
    <div class="panel">
        <div class="empty">
            <span class="empty-icon"><%= Icon("album") %></span>
            <h3>Todavía no hay álbumes</h3>
            <p>Cuando un administrador cree un álbum, aparecerá en esta galería.</p>
            <% If IsAdmin() Then %>
            <a class="btn btn-primary" href="<%= U("admin-album-form.asp") %>"><%= Icon("plus") %> Crear álbum</a>
            <% End If %>
        </div>
    </div>
    <% Else %>
    <div class="grid-albums">
        <% Do Until rs.EOF %>
        <article class="album-card">
            <div class="album-art">
                <%= CoverHtml(rs("ALBUM_IMAGE_PATH").Value, rs("TITLE_ALBUM").Value, "cover") %>
                <% If Not IsNull(rs("RELEASE_YEAR").Value) Then %>
                <span class="album-year"><%= rs("RELEASE_YEAR").Value %></span>
                <% End If %>
            </div>
            <div class="album-body">
                <strong><%= H(rs("TITLE_ALBUM").Value) %></strong>
                <small><%= Plural(rs("SONGS").Value, "canción", "canciones") %></small>
            </div>
            <% If IsAdmin() Then %>
            <div class="card-actions">
                <a class="btn btn-ghost btn-sm" href="<%= U("admin-album-form.asp") %>?id=<%= rs("ID_ALBUM").Value %>"><%= Icon("edit") %> Editar</a>
            </div>
            <% End If %>
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
