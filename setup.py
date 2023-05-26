from setuptools import setup, find_packages

setup(
    name='EV-Eye',
    version='1.0',
    packages=find_packages(),
    install_requires=[
        'torch >= 1.9.0'
        'numpy >= 1.21.0'
        'tqdm >= 4.61.1'
        'h5py >= 3.2.1'
        'torchvision >= 0.10.0'
        'argparse >= 1.1'
    ],
)