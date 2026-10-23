<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireAdmin

Dim rs, total, artistId, imagen, usos

PageTitle = "Artistas"
PageEyebrow = "Administración"
NavActive = "admin-artists"

If IsPost() Then
    If PostStr("action") = "delete" Then
        artistId = PostInt("id", 0)
        If artistId > 0 Then
            imagen = CStr(Scalar("SELECT ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = ?", Array(artistId)) & "")
            If CLng(Scalar("SELECT COUNT(*) FROM TBL_ARTIST WHERE ID_ARTIST = ?", Array(artistId))) > 0 Then
                RunSql "DELETE FROM TBL_PLAYER WHERE ID_ARTIST = ?", Array(artistId)
                RunSql "DELETE FROM TBL_ARTIST WHERE ID_ARTIST = ?", Array(artistId)

                If Left(LCase(imagen), 15) = "~/artistimages/" Then
                    usos = CLng(Scalar("SELECT COUNT(*) FROM TBL_ARTIST WHERE ARTIST_IMAGE = ?", Array(imagen)))
                    If usos = 0 Then EliminarArchivoFisico imagen
                End If
                SetFlash "ok", "Artista eliminado. Sus canciones siguen en el catálogo sin este artista."
            Else
                SetFlash "error", "El artista ya no existe."
            End If
        End If
        DbClose
        RedirectTo U("admin-artists.asp")
    End If
End If

Set rs = DBQuery("SELECT a.ID_ARTIST, a.ARTIST_NAME, a.ARTIST_LASTNAME, a.ARTIST_IMAGE, " & _
            "       (SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = a.ID_ARTIST) AS SONGS " & _
            "FROM TBL_ARTIST a ORDER BY a.ARTIST_NAME", Array())
total = rs.RecordCount
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Catálogo de artistas</h2>
            <p>Registra y mantén los artistas que participan en las canciones.</p>
        </div>
        <div class="section-actions">
            <a class="btn btn-primary" href="<%= U("admin-artist-form.asp") %>"><%= Icon("plus") %> Nuevo artista</a>
        </div>
    </div>

    <div class="panel">
        <div class="table-tools">
            <div class="searchbox">
                <%= Icon("search") %>
                <input type="search" placeholder="Filtrar artistas…" data-table-search="tablaArtistas" aria-label="Filtrar artistas">
            </div>
            <span class="badge"><%= Plural(total, "artista", "artistas") %></span>
            <a class="btn btn-ghost btn-sm" href="<%= U("artists.asp") %>">Ver galería</a>
        </div>

        <div class="table-scroll">
            <table class="data-table" id="tablaArtistas">
                <thead>
                    <tr>
                        <th scope="col">Artista</th>
                        <th scope="col" class="num">Canciones</th>
                        <th scope="col" style="text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                <% If total = 0 Then %>
                    <tr><td colspan="3">
                        <div class="empty">
                            <span class="empty-icon"><%= Icon("artist") %></span>
                            <h3>Sin artistas</h3>
                            <p>Registra el primer artista para asociarlo a las canciones.</p>
                            <a class="btn btn-primary" href="<%= U("admin-artist-form.asp") %>"><%= Icon("plus") %> Registrar artista</a>
                        </div>
                    </td></tr>
                <% Else %>
                    <% Do Until rs.EOF %>
                    <tr>
                        <td>
                            <div class="cell-main">
                                <%= AvatarHtml(rs("ARTIST_IMAGE").Value, rs("ARTIST_NAME").Value, "avatar") %>
                                <span>
                                    <strong><%= H(Trim(rs("ARTIST_NAME").Value & " " & rs("ARTIST_LASTNAME").Value & "")) %></strong>
                                    <small><%= IfElse(CStr(rs("ARTIST_LASTNAME").Value & "") = "", "Sin apellido registrado", "ID " & rs("ID_ARTIST").Value) %></small>
                                </span>
                            </div>
                        </td>
                        <td class="num"><%= rs("SONGS").Value %></td>
                        <td>
                            <div class="row-actions">
                                <a class="icon-btn" href="<%= U("admin-artist-form.asp") %>?id=<%= rs("ID_ARTIST").Value %>" title="Editar" aria-label="Editar <%= H(rs("ARTIST_NAME").Value) %>">
                                    <%= Icon("edit") %>
                                </a>
                                <form method="post" action="<%= U("admin-artists.asp") %>" class="inline-form"
                                      data-confirm="¿Eliminar al artista &quot;<%= H(Trim(rs("ARTIST_NAME").Value & " " & rs("ARTIST_LASTNAME").Value & "")) %>&quot;? Se quitará de sus canciones.">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="id" value="<%= rs("ID_ARTIST").Value %>">
                                    <button type="submit" class="icon-btn is-danger" title="Eliminar" aria-label="Eliminar <%= H(rs("ARTIST_NAME").Value) %>">
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
