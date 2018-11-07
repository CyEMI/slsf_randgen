#!/usr/bin/env python3
import argparse
import os.path
import re
import sys
import unittest

SYS_EXT = '.mdl'
OUTPUT_PREFIX = '_PPD'


class ModelPreprocessor():
    """docstring for ModelPreprocessor"""

    @property
    def unique_kws(self):
        return self._unique_kws

    def __init__(self, model_name, outdir, unique_kws=None):
        self._sys = model_name
        self._outdir = outdir

        self._outsys = None         # Output file

        self._outputs = []          # Output lines

        self._unique_kws = unique_kws if unique_kws is not None else set()    # Unique keywords

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

    def _get_tokens(self, line):
        return re.split(r'[\s]+', line)

    def _parse(self):
        
        self._outputs.append(self._get_prefix())

        with open(self._sys, 'r') as infile:
            for l in infile:
                line = l.strip()
                tokens = self._get_tokens(line)

                if not self._is_inside_System:
                    if self._check_valid_keyword_start(line, "System", tokens):
                        self._add_line(l)
                        self._brace_count = 1
                        self._is_inside_System = True
                    continue

                # Inside System
                self._process_System(line, l, tokens)
                
                if not self._is_inside_System:
                    self._add_line("}")
                    return

        self._outputs.append(self._get_suffix())

    def _check_valid_keyword_start(self, line, kw, tokens):
        if not line.startswith(kw):
            return False

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

    def _process_System(self, line, original_line, tokens):
        self._add_line(original_line)

        if line == "}":
            self._brace_count -= 1

            if self._brace_count == 0:
                self._is_inside_System = False
                return

        if "{" in tokens:
            self._brace_count += 1

        self._unique_kws.add(tokens[0])

    def _get_prefix(self):
        return """Model {\n
        """

    def _get_suffix(self):
        return """}\n
        """


class BulkModelProcessor:
    def __init__(self, input_dir, output_dir):
        self._input_dir = input_dir
        self._output_dir = output_dir
        self._unique_kw = set()                     # Unique Keywords

    def _process_dir(self, *args):
        for file in os.listdir(self._input_dir):
            if os.path.isdir(file) or not file.endswith(SYS_EXT):
                continue
            mp = ModelPreprocessor(file, self._output_dir, self._unique_kw)
            mp.go(*args)

    def _write_unique_kws(self):
        kw_file_name = 'unique_keywords.txt'
        kw_file_path = os.path.join(self._output_dir, kw_file_name)

        with open(kw_file_path, 'w') as outfile:
            outfile.write('\n'.join(self._unique_kw))

    def go(self, *args):
        if os.path.isfile(self._input_dir):
            mp = ModelPreprocessor(self._input_dir, self._output_dir, self._unique_kw)
            mp.go(*args)
        else:
            self._process_dir(*args)

        if '}' in self._unique_kw:
            self._unique_kw.remove('}')

        self._write_unique_kws()


class TestModelPreprocessor(unittest.TestCase):

    def test_sampleModel(self):
        sys_loc = '/home/cyfuzz/workspace/emi/slearner/sampleModel20.mdl'
        out_loc = '/home/cyfuzz/workspace/emi/slearner/output'

        mp = ModelPreprocessor(sys_loc, out_loc)
        result = mp.go(True)
        self.assertIsNone(result)


class TestBulkModelPreprocessor(unittest.TestCase):

    def test_smoke(self):
        sys_loc = '/home/cyfuzz/workspace/emi/slearner'
        out_loc = '/home/cyfuzz/workspace/emi/slearner/output'

        mp = BulkModelProcessor(sys_loc, out_loc)
        mp.go(True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    
    parser.add_argument("--sys", help='Full path of the Simulink Model')
    parser.add_argument('--outdir', help='output location')

    cmd_args = parser.parse_args()

    try:
        BulkModelProcessor(cmd_args.sys, cmd_args.outdir).go(True)
        print('-------- RETURNING FROM model_preprocessor --------')
        sys.exit(0)
    except Exception as e:
        print('Exception in model_preprocessor.py: {}'.format(e))
        sys.exit(-1)