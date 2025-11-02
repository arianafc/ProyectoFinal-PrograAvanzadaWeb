using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PerfilController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IHostEnvironment _environment;
        public PerfilController(IConfiguration configuration, IHostEnvironment environment)
        {
            _configuration = configuration;
            _environment = environment;
        }

        [HttpGet]
        [Route("ObtenerPerfil")]

        public IActionResult ObtenerPerfil(int IdUsuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", IdUsuario);

                var resultado = context.QueryFirstOrDefault<UsuarioModelResponse>("ObtenerPerfilSP", parametros);
                return Ok(resultado);
            }

        }

        [HttpGet]
        [Route("ObtenerEncargados")]

        public IActionResult ObtenerEncargados(int IdUsuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", IdUsuario);
                var resultado = context.Query<EncargadoResponseModel>("ObtenerEncargadosSP", parametros).ToList();
                return Ok(resultado);
            }

        }


    }
}
