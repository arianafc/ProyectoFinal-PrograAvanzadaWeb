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
                using (var context = _http.CreateClient())
                {
                    context.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

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

                        // Mostrar el error al usuario
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
                using (var context = _http.CreateClient())
                {
                    context.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                    var url = Api($"Estudiante/ListarEstudiantes?estado={estado}&idEspecialidad={idEspecialidad}");
                    System.Diagnostics.Debug.WriteLine($"[WEB] URL: {url}");

                    var resp = context.GetAsync(url).Result;
                    var content = resp.Content.ReadAsStringAsync().Result;

                    System.Diagnostics.Debug.WriteLine($"[WEB] Status: {resp.StatusCode}");
                    System.Diagnostics.Debug.WriteLine($"[WEB] Content: {content}");

                    if (resp.IsSuccessStatusCode)
                    {
                        var lista = JsonSerializer.Deserialize<List<EstudianteListItemModel>>(
                            content,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                        );

                        if (lista == null)
                            return Json(new { data = new List<object>() });

                        return Json(new { data = lista });
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"[WEB ERROR] {content}");
                        return Json(new { data = new List<object>(), error = content });
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[WEB ERROR] {ex.Message}");
                System.Diagnostics.Debug.WriteLine($"[WEB ERROR] Inner: {ex.InnerException?.Message}");
                return Json(new { data = new List<object>(), error = ex.Message });
            }
        }
        #endregion

        #region Detalle Estudiante
        [HttpGet]
        public IActionResult Detalle(int id)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    context.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                    var url = Api($"Estudiante/ConsultarEstudiante?idUsuario={id}");

                    // Log de la URL
                    System.Diagnostics.Debug.WriteLine($"URL de la API: {url}");

                    var resp = context.GetAsync(url).Result;

                    // Leer el contenido siempre (éxito o error)
                    var content = resp.Content.ReadAsStringAsync().Result;
                    System.Diagnostics.Debug.WriteLine($"Status Code: {resp.StatusCode}");
                    System.Diagnostics.Debug.WriteLine($"Response Content: {content}");

                    if (resp.IsSuccessStatusCode)
                    {
                        var estudiante = JsonSerializer.Deserialize<EstudianteDetalleModel>(
                            content,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
                        );

                        if (estudiante == null)
                        {
                            return Content("<div class='alert alert-warning'>No se encontró información del estudiante</div>");
                        }

                        ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
                        return PartialView("_DetalleEstudiante", estudiante);
                    }
                    else
                    {
                        // Retornar el error completo
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

        #region Actualizar Estado Académico
        [HttpPost]
        public IActionResult ActualizarEstadoAcademico(int idUsuario, int nuevoEstadoId)
        {
            using (var context = _http.CreateClient())
            {
                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

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
            using (var context = _http.CreateClient())
            {
                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

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