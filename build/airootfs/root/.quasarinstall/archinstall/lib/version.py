from importlib.metadata import version


def get_version() -> str:
	try:
		return version('archinstall')
	except Exception:
		return 'Quasarinstallversion not found'
