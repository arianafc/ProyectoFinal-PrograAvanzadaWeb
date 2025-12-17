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
    [FiltroUsuarioAdmin]
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



    }
}
