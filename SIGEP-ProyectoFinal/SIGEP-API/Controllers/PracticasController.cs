using Dapper;
using Microsoft.AspNetCore.Authorization;
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
    public class PracticasController : ControllerBase
    {


        private readonly IConfiguration _config;
        private readonly IEmailService _emailService;

        public PracticasController(IConfiguration config, IEmailService emailService)
        {
            _config = config;
            _emailService = emailService;
        }

        public PracticasController(IConfiguration configuration, ILogger<PracticasController> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        // ======================================================
        // LISTAR VACANTES
        // GET: api/Practicas/Listar?idEstado=&idEspecialidad=&idModalidad=
        // ======================================================
        [HttpGet]
        [Route("Listar")]
        public IActionResult Listar(int idEstado = 0, int idEspecialidad = 0, int idModalidad = 0)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdEstado", idEstado);
                    parametros.Add("IdEspecialidad", idEspecialidad);
                    parametros.Add("IdModalidad", idModalidad);

                    var resultado = context.Query<VacanteListDto>("GetVacantesSP", parametros, commandType: CommandType.StoredProcedure);

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error en Listar vacantes");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // DETALLE VACANTE
        // GET: api/Practicas/Detalle?id=1
        // ======================================================
        [HttpGet]
        [Route("Detalle")]
        public IActionResult Detalle(int id)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdVacante", id);

                    var resultado = context.QueryFirstOrDefault<VacanteDetalleDto>("DetalleVacanteSP", parametros, commandType: CommandType.StoredProcedure);

                    if (resultado == null)
                        return NotFound("Vacante no encontrada");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en Detalle - IdVacante: {id}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // UBICACIÓN EMPRESA
        // GET: api/Practicas/UbicacionEmpresa/1
        // ======================================================
        [HttpGet]
        [Route("UbicacionEmpresa/{idEmpresa}")]
        public IActionResult UbicacionEmpresa(int idEmpresa)
        {
            try
            {
                _logger.LogInformation($"UbicacionEmpresa - IdEmpresa: {idEmpresa}");

                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdEmpresa", idEmpresa);

                    // QueryFirstOrDefault retorna el valor de la primera columna del resultado
                    var resultado = context.QueryFirstOrDefault<string>(
                        "ObtenerUbicacionEmpresaSP",
                        parametros,
                        commandType: CommandType.StoredProcedure
                    );

                    if (string.IsNullOrEmpty(resultado))
                    {
                        _logger.LogWarning($"UbicacionEmpresa - No se encontró ubicación para empresa {idEmpresa}");
                        return Ok("No registrada");
                    }

                    _logger.LogInformation($"UbicacionEmpresa - Ubicación encontrada: {resultado}");
                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en UbicacionEmpresa - IdEmpresa: {idEmpresa}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // CREAR VACANTE
        // POST: api/Practicas/Crear
        // Body: VacanteCrearEditarDto (JSON)
        // ======================================================
        [HttpPost]
        [Route("Crear")]
        public IActionResult Crear([FromBody] VacanteCrearEditarDto dto)
        {
            try
            {
                _logger.LogInformation($"Crear Vacante - Nombre: {dto.Nombre}, IdEmpresa: {dto.IdEmpresa}");

                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("Nombre", dto.Nombre);
                    parametros.Add("IdEmpresa", dto.IdEmpresa);
                    parametros.Add("IdEspecialidad", dto.IdEspecialidad);
                    parametros.Add("NumCupos", dto.NumCupos);
                    parametros.Add("IdModalidad", dto.IdModalidad);
                    parametros.Add("Requerimientos", dto.Requerimientos);
                    parametros.Add("Descripcion", dto.Descripcion);
                    parametros.Add("FechaMaxAplicacion", dto.FechaMaxAplicacion);
                    parametros.Add("FechaCierre", dto.FechaCierre);
                    parametros.Add("Resultado", dbType: DbType.Int32, direction: ParameterDirection.ReturnValue);

                    context.Execute("CrearVacanteSP", parametros, commandType: CommandType.StoredProcedure);

                    var resultado = parametros.Get<int>("Resultado");

                    _logger.LogInformation($"Crear Vacante - Resultado: {resultado}");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en Crear Vacante - Nombre: {dto.Nombre}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // EDITAR VACANTE
        // PUT: api/Practicas/Editar
        // Body: VacanteCrearEditarDto (JSON)
        // ======================================================
        [HttpPut]
        [Route("Editar")]
        public IActionResult Editar([FromBody] VacanteCrearEditarDto dto)
        {
            try
            {
                _logger.LogInformation($"Editar Vacante - IdVacante: {dto.IdVacante}, Nombre: {dto.Nombre}");

                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdVacante", dto.IdVacante);
                    parametros.Add("Nombre", dto.Nombre);
                    parametros.Add("IdEmpresa", dto.IdEmpresa);
                    parametros.Add("IdEspecialidad", dto.IdEspecialidad);
                    parametros.Add("NumCupos", dto.NumCupos);
                    parametros.Add("IdModalidad", dto.IdModalidad);
                    parametros.Add("Requerimientos", dto.Requerimientos);
                    parametros.Add("Descripcion", dto.Descripcion);
                    parametros.Add("FechaMaxAplicacion", dto.FechaMaxAplicacion);
                    parametros.Add("FechaCierre", dto.FechaCierre);
                    parametros.Add("Resultado", dbType: DbType.Int32, direction: ParameterDirection.ReturnValue);

                    context.Execute("EditarVacanteSP", parametros, commandType: CommandType.StoredProcedure);

                    var resultado = parametros.Get<int>("Resultado");

                    _logger.LogInformation($"Editar Vacante - Resultado: {resultado}");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en Editar Vacante - IdVacante: {dto.IdVacante}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // ELIMINAR VACANTE
        // DELETE: api/Practicas/Eliminar/1
        // ======================================================
        [HttpDelete]
        [Route("Eliminar/{id}")]
        public IActionResult Eliminar(int id)
        {
            try
            {
                _logger.LogInformation($"Eliminar Vacante - IdVacante: {id}");

                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdVacante", id);
                    parametros.Add("Resultado", dbType: DbType.Int32, direction: ParameterDirection.ReturnValue);

                    context.Execute("EliminarVacanteSP", parametros, commandType: CommandType.StoredProcedure);

                    var resultado = parametros.Get<int>("Resultado");

                    _logger.LogInformation($"Eliminar Vacante - Resultado: {resultado}");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en Eliminar Vacante - IdVacante: {id}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // POSTULACIONES POR VACANTE
        // GET: api/Practicas/Postulaciones?idVacante=
        // ======================================================
        [HttpGet]
        [Route("Postulaciones")]
        public IActionResult Postulaciones(int idVacante)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdVacante", idVacante);

                    var resultado = context.Query<PostulacionDto>("ObtenerPostulacionesSP", parametros, commandType: CommandType.StoredProcedure);

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en Postulaciones - IdVacante: {idVacante}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // ESTUDIANTES PARA ASIGNAR
        // GET: api/Practicas/EstudiantesAsignar?idVacante=&idUsuarioSesion=
        // ======================================================
        [HttpGet]
        [Route("EstudiantesAsignar")]
        public IActionResult EstudiantesAsignar(int idVacante, int idUsuarioSesion)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdVacante", idVacante);
                    parametros.Add("IdUsuarioSesion", idUsuarioSesion);

                    var resultado = context.Query<EstAsignarDto>("ObtenerEstudiantesAsignarSP", parametros, commandType: CommandType.StoredProcedure);

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en EstudiantesAsignar - IdVacante: {idVacante}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // ASIGNAR ESTUDIANTE
        // POST: api/Practicas/AsignarEstudiante
        // ======================================================
        [HttpPost]
        [Route("AsignarEstudiante")]
        public IActionResult AsignarEstudiante(int idVacante, int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdVacante", idVacante);
                    parametros.Add("IdUsuario", idUsuario);
                    parametros.Add("Resultado", dbType: DbType.Int32, direction: ParameterDirection.ReturnValue);

                    context.Execute("AsignarEstudianteSP", parametros, commandType: CommandType.StoredProcedure);

                    var resultado = parametros.Get<int>("Resultado");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en AsignarEstudiante - IdVacante: {idVacante}, IdUsuario: {idUsuario}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // RETIRAR ESTUDIANTE
        // POST: api/Practicas/RetirarEstudiante
        // ======================================================
        [HttpPost]
        [Route("RetirarEstudiante")]
        public IActionResult RetirarEstudiante(int idVacante, int idUsuario, string comentario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdVacante", idVacante);
                    parametros.Add("IdUsuario", idUsuario);
                    parametros.Add("Comentario", comentario);
                    parametros.Add("Resultado", dbType: DbType.Int32, direction: ParameterDirection.ReturnValue);

                    context.Execute("RetirarEstudianteSP", parametros, commandType: CommandType.StoredProcedure);

                    var resultado = parametros.Get<int>("Resultado");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en RetirarEstudiante - IdVacante: {idVacante}, IdUsuario: {idUsuario}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // DESASIGNAR PRÁCTICA
        // POST: api/Practicas/DesasignarPractica
        // ======================================================
        [HttpPost]
        [Route("DesasignarPractica")]
        public IActionResult DesasignarPractica(int idPractica, string comentario)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("IdPractica", idPractica);
                    parametros.Add("Comentario", comentario);
                    parametros.Add("Resultado", dbType: DbType.Int32, direction: ParameterDirection.ReturnValue);

                    context.Execute("DesasignarPracticaSP", parametros, commandType: CommandType.StoredProcedure);

                    var resultado = parametros.Get<int>("Resultado");

                    return Ok(resultado);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error en DesasignarPractica - IdPractica: {idPractica}");
                return StatusCode(500, "Error interno del servidor");
            }
        }

        // ======================================================
        // VISUALIZACIÓN DE POSTULACIÓN
        // GET: api/Practicas/VisualizacionPostulacion?idVacante=&idUsuario=
        // ======================================================

        [HttpGet]
        [Route("ObtenerVisualizacionPractica")]
        public IActionResult ObtenerVisualizacionPractica(int idVacante, int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_config["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdVacante", idVacante);
                    parametros.Add("@IdUsuario", idUsuario);

                    var practica = context.QueryFirstOrDefault<VisualizacionPracticaResponseModel>(
                        "ObtenerVisualizacionPracticaSP",
                        parametros
                    );

                    if (practica == null)
                    {
                        return NotFound(new { mensaje = "No se encontró información de la práctica" });
                    }

                    return Ok(practica);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener la práctica", detalle = ex.Message });
            }
        }

        [HttpGet]
        [Route("ObtenerComentariosPractica")]
        public IActionResult ObtenerComentariosPractica(int idVacante, int idUsuario)
        {
            try
            {
                using (var context = new SqlConnection(_config["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdVacante", idVacante);
                    parametros.Add("@IdUsuario", idUsuario);

                    var comentarios = context.Query<ComentarioPracticaResponseModel>(
                        "ObtenerComentariosPracticaSP",
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

        [HttpGet]
        [Route("ObtenerEstadosPractica")]
        public IActionResult ObtenerEstadosPractica()
        {
            try
            {
                using (var context = new SqlConnection(_config["ConnectionStrings:BDConnection"]))
                {
                    var estados = context.Query<EstadoPracticaResponseModel>(
                        "ObtenerEstadosPracticaSP"
                    ).ToList();

                    return Ok(estados);
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { mensaje = "Error al obtener estados", detalle = ex.Message });
            }
        }

        [HttpPost]
        [Route("AgregarComentario")]
        public IActionResult AgregarComentario(AgregarComentarioRequestModel request)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(request.Comentario))
                {
                    return BadRequest(new { exito = false, mensaje = "El comentario no puede estar vacío" });
                }

                using (var context = new SqlConnection(_config["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdVacante", request.IdVacante);
                    parametros.Add("@IdUsuario", request.IdUsuario);
                    parametros.Add("@Comentario", request.Comentario);
                    parametros.Add("@IdUsuarioComentario", request.IdUsuarioComentario);

                    var resultado = context.QueryFirstOrDefault<dynamic>(
                        "InsertarComentarioPracticaSP",
                        parametros
                    );

                    if (resultado != null && resultado.FilasAfectadas > 0)
                    {
                        return Ok(new { exito = true, mensaje = "Comentario agregado correctamente" });
                    }

                    return BadRequest(new { exito = false, mensaje = "No se pudo agregar el comentario. Verifique que la práctica exista." });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { exito = false, mensaje = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        [Route("ActualizarEstadoPractica")]
        public IActionResult ActualizarEstadoPractica(ActualizarEstadoPracticaRequestModel request)
        {
            try
            {
                using (var context = new SqlConnection(_config["ConnectionStrings:BDConnection"]))
                {
                    // ✅ VALIDACIÓN 1: Verificar estado académico del estudiante usando SP
                    var parametrosEstudiante = new DynamicParameters();
                    parametrosEstudiante.Add("@IdPractica", request.IdPractica);

                    var estudiante = context.QueryFirstOrDefault<dynamic>(
                        "VerificarEstadoAcademicoEstudianteSP",
                        parametrosEstudiante
                    );

                    if (estudiante != null && estudiante.EstadoAcademico == false)
                    {
                        return Ok(new
                        {
                            exito = false,
                            mensaje = "El estudiante no puede realizar ninguna práctica debido a que su estado académico es Rezagado. Por favor, contacte al coordinador académico."
                        });
                    }

                    // ✅ VALIDACIÓN 2: Obtener descripción del estado usando SP
                    var parametrosEstado = new DynamicParameters();
                    parametrosEstado.Add("@IdEstado", request.IdEstado);

                    var estadoNuevo = context.QueryFirstOrDefault<string>(
                        "ObtenerDescripcionEstadoSP",
                        parametrosEstado
                    );

                    // ✅ Si se intenta asignar, verificar que no tenga otra práctica activa usando SP
                    if (estadoNuevo == "Asignada")
                    {
                        var parametrosConflicto = new DynamicParameters();
                        parametrosConflicto.Add("@IdPractica", request.IdPractica);

                        var practicaConflictiva = context.QueryFirstOrDefault<dynamic>(
                            "VerificarPracticasSP",
                            parametrosConflicto
                        );

                        if (practicaConflictiva != null)
                        {
                            return Ok(new
                            {
                                exito = false,
                                mensaje = $"El estudiante ya tiene una práctica en estado '{practicaConflictiva.Estado}' ({practicaConflictiva.Nombre ?? "Sin nombre"}). Si desea asignar otra práctica, primero debe retirar o finalizar la práctica actual."
                            });
                        }
                    }

                    // ✅ Ejecutar SP para actualizar estado
                    var parametros = new DynamicParameters();
                    parametros.Add("@IdPractica", request.IdPractica);
                    parametros.Add("@IdEstado", request.IdEstado);
                    parametros.Add("@Comentario", request.Comentario);
                    parametros.Add("@IdUsuarioSesion", request.IdUsuarioSesion);

                    var resultado = context.QueryFirstOrDefault<ActualizarEstadoPracticaResponseModel>(
                        "ActualizarEstadoPracticaSP",
                        parametros
                    );

                    if (resultado == null)
                    {
                        return BadRequest(new { exito = false, mensaje = "No se encontró la práctica" });
                    }


                    bool correoEnviado = false;
                    if (!string.IsNullOrEmpty(resultado.EstudianteCorreo))
                    {
                        try
                        {
                            correoEnviado = _emailService.EnviarCorreoActualizacionEstado(
                                resultado.EstudianteCorreo,
                                resultado.EstudianteNombre,
                                resultado.EstadoDescripcion,
                                resultado.Comentario,
                                resultado.FechaComentario
                            );
                        }
                        catch (Exception emailEx)
                        {
                            Console.WriteLine($"Error al enviar correo: {emailEx.Message}");
                        }
                    }

                    return Ok(new
                    {
                        exito = true,
                        mensaje = correoEnviado
                            ? "Estado actualizado correctamente y notificación enviada por correo."
                            : "Estado actualizado correctamente, pero no se pudo enviar el correo de notificación.",
                        data = new
                        {
                            estado = resultado.EstadoDescripcion,
                            comentario = resultado.Comentario,
                            fecha = resultado.FechaComentario?.ToString("dd/MM/yyyy HH:mm")
                        }
                    });
                }
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { exito = false, mensaje = "Error: " + ex.Message });
            }
        }
    }
}