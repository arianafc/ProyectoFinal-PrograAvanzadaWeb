$(document).ready(function () {
    const urlParams = new URLSearchParams(window.location.search);
    const idVacante = urlParams.get('idVacante');
    const idUsuario = urlParams.get('idUsuario');

    // Función para agregar comentario
    $("#btnAgregarComentario").on("click", function (event) {
        event.preventDefault();

        let comentarioInput = $("#comentarioProceso");
        let comentario = comentarioInput.val().trim();

        if (comentario === "") {
            Swal.fire({
                icon: "warning",
                title: "Comentario requerido",
                text: "Debes escribir un comentario antes de continuar.",
                confirmButtonColor: "#2D594D"
            });
            comentarioInput.focus();
            return;
        }

        if (!idVacante || !idUsuario) {
            Swal.fire({
                icon: "error",
                title: "Error",
                text: "No se pudieron obtener los datos necesarios. Recarga la página e inténtalo de nuevo.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        Swal.fire({
            title: 'Guardando comentario...',
            allowOutsideClick: false,
            didOpen: () => {
                Swal.showLoading();
            }
        });

        $.ajax({
            url: '/Practicas/AgregarComentario',
            type: 'POST',
            data: {
                idVacante: parseInt(idVacante),
                idUsuario: parseInt(idUsuario),
                comentario: comentario
            },
            success: function (response) {
                var esExitoso = response.success || response.exito;

                if (esExitoso) {
                    Swal.fire({
                        icon: "success",
                        title: "Comentario agregado",
                        text: response.message || response.mensaje || "Comentario agregado correctamente",
                        confirmButtonColor: "#2D594D"
                    }).then(() => {
                        $('#modalAgregarComentario').modal('hide');
                        comentarioInput.val('');
                        window.location.reload();
                    });
                } else {
                    Swal.fire({
                        icon: "error",
                        title: "Error",
                        text: response.message || response.mensaje || "No se pudo agregar el comentario",
                        confirmButtonColor: "#2D594D"
                    });
                }
            },
            error: function (xhr) {
                let errorMessage = "No se pudo guardar el comentario. Inténtalo de nuevo.";

                try {
                    let jsonResponse = JSON.parse(xhr.responseText);
                    if (jsonResponse && (jsonResponse.message || jsonResponse.mensaje)) {
                        errorMessage = jsonResponse.message || jsonResponse.mensaje;
                    }
                } catch (e) {
                    if (xhr.status === 404) {
                        errorMessage = "La función no está disponible. Contacta al administrador.";
                    } else if (xhr.status === 500) {
                        errorMessage = "Error en el servidor. Inténtalo más tarde.";
                    }
                }

                Swal.fire({
                    icon: "error",
                    title: "Error de conexión",
                    text: errorMessage,
                    confirmButtonColor: "#2D594D"
                });
            }
        });
    });

    // Función para actualizar estado
    $("#btnActualizarEstado").on("click", function (event) {
        event.preventDefault();

        let comentarioInput = $("#comentarioEstado");
        let estadoSelect = $("#nuevoEstado");
        let comentario = comentarioInput.val().trim();
        let nuevoEstado = estadoSelect.val();

        if (nuevoEstado === "" || nuevoEstado === null) {
            Swal.fire({
                icon: "warning",
                title: "Estado requerido",
                text: "Debes seleccionar un nuevo estado.",
                confirmButtonColor: "#2D594D"
            });
            estadoSelect.focus();
            return;
        }

        if (comentario === "") {
            Swal.fire({
                icon: "warning",
                title: "Comentario requerido",
                text: "Debes escribir un comentario antes de actualizar el estado.",
                confirmButtonColor: "#2D594D"
            });
            comentarioInput.focus();
            return;
        }

        let idPractica = $("#idPractica").val();

        if (!idPractica || idPractica === '0') {
            Swal.fire({
                icon: "error",
                title: "Error",
                text: "No se pudo obtener la información de la práctica. Recarga la página e inténtalo de nuevo.",
                confirmButtonColor: "#2D594D"
            });
            return;
        }

        Swal.fire({
            title: 'Actualizando estado...',
            text: 'Por favor espera...',
            allowOutsideClick: false,
            didOpen: () => {
                Swal.showLoading();
            }
        });

        $.ajax({
            url: '/Practicas/ActualizarEstadoPractica',
            type: 'POST',
            data: {
                idPractica: idPractica,
                idEstado: nuevoEstado,
                comentario: comentario
            },
            success: function (response) {
                var esExitoso = response.success || response.exito;

                if (esExitoso) {
                    var mensaje = response.message || response.mensaje || "Estado actualizado correctamente";
                    var estadoNuevo = response.data?.estado || '';

                    Swal.fire({
                        icon: "success",
                        title: "Estado actualizado",
                        html: `<p>${mensaje}</p>
                               ${estadoNuevo ? '<small><strong>Nuevo estado:</strong> ' + estadoNuevo + '</small>' : ''}`,
                        confirmButtonColor: "#2D594D"
                    }).then(() => {
                        $('#modalActualizarEstado').modal('hide');
                        window.location.reload();
                    });
                } else {
                    Swal.fire({
                        icon: "warning",
                        title: "No se puede actualizar",
                        html: response.message || response.mensaje || "No se pudo actualizar el estado",
                        confirmButtonText: "Entendido",
                        confirmButtonColor: "#2D594D"
                    });
                }
            },
            error: function (xhr) {
                let errorMessage = "No se pudo actualizar el estado. Inténtalo de nuevo.";

                try {
                    let jsonResponse = JSON.parse(xhr.responseText);
                    if (jsonResponse && (jsonResponse.message || jsonResponse.mensaje)) {
                        errorMessage = jsonResponse.message || jsonResponse.mensaje;
                    }
                } catch (e) {
                    if (xhr.status === 404) {
                        errorMessage = "La función no está disponible. Contacta al administrador.";
                    } else if (xhr.status === 500) {
                        errorMessage = "Error en el servidor. Inténtalo más tarde.";
                    }
                }

                Swal.fire({
                    icon: "error",
                    title: "Error de conexión",
                    text: errorMessage,
                    confirmButtonColor: "#2D594D"
                });
            }
        });
    });

    // Limpiar formularios cuando se cierren los modales
    $('#modalAgregarComentario').on('hidden.bs.modal', function () {
        $('#comentarioProceso').val('');
    });

    $('#modalActualizarEstado').on('hidden.bs.modal', function () {
        $('#comentarioEstado').val('');
        $('#nuevoEstado').val('');
    });
});