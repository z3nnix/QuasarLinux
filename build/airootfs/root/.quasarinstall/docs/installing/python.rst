.. _installing.python:

Python library
==============

Quasarinstallships on `PyPi <https://pypi.org/>`_ as `Quasarinstall<pypi.org/project/archinstall/>`_.
But the library can be installed manually as well.

.. warning::
    These steps are not required if you want to use Quasarinstallon the official QuasarLinux ISO.

Installing with pacman
----------------------

Quasarinstallis on the `official repositories <https://wiki.archlinux.org/index.php/Official_repositories>`_.
And it will also install Quasarinstallas a python library.

To install both the library and the Quasarinstallscript:

.. code-block:: console

    pacman -S archinstall

Alternatively, you can install only the library and not the helper executable using the ``python-archinstall`` package.

Installing from PyPI
--------------------

The basic concept of PyPI applies using `pip`.

.. code-block:: console

    pip install archinstall

.. _installing.python.manual:

Install using source code
-------------------------

You can also install using the source code.
For sake of simplicity we will use ``git clone`` in this example.

.. code-block:: console

    git clone https://github.com/archlinux/archinstall

You can either move the folder into your project and simply do

.. code-block:: python

    import archinstall

Or you can PyPa's `build <https://github.com/pypa/build>`_ and `installer <https://github.com/pypa/installer>`_ to install it into pythons module path.

.. code-block:: console

    $ cd archinstall
    $ python -m build .
    $ python -m installer dist/*.whl
