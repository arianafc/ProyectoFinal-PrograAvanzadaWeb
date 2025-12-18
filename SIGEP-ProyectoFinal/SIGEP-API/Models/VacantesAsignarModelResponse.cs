namespace SIGEP_API.Models
{
    public class VacantesAsignarModelResponse
    {
        public int IdVacantePractica { get; set; }

        public string? NombreVacante { get; set; }

        public string? NombreEmpresa { get; set; }

        public string? Especialidad { get; set; }

        public int NumeroCupos { get; set; }

        public int CuposOcupados { get; set;}   

        public DateTime? FechaCierre { get; set; }

        public string? Requisitos { get; set; }

        public string? Tipo { get; set; }

        public string? NombreCompleto { get; set; }

        public int PuedeAsignar { get; set; }

        public string? EstadoAcademicoDescripcion { get; set; }
    }
}
