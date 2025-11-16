//$(function () {
//    $("#FechaNacimientoRegistro").datepicker({
//        dateFormat: "yy-mm-dd",
//        changeMonth: true,
//        changeYear: true,
//        yearRange: "1950:" + new Date().getFullYear(),
//        maxDate: new Date(new Date().getFullYear() - 17, 11, 31),
//        defaultDate: new Date(new Date().getFullYear() - 17, 0, 1)
//    });



//    $('#btnSubirDoc').on('click', function () {
//        var archivo = $('#ArchivoDoc')[0].files[0];
//        var idUsuario = $('#IdUsuarioDoc').val();

//        if (!archivo) {
//            Swal.fire({
//                icon: 'warning',
//                title: 'No hay archivo',
//                text: 'Por favor seleccione un archivo antes de continuar.',
//                confirmButtonColor: '#3085d6'
//            });
//            return;
//        }

//        // Validar extensión
//        var extensionesPermitidas = ['.xls', '.xlsx', '.pdf', '.png', '.jpeg'];
//        var extension = '.' + archivo.name.split('.').pop().toLowerCase();
//        if (!extensionesPermitidas.includes(extension)) {
//            Swal.fire({
//                icon: 'error',
//                title: 'Extensión inválida',
//                text: 'Solo se permiten archivos .xls, .xlsx, .pdf, .jpeg o .png',
//                confirmButtonColor: '#d33'
//            });
//            return;
//        }

//        var formData = new FormData();
//        formData.append('archivo', archivo);
//        formData.append('idUsuario', idUsuario);

//        $.ajax({
//            url: '/Perfil/SubirDocumento',
//            type: 'POST',
//            data: formData,
//            contentType: false,
//            processData: false,
//            success: function (response) {
//                if (response.success) {
//                    Swal.fire({
//                        title: 'Éxito',
//                        text: response.message,
//                        icon: 'success',
//                        confirmButtonColor: '#2D594D'
//                    }).then(() => {
//                        $('#modalSubirDoc').modal('hide');
//                        location.reload(); // recarga la página para mostrar el documento
//                    });
//                } else {
//                    Swal.fire({
//                        title: 'Error',
//                        text: response.message,
//                        icon: 'error',
//                        confirmButtonColor: '#d33'
//                    });
//                }
//            },
//            error: function (xhr, status, error) {
//                Swal.fire({
//                    title: 'Error',
//                    text: 'Ocurrió un error al subir el documento: ' + error,
//                    icon: 'error',
//                    confirmButtonColor: '#d33'
//                });
//            }
//        });
//    });

//    function cargarDocumentos() {

//        let idUsuario = $('#IdUsuarioDocumento').val();

//        $.ajax({
//            url: '/Perfil/ObtenerDocumentos',
//            type: 'GET',
//            data: { idUsuario: idUsuario },
//            success: function (response) {
//                var contenedor = $('#listaDocumentos');
//                contenedor.empty();

//                if (!response.success) {
//                    Swal.fire('Error', response.message || 'No se pudieron cargar los documentos.', 'error');
//                    return;
//                }

//                var documentos = response.documentos;

//                if (!documentos || documentos.length === 0) {
//                    contenedor.append('<div class="text-center text-muted">No hay documentos subidos.</div>');
//                    return;
//                }

//                documentos.forEach(function (doc) {
//                    var item = $(`
//            <div class="list-group-item d-flex justify-content-between align-items-center" 
//                 style="background-color: white; border: 1px solid #8CA653; border-radius: 8px; margin-bottom: 10px;">
//                <div>
//                    <strong>${doc.Nombre}</strong><br />
//                    <small>Cargado: ${doc.FechaSubida}</small>
//                </div>
//                <div class="d-flex gap-3">
                    
//                    <a href="/Perfil/DescargarDocumento?ruta=${encodeURIComponent(doc.RutaArchivo)}&download=true" 
//                       title="Descargar" class="btn btn-link p-0 text-secondary">
//                       <i class="fas fa-download"></i>
//                    </a>
//                    <button class="btn btn-link p-0 text-secondary btnEliminarDoc" data-id="${doc.IdDocumento}" title="Eliminar">
//                       <i class="fas fa-trash-alt"></i>
//                    </button>
//                </div>
//            </div>
//        `);
//                    contenedor.append(item);
//                });
//            }
//,
//            error: function () {
//                Swal.fire('Error', 'No se pudieron cargar los documentos.', 'error');
//            }
//        });
//    }

