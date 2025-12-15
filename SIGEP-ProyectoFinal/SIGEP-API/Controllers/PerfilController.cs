using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using System.Data;
using System.Reflection;

namespace SIGEP_API.Controllers
{
    [Authorize]
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
                var resultado = context.QueryFirstOrDefault<EncargadoResponseModel>("ObtenerEncargadosSP", parametros);
                if (resultado == null)
                {
                    resultado = new EncargadoResponseModel();
                }
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


        [HttpPost]
        [Route("ConsultarEncargadoPorCedula")]

        public IActionResult ConsultarEncargadoPorCedula(string Cedula, int IdUsuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@Cedula", Cedula);
                var resultado = context.QueryFirstOrDefault<EncargadoResponseModel>(
                    "ValidarEncargadoSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                );
                if (resultado == null)
                {
                    return NotFound("No se encontró ningún encargado con la cédula proporcionada.");
                }
                return Ok(resultado);
            }
        }


        [HttpPost]
        [Route("AgregarEncargado")]
        public IActionResult AgregarEncargado(EncargadoRequestModel model)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametrosValidacion = new DynamicParameters();
                parametrosValidacion.Add("@Cedula", model.Cedula);

                var usuarioExistente = context.QueryFirstOrDefault<UsuarioModelResponse>(
                    "ValidarUsuarioEncargadoSP",
                    parametrosValidacion,
                    commandType: CommandType.StoredProcedure
                );

                if (usuarioExistente != null && usuarioExistente.IdRol == 1)
                {
                    return BadRequest(
                        "Lo sentimos. La cédula ingresada corresponde a un estudiante registrado en el sistema y no puede ser asignado como encargado."
                    );
                }

               
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", model.IdUsuario);
                parametros.Add("@Nombre", model.Nombre);
                parametros.Add("@Apellido1", model.Apellido1);
                parametros.Add("@Apellido2", model.Apellido2);
                parametros.Add("@Parentesco", model.Parentesco);
                parametros.Add("@Telefono", model.Telefono);
                parametros.Add("@Correo", model.Correo);
                parametros.Add("@Cedula", model.Cedula);
                parametros.Add("@Ocupacion", model.Ocupacion);
                parametros.Add("@LugarTrabajo", model.LugarTrabajo);
                parametros.Add("@Encargado", model.IdEncargado);

                context.Execute(
                    "AccionesEncargadoSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                );

                return Ok("Encargado registrado correctamente");
            }
        }



        [HttpPost]
        [Route("ActualizarEncargado")]


        public IActionResult ActualizarEncargado(EncargadoRequestModel model)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var validarSiEsEstudiante = new DynamicParameters();
                validarSiEsEstudiante.Add("@Cedula", model.Cedula);
                var existeEstudiante = context.QueryFirstOrDefault<UsuarioModelResponse>(
                    "ValidarUsuarioEncargadoSP",
                    validarSiEsEstudiante,
                    commandType: CommandType.StoredProcedure
                );

                if (existeEstudiante != null && existeEstudiante.IdRol == 1)
                {
                    return BadRequest(
                        "Lo sentimos. La cédula ingresada corresponde a un estudiante registrado en el sistema y no puede ser asignado como encargado."
                    );
                }

                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", model.IdUsuario);
                parametros.Add("@Nombre", model.Nombre);
                parametros.Add("@Apellido1", model.Apellido1);
                parametros.Add("@Apellido2", model.Apellido2);
                parametros.Add("@Parentesco", model.Parentesco);
                parametros.Add("@Telefono", model.Telefono);
                parametros.Add("@Correo", model.Correo);
                parametros.Add("@Cedula", model.Cedula);
                parametros.Add("@Ocupacion", model.Ocupacion);
                parametros.Add("@LugarTrabajo", model.LugarTrabajo);
                parametros.Add("@Accion", 2);
                parametros.Add("@Encargado", model.IdEncargado);

                var filasAfectadas = context.Execute(
                    "AccionesEncargadoSP",
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


        [HttpGet]
        [Route("ObtenerEncargado")]

        public IActionResult ObtenerEncargado(int IdEncargado, int IdUsuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdEncargado", IdEncargado);
                parametros.Add("@IdUsuario", IdUsuario);
                var resultado = context.QueryFirstOrDefault<EncargadoResponseModel>(
                    "ObtenerEncargadoSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                );
                return Ok(resultado);
            }


        }


        [HttpPost]
        [Route("SubirDocumentos")]
        public IActionResult SubirDocumentos(DocumentoRequest model)
        {
            using (var connection = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", model.IdUsuario);
                parametros.Add("@Documento", model.Documento);

                connection.Execute("SubirDocumentosPerfilSP",
                                   parametros,
                                   commandType: CommandType.StoredProcedure);
            }

            return Ok(new { exito = true });
        }

        [HttpGet]
        [Route("ObtenerDocumentos")]
        public IActionResult ObtenerDocumentos(int IdUsuario)

        {
            using (var connection = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", IdUsuario);

                var documentos = connection.Query<DocumentoResponse>(
                    "ObtenerDocumentosPerfilSP",
                    parametros,
                    commandType: CommandType.StoredProcedure
                ).ToList();

                return Ok(documentos);
            }
        }

    


        [HttpDelete]
        [Route("EliminarDocumento")]
        public IActionResult EliminarDocumento(int IdDocumento)
        {
            try
            {
                using (var connection = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdDocumento", IdDocumento);

                    connection.Execute(
                        "EliminarDocumentoSP",
                        parametros,
                        commandType: CommandType.StoredProcedure
                    );
                }

                return Ok(new { exito = true, mensaje = "Documento eliminado correctamente." });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    exito = false,
                    mensaje = "Ocurrió un error al eliminar el documento.",
                    detalle = ex.Message
                });
            }
        }

    }
}

