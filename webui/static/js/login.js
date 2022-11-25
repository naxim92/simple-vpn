async function login(event){
  event.preventDefault()

  var loginInfo = serializeForm(document.forms['login-form'])
  await sendLoginInfo(loginInfo, getLoginResult)
}

function serializeForm(form) {
  const { elements } = form

  let data = Array.from(elements)
    .filter((item) => !!item.name)
    .map((element) => {
      const { name, value } = element
      return { name, value }
    })

  plain_password = data.find((item) => item.name == 'password').value;
  data.find((item) => item.name == 'password').value = CryptoJS.SHA256(plain_password).toString()

  const ready_form = new FormData()
  data.forEach(item => { ready_form.append(item.name, item.value) })
  return ready_form
}

async function sendLoginInfo(data, callback) {

  await fetch('login', {
    redirect: 'manual',
    method: 'POST',
    body: data,
  }).then(function(response){ callback(response); })
}

function getLoginResult(response) {
    if(response.status == 403) {
        document.forms["login-form"].reset()
        document.getElementById("login-error-text").textContent = "Invalid username or password"
    }
    else {
        location.href = '/'
    }
}