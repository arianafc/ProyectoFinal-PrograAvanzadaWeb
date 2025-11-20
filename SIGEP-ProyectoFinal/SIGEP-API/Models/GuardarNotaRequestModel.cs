using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class GuardarNotaRequestModel
    {
        [Required(ErrorMessage = "El IdUsuario es requerido")]
        public int IdUsuario { get; set; }

        [Range(0, 100, ErrorMessage = "La Nota 1 debe estar entre 0 y 100")]
        public decimal? Nota1 { get; set; }

        [Range(0, 100, ErrorMessage = "La Nota 2 debe estar entre 0 y 100")]
        public decimal? Nota2 { get; set; }

        public decimal? NotaFinal { get; set; }

        [Required(ErrorMessage = "El IdCoordinador es requerido")]
        public int IdCoordinador { get; set; }
    }
}
