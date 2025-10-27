using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class UsuarioModelRequest
    {

        [Required]
        public string? Cedula { get; set; }

        [Required]

        public string? Contrasenna { get; set; }



    }
}
