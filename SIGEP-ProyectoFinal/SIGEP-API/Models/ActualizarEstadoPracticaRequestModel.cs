using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class ActualizarEstadoPracticaRequestModel
    {
        [Required]
        public int IdPractica { get; set; }
        [Required]
        public int IdEstado { get; set; }
        [Required]
        public string Comentario { get; set; } = string.Empty;
        [Required]
        public int IdUsuarioSesion { get; set; }
    }
}
