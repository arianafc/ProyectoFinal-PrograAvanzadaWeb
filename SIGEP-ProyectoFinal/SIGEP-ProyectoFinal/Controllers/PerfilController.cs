using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SIGEP_ProyectoFinal.Models;
using System.Net.Http.Headers;
using Utiles;
using static System.Net.WebRequestMethods;

namespace SIGEP_ProyectoFinal.Controllers
{
    [Seguridad]
    public class PerfilController : Controller
    {
        private readonly IHttpClientFactory _http;
        private readonly IConfiguration _configuration;

        public PerfilController(IHttpClientFactory http, IConfiguration configuration)
        {
            _http = http;
            _configuration = configuration;
        }



        [HttpGet]

        public IActionResult Perfil()
        {
            var usuario = new Usuario();
            ViewBag.Nombre = HttpContext.Session.GetString("Nombre");
            ViewBag.Rol = HttpContext.Session.GetInt32("Rol");
            ViewBag.Usuario = HttpContext.Session.GetInt32("IdUsuario");

            using (var context = _http.CreateClient())
            {
                var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ObtenerPerfil?IdUsuario=" + IdUsuario;
                var urlApi2 = _configuration["Valores:UrlApi"] + "Perfil/ObtenerEncargados?IdUsuario=" + IdUsuario;
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.GetAsync(urlApi).Result;
                var respuesta2 = context.GetAsync(urlApi2).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var usuarioRespuesta = respuesta.Content.ReadFromJsonAsync<Usuario>().Result;
                    usuario = usuarioRespuesta;

                }

                if (respuesta2.IsSuccessStatusCode)
                {
                    var encargadoApi = respuesta2.Content.ReadFromJsonAsync<Encargado>().Result;

                    if (encargadoApi != null && usuario != null)
                    {
                        if (usuario.EstudianteEncargado == null)
                            usuario.EstudianteEncargado = new Encargado();

                        usuario.EstudianteEncargado.IdEncargado = encargadoApi.IdEncargado;
                        usuario.EstudianteEncargado.Cedula = encargadoApi.Cedula;
                        usuario.EstudianteEncargado.Nombre = encargadoApi.Nombre;
                        usuario.EstudianteEncargado.Apellido1 = encargadoApi.Apellido1;
                        usuario.EstudianteEncargado.Apellido2 = encargadoApi.Apellido2;
                        usuario.EstudianteEncargado.Telefono = encargadoApi.Telefono;
                        usuario.EstudianteEncargado.Parentesco = encargadoApi.Parentesco;
                        usuario.EstudianteEncargado.LugarTrabajo = encargadoApi.LugarTrabajo;
                        usuario.EstudianteEncargado.Ocupacion = encargadoApi.Ocupacion;
                        usuario.EstudianteEncargado.Correo = encargadoApi.Correo;
                    }
                }

                var urlApi3 = _configuration["Valores:UrlAPI"] + "Home/ObtenerSecciones";
                var urlApi4 = _configuration["Valores:UrlAPI"] + "Home/ObtenerEspecialidades";
                var respuesta3 = context.GetAsync(urlApi3).Result;
                var respuesta4 = context.GetAsync(urlApi4).Result;

                if (respuesta3.IsSuccessStatusCode)
                {
                    var datosApi3 = respuesta3.Content.ReadFromJsonAsync<List<Secciones>>().Result;
                    usuario.ListaSecciones = datosApi3 ?? new List<Secciones>(); ;

                }
                else
                {
                    usuario.ListaSecciones = new List<Secciones>();
                }

                if (respuesta4.IsSuccessStatusCode)
                {
                    var datosApi4 = respuesta4.Content.ReadFromJsonAsync<List<Especialidades>>().Result;
                    usuario.ListaEspecialidades = datosApi4 ?? new List<Especialidades>();
                }
                else
                {
                    usuario.ListaEspecialidades = new List<Especialidades>();
                }

                usuario.ListaSecciones ??= new List<Secciones>();
                usuario.ListaEspecialidades ??= new List<Especialidades>();




                return View(usuario);
            }
        }


