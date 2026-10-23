/* ==========================================================================
   PoliMusic - Interacciones: reproductor global, menú, búsqueda y modales
   ========================================================================== */
(function () {
    'use strict';

    var $ = function (sel, ctx) { return (ctx || document).querySelector(sel); };
    var $$ = function (sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); };

    /* ------------------------------------------------------------- Reproductor */
    var audio = $('#audio');
    var queue = [];
    var index = -1;
    var reported = {};

    function fmtTime(sec) {
        if (!isFinite(sec) || sec < 0) { return '0:00'; }
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return m + ':' + (s < 10 ? '0' + s : s);
    }

    function setFill(el, pct) {
        if (el) { el.style.setProperty('--fill', Math.max(0, Math.min(100, pct)) + '%'); }
    }

    function collectQueue() {
        queue = $$('[data-track]').map(function (el) {
            return {
                el: el,
                id: el.getAttribute('data-id'),
                title: el.getAttribute('data-title') || '',
                artist: el.getAttribute('data-artist') || '',
                src: el.getAttribute('data-src') || '',
                cover: el.getAttribute('data-cover') || ''
            };
        });
        var badge = $('#queueCount');
        if (badge) { badge.textContent = queue.length; }
        $$('.js-play-all').forEach(function (btn) {
            btn.disabled = queue.length === 0;
        });
    }

    function markRow(track) {
        $$('[data-track]').forEach(function (el) { el.classList.remove('is-playing'); });
        if (track && track.el) { track.el.classList.add('is-playing'); }
    }

    function paintCover(track) {
        var box = $('#playerCover');
        if (!box) { return; }
        box.classList.remove('is-tile');
        if (track && track.cover) {
            box.innerHTML = '<img src="' + track.cover + '" alt="">';
        } else {
            box.classList.add('is-tile');
            box.textContent = track && track.title ? track.title.charAt(0).toUpperCase() : '♪';
        }
    }

    function setPlayingUI(playing) {
        var icon = $('#btnPlayIcon');
        var btn = $('#btnPlay');
        var eq = $('#playerEq');
        var vinyl = $('.vinyl');
        if (icon) { icon.innerHTML = playing ? pauseIcon : playIcon; }
        if (btn) {
            btn.setAttribute('aria-label', playing ? 'Pausar' : 'Reproducir');
            btn.title = playing ? 'Pausar' : 'Reproducir';
        }
        if (eq) { eq.classList.toggle('is-on', playing); }
        if (vinyl) { vinyl.classList.toggle('is-spinning', playing); }
    }

    var playIcon = '<svg class="icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M8 5.2v13.6L19 12z"/></svg>';
    var pauseIcon = '<svg class="icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><rect x="6" y="5" width="4" height="14" rx="1"/><rect x="14" y="5" width="4" height="14" rx="1"/></svg>';

    function reportPlay(track) {
        if (!track || !track.id || reported[track.id]) { return; }
        reported[track.id] = true;
        var base = (window.POLI && window.POLI.base) || '/';
        fetch(base + 'api-play.asp?id=' + encodeURIComponent(track.id), { credentials: 'same-origin' })
            .catch(function () { /* silencioso */ });
        $$('[data-track][data-id="' + track.id + '"] .js-play-count').forEach(function (cell) {
            var n = parseInt(cell.textContent.replace(/[^0-9]/g, ''), 10);
            if (!isNaN(n)) { cell.textContent = n + 1; }
        });
    }

    function playAt(i) {
        if (!audio || i < 0 || i >= queue.length) { return; }
        index = i;
        var track = queue[i];

        if (!track.src) {
            var meta = $('#playerArtist');
            if (meta) { meta.textContent = 'Archivo no disponible'; }
            return;
        }

        $('#playerTitle').textContent = track.title;
        $('#playerArtist').textContent = track.artist || 'Artista desconocido';
        paintCover(track);
        markRow(track);

        audio.src = track.src;
        var p = audio.play();
        if (p && p.catch) {
            p.catch(function () {
                $('#playerArtist').textContent = 'No se pudo reproducir este archivo';
                setPlayingUI(false);
            });
        }
    }

    function togglePlay() {
        if (!audio) { return; }
        if (index < 0 && queue.length) {
            playAt(0);
            return;
        }
        if (!audio.src) { return; }
        if (audio.paused) {
            audio.play().catch(function () {});
        } else {
            audio.pause();
        }
    }

    if (audio) {
        collectQueue();

        audio.volume = 0.8;
        var vol = $('#volume');
        var btnMute = $('#btnMute');
        var lastVolume = 0.8;
        if (vol) { setFill(vol, 80); }
        if (vol) {
            vol.addEventListener('input', function () {
                audio.volume = Number(this.value);
                lastVolume = audio.volume;
                setFill(this, audio.volume * 100);
                if (btnMute) {
                    $('#btnMuteIcon').innerHTML = audio.volume === 0 ? muteIcon : volumeIcon;
                }
            });
        }
        if (btnMute) {
            btnMute.addEventListener('click', function () {
                if (audio.volume > 0) {
                    lastVolume = audio.volume;
                    audio.volume = 0;
                } else {
                    audio.volume = lastVolume || 0.8;
                }
                if (vol) {
                    vol.value = audio.volume;
                    setFill(vol, audio.volume * 100);
                }
                $('#btnMuteIcon').innerHTML = audio.volume === 0 ? muteIcon : volumeIcon;
            });
        }

        var play = $('#btnPlay');
        if (play) { play.addEventListener('click', togglePlay); }

        var prev = $('#btnPrev');
        if (prev) {
            prev.addEventListener('click', function () {
                if (!queue.length) { return; }
                playAt(index <= 0 ? queue.length - 1 : index - 1);
            });
        }

        var next = $('#btnNext');
        if (next) {
            next.addEventListener('click', function () {
                if (!queue.length) { return; }
                playAt(index + 1 >= queue.length ? 0 : index + 1);
            });
        }

        var seek = $('#seek');
        if (seek) {
            seek.addEventListener('input', function () {
                if (audio.duration) { audio.currentTime = (Number(this.value) / 100) * audio.duration; }
                setFill(this, Number(this.value));
            });
        }

        audio.addEventListener('play', function () {
            setPlayingUI(true);
            var track = queue[index];
            if (track) {
                $('#playerTitle').textContent = track.title;
                $('#playerArtist').textContent = track.artist || 'Artista desconocido';
                paintCover(track);
                reportPlay(track);
            }
        });
        audio.addEventListener('pause', function () { setPlayingUI(false); });
        audio.addEventListener('ended', function () {
            if (index + 1 < queue.length) { playAt(index + 1); }
            else { setPlayingUI(false); }
        });
        audio.addEventListener('loadedmetadata', function () {
            var d = $('#durTime');
            if (d) { d.textContent = fmtTime(audio.duration); }
        });
        audio.addEventListener('timeupdate', function () {
            var cur = $('#curTime');
            if (cur) { cur.textContent = fmtTime(audio.currentTime); }
            var dur = $('#durTime');
            if (dur && audio.duration) { dur.textContent = fmtTime(audio.duration); }
            if (seek && audio.duration) {
                var pct = (audio.currentTime / audio.duration) * 100;
                if (!seek.matches(':active')) { seek.value = pct; }
                setFill(seek, pct);
            }
        });
        audio.addEventListener('error', function () {
            var meta = $('#playerArtist');
            if (meta && audio.src) { meta.textContent = 'No se pudo cargar el audio'; }
            setPlayingUI(false);
        });

        $$('.js-play').forEach(function (btn) {
            btn.addEventListener('click', function (ev) {
                ev.preventDefault();
                var row = this.closest('[data-track]');
                var i = queue.findIndex(function (t) { return t.el === row; });
                if (i >= 0) {
                    if (index === i && !audio.paused) { audio.pause(); }
                    else { playAt(i); }
                }
            });
        });

        $$('.js-play-all').forEach(function (btn) {
            btn.addEventListener('click', function (ev) {
                ev.preventDefault();
                if (queue.length) { playAt(0); }
            });
        });

        document.addEventListener('keydown', function (ev) {
            var tag = (ev.target.tagName || '').toLowerCase();
            if (tag === 'input' || tag === 'textarea' || tag === 'select' || ev.target.isContentEditable) { return; }
            if (ev.code === 'Space') {
                ev.preventDefault();
                togglePlay();
            }
        });
    }

    var volumeIcon = '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 10v4h3l4 3.5v-11L7 10z"/><path d="M15 9.2a4 4 0 0 1 0 5.6M17.6 6.8a7.5 7.5 0 0 1 0 10.4"/></svg>';
    var muteIcon = '<svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 10v4h3l4 3.5v-11L7 10z"/><path d="M15.5 10l4 4M19.5 10l-4 4"/></svg>';

    /* --------------------------------------------------------------- Sidebar */
    var body = document.body;
    var menuBtn = $('#menuBtn');
    var scrim = $('#scrim');

    function closeSidebar() {
        body.classList.remove('sidebar-open');
        if (menuBtn) { menuBtn.setAttribute('aria-expanded', 'false'); }
    }

    if (menuBtn) {
        menuBtn.addEventListener('click', function () {
            var open = body.classList.toggle('sidebar-open');
            this.setAttribute('aria-expanded', open ? 'true' : 'false');
        });
    }
    if (scrim) { scrim.addEventListener('click', closeSidebar); }

    document.addEventListener('keydown', function (ev) {
        if (ev.key === 'Escape') {
            closeSidebar();
            closeModal();
        }
    });

    /* ---------------------------------------------------------------- Flash */
    $$('.flash-close').forEach(function (btn) {
        btn.addEventListener('click', function () {
            var f = this.closest('.flash');
            if (f) { f.remove(); }
        });
    });

    /* ------------------------------------------------------- Confirmaciones */
    $$('form[data-confirm]').forEach(function (form) {
        form.addEventListener('submit', function (ev) {
            if (!window.confirm(this.getAttribute('data-confirm'))) { ev.preventDefault(); }
        });
    });

    /* -------------------------------------------------------------- Búsqueda */
    var search = $('#songSearch');
    if (search) {
        search.addEventListener('input', function () {
            var q = this.value.toLowerCase().trim();
            var rows = $$('[data-track]');
            var visible = 0;
            rows.forEach(function (row) {
                var text = row.textContent.toLowerCase();
                var ok = q === '' || text.indexOf(q) !== -1;
                row.hidden = !ok;
                if (ok) { visible++; }
            });
            var count = $('#songVisible');
            if (count) { count.textContent = visible; }
            var empty = $('#searchEmpty');
            if (empty) { empty.hidden = visible !== 0; }
        });
    }

    /* ---------------------------------------------------------------- Modales */
    var modal = $('#addModal');
    var addSongId = $('#addSongId');
    var addSongLabel = $('#addSongLabel');

    function openModal(btn) {
        if (!modal) { return; }
        if (addSongId) { addSongId.value = btn.getAttribute('data-add-song'); }
        if (addSongLabel) { addSongLabel.textContent = btn.getAttribute('data-song-title') || 'Canción'; }
        modal.hidden = false;
        var select = modal.querySelector('select');
        if (select) { select.focus(); }
    }

    function closeModal() {
        if (modal) { modal.hidden = true; }
    }

    $$('[data-add-song]').forEach(function (btn) {
        btn.addEventListener('click', function () { openModal(this); });
    });
    $$('[data-modal-close]').forEach(function (btn) {
        btn.addEventListener('click', closeModal);
    });
    if (modal) {
        modal.addEventListener('click', function (ev) {
            if (ev.target === modal) { closeModal(); }
        });
    }

    /* ------------------------------------------------- Filtrar tablas admin */
    $$('[data-table-search]').forEach(function (input) {
        input.addEventListener('input', function () {
            var table = document.getElementById(this.getAttribute('data-table-search'));
            if (!table) { return; }
            var q = this.value.toLowerCase().trim();
            $$('tbody tr', table).forEach(function (row) {
                row.hidden = q !== '' && row.textContent.toLowerCase().indexOf(q) === -1;
            });
        });
    });
})();
