# Equivalence-based Mutation of CPS models

## Mutation Strategies

### Fixating output type of every block

Two issues: one generalising from the issue solved by 
`emi.decs.FixateDTCOutputDataType` -- since block output types may get 
changed in the mutants and would result in comparison errors. Other is a 
possible bug

`TypeAnnotateByOutDTypeStr` fixates output type of every block.
`TypeAnnotateEveryBlock` fixates input types of every block.

See `emi.decs.TypeAnnotateByOutDTypeStr`

    MUTATOR_DECORATORS = {
        @emi.decs.TypeAnnotateEveryBlock                % Pre-process
        @emi.decs.TypeAnnotateByOutDTypeStr              % Pre-process
        @emi.decs.DeleteDeadAddSaturation
        };

### Fixating output type of DTC blocks

Issue: Data-type converters in the original model was getting a new 
output data type in the mutants, since their successors got change and 
Simulink was inferring new output data types for the DTC blocks. 
See `emi.decs.FixateDTCOutputDataType`

    MUTATOR_DECORATORS = {
        @emi.decs.FixateDTCOutputDataType               % Pre-process
        @emi.decs.TypeAnnotateEveryBlock                % Pre-process
        @emi.decs.DeleteDeadAddSaturation
        };

### Delete dead block and directly connect predecessors and successors

Issue: May change semantics in live path

Code:

    MUTATOR_DECORATORS = {
        @emi.decs.TypeAnnotateEveryBlock
        @emi.decs.DeleteDeadDirectReconnect
        };

