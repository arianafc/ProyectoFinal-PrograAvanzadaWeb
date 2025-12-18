using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using SIGEP_API.Services;
using System.Data;

namespace SIGEP_API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class GestionPracticasController : ControllerBase
    {

        private readonly IConfiguration _configuration;
        private readonly IHostEnvironment _environment;
        private readonly IEmailService _emailService;
        public GestionPracticasController(IConfiguration configuration, IHostEnvironment environment, IEmailService emailService)
        {
            _configuration = configuration;
            _environment = environment;
            _emailService = emailService;
        }


        [HttpGet]
        [Route("ObtenerPostulaciones")]
        public IActionResult ObtenerPostulaciones()
        {

            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {

                var resultado = context.Query<PostulacionDto>("ObtenerPostulacionesPracticasSP").ToList();
                return Ok(resultado);
            }
          
        }


        [HttpGet]
        [Route("ObtenerHistorico")]
        public IActionResult ObtenerHistorico()
        {

            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var resultado = context.Query<PostulacionDto>("ObtenerHistoricoSP").ToList();
                return Ok(resultado);
            }

        }

        [HttpPost]
        [Route("IniciarPractica")]

        public IActionResult IniciarPractica() {             
            
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
         
                var resultado = context.Execute("IniciarPracticasSP", commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPost]
        [Route("FinalizarPractica")]

        public IActionResult FinalizarPractica()
        {

            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {

                var resultado = context.Execute("FinalizarPracticasSP", commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpGet]
        [Route("ObtenerVacantesAsignar")]
        public IActionResult ObtenerVacantesAsignar(int IdUsuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", IdUsuario);

                var resultado = context
                    .Query<VacantesAsignarModelResponse>(
                        "ObtenerVacantesAsignarSP",
                        parametros,
                        commandType: CommandType.StoredProcedure
                    )
                    .ToList();

                return Ok(resultado);
            }
        }

        [HttpGet]
        [Route("ListarVacantesPorUsuario")]
        public IActionResult ListarVacantesPorUsuario()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", HttpContext.User.FindFirst("id")?.Value);

                var resultado = context
                    .Query<PostulacionDto>(
                        "ListarVacantesPorUsuarioSP",
                        parametros,
                        commandType: CommandType.StoredProcedure
                    )
                    .ToList();

                return Ok(resultado);
            }
        }

        [HttpGet]
        [Route("ObtenerMiPractica")]
        public IActionResult ObtenerMiPractica()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", HttpContext.User.FindFirst("id")?.Value);

                var resultado = context.QueryFirstOrDefault<PostulacionDto>(
            "ObtenerMiPracticaSP",
            parametros,
            commandType: CommandType.StoredProcedure
        );



                return Ok(resultado);
            }
        }


    }
}
