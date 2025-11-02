using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using static System.Net.WebRequestMethods;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class PerfilController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public PerfilController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }



        [HttpGet]
        public IActionResult Perfil()
        {
            var usuario = new Usuario();
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            using (var context = _http.CreateClient())
            {
                var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ObtenerPerfil?IdUsuario=" + IdUsuario;
                var urlApi2 = _configuration["Valores:UrlApi"] + "Perfil/ObtenerEncargados?IdUsuario=" + IdUsuario;
                var respuesta = context.GetAsync(urlApi).Result;
                var respuesta2 = context.GetAsync(urlApi2).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var usuarioRespuesta = respuesta.Content.ReadFromJsonAsync<Usuario>().Result;
                    usuario = usuarioRespuesta;
           
                }


                if(respuesta2.IsSuccessStatusCode)
                {
                    var encargados = respuesta2.Content.ReadFromJsonAsync<List<Encargado>>().Result;
                    usuario.ListaEncargado = encargados;
                }

                return View(usuario);
            }
        }

 
    }
}
