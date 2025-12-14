using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]
    public class AdministracionGeneralController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public AdministracionGeneralController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        #region Vista Principal

        [HttpGet]
        public IActionResult AdministracionGeneral(string tab = "usuarios")
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");
            ViewBag.Tab = string.IsNullOrWhiteSpace(tab) ? "usuarios" : tab;
            return View();
        }

        #endregion

        #region Usuarios

        [HttpGet]
        public IActionResult ConsultarUsuarios(string? rol = null)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/ConsultarUsuarios";
                    if (!string.IsNullOrWhiteSpace(rol))
                        urlApi += "?rol=" + Uri.EscapeDataString(rol);

                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var datosApi = respuesta.Content.ReadFromJsonAsync<List<UsuarioAdminModel>>().Result;
                        return Json(new { ok = true, data = datosApi });
                    }

                    return Json(new { ok = false, mensaje = "Error al consultar usuarios" });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, mensaje = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult CambiarEstadoUsuario([FromBody] CambiarEstadoUsuarioModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/CambiarEstadoUsuario";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                      
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                           
                            if (resultado > 0)
                            {
                                return Json(new { ok = true, msg = "Estado actualizado correctamente." });
                            }
                            else
                            {
                                return Json(new { ok = false, msg = "No se pudo cambiar el estado." });
                            }
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult CambiarRolUsuario([FromBody] CambiarRolUsuarioModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/CambiarRolUsuario";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                            if (resultado > 0)
                            {
                                return Json(new { ok = true, msg = "Rol actualizado correctamente." });
                            }
                            else
                            {
                                return Json(new { ok = false, msg = "No se pudo actualizar el rol. Verifica que el rol exista en el sistema." });
                            }
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        #endregion

        #region Especialidades

        [HttpGet]
        public IActionResult ConsultarEspecialidades()
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/ConsultarEspecialidades";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var datosApi = respuesta.Content.ReadFromJsonAsync<List<EspecialidadAdminModel>>().Result;
                        return Json(new { ok = true, data = datosApi });
                    }

                    return Json(new { ok = false, mensaje = "Error al consultar especialidades" });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, mensaje = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult CrearEspecialidad([FromBody] CrearEspecialidadAdminModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/CrearEspecialidad";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                            if (resultado > 0)
                                return Json(new { ok = true, msg = "Especialidad creada correctamente." });
                            else if (resultado == -1)
                                return Json(new { ok = false, msg = "Ya existe una especialidad inactiva con ese nombre. Actívala en lugar de crear una nueva." });
                            else
                                return Json(new { ok = false, msg = "Ya existe una especialidad activa con ese nombre." });
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult EditarEspecialidad([FromBody] EditarEspecialidadAdminModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/EditarEspecialidad";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PutAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                            if (resultado > 0)
                                return Json(new { ok = true, msg = "Cambios guardados correctamente." });
                            else if (resultado == -1)
                                return Json(new { ok = false, msg = "Ya existe otra especialidad inactiva con ese nombre." });
                            else
                                return Json(new { ok = false, msg = "Ya existe otra especialidad activa con ese nombre." });
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult CambiarEstadoEspecialidad([FromBody] CambiarEstadoEspecialidadAdminModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/CambiarEstadoEspecialidad";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                            if (resultado > 0)
                                return Json(new { ok = true, msg = $"Especialidad {(request.NuevoEstado == "Activo" ? "activada" : "desactivada")} correctamente." });
                            else if (resultado == -1)
                                return Json(new { ok = false, msg = "No se puede desactivar. Hay usuarios activos con esta especialidad." });
                            else
                                return Json(new { ok = false, msg = "No se pudo cambiar el estado." });
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        #endregion

        #region Secciones

        [HttpGet]
        public IActionResult ConsultarSecciones()
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/ConsultarSecciones";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var datosApi = respuesta.Content.ReadFromJsonAsync<List<SeccionAdminModel>>().Result;
                        return Json(new { ok = true, data = datosApi });
                    }

                    return Json(new { ok = false, mensaje = "Error al consultar secciones" });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, mensaje = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult CrearSeccion([FromBody] CrearSeccionModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/CrearSeccion";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                            if (resultado > 0)
                                return Json(new { ok = true, msg = "Sección creada correctamente." });
                            else if (resultado == -1)
                                return Json(new { ok = false, msg = "Ya existe una sección inactiva con ese nombre. Actívala en lugar de crear una nueva." });
                            else
                                return Json(new { ok = false, msg = "Ya existe una sección activa con ese nombre." });
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult EditarSeccion([FromBody] EditarSeccionModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/EditarSeccion";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PutAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                            if (resultado > 0)
                                return Json(new { ok = true, msg = "Cambios guardados correctamente." });
                            else if (resultado == -1)
                                return Json(new { ok = false, msg = "Ya existe otra sección inactiva con ese nombre." });
                            else
                                return Json(new { ok = false, msg = "Ya existe otra sección activa con ese nombre." });
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        [HttpPost]
        public IActionResult CambiarEstadoSeccion([FromBody] CambiarEstadoSeccionModel request)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "AdministracionGeneral/CambiarEstadoSeccion";
                    context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var contenido = respuesta.Content.ReadAsStringAsync().Result;

                        if (int.TryParse(contenido, out int resultado))
                        {
                            if (resultado > 0)
                                return Json(new { ok = true, msg = $"Sección {(request.NuevoEstado == "Activo" ? "activada" : "desactivada")} correctamente." });
                            else if (resultado == -1)
                                return Json(new { ok = false, msg = "No se puede desactivar. Hay usuarios activos en esta sección." });
                            else
                                return Json(new { ok = false, msg = "No se pudo cambiar el estado." });
                        }

                        return Json(new { ok = false, msg = "Respuesta inesperada del servidor." });
                    }

                    return Json(new { ok = false, msg = "Error al comunicarse con el servidor." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { ok = false, msg = "Error: " + ex.Message });
            }
        }

        #endregion
    }
}