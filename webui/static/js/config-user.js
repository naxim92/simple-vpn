loadPage()

async function loadPage() {
    let getConfigPromise = await fetch('?get_user_config', { method: 'GET' })
    let resultGetConfigPromise = await processImgFetchData(getConfigPromise)
    let errorTextContainer = document.getElementById('error-config')
    errorTextContainer.textContent = ''

    let imgContainer = document.getElementById('config-qr')
    console.log(resultGetConfigPromise)
    if(resultGetConfigPromise !== undefined) {
        imgContainer.src = resultGetConfigPromise
    }
    else {
        imgContainer.src = ''
        errorTextContainer.textContent = 'There is no linked user\'s config. Please, contact with Administrator!'
    }
}

async function processImgFetchData(fetchPromise) {
    let result = null
    if (fetchPromise.ok) {
        try {
            result = await fetchPromise.blob()
        } catch (e) {
            errorHandler('fetchImage', result, e)
        }

        let imageObjectURL = URL.createObjectURL(result)

        const blobToB64 = (blob) => new Promise((resolve, reject) => {
          const reader = new FileReader()
          reader.onload = (event) => resolve(event.target.result)
          reader.onerror = reject
          reader.readAsDataURL(blob)
        })
        return await blobToB64(result);
    }
    else {
        errorHandler('fetch', fetchPromise.status + ' ' + fetchPromise.statusText)
    }
}

function errorHandler(errorType, data, errorDescription) {
    if (!errorDescription) {
        errorDescription = ''
    }
    console.error(errorType, errorDescription)
}