#!/bin/python

import socket
import os
import sys
import re
import argparse
from datetime import datetime

socket_path = '/var/run/docker.sock'
sock_error_msg = 'No docker.sock on the machine'
unknown_error_msg = 'Unknown error'
http_body_pattern = '^HTTP\/1\.1 (.+?)\\r\\n'
log_file = None
now_date = datetime.now().strftime('%d-%m-%YT%H:%M:%S%z')


def main():
    log = sys.stderr.write
    if log_file:
        if not os.path.exists(os.path.dirname(log_file)):
            log(format_log_entity('ERROR: Uncorrect output option'))
        else:
            log = log_to_file

    if not os.path.exists(socket_path):
        log(format_log_entity(sock_error_msg))
        sys.exit(10)

    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.connect(socket_path)
    responce = None
    try:
        client.send(b'POST /containers/wireguard_balancer/kill?signal=HUP HTTP/1.1\r\nHost: docker\r\n\r\n')
        responce = client.recv(1024)
    except Exception as error:
        log(format_log_entity(error))
    finally:
        client.close()

    if responce:
        http_body = re.search(http_body_pattern, responce.decode()).group(1)
        log(format_log_entity(http_body))
    else:
        log(format_log_entity(unknown_error_msg))
        sys.exit(20)


def log_to_file(log_entity):
    with open(log_file, 'a') as f:
        f.write(log_entity)


def format_log_entity(log_entity):
    return '{0} {1}{2}'.format(now_date, log_entity, os.linesep)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Reload nginx in wireguard_balancer container.')
    parser.add_argument(
        '-o',
        '--output',
        action='store',
        help='redirect output to file')

    args = parser.parse_args()
    log_file = args.output

    main()
