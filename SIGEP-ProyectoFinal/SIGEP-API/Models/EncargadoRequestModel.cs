using System.ComponentModel.DataAnnotations;

namespace SIGEP_API.Models
{
    public class EncargadoRequestModel
    {
        //DATOS PARA EL ENCARGADO

        [Required]

        public int IdUsuario { get; set; }

        [Required]
        public string? Nombre { get; set; }

        [Required]
        public string? Apellido1 { get; set; }

        [Required]
        public string? Apellido2 { get; set; }

        [Required]
        public string? Parentesco { get; set; }

        [Required]
        public string? Cedula { get; set; }

        [Required]

        public string? Ocupacion { get; set; }

        [Required]

        public string? Telefono { get; set; }

        [Required]

        public string? LugarTrabajo { get; set; }

        [Required]


        public string? Correo { get; set; }

    public int IdEncargado { get; set; }

    }
}
