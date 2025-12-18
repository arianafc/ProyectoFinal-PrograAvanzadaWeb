using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using System.Data;
using System.IO;

namespace SIGEP_API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class EstudianteController : ControllerBase
    {
        private readonly IConfiguration _config;

        public EstudianteController(IConfiguration config)
        {
            _config = config;
        }

        private SqlConnection Conn() =>
            new SqlConnection(_config["ConnectionStrings:BDConnection"]);

        #region Listar Estudiantes
        [HttpGet]
        [Route("ListarEstudiantes")]
        public IActionResult ListarEstudiantes(string estado = null, int idEspecialidad = 0)
        {
            try
            {
                using (var db = Conn())
                {
                    db.Open();
                    var p = new DynamicParameters();
                    p.Add("@IdCoordinador", null);
                    p.Add("@Estado", string.IsNullOrWhiteSpace(estado) ? null : estado.Trim());
                    p.Add("@IdEspecialidad", idEspecialidad == 0 ? null : (int?)idEspecialidad);

                    var data = db.Query<EstudianteListItemModel>(
                        "ListarEstudiantesSP",
                        p,
                        commandType: CommandType.StoredProcedure
                    ).ToList();

                    return Ok(data);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message });
            }
        }
        #endregion

        #region Consultar Detalle Estudiante
        [HttpGet]
        [Route("ConsultarEstudiante")]
        public IActionResult ConsultarEstudiante(int idUsuario)
        {
            try
            {
                using (var db = Conn())
                {
                    db.Open();
                    var p = new DynamicParameters();
                    p.Add("@IdUsuario", idUsuario);

                    using (var multi = db.QueryMultiple(
                        "ConsultarEstudianteSP",
                        p,
                        commandType: CommandType.StoredProcedure))
                    {
                        var estudiante = multi.Read<EstudianteDetalleModel>().FirstOrDefault();

                        if (estudiante == null)
                        {
                            return NotFound(new { message = $"Estudiante con ID {idUsuario} no encontrado" });
                        }

                        estudiante.Encargados = multi.Read<EncargadoModel>().ToList();
                        estudiante.Documentos = multi.Read<DocumentoModel>().ToList();
                        estudiante.Practicas = multi.Read<PracticaModel>().ToList();

                        return Ok(estudiante);
                    }
                }
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new
                {
                    type = "SQL Error",
                    message = "Error de base de datos al consultar el estudiante",
                    error = sqlEx.Message,
                    number = sqlEx.Number,
                    procedure = sqlEx.Procedure,
                    lineNumber = sqlEx.LineNumber
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    type = ex.GetType().Name,
                    message = "Error al consultar el estudiante",
                    error = ex.Message,
                    innerError = ex.InnerException?.Message
                });
            }
        }
        #endregion

        #region Actualizar Estado Académico
        [HttpPost]
        [Route("ActualizarEstadoAcademico")]
        public IActionResult ActualizarEstadoAcademico([FromBody] ActualizarEstadoRequest request)
        {
            using (var db = Conn())
            {
                var p = new DynamicParameters();
                p.Add("@IdUsuario", request.IdUsuario);
                p.Add("@NuevoEstado", request.NuevoEstadoId == 1);

                var resultado = db.QueryFirstOrDefault<RespuestaGenericaModel>(
                    "ActualizarEstadoAcademicoSP",
                    p,
                    commandType: CommandType.StoredProcedure
                );

                if (resultado != null && resultado.Resultado == 1)
                    return Ok(new { success = true, message = resultado.Mensaje });

                return BadRequest(new { success = false, message = resultado?.Mensaje ?? "Error al actualizar" });
            }
        }
        #endregion

        #region Eliminar Documento
        [HttpPost]
        [Route("EliminarDocumento")]
        public IActionResult EliminarDocumento([FromBody] EliminarDocumentoRequest request)
        {
            using (var db = Conn())
            {
                var p = new DynamicParameters();
                p.Add("@IdDocumento", request.IdDocumento);

                var resultado = db.QueryFirstOrDefault<RespuestaGenericaModel>(
                    "EliminarDocumentoSP",
                    p,
                    commandType: CommandType.StoredProcedure
                );

                if (resultado != null && resultado.Resultado == 1)
                    return Ok(new { success = true, message = resultado.Mensaje });

                return BadRequest(new { success = false, message = "Error al eliminar el documento" });
            }
        }
        #endregion

        #region Obtener Especialidades
        [HttpGet]
        [Route("ObtenerEspecialidades")]
        public IActionResult ObtenerEspecialidades()
        {
            try
            {
                using (var db = Conn())
                {
                    db.Open();
                    var data = db.Query<EspecialidadModel>(
                        "ObtenerEspecialidadesSP",
                        commandType: CommandType.StoredProcedure
                    ).ToList();

                    return Ok(data);
                }
            }
            catch (SqlException sqlEx)
            {
                return StatusCode(500, new
                {
                    type = "SQL Error",
                    message = "Error de base de datos al obtener especialidades",
                    error = sqlEx.Message,
                    number = sqlEx.Number,
                    procedure = sqlEx.Procedure
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new
                {
                    type = ex.GetType().Name,
                    message = "Error al obtener especialidades",
                    error = ex.Message,
                    innerError = ex.InnerException?.Message
                });
            }
        }
        #endregion

        // ==========================================================
        // ✅ NUEVO: Visualizar / Descargar Documento (sin SQL directo)
        // Usa SP: ObtenerRutaDocumentoSP
        // ==========================================================

        #region Visualizar Documento (inline)
        [HttpGet]
        [Route("VisualizarDocumento/{id}")]
        public IActionResult VisualizarDocumento(int id)
        {
            try
            {
                using (var db = Conn())
                {
                    db.Open();

                    var p = new DynamicParameters();
                    p.Add("@IdDocumento", id);

                    // SP debe devolver al menos: UrlDocumento
                    var doc = db.QueryFirstOrDefault<DocumentoRutaResponse>(
                        "ObtenerRutaDocumentoSP",
                        p,
                        commandType: CommandType.StoredProcedure
                    );

                    if (doc == null || string.IsNullOrWhiteSpace(doc.Documento))
                        return NotFound(new { message = "Documento no encontrado o sin ruta" });

                    var ruta = NormalizarRutaLocal(doc.Documento);

                    if (!System.IO.File.Exists(ruta))
                        return NotFound(new { message = "Archivo no existe en disco", ruta });

                    var bytes = System.IO.File.ReadAllBytes(ruta);
                    var mime = ObtenerMimePorExtension(ruta);
                    var fileName = Path.GetFileName(ruta);

                    Response.Headers["Content-Disposition"] = $"inline; filename=\"{fileName}\"";
                    return File(bytes, mime);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message, inner = ex.InnerException?.Message });
            }
        }
        #endregion

        #region Descargar Documento (attachment)
        [HttpGet]
        [Route("DescargarDocumento/{id}")]
        public IActionResult DescargarDocumento(int id)
        {
            try
            {
                using (var db = Conn())
                {
                    db.Open();

                    var p = new DynamicParameters();
                    p.Add("@IdDocumento", id);

                    var doc = db.QueryFirstOrDefault<DocumentoRutaResponse>(
                        "ObtenerRutaDocumentoSP",
                        p,
                        commandType: CommandType.StoredProcedure
                    );

                    if (doc == null || string.IsNullOrWhiteSpace(doc.Documento))
                        return NotFound(new { message = "Documento no encontrado o sin ruta" });

                    var ruta = NormalizarRutaLocal(doc.Documento);

                    if (!System.IO.File.Exists(ruta))
                        return NotFound(new { message = "Archivo no existe en disco", ruta });

                    var bytes = System.IO.File.ReadAllBytes(ruta);
                    var mime = ObtenerMimePorExtension(ruta);
                    var fileName = Path.GetFileName(ruta);

                    return File(bytes, mime, fileName);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { error = ex.Message, inner = ex.InnerException?.Message });
            }
        }
        #endregion

        // ===== Helpers =====

        private static string NormalizarRutaLocal(string ruta)
        {
            if (string.IsNullOrWhiteSpace(ruta)) return ruta;

            // Soporta file:///C:/carpeta/archivo.pdf
            if (ruta.StartsWith("file:///", StringComparison.OrdinalIgnoreCase))
                ruta = ruta.Replace("file:///", "");

            // URL-style a Windows-style
            ruta = ruta.Replace("/", "\\");

            return ruta.Trim();
        }

        private static string ObtenerMimePorExtension(string ruta)
        {
            var ext = Path.GetExtension(ruta).ToLowerInvariant();
            return ext switch
            {
                ".pdf" => "application/pdf",
                ".png" => "image/png",
                ".jpg" => "image/jpeg",
                ".jpeg" => "image/jpeg",
                ".doc" => "application/msword",
                ".docx" => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                _ => "application/octet-stream"
            };
        }
    }

    #region Request Models
    public class ActualizarEstadoRequest
    {
        public int IdUsuario { get; set; }
        public int NuevoEstadoId { get; set; }
    }

    public class EliminarDocumentoRequest
    {
        public int IdDocumento { get; set; }
    }

    public class RespuestaGenericaModel
    {
        public int Resultado { get; set; }
        public string Mensaje { get; set; } = "";
    }
    #endregion

    #region SP Response Models
    // Respuesta del SP ObtenerRutaDocumentoSP
    public class DocumentoRutaResponse
    {
        public string Documento { get; set; } = "";
    }
    #endregion
}
