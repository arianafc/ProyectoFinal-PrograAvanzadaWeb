using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;

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

        [HttpGet]
        [Seguridad]
        public IActionResult Index()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("rol");
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
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Home/IniciarSesion";
                var respuesta = context.PostAsJsonAsync(urlApi, usuario).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var usuarioRespuesta = respuesta.Content.ReadFromJsonAsync<Usuario>().Result;
                    HttpContext.Session.SetString("nombre", usuarioRespuesta.Nombre ?? "");
                    HttpContext.Session.SetString("cedula", usuarioRespuesta.Cedula ?? "");
                    HttpContext.Session.SetInt32("IdUsuario", usuarioRespuesta.IdUsuario);
                    HttpContext.Session.SetInt32("rol", usuarioRespuesta.IdRol);
                    TempData["SwalSuccess"] = "Bienvenido a SIGEP," + usuario.Nombre;
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
            var cedula = "118810955";
            if (usuario.Cedula == cedula)
            {
                TempData["SwalSuccess"] = "Hemos enviado un link de recuperación al correo ari*****@gmail.com";
                return RedirectToAction("IniciarSesion");
            }
            else
            {
                TempData["SwalError"] = "La cédula proporcionada no se encuentra registrada";
                return View();
            }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CerrarSesion()
        {
            HttpContext.Session.Clear();
            return RedirectToAction("IniciarSesion");
        }
    }
}
