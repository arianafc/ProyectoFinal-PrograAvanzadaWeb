namespace SIGEP_API.Models
{
    public class GuardarComentarioResponseModel
    {
        public bool Exito { get; set; }
        public string Mensaje { get; set; } = string.Empty;
        public string Autor { get; set; } = string.Empty;
        public string Fecha { get; set; } = string.Empty;
    }
}
