#!/usr/bin/env python3

import argparse
import grp
import json
import logging
import pprint
import re
import subprocess

logger = logging.getLogger(__file__)

pp = pprint.PrettyPrinter(indent=4)

def main(filename):
    config = {}
    config['users'] = {}
    config['gids'] = {}
    try:
        users = subprocess.check_output(['wbinfo', '-u'], encoding='UTF-8').split()
    except FileNotFoundError:
        users = subprocess.check_output('getent passwd | cut -d: -f1', shell=True, encoding='UTF-8').split()
    for user in users:
        if ' ' in user:
            continue
        if '$' in user:
            continue
        if user in ['nfsnobody']:
            continue
        try:
            uid = subprocess.check_output(['id', '-u', user], encoding='UTF-8').split()[0]
        except subprocess.CalledProcessError:
            continue
        if int(uid) < 1024:
            continue
        logger.debug('user: ' + user)
        config['users'][user] = {}
        config['users'][user]['uid'] = uid
        config['users'][user]['gid'] = subprocess.check_output(['id', '-g', user], encoding='UTF-8').split()[0]
        logger.debug(subprocess.check_output(['id', '-G', user], encoding='UTF-8'))
        logger.debug(subprocess.check_output(['id', '-G', user], encoding='UTF-8').split('\n'))
        logger.debug(subprocess.check_output(['id', '-G', user], encoding='UTF-8').split('\n')[0])
        config['users'][user]['gids'] = sorted(subprocess.check_output(['id', '-G', user], encoding='UTF-8').split('\n')[0].split(' '))
        try:
            home_dir = subprocess.check_output(f'getent passwd {user}| cut -d: -f6', shell=True, encoding='UTF-8').split()[0]
        except:
            logger.exception(f"Couldn't get home dir for {user}")
            home_dir = ''
        config['users'][user]['home'] = home_dir

        for gid in config['users'][user]['gids']:
            config['gids'][str(gid)] = ''
    for gid in config['gids'].keys():
        if int(gid) < 1024:
            continue
        group_name = get_group_name(int(gid))
        if group_name in ['nfsnobody']:
            continue
        config['gids'][gid] = group_name
    with open(filename, 'w') as fh:
        #fh.write(pp.pformat(config))
        json.dump(config, fh, sort_keys=True, indent=4)
    return

def get_group_name(gid):
    try:
        group_name = grp.getgrgid(gid).gr_name
    except KeyError:
        # Handle the case where a group doesn't have a name.
        # This can happen inside the container when a group name from AD is too long.
        group_name = str(gid)
    group_name = re.sub(r'^.+\\(.+)', r'\1', group_name)
    group_name = re.sub(r' ', r'_', group_name)
    return group_name


if __name__ == '__main__':
    parser = argparse.ArgumentParser("Write user/group info to a json file")
    parser.add_argument('-o', dest='filename', action='store', required=True, help="output filename")
    parser.add_argument('--debug', '-d', action='count', default=False, help="Enable debug messages")
    args = parser.parse_args()

    logger_formatter = logging.Formatter('%(levelname)s:%(asctime)s: %(message)s')
    logger_streamHandler = logging.StreamHandler()
    logger_streamHandler.setFormatter(logger_formatter)
    logger.addHandler(logger_streamHandler)
    logger.setLevel(logging.INFO)
    if args.debug:
        logger.setLevel(logging.DEBUG)

    main(args.filename)
