using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using System.Text.Json;
using static SIGEP_ProyectoFinal.Models.VacantePracticaModel;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]
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
         * 1. VISTA: VACANTES ESTUDIANTES
         * ====================================================== */
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
         * 2. VISTA: PRÁCTICAS COORDINADOR (NUEVO)
         * ====================================================== */
        [HttpGet]
        public IActionResult PracticasCoordinador()
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

            // ESPECIALIDADES
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

            return View("PracticasCoordinador", vm);
        }

        /* ======================================================
         * 3. LISTAR ESTUDIANTES JSON (PARA DATATABLE)
         * ====================================================== */
        [HttpGet]
        public IActionResult ListarEstudiantesJson()
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Estudiante/ListarEstudiantesConPracticas");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.GetAsync(url).Result;

                if (!resp.IsSuccessStatusCode)
                    return Json(new { data = new List<object>() });

                var json = resp.Content.ReadAsStringAsync().Result;

                var parsed = JsonSerializer.Deserialize<ApiResponse<List<dynamic>>>(
                    json,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                );

                return Json(new { data = parsed?.Data ?? new List<dynamic>() });
            }
        }

        /* ======================================================
         * 4. OBTENER VACANTES PARA ASIGNAR
         * ====================================================== */
        [HttpGet]
        public IActionResult ObtenerVacantesAsignar(int idUsuario)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/VacantesParaAsignar?idUsuario={idUsuario}");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 5. CAMBIAR ESTADO ACADÉMICO
         * ====================================================== */
        [HttpPost]
        public IActionResult CambiarEstadoAcademico(int idUsuario, string nuevoEstado)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Estudiante/CambiarEstadoAcademico");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var form = new Dictionary<string, string>
                {
                    ["idUsuario"] = idUsuario.ToString(),
                    ["nuevoEstado"] = nuevoEstado
                };

                var resp = context.PostAsync(url, new FormUrlEncodedContent(form)).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 6. LLENAR TABLA VACANTES - CORREGIDO
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

                try
                {
                    // ✅ CORRECTO: El API retorna List<VacanteListDto> directamente
                    // NO está envuelto en ApiResponse
                    var vacantes = JsonSerializer.Deserialize<List<VacanteListVm>>(
                        json,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                    );

                    // DataTable espera { data: [...] }
                    return Json(new { data = vacantes ?? new List<VacanteListVm>() });
                }
                catch
                {
                    return Json(new { data = new List<object>() });
                }
            }
        }

        /* ======================================================
         * 7. CREAR VACANTE
         * ====================================================== */
        [HttpPost]
        public IActionResult Crear([FromBody] VacanteCrearEditarVm model)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/Crear");

                // ✅ VERIFICAR QUE ESTO EXISTA:
                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.PostAsJsonAsync(url, model).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 8. EDITAR VACANTE
         * ✅ CORREGIDO: Usa PutAsJsonAsync en lugar de PostAsJsonAsync
         * ====================================================== */
        [HttpPost]
        public IActionResult Editar([FromBody] VacanteCrearEditarVm model)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/Editar");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                // CRÍTICO: El API usa [HttpPut], así que debemos usar PutAsJsonAsync
                var resp = context.PutAsJsonAsync(url, model).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 9. ELIMINAR / ARCHIVAR
         * ✅ CORREGIDO: Usa DeleteAsync en lugar de PostAsync
         * ====================================================== */
        [HttpPost]
        public IActionResult Eliminar(int id)
        {
            using (var context = _http.CreateClient())
            {
                // CRÍTICO: El API usa [HttpDelete] y espera /{id} en la ruta
                var url = Api($"Practicas/Eliminar/{id}");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                // CRÍTICO: Usar DeleteAsync, NO PostAsync
                var resp = context.DeleteAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 10. DETALLE
         * ====================================================== */
        [HttpGet]
        public IActionResult Detalle(int id)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/Detalle?id={id}");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 11. UBICACIÓN EMPRESA
         * ✅ CORREGIDO: Usa /{idEmpresa} en la ruta, NO ?idEmpresa=
         * ====================================================== */
        [HttpGet]
        public IActionResult GetUbicacionEmpresa(int idEmpresa)
        {
            using (var context = _http.CreateClient())
            {
                // CRÍTICO: El API espera /{idEmpresa} en la ruta
                // Ejemplo: /api/Practicas/UbicacionEmpresa/1
                var url = Api($"Practicas/UbicacionEmpresa/{idEmpresa}");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 12. POSTULACIONES
         * ====================================================== */
        [HttpGet]
        public IActionResult ObtenerPostulaciones(int idVacante)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/Postulaciones?idVacante={idVacante}");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 14. ESTUDIANTES PARA ASIGNAR
         * ====================================================== */
        [HttpGet]
        public IActionResult ObtenerEstudiantesAsignar(int idVacante, int idUsuarioSesion)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api($"Practicas/EstudiantesAsignar?idVacante={idVacante}&idUsuarioSesion={idUsuarioSesion}");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var resp = context.GetAsync(url).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        /* ======================================================
         * 15. ASIGNAR ESTUDIANTE
         * ====================================================== */
        [HttpPost]
        public IActionResult AsignarEstudiante(int idUsuario, int idVacante)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/AsignarEstudiante");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

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
         * 16. RETIRAR ESTUDIANTE
         * ====================================================== */
        [HttpPost]
        public IActionResult RetirarEstudiante(int idVacante, int idUsuario, string comentario)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/RetirarEstudiante");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

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
         * 17. DESASIGNAR PRÁCTICA
         * ====================================================== */
        [HttpPost]
        public IActionResult DesasignarPractica(int idPractica, string comentario)
        {
            using (var context = _http.CreateClient())
            {
                var url = Api("Practicas/DesasignarPractica");

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var form = new Dictionary<string, string>
                {
                    ["idPractica"] = idPractica.ToString(),
                    ["comentario"] = comentario ?? ""
                };

                var resp = context.PostAsync(url, new FormUrlEncodedContent(form)).Result;

                return Content(resp.Content.ReadAsStringAsync().Result, "application/json");
            }
        }

        [HttpGet]
        public IActionResult VisualizacionPostulacion(int idVacante, int idUsuario)
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            try
            {
                using (var context = _http.CreateClient())
                {
                    // Obtener datos de la práctica
                    var urlPractica = _configuration["Valores:UrlAPI"] + $"Practicas/ObtenerVisualizacionPractica?idVacante={idVacante}&idUsuario={idUsuario}";
                    var respuestaPractica = context.GetAsync(urlPractica).Result;

                    if (!respuestaPractica.IsSuccessStatusCode)
                    {
                        ViewBag.Error = "No se encontró información de la práctica.";
                        return View(new VacantePracticaModel());
                    }

                    var practica = respuestaPractica.Content.ReadFromJsonAsync<VacantePracticaModel>().Result;

                    if (practica == null)
                    {
                        ViewBag.Error = "No se encontró información de la práctica.";
                        return View(new VacantePracticaModel());
                    }

                    // Obtener comentarios
                    var urlComentarios = _configuration["Valores:UrlAPI"] + $"Practicas/ObtenerComentariosPractica?idVacante={idVacante}&idUsuario={idUsuario}";
                    var respuestaComentarios = context.GetAsync(urlComentarios).Result;

                    if (respuestaComentarios.IsSuccessStatusCode)
                    {
                        var comentarios = respuestaComentarios.Content.ReadFromJsonAsync<List<ComentarioPracticaModel>>().Result;
                        practica.Comentarios = comentarios ?? new List<ComentarioPracticaModel>();
                    }

                    // Obtener estados
                    var urlEstados = _configuration["Valores:UrlAPI"] + "Practicas/ObtenerEstadosPractica";
                    var respuestaEstados = context.GetAsync(urlEstados).Result;

                    if (respuestaEstados.IsSuccessStatusCode)
                    {
                        var estados = respuestaEstados.Content.ReadFromJsonAsync<List<EstadoPracticaModel>>().Result;
                        practica.ListaEstados = estados ?? new List<EstadoPracticaModel>();
                    }

                    return View(practica);
                }
            }
            catch (Exception ex)
            {
                ViewBag.Error = "Error al cargar la información: " + ex.Message;
                return View(new VacantePracticaModel());
            }
        }
        [HttpPost]
        public IActionResult AgregarComentario(int idVacante, int idUsuario, string comentario)
        {
            try
            {
                var idUsuarioSesion = HttpContext.Session.GetInt32("IdUsuario");

                if (idUsuarioSesion == null)
                {
                    return Json(new { success = false, message = "Sesión expirada" });
                }

                if (string.IsNullOrWhiteSpace(comentario))
                {
                    return Json(new { success = false, message = "El comentario no puede estar vacío" });
                }

                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "Practicas/AgregarComentario";

                    var request = new
                    {
                        IdVacante = idVacante,
                        IdUsuario = idUsuario,
                        Comentario = comentario,
                        IdUsuarioComentario = idUsuarioSesion.Value
                    };

                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var resultado = respuesta.Content.ReadAsStringAsync().Result;
                        return Content(resultado, "application/json");
                    }

                    var error = respuesta.Content.ReadAsStringAsync().Result;
                    return Content(error, "application/json");
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult ActualizarEstadoPractica(int idPractica, int idEstado, string comentario)
        {
            try
            {
                var idUsuarioSesion = HttpContext.Session.GetInt32("IdUsuario");
                if (idUsuarioSesion == null)
                {
                    return Json(new { success = false, message = "Sesión expirada" });
                }

                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "Practicas/ActualizarEstadoPractica";
                    var request = new
                    {
                        IdPractica = idPractica,
                        IdEstado = idEstado,
                        Comentario = comentario,
                        IdUsuarioSesion = idUsuarioSesion.Value
                    };

                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var resultado = respuesta.Content.ReadAsStringAsync().Result;
                        return Content(resultado, "application/json");
                    }

                    var error = respuesta.Content.ReadAsStringAsync().Result;
                    return Content(error, "application/json");
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Error: " + ex.Message });
            }
        }

    }
}