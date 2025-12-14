using Microsoft.AspNetCore.Mvc;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class ComunicadosController : Controller
    {
        public IActionResult Comunicados()
        {
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            return View();
        }
    }
}
