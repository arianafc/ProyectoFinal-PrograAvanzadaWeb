using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SIGEP_ProyectoFinal.Models;
using System.Text.Json;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]        // Desde el inicio ya protege todas las vistas
    //[FiltroUsuarioAdmin] // Rol 2 → Coordinador
    public class PracticasController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _config;

        public PracticasController(IHttpClientFactory http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        [HttpGet]
        public IActionResult VacantesEstudiantes()
        {
            var model = CargarFiltros();
            return View("VacantesEstudiantes", model);
        }

        private string Api(string ruta) =>
            $"{_config["Valores:UrlAPI"]}{ruta}";

        // ======================================================
        // VISTA PRINCIPAL – COORDINADOR
        // ======================================================
        [HttpGet]
        public IActionResult PracticasCoordinador()
        {
            var model = CargarFiltros();
            return View(model);
        }

        // ======================================================
        // Cargar combos iniciales
        // ======================================================
        private VacantesViewModel CargarFiltros()
        {
            using var client = _http.CreateClient();

            var estados = GetSelectList(client.GetStringAsync(Api("Auxiliar/Estados")).Result);
            var modalidades = GetSelectList(client.GetStringAsync(Api("Auxiliar/Modalidades")).Result);
            var especialidades = GetSelectList(client.GetStringAsync(Api("Auxiliar/Especialidades")).Result);
            var empresas = GetSelectList(client.GetStringAsync(Api("Auxiliar/Empresas")).Result);

            return new VacantesViewModel
            {
                Estados = estados,
                Modalidades = modalidades,
                Especialidades = especialidades,
                Empresas = empresas,
                Vacante = new VacanteModel()
            };
        }

        private List<SelectListItem> GetSelectList(string json)
        {
            try
            {
                return JsonSerializer.Deserialize<List<SelectListItem>>(json)
                       ?? new List<SelectListItem>();
            }
            catch
            {
                return new List<SelectListItem>();
            }
        }

        // ======================================================
        // GET → Vacantes para DataTable
        // ======================================================
        [HttpGet]
        public IActionResult GetVacantes(int idEstado = 0, int idEspecialidad = 0, int idModalidad = 0)
        {
            using var client = _http.CreateClient();
            var url = Api($"Practicas/Listar?idEstado={idEstado}&idEspecialidad={idEspecialidad}&idModalidad={idModalidad}");

            var json = client.GetStringAsync(url).Result;
            return Content(json, "application/json");
        }

        // ======================================================
        // GET → Detalle vacante
        // ======================================================
        [HttpGet]
        public IActionResult Detalle(int id)
        {
            using var client = _http.CreateClient();
            var json = client.GetStringAsync(Api($"Practicas/Detalle/{id}")).Result;
            return Content(json, "application/json");
        }

        // ======================================================
        // GET → Ubicación empresa
        // ======================================================
        [HttpGet]
        public IActionResult GetUbicacionEmpresa(int idEmpresa)
        {
            using var client = _http.CreateClient();
            var json = client.GetStringAsync(Api($"Practicas/Ubicacion-Empresa?idEmpresa={idEmpresa}")).Result;
            return Content(json, "application/json");
        }

        // ======================================================
        // POST → Crear vacante
        // ======================================================
        [HttpPost]
        public IActionResult Crear(VacantesViewModel model)
        {
            using var client = _http.CreateClient();

            var dto = model.Vacante; // FUERTE TIPADO

            var resp = client.PostAsJsonAsync(Api("Practicas/Crear"), dto).Result;
            var json = resp.Content.ReadAsStringAsync().Result;

            return Content(json, "application/json");
        }

        // ======================================================
        // POST → Editar vacante
        // ======================================================
        [HttpPost]
        public IActionResult Editar(VacanteModel model)
        {
            using var client = _http.CreateClient();

            var resp = client.PostAsJsonAsync(Api("Practicas/Editar"), model).Result;
            var json = resp.Content.ReadAsStringAsync().Result;

            return Content(json, "application/json");
        }

        // ======================================================
        // POST → Eliminar / Archivar
        // ======================================================
        [HttpPost]
        public IActionResult Eliminar(int id)
        {
            using var client = _http.CreateClient();

            var resp = client.PostAsJsonAsync(Api("Practicas/Eliminar"), new { id }).Result;
            var json = resp.Content.ReadAsStringAsync().Result;

            return Content(json, "application/json");
        }

        // ======================================================
        // GET → Postulaciones
        // ======================================================
        [HttpGet]
        public IActionResult ObtenerPostulaciones(int idVacante)
        {
            using var client = _http.CreateClient();

            var json = client.GetStringAsync(Api($"Practicas/Postulaciones?idVacante={idVacante}")).Result;
            return Content(json, "application/json");
        }

        // ======================================================
        // GET → Estudiantes disponibles para asignar
        // ======================================================
        [HttpGet]
        public IActionResult ObtenerEstudiantesAsignar(int idVacante)
        {
            var idUsuario = HttpContext.Session.GetInt32("IdUsuario") ?? 0;

            using var client = _http.CreateClient();
            var json = client.GetStringAsync(
                Api($"Practicas/Estudiantes-Asignar?idVacante={idVacante}&idUsuarioSesion={idUsuario}")
            ).Result;

            return Content(json, "application/json");
        }

        // ======================================================
        // POST → Asignar estudiante
        // ======================================================
        [HttpPost]
        public IActionResult AsignarEstudiante(int idVacante, int idUsuario)
        {
            using var client = _http.CreateClient();

            var resp = client.PostAsJsonAsync(
                Api("Practicas/Asignar-Estudiante"),
                new { idVacante, idUsuario }
            ).Result;

            var json = resp.Content.ReadAsStringAsync().Result;
            return Content(json, "application/json");
        }

        // ======================================================
        // POST → Retirar estudiante
        // ======================================================
        [HttpPost]
        public IActionResult RetirarEstudiante(int idVacante, int idUsuario, string comentario)
        {
            using var client = _http.CreateClient();

            var resp = client.PostAsJsonAsync(
                Api("Practicas/Retirar-Estudiante"),
                new { idVacante, idUsuario, comentario }
            ).Result;

            var json = resp.Content.ReadAsStringAsync().Result;
            return Content(json, "application/json");
        }

        // ======================================================
        // POST → Desasignar práctica
        // ======================================================
        [HttpPost]
        public IActionResult DesasignarPractica(int idPractica, string comentario)
        {
            using var client = _http.CreateClient();

            var resp = client.PostAsJsonAsync(
                Api("Practicas/Desasignar-Practica"),
                new { idPractica, comentario }
            ).Result;

            var json = resp.Content.ReadAsStringAsync().Result;
            return Content(json, "application/json");
        }

        // ======================================================
        // GET → Visualización de una postulación específica
        // ======================================================
        [HttpGet]
        public IActionResult VisualizacionPostulacion(int idVacante, int idUsuario)
        {
            using var client = _http.CreateClient();

            var json = client.GetStringAsync(
                Api($"Practicas/Visualizacion-Postulacion?idVacante={idVacante}&idUsuario={idUsuario}")
            ).Result;

            return Content(json, "application/json");
        }
    }
}
