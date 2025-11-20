using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class GuardarComentarioRequestModel
    {
        [Required(ErrorMessage = "El IdUsuario es requerido")]
        public int IdUsuario { get; set; }

        [Required(ErrorMessage = "El IdCoordinador es requerido")]
        public int IdCoordinador { get; set; }

        [Required(ErrorMessage = "El comentario es requerido")]
        [StringLength(255, ErrorMessage = "El comentario no puede exceder 255 caracteres")]
        public string Comentario { get; set; } = string.Empty;
    }
}
