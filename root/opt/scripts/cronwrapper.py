#!/usr/bin/env python3

import argparse
import os
import re
import subprocess
import sys
import time

# Try to use the fastest json lib available
# Resort back to stdlib if necessary (slower)
try:
    import ujson as json
except ImportError:
    try:
        import simplejson as json
    except ImportError:
        import json


re_backspaces = re.compile('(\b)+')


def filterOutputString(string):
    return re_backspaces.sub('', string)


# MAIN
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Simple execution wrapper for cron type jobs',
                                    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-c', '--command', dest='command', action='store',
                        default='/usr/local/bin/php',
                        help='The path to the final cron')
    parser.add_argument('--forward-stderr', dest='forward_stderr', action='store_true',
                        default=False,
                        help='If True, forward script stderr to caller shell stderr')
    parser.add_argument('args', nargs='*',
                        default=[os.path.join(os.getenv('GLPI_PATHS_ROOT', '/'), 'front/cron.php')],
                        help='The arguments list')
    args = parser.parse_args()
    command_path = os.path.realpath(args.command)
    command_args = args.args
    if '--' in command_args:
        command_args.remove('--')

    log = dict(
      stdout='',
      stdout_size=0,
      stderr='',
      stderr_size=0,
      wrapped_command=args.command,
      wrapped_command_fullpath=command_path,
      return_code=None,
      arguments=' '.join(command_args),
      full_command=' '.join([command_path] + command_args),
    )

    raw_stdout = ''
    raw_stderr = ''
    try:
        log['start_time'] = time.time()
        result = subprocess.Popen([command_path] + command_args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
        raw_stdout, raw_stderr = result.communicate()
        log['stdout'] = filterOutputString(raw_stdout)
        log['stderr'] = filterOutputString(raw_stderr)
        log['return_code'] = result.returncode
    except subprocess.CalledProcessError as ex:
        log['stderr'] = str(ex)
    except OSError as ex:
        log['stderr'] = str(ex)
    finally:
        log['end_time'] = time.time()
        log['execution_time'] = log['end_time'] - log['start_time']

    log['stdout_size'] = len(log['stdout'])
    log['stderr_size'] = len(log['stderr'])
    sys.stdout.write(json.dumps(log)+'\n')
    if args.forward_stderr and len(log['stderr']):
      sys.stderr.write(log['stderr']+'\n')
    sys.exit(0)
