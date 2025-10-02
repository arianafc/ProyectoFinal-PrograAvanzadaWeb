using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class HomeController : Controller
    {

        //ACTIONS ADAPTADOS PARA LA PRACTICA


        private readonly ILogger<HomeController> _logger;

        public HomeController(ILogger<HomeController> logger)
        {
            _logger = logger;
        }

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
            //utilizar estos datos para validar e ingresar al sistema
            var coordinador = "118810955";
            var nombreCoordinador = "Ariana";
            var estudiante = "305550650";
            var nombreEstudiante = "Johnny";
            var profesor = "112233445";
            var nombreProfesor = "Jean Pool";
            var contrasenna = "Hola123456";

            bool credencialesValidas = false;

            if (usuario.Cedula == coordinador && usuario.Contrasenna == contrasenna)
            {
                HttpContext.Session.SetInt32("rol", 1);
                HttpContext.Session.SetString("nombre", nombreCoordinador);
                credencialesValidas = true;
            }
            else if (usuario.Cedula == estudiante && usuario.Contrasenna == contrasenna)
            {
                HttpContext.Session.SetInt32("rol", 2);
                HttpContext.Session.SetString("nombre", nombreEstudiante);
                
                credencialesValidas = true;
            }
            else if (usuario.Cedula == profesor && usuario.Contrasenna == contrasenna)
            {
                HttpContext.Session.SetInt32("rol", 3);
                HttpContext.Session.SetString("nombre", nombreProfesor);
                credencialesValidas = true;
            }

            if (!credencialesValidas)
            {
                TempData["SwalError"] = "Lo sentimos, el usuario no se encuentra registrado. Por favor, crea una cuenta";
                return View("IniciarSesion", usuario);
            }

            return RedirectToAction("Index");
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
