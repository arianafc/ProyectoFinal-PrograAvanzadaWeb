using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class DocumentoRequest
    {
        [Required]

        public int IdUsuario { get; set; }

        [Required]

        public string? Documento { get; set; }
    }
}
