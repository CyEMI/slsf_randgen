#!/usr/bin/env python3
import argparse
import os.path
import sys
import unittest

SYS_EXT = '.mdl'
OUTPUT_PREFIX = '_PPD'

class ModelPreprocessor():
    """docstring for ModelPreprocessor"""

    def __init__(self, sys, outdir):
        self._sys = sys
        self._outdir = outdir

        self._outsys = None         # Output file

        self._outputs = []          # Output lines

        self._unique_kws = set()    # Unique keywords

        self._kw_file_path = []      # Where we store the keywords

        # States

        self._is_inside_System = False
        self._brace_count = 0

    def go(self, write_in_disc):
        assert(os.path.exists(self._sys))
        assert(os.path.exists(self._outdir))

        self._get_out_files()
        self._parse()

        output = self._build_output()

        if write_in_disc:
            self._write_output(output)
            return None
        else:
            return output

    def _parse(self):
        
        self._outputs.append(self._get_prefix())

        with open(self._sys, 'r') as infile:
            for l in infile:
                line = l.strip()

                if not self._is_inside_System:
                    if self._check_valid_keyword_start(line, "System"):
                        self._add_line(l)
                        self._brace_count = 1
                        self._is_inside_System = True
                    continue

                # Inside System
                self._process_System(line, l)
                
                if not self._is_inside_System:
                    self._add_line("}")
                    return

        self._outputs.append(self._get_suffix())

    def _check_valid_keyword_start(self, line, kw):
        if not line.startswith(kw):
            return False

        tokens = line.split(" ")
        return tokens[0] == kw 

    def _build_output(self):
        result = ''.join(self._outputs)
        return result

    def _write_output(self, output):
        with open(self._outsys, 'w') as outfile:
            outfile.write(output)

    def _get_out_files(self):
        self._sysdir, sys = os.path.split(self._sys)

        self._outsys = os.path.join(self._outdir, sys)

    def _add_line(self, line):
        self._outputs.append('{0}'.format(line))

    def _process_System(self, line, original_line):
        self._add_line(original_line)

        if line == "}":
            self._brace_count -= 1

            if self._brace_count == 0:
                self._is_inside_System = False
                return

        tokens = line.split(' ')

        if "{" in tokens:
            self._brace_count += 1

        self._unique_kws.add(tokens[0])

    def _get_prefix(self):
        return """Model {\n
        """

    def _get_suffix(self):
        return """}\n
        """


class TestModelPreprocessor(unittest.TestCase):

    def test_sampleModel(self):
        sys_loc = '/home/cyfuzz/workspace/emi/slearner/sampleModel20.mdl'
        out_loc = '/home/cyfuzz/workspace/emi/slearner/output'

        mp = ModelPreprocessor(sys_loc, out_loc)
        result = mp.go(True)
        self.assertIsNone(result)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    
    parser.add_argument("--sys", help='Full path of the Simulink Model')
    parser.add_argument('--outdir', help='output location')

    args = parser.parse_args()

    try:
        ModelPreprocessor(args.sys, args.outdir).go(True)
        print('-------- RETURNING FROM model_preprocessor --------')
        sys.exit(0)
    except Exception as e:
        print('Exception in model_preprocessor.py: {}'.format(e))
        sys.exit(-1)