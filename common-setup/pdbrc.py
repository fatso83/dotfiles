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
    h_len = readline.get_current_history_length()
except FileNotFoundError:
    open(histfile, 'wb').close()
    h_len = 0

def save(prev_h_len, histfile):
    new_h_len = readline.get_current_history_length()
    readline.set_history_length(5000)
    readline.append_history_file(new_h_len - prev_h_len, histfile)

atexit.register(save, h_len, histfile)
