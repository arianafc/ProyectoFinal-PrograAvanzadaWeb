using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class ObtenerEstudiantesRequestModel
    {
        [Required(ErrorMessage = "El Id del Coordinador es requerido")]
        public int IdCoordinador { get; set; }
    }
}
