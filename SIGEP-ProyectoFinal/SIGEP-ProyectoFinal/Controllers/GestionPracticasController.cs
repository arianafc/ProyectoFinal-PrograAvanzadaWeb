using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using System.Reflection;
using System.Text.Json;
using static System.Net.WebRequestMethods;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]

    public class GestionPracticasController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public GestionPracticasController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        private string Api(string ruta)
        {
            return _configuration["Valores:UrlAPI"] + ruta;
        }

        [FiltroUsuarioAdmin]
        [HttpGet]
        public IActionResult GestionPracticas()
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


            try
            {
                var postulaciones = client.GetAsync(Api("GestionPracticas/ObtenerPostulaciones")).Result;

                if (postulaciones.IsSuccessStatusCode)
                {
                    vm.Postulaciones =
                      postulaciones.Content
                          .ReadFromJsonAsync<List<PostulacionDto>>()
                          .Result;
                }
                else
                {
                    vm.Postulaciones = new List<PostulacionDto>();
                }

                var resEsp = client.GetAsync(Api("Home/ObtenerEspecialidades")).Result;
                var especialidades = resEsp.Content.ReadFromJsonAsync<List<Especialidades>>().Result;
                vm.Especialidades = especialidades?.Select(x => new SelectListItem
                {
                    Value = x.IdEspecialidad.ToString(),
                    Text = x.Nombre
                }).ToList() ?? new List<SelectListItem>();
            }
            catch { vm.Especialidades = new List<SelectListItem>(); }

            return View("GestionPracticas", vm);
        }


        [HttpPost]
        public JsonResult AccionarPracticas(int accion)
        {
            var client = _http.CreateClient();
            var token = HttpContext.Session.GetString("Token");

            if (!string.IsNullOrEmpty(token))
            {
                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", token);
            }

            HttpResponseMessage response;

            if (accion == 1) // Iniciar
            {
                response = client.PostAsync(Api("GestionPracticas/IniciarPractica"), null).Result;

                return Json(new
                {
                    success = response.IsSuccessStatusCode,
                    message = response.IsSuccessStatusCode
                        ? "Prácticas iniciadas correctamente."
                        : "Error al iniciar las prácticas."
                });
            }
            else if (accion == 2) // Finalizar
            {
                response = client.PostAsync(Api("GestionPracticas/FinalizarPractica"), null).Result;

                return Json(new
                {
                    success = response.IsSuccessStatusCode,
                    message = response.IsSuccessStatusCode
                        ? "Prácticas finalizadas correctamente."
                        : "Error al finalizar las prácticas."
                });
            }

            return Json(new { success = false, message = "Acción no válida." });
        }

        [HttpGet]
        public JsonResult ObtenerVacantesAsignar(int IdUsuario)
        {
            try
            {
                var client = _http.CreateClient();
                var token = HttpContext.Session.GetString("Token");

                if (!string.IsNullOrEmpty(token))
                {
                    client.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", token);
                }

                var response = client.GetAsync(
                    Api("GestionPracticas/ObtenerVacantesAsignar?IdUsuario=" + IdUsuario)
                ).Result;

                if (response.IsSuccessStatusCode)
                {
                    var vacantes = response.Content
                        .ReadFromJsonAsync<List<VacanteModel>>()
                        .Result;

                    return Json(vacantes ?? new List<VacanteModel>());
                }

                return Json(new List<VacanteModel>());
            }
            catch
            {
                return Json(new List<VacanteModel>());
            }
        }

   

        [FiltroEstudiante]
        [HttpGet]
        public IActionResult PostulacionesEstudiantes()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            var vm = new VacantesViewModel();

            try
            {
                var client = _http.CreateClient();
                var token = HttpContext.Session.GetString("Token");

                if (string.IsNullOrEmpty(token))
                {
                    TempData["SwalError"] = "Sesión expirada. Inicie sesión nuevamente.";
                    return RedirectToAction("Login", "Cuenta");
                }

                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", token);

                var response = client
                    .GetAsync(Api("GestionPracticas/ListarVacantesPorUsuario"))
                    .Result;

                if (response.IsSuccessStatusCode)
                {
                    vm.Postulaciones = response.Content
                        .ReadFromJsonAsync<List<PostulacionDto>>()
                        .Result ?? new List<PostulacionDto>();

                    return View(vm);
                }

   
            }
            catch (HttpRequestException)
            {
                TempData["SwalError"] = "No se pudo conectar con el servidor.";
            }
            catch (Exception ex)
            {
              
                TempData["SwalError"] = "Ocurrió un error inesperado.";
            }

            return View(vm);
        }

    }

}
