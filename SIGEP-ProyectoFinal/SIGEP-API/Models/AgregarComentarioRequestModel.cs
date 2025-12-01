using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class AgregarComentarioRequestModel
    {
        [Required]
        public int IdVacante { get; set; }
        [Required]
        public int IdUsuario { get; set; }
        [Required]
        public string Comentario { get; set; } = string.Empty;
        [Required]
        public int IdUsuarioComentario { get; set; }
    }
}
