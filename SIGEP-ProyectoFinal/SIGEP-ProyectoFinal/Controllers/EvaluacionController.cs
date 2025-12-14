using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;

namespace SIGEP_ProyectoFinal.Controllers
{
    public class EvaluacionController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public EvaluacionController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }

        #region Vista Principal

        [HttpGet]
        public IActionResult ListarEstudianteConPractica()
        {
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            if (ViewBag.Usuario == null)
            {
                return RedirectToAction("IniciarSesion", "Home");
            }

            return View();
        }

        #endregion

        #region Obtener Estudiantes

        [HttpGet]
        public IActionResult ObtenerEstudiantes()
        {
            try
            {
                var idCoordinador = HttpContext.Session.GetInt32("IdUsuario");
                if (idCoordinador == null)
                {
                    return Json(new { success = false, message = "Sesión expirada" });
                }

                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "Evaluacion/ObtenerEstudiantes";
                    var request = new { IdCoordinador = idCoordinador.Value };

                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var datosApi = respuesta.Content.ReadFromJsonAsync<List<Evaluacion>>().Result;
                        return Json(datosApi);
                    }

                    return Json(new List<Evaluacion>());
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Error: " + ex.Message });
            }
        }

        #endregion

        #region Obtener Perfil Estudiante

        [HttpGet]
        public IActionResult ObtenerPerfilEstudiante(int idUsuario)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + $"Evaluacion/ObtenerPerfilEstudiante?idUsuario={idUsuario}";
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var perfil = respuesta.Content.ReadFromJsonAsync<PerfilEstudianteModel>().Result;

                        if (perfil != null)
                        {
                            var urlComentarios = _configuration["Valores:UrlAPI"] + $"Evaluacion/ObtenerComentarios?idUsuario={idUsuario}";
                            var respuestaComentarios = context.GetAsync(urlComentarios).Result;

                            if (respuestaComentarios.IsSuccessStatusCode)
                            {
                                var comentarios = respuestaComentarios.Content.ReadFromJsonAsync<List<ComentarioModel>>().Result;
                                perfil.Comentarios = comentarios ?? new List<ComentarioModel>();
                            }

                            return Json(new { success = true, perfil = perfil });
                        }

                        return Json(new { success = false, message = "Estudiante no encontrado" });
                    }

                    return Json(new { success = false, message = "Error al obtener perfil" });
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Error: " + ex.Message });
            }
        }

        #endregion

        #region Obtener Comentarios

        [HttpGet]
        public IActionResult ObtenerComentarios(int idUsuario)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + $"Evaluacion/ObtenerComentarios?idUsuario={idUsuario}";
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var comentarios = respuesta.Content.ReadFromJsonAsync<List<ComentarioModel>>().Result;
                        return Json(comentarios);
                    }

                    return Json(new List<ComentarioModel>());
                }
            }
            catch
            {
                return Json(new List<ComentarioModel>());
            }
        }

        #endregion

        #region Obtener Notas

        [HttpGet]
        public IActionResult ObtenerNotas(int idUsuario)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + $"Evaluacion/ObtenerNotas?idUsuario={idUsuario}";
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var notas = respuesta.Content.ReadFromJsonAsync<NotasModel>().Result;
                        return Json(notas);
                    }

                    return Json(new NotasModel { Nota1 = 0, Nota2 = 0, NotaFinal = 0 });
                }
            }
            catch
            {
                return Json(new NotasModel { Nota1 = 0, Nota2 = 0, NotaFinal = 0 });
            }
        }

        #endregion

        #region Guardar Nota

        [HttpPost]
        public IActionResult GuardarNota(GuardarNotaModel model)
        {
            try
            {
                var idCoordinador = HttpContext.Session.GetInt32("IdUsuario");
                if (idCoordinador == null)
                {
                    return Json(new { success = false, message = "Sesión expirada" });
                }

                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "Evaluacion/GuardarNota";
                    var request = new
                    {
                        IdUsuario = model.IdUsuario,
                        Nota1 = model.Nota1,
                        Nota2 = model.Nota2,
                        NotaFinal = model.NotaFinal,
                        IdCoordinador = idCoordinador.Value
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

        #endregion

        #region Guardar Comentario

        [HttpPost]
        public IActionResult GuardarComentario(GuardarComentarioModel model)
        {
            try
            {
                var idCoordinador = HttpContext.Session.GetInt32("IdUsuario");
                if (idCoordinador == null)
                {
                    return Json(new { success = false, message = "Sesión expirada" });
                }

                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "Evaluacion/GuardarComentario";
                    var request = new
                    {
                        IdUsuario = model.IdUsuario,
                        IdCoordinador = idCoordinador.Value,
                        Comentario = model.Comentario
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

        #endregion

        #region Subir Documento

        [HttpPost]
        public IActionResult SubirDocumento(IFormFile archivo, int idUsuario)
        {
            try
            {
                var idCoordinador = HttpContext.Session.GetInt32("IdUsuario");
                if (idCoordinador == null)
                {
                    return Json(new { success = false, message = "Sesión expirada" });
                }

                if (archivo == null || archivo.Length == 0)
                {
                    return Json(new { success = false, message = "No se seleccionó ningún archivo" });
                }

                var extensionesPermitidas = new[] { ".xls", ".xlsx", ".pdf" };
                var extension = Path.GetExtension(archivo.FileName).ToLower();

                if (!extensionesPermitidas.Contains(extension))
                {
                    return Json(new { success = false, message = "Solo se permiten archivos .xls, .xlsx o .pdf" });
                }

                string cedulaEstudiante = ObtenerCedula(idUsuario);
                if (string.IsNullOrEmpty(cedulaEstudiante))
                {
                    return Json(new { success = false, message = "No se pudo obtener la cédula del estudiante" });
                }

                string directorioBase = @"C:\sigepweb\Evaluaciones";
                if (!Directory.Exists(directorioBase))
                {
                    Directory.CreateDirectory(directorioBase);
                }

                string nombreOriginal = Path.GetFileNameWithoutExtension(archivo.FileName);
                string nombreArchivo = $"{cedulaEstudiante}_{nombreOriginal}{extension}";
                string rutaCompleta = Path.Combine(directorioBase, nombreArchivo);

                using (var stream = new FileStream(rutaCompleta, FileMode.Create))
                {
                    archivo.CopyTo(stream);
                }

                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + "Evaluacion/GuardarDocumento";
                    var request = new
                    {
                        IdUsuario = idUsuario,
                        NombreArchivo = archivo.FileName,
                        Tipo = "Evaluación"
                    };

                    var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var resultado = respuesta.Content.ReadAsStringAsync().Result;
                        return Content(resultado, "application/json");
                    }

                    if (System.IO.File.Exists(rutaCompleta))
                    {
                        System.IO.File.Delete(rutaCompleta);
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

        #endregion

        #region Obtener Documentos

        [HttpGet]
        public IActionResult ObtenerDocumentosEvaluacion(int idUsuario)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + $"Evaluacion/ObtenerDocumentosEvaluacion?idUsuario={idUsuario}";
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var documentos = respuesta.Content.ReadFromJsonAsync<List<DocumentoEvaluacionModel>>().Result;
                        return Json(new { success = true, documentos = documentos });
                    }

                    return Json(new { success = false, documentos = new List<DocumentoEvaluacionModel>() });
                }
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = "Error: " + ex.Message });
            }
        }

        #endregion

        #region Descargar Documento

        [HttpGet]
        public IActionResult DescargarDocumento(int idDocumento)
        {
            try
            {
                var infoDocumento = ObtenerInfoDocumento(idDocumento);
                if (infoDocumento == null)
                    return NotFound("Documento no encontrado");

                string cedulaEstudiante = ObtenerCedula(infoDocumento.IdUsuario);
                if (string.IsNullOrEmpty(cedulaEstudiante))
                    return NotFound("Estudiante no encontrado");

                string nombreArchivo = infoDocumento.Documento;
                string extension = Path.GetExtension(nombreArchivo);
                string nombreOriginal = Path.GetFileNameWithoutExtension(nombreArchivo);
                string nombreArchivoFisico = $"{cedulaEstudiante}_{nombreOriginal}{extension}";

                string directorioBase = @"C:\sigepweb\Evaluaciones";
                string rutaCompleta = Path.Combine(directorioBase, nombreArchivoFisico);

                if (!System.IO.File.Exists(rutaCompleta))
                    return NotFound("Archivo no encontrado en el servidor");

                var fileBytes = System.IO.File.ReadAllBytes(rutaCompleta);

                string contentType = extension.ToLower() switch
                {
                    ".pdf" => "application/pdf",
                    ".xlsx" => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    ".xls" => "application/vnd.ms-excel",
                    _ => "application/octet-stream"
                };

                return File(fileBytes, contentType, nombreArchivo);
            }
            catch (Exception ex)
            {
                return Content("Error al descargar: " + ex.Message);
            }
        }

        #endregion

        #region Visualizar Documento

        [HttpGet]
        public IActionResult VisualizarDocumento(int idDocumento)
        {
            try
            {
                var infoDocumento = ObtenerInfoDocumento(idDocumento);
                if (infoDocumento == null)
                    return NotFound("Documento no encontrado");

                string cedulaEstudiante = ObtenerCedula(infoDocumento.IdUsuario);
                if (string.IsNullOrEmpty(cedulaEstudiante))
                    return NotFound("Estudiante no encontrado");

                string nombreArchivo = infoDocumento.Documento;
                string extension = Path.GetExtension(nombreArchivo);
                string nombreOriginal = Path.GetFileNameWithoutExtension(nombreArchivo);
                string nombreArchivoFisico = $"{cedulaEstudiante}_{nombreOriginal}{extension}";

                string directorioBase = @"C:\sigepweb\Evaluaciones";
                string rutaCompleta = Path.Combine(directorioBase, nombreArchivoFisico);

                if (!System.IO.File.Exists(rutaCompleta))
                    return NotFound("Archivo no encontrado");

                var fileBytes = System.IO.File.ReadAllBytes(rutaCompleta);

                if (extension.ToLower() == ".pdf")
                {
                    return File(fileBytes, "application/pdf");
                }
                else
                {
                    return DescargarDocumento(idDocumento);
                }
            }
            catch (Exception ex)
            {
                return Content("Error: " + ex.Message);
            }
        }

        #endregion

        #region Eliminar Documento

        [HttpPost]
        public IActionResult EliminarDocumento(int idDocumento)
        {
            try
            {
                var idCoordinador = HttpContext.Session.GetInt32("IdUsuario");
                if (idCoordinador == null)
                {
                    return Json(new { success = false, message = "Sesión expirada" });
                }

                var infoDocumento = ObtenerInfoDocumento(idDocumento);
                if (infoDocumento != null)
                {
                    string cedulaEstudiante = ObtenerCedula(infoDocumento.IdUsuario);
                    if (!string.IsNullOrEmpty(cedulaEstudiante))
                    {
                        string nombreArchivo = infoDocumento.Documento;
                        string extension = Path.GetExtension(nombreArchivo);
                        string nombreOriginal = Path.GetFileNameWithoutExtension(nombreArchivo);
                        string nombreArchivoFisico = $"{cedulaEstudiante}_{nombreOriginal}{extension}";

                        string directorioBase = @"C:\sigepweb\Evaluaciones";
                        string rutaCompleta = Path.Combine(directorioBase, nombreArchivoFisico);

                        if (System.IO.File.Exists(rutaCompleta))
                        {
                            System.IO.File.Delete(rutaCompleta);
                        }
                    }
                }

                using (var context = _http.CreateClient())
                {
                    var urlEliminar = _configuration["Valores:UrlAPI"] + $"Evaluacion/EliminarDocumento?idDocumento={idDocumento}";
                    var request = new HttpRequestMessage(HttpMethod.Delete, urlEliminar);
                    var respuesta = context.SendAsync(request).Result;

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

        #endregion

        private string ObtenerCedula(int idUsuario)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + $"Evaluacion/ObtenerCedulaUsuario?idUsuario={idUsuario}";
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var resultado = respuesta.Content.ReadFromJsonAsync<CedulaModel>().Result;
                        return resultado?.Cedula ?? string.Empty;
                    }

                    return string.Empty;
                }
            }
            catch
            {
                return string.Empty;
            }
        }

        private DocumentoVM? ObtenerInfoDocumento(int idDocumento)
        {
            try
            {
                using (var context = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlAPI"] + $"Evaluacion/ObtenerDocumentoPorId?idDocumento={idDocumento}";
                    var respuesta = context.GetAsync(urlApi).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        var documento = respuesta.Content.ReadFromJsonAsync<DocumentoVM>().Result;
                        return documento;
                    }

                    return null;
                }
            }
            catch
            {
                return null;
            }
        }
    }
}