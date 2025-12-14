using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using Utiles;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class HomeController : Controller
    {

        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public HomeController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        [Seguridad]
        [HttpGet]
      
        public IActionResult Index()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            return View();
        }

        #region Iniciar Sesion

        [HttpGet]
        public IActionResult IniciarSesion()
        {
            return View();
        }

        [HttpPost]
        public IActionResult IniciarSesion(Usuario usuario)
        {

            var helper = new Helper();
            usuario.Contrasenna = helper.Encrypt(usuario.Contrasenna);

            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Home/IniciarSesion";
                var respuesta = context.PostAsJsonAsync(urlApi, usuario).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var usuarioRespuesta = respuesta.Content.ReadFromJsonAsync<Usuario>().Result;
                    HttpContext.Session.SetString("Token", usuarioRespuesta.Token);
                    HttpContext.Session.SetString("Nombre", usuarioRespuesta.Nombre ?? "");
                    HttpContext.Session.SetString("Cedula", usuarioRespuesta.Cedula ?? "");
                    HttpContext.Session.SetInt32("IdUsuario", usuarioRespuesta.IdUsuario);
                    HttpContext.Session.SetInt32("Rol", usuarioRespuesta.IdRol);

                    TempData["SwalSuccess"] = "Bienvenido a SIGEP, " + usuarioRespuesta.Nombre;
                    return RedirectToAction("Index");
                }
                else
                {
                    TempData["SwalError"] = "Cédula o contraseña incorrecta";
                    return View();
                }

            }
        }

        [HttpGet]
        public IActionResult Registro()
        {
            var usuario = new Usuario();
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlAPI"] + "Home/ObtenerSecciones";
                var urlApi2 = _configuration["Valores:UrlAPI"] + "Home/ObtenerEspecialidades";
                var respuesta = context.GetAsync(urlApi).Result;
                var respuesta2 = context.GetAsync(urlApi2).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var datosApi = respuesta.Content.ReadFromJsonAsync<List<Secciones>>().Result;
                    usuario.ListaSecciones = datosApi ?? new List<Secciones>(); ;

                }
                else
                {
                    usuario.ListaSecciones = new List<Secciones>();
                }

                if (respuesta2.IsSuccessStatusCode)
                {
                    var datosApi2 = respuesta2.Content.ReadFromJsonAsync<List<Especialidades>>().Result;
                    usuario.ListaEspecialidades = datosApi2 ?? new List<Especialidades>();
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

        #endregion

        [HttpPost]

        public IActionResult Registro(Usuario usuario)
        {

            var helper = new Helper();
            usuario.Contrasenna = helper.Encrypt(usuario.Contrasenna);

            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlAPI"] + "Home/Registro";
                var respuesta = context.PostAsJsonAsync(urlApi, usuario).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var datosApi = respuesta.Content.ReadFromJsonAsync<int>().Result;

                    if (datosApi < 0)
                    {
                        TempData["SwalSuccess"] = "Usuario registrado correctamente";
                        return RedirectToAction("IniciarSesion");
                    }

                    TempData["SwalError"] = "Lo sentimos. Hubo un error al registrar el usuario.";
                    return View();

                } else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
               
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al registrar el usuario. Intente nuevamente."
                        : mensajeError;

                    return RedirectToAction("Registro"); ;
                }

            }
        }

        [HttpGet]
        public IActionResult RecuperarAcceso()
        {
            return View();
        }

        [HttpPost]

        public IActionResult RecuperarAcceso(Usuario usuario)
        {
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlAPI"] + "Home/RecuperarAcceso?Cedula="+usuario.Cedula;
                var respuesta = context.GetAsync(urlApi).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var datosApi = respuesta.Content.ReadFromJsonAsync<Usuario>().Result;

                    if (datosApi != null)
                    {
                        TempData["SwalSuccess"] = "Hemos enviado una contraseña temporal al correo electrónico registrado. Por favor, cambie su contraseña al ingresar al sistema.";
                        return RedirectToAction("IniciarSesion");
                    }

                    TempData["SwalError"] = "Lo sentimos. Hubo un error al cambiar la contraseña.";
                    return View();

                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al recuperar acceso."
                        : mensajeError;

                    return RedirectToAction("Registro"); ;
                }

            }
        }


        [Seguridad]
        [HttpPost]

        public IActionResult CambiarContrasenna(Usuario usuario)
        {

            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            var helper = new Helper();
            usuario.Contrasenna = helper.Encrypt(usuario.Contrasenna);
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlAPI"] + "Home/CambiarContrasenna";
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                usuario.IdUsuario = (int)IdUsuario;
                var respuesta = context.PostAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    var datosApi = respuesta.Content.ReadFromJsonAsync<int>().Result;
                    if (datosApi > 0)
                    {
                        TempData["SwalSuccess"] = "Contraseña cambiada correctamente.";
                        return RedirectToAction("IniciarSesion");
                    }
                    TempData["SwalError"] = "Lo sentimos. Hubo un error al cambiar la contraseña.";
                    return View();
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al cambiar la contraseña. Intente nuevamente."
                        : mensajeError;
                    return RedirectToAction("Registro"); ;
                }
            }
        }


        [Seguridad]
        [HttpPost]
   
        public IActionResult CerrarSesion()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("IniciarSesion");
        }
    }
}
