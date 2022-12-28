var selected_row = null
var is_new_pass_valid = false
var selection_options = ''
requestData(getRolesListResult, 'list_roles')
requestData(getConfigsListResult, 'list_configs')
requestData(getUserListResult, 'list_users')

function continue_loading_page(part){
  if(part === 2) {
  }
  else if(part === 3) {
    const selector_ = '#users-list div.row'
    rows = document.querySelectorAll(selector_)
    rows.forEach(e => { e.addEventListener('click', (event) => {user_click(event)}) })
    selected_row = null
  }
  else if(part === 4) {
    manageCreateUserLayout('disable')
  }
}

async function requestData(callback, action) {
  await fetch('users?' + action, {
    method: 'GET',
  }).then(function(response) {
    if (response.status == 200) {
      return response.text();
    }
    else { return ''; }
  }).then(function(data){ callback(data); })
}

async function getRolesListResult(response) {
    var roles = JSON.parse(response)
    roles_list = document.getElementById('user-create-roles-list')
    roles_list_options = ''

    roles.forEach(role => {
      roles_list_options += `  <option value="${role}">${role}</option>
      `
    })
    roles_list.innerHTML = roles_list_options
    continue_loading_page(4)
}

async function getConfigsListResult(response) {
    var wireguard_configs = JSON.parse(response)
    users_list = document.getElementById('users-list')
    selection_options = `  <option value="None"></option>
      `
    wireguard_configs.forEach(peer => {
      selection_options += `  <option value="${peer}">${peer}</option>
      `
    })
    continue_loading_page(2)
}

function getUserListResult(response) {
    var users = JSON.parse(response)
    htmlList = document.getElementById("users-list")
    users.forEach(element => {
      var htmlRow = `
        <div class="row">
          <div class="userselected listitem">
          </div>
          <p class="username listitem">${element.name}</p>
          <p class="userrole listitem">${element.role}</p>
          <select class="userconfig listitem" onChange="selectConfig(this)">
          `
      htmlRow += selection_options
      htmlRow += `</select>
          <p class="userdefaultconfig hidden">${element.config}</p>
          <p class="usernewpass hidden"></p>
          <button class="password-buttons listitem" onclick="fill_new_pass('change')">New password</button>
          `
      htmlList.innerHTML += `</div>`
      htmlList.innerHTML += htmlRow
    });

    htmlList.childNodes.forEach(element => {
      if (element.nodeName == "#text") {
        return;
      }
      value = element.childNodes[9].textContent
      if (value == 'null') {
        element.childNodes[9].textContent = 'None'
        value = 'None'
      }
      element.childNodes[7].value = value
    })
    continue_loading_page(3)
}

async function remove_user() {
  remove_username = selected_row.childNodes[3].textContent

  const remove_user_request = new FormData()
  remove_user_request.append('action', 'remove_user')
  remove_user_request.append('username', remove_username)
  await fetch('users', {
    redirect: 'manual',
    method: 'POST',
    body: remove_user_request,
  }).then(function(response){ refreshUserList(response); })
}

function refreshUserList(response) {
  commit_user_button = document.getElementById('commit-user-button')
  commit_user_button.disabled = true
  users_list = document.getElementById('users-list')
  users_list.innerHTML = ''
  manageCreateUserLayout('disable')
  resetSelection()
  requestData(getUserListResult, 'list_users')
}

function add_user(e){
  users_list = document.getElementById('users-list')
  users_list.childNodes.forEach(element => {
  })
  manageCreateUserLayout('enable')
}

async function createUser(){
  create_user_request = new FormData()
  create_user_request.append('action', 'add_user')
  username = document.getElementById('user-create-username').value
  create_user_request.append('username', username)
  password = document.getElementById('create-user-new-pass').value
  if(hash != '') {
    create_user_request.append('hash', password)
  }
  role = document.getElementById('user-create-roles-list').value
  if(role != '') {
    create_user_request.append('role', role)
  }
  await fetch('users', {
    redirect: 'manual',
    method: 'POST',
    body: create_user_request,
  }).then(function(response){ refreshUserList(response); })
  username = null
  password = null
  hash = null
  role = null
}

async function commit_changes_user(){
  change_user_request = new FormData()
  changed_user = selected_row.childNodes[3].textContent
  change_user_request.append('action', 'change_user')
  change_user_request.append('username', changed_user)
  hash = selected_row.childNodes[11].textContent
  if(hash != '') {
    change_user_request.append('hash', hash)
  }
  config = selected_row.childNodes[7].value
  if(config != '') {
    change_user_request.append('config', config)
  }
  await fetch('users', {
    redirect: 'manual',
    method: 'POST',
    body: change_user_request,
  }).then(function(response){ refreshUserList(response); })
}

function user_click(e){
  var past_selected_row = selected_row
  users_list = document.getElementById('users-list')

  // Find out selected row
  users_list.childNodes.forEach(element => {
    if(element.contains(e.target)) {
      selected_row = element
      }
    })

  // If there is no change
  if(past_selected_row != null) {
    past_selected_row_username = past_selected_row.childNodes[3].textContent
    selected_row_username = selected_row.childNodes[3].textContent
    if(past_selected_row_username  == selected_row_username) {
      return
    }
  }

  // If selected row changed
  // Reset selection marks from all users list
  resetSelection()
  // Mark selected row with selection mark
  selected_row.childNodes[1].classList.add('active')
  // You cannot remove yourself
  // So if current user is selected user -
  // make the remove user button disabled
  welcome_message = document.getElementById('auth_user').textContent
  selected_user_name = selected_row.childNodes[3].textContent
  if(welcome_message == 'Welcome, ' + selected_user_name + '.') {
    remove_user_button.disabled = true
  }
  else {
    remove_user_button.disabled = false
  }
}