        [HttpPost]
        public IActionResult ActualizarPerfil(Usuario usuario)
        {

            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ActualizarPerfil";
                usuario.IdUsuario = (int)IdUsuario;
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Información personal actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al Actualizar perfil. Intente nuevamente."
                        : mensajeError;

                    return RedirectToAction("Perfil"); ;
                }
            }
        }

        [HttpPost]

        public IActionResult CambiarContrasenna(Usuario usuario)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/CambiarContrasenna";
                usuario.IdUsuario = (int)IdUsuario;
                var helper = new Helper();
                usuario.Contrasenna = helper.Encrypt(usuario.Contrasenna);
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Contraseña actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al cambiar la contraseña. Intente nuevamente."
                        : mensajeError;
                    return RedirectToAction("Perfil"); ;
                }
            }
        }


        [HttpPost]


        public IActionResult ActualizarInfoAcademica(Usuario usuario)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ActualizarInfoAcademica";
                usuario.IdUsuario = (int)IdUsuario;
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Información académica actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al Actualizar información académica. Intente nuevamente."
                        : mensajeError;
                    return RedirectToAction("Perfil"); ;
                }
            }
        }

        [HttpPost]

        public IActionResult ActualizarInfoMedica(Usuario usuario)
        {

            usuario.Padecimiento = usuario.Padecimiento ?? "Ninguno";
            usuario.Tratamiento = usuario.Tratamiento ?? "Ninguno";
            usuario.Alergia = usuario.Alergia ?? "Ninguno";


            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/ActualizarInfoMedica";
                usuario.IdUsuario = (int)IdUsuario;
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.PutAsJsonAsync(urlApi, usuario).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Información médica actualizada correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al Actualizar información médica. Intente nuevamente."
                        : mensajeError;
                    return RedirectToAction("Perfil"); ;
                }
            }
        }


        [HttpPost]
        public IActionResult GuardarEncargado(Usuario encargado)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");


            var cedula = encargado.EstudianteEncargado.Cedula;

            using (var context = _http.CreateClient())
            {

                var consultaCedula = _configuration["Valores:UrlApi"] + "Perfil/ConsultarEncargadoPorCedula?Cedula=" + cedula;
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuestaCedula = context.GetAsync(consultaCedula).Result;

                if (respuestaCedula.IsSuccessStatusCode)
                {

                    var encargadoApi = respuestaCedula.Content.ReadFromJsonAsync<Encargado>().Result;

                    encargado.EstudianteEncargado = encargadoApi;


                    TempData["SwalSuccess"] = "El encargado ya existía. Se cargó su información.";
                    return View("Perfil", encargado);
                }


                var urlApi = _configuration["Valores:UrlApi"] + "Perfil/AgregarEncargado";


                var request = new Encargado
                {
                    IdUsuario = (int)IdUsuario,
                    Nombre = encargado.EstudianteEncargado.Nombre,
                    Apellido1 = encargado.EstudianteEncargado.Apellido1,
                    Apellido2 = encargado.EstudianteEncargado.Apellido2,
                    Cedula = encargado.EstudianteEncargado.Cedula,
                    Correo = encargado.EstudianteEncargado.Correo,
                    Telefono = encargado.EstudianteEncargado.Telefono,
                    Ocupacion = encargado.EstudianteEncargado.Ocupacion,
                    LugarTrabajo = encargado.EstudianteEncargado.LugarTrabajo,
                    Parentesco = encargado.EstudianteEncargado.Parentesco,
                    IdEncargado = encargado.EstudianteEncargado.IdEncargado
                };
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.PostAsJsonAsync(urlApi, request).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    TempData["SwalSuccess"] = "Encargado guardado correctamente.";
                    return RedirectToAction("Perfil", "Perfil");
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                        ? "Error al agregar encargado. Intente nuevamente."
                        : mensajeError;

                    return RedirectToAction("Perfil", "Perfil");
                }
            }
        }

        [HttpGet]
        public JsonResult ObtenerEncargado(int IdEncargado)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");
            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"]
              + "Perfil/ObtenerEncargado?IdEncargado=" + IdEncargado
              + "&IdUsuario=" + IdUsuario;
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.GetAsync(urlApi).Result;
                if (respuesta.IsSuccessStatusCode)
                {
                    var encargadoRespuesta = respuesta.Content.ReadFromJsonAsync<Encargado>().Result;
                    return Json(encargadoRespuesta);
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;

                    return Json(new
                    {
                        exito = false,
                        mensaje = string.IsNullOrEmpty(mensajeError)
                            ? "Error al obtener encargado. Intente nuevamente."
                            : mensajeError
                    });
                }
            }
        }


        [HttpPost]
        public IActionResult SubirDocumentos(IFormFile Archivo, Usuario model)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");

            if (IdUsuario == null)
            {
                TempData["SwalError"] = "Sesión expirada. Vuelva a iniciar sesión.";
                return RedirectToAction("Login", "Home");
            }

            if (Archivo == null || Archivo.Length == 0)
            {
                TempData["SwalError"] = "Debe seleccionar un archivo para subir.";
                return RedirectToAction("Perfil", "Perfil");
            }

            if (string.IsNullOrWhiteSpace(model.Cedula))
            {
                TempData["SwalError"] = "No se encontró la cédula del usuario.";
                return RedirectToAction("Perfil", "Perfil");
            }

            string carpetaBase = @"C:\SIGEP\Perfil";
            string carpetaUsuario = Path.Combine(carpetaBase, model.Cedula);

            try
            {
                if (!Directory.Exists(carpetaUsuario))
                    Directory.CreateDirectory(carpetaUsuario);

                string nombreArchivo = Path.GetFileName(Archivo.FileName);
                string rutaCompleta = Path.Combine(carpetaUsuario, nombreArchivo);

                using (var stream = new FileStream(rutaCompleta, FileMode.Create))
                {
                    Archivo.CopyTo(stream);
                }


                using (var client = _http.CreateClient())
                {
                    var urlApi = _configuration["Valores:UrlApi"] + "Perfil/SubirDocumentos";

                    var request = new
                    {
                        IdUsuario = IdUsuario.Value,
                        Documento = rutaCompleta
                    };

                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                    var respuesta = client.PostAsJsonAsync(urlApi, request).Result;

                    if (respuesta.IsSuccessStatusCode)
                    {
                        TempData["SwalSuccess"] = "Documento subido y registrado correctamente.";
                        return RedirectToAction("Perfil", "Perfil");
                    }
                    else
                    {
                        var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                        TempData["SwalError"] = string.IsNullOrEmpty(mensajeError)
                            ? "El archivo se guardó en el servidor, pero hubo un error al registrar la información en el sistema."
                            : mensajeError;

                        return RedirectToAction("Perfil", "Perfil");
                    }
                }
            }
            catch (Exception ex)
            {
                TempData["SwalError"] = "Error al guardar el documento: " + ex.Message;
                return RedirectToAction("Perfil", "Perfil");
            }
        }

        [HttpGet]
        public JsonResult ObtenerDocumentos()
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");

            using (var context = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"] +
                             "Perfil/ObtenerDocumentos?IdUsuario=" + IdUsuario;
                context.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = context.GetAsync(urlApi).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    var documentosRespuesta = respuesta
                        .Content
                        .ReadFromJsonAsync<List<DocumentoVM>>()
                        .Result;

                    return Json(new
                    {
                        exito = true,
                        data = documentosRespuesta
                    });
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    return Json(new
                    {
                        exito = false,
                        mensaje = string.IsNullOrEmpty(mensajeError)
                            ? "Error al obtener documentos. Intente nuevamente."
                            : mensajeError
                    });
                }
            }
        }

        [HttpGet]
        public IActionResult DescargarDocumento(string ruta)
        {
            if (string.IsNullOrEmpty(ruta))
            {
                TempData["SwalError"] = "Ruta de documento inválida.";
                return RedirectToAction("Perfil", "Perfil");
            }

            if (!System.IO.File.Exists(ruta))
            {
                TempData["SwalError"] = "El archivo no existe en el servidor.";
                return RedirectToAction("Perfil", "Perfil");
            }

            var nombreArchivo = Path.GetFileName(ruta);
            var mimeType = "application/octet-stream";
            var fileBytes = System.IO.File.ReadAllBytes(ruta);
            return File(fileBytes, mimeType, nombreArchivo);
        }



        [HttpPost]
        public IActionResult EliminarDocumento(int idDocumento, string ruta)
        {
            var IdUsuario = HttpContext.Session.GetInt32("IdUsuario");

          
            try
            {
                if (!string.IsNullOrEmpty(ruta) && System.IO.File.Exists(ruta))
                {
                    System.IO.File.Delete(ruta);
                }
            }
            catch
            {

            }


            using (var client = _http.CreateClient())
            {
                var urlApi = _configuration["Valores:UrlApi"]
                             + $"Perfil/EliminarDocumento?IdDocumento={idDocumento}";
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", HttpContext.Session.GetString("Token"));
                var respuesta = client.DeleteAsync(urlApi).Result;

                if (respuesta.IsSuccessStatusCode)
                {
                    return Json(new { exito = true, mensaje = "Documento eliminado correctamente." });
                }
                else
                {
                    var mensajeError = respuesta.Content.ReadAsStringAsync().Result;
                    return Json(new
                    {
                        exito = false,
                        mensaje = string.IsNullOrEmpty(mensajeError)
                            ? "No se pudo eliminar el documento en el sistema."
                            : mensajeError
                    });
                }
            }
        }


    }


}