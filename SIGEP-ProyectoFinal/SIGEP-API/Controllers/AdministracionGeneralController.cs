using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using System.Data;

namespace SIGEP_API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class AdministracionGeneralController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<AdministracionGeneralController> _logger;

        public AdministracionGeneralController(IConfiguration configuration, ILogger<AdministracionGeneralController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        #region Usuarios

        [HttpGet]
        [Route("ConsultarUsuarios")]
        public IActionResult ConsultarUsuarios(string? rol = null)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Rol", rol);

                    var resultado = context.Query<DatosUsuarioResponseModel>("ConsultarUsuariosSP", parametros);
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en ConsultarUsuarios");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPost]
        [Route("CambiarEstadoUsuario")]
        public IActionResult CambiarEstadoUsuario(CambiarEstadoUsuarioRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", request.IdUsuario);
                    parametros.Add("@NuevoEstado", request.NuevoEstado);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("CambiarEstadoUsuarioSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    _logger.LogInformation($"CambiarEstadoUsuario - IdUsuario: {request.IdUsuario}, NuevoEstado: {request.NuevoEstado}, Resultado: {resultado}");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CambiarEstadoUsuario");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPost]
        [Route("CambiarRolUsuario")]
        public IActionResult CambiarRolUsuario(CambiarRolUsuarioRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", request.IdUsuario);
                    parametros.Add("@Rol", request.Rol);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("CambiarRolUsuarioSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    _logger.LogInformation($"CambiarRolUsuario - IdUsuario: {request.IdUsuario}, Rol: {request.Rol}, Resultado: {resultado}");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en CambiarRolUsuario - IdUsuario: {request.IdUsuario}, Rol: {request.Rol}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        #endregion

        #region Especialidades

        [HttpGet]
        [Route("ConsultarEspecialidades")]
        public IActionResult ConsultarEspecialidades()
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var resultado = context.Query<DatosEspecialidadResponseModel>("ConsultarEspecialidadesSP");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en ConsultarEspecialidades");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPost]
        [Route("CrearEspecialidad")]
        public IActionResult CrearEspecialidad(CrearEspecialidadRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Nombre", request.Nombre);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("CrearEspecialidadSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CrearEspecialidad");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPut]
        [Route("EditarEspecialidad")]
        public IActionResult EditarEspecialidad(EditarEspecialidadRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Id", request.Id);
                    parametros.Add("@Nombre", request.Nombre);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("EditarEspecialidadSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en EditarEspecialidad");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPost]
        [Route("CambiarEstadoEspecialidad")]
        public IActionResult CambiarEstadoEspecialidad(CambiarEstadoEspecialidadRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Id", request.Id);
                    parametros.Add("@NuevoEstado", request.NuevoEstado);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("CambiarEstadoEspecialidadSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CambiarEstadoEspecialidad");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        #endregion

        #region Secciones

        [HttpGet]
        [Route("ConsultarSecciones")]
        public IActionResult ConsultarSecciones()
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var resultado = context.Query<DatosSeccionResponseModel>("ConsultarSeccionesSP");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en ConsultarSecciones");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPost]
        [Route("CrearSeccion")]
        public IActionResult CrearSeccion(CrearSeccionRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@NombreSeccion", request.NombreSeccion);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("CrearSeccionSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CrearSeccion");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPut]
        [Route("EditarSeccion")]
        public IActionResult EditarSeccion(EditarSeccionRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Id", request.Id);
                    parametros.Add("@NombreSeccion", request.NombreSeccion);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("EditarSeccionSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en EditarSeccion");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        [HttpPost]
        [Route("CambiarEstadoSeccion")]
        public IActionResult CambiarEstadoSeccion(CambiarEstadoSeccionRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Id", request.Id);
                    parametros.Add("@NuevoEstado", request.NuevoEstado);
                    parametros.Add("@Resultado", direction: ParameterDirection.ReturnValue);

                    context.Execute("CambiarEstadoSeccionSP", parametros);

                    var resultado = parametros.Get<int>("@Resultado");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en CambiarEstadoSeccion");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        #endregion
    }
}