//    // Evento para eliminar
//    $(document).on('click', '.btnEliminarDoc', function () {
//        var idDocumento = $(this).data('id');

//        Swal.fire({
//            title: '¿Desea eliminar este documento?',
//            icon: 'warning',
//            showCancelButton: true,
//            confirmButtonText: 'Sí, eliminar',
//            cancelButtonText: 'Cancelar',
//            confirmButtonColor: '#d33',
//            cancelButtonColor: '#3085d6'
//        }).then((result) => {
//            if (result.isConfirmed) {
//                $.ajax({
//                    url: '/Perfil/EliminarDocumento',
//                    type: 'POST',
//                    data: { idDocumento: idDocumento },
//                    success: function (response) {
//                        if (response.success) {
//                            Swal.fire('Eliminado', response.message, 'success');
//                            cargarDocumentos(); // recargar lista
//                        } else {
//                            Swal.fire('Error', response.message, 'error');
//                        }
//                    },
//                    error: function () {
//                        Swal.fire('Error', 'Ocurrió un error al eliminar.', 'error');
//                    }
//                });
//            }
//        });
//    });

//    // Cargar documentos al abrir el modal
//    $('#modalVerDocs').on('shown.bs.modal', function () {
//        cargarDocumentos();
//    });

//    var Contrasenna = $('#ContrasennaNueva');
//    var ConfirmarContrasenna = $('#ConfirmarContrasenna');
//    var Form = $('#CambiarContrasennaForm');

//    $(".btnEditarEncargado").click(function () {
//        var idEncargado = $(this).data('id'); 
//        editarEncargado(idEncargado);
//    });
  


//    // ===================== AGREGAR ENCARGADO =====================
//    $('#btnGuardarEncargado').on('click', function () {
//        // Captura de datos del formulario
//        var data = {
//            cedula: $("#CedulaNuevoEncargado").val().trim(),
//            nombre: $('#NombreNuevoEncargado').val().trim(),
//            apellido1: $('#Apellido1NuevoEncargado').val().trim(),
//            apellido2: $('#Apellido2NuevoEncargado').val().trim(),
//            telefono: $('#TelefonoNuevoEncargado').val().trim(),
//            correo: $('#CorreoNuevoEncargado').val().trim(),
//            parentesco: $('#ParentescoNuevoEncargado').val().trim(),
//            ocupacion: $('#OcupacionNuevoEncargado').val().trim(),
//            lugarTrabajo: $('#ResidenciaNuevoEncargado').val().trim()
//        };

//        // Validaciones
//        if (!data.cedula || !data.nombre || !data.apellido1 || !data.telefono || !data.correo || !data.parentesco) {
//            Swal.fire('Error', 'Por favor complete todos los campos obligatorios.', 'error');
//            return;
//        }

//        // Validar correo electrónico
//        var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
//        if (!emailPattern.test(data.correo)) {
//            Swal.fire('Error', 'Ingrese un correo electrónico válido.', 'error');
//            return;
//        }

//        // Validar teléfono (solo números y mínimo 8 dígitos)
//        var telefonoPattern = /^\d{8,}$/;
//        if (!telefonoPattern.test(data.telefono)) {
//            Swal.fire('Error', 'Ingrese un número de teléfono válido (mínimo 8 dígitos).', 'error');
//            return;
//        }

//        // Enviar datos por AJAX
//        $.ajax({
//            url: '/Perfil/AgregarEncargado',
//            type: 'POST',
//            data: data,
//            success: function (response) {
//                if (response.success) {
//                    Swal.fire({
//                        title: 'Éxito',
//                        text: response.mensaje,
//                        icon: 'success',
//                        confirmButtonColor: '#2D594D'
//                    }).then(() => {
//                        window.location.href = '/Perfil/MiPerfil';
//                    });
//                } else {
//                    Swal.fire({
//                        title: 'Error',
//                        text: response.mensaje,
//                        icon: 'error',
//                        confirmButtonColor: '#d33'
//                    });
//                }
//            },
//            error: function (error) {
//                Swal.fire('Error', 'Error al agregar encargado: ' + error.responseText, 'error');
//            }
//        });
//    });


