<%
' ===========================================================================
'  layout-bottom.asp  -  Reproductor global, scripts y cierre del documento
' ===========================================================================
%>
        </main>
    </div>
</div>

<div class="player" id="player" aria-label="Reproductor">
    <div class="player-track">
        <span class="player-cover" id="playerCover">
            <%= Icon("music") %>
        </span>
        <div class="player-meta">
            <strong id="playerTitle">Nada sonando</strong>
            <span id="playerArtist">Elige una canción del Song List</span>
        </div>
        <span class="player-eq" id="playerEq" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
    </div>

    <div class="player-center">
        <div class="player-controls">
            <button type="button" class="icon-btn" id="btnPrev" title="Anterior" aria-label="Canción anterior">
                <%= Icon("prev") %>
            </button>
            <button type="button" class="play-toggle" id="btnPlay" title="Reproducir" aria-label="Reproducir">
                <span id="btnPlayIcon"><%= Icon("play") %></span>
            </button>
            <button type="button" class="icon-btn" id="btnNext" title="Siguiente" aria-label="Canción siguiente">
                <%= Icon("next") %>
            </button>
        </div>
        <div class="player-progress">
            <span class="time" id="curTime">0:00</span>
            <input type="range" id="seek" class="range" min="0" max="100" step="0.1" value="0" aria-label="Progreso de la canción">
            <span class="time" id="durTime">0:00</span>
        </div>
    </div>

    <div class="player-extra">
        <button type="button" class="icon-btn" id="btnMute" title="Silenciar" aria-label="Silenciar">
            <span id="btnMuteIcon"><%= Icon("volume") %></span>
        </button>
        <input type="range" id="volume" class="range range-vol" min="0" max="1" step="0.01" value="0.8" aria-label="Volumen">
        <span class="queue-pill" title="Canciones en cola">
            <%= Icon("playlist") %><span id="queueCount">0</span>
        </span>
    </div>

    <audio id="audio" preload="metadata"></audio>
</div>

<script>
window.POLI = { base: "<%= gBase %>" };
</script>
<script src="<%= U("js/app.js") %>"></script>
</body>
</html>
<%
DbClose
%>
