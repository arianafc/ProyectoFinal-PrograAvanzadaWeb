namespace SIGEP_ProyectoFinal.Models
{
    public class DocumentoVM
    {
        public int IdDocumento { get; set; }
        public string Documento { get; set; } = string.Empty;
        public int IdUsuario { get; set; }
        public DateTime FechaSubida { get; set; }

    }
}
