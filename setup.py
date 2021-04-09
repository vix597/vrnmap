"""Setup script for pynmapservice package."""
import os
from typing import List
from setuptools import setup

from pynmapservice.version import __version__


def load_requirements(filename: str) -> List[str]:
    """
    Load the requirements for the package.

    :param filename: The filename within the requirements folder to load from
    :returns: List of requirements in the requirements file (skipping comments)
    """
    path = os.path.join(os.path.dirname(__file__), 'requirements', filename)
    return [line for line in open(path, 'r').readlines() if line.strip() and not line.startswith('#')]


# Load the requirements
requirements = load_requirements('requirements.txt')
dev_requirements = load_requirements('requirements-dev.txt')

setup(
    name='pynmapservice',
    version=__version__,
    license='ISC',
    description='Websocket controlled Nmap for VR Nmap',
    long_description=open("README.md", 'r').read(),
    long_description_content_type='text/markdown',
    author='Sean LaPlante',
    author_email='laplante.sean@gmail.com',
    url='TODO',
    packages=['pynmapservice'],
    install_requires=requirements,
    extras_require={
        'dev': dev_requirements
    },
    project_urls={
        'Source': 'https://github.com/vix597/vrnmap/',
    },
    keywords=['VR', 'Game', "Nmap"],
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: ISC License (ISCL)',
        'Natural Language :: English',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3',
        'Topic :: Games/Entertainment'
    ]
)
