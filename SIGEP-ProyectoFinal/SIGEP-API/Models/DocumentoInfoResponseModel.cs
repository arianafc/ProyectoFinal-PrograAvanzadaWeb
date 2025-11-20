namespace SIGEP_API.Models
{
    public class DocumentoInfoResponseModel
    {
        public int IdDocumento { get; set; }
        public string Documento { get; set; } = string.Empty;
        public int IdUsuario { get; set; }
    }
}
