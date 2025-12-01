(function ($) {
    $(function () {

        // =====================================================
        // 🔹 Configuración global
        // =====================================================
        const CFG = window.VacantesCfg || { urls: {}, rol: 0 };

        console.log('[VacantesEstudiantes] CFG cargado:', CFG);

        // =====================================================
        // 🔹 Helpers
        // =====================================================

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

        function escapeHtml(text) {
            if (!text && text !== 0) return '';
            return $('<div>').text(text).html();
        }

        function normalizarEstado(str) {
            return (str || '')
                .toString()
                .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
                .toLowerCase()
                .replace(/\s+/g, ' ')
                .trim();
        }

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
                // ✅ USA EL WEB CONTROLLER, NO EL API DIRECTO
                url: CFG.urls.getVacantes || '/Practicas/GetVacantes',
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
                    console.log('[DataTable] Respuesta recibida:', json);

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

                    // El Web Controller retorna { data: [...] }
                    if (json && Array.isArray(json.data)) {
                        return json.data;
                    }

                    // Si viene array directo del API
                    if (Array.isArray(json)) {
                        return json;
                    }

                    if (json && json.ok === false) {
                        Swal.fire('Error', json.error || 'Error en servidor.', 'error');
                        return [];
                    }

                    return [];
                },
                error: function (xhr) {
                    console.error('[DataTable] Error:', xhr);
                    const ct = xhr.getResponseHeader('content-type') || '';
                    if (ct.indexOf('text/html') >= 0) {
                        Swal.fire('Error', 'Se recibió HTML en lugar de JSON (¿login/500?).', 'error');
                    } else {
                        Swal.fire('Error', `Error consultando vacantes (${xhr.status}).`, 'error');
                    }
                }
            },
            columns: [
                {
                    data: 'empresaNombre',
                    title: 'Empresa',
                    render: function (d) {
                        return d || '—';
                    }
                },
                {
                    data: 'especialidadNombre',
                    title: 'Especialidad',
                    render: function (d) {
                        return d || '—';
                    }
                },
                {
                    data: 'requerimientos',
                    title: 'Requisitos',
                    render: function (d) {
                        return d || '—';
                    }
                },
                {
                    data: 'numCupos',
                    title: 'Cupos Disponibles',
                    render: function (d) {
                        return d || 0;
                    }
                },
                {
                    data: 'numPostulados',
                    title: 'Estudiantes Postulados',
                    render: function (d) {
                        return `<strong>${d || 0}</strong>`;
                    }
                },
                {
                    data: 'estadoNombre',
                    title: 'Estado',
                    render: function (d) {
                        return badgeEstado(d);
                    }
                },
                {
                    data: 'idVacante',
                    orderable: false,
                    title: 'Acciones',
                    render: function (data, type, row) {
                        const estado = normalizarEstado(row.estadoNombre);
                        const inactivo = (estado === 'inactivo' || estado === 'archivado');
                        const dis = inactivo ? 'disabled aria-disabled="true"' : '';
                        const muted = inactivo ? 'opacity:0.35; cursor:not-allowed;' : '';

                        const nombreVacante = (row.nombre || '').toString().toLowerCase();
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

        $('#filtroPractica, #filtroEspecialidad, #filtroModalidad')
            .on('change', function () {
                tabla.ajax.reload();
            });

        // =====================================================
        // 🔹 Ubicación empresa en Crear / Editar
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
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

            console.log('[Ubicación] Consultando empresa:', idEmpresa);

            // ✅ LLAMAR AL WEB CONTROLLER, NO AL API DIRECTO
            $.ajax({
                url: `/Practicas/GetUbicacionEmpresa?idEmpresa=${idEmpresa}`,
                type: 'GET',
                dataType: 'text', // El Web Controller retorna STRING directo
                success: function (ubicacion) {
                    console.log('[Ubicación] Recibida:', ubicacion);
                    $inputUbicacion.val(ubicacion || 'No registrada');
                },
                error: function (xhr) {
                    console.error('[Ubicación] Error:', xhr);
                    $inputUbicacion.val('Error al obtener ubicación');
                }
            });
        });

        // =====================================================
        // 🔹 Crear Vacante
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
        // =====================================================

        $('#formCrearVacante').on('submit', function (e) {
            e.preventDefault();

            const nombre = $('[name="Vacante.Nombre"]').val().trim();
            const idEmpresa = $('[name="Vacante.IdEmpresa"]').val();
            const requerimientos = $('[name="Vacante.Requerimientos"]').val().trim();
            const numCupos = parseInt($('[name="Vacante.NumCupos"]').val()) || 0;
            const idEspecialidad = $('[name="Vacante.IdEspecialidad"]').val();
            const idModalidad = $('[name="Vacante.IdModalidad"]').val();
            const fechaAplic = $('[name="Vacante.FechaMaxAplicacion"]').val();
            const fechaCierre = $('[name="Vacante.FechaCierre"]').val();

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

            const payload = {
                Nombre: nombre,
                IdEmpresa: parseInt(idEmpresa),
                IdEspecialidad: parseInt(idEspecialidad),
                NumCupos: numCupos,
                IdModalidad: parseInt(idModalidad),
                Requerimientos: requerimientos,
                Descripcion: $('[name="Vacante.Descripcion"]').val().trim(),
                FechaMaxAplicacion: fechaAplic,
                FechaCierre: fechaCierre
            };

            console.log('[Crear Vacante] Payload:', payload);

            // ✅ LLAMAR AL WEB CONTROLLER
            $.ajax({
                url: '/Practicas/Crear',
                type: "POST",
                contentType: "application/json",
                data: JSON.stringify(payload),
                success: function (resultado) {
                    console.log('[Crear Vacante] Resultado:', resultado);

                    // ✅ AGREGAR ESTA VALIDACIÓN
                    if (typeof resultado === 'string' && resultado.indexOf('<!DOCTYPE html') >= 0) {
                        Swal.fire({
                            icon: 'warning',
                            title: 'Sesión expirada',
                            text: 'Tu sesión ha expirado. Serás redirigido al login.'
                        }).then(() => {
                            window.location.href = '/Home/IniciarSesion';
                        });
                        return;
                    }

                    const idCreado = typeof resultado === 'number' ? resultado : parseInt(resultado);

                    if (idCreado > 0) {
                        Swal.fire('Éxito', 'Vacante creada correctamente.', 'success')
                            .then(function () {
                                $('#modalCrearVacante').modal('hide');
                                $('#formCrearVacante')[0].reset();
                                tabla.ajax.reload(null, false);
                            });
                    } else {
                        Swal.fire('Error', 'No se pudo crear la vacante. Verifique los datos.', 'error');
                    }
                },
                error: function (xhr) {
                    console.error('[Crear Vacante] Error:', xhr.responseText);

                    // ✅ AGREGAR VALIDACIÓN DE HTML
                    if (xhr.responseText && xhr.responseText.indexOf('<!DOCTYPE html') >= 0) {
                        Swal.fire({
                            icon: 'warning',
                            title: 'Sesión expirada',
                            text: 'Tu sesión ha expirado. Serás redirigido al login.'
                        }).then(() => {
                            window.location.href = '/Home/IniciarSesion';
                        });
                        return;
                    }

                    Swal.fire('Error', xhr.responseText || 'Error al crear la vacante.', 'error');
                }
            });
        });

        // =====================================================
        // 🔹 Visualizar Vacante + Postulaciones
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
        // =====================================================

        $('#miTabla').on('click', '.btn-visualizar', function () {
            const id = $(this).data('id');

            $.ajax({
                url: `/Practicas/Detalle?id=${id}`,
                type: 'GET',
                success: function (d) {
                    console.log('[Detalle Vacante]', d);

                    $('#vis-Nombre').val(d.Nombre || d.nombre);
                    $('#vis-Empresa').val(d.IdEmpresa || d.idEmpresa);
                    $('#vis-Ubicacion').val(d.Ubicacion || d.ubicacion || 'No registrada');
                    $('#vis-Especialidad').val(d.IdEspecialidad || d.idEspecialidad);
                    $('#vis-NumCupos').val(d.NumCupos || d.numCupos);
                    $('#vis-Modalidad').val(d.IdModalidad || d.idModalidad);
                    $('#vis-Requerimientos').val(d.Requerimientos || d.requisitos);
                    $('#vis-Descripcion').val(d.Descripcion || d.descripcion);
                    $('#vis-FechaAplicacion').val(d.FechaMaxAplicacion ? d.FechaMaxAplicacion.split('T')[0] : '');
                    $('#vis-FechaCierre').val(d.FechaCierre ? d.FechaCierre.split('T')[0] : '');

                    $('#modalVisualizarVacante').data('idVacante', id);
                    $('#modalVisualizarVacante').modal('show');

                    // Cargar postulaciones
                    $.ajax({
                        url: `/Practicas/ObtenerPostulaciones?idVacante=${id}`,
                        type: 'GET',
                        success: function (postulaciones) {
                            const $lista = $('#listaPostulaciones').empty();
                            const hayData = Array.isArray(postulaciones) && postulaciones.length > 0;
                            $('#mensajeSinPostulaciones').toggle(!hayData);

                            if (hayData) {
                                postulaciones.forEach(function (p) {
                                    const estado = p.EstadoDescripcion || p.estadoDescripcion || 'Sin estado';
                                    const badge = badgeEstado(estado);

                                    $lista.append(`
                                        <li class="d-flex justify-content-between align-items-center p-2 border rounded mb-2">
                                            <div>
                                                <a href="${CFG.urls.visualizacionPostulacion}?idVacante=${p.IdVacante || p.idVacante}&idUsuario=${p.IdUsuario || p.idUsuario}"
                                                   class="text-decoration-none fw-bold"
                                                   style="color:#2d594d;">
                                                    ${escapeHtml(p.NombreCompleto || p.nombreCompleto)}
                                                </a>
                                            </div>
                                            <div class="d-flex align-items-center gap-2">${badge}</div>
                                        </li>`);
                                });
                            }
                        }
                    });
                },
                error: function () {
                    Swal.fire('Error', 'No se pudo cargar la vacante.', 'error');
                }
            });
        });

        // =====================================================
        // 🔹 Helper: cargar estudiantes para asignar
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
        // =====================================================

        function cargarEstudiantesAsignar(idVacante) {
            $.ajax({
                url: `/Practicas/ObtenerEstudiantesAsignar?idVacante=${idVacante}&idUsuarioSesion=${CFG.idUsuarioSesion || 0}`,
                type: 'GET',
                success: function (estudiantes) {
                    const tbody = $('#miTablaAsignar tbody').empty();

                    // El Web Controller puede retornar array directo o wrapped
                    const data = Array.isArray(estudiantes) ? estudiantes : (estudiantes.data || []);

                    if (!data.length) {
                        tbody.append('<tr><td colspan="5" class="text-center text-muted">No hay estudiantes disponibles</td></tr>');
                        return;
                    }

                    data.forEach(function (e) {
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
                        } else {
                            btn = `<button class="btn btn-sm btn-bloqueado"
                                   title="No puede ser asignado"
                                   style="background:none; border:none; color:#6c757d;" disabled>
                                <i class="fas fa-ban fa-lg"></i>
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
                }
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
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
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

                $.ajax({
                    url: '/Practicas/AsignarEstudiante',
                    type: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    data: { idUsuario: idUsuario, idVacante: idVacante },
                    success: function (resultado) {
                        console.log('[Asignar] Resultado:', resultado);

                        const res = typeof resultado === 'number' ? resultado : parseInt(resultado);

                        if (res === 1) {
                            Swal.fire({
                                icon: 'success',
                                title: 'Éxito',
                                text: 'Estudiante asignado correctamente.',
                                timer: 2000,
                                showConfirmButton: false
                            });
                            cargarEstudiantesAsignar(idVacante);
                            tabla.ajax.reload(null, false);
                        } else if (res === -1) {
                            Swal.fire('Aviso', 'El estudiante ya tiene una práctica asignada.', 'warning');
                        } else if (res === -2) {
                            Swal.fire('Aviso', 'No hay cupos disponibles en esta vacante.', 'warning');
                        } else {
                            Swal.fire('Error', 'No se pudo completar la asignación.', 'error');
                        }
                    },
                    error: function () {
                        Swal.fire('Error', 'Error de conexión al servidor.', 'error');
                    }
                });
            });
        });

        // =====================================================
        // 🔹 Retirar estudiante
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
        // =====================================================

        $(document).on('click', '.btn-retirar-estudiante', function () {
            const idVacante = $('#modalAsignar').data('idVacante');
            const idUsuario = $(this).data('idusuario');
            const idPractica = $(this).data('idpractica') || 0;
            const nombre = $(this).data('nombre') || '—';

            Swal.fire({
                title: '¿Deseas desasignar esta práctica?',
                html: `El estudiante <b>${nombre}</b> pasará al estado de práctica <b>"Retirada"</b>.`,
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
                if (!result.isConfirmed) return;

                const comentario = result.value.trim();
                const url = idPractica > 0 ? '/Practicas/DesasignarPractica' : '/Practicas/RetirarEstudiante';
                const data = idPractica > 0
                    ? { idPractica: idPractica, comentario: comentario }
                    : { idVacante: idVacante, idUsuario: idUsuario, comentario: comentario };

                $.ajax({
                    url: url,
                    type: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded'
                    },
                    data: data,
                    success: function (resultado) {
                        console.log('[Desasignar] Resultado:', resultado);

                        const res = typeof resultado === 'number' ? resultado : parseInt(resultado);

                        if (res === 1) {
                            Swal.fire({
                                icon: 'success',
                                title: 'Desasignado correctamente',
                                text: 'La práctica fue desasignada exitosamente.',
                                timer: 1800,
                                showConfirmButton: false
                            });
                            cargarEstudiantesAsignar(idVacante);
                            tabla.ajax.reload(null, false);
                        } else {
                            Swal.fire('Error', 'No se pudo desasignar la práctica.', 'error');
                        }
                    },
                    error: function () {
                        Swal.fire('Error', 'Error de conexión al servidor.', 'error');
                    }
                });
            });
        });

        // =====================================================
        // 🔹 Editar Vacante
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
        // =====================================================

        $('#miTabla').on('click', '.btn-editar', function () {
            const id = $(this).data('id');

            $.ajax({
                url: `/Practicas/Detalle?id=${id}`,
                type: 'GET',
                success: function (d) {
                    $('#edit-IdVacante').val(d.IdVacante || d.idVacante);
                    $('#edit-Nombre').val(d.Nombre || d.nombre);
                    $('#edit-IdEmpresa').val(d.IdEmpresa || d.idEmpresa);
                    $('#edit-Ubicacion').val(d.Ubicacion || d.ubicacion);
                    $('#edit-IdEspecialidad').val(d.IdEspecialidad || d.idEspecialidad);
                    $('#edit-NumCupos').val(d.NumCupos || d.numCupos);
                    $('#edit-IdModalidad').val(d.IdModalidad || d.idModalidad);
                    $('#edit-Requerimientos').val(d.Requerimientos || d.requisitos);
                    $('#edit-Descripcion').val(d.Descripcion || d.descripcion);
                    $('#edit-FechaMaxAplicacion').val(d.FechaMaxAplicacion ? d.FechaMaxAplicacion.split('T')[0] : '');
                    $('#edit-FechaCierre').val(d.FechaCierre ? d.FechaCierre.split('T')[0] : '');

                    $('#modalEditarVacante').modal('show');
                },
                error: function () {
                    Swal.fire('Error', 'No se pudo cargar la información.', 'error');
                }
            });
        });

        $('#formEditarVacante').on('submit', function (e) {
            e.preventDefault();

            const payload = {
                IdVacante: parseInt($('#edit-IdVacante').val()) || 0,
                Nombre: $('#edit-Nombre').val().trim(),
                IdEmpresa: parseInt($('#edit-IdEmpresa').val()),
                IdEspecialidad: parseInt($('#edit-IdEspecialidad').val()),
                NumCupos: parseInt($('#edit-NumCupos').val()) || 0,
                IdModalidad: parseInt($('#edit-IdModalidad').val()),
                Requerimientos: $('#edit-Requerimientos').val().trim(),
                Descripcion: $('#edit-Descripcion').val().trim(),
                FechaMaxAplicacion: $('#edit-FechaMaxAplicacion').val(),
                FechaCierre: $('#edit-FechaCierre').val()
            };

            console.log('[Editar Vacante] Payload:', payload);

            $.ajax({
                url: '/Practicas/Editar',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify(payload),
                success: function (resultado) {
                    console.log('[Editar Vacante] Resultado:', resultado);

                    const res = typeof resultado === 'number' ? resultado : parseInt(resultado);

                    if (res > 0) {
                        Swal.fire('Éxito', 'Vacante actualizada correctamente.', 'success');
                        $('#modalEditarVacante').modal('hide');
                        tabla.ajax.reload(null, false);
                    } else {
                        Swal.fire('Error', 'No se pudo actualizar la vacante.', 'error');
                    }
                },
                error: function (xhr) {
                    Swal.fire('Error', xhr.responseText || 'Error al actualizar.', 'error');
                }
            });
        });

        // =====================================================
        // 🔹 Eliminar Vacante
        // ✅ CORREGIDO: USA EL WEB CONTROLLER
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

                $.ajax({
                    url: `/Practicas/Eliminar?id=${id}`,
                    type: 'POST',
                    success: function (resultado) {
                        console.log('[Eliminar] Resultado:', resultado);

                        const res = typeof resultado === 'number' ? resultado : parseInt(resultado);

                        if (res === 1) {
                            Swal.fire('Éxito', 'Vacante archivada correctamente.', 'success');
                            tabla.ajax.reload(null, false);
                        } else if (res === -1) {
                            Swal.fire('Aviso', 'No se puede eliminar porque tiene estudiantes asignados.', 'warning');
                        } else {
                            Swal.fire('Error', 'No se pudo archivar la vacante.', 'error');
                        }
                    },
                    error: function () {
                        Swal.fire('Error', 'Error al archivar.', 'error');
                    }
                });
            });
        });

    });
})(jQuery);