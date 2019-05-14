# CyEMI: EMI-based Validation of Cyber-Physical System Development Tool Chain

We are investigating automated _Equivalence Modulo Input (EMI)_-based testing of commercial cyber-physical system development tool chains (e.g. MATLAB/Simulink). We present following three independant tools in this repository:

- [Rapid Experimentation Framework](+covexp/)
- [Mutant Generator](+emi/)
- [Differential Tester](+difftest/)

## Notes to Reviewers

- [ASE 2019 Data and Bugs](notes/ase/)

## Requirements

MATLAB R2018a with default Simulink toolboxes

## Installation

Please use `git` to properly install all third-party dependencies:

    git clone https://github.com/CyEMI/slsf_randgen.git
    cd slsf_randgen
    git submodule update --init
    matlab # Opens MATLAB


## Randomly Generated Seed Models

We use the open source *SLforge* tool to generate valid Simulink models. 
Although we initially forked from the project, our current version are independant of SLforge and its predecessor CyFuzz

### SLforge: Automatically Finding Bugs in a Commercial Cyber-Physical Systems Development Tool

Check out [SLforge homepage](https://github.com/verivital/slsf_randgen/wiki) for latest news, running the tools and to contribute.

### CyFuzz: A Differential Testing Framework for Cyber-Physical Systems Development Environments

SLforge is developed extending CyFuzz's code base, which is still availale in the `cyfuzz-experiments` branch.

#### SLforge Acknowledgement (Kept as-is from the SLforge project's Readme.md)

This material is based upon work supported by the National Science Foundation under Grants No. 1117369, 1464311, and 1527398. Any opinions, findings, and conclusions or recommendations expressed in this material are those of the author(s) and do not necessarily reflect the views of the National Science Foundation.
