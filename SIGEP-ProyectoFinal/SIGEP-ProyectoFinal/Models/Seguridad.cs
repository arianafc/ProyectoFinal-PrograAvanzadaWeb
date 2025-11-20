using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace SIGEP_ProyectoFinal.Models
{
    public class Seguridad : ActionFilterAttribute
    {
        public override void OnActionExecuting(ActionExecutingContext context)
        {
            if (context.HttpContext.Session.GetInt32("IdUsuario") == null)
            {
                context.Result = new RedirectToActionResult("IniciarSesion", "Home", null);
            }
            else
            {
                base.OnActionExecuting(context);
            }           
        }
    }


    public class FiltroEstudiante : ActionFilterAttribute
    {
        public override void OnActionExecuting(ActionExecutingContext context)
        {
            var httpContext = context.HttpContext;
            var session = httpContext.Session;

            var rol = session.GetString("Rol");

            if (string.IsNullOrEmpty(rol) || rol != "1")
            {
                if (context.Controller is Controller controller)
                {
                    controller.TempData["SwalError"] = "No tienes permiso para acceder a esta página.";
                }

                context.Result = new RedirectResult("~/Home/Index");
            }

            base.OnActionExecuting(context);
        }
    }

    public class FiltroUsuarioAdmin : ActionFilterAttribute
    {
        public override void OnActionExecuting(ActionExecutingContext context)
        {
            var httpContext = context.HttpContext;
            var session = httpContext.Session;

            var rol = session.GetString("Rol");

            if (string.IsNullOrEmpty(rol) || rol != "2")
            {
                if (context.Controller is Controller controller)
                {
                    controller.TempData["SwalError"] = "No tienes permiso para acceder a esta página.";
                }

                context.Result = new RedirectResult("~/Home/Index");
            }

            base.OnActionExecuting(context);
        }
    }
}
