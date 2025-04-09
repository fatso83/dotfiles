# vi: ft=python
import rlcompleter
import readline
import atexit
import os
from pdb import Pdb

# Enable tab completion
readline.parse_and_bind("tab: complete")
Pdb.complete = rlcompleter.Completer(locals()).complete
# Enable command history
histfile = os.path.join(os.path.expanduser("~"), ".pdb_history")
try:
    readline.read_history_file(histfile)
except FileNotFoundError:
    pass

atexit.register(readline.write_history_file, histfile)
