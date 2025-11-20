namespace SIGEP_API.Models
{
    public class ComentarioResponseModel
    {
        public int IdComentario { get; set; }
        public string Autor { get; set; } = string.Empty;
        public string FechaFormateada { get; set; } = string.Empty;
        public DateTime Fecha { get; set; }
        public string Comentario { get; set; } = string.Empty;
        public string Tipo { get; set; } = string.Empty;
    }
}
