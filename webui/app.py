from flask import Flask, render_template, request, redirect, abort, make_response, session, send_file
from werkzeug.exceptions import HTTPException, InternalServerError, ImATeapot
from jinja2.exceptions import TemplateNotFound
from prometheus_flask_exporter import PrometheusMetrics
from os import urandom
from os import walk
from os.path import join
from base64 import b64encode
from os.path import dirname, abspath
from hashlib import sha256
from secrets import token_hex
import sqlite3
import re
from enum import Enum
from exceptions import *


class AuthStatus(Enum):
    OK = 1
    NO_USER = 2
    WRONG_PASS = 3


class Roles(Enum):
    USER = 'user'
    ADMIN = 'admin'
    INSTANCE_ADMIN = 'instance_admin'


app_path = dirname(abspath(__file__))
webui_db_path = app_path + '/data/webui.db'
default_user = 'admin'
default_password = 'admin'
default_admin_role = Roles.ADMIN.value
wireguard_dir = '../wireguard/config'
wireguard_config_pattern = 'peer'
wireguard_config_qr_pattern = 'peer[0-9]+\.png'


def try_load_secret_key():
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        select value from config
        where name = 'SessionKey'
        """
        cursor.execute(sql)
        app.secret_key = cursor.fetchone()[0]
    except Exception as error:
        raise error
    finally:
        cursor.close()
        sqlite_connection.close()


app = Flask(__name__)
try:
    try_load_secret_key()
except Exception:
    pass

metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Application info', version='1.0.3')


@app.route("/install")
def install():
    force = False if request.args.get('force') is None else True
    if force:
        try:
            sqlite_connection = sqlite3.connect(webui_db_path)
            cursor = sqlite_connection.cursor()
            sql = """
            drop table if exists security;
            drop table if exists sessions;
            drop table if exists config;
            """
            cursor.executescript(sql)
        except Exception as error:
            abort(500, error)
        finally:
            cursor.close()
            sqlite_connection.close()
    try:
        try_config_app()
        try_create_user(
            username=default_user,
            role=default_admin_role,
            password=default_password)
    except CreateUserException:
        abort(500)
    return 'OK!'


# Temp, TODO: use nginx
@app.route('/favicon.ico')
def favicon():
    return send_file('static/favicon/favicon.ico', mimetype='image/png')


@app.route("/")
def root():
    if not app.authenticated:
        return redirect('/login')
    elif app.auth_role == 'admin':
        get_config_opt = request.args.get('get_user_config')
        username_opt = request.args.get('username')
        if request.method == 'GET':
            if get_config_opt is not None and \
                    username_opt is not None and \
                    username_opt != '':
                qr_user_config = None
                try:
                    qr_user_config = try_get_user_config(username_opt)
                except Exception as error:
                    abort(500, error)
                if qr_user_config is None:
                    abort(404, 'There is no user\'s config')
                else:
                    return send_file(qr_user_config, mimetype='image/png')
            return render_template(
                "config-admin.html",
                username=app.auth_username,
                role=app.auth_role)
        else:
            abort(400)
    else:
        get_config_opt = request.args.get('get_user_config')
        if request.method == 'GET':
            if get_config_opt is not None:
                qr_user_config = None
                try:
                    qr_user_config = try_get_user_config(app.auth_username)
                except Exception as error:
                    abort(500, error)
                if qr_user_config is None:
                    abort(404, 'There is no user\'s config')
                else:
                    return send_file(qr_user_config, mimetype='image/png')
            else:
                return render_template(
                    "config-user.html",
                    username=app.auth_username,
                    role=app.auth_role)
        else:
            abort(400)


@app.route("/test")
def hello():
    return render_template(
        "test.html",
        username=app.auth_username,
        role=app.auth_role)


@app.route("/users", methods=['GET', 'POST'])
def users():
    if app.auth_role != 'admin':
        abort(403)
    list_users_opt = request.args.get('list_users')
    list_roles_opt = request.args.get('list_roles')
    list_configs_opt = request.args.get('list_configs')
    if request.method == 'GET':
        if list_users_opt is not None:
            try:
                return try_list_users()
            except Exception as error:
                abort(500, error)
        elif list_roles_opt is not None:
            return list_roles()
        elif list_configs_opt is not None:
            return list_wireguard_configs()
    elif request.method == 'POST':
        action = request.form.get('action', None)
        username = request.form.get('username', None)
        if action is None:
            abort(400)
        if action == 'remove_user':
            if username is None:
                return False
            if username == app.auth_username:
                return False
            try:
                try_remove_user(username)
            except Exception as error:
                abort(500, error)

        if action == 'add_user':
            password_hash = request.form.get('hash', None)
            role = request.form.get('role', None)
            try:
                try_create_user(
                    username=username,
                    role=role,
                    password_hash=password_hash)
            except Exception as error:
                abort(500, error)

        if action == 'change_user':
            user_config = request.form.get('config', None)
            new_pass_hash = request.form.get('hash', None)
            try:
                try_change_user(
                    username=username,
                    config=user_config,
                    password_hash=new_pass_hash)
            except Exception as error:
                abort(500, error)
    return render_template(
        "users.html",
        username=app.auth_username,
        role=app.auth_role)


@app.route("/logout")
def logout():
    session.clear()
    return redirect("/login")


@app.route("/login", methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        auth_result, username = auth()
        if auth_result == AuthStatus.OK:
            session.permanent = True
            session['authUsername'] = username
            return redirect('/')
        else:
            return abort(403)
    elif app.authenticated:
        return redirect('/')
    else:
        return render_template("login.html")


@app.before_request
def reset_vars():
    app.authenticated = False
    app.auth_role = None
    app.auth_username = None


@app.before_request
def getSessionKey():
    check_no_session_url = re.match(
        "^/(favicon.ico$|static/|install($|(/$)))",
        request.path)
    if check_no_session_url is not None:
        return
    if app.secret_key is None:
        abort(500, """
            WebUI had\'t been configured properly.
            SessionKey is missing.
            Try to reinstall WebUI.
            """)
    # First request after run will be unauthenticated
    # as secret_key hasn't properly loaded yet.
    # Second and nexts requests will be processed correctly.


@app.before_request
def get_role():
    app.auth_username = session.get("authUsername")
    if not app.auth_username:
        app.authenticated = False
    else:
        app.authenticated = True
        try:
            role = try_get_role()
            app.auth_role = role
        except Exception:
            # TODO: abort(500) or set default??
            abort(500, 'Who\'re you?')


def try_get_role():
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        select role from security
        where username=:username
        """
        cursor.execute(sql, {"username": app.auth_username})
        role = cursor.fetchone()
        return role[0]
    except Exception as error:
        abort(500, error)
        # raise GetRoleException from error
    finally:
        cursor.close()
        sqlite_connection.close()


