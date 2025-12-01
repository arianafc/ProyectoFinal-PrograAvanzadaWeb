using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using SIGEP_API.Services;

namespace SIGEP_API.Controllers
{
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

        private SqlConnection Conn() =>
            new SqlConnection(_config.GetConnectionString("BDConnection"));

        // ======================================================
        // LISTAR VACANTES
        // GET: api/Practicas/Listar?idEstado=&idEspecialidad=&idModalidad=
        // ======================================================
        [HttpGet("Listar")]
        public IActionResult Listar(int idEstado = 0, int idEspecialidad = 0, int idModalidad = 0)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdEstado", idEstado);
            p.Add("@IdEspecialidad", idEspecialidad);
            p.Add("@IdModalidad", idModalidad);

            var data = cn.Query<VacanteListDto>(
                "GetVacantesSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new
            {
                ok = true,
                data = data
            });
        }

        // ======================================================
        // DETALLE VACANTE
        // GET: api/Practicas/Detalle?id=1
        // ======================================================
        [HttpGet("Detalle")]
        public IActionResult Detalle(int id)
        {
            using var cn = Conn();

            var p = new DynamicParameters();
            p.Add("@IdVacante", id);

            var d = cn.QueryFirstOrDefault<VacanteDetalleDto>(
                "DetalleVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            if (d == null)
                return NotFound(ApiResponse<string>.Fail("Vacante no encontrada."));

            return Ok(ApiResponse<VacanteDetalleDto>.Success(d));
        }

        // ======================================================
        // UBICACIÓN EMPRESA
        // GET: api/Practicas/UbicacionEmpresa?idEmpresa=1
        // ======================================================
        [HttpGet("UbicacionEmpresa")]
        public IActionResult UbicacionEmpresa(int idEmpresa)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdEmpresa", idEmpresa);

            var data = cn.QueryFirstOrDefault<string>(
                "ObtenerUbicacionEmpresaSP",
                p,
                commandType: System.Data.CommandType.StoredProcedure
            ) ?? "No registrada";

            return Ok(new { ok = true, ubicacion = data });
        }

        // ======================================================
        // CREAR VACANTE
        // POST: api/Practicas/Crear
        // Body: VacanteCrearEditarDto (JSON)
        // ======================================================
        [HttpPost("Crear")]
        public IActionResult Crear([FromBody] VacanteCrearEditarDto dto)
        {
            using var cn = Conn();
            var p = new DynamicParameters();

            p.Add("@Nombre", dto.Nombre);
            p.Add("@IdEmpresa", dto.IdEmpresa);
            p.Add("@IdEspecialidad", dto.IdEspecialidad);
            p.Add("@NumCupos", dto.NumCupos);
            p.Add("@IdModalidad", dto.IdModalidad);
            p.Add("@Requerimientos", dto.Requerimientos);
            p.Add("@Descripcion", dto.Descripcion);
            p.Add("@FechaMaxAplicacion", dto.FechaMaxAplicacion);
            p.Add("@FechaCierre", dto.FechaCierre);

            var resp = cn.QueryFirst<(int ok, string message, int? IdVacante)>(
                "CrearVacanteSP",
                p,
                commandType: System.Data.CommandType.StoredProcedure
            );

            return Ok(new
            {
                ok = resp.ok == 1,
                message = resp.message,
                idVacante = resp.IdVacante
            });
        }

        // ======================================================
        // EDITAR VACANTE
        // POST: api/Practicas/Editar
        // Body: VacanteCrearEditarDto (JSON)
        // ======================================================
        [HttpPost("Editar")]
        public IActionResult Editar([FromBody] VacanteCrearEditarDto dto)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", dto.IdVacante);
            p.Add("@Nombre", dto.Nombre);
            p.Add("@IdEmpresa", dto.IdEmpresa);
            p.Add("@IdEspecialidad", dto.IdEspecialidad);
            p.Add("@NumCupos", dto.NumCupos);
            p.Add("@IdModalidad", dto.IdModalidad);
            p.Add("@Requerimientos", dto.Requerimientos);
            p.Add("@Descripcion", dto.Descripcion);
            p.Add("@FechaMaxAplicacion", dto.FechaMaxAplicacion);
            p.Add("@FechaCierre", dto.FechaCierre);

            var rows = cn.Execute("EditarVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new
            {
                ok = rows > 0,
                message = rows > 0 ? "Vacante actualizada." : "Error al actualizar."
            });
        }

        // ======================================================
        // ELIMINAR / ARCHIVAR VACANTE
        // POST: api/Practicas/Eliminar
        // ======================================================
        [HttpPost("Eliminar")]
        public IActionResult Eliminar([FromForm] int id)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", id);

            var res = cn.QueryFirst<(int ok, string message)>(
                "EliminarVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new { ok = res.ok == 1, message = res.message });
        }

        // ======================================================
        // POSTULACIONES POR VACANTE
        // GET: api/Practicas/Postulaciones?idVacante=
        // ======================================================
        [HttpGet("Postulaciones")]
        public IActionResult Postulaciones(int idVacante)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);

            var data = cn.Query<PostulacionDto>(
                "ObtenerPostulacionesSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new { ok = true, data });
        }

        // ======================================================
        // ESTUDIANTES PARA ASIGNAR
        // GET: api/Practicas/EstudiantesAsignar?idVacante=&idUsuarioSesion=
        // ======================================================
        [HttpGet("EstudiantesAsignar")]
        public IActionResult EstudiantesAsignar(int idVacante, int idUsuarioSesion)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuarioSesion", idUsuarioSesion);

            var data = cn.Query<EstAsignarDto>(
                "ObtenerEstudiantesAsignarSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new { ok = true, data });
        }

        // ======================================================
        // ASIGNAR ESTUDIANTE
        // POST: api/Practicas/AsignarEstudiante
        // ======================================================
        [HttpPost("AsignarEstudiante")]
        public IActionResult AsignarEstudiante(int idVacante, int idUsuario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuario", idUsuario);

            var r = cn.QueryFirst<(int ok, string message)>(
                "AsignarEstudianteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new { ok = r.ok == 1, message = r.message });
        }

        // ======================================================
        // RETIRAR ESTUDIANTE (por vacante + usuario)
        // POST: api/Practicas/RetirarEstudiante
        // ======================================================
        [HttpPost("RetirarEstudiante")]
        public IActionResult Retirar(int idVacante, int idUsuario, string comentario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuario", idUsuario);
            p.Add("@Comentario", comentario);

            var r = cn.QueryFirst<(int ok, string message)>(
                "RetirarEstudianteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new { ok = r.ok == 1, message = r.message });
        }

        // ======================================================
        // DESASIGNAR PRÁCTICA (por IdPractica)
        // POST: api/Practicas/DesasignarPractica
        // ======================================================
        [HttpPost("DesasignarPractica")]
        public IActionResult Desasignar(int idPractica, string comentario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdPractica", idPractica);
            p.Add("@Comentario", comentario);

            var r = cn.QueryFirst<(int ok, string message)>(
                "DesasignarPracticaSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new { ok = r.ok == 1, message = r.message });
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