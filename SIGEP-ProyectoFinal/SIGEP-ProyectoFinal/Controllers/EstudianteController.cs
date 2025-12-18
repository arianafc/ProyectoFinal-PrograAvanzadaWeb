using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using System.Text.Json;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]
    public class EstudianteController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public EstudianteController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        private string Api(string ruta) =>
            _configuration["Valores:UrlAPI"] + ruta;

        private HttpClient CrearClienteConToken()
        {
            var context = _http.CreateClient();
            var token = HttpContext.Session.GetString("Token") ?? "";
            context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return context;
        }

        private static string ObtenerNombreArchivo(HttpResponseMessage resp, int id, string fallback)
        {
            var cd = resp.Content.Headers.ContentDisposition;
            if (cd != null)
            {
                var fileName = cd.FileNameStar ?? cd.FileName;
                if (!string.IsNullOrWhiteSpace(fileName))
                    return fileName.Trim('"');
            }

            return $"{fallback}_{id}";
        }

        private static string ObtenerContentType(HttpResponseMessage resp)
        {
            return resp.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";
        }

        #region Vista Principal
        [HttpGet]
        public IActionResult ListarEstudiante()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            if (ViewBag.Usuario == null)
                return RedirectToAction("IniciarSesion", "Home");

            try
            {
                using (var context = CrearClienteConToken())
                {
                    var urlEsp = Api("Estudiante/ObtenerEspecialidades");
                    System.Diagnostics.Debug.WriteLine($"[WEB] URL Especialidades: {urlEsp}");

                    var respEsp = context.GetAsync(urlEsp).Result;
                    var content = respEsp.Content.ReadAsStringAsync().Result;

                    System.Diagnostics.Debug.WriteLine($"[WEB] Status Code: {respEsp.StatusCode}");
                    System.Diagnostics.Debug.WriteLine($"[WEB] Response Content: {content}");

                    if (respEsp.IsSuccessStatusCode)
                    {
                        ViewBag.Especialidades = JsonSerializer.Deserialize<List<EspecialidadModel>>(
                            content,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                        ) ?? new List<EspecialidadModel>();

                        System.Diagnostics.Debug.WriteLine($"[WEB] Especialidades cargadas: {ViewBag.Especialidades.Count}");
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"[WEB ERROR] Error al obtener especialidades: {content}");
                        ViewBag.Especialidades = new List<EspecialidadModel>();
                        TempData["Error"] = $"Error al cargar especialidades: {respEsp.StatusCode}";
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[WEB ERROR] Exception: {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[WEB ERROR] Inner: {ex.InnerException?.Message}");
                System.Diagnostics.Debug.WriteLine($"[WEB ERROR] Stack: {ex.StackTrace}");

                ViewBag.Especialidades = new List<EspecialidadModel>();
                TempData["Error"] = $"Error al cargar especialidades: {ex.Message}";
            }

            return View();
        }
        #endregion

        #region Obtener Estudiantes (DataTable)
        [HttpGet]
        public IActionResult GetEstudiantes(string estado = "", int idEspecialidad = 0)
        {
            try
            {
                using (var context = CrearClienteConToken())
                {
                    var url = Api($"Estudiante/ListarEstudiantes?estado={estado}&idEspecialidad={idEspecialidad}");

                    var resp = context.GetAsync(url).Result;
                    var content = resp.Content.ReadAsStringAsync().Result;

                    if (resp.IsSuccessStatusCode)
                    {
                        var lista = JsonSerializer.Deserialize<List<EstudianteListItemModel>>(
                            content,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                        );

                        return Json(new
                        {
                            data = lista ?? new List<EstudianteListItemModel>()
                        });
                    }

                    return Json(new
                    {
                        data = new List<EstudianteListItemModel>(),
                        error = content
                    });
                }
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    data = new List<EstudianteListItemModel>(),
                    error = ex.Message
                });
            }
        }

        #endregion

        #region Detalle Estudiante
        [HttpGet]
        public IActionResult Detalle(int id)
        {
            try
            {
                using (var context = CrearClienteConToken())
                {
                    var url = Api($"Estudiante/ConsultarEstudiante?idUsuario={id}");
                    var resp = context.GetAsync(url).Result;
                    var content = resp.Content.ReadAsStringAsync().Result;

                    if (resp.IsSuccessStatusCode)
                    {
                        var estudiante = JsonSerializer.Deserialize<EstudianteDetalleModel>(
                            content,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                        );

                        if (estudiante == null)
                            return Content("<div class='alert alert-warning'>No se encontró información del estudiante</div>");

                        ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
                        return PartialView("_DetalleEstudiante", estudiante);
                    }

                    return Content($@"
                        <div class='alert alert-danger'>
                            <h5>Error al cargar el perfil</h5>
                            <p><strong>Status Code:</strong> {resp.StatusCode}</p>
                            <p><strong>Detalles:</strong></p>
                            <pre>{content}</pre>
                        </div>
                    ");
                }
            }
            catch (Exception ex)
            {
                var errorMessage = $@"
                    <div class='alert alert-danger'>
                        <h5>Error en el Controlador Web</h5>
                        <p><strong>Mensaje:</strong> {ex.Message}</p>
                        <p><strong>Inner Exception:</strong> {ex.InnerException?.Message}</p>
                        <p><strong>Stack Trace:</strong></p>
                        <pre>{ex.StackTrace}</pre>
                    </div>
                ";
                return Content(errorMessage);
            }
        }
        #endregion

        #region 

        #region ✅ Visualizar / Descargar Documento (WEB proxy a API) - DEBUG

        [HttpGet]
        public IActionResult VisualizarDocumento(int id)
        {
            try
            {
                using (var context = CrearClienteConToken())
                {
                    // IMPORTANTE: probamos dos rutas comunes
                    var url1 = Api($"Estudiante/VisualizarDocumento/{id}");
                    var resp = context.GetAsync(url1).Result;

                    if (!resp.IsSuccessStatusCode)
                    {
                        var url2 = Api($"Estudiante/VisualizarDocumento?id={id}");
                        resp = context.GetAsync(url2).Result;

                        if (!resp.IsSuccessStatusCode)
                        {
                            var bodyFail = resp.Content.ReadAsStringAsync().Result;
                            return Content(
                                $"[WEB] API falló\n" +
                                $"URL probada 1: {url1}\n" +
                                $"URL probada 2: {url2}\n" +
                                $"Status: {(int)resp.StatusCode} {resp.StatusCode}\n" +
                                $"Body:\n{bodyFail}",
                                "text/plain"
                            );
                        }
                    }

                    var bytes = resp.Content.ReadAsByteArrayAsync().Result;
                    var contentType = resp.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";

                    var cd = resp.Content.Headers.ContentDisposition;
                    var fileName = (cd?.FileNameStar ?? cd?.FileName ?? $"documento_{id}").Trim('"');

                    Response.Headers["Content-Disposition"] = $"inline; filename=\"{fileName}\"";
                    return File(bytes, contentType);
                }
            }
            catch (Exception ex)
            {
                return Content(
                    $"[WEB] EXCEPTION\n{ex.Message}\n{ex.InnerException?.Message}\n{ex.StackTrace}",
                    "text/plain"
                );
            }
        }

        [HttpGet]
        public IActionResult DescargarDocumento(int id)
        {
            try
            {
                using (var context = CrearClienteConToken())
                {
                    var url1 = Api($"Estudiante/DescargarDocumento/{id}");
                    var resp = context.GetAsync(url1).Result;

                    if (!resp.IsSuccessStatusCode)
                    {
                        var url2 = Api($"Estudiante/DescargarDocumento?id={id}");
                        resp = context.GetAsync(url2).Result;

                        if (!resp.IsSuccessStatusCode)
                        {
                            var bodyFail = resp.Content.ReadAsStringAsync().Result;
                            return Content(
                                $"[WEB] API falló\n" +
                                $"URL probada 1: {url1}\n" +
                                $"URL probada 2: {url2}\n" +
                                $"Status: {(int)resp.StatusCode} {resp.StatusCode}\n" +
                                $"Body:\n{bodyFail}",
                                "text/plain"
                            );
                        }
                    }

                    var bytes = resp.Content.ReadAsByteArrayAsync().Result;
                    var contentType = resp.Content.Headers.ContentType?.ToString() ?? "application/octet-stream";

                    var cd = resp.Content.Headers.ContentDisposition;
                    var fileName = (cd?.FileNameStar ?? cd?.FileName ?? $"documento_{id}").Trim('"');

                    return File(bytes, contentType, fileName);
                }
            }
            catch (Exception ex)
            {
                return Content(
                    $"[WEB] EXCEPTION\n{ex.Message}\n{ex.InnerException?.Message}\n{ex.StackTrace}",
                    "text/plain"
                );
            }
        }

        #endregion


        #endregion

        #region Actualizar Estado Académico
        [HttpPost]
        public IActionResult ActualizarEstadoAcademico(int idUsuario, int nuevoEstadoId)
        {
            using (var context = CrearClienteConToken())
            {
                var url = Api("Estudiante/ActualizarEstadoAcademico");
                var modelo = new { IdUsuario = idUsuario, NuevoEstadoId = nuevoEstadoId };

                var respuesta = context.PostAsJsonAsync(url, modelo).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var datosApi = respuesta.Content.ReadFromJsonAsync<dynamic>().Result;
                    return Json(datosApi);
                }

                return Json(new { success = false, message = "Error al actualizar el estado académico" });
            }
        }
        #endregion

        #region Eliminar Documento
        [HttpPost]
        public IActionResult EliminarDocumento(int id)
        {
            using (var context = CrearClienteConToken())
            {
                var url = Api("Estudiante/EliminarDocumento");
                var modelo = new { IdDocumento = id };

                var respuesta = context.PostAsJsonAsync(url, modelo).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var datosApi = respuesta.Content.ReadFromJsonAsync<dynamic>().Result;
                    return Json(datosApi);
                }

                return Json(new { success = false, message = "Error al eliminar el documento" });
            }
        }
        #endregion
    }
}
