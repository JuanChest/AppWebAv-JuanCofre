using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : System.Web.UI.Page
    {
        private readonly string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                LoadUserProfile();
                LoadSongsTable();
            }
        }

        private void LoadUserProfile()
        {
            EntityLayer.PoliMusicV3.User user = Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User;

            if (user != null)
            {
                lblUserName.Text = Server.HtmlEncode(user.UserName);
                lblUserEmail.Text = Server.HtmlEncode(user.Email);

                string photoVirtualPath = string.IsNullOrWhiteSpace(user.Photo) ? "~/UserImages/default.jpg" : user.Photo;
                string physicalPath = Server.MapPath(photoVirtualPath);
                if (!File.Exists(physicalPath))
                {
                    photoVirtualPath = "~/UserImages/default.jpg";
                }
                imgUserPhoto.ImageUrl = ResolveUrl(photoVirtualPath);
            }
            else if (User != null && User.Identity != null && User.Identity.IsAuthenticated)
            {
                lblUserName.Text = Server.HtmlEncode(User.Identity.Name);
                lblUserEmail.Text = "Sesión activa";
                imgUserPhoto.ImageUrl = ResolveUrl("~/UserImages/default.jpg");
            }
            else
            {
                Response.Redirect("~/Login.aspx", true);
            }
        }

        private void LoadSongsTable()
        {
            DataTable dtSongs = new BLL.PoliMusicV3.Song(strConnString).Read();
            StringBuilder sb = new StringBuilder();

            string[] playlistCovers = new string[]
            {
                "~/PlaylistImages/playlist1.png",
                "~/PlaylistImages/playlist2.png",
                "~/PlaylistImages/playlist3.png",
                "~/PlaylistImages/playlist4.png",
                "~/PlaylistImages/playlist5.png"
            };

            if (dtSongs != null && dtSongs.Rows.Count > 0)
            {
                lblTotalSongs.Text = dtSongs.Rows.Count + (dtSongs.Rows.Count == 1 ? " pista" : " pistas");
                int index = 0;

                foreach (DataRow row in dtSongs.Rows)
                {
                    int idSong = Convert.ToInt32(row["ID_SONG"]);
                    string songName = row["SONG_NAME"] != DBNull.Value ? row["SONG_NAME"].ToString() : string.Empty;
                    string rawPath = row["SONG_PATH"] != DBNull.Value ? row["SONG_PATH"].ToString() : string.Empty;
                    int plays = row["PLAYS"] != DBNull.Value ? Convert.ToInt32(row["PLAYS"]) : 0;

                    string resolvedAudioUrl = ResolveUrl(rawPath);
                    string coverVirtualPath = playlistCovers[index % playlistCovers.Length];
                    string resolvedCoverUrl = ResolveUrl(coverVirtualPath);
                    index++;

                    sb.AppendFormat("<tr class='pm-song-row' data-song-id='{0}' data-song-name='{1}'>",
                        idSong,
                        HttpUtility.HtmlAttributeEncode(songName));

                    // Columna 1: Id canción
                    sb.AppendFormat("<td class='pm-col-id'><span class='pm-id-pill'>#{0}</span></td>", idSong);

                    // Columna 2: Nombre (con miniatura de PlaylistImages)
                    sb.Append("<td><div class='pm-song-info'>");
                    sb.AppendFormat("<img src='{0}' alt='{1}' class='pm-song-cover' />",
                        resolvedCoverUrl,
                        HttpUtility.HtmlAttributeEncode(songName));
                    sb.Append("<div>");
                    sb.AppendFormat("<span class='pm-song-title'>{0}</span>", Server.HtmlEncode(songName));
                    sb.Append("<span class='pm-song-status'>&#9654; En reproducción</span>");
                    sb.Append("</div></div></td>");

                    // Columna 3: Ruta
                    sb.AppendFormat("<td><span class='pm-song-path'>{0}</span></td>", Server.HtmlEncode(rawPath));

                    // Columna 4: Reproducciones
                    sb.Append("<td style='text-align: center;'>");
                    sb.AppendFormat("<span class='pm-plays-badge'>&#9835; <span class='pm-plays-value'>{0}</span></span>", plays);
                    sb.Append("</td>");

                    // Columna 5: Reproducir
                    sb.Append("<td>");
                    sb.AppendFormat("<audio class='pm-audio-player' controls preload='none'><source src='{0}' type='audio/mpeg' />Tu navegador no soporta reproducción de audio.</audio>",
                        resolvedAudioUrl);
                    sb.Append("</td>");

                    sb.Append("</tr>");
                }
            }
            else
            {
                lblTotalSongs.Text = "0 pistas";
                sb.Append("<tr><td colspan='5' class='pm-empty-state'>No hay canciones registradas en la base de datos.</td></tr>");
            }

            litSongsRows.Text = sb.ToString();
        }

        [WebMethod]
        public static bool IncrementPlays(int idSong)
        {
            try
            {
                string connStr = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
                int updated = new BLL.PoliMusicV3.Song(connStr).IncrementPlays(idSong);
                return updated > 0;
            }
            catch
            {
                return false;
            }
        }
    }
}
