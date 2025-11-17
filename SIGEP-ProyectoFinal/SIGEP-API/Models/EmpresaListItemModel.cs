namespace SIGEP_API.Models
{
    public class EmpresaListItemModel
    {
        public int IdEmpresa { get; set; }
        public string NombreEmpresa { get; set; } = "";
        public string AreasAfinidad { get; set; } = "";
        public string Ubicacion { get; set; } = "";
        public int HistorialVacantes { get; set; }
    }
}
