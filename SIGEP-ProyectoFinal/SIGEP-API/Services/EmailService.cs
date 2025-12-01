using System.Net;
using System.Net.Mail;
using System.Text;

namespace SIGEP_API.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _environment;

        public EmailService(IConfiguration configuration, IWebHostEnvironment environment)
        {
            _configuration = configuration;
            _environment = environment;
        }

        public bool EnviarCorreo(string destinatario, string asunto, string cuerpoHtml)
        {
            try
            {
                var correoSMTP = _configuration["Valores:CorreoSMTP"];
                var contrasennaSMTP = _configuration["Valores:ContrasennaSMTP"];

                if (string.IsNullOrEmpty(correoSMTP) || string.IsNullOrEmpty(contrasennaSMTP))
                {
                    return false;
                }

                var mensaje = new MailMessage
                {
                    From = new MailAddress(correoSMTP),
                    Subject = asunto,
                    Body = cuerpoHtml,
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
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ERROR al enviar correo: {ex.Message}");
                return false;
            }
        }

        public bool EnviarCorreoRecuperacion(string destinatario, string nombre, string contrasennaGenerada)
        {
            try
            {
                var ruta = Path.Combine(_environment.ContentRootPath, "PlantillaCorreo.html");

                if (!File.Exists(ruta))
                {
                    Console.WriteLine($"ERROR: No se encontró la plantilla en {ruta}");
                    return false;
                }

                var html = File.ReadAllText(ruta, Encoding.UTF8);
                html = html.Replace("{{Nombre}}", nombre);
                html = html.Replace("{{Contrasenna}}", contrasennaGenerada);

                return EnviarCorreo(destinatario, "Recuperar Acceso", html);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ERROR al enviar correo de recuperación: {ex.Message}");
                return false;
            }
        }

        public bool EnviarCorreoActualizacionEstado(string destinatario, string nombreEstudiante, string estadoDescripcion, string comentario, DateTime? fechaComentario)
        {
            try
            {
                var ruta = Path.Combine(_environment.ContentRootPath, "PlantillaActualizacionEstado.html");

                if (!File.Exists(ruta))
                {
                    Console.WriteLine($"ERROR: No se encontró la plantilla en {ruta}");
                    return false;
                }

                var html = File.ReadAllText(ruta, Encoding.UTF8);
                html = html.Replace("{{NombreEstudiante}}", nombreEstudiante);
                html = html.Replace("{{EstadoDescripcion}}", estadoDescripcion);
                html = html.Replace("{{Comentario}}", comentario);
                html = html.Replace("{{FechaComentario}}", fechaComentario?.ToString("dd/MM/yyyy") ?? "");

                return EnviarCorreo(destinatario, "Actualización de Estado de Práctica - SIGEP", html);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"ERROR al enviar correo de actualización: {ex.Message}");
                return false;
            }
        }

    }
}