//    // ===================== ACTUALIZAR ENCARGADO =====================
//    $('#btnActualizarEncargado').click(function () {
//        var data = {
//            IdEncargado: $('#IdEncargado').val(),
//            Nombre: $('#NombreEditar').val(),
//            Apellido1: $('#Apellido1Editar').val(),
//            Apellido2: $('#Apellido2Editar').val(),
//            Telefono: $('#TelefonoEditar').val(),
//            Parentesco: $('#ParentescoEditar').val(),
//            LugarTrabajo: $('#LugarTrabajoEditar').val(),
//            Ocupacion: $('#OcupacionEditar').val(),
//            Correo: $('#CorreoEditar').val(),
//            Cedula: $('#CedulaEditar').val()
//        };

//        if (!data.Cedula || !data.Nombre || !data.Apellido1 || !data.Apellido2 || !data.Telefono || !data.Correo || !data.Ocupacion || !data.LugarTrabajo || !data.Parentesco) {
//            Swal.fire('Error', 'Por favor complete todos los campos obligatorios.', 'error');
//            return;
//        }

//        // Validar correo electrónico
//        var emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
//        if (!emailPattern.test(data.Correo)) {
//            Swal.fire('Error', 'Ingrese un correo electrónico válido.', 'error');
//            return;
//        }

//        // Validar teléfono (solo números y mínimo 8 dígitos)
//        var telefonoPattern = /^\d{8,}$/;
//        if (!telefonoPattern.test(data.Telefono)) {
//            Swal.fire('Error', 'Ingrese un número de teléfono válido (mínimo 8 dígitos).', 'error');
//            return;
//        }


//        $.ajax({
//            url: '/Perfil/ActualizarEncargado',
//            type: 'POST',
//            data: data,
//            success: function (response) {
//                if (response.success) {
//                    $('#modalEditarEncargado').modal('hide');
//                    Swal.fire({
//                        title: 'Éxito',
//                        text: response.mensaje,
//                        icon: 'success',
//                        confirmButtonColor: '#2D594D'
//                    }).then(() => {
//                        window.location.href = '/Perfil/MiPerfil';
//                    });
//                } else {
//                    Swal.fire({
//                        title: 'Error',
//                        text: response.mensaje,
//                        icon: 'error',
//                        confirmButtonColor: '#d33'
//                    });
//                }
//            },
//            error: function () {
//                Swal.fire('Error', 'No se pudo actualizar el encargado.', 'error');
//            }
//        });
//    });


//    $('#modalEditarEncargado').on('hidden.bs.modal', function () {
//        $('#modalVerEncargados').modal('hide');
//    });
//    // ===================== VALIDAR CONTRASEÑA =====================
//    function validarContrasenna() {
//        let pass = Contrasenna.val().trim();
//        let confirm = ConfirmarContrasenna.val().trim();

//        if (pass.length < 8) {
//            Swal.fire({
//                icon: 'warning',
//                title: 'Contraseña muy corta',
//                text: 'La contraseña debe tener al menos 8 caracteres.',
//                confirmButtonColor: '#8CA653'
//            });
//            return false;
//        }

//        if (pass !== confirm) {
//            Swal.fire({
//                icon: 'warning',
//                title: 'Las contraseñas no coinciden',
//                text: 'Por favor, verifique que ambas contraseñas sean iguales.',
//                confirmButtonColor: '#8CA653'
//            });
//            return false;
//        }

//        return true;
//    }

//    Form.on("submit", function (e) {
//        if (!validarContrasenna()) {
//            e.preventDefault();
//            return false;
//        }
//    });


//    // ===================== MENSAJES REUTILIZABLES =====================
//    function mostrarSuccessMensaje() {
//        Swal.fire({
//            icon: 'success',
//            title: 'Información guardada correctamente',
//            showConfirmButton: false,
//            timer: 2000
//        });
//    }



