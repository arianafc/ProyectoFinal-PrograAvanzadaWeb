namespace SIGEP_ProyectoFinal.Models
{
    public class ApiResponse<T>
    {
        public bool Ok { get; set; }
        public T? Data { get; set; }
        public string? Message { get; set; }

        public static ApiResponse<T> Success(T data, string? message = null)
            => new ApiResponse<T> { Ok = true, Data = data, Message = message };

        public static ApiResponse<T> Fail(string message)
            => new ApiResponse<T> { Ok = false, Message = message };
    }
}
