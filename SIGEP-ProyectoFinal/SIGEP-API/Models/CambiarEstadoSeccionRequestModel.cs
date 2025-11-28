using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class CambiarEstadoSeccionRequestModel
    {
        [Required]
        public int Id { get; set; }
        [Required]
        public string NuevoEstado { get; set; } = string.Empty;
    }
}
