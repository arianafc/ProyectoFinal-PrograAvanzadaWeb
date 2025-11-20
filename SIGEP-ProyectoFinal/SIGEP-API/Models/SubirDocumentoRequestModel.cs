using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class SubirDocumentoRequestModel
    {
        [Required(ErrorMessage = "El IdUsuario es requerido")]
        public int IdUsuario { get; set; }

        [Required(ErrorMessage = "El nombre del archivo es requerido")]
        public string NombreArchivo { get; set; } = string.Empty;

        public string Tipo { get; set; } = "Evaluación";
    }
}
