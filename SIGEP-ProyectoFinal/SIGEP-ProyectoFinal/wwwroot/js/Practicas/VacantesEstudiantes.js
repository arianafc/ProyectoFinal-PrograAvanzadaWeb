(function ($) {
    $(function () {

        // =====================================================
        // 🔹 Configuración global
        // =====================================================
        const CFG = window.VacantesCfg || { urls: {}, rol: 0 };

        // =====================================================
        // 🔹 Helpers
        // =====================================================

        // Redirige al login si el servidor devolvió HTML (vista de login / error)
        function redirSiLogin(res, xhr) {
            try {
                const ct = (xhr && xhr.getResponseHeader && xhr.getResponseHeader('content-type')) || '';

                if ((typeof res === 'string' && res.indexOf('<!DOCTYPE html') >= 0) ||
                    (ct && ct.indexOf('text/html') >= 0)) {
                    window.location.href = CFG.urls.login;
                    return true;
                }
            } catch (e) { }

            return false;
        }

        // Escapar HTML para evitar XSS
        function escapeHtml(text) {
            if (!text && text !== 0) return '';
            return $('<div>').text(text).html();
        }

        // Normaliza texto de estado
        function normalizarEstado(str) {
            return (str || '')
                .toString()
                .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
                .toLowerCase()
                .replace(/\s+/g, ' ')
                .trim();
        }

        // Badge visual según estado
        function badgeEstado(estadoOriginal) {
            const est = normalizarEstado(estadoOriginal);

            const mapa = {
                'en proceso de aplicacion': { cls: 'badge-en-progreso', txt: 'En proceso de Aplicación' },
                'rechazada': { cls: 'badge-rechazada', txt: 'Rechazada' },
                'asignada': { cls: 'badge-asignada', txt: 'Asignada' },
                'aprobada': { cls: 'badge-aprobada', txt: 'Aprobada' },
                'retirada': { cls: 'badge-retirada', txt: 'Retirada' },
                'finalizada': { cls: 'badge-finalizada', txt: 'Finalizada' },
                'rezagado': { cls: 'badge-rezagado', txt: 'Rezagado' },
                'archivado': { cls: 'badge-archivado', txt: 'Archivado' },
                'en curso': { cls: 'badge-en-curso', txt: 'En Curso' },
                'activo': { cls: 'badge-activo', txt: 'Activo' },
                'inactivo': { cls: 'badge-inactivo', txt: 'Inactivo' },
                'sin proceso activo': { cls: 'badge-no-asignada', txt: 'Sin proceso activo' }
            };

            const info = mapa[est] || { cls: 'badge-no-asignada', txt: estadoOriginal || '—' };
            return `<span class="badge ${info.cls}">${info.txt}</span>`;
        }

        // Valida que la fecha de aplicación no sea mayor que la de cierre
        function validarFechas(fechaAplic, fechaCierre) {
            if (!fechaAplic || !fechaCierre) return false;

            const f1 = new Date(fechaAplic);
            const f2 = new Date(fechaCierre);

            return f1 && f2 && f1 > f2;
        }

        // =====================================================
        // 🔹 DataTable principal
        // =====================================================

        const tabla = $('#miTabla').DataTable({
            responsive: true,
            processing: true,
            ajax: {
                url: CFG.urls.getVacantes,
                type: 'GET',
                cache: false,
                dataType: 'json',
                data: function () {
                    return {
                        idEstado: $('#filtroPractica').val() || 0,
                        idEspecialidad: $('#filtroEspecialidad').val() || 0,
                        idModalidad: $('#filtroModalidad').val() || 0
                    };
                },
                dataSrc: function (json) {

                    // Si el servidor devolvió HTML, avisamos
                    if (typeof json === 'string') {
                        if (json.indexOf('<!DOCTYPE html') >= 0 || json.indexOf('<html') >= 0) {
                            Swal.fire('Error', 'La sesión puede haber expirado o el servidor devolvió HTML.', 'error');
                            return [];
                        }

                        try {
                            json = JSON.parse(json);
                        } catch (e) {
                            Swal.fire('Error', 'Respuesta no válida del servidor.', 'error');
                            return [];
                        }
                    }

                    if (json && json.ok === false) {
                        Swal.fire('Error', json.error || 'Error en servidor.', 'error');
                        return [];
                    }

                    return (json && Array.isArray(json.data)) ? json.data : [];
                },
                error: function (xhr) {
                    const ct = xhr.getResponseHeader('content-type') || '';
                    if (ct.indexOf('text/html') >= 0) {
                        Swal.fire('Error', 'Se recibió HTML en lugar de JSON (¿login/500?).', 'error');
                    } else {
                        Swal.fire('Error', `Error consultando vacantes (${xhr.status}).`, 'error');
                    }
                }
            },
            columns: [
                { data: 'EmpresaNombre', title: 'Empresa' },
                { data: 'EspecialidadNombre', title: 'Especialidad' },
                { data: 'Requerimientos', title: 'Requisitos' },
                { data: 'NumCupos', title: 'Cupos Disponibles' },
                {
                    data: 'NumPostulados',
                    title: 'Estudiantes Postulados',
                    render: function (d) {
                        return `<strong>${d || 0}</strong>`;
                    }
                },
                {
                    data: 'EstadoNombre',
                    title: 'Estado',
                    render: function (d) {
                        return badgeEstado(d);
                    }
                },
                {
                    data: 'IdVacante',
                    orderable: false,
                    title: 'Acciones',
                    render: function (data, type, row) {

                        const estado = normalizarEstado(row.EstadoNombre);
                        const inactivo = (estado === 'inactivo' || estado === 'archivado');
                        const dis = inactivo ? 'disabled aria-disabled="true"' : '';
                        const muted = inactivo ? 'opacity:0.35; cursor:not-allowed;' : '';

                        const nombreVacante = (row.Nombre || '').toString().toLowerCase();
                        const autog = nombreVacante.includes('práctica autogestionada') ||
                            nombreVacante.includes('practica autogestionada');

                        let acc = `
                            <button class="btn bg-transparent btn-accion btn-visualizar"
                                    data-id="${data}"
                                    title="Visualizar"
                                    style="color:#2d594d">
                                <i class="fas fa-eye"></i>
                            </button>`;

                        if (!autog) {
                            acc += `
                                <button class="btn bg-transparent btn-accion btn-asignar"
                                        data-id="${data}"
                                        style="color:#2d594d; ${muted}" ${dis}>
                                    <i class="fas fa-user-plus"></i>
                                </button>`;
                        }

                        acc += `
                            <button class="btn bg-transparent btn-accion btn-editar"
                                    data-id="${data}"
                                    style="color:#2d594d; ${muted}" ${dis}>
                                <i class="fas fa-sync-alt"></i>
                            </button>
                            <button class="btn btn-accion toggle btn-eliminar"
                                    data-id="${data}"
                                    style="color:#2d594d; ${muted}" ${dis}>
                                <i class="fas fa-archive"></i>
                            </button>`;

                        return acc;
                    }
                }
            ],
            language: { url: "//cdn.datatables.net/plug-ins/1.13.6/i18n/es-ES.json" }
        });

        // Filtros de búsqueda
        $('#filtroPractica, #filtroEspecialidad, #filtroModalidad')
            .on('change', function () {
                tabla.ajax.reload();
            });

        // =====================================================
        // 🔹 Ubicación empresa en Crear / Editar
        // =====================================================

        $('#IdEmpresa, #edit-IdEmpresa').on('change', function () {
            const idEmpresa = $(this).val();
            const $inputUbicacion = $(this).attr('id') === 'IdEmpresa'
                ? $('#ubicacionEmpresa')
                : $('#edit-Ubicacion');

            if (!idEmpresa) {
                $inputUbicacion.val('');
                return;
            }

            $.getJSON(CFG.urls.getUbicacionEmpresa, { idEmpresa: idEmpresa })
                .done(function (res) {
                    if (res && res.ok) {
                        $inputUbicacion.val(res.ubicacion);
                    } else {
                        $inputUbicacion.val('No registrada');
                    }
                })
                .fail(function () {
                    $inputUbicacion.val('Error al obtener ubicación');
                });
        });

        // =====================================================
        // 🔹 Crear Vacante
        // =====================================================

        $('#formCrearVacante').on('submit', function (e) {
            e.preventDefault();

            const nombre = $('[name="Nombre"]').val().trim();
            const idEmpresa = $('[name="IdEmpresa"]').val();
            const requerimientos = $('[name="Requerimientos"]').val().trim();
            const numCupos = parseInt($('[name="NumCupos"]').val()) || 0;
            const idEspecialidad = $('[name="IdEspecialidad"]').val();
            const idModalidad = $('[name="IdModalidad"]').val();
            const fechaAplic = $('[name="FechaMaxAplicacion"]').val();
            const fechaCierre = $('[name="FechaCierre"]').val();

            if (!nombre || !idEmpresa || !requerimientos || numCupos < 1 || !idEspecialidad || !idModalidad) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Campos obligatorios',
                    text: 'Debe completar todos los campos requeridos.'
                });
                return false;
            }

            if (validarFechas(fechaAplic, fechaCierre)) {
                Swal.fire({
                    icon: 'warning',
                    title: 'Fechas inválidas',
                    text: 'La fecha de aplicación no puede ser mayor que la de cierre.'
                });
                return false;
            }

            const formData = $(this).serialize();

            $.ajax({
                url: CFG.urls.crear,
                type: 'POST',
                data: formData,
                success: function (res, status, xhr) {
                    if (redirSiLogin(res, xhr)) return;

                    if (res.ok) {
                        Swal.fire('Éxito', res.message || 'Vacante creada correctamente.', 'success')
                            .then(function () {
                                $('#modalCrearVacante').modal('hide');
                                $('#formCrearVacante')[0].reset();
                                tabla.ajax.reload(null, false);
                            });
                    } else {
                        Swal.fire('Error', res.message || 'No se pudo crear la vacante.', 'error');
                    }
                },
                error: function () {
                    Swal.fire('Error', 'Error al crear la vacante.', 'error');
                }
            });
        });

        // =====================================================
        // 🔹 Visualizar Vacante + Postulaciones
        // =====================================================

        $('#miTabla').on('click', '.btn-visualizar', function () {
            const id = $(this).data('id');

            $.get(CFG.urls.detalle, { id: id }, function (res, _, xhr) {
                if (redirSiLogin(res, xhr)) return;

                if (!res.ok || !res.data) {
                    Swal.fire('Error', 'No se pudo cargar la vacante.', 'error');
                    return;
                }

                const d = res.data;

                $('#vis-Nombre').val(d.Nombre);
                $('#vis-Empresa').val(d.IdEmpresa);
                $('#vis-Ubicacion').val(d.Ubicacion);
                $('#vis-Especialidad').val(d.IdEspecialidad);
                $('#vis-NumCupos').val(d.NumCupos);
                $('#vis-Modalidad').val(d.IdModalidad);
                $('#vis-Requerimientos').val(d.Requerimientos);
                $('#vis-Descripcion').val(d.Descripcion);
                $('#vis-FechaAplicacion').val(d.FechaMaxAplicacion ? d.FechaMaxAplicacion.split('T')[0] : '');
                $('#vis-FechaCierre').val(d.FechaCierre ? d.FechaCierre.split('T')[0] : '');

                $('#modalVisualizarVacante').data('idVacante', id);
                $('#modalVisualizarVacante').modal('show');

                // Postulaciones
                $.getJSON(CFG.urls.obtenerPostulaciones, { idVacante: id }, function (r2) {
                    const $lista = $('#listaPostulaciones').empty();
                    $('#mensajeSinPostulaciones').toggle(!r2.ok || !r2.data || !r2.data.length);

                    if (r2.ok && r2.data && r2.data.length) {
                        r2.data.forEach(function (p) {
                            const estado = p.EstadoDescripcion || 'Sin estado';
                            const badge = badgeEstado(estado);

                            $lista.append(`
                                <li class="d-flex justify-content-between align-items-center p-2 border rounded mb-2">
                                    <div>
                                        <a href="${CFG.urls.visualizacionPostulacion}?idVacante=${p.IdVacante}&idUsuario=${p.IdUsuario}"
                                           class="text-decoration-none fw-bold"
                                           style="color:#2d594d;">
                                            ${escapeHtml(p.NombreCompleto)}
                                        </a>
                                    </div>
                                    <div class="d-flex align-items-center gap-2">${badge}</div>
                                </li>`);
                        });
                    }
                });

            });
        });

        // =====================================================
        // 🔹 Helper: cargar estudiantes para asignar
        // =====================================================

        function cargarEstudiantesAsignar(idVacante) {

            $.getJSON(CFG.urls.obtenerEstudiantesAsignar, {
                idVacante: idVacante,
                idUsuarioSesion: CFG.idUsuarioSesion || 0
            }, function (res) {

                const tbody = $('#miTablaAsignar tbody').empty();
                $('[title]').tooltip({ placement: 'top', trigger: 'hover' });

                if (!res || !res.ok || !res.data || !res.data.length) {
                    tbody.append('<tr><td colspan="5" class="text-center text-muted">No hay estudiantes disponibles</td></tr>');
                    return;
                }

                res.data.forEach(function (e) {

                    const estadoVacante = normalizarEstado(e.EstadoVacante || e.EstadoPractica || 'Sin proceso activo');
                    let estadoMostrar = e.EstadoVacante || e.EstadoPractica || 'Sin proceso activo';

                    if ((e.TipoMensaje || '').toLowerCase() === 'autogestionada') {
                        if (!estadoMostrar.toLowerCase().includes('autogestionada')) {
                            estadoMostrar += ' (Autogestionada)';
                        }
                    }

                    const badge = badgeEstado(estadoMostrar);
                    const estadoAcademico = parseInt(e.EstadoAcademico || 0);
                    let btn = '';

                    // Estado académico 9: ignorar
                    if (estadoAcademico === 9) {
                        return;
                    }

                    if (['sin proceso activo', 'retirada', 'en proceso de aplicacion'].includes(estadoVacante)) {

                        btn = `<button class="btn btn-sm btn-asignar-estudiante"
                               data-idusuario="${e.IdUsuario}"
                               data-nombre="${escapeHtml(e.NombreCompleto)}"
                               title="Asignar o confirmar asignación"
                               style="background:none; border:none; color:#198754;">
                            <i class="fas fa-user-plus fa-lg"></i>
                        </button>`;

                    } else if (estadoVacante === 'asignada') {

                        btn = `<button class="btn btn-sm btn-retirar-estudiante"
                               data-idusuario="${e.IdUsuario}"
                               data-idpractica="${e.IdPracticaVacante || e.idPracticaVacante || 0}"
                               data-nombre="${escapeHtml(e.NombreCompleto)}"
                               title="Retirar estudiante"
                               style="background:none; border:none; color:#dc3545;">
                            <i class="fas fa-trash-alt fa-lg"></i>
                        </button>`;

                    } else if (['en curso', 'finalizada', 'rezagado', 'rechazada', 'aprobada'].includes(estadoVacante)) {

                        btn = `<button class="btn btn-sm btn-bloqueado"
                               title="No puede ser asignado"
                               style="background:none; border:none; color:#6c757d;" disabled>
                            <i class="fas fa-ban fa-lg"></i>
                        </button>`;

                    } else {

                        btn = `<button class="btn btn-sm" disabled
                               title="Estado desconocido"
                               style="background:none; border:none; color:#6c757d;">
                            <i class="fas fa-question fa-lg"></i>
                        </button>`;
                    }

                    tbody.append(`
                        <tr>
                            <td>${escapeHtml(e.NombreCompleto)}</td>
                            <td>${escapeHtml(e.Cedula || '')}</td>
                            <td>${escapeHtml(e.Especialidad || '')}</td>
                            <td class="text-center">${badge}</td>
                            <td class="text-center">${btn}</td>
                        </tr>`);
                });
            });
        }

        // =====================================================
        // 🔹 Abrir modal Asignar
        // =====================================================

        $('#miTabla').on('click', '.btn-asignar', function () {
            const idVacante = $(this).data('id');
            $('#modalAsignar').data('idVacante', idVacante).modal('show');
            cargarEstudiantesAsignar(idVacante);
        });

        // =====================================================
        // 🔹 Asignar estudiante
        // =====================================================

        $(document).on('click', '.btn-asignar-estudiante', function () {
            const idUsuario = $(this).data('idusuario');
            const idVacante = $('#modalAsignar').data('idVacante');
            const nombre = $(this).data('nombre');

            Swal.fire({
                title: 'Confirmar acción',
                html: `¿Deseas asignar la vacante al estudiante <b>${nombre}</b>?<br>
                       <small>Primer clic: "En proceso de aplicación"<br>
                       Segundo clic: "Asignada"</small>`,
                icon: 'question',
                showCancelButton: true,
                confirmButtonText: 'Sí, continuar',
                cancelButtonText: 'Cancelar',
                confirmButtonColor: '#2d594d'
            }).then(function (r) {
                if (!r.isConfirmed) return;

                $.post(CFG.urls.asignarEstudiante, { idUsuario: idUsuario, idVacante: idVacante })
                    .done(function (res) {
                        if (!res) {
                            Swal.fire('Error', 'Sin respuesta del servidor.', 'error');
                            return;
                        }

                        if (res.ok) {
                            Swal.fire({
                                icon: 'success',
                                title: 'Éxito',
                                text: res.message || 'Acción completada correctamente.',
                                timer: 2000,
                                showConfirmButton: false
                            });

                            cargarEstudiantesAsignar(idVacante);
                            tabla.ajax.reload(null, false);
                        } else {
                            Swal.fire('Aviso', res.message || 'No se pudo completar la acción.', 'warning');
                        }
                    })
                    .fail(function () {
                        Swal.fire('Error', 'Error de conexión al servidor.', 'error');
                    });
            });
        });

        // =====================================================
        // 🔹 Retirar estudiante
        // =====================================================

        $(document).on('click', '.btn-retirar-estudiante', function () {
            const idVacante = $('#modalAsignar').data('idVacante');
            const idUsuario = $(this).data('idusuario');
            const idPractica = $(this).data('idpractica') || 0;
            const nombre = $(this).data('nombre') || '—';
            const estadoAcademico = $(this).data('estadoacademico') || 'Activo';

            const modal = document.getElementById('modalAsignar');
            const modalInstance = modal ? bootstrap.Modal.getInstance(modal) : null;

            if (modalInstance && modalInstance._focustrap) {
                modalInstance._focustrap.deactivate();
            }

            Swal.fire({
                title: '¿Deseas desasignar esta práctica?',
                html: `
                    <div style="font-size:15px;line-height:1.5;">
                        El estudiante <b style="color:#2d594d;">${nombre}</b><br>
                        <small>Estado académico actual: <b>${estadoAcademico}</b></small><br><br>
                        Pasará al estado de práctica <b>"Retirada"</b>.
                    </div>`,
                icon: 'warning',
                input: 'textarea',
                inputLabel: 'Comentario (obligatorio)',
                inputPlaceholder: 'Escribe el motivo de la desasignación...',
                showCancelButton: true,
                confirmButtonText: 'Sí, desasignar',
                cancelButtonText: 'Cancelar',
                confirmButtonColor: '#2d594d',
                allowOutsideClick: false,
                preConfirm: function (value) {
                    if (!value || !value.trim()) {
                        Swal.showValidationMessage('⚠️ Debes ingresar el motivo de la desasignación.');
                    }
                }
            }).then(function (result) {

                if (!result.isConfirmed) {
                    if (modalInstance && modalInstance._focustrap) {
                        modalInstance._focustrap.activate();
                    }
                    return;
                }

                const comentario = result.value.trim();
                const url = idPractica > 0 ? CFG.urls.desasignarPractica : CFG.urls.retirarEstudiante;
                const data = idPractica > 0
                    ? { idPractica: idPractica, comentario: comentario }
                    : { idVacante: idVacante, idUsuario: idUsuario, comentario: comentario };

                $.post(url, data)
                    .done(function (res) {
                        if (res.ok) {
                            Swal.fire({
                                icon: 'success',
                                title: 'Desasignado correctamente',
                                text: res.msg || res.message || 'La práctica fue desasignada exitosamente.',
                                timer: 1800,
                                showConfirmButton: false
                            });

                            cargarEstudiantesAsignar(idVacante);
                            tabla.ajax.reload(null, false);
                        } else {
                            Swal.fire('Error', res.msg || res.message || 'No se pudo desasignar la práctica.', 'error');
                        }
                    })
                    .fail(function () {
                        Swal.fire('Error', 'Error de conexión al servidor.', 'error');
                    })
                    .always(function () {
                        if (modalInstance && modalInstance._focustrap) {
                            modalInstance._focustrap.activate();
                        }
                    });
            });
        });

        // =====================================================
        // 🔹 Botón bloqueado
        // =====================================================

        $(document).on('click', '.btn-bloqueado', function () {
            Swal.fire({
                icon: 'warning',
                title: 'Estudiante no disponible',
                text: 'Este estudiante ya tiene una práctica activa o completada y no puede ser asignado.'
            });
        });

        // =====================================================
        // 🔹 Editar Vacante
        // =====================================================

        $('#miTabla').on('click', '.btn-editar', function () {
            const id = $(this).data('id');

            $.get(CFG.urls.detalle, { id: id }, function (res, _, xhr) {
                if (redirSiLogin(res, xhr)) return;

                if (!res.ok || !res.data) {
                    Swal.fire('Error', 'No se pudo cargar la información.', 'error');
                    return;
                }

                const d = res.data;

                $('#edit-IdVacante').val(d.IdVacante);
                $('#edit-Nombre').val(d.Nombre);
                $('#edit-IdEmpresa').val(d.IdEmpresa);
                $('#edit-Ubicacion').val(d.Ubicacion);
                $('#edit-IdEspecialidad').val(d.IdEspecialidad);
                $('#edit-NumCupos').val(d.NumCupos);
                $('#edit-IdModalidad').val(d.IdModalidad);
                $('#edit-Requerimientos').val(d.Requerimientos);
                $('#edit-Descripcion').val(d.Descripcion);
                $('#edit-FechaMaxAplicacion').val(d.FechaMaxAplicacion ? d.FechaMaxAplicacion.split('T')[0] : '');
                $('#edit-FechaCierre').val(d.FechaCierre ? d.FechaCierre.split('T')[0] : '');

                $('#modalEditarVacante').modal('show');
            });
        });

        $('#formEditarVacante').on('submit', function (e) {
            e.preventDefault();

            const fAplic = $('#edit-FechaMaxAplicacion').val();
            const fCierre = $('#edit-FechaCierre').val();

            if (validarFechas(fAplic, fCierre)) {
                Swal.fire('Fechas inválidas', 'La fecha de aplicación no puede ser mayor que la de cierre.', 'warning');
                return false;
            }

            $.post(CFG.urls.editar, $(this).serialize())
                .done(function (res, _, xhr) {
                    if (redirSiLogin(res, xhr)) return;

                    if (res.ok) {
                        Swal.fire('Éxito', res.message, 'success');
                        $('#modalEditarVacante').modal('hide');
                        tabla.ajax.reload(null, false);
                    } else {
                        Swal.fire('Error', res.message, 'error');
                    }
                })
                .fail(function () {
                    Swal.fire('Error', 'Ocurrió un problema al actualizar.', 'error');
                });
        });

        // =====================================================
        // 🔹 Eliminar / Archivar Vacante
        // =====================================================

        $('#miTabla').on('click', '.btn-eliminar', function () {
            const id = $(this).data('id');

            Swal.fire({
                title: '¿Deseas archivar esta vacante?',
                text: 'Solo se archivará si no tiene estudiantes activos.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#2d594d',
                confirmButtonText: 'Sí, archivar',
                cancelButtonText: 'Cancelar'
            }).then(function (r) {
                if (!r.isConfirmed) return;

                $.post(CFG.urls.eliminar, { id: id })
                    .done(function (res, _, xhr) {
                        if (redirSiLogin(res, xhr)) return;

                        if (res.ok) {
                            Swal.fire('Éxito', res.message, 'success');
                            tabla.ajax.reload(null, false);
                        } else {
                            Swal.fire('Aviso', res.message, 'warning');
                        }
                    })
                    .fail(function () {
                        Swal.fire('Error', 'Error al archivar la vacante.', 'error');
                    });
            });
        });

        // =====================================================
        // 🔹 Desasignar desde modal Visualizar
        // =====================================================

        $(document).on('click', '.BtnDesasignarPracticaEstudiante', function (e) {
            e.preventDefault();

            const idPractica = $(this).data('idpractica');
            const nombreEst = $(this).data('nombre');
            const idVacante = $('#modalVisualizarVacante').data('idVacante');

            if (!idPractica) {
                Swal.fire('Error', 'No se encontró el identificador de la práctica.', 'error');
                return;
            }

            const modalVisual = document.getElementById('modalVisualizarVacante');
            const modalInstance = modalVisual ? bootstrap.Modal.getInstance(modalVisual) : null;

            if (modalInstance && modalInstance._focustrap) {
                modalInstance._focustrap.deactivate();
            }

            Swal.fire({
                title: '¿Deseas desasignar esta práctica?',
                html: `
                    <p>El estado de <b>${escapeHtml(nombreEst || 'el estudiante')}</b> se cambiará a <b>"Retirada"</b>.</p>
                `,
                icon: 'warning',
                input: 'textarea',
                inputLabel: 'Comentario (opcional)',
                inputPlaceholder: 'Escribe el motivo de la desasignación...',
                inputAttributes: { maxlength: 500 },
                showCancelButton: true,
                confirmButtonText: 'Sí, desasignar',
                cancelButtonText: 'Cancelar',
                confirmButtonColor: '#2d594d',
                allowOutsideClick: false,
                didOpen: function () {
                    const textarea = Swal.getInput();
                    if (textarea) {
                        setTimeout(function () { textarea.focus(); }, 150);
                    }
                }
            }).then(function (result) {
                if (!result.isConfirmed) {
                    if (modalInstance && modalInstance._focustrap) {
                        modalInstance._focustrap.activate();
                    }
                    return;
                }

                const comentario = (result.value || '').trim();

                $.ajax({
                    url: CFG.urls.desasignarPractica,
                    type: 'POST',
                    data: {
                        idPractica: idPractica,
                        comentario: comentario
                    },
                    success: function (res, status, xhr) {
                        if (redirSiLogin(res, xhr)) return;

                        if (res.ok) {
                            Swal.fire({
                                title: 'Desasignado',
                                text: res.msg || 'La práctica fue desasignada correctamente.',
                                icon: 'success',
                                timer: 1500,
                                showConfirmButton: false
                            }).then(function () {

                                // Refrescar lista de postulaciones
                                $.getJSON(CFG.urls.obtenerPostulaciones, { idVacante: idVacante }, function (r2) {
                                    const $lista = $('#listaPostulaciones').empty();
                                    $('#mensajeSinPostulaciones').toggle(!r2.ok || !r2.data || !r2.data.length);

                                    if (r2.ok && r2.data && r2.data.length) {

                                        r2.data.forEach(function (p) {
                                            const estado = p.EstadoDescripcion || 'Sin estado';
                                            const estNorm = normalizarEstado(estado);
                                            const badge = badgeEstado(estado);
                                            const mostrarBoton =
                                                ['asignada', 'en proceso de aplicacion'].includes(estNorm);

                                            const btnDes = mostrarBoton
                                                ? `<button class="btn bg-transparent BtnDesasignarPracticaEstudiante"
                                                           data-idpractica="${p.IdPractica}"
                                                           data-nombre="${escapeHtml(p.NombreCompleto)}"
                                                           title="Desasignar práctica"
                                                           style="color:#2D594D;">
                                                       <i class="fas fa-trash-alt"></i>
                                                   </button>`
                                                : '';

                                            $lista.append(`
                                                <li class="d-flex justify-content-between align-items-center p-2 border rounded mb-2">
                                                    <div>
                                                        <a href="${CFG.urls.visualizacionPostulacion}?idVacante=${p.IdVacante}&idUsuario=${p.IdUsuario}"
                                                           class="text-decoration-none fw-bold"
                                                           style="color:#2d594d;">
                                                            ${escapeHtml(p.NombreCompleto)}
                                                        </a>
                                                    </div>
                                                    <div class="d-flex align-items-center gap-2">${badge}${btnDes}</div>
                                                </li>`);
                                        });
                                    }

                                    if (typeof tabla !== 'undefined') {
                                        tabla.ajax.reload(null, false);
                                    }
                                });

                                if (modalInstance && modalInstance._focustrap) {
                                    modalInstance._focustrap.activate();
                                }
                            });
                        } else {
                            Swal.fire('Error', res.msg || 'No se pudo desasignar la práctica.', 'error');
                        }
                    },
                    error: function () {
                        Swal.fire('Error', 'Ocurrió un error al procesar la solicitud.', 'error');
                    },
                    complete: function () {
                        if (modalInstance && modalInstance._focustrap) {
                            modalInstance._focustrap.activate();
                        }
                    }
                });
            });
        });

    });
})(jQuery);
