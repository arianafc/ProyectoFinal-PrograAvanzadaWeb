using Dapper;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PracticasController : ControllerBase
    {
        private readonly IConfiguration _config;
        public PracticasController(IConfiguration config) => _config = config;

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
        [HttpGet("VisualizacionPostulacion")]
        public IActionResult VisualizarPostulacion(int idVacante, int idUsuario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuario", idUsuario);

            var data = cn.QueryFirstOrDefault<PostulacionDto>(
                "VisualizacionPostulacionSP", p, commandType: System.Data.CommandType.StoredProcedure);

            if (data == null)
                return NotFound(new { ok = false, message = "No encontrada." });

            return Ok(new { ok = true, data });
        }
    }
}