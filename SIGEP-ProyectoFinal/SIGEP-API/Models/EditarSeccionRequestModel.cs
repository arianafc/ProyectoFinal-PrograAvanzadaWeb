using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class EditarSeccionRequestModel
    {
        [Required]
        public int Id { get; set; }
        [Required]
        public string NombreSeccion { get; set; } = string.Empty;
    }
}
