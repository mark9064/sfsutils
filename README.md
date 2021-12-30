# sfsutils

A KSP SFS savefile parser

## Install

`pip3 install sfsutils`

## Usage

Example:
```python
import sfsutils
data = sfsutils.parse_savefile("saves/persistent.sfs")
# edit data
sfsutils.writeout_savefile(data, destination_file="saves/edited.sfs")
```
All documentation is in the docstrings of each function/class.

Available functions are (see docstrings for more info):
* parse_savefile - Parses an SFS file from stream or file
* writeout_savefile - Writes out the parsed data back into the SFS format

## Notes

This library requires Python 3.6+ in order to have a deterministic parsing order.
Earlier Python versions may work, but the resulting serialised file may not be in the exact same order as the input file.
As far as I am aware, such a file should still load into KSP without issues.


There is a Cython implementation of this module.
With the Cython implementation, parsing is about 4x as fast, and serialisation is about 2x as fast.
The Cython backend will automatically be built and selected if Cython is installed along with a working C compiler at the time when this library is installed.
You can check which backend is in use with sfsutils.BACKEND (possible values: "Python", "Cython").

## License

GPLV3