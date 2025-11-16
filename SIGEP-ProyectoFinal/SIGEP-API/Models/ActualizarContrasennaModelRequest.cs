using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class ActualizarContrasennaModelRequest
    {
        [Required]

        public int IdUsuario { get; set; }

        [Required]

        public string? Contrasenna { get; set; }


    }
}
