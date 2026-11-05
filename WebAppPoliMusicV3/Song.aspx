<%@ Page Title="Canciones" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Song.aspx.cs" Inherits="WebAppPoliMusicV3.Song" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <style>
        /* Modern & Minimalist Black-Blue Theme for PoliMusic */
        body {
            background-color: #060911 !important;
            background-image: 
                radial-gradient(circle at 15% 15%, rgba(29, 78, 216, 0.14) 0%, transparent 45%),
                radial-gradient(circle at 85% 80%, rgba(14, 165, 233, 0.1) 0%, transparent 45%);
            color: #e2e8f0 !important;
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            min-height: 100vh;
        }

        .navbar.bg-dark {
            background-color: rgba(6, 9, 17, 0.88) !important;
            backdrop-filter: blur(12px);
            border-bottom: 1px solid rgba(59, 130, 246, 0.2);
        }

        .body-content hr {
            border-color: rgba(59, 130, 246, 0.15);
        }

        .body-content footer {
            color: #64748b;
            font-size: 0.85rem;
        }

        .pm-wrapper {
            padding: 28px 0 40px;
        }

        /* User Hero / Header Card */
        .pm-hero {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
            align-items: center;
            gap: 20px;
            background: linear-gradient(135deg, rgba(15, 23, 42, 0.92) 0%, rgba(7, 11, 22, 0.96) 100%);
            border: 1px solid rgba(59, 130, 246, 0.25);
            border-radius: 16px;
            padding: 24px 30px;
            margin-bottom: 28px;
            box-shadow: 0 12px 32px -8px rgba(0, 0, 0, 0.7), 0 0 24px rgba(37, 99, 235, 0.1);
        }

        .pm-user-profile {
            display: flex;
            align-items: center;
            gap: 18px;
        }

        .pm-avatar {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid #3b82f6;
            box-shadow: 0 0 16px rgba(59, 130, 246, 0.45);
            background-color: #0f172a;
        }

        .pm-greeting-label {
            font-size: 0.75rem;
            text-transform: uppercase;
            letter-spacing: 1.5px;
            color: #38bdf8;
            font-weight: 600;
            margin-bottom: 2px;
            display: block;
        }

        .pm-greeting-title {
            font-size: 1.5rem;
            font-weight: 700;
            color: #f8fafc;
            margin: 0;
            letter-spacing: -0.3px;
        }

        .pm-greeting-sub {
            font-size: 0.85rem;
            color: #94a3b8;
            margin: 2px 0 0;
        }

        /* Search & Stats Bar */
        .pm-toolbar {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 16px;
            margin-bottom: 20px;
        }

        .pm-section-title {
            display: flex;
            align-items: center;
            gap: 12px;
            margin: 0;
            font-size: 1.2rem;
            font-weight: 600;
            color: #f1f5f9;
        }

        .pm-badge-count {
            background: rgba(37, 99, 235, 0.18);
            color: #60a5fa;
            border: 1px solid rgba(59, 130, 246, 0.35);
            font-size: 0.78rem;
            padding: 3px 10px;
            border-radius: 999px;
            font-weight: 600;
        }

        .pm-search-box {
            position: relative;
            min-width: 260px;
        }

        .pm-search-input {
            width: 100%;
            max-width: 320px;
            background: rgba(15, 23, 42, 0.85);
            border: 1px solid rgba(59, 130, 246, 0.28);
            border-radius: 10px;
            padding: 9px 14px 9px 36px;
            color: #f8fafc;
            font-size: 0.88rem;
            transition: all 0.2s ease;
            outline: none;
        }

        .pm-search-input::placeholder {
            color: #64748b;
        }

        .pm-search-input:focus {
            border-color: #3b82f6;
            box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.2);
            background: #0f172a;
        }

        .pm-search-icon {
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: #60a5fa;
            font-size: 0.85rem;
            pointer-events: none;
        }

        /* Songs Table Card */
        .pm-table-card {
            background: rgba(11, 17, 32, 0.9);
            border: 1px solid rgba(59, 130, 246, 0.22);
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 16px 40px -12px rgba(0, 0, 0, 0.75);
        }

        .pm-table-responsive {
            width: 100%;
            overflow-x: auto;
        }

        .pm-table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
        }

        .pm-table thead {
            background: linear-gradient(90deg, rgba(15, 23, 42, 0.98) 0%, rgba(23, 37, 84, 0.65) 100%);
            border-bottom: 1px solid rgba(59, 130, 246, 0.35);
        }

        .pm-table thead th {
            padding: 15px 20px;
            font-size: 0.75rem;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 1.1px;
            color: #60a5fa;
            white-space: nowrap;
        }

        .pm-table tbody tr {
            border-bottom: 1px solid rgba(30, 41, 59, 0.8);
            transition: background-color 0.2s ease, transform 0.15s ease;
        }

        .pm-table tbody tr:last-child {
            border-bottom: none;
        }

        .pm-table tbody tr:hover {
            background-color: rgba(30, 58, 138, 0.18);
        }

        .pm-table tbody tr.is-playing {
            background: linear-gradient(90deg, rgba(37, 99, 235, 0.22) 0%, rgba(14, 165, 233, 0.08) 100%);
            border-left: 3px solid #3b82f6;
        }

        .pm-table tbody td {
            padding: 14px 20px;
            vertical-align: middle;
            font-size: 0.92rem;
            color: #cbd5e1;
        }

        /* Table Cell Specific Styles */
        .pm-col-id {
            font-family: 'Consolas', 'Courier New', monospace;
            color: #64748b;
            font-weight: 600;
            width: 110px;
        }

        .pm-id-pill {
            display: inline-block;
            background: rgba(15, 23, 42, 0.9);
            border: 1px solid rgba(59, 130, 246, 0.25);
            color: #93c5fd;
            padding: 3px 10px;
            border-radius: 8px;
            font-size: 0.8rem;
        }

        .pm-song-info {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .pm-song-cover {
            width: 42px;
            height: 42px;
            border-radius: 10px;
            object-fit: cover;
            border: 1px solid rgba(59, 130, 246, 0.35);
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.4);
            flex-shrink: 0;
        }

        .pm-song-title {
            font-weight: 600;
            color: #f8fafc;
            font-size: 0.96rem;
            display: block;
        }

        .pm-song-status {
            font-size: 0.75rem;
            color: #38bdf8;
            display: none;
            align-items: center;
            gap: 5px;
            margin-top: 2px;
        }

        tr.is-playing .pm-song-status {
            display: inline-flex;
        }

        .pm-song-path {
            font-family: 'Consolas', 'Courier New', monospace;
            font-size: 0.8rem;
            color: #94a3b8;
            background: rgba(15, 23, 42, 0.65);
            padding: 4px 10px;
            border-radius: 6px;
            border: 1px solid rgba(51, 65, 85, 0.6);
            display: inline-block;
            word-break: break-all;
            max-width: 280px;
        }

        .pm-plays-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            background: rgba(29, 78, 216, 0.16);
            color: #60a5fa;
            border: 1px solid rgba(59, 130, 246, 0.3);
            padding: 5px 14px;
            border-radius: 999px;
            font-weight: 700;
            font-size: 0.85rem;
            min-width: 68px;
            transition: all 0.25s ease;
        }

        tr.is-playing .pm-plays-badge {
            background: #2563eb;
            color: #ffffff;
            box-shadow: 0 0 14px rgba(37, 99, 235, 0.5);
        }

        /* Audio Player Styling */
        .pm-audio-player {
            height: 36px;
            width: 250px;
            max-width: 100%;
            border-radius: 999px;
            outline: none;
            filter: invert(92%) hue-rotate(175deg) brightness(1.05) contrast(1.05);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .pm-audio-player:hover,
        .pm-audio-player:focus {
            transform: scale(1.02);
        }

        /* Now Playing Floating Bar */
        .pm-now-playing {
            margin-top: 20px;
            background: linear-gradient(90deg, rgba(15, 23, 42, 0.95) 0%, rgba(30, 58, 138, 0.35) 100%);
            border: 1px solid rgba(59, 130, 246, 0.3);
            border-radius: 12px;
            padding: 12px 20px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 0.88rem;
            color: #94a3b8;
        }

        .pm-now-playing strong {
            color: #60a5fa;
        }

        .pm-empty-state {
            text-align: center;
            padding: 40px 20px !important;
            color: #64748b !important;
            font-size: 0.95rem;
        }

        @media (max-width: 768px) {
            .pm-hero {
                padding: 18px 20px;
            }
            .pm-audio-player {
                width: 190px;
            }
        }
    </style>

    <div class="pm-wrapper">
        <!-- Hero User Banner -->
        <div class="pm-hero">
            <div class="pm-user-profile">
                <asp:Image ID="imgUserPhoto" runat="server" CssClass="pm-avatar" AlternateText="Foto de perfil" />
                <div>
                    <span class="pm-greeting-label">PoliMusic Studio</span>
                    <h1 class="pm-greeting-title">
                        Bienvenido, <asp:Label ID="lblUserName" runat="server" Text="Usuario"></asp:Label>
                    </h1>
                    <p class="pm-greeting-sub">
                        <asp:Label ID="lblUserEmail" runat="server" Text=""></asp:Label>
                    </p>
                </div>
            </div>
            <div class="pm-now-playing" style="margin-top: 0;">
                <span>&#9835; Estado del reproductor: <strong id="nowPlayingText">Listo para reproducir</strong></span>
            </div>
        </div>

        <!-- Toolbar: Title + Filter -->
        <div class="pm-toolbar">
            <h2 class="pm-section-title">
                Catálogo de Canciones
                <asp:Label ID="lblTotalSongs" runat="server" CssClass="pm-badge-count" Text="0 pistas"></asp:Label>
            </h2>
            <div class="pm-search-box">
                <span class="pm-search-icon">&#128269;</span>
                <input type="text" id="txtSearchSong" class="pm-search-input" placeholder="Filtrar por nombre o ruta..." aria-label="Filtrar canciones" />
            </div>
        </div>

        <!-- Songs Table -->
        <div class="pm-table-card">
            <div class="pm-table-responsive">
                <table class="pm-table" id="tblSongs">
                    <thead>
                        <tr>
                            <th>Id canción</th>
                            <th>Nombre</th>
                            <th>Ruta</th>
                            <th style="text-align: center;">Reproducciones</th>
                            <th>Reproducir</th>
                        </tr>
                    </thead>
                    <tbody>
                        <asp:Literal ID="litSongsRows" runat="server"></asp:Literal>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <script type="text/javascript">
        document.addEventListener("DOMContentLoaded", function () {
            var audioElements = document.querySelectorAll(".pm-audio-player");
            var nowPlayingText = document.getElementById("nowPlayingText");
            var searchInput = document.getElementById("txtSearchSong");
            var tableRows = document.querySelectorAll("#tblSongs tbody tr.pm-song-row");

            // Manage exclusive playback & play count increment
            audioElements.forEach(function (audio) {
                audio.addEventListener("play", function () {
                    // Pause any other playing song
                    audioElements.forEach(function (otherAudio) {
                        if (otherAudio !== audio && !otherAudio.paused) {
                            otherAudio.pause();
                        }
                    });

                    // Highlight active row
                    tableRows.forEach(function (row) {
                        row.classList.remove("is-playing");
                    });

                    var currentRow = audio.closest("tr");
                    if (currentRow) {
                        currentRow.classList.add("is-playing");
                        var songName = currentRow.getAttribute("data-song-name") || "Canción";
                        var songId = currentRow.getAttribute("data-song-id");
                        if (nowPlayingText) {
                            nowPlayingText.textContent = "Reproduciendo: " + songName;
                        }

                        // Increment play counter once per play start if not already counted in this session
                        if (!audio.dataset.counted) {
                            audio.dataset.counted = "true";
                            var playsEl = currentRow.querySelector(".pm-plays-value");
                            if (playsEl) {
                                var currentPlays = parseInt(playsEl.textContent, 10) || 0;
                                playsEl.textContent = currentPlays + 1;
                            }

                            if (songId) {
                                fetch("Song.aspx/IncrementPlays", {
                                    method: "POST",
                                    headers: { "Content-Type": "application/json; charset=utf-8" },
                                    body: JSON.stringify({ idSong: parseInt(songId, 10) })
                                }).catch(function () { });
                            }
                        }
                    }
                });

                audio.addEventListener("ended", function () {
                    audio.dataset.counted = "";
                    var currentRow = audio.closest("tr");
                    if (currentRow) {
                        currentRow.classList.remove("is-playing");
                    }
                    if (nowPlayingText) {
                        nowPlayingText.textContent = "Reproducción finalizada";
                    }
                });
            });

            // Client-side instant search filter
            if (searchInput) {
                searchInput.addEventListener("input", function () {
                    var query = searchInput.value.toLowerCase().trim();
                    tableRows.forEach(function (row) {
                        var text = row.textContent.toLowerCase();
                        row.style.display = text.indexOf(query) !== -1 ? "" : "none";
                    });
                });
            }
        });
    </script>
</asp:Content>
