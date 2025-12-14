using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;

namespace SIGEP_API.Controllers
{
    //[Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class EvaluacionController : ControllerBase
    {
        private readonly IConfiguration _configuration;

        public EvaluacionController(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        #region Obtener Estudiantes

        [HttpPost]
        [Route("ObtenerEstudiantes")]
        public IActionResult ObtenerEstudiantes(ObtenerEstudiantesRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdCoordinador", request.IdCoordinador);

                    var estudiantes = context.Query<EstudianteEvaluacionResponseModel>(
                        "ObtenerEstudiantesParaEvaluacionSP",
                        parametros
                    ).ToList();

                    return Ok(estudiantes);
                }
            }
            catch (SqlException ex)
            {
                return BadRequest(new { mensaje = ex.Message });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error interno del servidor", detalle = ex.Message });
            }
        }

        #endregion

        #region Obtener Perfil Estudiante

        [HttpGet]
        [Route("ObtenerPerfilEstudiante")]
        public IActionResult ObtenerPerfilEstudiante(int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", idUsuario);

                    var perfil = context.QueryFirstOrDefault<PerfilEstudianteResponseModel>(
                        "ObtenerPerfilEstudianteSP",
                        parametros
                    );

                    if (perfil == null)
                        return NotFound(new { mensaje = "Estudiante no encontrado" });

                    return Ok(perfil);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener perfil", detalle = ex.Message });
            }
        }

        #endregion

        #region Obtener Comentarios

        [HttpGet]
        [Route("ObtenerComentarios")]
        public IActionResult ObtenerComentarios(int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", idUsuario);

                    var comentarios = context.Query<ComentarioResponseModel>(
                        "ObtenerComentariosEstudianteSP",
                        parametros
                    ).ToList();

                    return Ok(comentarios);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener comentarios", detalle = ex.Message });
            }
        }

        #endregion

        #region Obtener Notas

        [HttpGet]
        [Route("ObtenerNotas")]
        public IActionResult ObtenerNotas(int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", idUsuario);

                    var notas = context.QueryFirstOrDefault<NotasResponseModel>(
                        "ObtenerNotasEstudianteSP",
                        parametros
                    );

                    if (notas == null)
                    {
                        return Ok(new NotasResponseModel
                        {
                            Nota1 = 0,
                            Nota2 = 0,
                            NotaFinal = 0
                        });
                    }

                    return Ok(notas);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener notas", detalle = ex.Message });
            }
        }

        #endregion

        #region Guardar Nota

        [HttpPost]
        [Route("GuardarNota")]
        public IActionResult GuardarNota(GuardarNotaRequestModel request)
        {
            try
            {
                if (request.Nota1 == null && request.Nota2 == null)
                {
                    return BadRequest(new GuardarNotaResponseModel
                    {
                        Exito = false,
                        Mensaje = "Debe ingresar al menos una nota"
                    });
                }

                if (request.Nota1.HasValue && (request.Nota1.Value < 0 || request.Nota1.Value > 100))
                {
                    return BadRequest(new GuardarNotaResponseModel
                    {
                        Exito = false,
                        Mensaje = "La Nota 1 debe estar entre 0 y 100"
                    });
                }

                if (request.Nota2.HasValue && (request.Nota2.Value < 0 || request.Nota2.Value > 100))
                {
                    return BadRequest(new GuardarNotaResponseModel
                    {
                        Exito = false,
                        Mensaje = "La Nota 2 debe estar entre 0 y 100"
                    });
                }

                decimal? notaFinal = null;
                if (request.Nota1.HasValue && request.Nota2.HasValue)
                {
                    notaFinal = (request.Nota1.Value + request.Nota2.Value) / 2;
                }

                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", request.IdUsuario);
                    parametros.Add("@Nota1", request.Nota1 ?? 0);
                    parametros.Add("@Nota2", request.Nota2 ?? 0);
                    parametros.Add("@NotaFinal", notaFinal ?? 0);
                    parametros.Add("@IdCoordinador", request.IdCoordinador);

                    var resultado = context.QueryFirstOrDefault<GuardarNotaResponseModel>(
                        "GuardarNotaEstudianteSP",
                        parametros
                    );

                    if (resultado != null && resultado.Exito)
                    {
                        if (request.Nota1.HasValue && request.Nota2.HasValue)
                        {
                            resultado.Mensaje = "Notas registradas correctamente. Nota final calculada.";
                        }
                        else if (request.Nota1.HasValue)
                        {
                            resultado.Mensaje = "Nota 1 registrada correctamente. Ingrese Nota 2 para calcular la nota final.";
                        }
                        else if (request.Nota2.HasValue)
                        {
                            resultado.Mensaje = "Nota 2 registrada correctamente. Ingrese Nota 1 para calcular la nota final.";
                        }

                        return Ok(resultado);
                    }

                    return BadRequest(resultado);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new GuardarNotaResponseModel
                {
                    Exito = false,
                    Mensaje = "Error al guardar la nota: " + ex.Message
                });
            }
        }

        #endregion

        #region Guardar Comentario

        [HttpPost]
        [Route("GuardarComentario")]
        public IActionResult GuardarComentario(GuardarComentarioRequestModel request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Comentario))
                {
                    return BadRequest(new GuardarComentarioResponseModel
                    {
                        Exito = false,
                        Mensaje = "El comentario no puede estar vacío"
                    });
                }

                if (request.Comentario.Length > 255)
                {
                    return BadRequest(new GuardarComentarioResponseModel
                    {
                        Exito = false,
                        Mensaje = "El comentario no puede exceder los 255 caracteres"
                    });
                }

                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", request.IdUsuario);
                    parametros.Add("@IdCoordinador", request.IdCoordinador);
                    parametros.Add("@Comentario", request.Comentario.Trim());

                    var resultado = context.QueryFirstOrDefault<GuardarComentarioResponseModel>(
                        "GuardarComentarioEvaluacionSP",
                        parametros
                    );

                    if (resultado != null && resultado.Exito)
                    {
                        var parametrosNombre = new DynamicParameters();
                        parametrosNombre.Add("@IdUsuario", request.IdCoordinador);

                        var coordinador = context.QueryFirstOrDefault<NombreCompletoResponseModel>(
                            "ObtenerNombreCompletoUsuarioSP",
                            parametrosNombre
                        );

                        resultado.Autor = coordinador?.NombreCompleto ?? "Coordinador";
                        resultado.Fecha = DateTime.Now.ToString("dd/MM/yyyy HH:mm");

                        return Ok(resultado);
                    }

                    return BadRequest(resultado);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new GuardarComentarioResponseModel
                {
                    Exito = false,
                    Mensaje = "Error al guardar comentario: " + ex.Message
                });
            }
        }

        #endregion

        #region Guardar Documento

        [HttpPost]
        [Route("GuardarDocumento")]
        public IActionResult GuardarDocumento(SubirDocumentoRequestModel request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.NombreArchivo))
                {
                    return BadRequest(new SubirDocumentoResponseModel
                    {
                        Exito = false,
                        Mensaje = "El nombre del archivo es requerido"
                    });
                }

                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", request.IdUsuario);
                    parametros.Add("@NombreArchivo", request.NombreArchivo);
                    parametros.Add("@Tipo", request.Tipo);

                    var resultado = context.QueryFirstOrDefault<SubirDocumentoResponseModel>(
                        "GuardarDocumentoEvaluacionSP",
                        parametros
                    );

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new SubirDocumentoResponseModel
                {
                    Exito = false,
                    Mensaje = "Error al guardar documento: " + ex.Message
                });
            }
        }

        #endregion

        #region Obtener Documentos

        [HttpGet]
        [Route("ObtenerDocumentosEvaluacion")]
        public IActionResult ObtenerDocumentosEvaluacion(int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", idUsuario);

                    var documentos = context.Query<DocumentoEvaluacionResponseModel>(
                        "ObtenerDocumentosEvaluacionSP",
                        parametros
                    ).ToList();

                    return Ok(documentos);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener documentos", detalle = ex.Message });
            }
        }

        #endregion

        #region Obtener Documento Por ID

        [HttpGet]
        [Route("ObtenerDocumentoPorId")]
        public IActionResult ObtenerDocumentoPorId(int idDocumento)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdDocumento", idDocumento);

                    var documento = context.QueryFirstOrDefault<DocumentoInfoResponseModel>(
                        "ObtenerDocumentoPorIdSP",
                        parametros
                    );

                    if (documento == null)
                        return NotFound(new { mensaje = "Documento no encontrado" });

                    return Ok(documento);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener documento", detalle = ex.Message });
            }
        }

        #endregion

        #region Obtener Cédula Usuario

        [HttpGet]
        [Route("ObtenerCedulaUsuario")]
        public IActionResult ObtenerCedulaUsuario(int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdUsuario", idUsuario);

                    var resultado = context.QueryFirstOrDefault<CedulaResponseModel>(
                        "ObtenerCedulaUsuarioSP",
                        parametros
                    );

                    if (resultado == null)
                        return NotFound(new { mensaje = "Usuario no encontrado" });

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener cédula", detalle = ex.Message });
            }
        }

        #endregion

        #region Eliminar Documento

        [HttpDelete]
        [Route("EliminarDocumento")]
        public IActionResult EliminarDocumento(int idDocumento)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdDocumento", idDocumento);

                    var resultado = context.QueryFirstOrDefault<EliminarDocumentoResponseModel>(
                        "EliminarDocumentoSP",
                        parametros
                    );

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new EliminarDocumentoResponseModel
                {
                    Exito = false,
                    Mensaje = "Error al eliminar: " + ex.Message
                });
            }
        }

        #endregion
    }
}