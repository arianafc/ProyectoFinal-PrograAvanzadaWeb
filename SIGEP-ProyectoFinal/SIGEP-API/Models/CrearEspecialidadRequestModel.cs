using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class CrearEspecialidadRequestModel
    {
        [Required]
        public string Nombre { get; set; } = string.Empty;
    }
}
