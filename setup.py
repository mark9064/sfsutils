import setuptools

try:
    from Cython.Build import cythonize
except ImportError:
    USE_CYTHON = False
else:
    USE_CYTHON = True

with open("README.md", "r") as fh:
    LONG_DESCRIPTION = fh.read()

setup_args = dict(
    name="sfsutils",
    version="1.1.1",
    author="mark9064",
    description="A KSP SFS savefile parser",
    long_description=LONG_DESCRIPTION,
    long_description_content_type="text/markdown",
    url="https://github.com/mark9064/sfsutils",
    packages=setuptools.find_packages(),
    python_requires='>=3.7',
    install_requires=[],
    zip_safe=False,
    classifiers=[
        "Programming Language :: Python :: 3",
        "Programming Language :: Cython",
        "License :: OSI Approved :: GNU General Public License v3 (GPLv3)",
        "Operating System :: OS Independent",
        "Development Status :: 4 - Beta",
        "Natural Language :: English",
    ],
)

if USE_CYTHON:
    setup_args_cython = setup_args.copy()
    setup_args_cython["ext_modules"] = cythonize(
        [setuptools.Extension(name="sfsutils._sfsutils", sources=["sfsutils/_sfsutils.pyx"])],
        language_level=3,
    )
    try:
        setuptools.setup(**setup_args_cython)
    except BaseException:
        USE_CYTHON = False
if not USE_CYTHON:
    setuptools.setup(**setup_args)
