"""Parser for KSP savefiles"""

BACKEND = "Cython"


cpdef dict parse_savefile(str sfs, bint sfs_is_path=True):
    """Parses an SFS file

    Params:
        sfs: str; the path to the SFS file to read or a string containing data read from an sfs.
        sfs_is_path (optional, default True): bool; whether the 'sfs' param is a path or raw data.
    Raises:
        No specific exceptions.
    Returns:
        Dictionary containing the data in the SFS.
    Extra information:
        All values are strings as SFS files do not reveal data to be any type.
        The SFS format is particularly bad and this leads to the returned dictionary
        containing data that is unusually structured. If the SFS contains multiple keys of any
        kind with the same name (this can be a 'node' header or values in a node), then the data
        contained within these keys will formatted as the common name of the keys as a key
        in a dict, and the values as a list. This data will always be in the exact order
        that they were in in the SFS (dictionaries are ordered in Python 3.6+). Example:

        --SFS format--
        NODE
        {
            x = 1
            x = 2
            y = 3
        }
        NODE
        {
            value = 1
        }
        OTHER
        {
            z = 4
        }

        --Python structure--
        {
            "NODE": [
                {"x": ["1","2"], "y": "3"},
                {"value": "1"}
            ],
            "OTHER": {
                "z": "4"
            }
        }
    """
    cdef:
        object file
        str data
        list in_nodes
        dict out_dict
        long key_read
        long value_read
        long index
        Py_UCS4 char
        list write_list
    if sfs_is_path:
        with open(sfs, "r") as file:
            data = file.read()
    else:
        data = sfs
    # removes all tabs, spaces after newlines and spaces around equals
    data = data.replace("\t", "").replace("\n ", "\n").replace(" = ", "=")
    # in_nodes tracks the location of data being parsed (what nodes the parser is inside)
    in_nodes = []
    out_dict = {}
    # key_read contains the start index of the key being read
    key_read = 0
    # value_read contains the start index of the value being read
    value_read = 0
    for index, char in enumerate(data):
        if char == "\n":
            # if the last character wasn't a bracket, we have a node
            if data[index - 1] not in {"{", "}"}:
                # if next char is an open bracket, save it as a new node
                if data[index + 1] == "{":
                    in_nodes.append(data[key_read:index])
                    set_value(out_dict, in_nodes, {})
                # else it is a value in an existing node
                else:
                    write_list = in_nodes[:]
                    # use value_read - 1 as the endpoint as the key must end 2 chars before the value starts
                    write_list.append(data[key_read : value_read - 1])
                    set_value(out_dict, write_list, data[value_read:index])
            # read the key from the beginning of the next line
            key_read = index + 1
        # pop the end of the 'stack' used to track attribute location
        # when the end of a node is found
        elif char == "}":
            in_nodes.pop()
        # set the start index of the value (the end index of the key must be one less than this)
        elif char == "=":
            value_read = index + 1
    return out_dict


cdef inline void set_value(dict dict_nested, list address_list, object value):
    """Sets a value in a nested dict
    WARNING - mutates the dictionary passed as an argument"""
    cdef:
        object current
        str path_item
        str prev_node
    # references the main dict
    current = dict_nested
    # locate the desired node to write to through iterating through the keys
    # while selecting the last element of any list found, as the data is in order
    for path_item in address_list[:-1]:
        if isinstance(current, list):
            current = current[-1][path_item]
        else:
            current = current[path_item]
    # if current is a list, then take the last entry as that's what will be modified
    if isinstance(current, list):
        current = current[-1]
    # if the node already exists
    prev_node = address_list[-1]
    if prev_node in current:
        # if it's a list simply append it to the list
        if isinstance(current[prev_node], list):
            current[prev_node].append(value)
        # else convert the existing dict to a list
        else:
            current[prev_node] = [current[prev_node], value]
    # if it doesn't exist
    else:
        # guaranteed to be a dict thanks to earlier list check, so insert the key into the dict
        current[prev_node] = value


cpdef str writeout_savefile(dict parsed_data, str destination_file=None):
    """Writes out the parsed data back into the SFS format

    Params:
        parsed_data: dict; the parsed dictionary generated by parse_savefile.
        destination_file (optional): str; the destination file to write the SFS to.
    Raises:
        No specific exceptions.
    Returns:
        str containing the generated SFS if a destination file is not specified.
        None if a destination file is specified.
    Extra information:
        This function will generate a byte perfect copy of the original SFS parsed assuming
        the data is not modified. All abnormalities of the SFS format are addressed and
        represented correctly.
    """
    cdef:
        str out_str
        list out_data
        object file
    out_data = []
    serialise_data(parsed_data, out_data, -1)
    out_str = "".join(out_data)
    if not destination_file:
        return out_str
    with open(destination_file, "w") as file:
        file.write(out_str)
    return None


cdef void serialise_data(object obj, list out_data, int indents):
    """Recursively serialises data"""
    cdef:
        str indent_str
        list buffer_list
        dict item
        str key
        object value
        str res
        dict subdict
    # indent upon each recurse
    indents += 1
    indent_str = "\t" * indents
    # set up the buffer list
    if isinstance(obj, list):
        buffer_list = obj
    else:
        buffer_list = [obj]
    for item in buffer_list:
        # it is a dict, so iterate through
        for key, value in item.items():
            # if value is a string, it must be a value to write to a node
            if isinstance(value, str):
                out_data.extend((indent_str, key, " = ", value, "\n"))
            # if it's a dict, it's another node, so recurse
            elif isinstance(value, dict):
                write_new_node(out_data, indent_str, indents, key, value)
            # if it's a list it could be multiple things
            else:
                # if the first element is a string, they will all be
                # it is a multi value node
                if isinstance(value[0], str):
                    # write out each value in the node
                    for res in value:
                        out_data.extend((indent_str, key, " = ", res, "\n"))
                # else just write out each subdict in the list
                else:
                    for subdict in value:
                        write_new_node(out_data, indent_str, indents, key, subdict)


cdef inline void write_new_node(
    list out_data,
    str indent_str,
    int indents,
    str sect_name,
    object value,
):
    """Write a new node to the SFS"""
    # adds the header
    out_data.extend((indent_str, sect_name, "\n", indent_str, "{\n"))
    # adds data through recursion
    serialise_data(value, out_data, indents)
    # closes the block
    out_data.extend((indent_str, "}\n"))
