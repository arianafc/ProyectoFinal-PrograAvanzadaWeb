namespace SIGEP_API.Models
{
    public class EmpresaDetalleModel
    {
        public int IdEmpresa { get; set; }
        public string NombreEmpresa { get; set; } = "";
        public string NombreContacto { get; set; } = "";

        public string Email { get; set; } = "";
        public string Telefono { get; set; } = "";

        public string Provincia { get; set; } = "";
        public string Canton { get; set; } = "";
        public string Distrito { get; set; } = "";
        public string DireccionExacta { get; set; } = "";

        public string AreasAfinidad { get; set; } = "";
    }
}
