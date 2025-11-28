using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class EditarEspecialidadRequestModel
    {
        [Required]
        public int Id { get; set; }
        [Required]
        public string Nombre { get; set; } = string.Empty;
    }
}
