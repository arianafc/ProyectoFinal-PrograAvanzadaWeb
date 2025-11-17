using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using System.Data;
using System.Reflection;

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


        [HttpPut]
        [Route("CambiarContrasenna")]

        public IActionResult CambiarContrasenna(CambioContrasennaRequestModel modelo)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", modelo.IdUsuario);
                parametros.Add("@Contrasenna", modelo.Contrasenna);

                var filasAfectadas = context.Execute(
                    "ActualizarContrasennaSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                );
                return Ok(new
                {
                    exito = true,
                    filasAfectadas
                });
            }
        }

        [HttpPut]
        [Route("ActualizarPerfil")]

        public IActionResult ActualizarPerfil(InfoPersonalRequestModel usuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {

                var validarCedula = new DynamicParameters();
                validarCedula.Add("@Cedula", usuario.Cedula);


                var existeCedula = context.QueryFirstOrDefault<UsuarioModelResponse>(
                    "ValidarUsuarioSP",
                    validarCedula,
                    commandType: CommandType.StoredProcedure
                );

                if (existeCedula != null && existeCedula.IdUsuario != usuario.IdUsuario)
                {
                    return BadRequest("Lo sentimos. Ya existe otro usuario en sistema registrado con esa cédula.");
                }


                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", usuario.IdUsuario);
                parametros.Add("@Nombre", usuario.Nombre);
                parametros.Add("@Apellido1", usuario.Apellido1);
                parametros.Add("@Apellido2", usuario.Apellido2);
                parametros.Add("@Cedula", usuario.Cedula);
                parametros.Add("@Telefono", usuario.Telefono);
                parametros.Add("@Correo", usuario.Correo);
                parametros.Add("@Provincia", usuario.Provincia);
                parametros.Add("@Canton", usuario.Canton);
                parametros.Add("@Distrito", usuario.Distrito);
                parametros.Add("@DireccionExacta", usuario.DireccionExacta);
                parametros.Add("@FechaNacimiento", usuario.FechaNacimiento);
                parametros.Add("@Sexo", usuario.Sexo);
                parametros.Add("@Nacionalidad", usuario.Nacionalidad);

                var filasAfectadas = context.Execute(
                    "ActualizarInformacionPersonalSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                );


                return Ok(new
                {
                    exito = true,
                    filasAfectadas
                });
            }
        }

        [HttpPut]
        [Route("ActualizarInfoAcademica")]

        public IActionResult ActualizarInfoAcademica(InfoAcademicaRequestModel model)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", model.IdUsuario);
                parametros.Add("@IdEspecialidad", model.IdEspecialidad);
                parametros.Add("@IdSeccion", model.IdSeccion);

                var filasAfectadas = context.Execute(
                    "ActualizarInfoAcademicaSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                );
                return Ok(new
                {
                    exito = true,
                    filasAfectadas
                });
            }
        }


        [HttpPut]
        [Route("ActualizarInfoMedica")]

        public IActionResult ActualizarInfoMedica(InfoMedicaRequestModel model)
        {

            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", model.IdUsuario);
                parametros.Add("@Padecimiento", model.Padecimiento);
                parametros.Add("@Tratamiento", model.Tratamiento);
                parametros.Add("@Alergia", model.Alergia);

                var filasAfectadas = context.Execute(
                    "ActualizarInfoMedicaSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                );
                return Ok(new
                {
                    exito = true,
                    filasAfectadas
                });
            }

        }
    }
}
