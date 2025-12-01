namespace SIGEP_API.Models
{
    public class ComentarioPracticaResponseModel
    {
        public int Id { get; set; }
        public DateTime Fecha { get; set; }
        public string Usuario { get; set; } = string.Empty;
        public string Comentario { get; set; } = string.Empty;
    }
}
