namespace SIGEP_API.Models
{
    public class ComunicadoModelResponse
    {
        public int IdComunicado { get; set; }

        public string? Nombre { get; set; }

        public string? Informacion { get; set; }

        public string? Poblacion { get; set; }

        public DateTime? Fecha { get; set; }

        public DateTime? FechaLimite { get; set; }  

        public int IdUsuario { get; set; }

        public string? PublicadoPor { get; set; }

        public int IdEstado { get; set; }

    }
}
