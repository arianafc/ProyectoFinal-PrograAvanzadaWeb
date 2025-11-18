using Dapper;
using Microsoft.AspNetCore.Http;
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

        // LISTAR
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

            return Ok(ApiResponse<IEnumerable<VacanteListDto>>.Success(data));
        }

        // DETALLE
        [HttpGet("Detalle/{id}")]
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

        // UBICACION EMPRESA
        [HttpGet("Ubicacion-Empresa")]
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

        // CREAR
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

            var rows = cn.Execute(
                "CrearVacanteSP",
                p,
                commandType: System.Data.CommandType.StoredProcedure
            );

            return Ok(new
            {
                ok = rows > 0,
                message = rows > 0 ? "Vacante creada correctamente." : "Error al crear vacante."
            });
        }


        // EDITAR
        [HttpPost("Editar")]
        public IActionResult Editar([FromBody] VacanteCrearEditarDto dto)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.AddDynamicParams(dto);

            var rows = cn.Execute("EditarVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Ok(new
            {
                ok = rows > 0,
                message = rows > 0 ? "Vacante actualizada." : "Error al actualizar."
            });
        }

        // ELIMINAR
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

        // POSTULACIONES
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

        // ESTUDIANTES-ASIGNAR
        [HttpGet("Estudiantes-Asignar")]
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

        // ASIGNAR
        [HttpPost("Asignar-Estudiante")]
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

        // RETIRAR
        [HttpPost("Retirar-Estudiante")]
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

        // DESASIGNAR PRACTICA
        [HttpPost("Desasignar-Practica")]
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

        // VISUALIZACIÓN DE POSTULACIÓN
        [HttpGet("Visualizacion-Postulacion")]
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
