namespace SIGEP_API.Models
{
    public class EnviarCorreoRequest
    {
 
        public string? Poblacion { get; set; }
        public string? Asunto { get; set; }
        public string? Mensaje { get; set; }
        public List<IFormFile>? Archivos { get; set; }
    }
}