function selectConfig(e){
  if(selected_row.childNodes[7].value !== selected_row.childNodes[9].textContent) {
    commit_user_button = document.getElementById('commit-user-button')
    commit_user_button.disabled = false
  }
}

function resetSelection() {
  // Disable commit changes button
  commit_user_button = document.getElementById('commit-user-button')
  commit_user_button.disabled = true

  // Reset selection
  users_list = document.getElementById('users-list')
  users_list.childNodes.forEach(element => {
    if (element.nodeName == "#text") {
      return;
    }
    if(selected_row != '') {
      current_row_username = element.childNodes[3].textContent
      selected_row_username = selected_row.childNodes[3].textContent
      if(current_row_username == selected_row_username) { return }
    }
    element.childNodes[11].value = ''
    value = element.childNodes[9].textContent
    element.childNodes[7].value = value
    element.childNodes[1].classList.remove('active')
    // remove_user_button.classList.remove('inactive')
  })
  manageCreateUserLayout('disable')
  remove_user_button = document.getElementById('remove-user-button')
  remove_user_button.disabled = true
}

function fill_new_pass(action) {
  is_new_pass_valid = false
  document.getElementById('new-password').value = ''
  new_password_splash = document.getElementById('splash-new-password')
  new_password_splash.classList.add('active')

  fill_new_password_button = document.getElementById('fill-new-password')
  fill_new_password_button.onclick = null
  fill_new_password_button.addEventListener('click', () => {fill_new_password(action)})
}

function fill_new_password(action) {
  new_password_splash = document.getElementById('splash-new-password')
  new_password_splash.classList.remove('active')
  if(is_new_pass_valid) {
    hash = encryptPass(document.getElementById('new-password').value)

    if(action === 'change') {
      selected_row.childNodes[11].textContent = hash
      commit_user_button = document.getElementById('commit-user-button')
      commit_user_button.disabled = false
    }
    else if(action === 'newUser') {
      document.getElementById('create-user-new-pass').value = hash
      enableAddUserButton()
    }
  }
  document.getElementById('new-password').value = ''
}

function validateNewPass() {
  new_password_text = document.getElementById('new-password').value
  fill_new_password_button = document.getElementById('fill-new-password')
  if(new_password_text != '')
  {
    is_new_pass_valid = true
    fill_new_password_button.disabled = false
  }
  else {
    fill_new_password_button.disabled = true
  }
}

function validateNewUsername() {
  newUsername = document.getElementById('user-create-username').value
  users_list = document.getElementById('users-list')
  user_create_button = document.getElementById('user-create-button')
  error_label = document.getElementById('user-create-error-text')
  bad_username = false
  users_list.childNodes.forEach(element => {
      if (element.nodeName == "#text") {
        return;
      }
      if (newUsername.length == 0) {
        error_label.textContent = 'Username is too small!'
        user_create_button.disabled = true
        bad_username = true
      }
      if (newUsername === element.childNodes[3].textContent) {
        error_label.textContent = 'Username is not unique!'
        enableAddUserButton()
        bad_username = true
      }
  })
  if (!bad_username){
    error_label.textContent = ''
    enableAddUserButton()
  }
}

function encryptPass(plain_password) {
  return CryptoJS.SHA256(plain_password).toString()
}

function cancel_fill_new_password() {
  new_password_splash = document.getElementById('splash-new-password')
  new_password_splash.classList.remove('active')
}

function manageCreateUserLayout(action) {
  if (action === 'disable') {
    document.getElementById('user-create-button').disabled = true
    document.getElementById('user-create-username').disabled = true
    document.getElementById('user-create-roles-list').disabled = true
    document.getElementById('user-create-password').disabled = true

    document.getElementById('user-create-username').value = ''
    document.getElementById('user-create-roles-list').value = 'user'
    document.getElementById('create-user-new-pass').value = ''
    document.getElementById('user-create-error-text').textContent = ''
    document.getElementById('user-create-header').classList.add('disable')
  }
  else if (action === 'enable') {
    document.getElementById('user-create-username').disabled = false
    document.getElementById('user-create-roles-list').disabled = false
    document.getElementById('user-create-password').disabled = false

    document.getElementById('user-create-username').value = ''
    document.getElementById('create-user-new-pass').value = ''
    document.getElementById('user-create-error-text').textContent = ''
    document.getElementById('user-create-header').classList.remove('disable')
  }
}

function enableAddUserButton() {
  username = document.getElementById('user-create-username').value
  password = document.getElementById('create-user-new-pass').value
  role = document.getElementById('user-create-roles-list').value
  error = document.getElementById('user-create-error-text').textContent
  if (username == '' || password == '' || role == '' || error != '') {
    document.getElementById('user-create-button').disabled = true
  }
  else {
    document.getElementById('user-create-button').disabled = false
  }
  username = null
  password = null
  role = null
  error = null
}
