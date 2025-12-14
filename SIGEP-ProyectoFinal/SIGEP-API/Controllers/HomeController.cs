using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.IdentityModel.Tokens;
using SIGEP_API.Models;
using SIGEP_API.Services;
using System.IdentityModel.Tokens.Jwt;
using System.Net;
using System.Net.Mail;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Utiles;

namespace SIGEP_API.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class HomeController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly IHostEnvironment _environment;
        private readonly IEmailService _emailService;

        public HomeController(IConfiguration configuration, IHostEnvironment environment, IEmailService emailService)
        {
            _configuration = configuration;
            _environment = environment;
            _emailService = emailService;
        }

        #region Iniciar Sesion
        [AllowAnonymous]
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
                {
                    resultado.Token = GenerarToken(resultado.IdUsuario, resultado.Nombre, resultado.IdRol);
                    return Ok(resultado);
                }

                return NotFound();  
            }
        }

        #endregion

        #region Registro
        [AllowAnonymous]
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
                parametros.Add("@Correo", usuario.Correo);
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
        [AllowAnonymous]
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

        [AllowAnonymous]
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

        [AllowAnonymous]
        [HttpGet]
        [Route("RecuperarAcceso")]

        public IActionResult RecuperarAcceso(string Cedula)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@Cedula", Cedula);
                var resultado = context.QueryFirstOrDefault<UsuarioModelResponse>("ValidarUsuarioSP", parametros);

                if (resultado != null)
                {
                    var helper = new Helper();
                  
                    var contrasennaGenerada = GenerarContrasenna(); 
                    var almacenarContrasenna = helper.Encrypt(contrasennaGenerada);

                    var correo = resultado.Correo;

                    var parametrosActualizar = new DynamicParameters();
                    parametrosActualizar.Add("@IdUsuario", resultado.IdUsuario);
                    parametrosActualizar.Add("@Contrasenna", almacenarContrasenna);
                    var ejecutar = context.Execute("ActualizarContrasennaSP", parametrosActualizar);

                    if (ejecutar > 0)
                    {
                        var correoEnviado = _emailService.EnviarCorreoRecuperacion(correo, resultado.Nombre, contrasennaGenerada);

                        if (correoEnviado)
                        {
                            return Ok(resultado);
                        }
                        else
                        {
                            return Ok(new
                            {
                                mensaje = "Contraseña actualizada pero no se pudo enviar el correo",
                                usuario = resultado
                            });
                        }
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


        #region CambiarContrasenna

        [Authorize]
        [HttpPost]
        [Route("CambiarContrasenna")]

        public IActionResult CambiarContrasenna(CambioContrasennaRequestModel usuario)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {

                if(usuario.Contrasenna != usuario.ConfirmarContrasenna)
                {
                    return BadRequest("Error. Las contraseñas no coinciden.");
                }
                else if (usuario.Contrasenna.Length
                    < 8)
                {
                    return BadRequest("Error. La contraseña debe tener al menos 8 caracteres.");
                }


                var parametros = new DynamicParameters();
                parametros.Add("@IdUsuario", usuario.IdUsuario);
                parametros.Add("@Contrasenna", usuario.Contrasenna);


                var resultado = context.Execute("ActualizarContrasennaSP", parametros);

                return Ok(resultado);
            }
        }



        #endregion

        private string GenerarToken(int usuarioId, string nombre, int rol)
        {
            var key = _configuration["Valores:KeyJWT"]!;

            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(key));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
        new Claim("id", usuarioId.ToString()),
        new Claim("nombre", nombre),
        new Claim("rol", rol.ToString())
    };

            var token = new JwtSecurityToken(
                claims: claims,
                expires: DateTime.UtcNow.AddHours(8), 
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

    }
}
