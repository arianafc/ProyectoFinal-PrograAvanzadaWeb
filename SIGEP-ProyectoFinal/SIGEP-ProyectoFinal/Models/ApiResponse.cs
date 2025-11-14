namespace SIGEP_ProyectoFinal.Models
{
    public class ApiResponse<T>
    {
        public bool Ok { get; set; }
        public T? Data { get; set; }
        public string? Message { get; set; }
    }
}
