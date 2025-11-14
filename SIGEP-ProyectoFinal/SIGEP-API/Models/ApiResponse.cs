namespace SIGEP_API.Models
{
    public class ApiResponse<T>
    {
        public bool Ok { get; set; }
        public T? Data { get; set; }
        public string? Message { get; set; }

        public static ApiResponse<T> Success(T data, string? msg = null) => new() { Ok = true, Data = data, Message = msg };
        public static ApiResponse<T> Fail(string msg) => new() { Ok = false, Data = default, Message = msg };
    }
}
