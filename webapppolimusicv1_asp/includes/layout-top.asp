<%
' ===========================================================================
'  layout-top.asp  -  Cabecera, barra lateral y apertura del contenido
'  Requiere haber definido previamente: config, db, helpers, auth
'  Variables opcionales: PageTitle, PageEyebrow, NavActive
' ===========================================================================
If Not IsLoggedIn() Then RedirectTo U("login.asp")

%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><%= H(PageTitle) %> &middot; PoliMusic</title>
<link rel="stylesheet" href="<%= U("css/app.css") %>">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 64 64'%3E%3Crect width='64' height='64' rx='14' fill='%23ff6b1a'/%3E%3Cpath d='M18 40V24M26 46V18M34 38V26M42 44V20M50 34V30' stroke='%230b0b0d' stroke-width='5' stroke-linecap='round'/%3E%3C/svg%3E">
</head>
<body class="app-body">
<div class="app-shell">

    <aside class="sidebar" id="sidebar">
        <a class="brand" href="<%= U("home.asp") %>" aria-label="PoliMusic, inicio">
            <span class="brand-mark" aria-hidden="true">
                <i></i><i></i><i></i><i></i><i></i>
            </span>
            <span class="brand-text">
                <strong>Poli<span>Music</span></strong>
                <small>streaming club</small>
            </span>
        </a>

        <nav class="nav" aria-label="Principal">
            <span class="nav-label">Explorar</span>
            <a class="nav-link <%= IfElse(NavActive = "home", "is-active", "") %>" href="<%= U("home.asp") %>">
                <%= Icon("home") %><span>Inicio</span>
            </a>
            <a class="nav-link <%= IfElse(NavActive = "playlists", "is-active", "") %>" href="<%= U("playlists.asp") %>">
                <%= Icon("playlist") %><span>Mis playlists</span>
            </a>
            <a class="nav-link <%= IfElse(NavActive = "albums", "is-active", "") %>" href="<%= U("albums.asp") %>">
                <%= Icon("album") %><span>Álbumes</span>
            </a>
            <a class="nav-link <%= IfElse(NavActive = "artists", "is-active", "") %>" href="<%= U("artists.asp") %>">
                <%= Icon("artist") %><span>Artistas</span>
            </a>

            <% If IsAdmin() Then %>
            <span class="nav-label nav-label-admin">Administración</span>
            <a class="nav-link <%= IfElse(NavActive = "admin-songs", "is-active", "") %>" href="<%= U("admin-songs.asp") %>">
                <%= Icon("music") %><span>Canciones</span>
            </a>
            <a class="nav-link <%= IfElse(NavActive = "admin-albums", "is-active", "") %>" href="<%= U("admin-albums.asp") %>">
                <%= Icon("album") %><span>Álbumes</span>
            </a>
            <a class="nav-link <%= IfElse(NavActive = "admin-artists", "is-active", "") %>" href="<%= U("admin-artists.asp") %>">
                <%= Icon("artist") %><span>Artistas</span>
            </a>
            <% End If %>
        </nav>

        <div class="sidebar-tip">
            <span class="sidebar-tip-icon"><%= Icon("headphones") %></span>
            <p><strong>Song List</strong><br>Todo tu catálogo suena aquí, sin salir de la página.</p>
        </div>

        <div class="sidebar-user">
            <a class="sidebar-user-main" href="<%= U("playlists.asp") %>">
                <%= AvatarHtml(CurrentUserPhoto(), CurrentUserName(), "avatar avatar-md") %>
                <span>
                    <strong><%= H(CurrentUserName()) %></strong>
                    <small><%= H(RoleName(CurrentUserType())) %></small>
                </span>
            </a>
            <a class="icon-btn" href="<%= U("logout.asp") %>" title="Cerrar sesión" aria-label="Cerrar sesión">
                <%= Icon("logout") %>
            </a>
        </div>
    </aside>

    <div class="main">
        <header class="topbar">
            <button type="button" class="icon-btn menu-btn" id="menuBtn" aria-label="Abrir menú" aria-expanded="false" aria-controls="sidebar">
                <%= Icon("menu") %>
            </button>
            <div class="topbar-title">
                <span class="eyebrow"><%= H(PageEyebrow) %></span>
                <h1><%= H(PageTitle) %></h1>
            </div>
            <div class="topbar-actions">
                <span class="role-chip <%= IfElse(IsAdmin(), "role-admin", "role-user") %>">
                    <%= IfElse(IsAdmin(), "Admin", "Normal") %>
                </span>
                <span class="user-chip">
                    <%= AvatarHtml(CurrentUserPhoto(), CurrentUserName(), "avatar avatar-sm") %>
                    <span><%= H(CurrentUserName()) %></span>
                </span>
                <a class="icon-btn" href="<%= U("logout.asp") %>" title="Cerrar sesión" aria-label="Cerrar sesión">
                    <%= Icon("logout") %>
                </a>
            </div>
        </header>

        <div class="scrim" id="scrim"></div>

        <main class="content" id="mainContent">
            <% ShowFlash %>
