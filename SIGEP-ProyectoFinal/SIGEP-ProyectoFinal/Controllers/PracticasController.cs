using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using System.Text;
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

        private HttpClient CreateApiClient()
        {
            var client = _http.CreateClient();
            var token = HttpContext.Session.GetString("Token");

            if (!string.IsNullOrWhiteSpace(token))
            {
                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", token);
            }

            return client;
        }

        private JsonSerializerOptions JsonOptions() => new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        };

        /* ======================================================
         VISTA: VACANTES ESTUDIANTES
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> VacantesEstudiantes()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            var vm = new VacantesViewModel();
            var options = JsonOptions();

            using (var client = CreateApiClient())
            {
                try
                {
                    var resEstados = await client.GetStringAsync(Api("Auxiliar/Estados"));
                    var estados = JsonSerializer.Deserialize<List<ComboVm>>(resEstados, options);
                    vm.Estados = estados?.Select(x => new SelectListItem
                    {
                        Value = x.value,
                        Text = x.text
                    }).ToList() ?? new List<SelectListItem>();
                }
                catch { vm.Estados = new List<SelectListItem>(); }

                try
                {
                    var resMod = await client.GetStringAsync(Api("Auxiliar/Modalidades"));
                    var modalidades = JsonSerializer.Deserialize<List<ComboVm>>(resMod, options);
                    vm.Modalidades = modalidades?.Select(x => new SelectListItem
                    {
                        Value = x.value,
                        Text = x.text
                    }).ToList() ?? new List<SelectListItem>();
                }
                catch { vm.Modalidades = new List<SelectListItem>(); }

                try
                {
                    var resEsp = await client.GetStringAsync(Api("Auxiliar/Especialidades"));
                    var especialidades = JsonSerializer.Deserialize<List<ComboVm>>(resEsp, options);
                    vm.Especialidades = especialidades?.Select(x => new SelectListItem
                    {
                        Value = x.value,
                        Text = x.text
                    }).ToList() ?? new List<SelectListItem>();
                }
                catch { vm.Especialidades = new List<SelectListItem>(); }

                try
                {
                    var resEmp = await client.GetStringAsync(Api("Auxiliar/Empresas"));
                    var empresas = JsonSerializer.Deserialize<List<ComboVm>>(resEmp, options);
                    vm.Empresas = empresas?.Select(x => new SelectListItem
                    {
                        Value = x.value,
                        Text = x.text
                    }).ToList() ?? new List<SelectListItem>();
                }
                catch { vm.Empresas = new List<SelectListItem>(); }
            }

            return View("VacantesEstudiantes", vm);
        }

        /* ======================================================
         VISTA: PRÁCTICAS COORDINADOR 
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> PracticasCoordinador()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            var vm = new VacantesViewModel();
            var options = JsonOptions();

            using (var client = CreateApiClient())
            {
                try
                {
                    var resEsp = await client.GetStringAsync(Api("Auxiliar/Especialidades"));
                    var especialidades = JsonSerializer.Deserialize<List<ComboVm>>(resEsp, options);
                    vm.Especialidades = especialidades?.Select(x => new SelectListItem
                    {
                        Value = x.value,
                        Text = x.text
                    }).ToList() ?? new List<SelectListItem>();
                }
                catch { vm.Especialidades = new List<SelectListItem>(); }
            }

            return View("PracticasCoordinador", vm);
        }

        /* ======================================================
         LISTAR ESTUDIANTES JSON (PARA DATATABLE)
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> ListarEstudiantesJson()
        {
            using (var client = CreateApiClient())
            {
                var url = Api("Estudiante/ListarEstudiantesConPracticas");
                var resp = await client.GetAsync(url);

                if (!resp.IsSuccessStatusCode)
                    return Json(new { data = new List<object>() });

                var json = await resp.Content.ReadAsStringAsync();

                var parsed = JsonSerializer.Deserialize<ApiResponse<List<dynamic>>>(
                    json,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                );

                return Json(new { data = parsed?.Data ?? new List<dynamic>() });
            }
        }

        /* ======================================================
         OBTENER VACANTES PARA ASIGNAR
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> ObtenerVacantesAsignar(int idUsuario)
        {
            using (var client = CreateApiClient())
            {
                var url = Api($"Practicas/VacantesParaAsignar?idUsuario={idUsuario}");
                var resp = await client.GetAsync(url);
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         CAMBIAR ESTADO ACADÉMICO
         * ====================================================== */
        [HttpPost]
        public async Task<IActionResult> CambiarEstadoAcademico(int idUsuario, string nuevoEstado)
        {
            using (var client = CreateApiClient())
            {
                var url = Api("Estudiante/CambiarEstadoAcademico");

                var form = new Dictionary<string, string>
                {
                    ["idUsuario"] = idUsuario.ToString(),
                    ["nuevoEstado"] = nuevoEstado
                };

                var resp = await client.PostAsync(url, new FormUrlEncodedContent(form));
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         LLENAR TABLA VACANTES
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> GetVacantes(int idEstado = 0, int idEspecialidad = 0, int idModalidad = 0)
        {
            using (var client = CreateApiClient())
            {
                var url = Api($"Practicas/Listar?idEstado={idEstado}&idEspecialidad={idEspecialidad}&idModalidad={idModalidad}");

                var token = HttpContext.Session.GetString("Token");

                if (!string.IsNullOrEmpty(token))
                {
                    client.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", token);
                }

                var resp = await client.GetAsync(url);



                if (!resp.IsSuccessStatusCode)
                    return Json(new { data = new List<object>() });

                var json = await resp.Content.ReadAsStringAsync();

                try
                {
                    var vacantes = JsonSerializer.Deserialize<List<VacanteListVm>>(
                        json,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                    );

                    return Json(new { data = vacantes ?? new List<VacanteListVm>() });
                }
                catch
                {
                    return Json(new { data = new List<object>() });
                }
            }
        }

        /* ======================================================
         CREAR VACANTE
         * ====================================================== */
        [HttpPost]
        public async Task<IActionResult> Crear([FromBody] JsonElement json)
        {
            using (var client = CreateApiClient())
            {

                var url = Api("Practicas/Crear");
                var content = new StringContent(json.GetRawText(), Encoding.UTF8, "application/json");

                var resp = await client.PostAsync(url, content);
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         EDITAR VACANTE
         * ====================================================== */
        [HttpPost]
        public async Task<IActionResult> Editar([FromBody] JsonElement json)
        {
            using (var client = CreateApiClient())
            {
                var url = Api("Practicas/Editar");
                var content = new StringContent(json.GetRawText(), Encoding.UTF8, "application/json");

                var resp = await client.PutAsync(url, content);
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         ELIMINAR / ARCHIVAR
         * ====================================================== */
        [HttpPost]
        public async Task<IActionResult> Eliminar(int id)
        {
            using (var client = CreateApiClient())
            {
                var url = Api($"Practicas/Eliminar/{id}");
                var resp = await client.DeleteAsync(url);
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         DETALLE
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> Detalle(int id)
        {
            using (var client = CreateApiClient())
            {
                var url = Api($"Practicas/Detalle?id={id}");
                var resp = await client.GetAsync(url);
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         UBICACIÓN EMPRESA
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> GetUbicacionEmpresa(int idEmpresa)
        {
            using (var client = CreateApiClient())
            {
                var url = Api($"Practicas/UbicacionEmpresa/{idEmpresa}");
                var resp = await client.GetAsync(url);
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         ASIGNAR ESTUDIANTE
         * ====================================================== */
        [HttpPost]
        public async Task<IActionResult> AsignarEstudiante(int idUsuario, int idVacante)
        {
            try
            {
                using (var client = CreateApiClient())
                {
                    var url = Api("Practicas/AsignarEstudiante");

                    var form = new Dictionary<string, string>
                    {
                        ["idVacante"] = idVacante.ToString(),
                        ["idUsuario"] = idUsuario.ToString()
                    };

                    var resp = await client.PostAsync(url, new FormUrlEncodedContent(form));
                    return Content(await resp.Content.ReadAsStringAsync(), "application/json");
                }
            }
            catch
            {
                return StatusCode(500, "Error interno del servidor");
            }
        }

        /* ======================================================
         RETIRAR ESTUDIANTE
         * ====================================================== */
        [HttpPost]
        public async Task<IActionResult> RetirarEstudiante(int idVacante, int idUsuario, string comentario)
        {
            using (var client = CreateApiClient())
            {
                var url = Api("Practicas/RetirarEstudiante");

                var form = new Dictionary<string, string>
                {
                    ["idVacante"] = idVacante.ToString(),
                    ["idUsuario"] = idUsuario.ToString(),
                    ["comentario"] = comentario ?? ""
                };

                var resp = await client.PostAsync(url, new FormUrlEncodedContent(form));
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         DESASIGNAR PRÁCTICA
         * ====================================================== */
        [HttpPost]
        public async Task<IActionResult> DesasignarPractica(int idPractica, string comentario)
        {
            using (var client = CreateApiClient())
            {
                var url = Api("Practicas/DesasignarPractica");

                var form = new Dictionary<string, string>
                {
                    ["idPractica"] = idPractica.ToString(),
                    ["comentario"] = comentario ?? ""
                };

                var resp = await client.PostAsync(url, new FormUrlEncodedContent(form));
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

        /* ======================================================
         VISTA: VISUALIZACIÓN POSTULACIÓN
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> VisualizacionPostulacion(int idVacante, int idUsuario)
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            try
            {
                using (var client = CreateApiClient())
                {
                    var token = HttpContext.Session.GetString("Token");

                    if (!string.IsNullOrEmpty(token))
                    {
                        client.DefaultRequestHeaders.Authorization =
                            new AuthenticationHeaderValue("Bearer", token);
                    }


                    var urlPractica = Api($"Practicas/ObtenerVisualizacionPractica?idVacante={idVacante}&idUsuario={idUsuario}");
                    var respuestaPractica = await client.GetAsync(urlPractica);

                    if (!respuestaPractica.IsSuccessStatusCode)
                    {
                        ViewBag.Error = "No se encontró información de la práctica.";
                        return View(new VacantePracticaModel());
                    }

                    var practica = await respuestaPractica.Content.ReadFromJsonAsync<VacantePracticaModel>();

                    if (practica == null)
                    {
                        ViewBag.Error = "No se encontró información de la práctica.";
                        return View(new VacantePracticaModel());
                    }

                    var urlComentarios = Api($"Practicas/ObtenerComentariosPractica?idVacante={idVacante}&idUsuario={idUsuario}");
                    var respuestaComentarios = await client.GetAsync(urlComentarios);

                    if (respuestaComentarios.IsSuccessStatusCode)
                    {
                        var comentarios = await respuestaComentarios.Content.ReadFromJsonAsync<List<ComentarioPracticaModel>>();
                        practica.Comentarios = comentarios ?? new List<ComentarioPracticaModel>();
                    }

                    var urlEstados = Api("Practicas/ObtenerEstadosPractica");
                    var respuestaEstados = await client.GetAsync(urlEstados);

                    if (respuestaEstados.IsSuccessStatusCode)
                    {
                        var estados = await respuestaEstados.Content.ReadFromJsonAsync<List<EstadoPracticaModel>>();
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

        /* ======================================================
         OBTENER ESTUDIANTES ASIGNAR
         * ====================================================== */
        [HttpGet]
        public async Task<IActionResult> ObtenerEstudiantesAsignar(int idVacante, int idUsuarioSesion)
        {
            using (var client = CreateApiClient())
            {
                var url = Api($"Practicas/EstudiantesAsignar?idVacante={idVacante}&idUsuarioSesion={idUsuarioSesion}");
                var resp = await client.GetAsync(url);
                return Content(await resp.Content.ReadAsStringAsync(), "application/json");
            }
        }

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
                    var token = HttpContext.Session.GetString("Token");

                    if (!string.IsNullOrEmpty(token))
                    {
                        context.DefaultRequestHeaders.Authorization =
                            new AuthenticationHeaderValue("Bearer", token);
                    }


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

                    var token = HttpContext.Session.GetString("Token");

                    if (!string.IsNullOrEmpty(token))
                    {
                        context.DefaultRequestHeaders.Authorization =
                            new AuthenticationHeaderValue("Bearer", token);
                    }

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