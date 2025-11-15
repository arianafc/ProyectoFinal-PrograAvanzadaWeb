
let direccionesData = null;

async function cargarJSONDirecciones() {
    try {
        const response = await fetch('/json/costarica.json'); 

        if (!response.ok) {
            throw new Error('No se pudo cargar el archivo JSON');
        }

        direccionesData = await response.json();

       
        inicializarDirecciones();

    } catch (error) {
        console.error('Error cargando direcciones:', error);
        alert('Error al cargar las direcciones. Por favor, recarga la página.');
    }
}

function cargarCantones() {

    if (!direccionesData) {
        console.error('JSON de direcciones no está cargado');
        return;
    }

    const provinciaSelect = document.querySelector('select[name="Provincia"]');
    const cantonSelect = document.querySelector('select[name="Canton"]');
    const distritoSelect = document.querySelector('select[name="Distrito"]');

    const provinciaNombre = provinciaSelect.value;

   
    cantonSelect.innerHTML = '<option value="">Seleccione un cantón</option>';
    distritoSelect.innerHTML = '<option value="">Seleccione un distrito</option>';

    if (!provinciaNombre) {
        return;
    }

    const provinciaKey = Object.keys(direccionesData.provincias).find(
        key => direccionesData.provincias[key].nombre === provinciaNombre
    );

    if (!provinciaKey) {
        console.error('Provincia no encontrada:', provinciaNombre);
        return;
    }

    const provincia = direccionesData.provincias[provinciaKey];

    const cantones = Object.keys(provincia.cantones).map(key => ({
        key: key,
        nombre: provincia.cantones[key].nombre
    })).sort((a, b) => a.nombre.localeCompare(b.nombre));

    cantones.forEach(canton => {
        const option = document.createElement('option');
        option.value = canton.nombre;
        option.textContent = canton.nombre;
        cantonSelect.appendChild(option);
    });
}

function cargarDistritos() {
 
    if (!direccionesData) {
        console.error('JSON de direcciones no está cargado');
        return;
    }

    const provinciaSelect = document.querySelector('select[name="Provincia"]');
    const cantonSelect = document.querySelector('select[name="Canton"]');
    const distritoSelect = document.querySelector('select[name="Distrito"]');

    const provinciaNombre = provinciaSelect.value;
    const cantonNombre = cantonSelect.value;

    distritoSelect.innerHTML = '<option value="">Seleccione un distrito</option>';

    if (!provinciaNombre || !cantonNombre) {
        return;
    }

    const provinciaKey = Object.keys(direccionesData.provincias).find(
        key => direccionesData.provincias[key].nombre === provinciaNombre
    );

    if (!provinciaKey) {
        console.error('Provincia no encontrada:', provinciaNombre);
        return;
    }

    const provincia = direccionesData.provincias[provinciaKey];

    const cantonKey = Object.keys(provincia.cantones).find(
        key => provincia.cantones[key].nombre === cantonNombre
    );

    if (!cantonKey) {
        console.error('Cantón no encontrado:', cantonNombre);
        return;
    }

    const canton = provincia.cantones[cantonKey];

    const distritos = Object.keys(canton.distritos).map(key => ({
        key: key,
        nombre: canton.distritos[key]
    })).sort((a, b) => a.nombre.localeCompare(b.nombre));

    distritos.forEach(distrito => {
        const option = document.createElement('option');
        option.value = distrito.nombre;
        option.textContent = distrito.nombre;
        distritoSelect.appendChild(option);
    });
}

function inicializarDirecciones() {
    const provinciaSelect = document.querySelector('select[name="Provincia"]');
    const cantonSelect = document.querySelector('select[name="Canton"]');
    const distritoSelect = document.querySelector('select[name="Distrito"]');


    if (!provinciaSelect || !cantonSelect || !distritoSelect) {
        return;
    }

  
    const provinciaSeleccionada = provinciaSelect.value;
    const cantonSeleccionado = cantonSelect.getAttribute('data-selected') || '';
    const distritoSeleccionado = distritoSelect.getAttribute('data-selected') || '';

   
    if (provinciaSeleccionada && provinciaSeleccionada !== '') {
        cargarCantones();

    
        if (cantonSeleccionado && cantonSeleccionado !== '') {
            setTimeout(() => {
                cantonSelect.value = cantonSeleccionado;

                if (cantonSelect.value) {
                    cargarDistritos();

                  
                    if (distritoSeleccionado && distritoSeleccionado !== '') {
                        setTimeout(() => {
                            distritoSelect.value = distritoSeleccionado;
                        }, 50);
                    }
                }
            }, 50);
        }
    }
}


if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', cargarJSONDirecciones);
} else {
    cargarJSONDirecciones();
}