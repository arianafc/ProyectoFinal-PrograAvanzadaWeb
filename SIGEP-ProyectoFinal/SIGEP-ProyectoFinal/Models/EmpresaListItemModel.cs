namespace SIGEP_ProyectoFinal.Models
{
    public class EmpresaListItemModel
    {
        public int IdEmpresa { get; set; }
        public string NombreEmpresa { get; set; } = "";
        public string AreasAfinidad { get; set; } = "";
        public string Ubicacion { get; set; } = "";
        public int HistorialVacantes { get; set; }
        public string Provincia { get; set; } = "";
        public string Canton { get; set; } = "";
        public string Distrito { get; set; } = "";
    }
}