//    // ===================== EDITAR ENCARGADO =====================
   

//    // ===================== ELIMINAR ENCARGADO =====================
  

//    // ===================== LIMPIAR MODAL =====================
   
//});
//function editarEncargado(idEncargado) {
//    $.ajax({
//        url: '/Perfil/ObtenerEncargadoPorId',
//        type: 'GET',
//        data: { idEncargado: idEncargado },
//        success: function (data) {
//            if (data && !data.error) {
//                $('#IdEncargado').val(data.IdEncargado);
//                $('#CedulaEditar').val(data.Cedula);
//                $('#NombreEditar').val(data.Nombre);
//                $('#Apellido1Editar').val(data.Apellido1);
//                $('#Apellido2Editar').val(data.Apellido2);
//                $('#TelefonoEditar').val(data.Telefono);
//                $('#ParentescoEditar').val(data.Parentesco);
//                $('#LugarTrabajoEditar').val(data.LugarTrabajo);
//                $('#OcupacionEditar').val(data.Ocupacion);
//                $('#CorreoEditar').val(data.Correo);
//                $('#modalVerEncargados').modal('hide');
//                $('#modalEditarEncargado').modal('show');


//            } else {
//                Swal.fire('Error', data.mensaje || 'No se pudo obtener la información del encargado.', 'error');
//            }
//        },
//        error: function () {
//            Swal.fire('Error', 'No se pudo conectar con el servidor.', 'error');
//        }
//    });
//}

//function eliminarEncargado(idEncargado) {
//    Swal.fire({
//        title: '¿Está seguro?',
//        text: "¿Seguro que desea desactivar este encargado?",
//        icon: 'warning',
//        showCancelButton: true,
//        confirmButtonColor: '#3085d6',
//        cancelButtonColor: '#d33',
//        confirmButtonText: 'Sí, desactivar',
//        cancelButtonText: 'Cancelar'
//    }).then((result) => {
//        if (result.isConfirmed) {
//            $.ajax({
//                url: '/Perfil/EliminarEncargado',
//                type: 'POST',
//                data: { IdEncargado: idEncargado },
//                success: function (response) {
//                    if (response.success) {
//                        Swal.fire({
//                            title: 'Éxito',
//                            text: response.mensaje,
//                            icon: 'success',
//                            confirmButtonColor: '#2D594D'
//                        }).then(() => {
//                            window.location.href = '/Perfil/MiPerfil';
//                        });
//                    } else {
//                        Swal.fire({
//                            title: 'Error',
//                            text: response.mensaje,
//                            icon: 'error',
//                            confirmButtonColor: '#d33'
//                        });
//                    }
//                },
//                error: function () {
//                    Swal.fire('Error', 'No se pudo eliminar el encargado.', 'error');
//                }
//            });
//        }
//    });
//}


//function activarEncargado(idEncargado) {
//    Swal.fire({
//        title: '¿Está seguro?',
//        text: "¿Seguro que desea activar este encargado?",
//        icon: 'warning',
//        showCancelButton: true,
//        confirmButtonColor: '#3085d6',
//        cancelButtonColor: '#d33',
//        confirmButtonText: 'Sí, activar',
//        cancelButtonText: 'Cancelar'
//    }).then((result) => {
//        if (result.isConfirmed) {
//            $.ajax({
//                url: '/Perfil/ActivarEncargado',
//                type: 'POST',
//                data: { IdEncargado: idEncargado },
//                success: function (response) {
//                    if (response.success) {
//                        Swal.fire({
//                            title: 'Éxito',
//                            text: response.mensaje,
//                            icon: 'success',
//                            confirmButtonColor: '#2D594D'
//                        }).then(() => {
//                            window.location.href = '/Perfil/MiPerfil';
//                        });
//                    } else {
//                        Swal.fire({
//                            title: 'Error',
//                            text: response.mensaje,
//                            icon: 'error',
//                            confirmButtonColor: '#d33'
//                        });
//                    }
//                },
//                error: function () {
//                    Swal.fire('Error', 'No se pudo activar el encargado.', 'error');
//                }
//            });
//        }
//    });
//}



