namespace SIGEP_ProyectoFinal.Models
{
    public class CambiarEstadoUsuarioModel
    {
        public int IdUsuario { get; set; }
        public string NuevoEstado { get; set; } = string.Empty;
    }
}
