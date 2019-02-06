# Experiment on Data (aka Models) and Aggregate Results

This package contains scripts helpful for running various experiments on
Simulink models (aka Model), cache them and aggregate results

Results on individual Models are cached in the disc with the `covdata.mat`
suffix

### Why call `covexp`?

We initially creatd the package to experiment with Model coverage. 
Now this is used for other types of experiments with the Models

## Configuring

Edit the `../covcfg.m` file

### Parallel run

set `PARFOR = true`

## Running

    covexp.covcollect();

## Experiments

To create an experiment, write a script inside `+covexp/+experiments`

Initialize the results that the experiment would return inside 
`+covexp/+experiments/+ds_init`

- Experiment should not throw errors. If an experiment throws, following experiments for the same model will not run.
- In Parallel mode other models will be run, but the `touched` file will not be cleared so that you know which model threw.
- In serial mode the script will stop sot that you can fix the bug.
- Do not close the model inside experiments

## Copying cached results created elsewhere

In some other machine, issue following

    tar -cjvf backup.tar.bz2 *covdata.mat *_pp.slx

Here, we are also copying the pre-processed `_pp.slx` files.

Next, copy the tar.bz2 file in your machine and extract:

  tar -xjvf backup.tar.bz2 --overwrite

### Fixing Model locations

Since the cached `covdata.mat` files were created in a different machine, 
they contain absolute directory locations for that machine. To fix these,
run the `fix_input_loc` (5th) experiment

## Results

Explain how to interpret the cached results

- `simdur` : duration to simulate the original model
- `duration` : duration to collect coverage