//$('#CedulaNuevoEncargado').on('blur', function () {
//    let cedula = $(this).val().trim();

//    if (cedula === '') return; // Evita llamadas vacías

//    $.ajax({
//        url: '/Perfil/ObtenerEncargadoPorCedula',
//        type: 'GET',
//        data: { Cedula: cedula },
//        success: function (response) {
//            if (response.success && response.data) {
//                let e = response.data;

//                $('#NombreNuevoEncargado').val(e.Nombre);
//                $('#Apellido1NuevoEncargado').val(e.Apellido1);
//                $('#Apellido2NuevoEncargado').val(e.Apellido2);
//                $('#TelefonoNuevoEncargado').val(e.Telefono);
//                $('#CorreoNuevoEncargado').val(e.Correo);
//                $('#ParentescoNuevoEncargado').val(''); 
//                $('#OcupacionNuevoEncargado').val(e.Ocupacion);
//                $('#ResidenciaNuevoEncargado').val(e.LugarTrabajo);

//                Swal.fire({
//                    icon: 'info',
//                    title: 'Encargado encontrado',
//                    text: 'Se han autocompletado los datos del encargado.',
//                    timer: 2000,
//                    showConfirmButton: false
//                });
//            } else {
                
//                $('#NombreNuevoEncargado, #Apellido1NuevoEncargado, #Apellido2NuevoEncargado, #TelefonoNuevoEncargado, #CorreoNuevoEncargado, #ParentescoNuevoEncargado, #OcupacionNuevoEncargado, #ResidenciaNuevoEncargado').val('');

//                Swal.fire({
//                    icon: 'warning',
//                    title: 'No encontrado',
//                    text: 'No existe un encargado con esa cédula. Puede registrarlo nuevo.',
//                    timer: 2500,
//                    showConfirmButton: false
//                });
//            }
//        },
//        error: function () {
//            Swal.fire({
//                icon: 'error',
//                title: 'Error de conexión',
//                text: 'No se pudo consultar la cédula. Intente nuevamente.'
//            });
//        }
//    });
//});



//$('#ActualizarPerfil').on('submit', function (e) {
//    e.preventDefault(); 

//    let nombre = $('#NombrePerfil').val().trim();
//    let apellido1 = $('#Apellido1Perfil').val().trim();
//    let apellido2 = $('#Apellido2Perfil').val().trim();
//    let cedula = $('#CedulaPerfil').val().trim();
//    let telefono = $('#TelefonoPerfil').val().trim();
//    let correo = $('#CorreoPersonalPerfil').val().trim();
//    let direccion = $('#DireccionPerfil').val().trim();

//    // Validar campos vacíos
//    if (!nombre || !apellido1 || !apellido2 || !cedula || !telefono ||
//        !correo || !direccion) {
//        Swal.fire({
//            icon: 'warning',
//            title: 'Campos incompletos',
//            text: 'Por favor complete todos los campos obligatorios antes de continuar.',
//            confirmButtonColor: '#3085d6'
//        });
//        return;
//    }

//    // Validar correo electrónico
//    let emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
//    if (!emailRegex.test(correo)) {
//        Swal.fire({
//            icon: 'error',
//            title: 'Correo inválido',
//            text: 'Por favor ingrese un correo electrónico válido.',
//            confirmButtonColor: '#3085d6'
//        });
//        return;
//    }

//    // Validar teléfono (solo números y mínimo 8 dígitos)
//    var telefonoPattern = /^\d{8,}$/;
//    if (!telefonoPattern.test(telefono)) {
//        Swal.fire('Error', 'Ingrese un número de teléfono válido (mínimo 8 dígitos).', 'error');
//        return;
//    }
//    // Confirmación antes de enviar
//    Swal.fire({
//        title: '¿Desea actualizar su información?',
//        icon: 'question',
//        showCancelButton: true,
//        confirmButtonText: 'Sí, actualizar',
//        cancelButtonText: 'Cancelar',
//        confirmButtonColor: '#3085d6',
//        cancelButtonColor: '#d33'
//    }).then((result) => {
//        if (result.isConfirmed) {
//            e.currentTarget.submit();
//        }
//    });
//});

