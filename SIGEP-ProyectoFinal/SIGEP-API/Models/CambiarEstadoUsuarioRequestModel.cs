using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class CambiarEstadoUsuarioRequestModel
    {
        [Required]
        public int IdUsuario { get; set; }
        [Required]
        public string NuevoEstado { get; set; } = string.Empty;
    }
}
