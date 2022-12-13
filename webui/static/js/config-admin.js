init()
loadPage()

function init() {
    users = {
        usersArray: [],
        configsArray: [],
        onChange(eventType, details=null) {},
        list() { return this.usersArray },
        length() { return this.usersArray.length },
        append(value) {
            this.usersArray.push(value)
            this.onChange('append', value)
        },
        clear() {
            this.usersArray = []
            this.configsArray = []
            this.onChange('clear')
        },
        getConfig(userName) {},
    }

    users.onChange = usersChanged
}

function usersChanged(eventType, details=null) {
    console.log('usersChanged', eventType)
    usersListCombobox = document.getElementById('users-list')

    if(eventType === 'append') {
        usersListCombobox.innerHTML += `  <option value="${details}">${details}</option>
        `
    }
    if(eventType === 'clear') {
        usersListCombobox.innerHTML = ''
    }
}

async function loadPage() {
    let listUsersPromise = await fetch('users?list_users', { method: 'GET' })
    let resultListUsers = await processFetchData(listUsersPromise)
    if(resultListUsers !== null) {
        loadUsersList(resultListUsers)
    }
    setDefaultSelectedUser()
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

async function processFetchData(fetchPromise) {
    let result = null
    if (fetchPromise.ok) {
        try {
            result = await fetchPromise.json();
        } catch (e) {
            errorHandler('jsonParse', result, e)
        }
        return result;
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

function loadUsersList(usersList) {
    usersList.forEach((userInfo) => {
        users.append(userInfo['name'])
    })
}

async function changedSelectedUser(){
    console.log('changedSelectedUser')
    let username = document.getElementById('users-list').value

    let getConfigPromise = await fetch('?get_user_config&username=' + username, { method: 'GET' })
    let resultGetConfigPromise = await processImgFetchData(getConfigPromise)

    let imgContainer = document.getElementById('config-qr')
    console.log(resultGetConfigPromise)
    if(resultGetConfigPromise !== undefined) {
        imgContainer.src = resultGetConfigPromise
    }
    else {
        imgContainer.src = ''
    }
}

function setDefaultSelectedUser() {
    usersListCombobox = document.getElementById('users-list')
    usersListCombobox.selectedIndex = 0
    usersListCombobox.dispatchEvent(new Event('change'))
}