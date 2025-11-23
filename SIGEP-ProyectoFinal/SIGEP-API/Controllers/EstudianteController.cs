using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using System.Data;
using System.Text.Json;

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


        #region Listar Estudiantes CON LOGGING COMPLETO
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

                    // ⭐⭐⭐ AGREGAR ESTA CONFIGURACIÓN ⭐⭐⭐
                    return Ok(data); // Esto serializa automáticamente
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
                Console.WriteLine($"[API] Consultando estudiante con ID: {idUsuario}");

                using (var db = Conn())
                {
                    db.Open();
                    Console.WriteLine("[API] Conexión a BD abierta");

                    var p = new DynamicParameters();
                    p.Add("@IdUsuario", idUsuario);

                    Console.WriteLine("[API] Ejecutando SP ConsultarEstudianteSP");

                    using (var multi = db.QueryMultiple(
                        "ConsultarEstudianteSP",
                        p,
                        commandType: CommandType.StoredProcedure))
                    {
                        Console.WriteLine("[API] SP ejecutado, leyendo resultados...");

                        // Leer el estudiante
                        var estudiante = multi.Read<EstudianteDetalleModel>().FirstOrDefault();
                        Console.WriteLine($"[API] Estudiante leído: {(estudiante != null ? "OK" : "NULL")}");

                        if (estudiante == null)
                        {
                            Console.WriteLine($"[API] No se encontró estudiante con ID {idUsuario}");
                            return NotFound(new { message = $"Estudiante con ID {idUsuario} no encontrado" });
                        }

                        // Leer encargados
                        var encargados = multi.Read<EncargadoModel>().ToList();
                        estudiante.Encargados = encargados;
                        Console.WriteLine($"[API] Encargados leídos: {encargados.Count}");

                        // Leer documentos
                        var documentos = multi.Read<DocumentoModel>().ToList();
                        estudiante.Documentos = documentos;
                        Console.WriteLine($"[API] Documentos leídos: {documentos.Count}");

                        // Leer prácticas
                        var practicas = multi.Read<PracticaModel>().ToList();
                        estudiante.Practicas = practicas;
                        Console.WriteLine($"[API] Prácticas leídas: {practicas.Count}");

                        Console.WriteLine("[API] Retornando estudiante completo");
                        return Ok(estudiante);
                    }
                }
            }
            catch (SqlException sqlEx)
            {
                Console.WriteLine($"[API ERROR SQL] Number: {sqlEx.Number}, Message: {sqlEx.Message}");
                return StatusCode(500, new
                {
                    type = "SQL Error",
                    message = "Error de base de datos al consultar el estudiante",
                    error = sqlEx.Message,
                    number = sqlEx.Number,
                    procedure = sqlEx.Procedure,
                    lineNumber = sqlEx.LineNumber,
                    stackTrace = sqlEx.StackTrace
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[API ERROR] {ex.GetType().Name}: {ex.Message}");
                Console.WriteLine($"[API ERROR] Stack: {ex.StackTrace}");

                return StatusCode(500, new
                {
                    type = ex.GetType().Name,
                    message = "Error al consultar el estudiante",
                    error = ex.Message,
                    innerError = ex.InnerException?.Message,
                    innerType = ex.InnerException?.GetType().Name,
                    stackTrace = ex.StackTrace
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
                Console.WriteLine("[API] Obteniendo especialidades...");

                using (var db = Conn())
                {
                    db.Open();
                    Console.WriteLine("[API] Conexión abierta");

                    var data = db.Query<EspecialidadModel>(
                        "ObtenerEspecialidadesSP",
                        commandType: CommandType.StoredProcedure
                    ).ToList();

                    Console.WriteLine($"[API] Especialidades encontradas: {data.Count}");

                    return Ok(data);
                }
            }
            catch (SqlException sqlEx)
            {
                Console.WriteLine($"[API ERROR SQL] Number: {sqlEx.Number}");
                Console.WriteLine($"[API ERROR SQL] Message: {sqlEx.Message}");
                Console.WriteLine($"[API ERROR SQL] Procedure: {sqlEx.Procedure}");

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
                Console.WriteLine($"[API ERROR] Type: {ex.GetType().Name}");
                Console.WriteLine($"[API ERROR] Message: {ex.Message}");
                Console.WriteLine($"[API ERROR] Stack: {ex.StackTrace}");

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
}