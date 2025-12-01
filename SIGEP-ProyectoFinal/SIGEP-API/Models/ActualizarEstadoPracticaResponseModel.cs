namespace SIGEP_API.Models
{
    public class ActualizarEstadoPracticaResponseModel
    {
        public int IdPractica { get; set; }
        public int IdVacante { get; set; }
        public int IdUsuario { get; set; }
        public string EstudianteNombre { get; set; } = string.Empty;
        public string EstudianteCorreo { get; set; } = string.Empty;
        public string EstadoDescripcion { get; set; } = string.Empty;
        public string Comentario { get; set; } = string.Empty;
        public DateTime? FechaComentario { get; set; }
    }
}
