using Dapper;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ErrorController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        public ErrorController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [Route("RegistrarError")]
        public IActionResult RegistrarError()
        {
            var exception = HttpContext.Features.Get<IExceptionHandlerFeature>();

            int IdUsuario = int.TryParse(HttpContext.User.FindFirst("id")?.Value, out var id)
             ? id
             : 0;

            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", IdUsuario);
                parametros.Add("@MensajeError", exception?.Error.Message);
                parametros.Add("@OrigenError", exception?.Path);

                context.Execute("RegistrarError", parametros);
            }

            return StatusCode(500, "Se presentó una excepción en nuestro servicio");
        }
    }
}