function calcularFechaMaxima() {
    const hoy = new Date();
    const año = hoy.getFullYear() - 17;
    const mes = String(hoy.getMonth() + 1).padStart(2, '0');
    const dia = String(hoy.getDate()).padStart(2, '0');
    return `${año}-${mes}-${dia}`;
}


function validarEdad(fechaNacimiento) {

    const partes = fechaNacimiento.split('-');
    const fecha = new Date(partes[0], partes[1] - 1, partes[2]);
    const hoy = new Date();

   
    hoy.setHours(0, 0, 0, 0);
    fecha.setHours(0, 0, 0, 0);

    let edad = hoy.getFullYear() - fecha.getFullYear();
    const mes = hoy.getMonth() - fecha.getMonth();

    if (mes < 0 || (mes === 0 && hoy.getDate() < fecha.getDate())) {
        edad--;
    }

    return edad >= 17;
}

document.addEventListener('DOMContentLoaded', function () {


    const formContrasenna = document.getElementById("ActualizarContrasenna");

    formContrasenna.addEventListener("submit", function (e) {
        e.preventDefault();


        let pass = document.getElementById("ContrasennaNueva").value.trim();
        let passConf = document.getElementById("ContrasennaNuevaPerfil").value.trim();

        if (pass.length < 8) {
            Swal.fire("Atención", "La contraseña debe tener al menos 8 caracteres.", "warning");
            return;
        }
        if (pass !== passConf) {
            Swal.fire("Error", "Las contraseñas no coinciden.", "error");
            return;
        }


        Swal.fire({
            title: "¿Deseas actualizar la contraseña?",
            icon: "question",
            showCancelButton: true,
            confirmButtonText: "Sí, actualizar",
            cancelButtonText: "Cancelar"
        }).then((result) => {
            if (result.isConfirmed) {
                formContrasenna.submit();
            }
        });

    });

    const formPerfil = document.getElementById('ActualizarPerfil');

    formPerfil.addEventListener('submit', function (e) {
       
        limpiarErrores();

        let esValido = true;
        let mensajesErrores = [];

      
        const nombre = document.getElementById('NombrePerfil');
        const apellido1 = document.getElementById('Apellido1Perfil');
        const apellido2 = document.getElementById('Apellido2Perfil');
        const cedula = document.getElementById('CedulaPerfil');
        const fechaNac = document.getElementById('FechaNacimientoPerfil');
        const telefono = document.getElementById('TelefonoPerfil');
        const correo = document.getElementById('CorreoPersonalPerfil');
        const sexo = document.getElementById('SexoPerfil'); 
        const nacionalidad = document.getElementById('NacionalidadPerfil');
        const provincia = document.getElementById('Provincia');
        const canton = document.getElementById('Canton');
        const distrito = document.getElementById('Distrito');
        const direccion = document.getElementById('DireccionPerfil');

       
        function marcarError(campo, mensaje) {
            esValido = false;
            mensajesErrores.push(mensaje);
            campo.classList.add('is-invalid');

            const spanError = document.createElement('div');
            spanError.classList.add('invalid-feedback');
            spanError.textContent = mensaje;

            const existente = campo.parentElement.querySelector('.invalid-feedback');
            if (existente) {
                existente.remove();
            }

            campo.parentElement.appendChild(spanError);
        }

        if (!nombre.value.trim()) {
            marcarError(nombre, 'El nombre es obligatorio.');
        }

        if (!apellido1.value.trim()) {
            marcarError(apellido1, 'El primer apellido es obligatorio.');
        }

        if (!apellido2.value.trim()) {
            marcarError(apellido2, 'El segundo apellido es obligatorio.');
        }

        if (!cedula.value.trim()) {
            marcarError(cedula, 'La cédula es obligatoria.');
        }

       
        if (!fechaNac.value) {
            marcarError(fechaNac, 'La fecha de nacimiento es obligatoria.');
        } else {
            const hoy = new Date();
            const fechaNacimiento = new Date(fechaNac.value);

            let edad = hoy.getFullYear() - fechaNacimiento.getFullYear();
            const mes = hoy.getMonth() - fechaNacimiento.getMonth();
            if (mes < 0 || (mes === 0 && hoy.getDate() < fechaNacimiento.getDate())) {
                edad--;
            }

            if (isNaN(edad)) {
                marcarError(fechaNac, 'La fecha de nacimiento no es válida.');
            } else if (edad < 17) {
                marcarError(fechaNac, 'Debes ser mayor de 17 años.');
            }
        }

        
        if (!telefono.value.trim()) {
            marcarError(telefono, 'El teléfono es obligatorio.');
        } else {
            const soloDigitos = telefono.value.replace(/\D/g, '');
            if (soloDigitos.length < 8) {
                marcarError(telefono, 'El teléfono debe tener al menos 8 dígitos.');
            }
        }

      
        if (!correo.value.trim()) {
            marcarError(correo, 'El correo electrónico es obligatorio.');
        } else {
            const regexCorreo = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!regexCorreo.test(correo.value.trim())) {
                marcarError(correo, 'El correo electrónico no tiene un formato válido.');
            }
        }

        
        if (!provincia.value || provincia.value === 'Seleccione una provincia') {
            marcarError(provincia, 'La provincia es obligatoria.');
        }

        if (!canton.value || canton.value === 'Seleccione un cantón') {
            marcarError(canton, 'El cantón es obligatorio.');
        }

        if (!distrito.value || distrito.value === 'Seleccione un distrito') {
            marcarError(distrito, 'El distrito es obligatorio.');
        }

      
        if (!direccion.value.trim()) {
            marcarError(direccion, 'La dirección exacta es obligatoria.');
        }

      
        if (!sexo.value) {
            marcarError(sexo, 'El sexo/género es obligatorio.');
        }

        if (!nacionalidad.value.trim()) {
            marcarError(nacionalidad, 'La nacionalidad es obligatoria.');
        }
        

        if (!esValido) {
            e.preventDefault();

          
            Swal.fire({
                icon: 'error',
                title: 'Revisa la información',
                html: '<ul style="text-align:left;">' +
                    mensajesErrores.map(m => `<li>${m}</li>`).join('') +
                    '</ul>',
                confirmButtonText: 'Aceptar'
            });
        } else {
          
            e.preventDefault(); 

            Swal.fire({
                icon: 'question',
                title: 'Confirmar actualización',
                text: '¿Deseas guardar los cambios en tu información personal?',
                showCancelButton: true,
                confirmButtonText: 'Sí, guardar',
                cancelButtonText: 'Cancelar'
            }).then((result) => {
                if (result.isConfirmed) {
                    form.submit(); 
                }
            });
        }
    });

    function limpiarErrores() {
        const camposInvalidos = document.querySelectorAll('#ActualizarPerfil .is-invalid');
        camposInvalidos.forEach(c => c.classList.remove('is-invalid'));

        const mensajes = document.querySelectorAll('#ActualizarPerfil .invalid-feedback');
        mensajes.forEach(m => m.remove());
    }


    const inputFecha = document.getElementById('FechaNacimientoPerfil');

    if (!inputFecha) return;

   
    inputFecha.max = calcularFechaMaxima();

  
    const añoMinimo = new Date().getFullYear() - 100;
    inputFecha.min = `${añoMinimo}-01-01`;

    inputFecha.addEventListener('change', function () {
        const fechaSeleccionada = this.value;

        if (!fechaSeleccionada) {
            this.setCustomValidity('Por favor, seleccione su fecha de nacimiento');
            return;
        }

        if (!validarEdad(fechaSeleccionada)) {
            this.setCustomValidity('Debe ser mayor de 17 años para registrarse');
            this.reportValidity();
        } else {
            this.setCustomValidity('');
        }
    });

    const form = inputFecha.closest('form');
    if (form) {
        form.addEventListener('submit', function (e) {
            const fechaSeleccionada = inputFecha.value;

            if (!fechaSeleccionada || !validarEdad(fechaSeleccionada)) {
                e.preventDefault();
                inputFecha.setCustomValidity('Debes tener al menos 17 años');
                inputFecha.reportValidity();
            }
        });
    }
});