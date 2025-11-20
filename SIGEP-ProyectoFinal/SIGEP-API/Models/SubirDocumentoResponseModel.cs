namespace SIGEP_API.Models
{
    public class SubirDocumentoResponseModel
    {
        public bool Exito { get; set; }
        public string Mensaje { get; set; } = string.Empty;
        public int? IdDocumento { get; set; }
    }
}
