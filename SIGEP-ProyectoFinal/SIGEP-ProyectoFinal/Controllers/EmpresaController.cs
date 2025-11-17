using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using System.Text;
using System.Text.Json;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class EmpresaController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public EmpresaController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        private string Api(string ruta) =>
            _configuration["Valores:UrlAPI"] + ruta;

        // ======================================================
        // VISTA PRINCIPAL
        // ======================================================
        [HttpGet]
        public IActionResult ListarEmpresas()
        {
            return View();
        }

        // ======================================================
        // LISTADO PARA DATATABLE
        // ======================================================
        [HttpGet]
        public IActionResult GetEmpresas()
        {
            var client = _http.CreateClient();
            var url = Api("Empresa/ListarEmpresas");

            var resp = client.GetStringAsync(url).Result;

            var lista = JsonSerializer.Deserialize<List<EmpresaListItemModel>>(
                resp,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
            );

            if (lista == null)
                return Json(new { data = new List<object>() });

            
            var data = lista.Select(e => new {
                IdEmpresa = e.IdEmpresa,
                NombreEmpresa = e.NombreEmpresa,   
                AreasAfinidad = e.AreasAfinidad,
                Ubicacion = e.Ubicacion,
                HistorialVacantes = e.HistorialVacantes
            });

            return Json(new { data });
        }




        // ======================================================
        // OBTENER EMPRESA POR ID
        // ======================================================
        [HttpGet]
        public IActionResult GetEmpresa(int id)
        {
            var context = _http.CreateClient();
            var url = Api("Empresa/ConsultarEmpresas?IdEmpresa=" + id);

            var resp = context.GetAsync(url).Result;

            if (resp.IsSuccessStatusCode)
            {
                var lista = resp.Content.ReadFromJsonAsync<List<EmpresaDetalleModel>>().Result;

                if (lista != null && lista.Count > 0)
                    return Json(new { ok = true, data = lista[0] });
            }

            return Json(new { ok = false, msg = "Empresa no encontrada." });
        }

        // ======================================================
        // CREAR EMPRESA
        // ======================================================
        [HttpPost]
        public IActionResult CrearEmpresa(EmpresaCreateVM vm)
        {
            var context = _http.CreateClient();
            var url = Api("Empresa/AgregarEmpresa");

            var modelo = new
            {
                vm.NombreEmpresa,
                vm.NombreContacto,
                vm.Email,
                vm.Telefono,
                vm.Provincia,
                vm.Canton,
                vm.Distrito,
                vm.DireccionExacta,
                vm.AreasAfinidad
            };

            var resp = context.PostAsJsonAsync(url, modelo).Result;

            if (resp.IsSuccessStatusCode)
                return Json(new { ok = true, msg = "Empresa creada correctamente." });

            return Json(new { ok = false, msg = "No se pudo crear la empresa." });
        }

        // ======================================================
        // EDITAR EMPRESA
        // ======================================================
        [HttpPost]
        public IActionResult EditarEmpresa(EmpresaEditVM vm)
        {
            var context = _http.CreateClient();
            var url = Api("Empresa/ActualizarEmpresa");

            var modelo = new EmpresaGuardarRequestModel
            {
                IdEmpresa = vm.IdEmpresa,
                NombreEmpresa = vm.NombreEmpresa,
                NombreContacto = vm.NombreContacto,
                Email = vm.Email,
                Telefono = vm.Telefono,
                Provincia = vm.Provincia,
                Canton = vm.Canton,
                Distrito = vm.Distrito,
                DireccionExacta = vm.DireccionExacta,
                AreasAfinidad = vm.AreasAfinidad
            };

            var resp = context.PostAsJsonAsync(url, modelo).Result;

            if (resp.IsSuccessStatusCode)
                return Json(new { ok = true, msg = "Cambios guardados correctamente." });

            return Json(new { ok = false, msg = "No se pudo actualizar la empresa." });
        }

        // ======================================================
        // ELIMINAR EMPRESA
        // ======================================================
        [HttpPost]
        public IActionResult EliminarEmpresa(int id)
        {
            var context = _http.CreateClient();
            var url = Api("Empresa/EliminarEmpresa");

            var modelo = new { Id = id };

            var resp = context.PostAsJsonAsync(url, modelo).Result;

            if (resp.IsSuccessStatusCode)
                return Json(new { ok = true, msg = "Empresa eliminada." });

            return Json(new { ok = false, msg = "No se pudo eliminar." });
        }
    }
}


