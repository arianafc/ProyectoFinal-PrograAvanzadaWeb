namespace SIGEP_API.Services
{
    public interface IEmailService
    {
        bool EnviarCorreo(string destinatario, string asunto, string cuerpoHtml);
        bool EnviarCorreoRecuperacion(string destinatario, string nombre, string contrasennaGenerada);
        bool EnviarCorreoActualizacionEstado(string destinatario, string nombreEstudiante, string estadoDescripcion, string comentario, DateTime? fechaComentario);
    }
}
