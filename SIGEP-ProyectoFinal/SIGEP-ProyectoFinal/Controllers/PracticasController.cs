using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using System.Text.Json;

namespace SIGEP_ProyectoFinal.Controllers
{
    //[Seguridad]
    //[FiltroUsuarioAdmin]
    public class PracticasController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public PracticasController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        private string Api(string ruta)
        {
            return _configuration["Valores:UrlAPI"] + ruta;
        }

        /* ======================================================
         * 1. VISTA PRINCIPAL
         * ====================================================== */
        /* ====================================================================================
  * 1. VISTA PRINCIPAL — CARGA DE DROPDOWNS (CORREGIDO)
  * ==================================================================================== */
        [HttpGet]
        public IActionResult VacantesEstudiantes()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            var vm = new VacantesViewModel();

            var client = _http.CreateClient();

           
            var token = HttpContext.Session.GetString("Token");
            if (!string.IsNullOrEmpty(token))
            {
                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", token);
            }

            var options = new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            };

            // 1️⃣ ESTADOS
            try
            {
                var resEstados = client.GetStringAsync(Api("Auxiliar/Estados")).Result;
                var estados = JsonSerializer.Deserialize<List<ComboVm>>(resEstados, options);
                vm.Estados = estados?.Select(x => new SelectListItem
                {
                    Value = x.value,
                    Text = x.text
                }).ToList() ?? new List<SelectListItem>();
            }
            catch { vm.Estados = new List<SelectListItem>(); }

            // 2️⃣ MODALIDADES
            try
            {
                var resMod = client.GetStringAsync(Api("Auxiliar/Modalidades")).Result;
                var modalidades = JsonSerializer.Deserialize<List<ComboVm>>(resMod, options);
                vm.Modalidades = modalidades?.Select(x => new SelectListItem
                {
                    Value = x.value,
                    Text = x.text
                }).ToList() ?? new List<SelectListItem>();
            }
            catch { vm.Modalidades = new List<SelectListItem>(); }

            // 3️⃣ ESPECIALIDADES
            try
            {
                var resEsp = client.GetStringAsync(Api("Auxiliar/Especialidades")).Result;
                var especialidades = JsonSerializer.Deserialize<List<ComboVm>>(resEsp, options);
                vm.Especialidades = especialidades?.Select(x => new SelectListItem
                {
                    Value = x.value,
                    Text = x.text
                }).ToList() ?? new List<SelectListItem>();
            }
            catch { vm.Especialidades = new List<SelectListItem>(); }

            // 4️⃣ EMPRESAS
            try
            {
                var resEmp = client.GetStringAsync(Api("Auxiliar/Empresas")).Result;
                var empresas = JsonSerializer.Deserialize<List<ComboVm>>(resEmp, options);
                vm.Empresas = empresas?.Select(x => new SelectListItem
                {
                    Value = x.value,
                    Text = x.text
                }).ToList() ?? new List<SelectListItem>();
            }
            catch { vm.Empresas = new List<SelectListItem>(); }

            return View("VacantesEstudiantes", vm);
        }


        /* ======================================================
         * 2. LLENAR TABLA
         * ====================================================== */
        [HttpGet]
        public IActionResult GetVacantes(int idEstado = 0, int idEspecialidad = 0, int idModalidad = 0)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/Listar?idEstado={idEstado}&idEspecialidad={idEspecialidad}&idModalidad={idModalidad}");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.GetAsync(url).Result;

                if (!resp.IsSuccessStatusCode)
                    return Json(new { data = new List<object>() });

                var json = resp.Content.ReadAsStringAsync().Result;

                var parsed = JsonSerializer.Deserialize<ApiResponse<List<VacanteListVm>>>(
                    json,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                );

                return Json(new { data = parsed?.Data ?? new List<VacanteListVm>() });
            }
        }


        /* ======================================================
         * 3. CREAR
         * ====================================================== */
        [HttpPost]
        public IActionResult Crear([FromBody] VacanteCrearEditarVm model)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/Crear");
                var resp = context.PostAsJsonAsync(url, model).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 4. EDITAR
         * ====================================================== */
        [HttpPost]
        public IActionResult Editar([FromBody] VacanteCrearEditarVm model)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/Editar");
                var resp = context.PostAsJsonAsync(url, model).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 5. ELIMINAR / ARCHIVAR
         * ====================================================== */
        [HttpPost]
        public IActionResult Eliminar(int id)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/Eliminar?id={id}");
                var resp = context.PostAsync(url, null).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 6. DETALLE
         * ====================================================== */
        [HttpGet]
        public IActionResult Detalle(int id)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/Detalle?id={id}");
                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 7. UBICACIÓN EMPRESA
         * ====================================================== */
        [HttpGet]
        public IActionResult GetUbicacionEmpresa(int idEmpresa)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/UbicacionEmpresa?idEmpresa={idEmpresa}");
                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 8. POSTULACIONES
         * ====================================================== */
        [HttpGet]
        public IActionResult ObtenerPostulaciones(int idVacante)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/Postulaciones?idVacante={idVacante}");
                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 9. VISUALIZACIÓN POSTULACIÓN
         * ====================================================== */
        [HttpGet]
        public IActionResult VisualizacionPostulacion(int idVacante, int idUsuario)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/VisualizacionPostulacion?idVacante={idVacante}&idUsuario={idUsuario}");
                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 10. ESTUDIANTES PARA ASIGNAR
         * ====================================================== */
        [HttpGet]
        public IActionResult ObtenerEstudiantesAsignar(int idVacante, int idUsuarioSesion)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/EstudiantesAsignar?idVacante={idVacante}&idUsuarioSesion={idUsuarioSesion}");
                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 11. ASIGNAR
         * ====================================================== */
        [HttpPost]
        public IActionResult AsignarEstudiante(int idUsuario, int idVacante)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/AsignarEstudiante");

                var form = new Dictionary<string, string>
                {
                    ["idUsuario"] = idUsuario.ToString(),
                    ["idVacante"] = idVacante.ToString()
                };

                var resp = context.PostAsync(url, new FormUrlEncodedContent(form)).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 12. RETIRAR
         * ====================================================== */
        [HttpPost]
        public IActionResult RetirarEstudiante(int idVacante, int idUsuario, string comentario)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/RetirarEstudiante");

                var form = new Dictionary<string, string>
                {
                    ["idVacante"] = idVacante.ToString(),
                    ["idUsuario"] = idUsuario.ToString(),
                    ["comentario"] = comentario ?? ""
                };

                var resp = context.PostAsync(url, new FormUrlEncodedContent(form)).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }


        /* ======================================================
         * 13. DESASIGNAR
         * ====================================================== */
        [HttpPost]
        public IActionResult DesasignarPractica(int idPractica, string comentario)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/DesasignarPractica");

                var form = new Dictionary<string, string>
                {
                    ["idPractica"] = idPractica.ToString(),
                    ["comentario"] = comentario ?? ""
                };

                var resp = context.PostAsync(url, new FormUrlEncodedContent(form)).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }
    }
}
