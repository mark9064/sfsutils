# sfsutils

A KSP SFS savefile parser

## Install

`pip install sfsutils`

## Usage

Example:
```python
import sfsutils
data = sfsutils.parse_savefile("saves/persistent.sfs")
# edit data
sfsutils.writeout_savefile(data, destination_file="saves/edited.sfs")
```
All documentation is in the docstrings of each function.

Available functions are (see docstrings for more info):
* parse_savefile - Parses an SFS file from stream or file
* writeout_savefile - Writes out the parsed data back into the SFS format

## Notes

The parsing order of this library is deterministic, but note that this guarantee is provided by Python dictionaries sorting keys by the order of insertion (this is the case since Python 3.6).


There is a Cython implementation of this module.
With the Cython implementation, parsing is about 4x as fast, and serialisation is about 2x as fast. The Cython backend will automatically be built and selected if Cython is installed along with a working C compiler at the time when this library is installed. If Cython is not available or the build otherwise fails, the pure Python backend will be installed instead.

The backend in use can be checked with sfsutils.BACKEND (possible values: "Python", "Cython").

## License

GPLV3