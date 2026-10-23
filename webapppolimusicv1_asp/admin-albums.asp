<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="includes/config.asp"-->
<!--#include file="includes/db.asp"-->
<!--#include file="includes/helpers.asp"-->
<!--#include file="includes/auth.asp"-->
<%
RequireAdmin

Dim rs, total, albumId, imagen, usos

PageTitle = "Álbumes"
PageEyebrow = "Administración"
NavActive = "admin-albums"

If IsPost() Then
    If PostStr("action") = "delete" Then
        albumId = PostInt("id", 0)
        If albumId > 0 Then
            If CLng(Scalar("SELECT COUNT(*) FROM TBL_ALBUM WHERE ID_ALBUM = ?", Array(albumId))) > 0 Then
                imagen = CStr(Scalar("SELECT ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = ?", Array(albumId)) & "")
                RunSql "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = ?", Array(albumId)
                RunSql "DELETE FROM TBL_ALBUM WHERE ID_ALBUM = ?", Array(albumId)

                If Left(LCase(imagen), 14) = "~/albumimages/" Then
                    usos = CLng(Scalar("SELECT COUNT(*) FROM TBL_ALBUM WHERE ALBUM_IMAGE_PATH = ?", Array(imagen)))
                    If usos = 0 Then EliminarArchivoFisico imagen
                End If
                SetFlash "ok", "Álbum eliminado. Las canciones permanecen en el catálogo."
            Else
                SetFlash "error", "El álbum ya no existe."
            End If
        End If
        DbClose
        RedirectTo U("admin-albums.asp")
    End If
End If

Set rs = DBQuery("SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
            "       (SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) AS SONGS " & _
            "FROM TBL_ALBUM a ORDER BY a.TITLE_ALBUM", Array())
total = rs.RecordCount
%>
<!--#include file="includes/layout-top.asp"-->

<section class="section">
    <div class="section-head">
        <div class="section-title">
            <h2>Catálogo de álbumes</h2>
            <p>Agrupa las canciones en álbumes con portada y año de lanzamiento.</p>
        </div>
        <div class="section-actions">
            <a class="btn btn-primary" href="<%= U("admin-album-form.asp") %>"><%= Icon("plus") %> Nuevo álbum</a>
        </div>
    </div>

    <div class="panel">
        <div class="table-tools">
            <div class="searchbox">
                <%= Icon("search") %>
                <input type="search" placeholder="Filtrar álbumes…" data-table-search="tablaAlbumes" aria-label="Filtrar álbumes">
            </div>
            <span class="badge"><%= Plural(total, "álbum", "álbumes") %></span>
            <a class="btn btn-ghost btn-sm" href="<%= U("albums.asp") %>">Ver galería</a>
        </div>

        <div class="table-scroll">
            <table class="data-table" id="tablaAlbumes">
                <thead>
                    <tr>
                        <th scope="col">Álbum</th>
                        <th scope="col" class="num">Año</th>
                        <th scope="col" class="num">Canciones</th>
                        <th scope="col" style="text-align:right;">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                <% If total = 0 Then %>
                    <tr><td colspan="4">
                        <div class="empty">
                            <span class="empty-icon"><%= Icon("album") %></span>
                            <h3>Sin álbumes</h3>
                            <p>Crea el primer álbum para organizar las canciones.</p>
                            <a class="btn btn-primary" href="<%= U("admin-album-form.asp") %>"><%= Icon("plus") %> Crear álbum</a>
                        </div>
                    </td></tr>
                <% Else %>
                    <% Do Until rs.EOF %>
                    <tr>
                        <td>
                            <div class="cell-main">
                                <%= CoverHtml(rs("ALBUM_IMAGE_PATH").Value, rs("TITLE_ALBUM").Value, "cover cover-xs") %>
                                <span>
                                    <strong><%= H(rs("TITLE_ALBUM").Value) %></strong>
                                    <small class="mono"><%= H(ShortText(rs("ALBUM_IMAGE_PATH").Value, 40)) %></small>
                                </span>
                            </div>
                        </td>
                        <td class="num"><%= IfElse(IsNull(rs("RELEASE_YEAR").Value), "—", rs("RELEASE_YEAR").Value) %></td>
                        <td class="num"><%= rs("SONGS").Value %></td>
                        <td>
                            <div class="row-actions">
                                <a class="icon-btn" href="<%= U("admin-album-form.asp") %>?id=<%= rs("ID_ALBUM").Value %>" title="Editar" aria-label="Editar <%= H(rs("TITLE_ALBUM").Value) %>">
                                    <%= Icon("edit") %>
                                </a>
                                <form method="post" action="<%= U("admin-albums.asp") %>" class="inline-form"
                                      data-confirm="¿Eliminar el álbum &quot;<%= H(rs("TITLE_ALBUM").Value) %>&quot;? Las canciones no se borrarán.">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="id" value="<%= rs("ID_ALBUM").Value %>">
                                    <button type="submit" class="icon-btn is-danger" title="Eliminar" aria-label="Eliminar <%= H(rs("TITLE_ALBUM").Value) %>">
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
