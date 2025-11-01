using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IHostEnvironment _environment;
        public HomeController(IConfiguration configuration, IHostEnvironment environment)
        {
            _configuration = configuration;
            _environment = environment;
        }

        #region Iniciar Sesion

        [HttpPost]
        [Route("IniciarSesion")]

        public IActionResult IniciarSesion(UsuarioModelRequest usuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@Cedula", usuario.Cedula);
                parametros.Add("@Contrasenna", usuario.Contrasenna);

                var resultado = context.QueryFirstOrDefault<UsuarioModelResponse>("LoginSP", parametros);
                if (resultado != null)
                    return Ok(resultado);
                return NotFound();
            }
        }

        #endregion

        #region Registro

        [HttpPost]
        [Route("Registro")]

        public IActionResult Registro(RegistroModelRequest usuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var cedula = new DynamicParameters();
                cedula.Add("@Cedula", usuario.Cedula);

                var ejecutar = context.QueryFirstOrDefault("ValidarUsuarioSP", cedula);

                if (ejecutar!=null)
                {
                    return BadRequest("Error. Ya existe otro usuario asociado a esa cédula");
                }
                
                var parametros = new DynamicParameters();
                parametros.Add("@Cedula", usuario.Cedula);
                parametros.Add("@Contrasenna", usuario.Contrasenna);
                parametros.Add("@Correo", usuario.CorreoPersonal);
                parametros.Add("@Nombre", usuario.Nombre);
                parametros.Add("@IdEspecialidad", usuario.IdEspecialidad);
                parametros.Add("@IdSeccion", usuario.IdSeccion);
                parametros.Add("@Apellido1", usuario.Apellido1);
                parametros.Add("@Apellido2", usuario.Apellido2);
                parametros.Add("@FechaNacimiento", usuario.FechaNacimiento);

                var resultado = context.Execute("RegistroSP", parametros);
                return Ok(resultado); 
            }
        }


        [HttpGet]
        [Route("ObtenerSecciones")]

        public IActionResult ObtenerSecciones()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var resultado = context.Query<SeccionesResponseModel>("ObtenerSeccionesSP").ToList();
                return Ok(resultado);
            }

        }

        [HttpGet]
        [Route("ObtenerEspecialidades")]

        public IActionResult ObtenerEspecialidades()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var resultado = context.Query<EspecialidadesResponseModel>("ObtenerEspecialidadesSP").ToList();
                return Ok(resultado);
            }

        }

        #endregion

    }
}