def try_list_users():
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        select username, role, config from security
        """
        cursor.execute(sql)
        users = cursor.fetchall()
        users = sorted(users, key=lambda u: u[0])
        formated_users = []
        for u in users:
            formated_users.append(
                {"name": u[0],
                 "role": u[1],
                 "config": u[2]})
        return formated_users
    except Exception as error:
        raise Exception from error
    finally:
        cursor.close()
        sqlite_connection.close()


def list_roles():
    return [role.value for role in Roles]


def list_wireguard_configs():
    peers = []
    for root, dirs, files in walk(wireguard_dir, topdown=False):
        for dir in dirs:
            if re.match(wireguard_config_pattern, dir):
                peers.append(dir)
    peers_sorted = sorted(peers, key=lambda u: u)
    return peers_sorted


def try_get_user_config(username):
    sql_config_name = None
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        select config from security
        where username=:username
        """
        cursor.execute(sql,
                       {"username": username})
        user_data = cursor.fetchone()
        sql_config_name = user_data[0]
    except Exception as error:
        abort(500, error)
    finally:
        cursor.close()
        sqlite_connection.close()

    if sql_config_name is None:
        return None

    for root, dirs, files in walk(
            join(wireguard_dir, sql_config_name),
            topdown=False):
        for file in files:
            if re.match(wireguard_config_qr_pattern, file):
                return join(root, file)
    return None


