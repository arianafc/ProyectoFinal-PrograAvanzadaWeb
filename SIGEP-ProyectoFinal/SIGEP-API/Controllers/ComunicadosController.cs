using Dapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using SIGEP_API.Models;
using SIGEP_API.Services;
using System.Data;

namespace SIGEP_API.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class ComunicadosController : ControllerBase
    {

        private readonly IConfiguration _configuration;
        private readonly IHostEnvironment _environment;
        private readonly IEmailService _emailService;
        public ComunicadosController(IConfiguration configuration, IHostEnvironment environment, IEmailService emailService)
        {
            _configuration = configuration;
            _environment = environment;
            _emailService = emailService;
        }

        [HttpGet]
        [Route("ObtenerComunicados")]

        public IActionResult ObtenerComunicados(string Poblacion)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@Poblacion", Poblacion);

                var resultado = context.Query<ComunicadoModelResponse>("ObtenerComunicadosSP", parametros).ToList();
                return Ok(resultado);
            }

        }

        [HttpPost]
        [Route("AgregarComunicado")]
        public IActionResult AgregarComunicado(ComunicadoRequestModel comunicado)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@Nombre", comunicado.Nombre);
                parametros.Add("@Informacion", comunicado.Informacion);
                parametros.Add("@Poblacion", comunicado.Poblacion);
                parametros.Add("@FechaLimite", comunicado.FechaLimite);
                parametros.Add("@IdUsuario", comunicado.IdUsuario);
                var idComunicado = context.QuerySingle<int>("AgregarComunicadoSP", parametros, commandType: System.Data.CommandType.StoredProcedure);

                if (comunicado.Documentos != null && comunicado.Documentos.Count > 0)
                {
                    foreach (var doc in comunicado.Documentos)
                    {
                        var docParams = new DynamicParameters();
                        docParams.Add("@IdComunicado", idComunicado);
                        docParams.Add("@NombreArchivo", doc.Documento);
                        docParams.Add("@Tipo", doc.Tipo);
                        context.Execute("GuardarDocumentosComunicadoSP", docParams, commandType: System.Data.CommandType.StoredProcedure);
                    }
                }
                return Ok(new { IdComunicado = idComunicado });
            }
        }


        [HttpPut]
        [Route("EditarComunicado")]
        public IActionResult EditarComunicado(ComunicadoRequestModel comunicado)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
              
                var parametros = new DynamicParameters();
                parametros.Add("@IdComunicado", comunicado.IdComunicado);
                parametros.Add("@Nombre", comunicado.Nombre);
                parametros.Add("@Informacion", comunicado.Informacion);
                parametros.Add("@Poblacion", comunicado.Poblacion);
                parametros.Add("@FechaLimite", comunicado.FechaLimite);

                context.Execute(
                    "EditarComunicadoSP",
                    parametros,
                    commandType: System.Data.CommandType.StoredProcedure
                );

               
                if (comunicado.Documentos != null && comunicado.Documentos.Count > 0)
                {
                    foreach (var doc in comunicado.Documentos)
                    {
                        var docParams = new DynamicParameters();
                        docParams.Add("@IdComunicado", comunicado.IdComunicado);
                        docParams.Add("@NombreArchivo", doc.Documento);
                        docParams.Add("@Tipo", doc.Tipo);

                        context.Execute(
                            "GuardarDocumentosComunicadoSP",
                            docParams,
                            commandType: System.Data.CommandType.StoredProcedure
                        );
                    }
                }

                return Ok(new
                {
                    Exito = true,
                    IdComunicado = comunicado.IdComunicado
                });
            }
        }


        [HttpGet]
        [Route("ObtenerComunicado")]

        public IActionResult ObtenerComunicado(int IdComunicado)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdComunicado", IdComunicado);

                var resultado = context.QueryFirstOrDefault<ComunicadoModelResponse>("ObtenerDetallesComunicadoSP", parametros);

                if (resultado == null)
                    return NotFound();

                return Ok(resultado);
            }
        }

        [HttpGet]
        [Route("ObtenerDocumentosComunicado")]

        public IActionResult ObtenerDocumentosComunicado(int IdComunicado)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdComunicado", IdComunicado);

                var resultado = context.Query<DocumentoResponse>("ObtenerDocumentosComunicadoSP", parametros).ToList(); ;

                if (resultado == null)
                    return NotFound();

                return Ok(resultado);
            }
        }

        [HttpGet]
        [Route("ObtenerDocumentoPorId")]

        public IActionResult ObtenerDocumentoPorId(int IdDocumento)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdDocumento", IdDocumento);

                var resultado = context.QueryFirstOrDefault<DocumentoResponse>("ObtenerDocumentoPorIdSP", parametros) ;

                if (resultado == null)
                    return NotFound();

                return Ok(resultado);
            }
        }



        [HttpPut]
        [Route("DesactivarComunicado")]

        public IActionResult DesactivarComunicado(int IdComunicado)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdComunicado", IdComunicado);
                parametros.Add("@IdEstado", 2);
                context.Execute("CambiarEstadoDocumentoSP", parametros, commandType: CommandType.StoredProcedure);
                return Ok(new { mensaje = "Comunicado desactivado correctamente." });
            }


        }


        [HttpPut]
        [Route("ActivarComunicado")]

        public IActionResult ActivarComunicado(int IdComunicado)
        {
            using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
            {
                var parametros = new DynamicParameters();
                parametros.Add("@IdComunicado", IdComunicado);
                parametros.Add("@IdEstado", 1);
                context.Execute("CambiarEstadoDocumentoSP", parametros, commandType: CommandType.StoredProcedure);
                return Ok(new { mensaje = "Comunicado desactivado correctamente." });
            }


        }

        [HttpPost]
        [Route("EnviarCorreoMasivo")]
        public IActionResult EnviarCorreoMasivo(EnviarCorreoRequest request)
        {
            try
            {
                using (var context = new SqlConnection(_configuration["ConnectionStrings:BDConnection"]))
                {
                    var parametros = new DynamicParameters();
                    parametros.Add("@Destinatario", request.Poblacion);

                    var correos = context.Query<EmailsCorreoResponse>(
                        "ObtenerEmailsSP",
                        parametros,
                        commandType: CommandType.StoredProcedure
                    ).ToList();

                    if (!correos.Any())
                        return BadRequest("No hay correos.");

                    int enviados = 0;

                    foreach (var item in correos)
                    {
                        if (string.IsNullOrEmpty(item.Email))
                            continue;

                        bool enviado = _emailService.EnviarCorreoConAdjuntos(
                            item.Email,
                            request.Asunto,
                            request.Mensaje,
                            request.Archivos
                        );

                        if (enviado)
                            enviados++;
                    }

                    return Ok(new { Total = correos.Count, Enviados = enviados });
                }
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }




    }
}

