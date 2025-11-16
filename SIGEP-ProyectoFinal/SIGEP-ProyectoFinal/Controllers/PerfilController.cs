using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using static System.Net.WebRequestMethods;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]
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

                var urlApi3 = _configuration["Valores:UrlAPI"] + "Home/ObtenerSecciones";
                var urlApi4 = _configuration["Valores:UrlAPI"] + "Home/ObtenerEspecialidades";
                var respuesta3 = context.GetAsync(urlApi3).Result;
                var respuesta4 = context.GetAsync(urlApi4).Result;

                if (respuesta3.IsSuccessStatusCode)
                {
                    var datosApi3 = respuesta3.Content.ReadFromJsonAsync<List<Secciones>>().Result;
                    usuario.ListaSecciones = datosApi3 ?? new List<Secciones>(); ;

                }
                else
                {
                    usuario.ListaSecciones = new List<Secciones>();
                }

                if (respuesta4.IsSuccessStatusCode)
                {
                    var datosApi4 = respuesta4.Content.ReadFromJsonAsync<List<Especialidades>>().Result;
                    usuario.ListaEspecialidades = datosApi4 ?? new List<Especialidades>();
                }
                else
                {
                    usuario.ListaEspecialidades = new List<Especialidades>();
                }

                usuario.ListaSecciones ??= new List<Secciones>();
                usuario.ListaEspecialidades ??= new List<Especialidades>();




                return View(usuario);
            }
        }


        [HttpPost]
        public IActionResult ActualizarPerfil(Usuario usuario)
        {

            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ActualizarPerfil";
                usuario.IdUsuario = (int)IdUsuario;
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Información personal actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al Actualizar perfil. Intente nuevamente."
                        : mensajeError;

                    return RedirectToAction("Perfil"); ;
                }
            }
        }

        [HttpPost]

        public IActionResult CambiarContrasenna(Usuario usuario)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/CambiarContrasenna";
                usuario.IdUsuario = (int)IdUsuario;
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Contraseña actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al cambiar la contraseña. Intente nuevamente."
                        : mensajeError;
                    return RedirectToAction("Perfil"); ;
                }
            }
        }


        [HttpPost]


        public IActionResult ActualizarInfoAcademica(Usuario usuario)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ActualizarInfoAcademica";
                usuario.IdUsuario = (int)IdUsuario;
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Información académica actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al Actualizar información académica. Intente nuevamente."
                        : mensajeError;
                    return RedirectToAction("Perfil"); ;
                }
            }
        }

        [HttpPost]

        public IActionResult ActualizarInfoMedica(Usuario usuario)
        {

            usuario.Padecimiento = usuario.Padecimiento ?? "Ninguno";
            usuario.Tratamiento = usuario.Tratamiento ?? "Ninguno";
            usuario.Alergia = usuario.Alergia ?? "Ninguno";


            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ActualizarInfoMedica";
                usuario.IdUsuario = (int)IdUsuario;
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Información médica actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al Actualizar información médica. Intente nuevamente."
                        : mensajeError;
                    return RedirectToAction("Perfil"); ;
                }
            }
        }

    }
}
