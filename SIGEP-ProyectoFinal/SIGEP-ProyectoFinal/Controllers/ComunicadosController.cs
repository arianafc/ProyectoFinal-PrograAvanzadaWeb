using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using System.Reflection;
using static System.Net.WebRequestMethods;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]
    public class ComunicadosController : Controller
    {

        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public ComunicadosController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }



        [HttpGet]
        public IActionResult Comunicados()
        {
            var model = new Comunicado();

            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            using (var client = _http.CreateClient())
            {
                client.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var urlBase = _configuration["Valores:UrlApi"];

                var urlAdministrativos = urlBase + "Comunicados/ObtenerComunicados?Poblacion=Administrativos";
                var urlEstudiantes = urlBase + "Comunicados/ObtenerComunicados?Poblacion=Estudiantes";

                var respuestaAdmin = client.GetAsync(urlAdministrativos).Result;
                var respuestaEst = client.GetAsync(urlEstudiantes).Result;

                if (respuestaAdmin.IsSuccessStatusCode)
                {
                    model.AllComunicados =
                        respuestaAdmin.Content
                            .ReadFromJsonAsync<List<Comunicado>>()
                            .Result;
                }

                if (respuestaEst.IsSuccessStatusCode)
                {
                    model.ComunicadosEstudiantes =
                        respuestaEst.Content
                            .ReadFromJsonAsync<List<Comunicado>>()
                            .Result;
                }
            }

            return View(model);
        }

        [HttpPost]

        public IActionResult AgregarComunicado(string Nombre,
                    string Informacion,
                    string Poblacion,
                    DateTime? FechaLimite,
                    List<IFormFile> archivos)
        {

            int idUsuario = HttpContext.Session.GetInt32("IdUsuario") ?? 0;

            var comunicado = new Comunicado
            {
                Nombre = Nombre,
                Informacion = Informacion,
                Poblacion = Poblacion,
                FechaLimite = FechaLimite,
                IdUsuario = idUsuario,
                Documentos = new List<DocumentoVM>()
            };


            if (archivos != null && archivos.Count > 0)
            {
                string carpetaBase = @"C:\SIGEP\Comunicados\";

                if (!Directory.Exists(carpetaBase))
                    Directory.CreateDirectory(carpetaBase);

                foreach (var file in archivos)
                {
                    string extension = Path.GetExtension(file.FileName);


                    string nombreOriginal = Path.GetFileNameWithoutExtension(file.FileName)
                                                .Replace(" ", "_");

                    string nombreArchivo = $"{idUsuario}_{nombreOriginal}{extension}";
                    string rutaCompleta = Path.Combine(carpetaBase, nombreArchivo);

                    using (var stream = new FileStream(rutaCompleta, FileMode.Create))
                    {
                        file.CopyTo(stream);
                    }

                    comunicado.Documentos.Add(new DocumentoVM
                    {
                        Documento = nombreArchivo,
                        Tipo = extension
                    });
                }
            }


            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlAPI"] + "Comunicados/AgregarComunicado";
                context.DefaultRequestHeaders.Authorization =
                  new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var respuesta = context.PostAsJsonAsync(urlApi, comunicado).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Comunicado agregado correctamente";
                    return RedirectToAction("Comunicados");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al agregar el comunicado. Intente nuevamente."
                        : mensajeError;

                    return RedirectToAction("Comunicados");
                }
            }
        }

        [HttpPost]
        public IActionResult EditarComunicado(
    int IdComunicado,
    string Nombre,
    string Informacion,
    string Poblacion,
    DateTime? FechaLimite,
    List<IFormFile> archivos)
        {
            int idUsuario = HttpContext.Session.GetInt32("IdUsuario") ?? 0;

            var comunicado = new Comunicado
            {
                IdComunicado = IdComunicado,
                Nombre = Nombre,
                Informacion = Informacion,
                Poblacion = Poblacion,
                FechaLimite = FechaLimite,
                IdUsuario = idUsuario,
                Documentos = new List<DocumentoVM>()
            };

           
            if (archivos != null && archivos.Count > 0)
            {
                string carpetaBase = @"C:\SIGEP\Comunicados\";

                if (!Directory.Exists(carpetaBase))
                    Directory.CreateDirectory(carpetaBase);

                foreach (var file in archivos)
                {
                    string extension = Path.GetExtension(file.FileName);

                    string nombreOriginal = Path.GetFileNameWithoutExtension(file.FileName)
                                                .Replace(" ", "_");

                   
                    string nombreArchivo = $"{IdComunicado}_{nombreOriginal}{extension}";
                    string rutaCompleta = Path.Combine(carpetaBase, nombreArchivo);

                    using (var stream = new FileStream(rutaCompleta, FileMode.Create))
                    {
                        file.CopyTo(stream);
                    }

                    comunicado.Documentos.Add(new DocumentoVM
                    {
                        Documento = nombreArchivo,
                        Tipo = extension
                    });
                }
            }

            
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlAPI"] + "Comunicados/EditarComunicado";

                context.DefaultRequestHeaders.Authorization =
                    new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                var respuesta = context.PutAsJsonAsync(urlApi, comunicado).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Comunicado actualizado correctamente";
                    return RedirectToAction("Comunicados");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al actualizar el comunicado. Intente nuevamente."
                        : mensajeError;

                    return RedirectToAction("Comunicados");
                }
            }
        }



        [HttpGet]
        public JsonResult ObtenerDetallesComunicado(int IdComunicado)
        {
            var comunicado = new Comunicado
            {
                Documentos = new List<DocumentoVM>()
            };

            using (var client = _http.CreateClient())
            {
                var token = HttpContext.Session.GetString("Token");

                if (!string.IsNullOrEmpty(token))
                {
                    client.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", token);
                }

                var urlBase = _configuration["Valores:UrlApi"];

                var urlComunicado = $"{urlBase}Comunicados/ObtenerComunicado?IdComunicado={IdComunicado}";
                var urlDocumentos = $"{urlBase}Comunicados/ObtenerDocumentosComunicado?IdComunicado={IdComunicado}";

                // ======================
                // COMUNICADO
                // ======================
                var respuesta = client.GetAsync(urlComunicado).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var resultado = respuesta
                        .Content
                        .ReadFromJsonAsync<Comunicado>()
                        .Result;

                    if (resultado != null)
                    {
                        comunicado.IdComunicado = IdComunicado;
                        comunicado.Nombre = resultado.Nombre;
                        comunicado.Poblacion = resultado.Poblacion;
                        comunicado.PublicadoPor = resultado.PublicadoPor;
                        comunicado.Fecha = resultado.Fecha;
                        comunicado.FechaLimite = resultado.FechaLimite;
                        comunicado.Informacion = resultado.Informacion;
                        comunicado.IdEstado = resultado.IdEstado;   
                    }
                }

                // ======================
                // DOCUMENTOS
                // ======================
                
                  var respuestaDocs = client.GetAsync(urlDocumentos).Result;

                if (respuestaDocs.IsSuccessStatusCode)
                {
                    var docs = respuestaDocs
                        .Content
                        .ReadFromJsonAsync<List<DocumentoVM>>()
                        .Result;

                    if (docs != null)
                    {
                        comunicado.Documentos = docs;
                    }
                }

                return Json(comunicado);
            }
        }

        [HttpGet]
        public IActionResult DescargarDocumento(string nombreArchivo)
        {
            if (string.IsNullOrEmpty(nombreArchivo))
            {
                TempData["SwalError"] = "Documento inválido.";
                return RedirectToAction("Comunicados", "Comunicados");
            }

            string carpetaBase = @"C:\SIGEP\Comunicados\";
            string rutaCompleta = Path.Combine(carpetaBase, nombreArchivo);

            if (!System.IO.File.Exists(rutaCompleta))
            {
                TempData["SwalError"] = "El archivo no existe en el servidor.";
                return RedirectToAction("Comunicados", "Comunicados");
            }

            var mimeType = "application/octet-stream";
            var fileBytes = System.IO.File.ReadAllBytes(rutaCompleta);

            return File(fileBytes, mimeType, nombreArchivo);
        }


        [HttpGet]
        public IActionResult VisualizarDocumento(string nombreArchivo)
        {
            if (string.IsNullOrEmpty(nombreArchivo))
                return BadRequest();

            if (nombreArchivo.Contains(".."))
                return BadRequest();

            string carpetaBase = @"C:\SIGEP\Comunicados\";
            string rutaCompleta = Path.Combine(carpetaBase, nombreArchivo);

            if (!System.IO.File.Exists(rutaCompleta))
                return NotFound();

            var extension = Path.GetExtension(nombreArchivo).ToLower();

            string mimeType = extension switch
            {
                ".pdf" => "application/pdf",
                ".xls" => "application/vnd.ms-excel",
                ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                _ => "application/octet-stream"
            };

            var stream = new FileStream(rutaCompleta, FileMode.Open, FileAccess.Read);

            Response.Headers.Add("Content-Disposition", "inline; filename=" + nombreArchivo);

            return File(stream, mimeType);
        }


        [HttpPost]
        public JsonResult ActivarComunicado(int IdComunicado)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlApi"] +
                                 $"Comunicados/ActivarComunicado?IdComunicado={IdComunicado}";

                    context.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                    var respuesta = context.PutAsync(urlApi, null).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        return Json(new
                        {
                            success = true,
                            message = "Comunicado activado correctamente"
                        });
                    }

                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    return Json(new
                    {
                        success = false,
                        message = string.IsNullOrEmpty(mensajeError)
                            ? "Error al activar el comunicado."
                            : mensajeError
                    });
                }
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    success = false,
                    message = ex.Message
                });
            }
        }



        [HttpPost]
        public JsonResult DesactivarComunicado(int IdComunicado)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlApi"] +
                                 $"Comunicados/DesactivarComunicado?IdComunicado={IdComunicado}";

                    context.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                    var respuesta = context.PutAsync(urlApi, null).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        return Json(new
                        {
                            success = true,
                            message = "Comunicado desactivado correctamente"
                        });
                    }

                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    return Json(new
                    {
                        success = false,
                        message = string.IsNullOrEmpty(mensajeError)
                            ? "Error al desactivar el comunicado."
                            : mensajeError
                    });
                }
            }
            catch (Exception ex)
            {
                return Json(new
                {
                    success = false,
                    message = ex.Message
                });
            }
        }


        [HttpPost]
        public IActionResult EliminarDocumento(int idDocumento)
        {
            try
            {
                using (var client = _http.CreateClient())
                {
                    client.DefaultRequestHeaders.Authorization =
                        new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));

                  
                    var urlObtener = _configuration["Valores:UrlApi"] +
                                     $"Comunicados/ObtenerDocumentoPorId?IdDocumento={idDocumento}";

                    var respuestaDoc = client.GetAsync(urlObtener).Result;

                    if (!respuestaDoc.IsSuccessStatusCode)
                        return Json(new { exito = false, mensaje = "No se encontró el documento." });

                    var doc = respuestaDoc.Content.ReadFromJsonAsync<DocumentoVM>().Result;

                  
                    string carpetaBase = @"C:\SIGEP\Comunicados\";
                    string rutaCompleta = Path.Combine(carpetaBase, doc.Documento);

              
                    if (System.IO.File.Exists(rutaCompleta))
                    {
                        System.IO.File.Delete(rutaCompleta);
                    }


                    var urlEliminar = _configuration["Valores:UrlApi"] +
                                      $"Perfil/EliminarDocumento?IdDocumento={idDocumento}";

                    var respuestaEliminar = client.DeleteAsync(urlEliminar).Result;

                    if (respuestaEliminar.IsSuccessStatusCode)
                    {
                        return Json(new { exito = true, mensaje = "Documento eliminado correctamente." });
                    }

                    return Json(new { exito = false, mensaje = "No se pudo eliminar el documento." });
                }
            }
            catch (Exception ex)
            {
                return Json(new { exito = false, mensaje = "Error al eliminar el documento." });
            }
        }













    }
}
