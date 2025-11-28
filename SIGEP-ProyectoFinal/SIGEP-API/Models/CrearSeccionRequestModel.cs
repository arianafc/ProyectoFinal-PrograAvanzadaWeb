using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class CrearSeccionRequestModel
    {
        [Required]
        public string NombreSeccion { get; set; } = string.Empty;
    }
}
