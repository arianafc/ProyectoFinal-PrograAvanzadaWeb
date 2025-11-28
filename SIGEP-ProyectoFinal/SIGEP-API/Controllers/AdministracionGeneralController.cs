using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;

namespace SIGEP_API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class AdministracionGeneralController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public AdministracionGeneralController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        #region Usuarios

        [HttpGet]
        [Route("ConsultarUsuarios")]
        public IActionResult ConsultarUsuarios(string? rol = null)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("Rol", rol);

                var resultado = context.Query<DatosUsuarioResponseModel>("ConsultarUsuariosSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPost]
        [Route("CambiarEstadoUsuario")]
        public IActionResult CambiarEstadoUsuario(CambiarEstadoUsuarioRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("IdUsuario", request.IdUsuario);
                parametros.Add("NuevoEstado", request.NuevoEstado);

                var resultado = context.Execute("CambiarEstadoUsuarioSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPost]
        [Route("CambiarRolUsuario")]
        public IActionResult CambiarRolUsuario(CambiarRolUsuarioRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("IdUsuario", request.IdUsuario);
                parametros.Add("Rol", request.Rol);

                var resultado = context.Execute("CambiarRolUsuarioSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        #endregion

        #region Especialidades

        [HttpGet]
        [Route("ConsultarEspecialidades")]
        public IActionResult ConsultarEspecialidades()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var resultado = context.Query<DatosEspecialidadResponseModel>("ConsultarEspecialidadesSP", commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPost]
        [Route("CrearEspecialidad")]
        public IActionResult CrearEspecialidad(CrearEspecialidadRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("Nombre", request.Nombre);

                var resultado = context.Execute("CrearEspecialidadSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPut]
        [Route("EditarEspecialidad")]
        public IActionResult EditarEspecialidad(EditarEspecialidadRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("Id", request.Id);
                parametros.Add("Nombre", request.Nombre);

                var resultado = context.Execute("EditarEspecialidadSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPost]
        [Route("CambiarEstadoEspecialidad")]
        public IActionResult CambiarEstadoEspecialidad(CambiarEstadoEspecialidadRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("Id", request.Id);
                parametros.Add("NuevoEstado", request.NuevoEstado);

                var resultado = context.Execute("CambiarEstadoEspecialidadSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        #endregion

        #region Secciones

        [HttpGet]
        [Route("ConsultarSecciones")]
        public IActionResult ConsultarSecciones()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var resultado = context.Query<DatosSeccionResponseModel>("ConsultarSeccionesSP", commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPost]
        [Route("CrearSeccion")]
        public IActionResult CrearSeccion(CrearSeccionRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("NombreSeccion", request.NombreSeccion);

                var resultado = context.Execute("CrearSeccionSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPut]
        [Route("EditarSeccion")]
        public IActionResult EditarSeccion(EditarSeccionRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("Id", request.Id);
                parametros.Add("NombreSeccion", request.NombreSeccion);

                var resultado = context.Execute("EditarSeccionSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        [HttpPost]
        [Route("CambiarEstadoSeccion")]
        public IActionResult CambiarEstadoSeccion(CambiarEstadoSeccionRequestModel request)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("Id", request.Id);
                parametros.Add("NuevoEstado", request.NuevoEstado);

                var resultado = context.Execute("CambiarEstadoSeccionSP", parametros, commandType: System.Data.CommandType.StoredProcedure);
                return Ok(resultado);
            }
        }

        #endregion
    }
}