def auth():
    username = request.form.get('username', None)
    password = request.form.get('password', None)
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        select password, salt from security
        where username=:username
        """
        cursor.execute(sql,
                       {"username": username})
        user_data = cursor.fetchone()
        sql_password = user_data[0]
        sql_salt = user_data[1]
    except Exception:
        return AuthStatus.NO_USER, None
    finally:
        cursor.close()
        sqlite_connection.close()
    testing_hash = sha256(password.encode() + sql_salt).hexdigest()
    original_hash = sql_password
    if testing_hash == original_hash:
        return AuthStatus.OK, username
    return AuthStatus.WRONG_PASS, None


def try_config_app():
    sessionKey = b64encode(urandom(20)).decode()
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        create table if not exists security
        (username type unique, password, salt, role, config);
        create table if not exists config
        (name type unique, value);
        """
        cursor.executescript(sql)
        sql = """
        insert into config (name, value)
        values (:name, :value)
        """
        cursor.execute(sql,
                       {"name": 'SessionKey',
                        "value": sessionKey})
        sqlite_connection.commit()
    except Exception as error:
        abort(500, error)
    finally:
        cursor.close()
        sqlite_connection.close()
    app.secret_key = sessionKey


def try_create_user(username, role, password=None, password_hash=None):
    if (password is None and password_hash is None) or \
            (password == '' and password_hash == ''):
        CreateUserException('Get me a password!')
    if (username is None or username == '') or (role is None or role == ''):
        CreateUserException('Bad request!')
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        create table if not exists security
        (username type unique, password, salt, role, config)
        """
        cursor.execute(sql)
        sql = """
        insert into security (username, password, salt, role)
        values (:username, :password, :salt, :role)
        """
        salt = token_hex(9).encode()
        if password is not None:
            password_hash = sha256(password.encode()).hexdigest()
        hash = sha256(
            (password_hash + salt.decode()).encode())
        cursor.execute(sql,
                       {"username": username,
                        "password": hash.hexdigest(),
                        "salt": salt,
                        "role": role})
        sqlite_connection.commit()
    except Exception as error:
        raise CreateUserException() from error
    finally:
        cursor.close()
        sqlite_connection.close()


def try_remove_user(username):
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        create table if not exists security
        (username type unique, password, salt, role, config)
        """
        cursor.execute(sql)
        sql = """
        delete from security where username=:username
        """
        cursor.execute(sql, {"username": username})
        sqlite_connection.commit()
    except Exception as error:
        raise RemoveUserException() from error
    finally:
        cursor.close()
        sqlite_connection.close()


def try_change_user(username, config=None, password_hash=None):
    try:
        sqlite_connection = sqlite3.connect(webui_db_path)
        cursor = sqlite_connection.cursor()
        sql = """
        create table if not exists security
        (username type unique, password, salt, role, config)
        """
        cursor.execute(sql)
        if config is None and password_hash is None:
            return
        sql = """
        update security
        set """
        salt = None
        hash = None
        if config is not None:
            sql += "config=:config"
        if config is not None and password_hash is not None:
            sql += ", "
        if password_hash is not None:
            sql += "password=:password, salt=:salt"
            salt = token_hex(9).encode()
            hash = sha256(
                (password_hash + salt.decode()).encode())
            hash = hash.hexdigest()
        if config == 'None':
            config = None
        sql += " where username=:username"
        cursor.execute(sql,
                       {"username": username,
                        "config": config,
                        "password": hash,
                        "salt": salt})
        sqlite_connection.commit()
    except Exception as error:
        raise ChangeUserException() from error
    finally:
        cursor.close()
        sqlite_connection.close()


@app.errorhandler(HTTPException)
def handle_error(e):
    try:
        error_page = render_template('errors/' + str(e.code) + '.html')
    except TemplateNotFound:
        error_page = render_template('errors/500.html')
    return error_page, e.code


@app.errorhandler(TemplateNotFound)
def handle_template_not_found_error(e):
    return render_template('errors/404.html'), 404


@app.errorhandler(InternalServerError)
def handle_internal_error(e):
    return render_template('errors/500.html', detailes=e.description), 500


@app.errorhandler(ImATeapot)
def handle_teapor_error(e):
    return e.description, 418
