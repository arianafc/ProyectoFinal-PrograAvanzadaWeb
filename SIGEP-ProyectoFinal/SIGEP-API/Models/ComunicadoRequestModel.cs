using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class ComunicadoRequestModel
    {
        [Required]
        public string? Nombre { get; set; }
        [Required]
        public string? Informacion { get; set; }
        [Required]
        public string? Poblacion { get; set; }
   
        public DateTime? FechaLimite { get; set; }

        [Required]
        public int IdUsuario { get; set; }

        public List<DocumentoComunicadoRequestModel> Documentos { get; set; } = new List<DocumentoComunicadoRequestModel>();

        public int IdComunicado { get; set; }
    }
}
