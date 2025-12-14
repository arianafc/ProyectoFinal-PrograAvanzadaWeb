using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class ErrorController : Controller
    {
        public IActionResult MostrarError()
        {
            var exception = HttpContext.Features.Get<IExceptionHandlerFeature>();
            return View();
        }
    }
}
