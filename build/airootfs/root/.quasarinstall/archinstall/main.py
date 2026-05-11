#!/usr/bin/env python3
# QuasarLinux installer - полностью standalone приложение

import importlib
import os
import sys
import textwrap
import time
import traceback
from pathlib import Path

# Добавляем родительскую директорию Quasarinstallв путь
# Структура: /root/archinstall/archinstall/lib/...
# Нам нужно добавить /root/archinstall
ARCHINSTALL_PARENT = '/root/.quasarinstall'

if os.path.exists(ARCHINSTALL_PARENT):
    sys.path.insert(0, ARCHINSTALL_PARENT)
else:
    print(f"FATAL: Quasarinstall directory not found at {ARCHINSTALL_PARENT}")
    sys.exit(1)

# Теперь импортируем из ЛОКАЛЬНОЙ копии archinstall
try:
    from archinstall.lib.args import ArchConfigHandler
    from archinstall.lib.disk.utils import disk_layouts
    from archinstall.lib.hardware import SysInfo
    from archinstall.lib.menu.helpers import Confirmation
    from archinstall.lib.network.wifi_handler import WifiHandler
    from archinstall.lib.networking import ping
    from archinstall.lib.output import debug, error, info, warn
    from archinstall.lib.packages.util import check_version_upgrade
    from archinstall.lib.pacman.pacman import Pacman
    from archinstall.lib.translationhandler import tr, translation_handler
    from archinstall.lib.utils.util import running_from_iso
    from archinstall.tui.components import tui
    from archinstall.tui.menu_item import MenuItemGroup
except ImportError as e:
    print(f"FATAL: Cannot import Quasarinstall modules: {e}")
    print(f"Make sure '{ARCHINSTALL_PARENT}/archinstall' exists")
    sys.exit(1)

CURRENT_DIR = Path(__file__).parent


def _log_sys_info() -> None:
    debug(f'Hardware model detected: {SysInfo.sys_vendor()} {SysInfo.product_name()}; UEFI mode: {SysInfo.has_uefi()}')
    debug(f'Processor model detected: {SysInfo.cpu_model()}')
    debug(f'Memory statistics: {SysInfo.mem_available()} available out of {SysInfo.mem_total()} total installed')
    debug(f'Virtualization detected: {SysInfo.virtualization()}; is VM: {SysInfo.is_vm()}')
    debug(f'Graphics devices detected: {list(SysInfo._graphics_devices().keys())}')
    debug(f'Disk states before installing:\n{disk_layouts()}')


def _check_online(wifi_handler=None) -> bool:
    try:
        ping('1.1.1.1')
        return True
    except OSError as ex:
        if 'Network is unreachable' in str(ex):
            if wifi_handler is not None:
                result = tui.run(wifi_handler)
                return result
        return False


def _fetch_arch_db() -> bool:
    info('Fetching QuasarLinux package database...')
    try:
        Pacman.run('-Sy')
    except Exception as e:
        error('Failed to sync QuasarLinux package database.')
        if 'could not resolve host' in str(e).lower():
            error('Most likely due to a missing network connection or DNS issue.')
        error('Run with --debug and check logs for details.')
        debug(f'Failed to sync: {e}')
        return False
    return True


def _list_scripts() -> str:
    lines = ['The following are viable --script options:']
    scripts_dir = CURRENT_DIR / 'scripts'
    
    if scripts_dir.exists():
        for file in scripts_dir.glob('*.py'):
            if file.stem != '__init__':
                lines.append(f'    {file.stem}')
    else:
        lines.append('    No scripts found')
    
    return '\n'.join(lines)


def _tui_confirm(header: str) -> bool:
    async def _ask() -> bool:
        result = await Confirmation(
            group=MenuItemGroup.yes_no(),
            header=header,
            allow_skip=False,
            preset=False,
        ).show()
        return result.get_value()
    
    return tui.run(_ask)


def run() -> int:
    if 'share-log' in sys.argv:
        warn('share-log functionality not implemented in standalone version')
        return 1
    
    arch_config_handler = ArchConfigHandler()
    
    if '--help' in sys.argv or '-h' in sys.argv:
        arch_config_handler.print_help()
        return 0
    
    script = arch_config_handler.get_script()
    
    if script == 'list':
        print(_list_scripts())
        return 0
    
    if os.getuid() != 0:
        print(tr('Quasarinstall requires root privileges to run. See --help for more.'))
        return 1
    
    translation_handler.save_console_font()
    _log_sys_info()
    
    if not arch_config_handler.args.offline:
        if not arch_config_handler.args.skip_wifi_check:
            wifi_handler = WifiHandler()
        else:
            wifi_handler = None
        
        if not _check_online(wifi_handler):
            return 0
        
        if not _fetch_arch_db():
            return 1
        
        if not arch_config_handler.args.skip_version_check:
            upgrade = check_version_upgrade()
            if upgrade:
                info(f'New version available: {upgrade}')
                time.sleep(3)
    
    if running_from_iso():
        debug('Running from ISO (Live Mode)...')
    else:
        debug('Running from Host (H2T Mode)...')
    
    # Загружаем скрипт из локальной папки scripts
    mod_name = f'scripts.{script}'
    try:
        if str(CURRENT_DIR) not in sys.path:
            sys.path.insert(0, str(CURRENT_DIR))
        module = importlib.import_module(mod_name)
        module.main(arch_config_handler)
    except ImportError as e:
        error(f'Failed to load script "{script}": {e}')
        print(_list_scripts())
        return 1
    
    return 0


def _error_message(exc: Exception) -> None:
    err = ''.join(traceback.format_exception(type(exc), exc, exc.__traceback__))
    error(f'Exception: {err}')
    
    text = textwrap.dedent(
        """\
        QuasarLinux installer experienced an error.
        Please report this issue.
        """
    )
    warn(text)


def main() -> int:
    rc = 0
    exc = None
    
    try:
        rc = run()
    except Exception as e:
        exc = e
    finally:
        if exc:
            _error_message(exc)
            rc = 1
        translation_handler.restore_console_font()
    
    return rc


if __name__ == '__main__':
    sys.exit(main())