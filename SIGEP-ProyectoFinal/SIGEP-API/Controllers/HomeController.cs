using Dapper;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using System.Net;
using System.Net.Mail;
using System.Security.Cryptography;
using System.Text;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IHostEnvironment _environment;
        public HomeController(IConfiguration configuration, IHostEnvironment environment)
        {
            _configuration = configuration;
            _environment = environment;
        }

        #region Iniciar Sesion

        [HttpPost]
        [Route("IniciarSesion")]

        public IActionResult IniciarSesion(UsuarioModelRequest usuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@Cedula", usuario.Cedula);
                parametros.Add("@Contrasenna", usuario.Contrasenna);

                var resultado = context.QueryFirstOrDefault<UsuarioModelResponse>("LoginSP", parametros);
                if (resultado != null)
                    return Ok(resultado);
                return NotFound();
            }
        }

        #endregion

        #region Registro

        [HttpPost]
        [Route("Registro")]

        public IActionResult Registro(RegistroModelRequest usuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var cedula = new DynamicParameters();
                cedula.Add("@Cedula", usuario.Cedula);

                var ejecutar = context.QueryFirstOrDefault("ValidarUsuarioSP", cedula);

                if (ejecutar!=null)
                {
                    return BadRequest("Error. Ya existe otro usuario asociado a esa cédula");
                }
                
                var parametros = new DynamicParameters();
                parametros.Add("@Cedula", usuario.Cedula);
                parametros.Add("@Contrasenna", usuario.Contrasenna);
                parametros.Add("@Correo", usuario.CorreoPersonal);
                parametros.Add("@Nombre", usuario.Nombre);
                parametros.Add("@IdEspecialidad", usuario.IdEspecialidad);
                parametros.Add("@IdSeccion", usuario.IdSeccion);
                parametros.Add("@Apellido1", usuario.Apellido1);
                parametros.Add("@Apellido2", usuario.Apellido2);
                parametros.Add("@FechaNacimiento", usuario.FechaNacimiento);

                var resultado = context.Execute("RegistroSP", parametros);
                return Ok(resultado); 
            }
        }


        #endregion

        [HttpGet]
        [Route("ObtenerSecciones")]

        public IActionResult ObtenerSecciones()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var resultado = context.Query<SeccionesResponseModel>("ObtenerSeccionesSP").ToList();
                return Ok(resultado);
            }

        }

        [HttpGet]
        [Route("ObtenerEspecialidades")]

        public IActionResult ObtenerEspecialidades()
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var resultado = context.Query<EspecialidadesResponseModel>("ObtenerEspecialidadesSP").ToList();
                return Ok(resultado);
            }

        }


        #region Recuperar Acceso


        [HttpGet]
        [Route("RecuperarAcceso")]

        public IActionResult RecuperarAcceso(string Cedula)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@Cedula", Cedula);
                var resultado = context.QueryFirstOrDefault<UsuarioModelResponse>("ValidarUsuarioSP", parametros);

                if (resultado!= null)
                {
                    var ContrasennaGenerada = GenerarContrasenna();
                    var correo = resultado.Correo;
                    
                    var parametrosActualizar = new DynamicParameters();
                    parametrosActualizar.Add("@Cedula", Cedula);
                    parametrosActualizar.Add("@Contrasenna", ContrasennaGenerada);
                    var ejecutar = context.Execute("ActualizarContrasennaSP", parametrosActualizar);
                    if (ejecutar > 0)
                    {
                        var ruta = Path.Combine(_environment.ContentRootPath, "PlantillaCorreo.html");
                        var html = System.IO.File.ReadAllText(ruta, UTF8Encoding.UTF8);

                        html = html.Replace("{{Nombre}}", resultado.Nombre);
                        html = html.Replace("{{Contrasenna}}", ContrasennaGenerada);

                        EnviarCorreo("Recuperar Acceso", html, correo);
                        return Ok(resultado);

                    }
                  
                }

                return BadRequest("Error. La cédula no coincide con nuestros registros.");
            }
        }


        private string GenerarContrasenna()
        {
            int longitud = 8;
            const string caracteres = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            StringBuilder resultado = new();

            using var rng = RandomNumberGenerator.Create();
            byte[] buffer = new byte[1];

            while (resultado.Length < longitud)
            {
                rng.GetBytes(buffer);
                int valor = buffer[0] % caracteres.Length;
                resultado.Append(caracteres[valor]);
            }

            return resultado.ToString();
        }

        private void EnviarCorreo(string subject, string body, string destinatario)
        {
            var correoSMTP = _configuration["Valores:CorreoSMTP"]!;
            var contrasennaSMTP = _configuration["Valores:ContrasennaSMTP"]!;

            if (string.IsNullOrEmpty(contrasennaSMTP))
                return;

            var mensaje = new MailMessage
            {
                From = new MailAddress(correoSMTP),
                Subject = subject,
                Body = body,
                IsBodyHtml = true
            };

            mensaje.To.Add(destinatario);

            using var smtp = new SmtpClient("smtp.gmail.com")
            {
                Port = 587,
                Credentials = new NetworkCredential(correoSMTP, contrasennaSMTP),
                EnableSsl = true
            };

            smtp.Send(mensaje);
        }


        #endregion

    }
}
