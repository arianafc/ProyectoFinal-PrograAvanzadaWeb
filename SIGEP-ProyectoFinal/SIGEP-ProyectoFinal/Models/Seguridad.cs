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
}
