using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.Data.SqlClient;
using SIGEP_ProyectoFinal.Models;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class PracticasController : Controller
    {
        private readonly IConfiguration _config;
        public PracticasController(IConfiguration config) => _config = config;
        private SqlConnection Conn() => new SqlConnection(_config.GetConnectionString("BDConnection"));

        // GET: /Practicas/Vacantes
        public async Task<IActionResult> Vacantes()
        {
            var rol = HttpContext.Session.GetInt32("IdRol") ?? 0;

            using var cn = Conn();
            var model = new VacantesViewModel
            {
                IdRol = rol,
                Estados = await cn.QueryAsync<SelectListItem>(
                    "SELECT CAST(IdEstado AS nvarchar(10)) AS [Value], Descripcion AS [Text] FROM EstadoTB ORDER BY Descripcion"),
                Modalidades = await cn.QueryAsync<SelectListItem>(
                    "SELECT CAST(IdModalidad AS nvarchar(10)) AS [Value], Descripcion AS [Text] FROM ModalidadTB ORDER BY Descripcion"),
                Especialidades = await cn.QueryAsync<SelectListItem>(
                    "SELECT CAST(IdEspecialidad AS nvarchar(10)) AS [Value], Descripcion AS [Text] FROM EspecialidadTB ORDER BY Descripcion"),
                Empresas = await cn.QueryAsync<SelectListItem>(
                    "SELECT CAST(IdEmpresa AS nvarchar(10)) AS [Value], Nombre AS [Text] FROM EmpresaTB ORDER BY Nombre")
            };

            return View(model);
        }

        // ============== JSON endpoints usados por tu JS =================

        // GET: /Practicas/GetVacantes
        [HttpGet]
        public async Task<IActionResult> GetVacantes(int idEstado = 0, int idEspecialidad = 0, int idModalidad = 0)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdEstado", idEstado);
            p.Add("@IdEspecialidad", idEspecialidad);
            p.Add("@IdModalidad", idModalidad);

            var data = await cn.QueryAsync<VacanteListDto>(
                "GetVacantesSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Json(new { ok = true, data });
        }

        // GET: /Practicas/Detalle
        [HttpGet]
        public async Task<IActionResult> Detalle(int id)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", id);

            var d = await cn.QueryFirstOrDefaultAsync<VacanteDetalleDto>(
                "DetalleVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            if (d == null) return Json(new { ok = false, message = "Vacante no encontrada." });
            return Json(new { ok = true, data = d });
        }

        // GET: /Practicas/GetUbicacionEmpresa
        [HttpGet]
        public async Task<IActionResult> GetUbicacionEmpresa(int idEmpresa)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdEmpresa", idEmpresa);

            var ubi = await cn.QueryFirstOrDefaultAsync<string>(
                "ObtenerUbicacionEmpresaSP", p, commandType: System.Data.CommandType.StoredProcedure) ?? "No registrada";

            return Json(new { ok = true, ubicacion = ubi });
        }

        // POST: /Practicas/Crear
        [HttpPost]
        public async Task<IActionResult> Crear(VacanteCrearEditarDto dto)
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

            var rows = await cn.ExecuteAsync("CrearVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);
            return Json(new { ok = rows > 0, message = rows > 0 ? "Vacante creada correctamente." : "No se pudo crear la vacante." });
        }

        // POST: /Practicas/Editar
        [HttpPost]
        public async Task<IActionResult> Editar(VacanteCrearEditarDto dto)
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

            var rows = await cn.ExecuteAsync("EditarVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);
            return Json(new { ok = rows > 0, message = rows > 0 ? "Vacante actualizada." : "No se pudo actualizar." });
        }

        // POST: /Practicas/Eliminar
        [HttpPost]
        public async Task<IActionResult> Eliminar(int id)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", id);

            // El SP devuelve SELECT 1 ok, 'mensaje' message
            var res = await cn.QueryFirstOrDefaultAsync<(int ok, string message)>(
                "EliminarVacanteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Json(new { ok = res.ok == 1, message = res.message });
        }

        // GET: /Practicas/ObtenerPostulaciones
        [HttpGet]
        public async Task<IActionResult> ObtenerPostulaciones(int idVacante)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);

            var data = await cn.QueryAsync<PostulacionDto>(
                "ObtenerPostulacionesSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Json(new { ok = true, data });
        }

        // GET: /Practicas/ObtenerEstudiantesAsignar
        [HttpGet]
        public async Task<IActionResult> ObtenerEstudiantesAsignar(int idVacante)
        {
            var idUsuarioSesion = HttpContext.Session.GetInt32("IdUsuario") ?? 0;

            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuarioSesion", idUsuarioSesion);

            var data = await cn.QueryAsync<EstAsignarDto>(
                "ObtenerEstudiantesAsignarSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Json(new { ok = true, data });
        }

        // POST: /Practicas/AsignarEstudiante
        [HttpPost]
        public async Task<IActionResult> AsignarEstudiante(int idVacante, int idUsuario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuario", idUsuario);

            var res = await cn.QueryFirstAsync<(int ok, string message)>(
                "AsignarEstudianteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Json(new { ok = res.ok == 1, message = res.message });
        }

        // POST: /Practicas/RetirarEstudiante
        [HttpPost]
        public async Task<IActionResult> RetirarEstudiante(int idVacante, int idUsuario, string comentario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuario", idUsuario);
            p.Add("@Comentario", comentario);

            var res = await cn.QueryFirstAsync<(int ok, string message)>(
                "RetirarEstudianteSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Json(new { ok = res.ok == 1, message = res.message });
        }

        // POST: /Practicas/DesasignarPractica
        [HttpPost]
        public async Task<IActionResult> DesasignarPractica(int idPractica, string comentario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdPractica", idPractica);
            p.Add("@Comentario", comentario);

            var res = await cn.QueryFirstAsync<(int ok, string message)>(
                "DesasignarPracticaSP", p, commandType: System.Data.CommandType.StoredProcedure);

            return Json(new { ok = res.ok == 1, message = res.message });
        }

        // GET: /Practicas/VisualizacionPostulacion
        [HttpGet]
        public async Task<IActionResult> VisualizacionPostulacion(int idVacante, int idUsuario)
        {
            using var cn = Conn();
            var p = new DynamicParameters();
            p.Add("@IdVacante", idVacante);
            p.Add("@IdUsuario", idUsuario);

            var data = await cn.QueryFirstOrDefaultAsync<PostulacionDto>(
                "VisualizacionPostulacionSP", p, commandType: System.Data.CommandType.StoredProcedure);

            if (data == null) return Json(new { ok = false, message = "No encontrada." });
            return Json(new { ok = true, data });
        }
    }
}
