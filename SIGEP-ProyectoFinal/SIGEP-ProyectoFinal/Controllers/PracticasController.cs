using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]
    [FiltroUsuarioAdmin]
    public class PracticasController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public PracticasController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        private string UrlApi(string ruta)
        {
            return _configuration["Valores:UrlAPI"] + ruta;
        }

        // ======================================================
        // VISTA: PRACTICAS COORDINADOR
        // ======================================================
        [HttpGet]
        public IActionResult PracticasCoordinador()
        {
            var model = CargarFiltros();
            return View(model);    
        }

        // ======================================================
        // VISTA: VACANTES ESTUDIANTES
        // ======================================================
        [HttpGet]
        public IActionResult VacantesEstudiantes()
        {
            var model = CargarFiltros();
            return View(model);   
        }

        // ======================================================
        // MÉTODO REUTILIZABLE PARA DROPDOWNS
        // ======================================================
        private VacantesViewModel CargarFiltros()
        {
            using var client = _http.CreateClient();

            var estados = client.GetAsync(UrlApi("Auxiliar/Estados")).Result
                .Content.ReadFromJsonAsync<List<SelectListItem>>().Result ?? new();

            var modalidades = client.GetAsync(UrlApi("Auxiliar/Modalidades")).Result
                .Content.ReadFromJsonAsync<List<SelectListItem>>().Result ?? new();

            var especialidades = client.GetAsync(UrlApi("Auxiliar/Especialidades")).Result
                .Content.ReadFromJsonAsync<List<SelectListItem>>().Result ?? new();

            var empresas = client.GetAsync(UrlApi("Auxiliar/Empresas")).Result
                .Content.ReadFromJsonAsync<List<SelectListItem>>().Result ?? new();

            return new VacantesViewModel
            {
                IdRol = HttpContext.Session.GetInt32("IdRol") ?? 0,
                Estados = estados,
                Modalidades = modalidades,
                Especialidades = especialidades,
                Empresas = empresas
            };
        }


        [HttpGet]
        public IActionResult GetVacantes(int idEstado = 0, int idEspecialidad = 0, int idModalidad = 0)
        {
            using var client = _http.CreateClient();
            var resp = client.GetAsync(
                UrlApi($"Practicas/Listar?idEstado={idEstado}&idEspecialidad={idEspecialidad}&idModalidad={idModalidad}")
            ).Result;

            if (!resp.IsSuccessStatusCode)
                return Json(new { ok = false, data = Array.Empty<object>() });

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpGet]
        public IActionResult Detalle(int id)
        {
            using var client = _http.CreateClient();
            var resp = client.GetAsync(UrlApi($"Practicas/Detalle/{id}")).Result;
            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpGet]
        public IActionResult GetUbicacionEmpresa(int idEmpresa)
        {
            using var client = _http.CreateClient();
            var resp = client.GetAsync(
                UrlApi($"Practicas/Ubicacion-Empresa?idEmpresa={idEmpresa}")
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpPost]
        public IActionResult Crear(VacanteCrearEditarDto dto)
        {
            using var client = _http.CreateClient();
            var resp = client.PostAsJsonAsync(
                UrlApi("Practicas/Crear"), dto
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpPost]
        public IActionResult Editar(VacanteCrearEditarDto dto)
        {
            using var client = _http.CreateClient();
            var resp = client.PostAsJsonAsync(
                UrlApi("Practicas/Editar"), dto
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpPost]
        public IActionResult Eliminar(int id)
        {
            using var client = _http.CreateClient();
            var resp = client.PostAsJsonAsync(
                UrlApi("Practicas/Eliminar"), new { id }
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpGet]
        public IActionResult ObtenerPostulaciones(int idVacante)
        {
            using var client = _http.CreateClient();
            var resp = client.GetAsync(
                UrlApi($"Practicas/Postulaciones?idVacante={idVacante}")
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpGet]
        public IActionResult ObtenerEstudiantesAsignar(int idVacante)
        {
            var idUsuario = HttpContext.Session.GetInt32("IdUsuario") ?? 0;

            using var client = _http.CreateClient();
            var resp = client.GetAsync(
                UrlApi($"Practicas/Estudiantes-Asignar?idVacante={idVacante}&idUsuarioSesion={idUsuario}")
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpPost]
        public IActionResult AsignarEstudiante(int idVacante, int idUsuario)
        {
            using var client = _http.CreateClient();
            var resp = client.PostAsJsonAsync(
                UrlApi("Practicas/Asignar-Estudiante"),
                new { idVacante, idUsuario }
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpPost]
        public IActionResult RetirarEstudiante(int idVacante, int idUsuario, string comentario)
        {
            using var client = _http.CreateClient();
            var resp = client.PostAsJsonAsync(
                UrlApi("Practicas/Retirar-Estudiante"),
                new { idVacante, idUsuario, comentario }
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpPost]
        public IActionResult DesasignarPractica(int idPractica, string comentario)
        {
            using var client = _http.CreateClient();
            var resp = client.PostAsJsonAsync(
                UrlApi("Practicas/Desasignar-Practica"),
                new { idPractica, comentario }
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }

        [HttpGet]
        public IActionResult VisualizacionPostulacion(int idVacante, int idUsuario)
        {
            using var client = _http.CreateClient();
            var resp = client.GetAsync(
                UrlApi($"Practicas/Visualizacion-Postulacion?idVacante={idVacante}&idUsuario={idUsuario}")
            ).Result;

            return Json(resp.Content.ReadFromJsonAsync<object>().Result);
        }
    }
}
