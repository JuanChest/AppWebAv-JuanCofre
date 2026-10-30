using System;
using System.Configuration;
using System.Data;
using System.Text;
using System.Web;
using System.Web.UI;

namespace WebAppPoliMusicV2
{
    public partial class Song : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            Entities.User user = Session[Util.Constants.USER] as Entities.User;
            if (user == null)
            {
                Response.Redirect("Login.aspx", true);
                return;
            }

            StringBuilder html = new StringBuilder();

            html.Append("<style>");
            html.Append("*{margin:0;padding:0;box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif;}");
            html.Append("body{background:#0d0d0d;color:#e6e6e6;min-height:100vh;padding:30px 20px;}");
            html.Append(".container{max-width:1000px;margin:0 auto;}");
            html.Append(".header{display:flex;justify-content:space-between;align-items:center;");
            html.Append("background:linear-gradient(90deg,#0f2f1a,#000);border:1px solid #1db954;");
            html.Append("border-radius:12px;padding:20px 30px;margin-bottom:30px;box-shadow:0 4px 20px rgba(29,185,84,.25);}");
            html.Append(".header h1{font-size:24px;font-weight:600;color:#1db954;}");
            html.Append(".header h1 span{color:#fff;}");
            html.Append(".btn-logout{background:#1db954;color:#000;border:none;border-radius:20px;");
            html.Append("padding:10px 22px;font-size:14px;font-weight:700;cursor:pointer;transition:all .3s;}");
            html.Append(".btn-logout:hover{background:#17a747;transform:scale(1.05);}");
            html.Append(".table-wrapper{background:#161616;border:1px solid #222;border-radius:12px;overflow:hidden;}");
            html.Append("table{width:100%;border-collapse:collapse;}");
            html.Append("thead{background:#0f2f1a;}");
            html.Append("thead th{color:#1db954;padding:14px 16px;text-align:left;font-size:13px;");
            html.Append("text-transform:uppercase;letter-spacing:1px;border-bottom:1px solid #1db954;}");
            html.Append("tbody td{padding:12px 16px;border-bottom:1px solid #222;font-size:14px;vertical-align:middle;}");
            html.Append("tbody tr:hover{background:#1a1a1a;}");
            html.Append("tbody tr:last-child td{border-bottom:none;}");
            html.Append(".song-id{color:#777;font-size:12px;}");
            html.Append(".song-name{color:#fff;font-weight:600;}");
            html.Append(".song-path{color:#888;font-size:12px;word-break:break-all;max-width:220px;}");
            html.Append(".song-plays{color:#1db954;font-weight:700;text-align:center;}");
            html.Append("audio{height:34px;width:220px;outline:none;}");
            html.Append("audio::-webkit-media-controls-panel{background:#1db954;}");
            html.Append(".footer{margin-top:25px;text-align:center;color:#555;font-size:12px;}");
            html.Append("</style>");

            html.Append("<div class='container'>");
            html.Append("<div class='header'>");
            html.Append("<h1>Bienvenido <span>" + Server.HtmlEncode(user.UserName) + "</span></h1>");
            html.Append("<button class='btn-logout' onclick=\"window.location='Logout.aspx';return false;\">Logout</button>");
            html.Append("</div>");

            DataTable dtSongs = new BLL.Song(strConnString).Read();

            html.Append("<div class='table-wrapper'>");
            html.Append("<table>");
            html.Append("<thead><tr>");
            html.Append("<th>Id</th><th>Nombre</th><th>Ruta</th><th>Reproducciones</th><th>Reproducir</th>");
            html.Append("</tr></thead><tbody>");

            if (dtSongs != null && dtSongs.Rows.Count > 0)
            {
                foreach (DataRow row in dtSongs.Rows)
                {
                    string path = ResolveUrl(row["SONG_PATH"].ToString());
                    html.Append("<tr>");
                    html.Append("<td class='song-id'>#" + row["ID_SONG"] + "</td>");
                    html.Append("<td class='song-name'>" + Server.HtmlEncode(row["SONG_NAME"].ToString()) + "</td>");
                    html.Append("<td class='song-path'>" + Server.HtmlEncode(row["SONG_PATH"].ToString()) + "</td>");
                    html.Append("<td class='song-plays'>" + row["PLAYS"] + "</td>");
                    html.Append("<td><audio controls preload='none'><source src='" + path + "' type='audio/mpeg'/></audio></td>");
                    html.Append("</tr>");
                }
            }
            else
            {
                html.Append("<tr><td colspan='5' style='text-align:center;color:#888;'>No hay canciones registradas.</td></tr>");
            }

            html.Append("</tbody></table></div>");
            html.Append("<div class='footer'>PoliMusic &copy; " + DateTime.Now.Year + "</div>");
            html.Append("</div>");

            phContent.Controls.Add(new LiteralControl(html.ToString()));
        }
    }
}
