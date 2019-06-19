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

## License

GPLV3