var selected_row = null
var is_new_pass_valid = false
var selection_options = ''
requestConfigsList(getConfigsListResult)
requestUserList(getUserListResult)

function continue_loading_page(part){
  if(part === 2) {
  }
  else {
    const selector_ = '#users-list div.row'
    rows = document.querySelectorAll(selector_)
    rows.forEach(e => { e.addEventListener('click', (event) => {user_click(event)}) })
    selected_row = null
  }
}

async function requestConfigsList(callback) {
  await fetch('users?list_configs', {
    method: 'GET',
  }).then(function(response) {
    if (response.status == 200) {
      return response.text();
    }
    else { return ''; }
  }).then(function(data){ callback(data); })
}

async function requestUserList(callback) {
  await fetch('users?list_users', {
    method: 'GET',
  }).then(function(response) {
    if (response.status == 200) {
      return response.text();
    }
    else { return ''; }
  }).then(function(data){ callback(data); })
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
        <div class="flex horizontal bellowrow">
          <div class="userselected bellowrow">
          </div>
          <p class="username bellowrow">${element.name}</p>
          <p class="userrole bellowrow">${element.role}</p>
          <select class="userconfig bellowrow" onChange="selectConfig(this)">
          `
      htmlRow += selection_options
      htmlRow += `</select>
          <p class="userconfig hidden">${element.config}</p>
          <p class="usernewpass hidden"></p>
          <button class="password-buttons" id="fill-new-password-button" onclick="fill_new_pass()">New password</button>
          `
      htmlRow +=`
      </div>
      `
      htmlList.innerHTML += htmlRow
    });

    htmlList.childNodes.forEach(element => {
      if (element.nodeName == "#text") {
        return;
      }
      value = element.childNodes[1].childNodes[9].textContent
      if (value == 'null') {
        element.childNodes[1].childNodes[9].textContent = 'None'
        value = 'None'
      }
      element.childNodes[1].childNodes[7].value = value
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
  requestUserList(getUserListResult)
}

function add_user(e){
  users_list = document.getElementById('users-list')
  users_list.childNodes.forEach(element => {
  })
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
      selected_row = element.childNodes[1]
      }
    })

  // If there is no change
  if(past_selected_row != null) {
    past_selected_row_username = past_selected_row.childNodes[3].textContent
    selected_row_username = selected_row.childNodes[3].textContent
    if(past_selected_row_username  == selected_row_username) {
      console.log('No change')
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

  remove_user_button = document.getElementById('remove-user-button')
  // Reset selection
  users_list = document.getElementById('users-list')
  users_list.childNodes.forEach(element => {
    if (element.nodeName == "#text") {
      return;
    }
    if(selected_row != '') {
      current_row_username = element.childNodes[1].childNodes[3].textContent
      selected_row_username = selected_row.childNodes[3].textContent
      if(current_row_username == selected_row_username) { return }
    }
    element.childNodes[1].childNodes[11].value = ''
    value = element.childNodes[1].childNodes[9].textContent
    element.childNodes[1].childNodes[7].value = value
    element.childNodes[1].childNodes[1].classList.remove('active')
    remove_user_button.classList.remove('inactive')
  })
}

function fill_new_pass() {
  is_new_pass_valid = false
  document.getElementById('new-password').value = ''
  new_password_splash = document.getElementById('splash-new-password')
  new_password_splash.classList.add('active')
}

function fill_new_password() {
  new_password_splash = document.getElementById('splash-new-password')
  new_password_splash.classList.remove('active')
  if(is_new_pass_valid) {
    hash = encryptPass(document.getElementById('new-password').value)
    selected_row.childNodes[11].textContent = hash
    commit_user_button = document.getElementById('commit-user-button')
    commit_user_button.disabled = false
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

function encryptPass(plain_password) {
  return CryptoJS.SHA256(plain_password).toString()
}

function cancel_fill_new_password() {
  new_password_splash = document.getElementById('splash-new-password')
  new_password_splash.classList.remove('active')
}