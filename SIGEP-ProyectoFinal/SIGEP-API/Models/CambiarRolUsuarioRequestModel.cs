using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class CambiarRolUsuarioRequestModel
    {
        [Required]
        public int IdUsuario { get; set; }
        [Required]
        public string Rol { get; set; } = string.Empty;
    }
}
