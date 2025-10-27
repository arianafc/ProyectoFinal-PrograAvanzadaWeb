using System.Diagnostics;
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
        public IActionResult Index()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("rol");
            return View();
        }

        [HttpGet]
        public IActionResult IniciarSesion()
        {
            return View();
        }

        [HttpPost]
        public IActionResult IniciarSesion(Usuario usuario)
        {
            using (var context = _http.CreateClient()) {
                var urlApi = _configuration["Valores:UrlApi"] + "Home/IniciarSesion";
                var respuesta = context.PostAsJsonAsync(urlApi, usuario).Result;

                if(respuesta.IsSuccessStatusCode)
                {                     
                    var usuarioRespuesta = respuesta.Content.ReadFromJsonAsync<Usuario>().Result;
                    HttpContext.Session.SetString("nombre", usuarioRespuesta.Nombre ?? "");
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
            return View();
        }


        [HttpPost]

        public IActionResult Registro(Usuario usuario)
        {
            TempData["SwalSuccess"] = "Usuario registrado correctamente";
            return RedirectToAction("Login");
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
